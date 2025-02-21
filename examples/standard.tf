locals {
  azure_tags = {
    DataClassification      = "Undefined"
    wid                     = 000001
    Metadata                = "Undefined"
    environment             = "dev"
    PrimaryTechnicalContact = "william.hearn@ssc-spc.gc.ca"
    PrimaryProjectContact   = "albertabdullah.kouri@ssc-spc.gc.ca"
  }

  cluster_ssh_key = "ssh-rsa ArandomstuffhereEAw== ex-dev-cc-00"
}

#####################
### Prerequisites ###
#####################

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "this" {}

# Manages a Resource Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
#
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "Canada Central"
}

# Manages a virtual network including any configured subnets.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
#
resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Manages a subnet.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
#
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

# Manages an Azure Network Security Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
#
resource "azurerm_network_security_group" "this" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  security_rule       = []

  tags = local.azure_tags
}

# Manages an Azure Route Table. The route table redirects traffic heading to the internet to the firewall first.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
#
resource "azurerm_route_table" "this" {
  name                = "example-rt"
  resource_group_name = azurerm_resource_group.example.name
  location            = "Canada Central"

  route = [
    {
      name                   = "example-default-route"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.23.160.22"
    }
  ]

  tags = local.azure_tags
}

# Remote virtual network

# Manages a Resource Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
#
resource "azurerm_resource_group" "remote" {
  name     = "example-remote-vnet-rg"
  location = "Canada Central"
}

# Manages a virtual network
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
#
resource "azurerm_virtual_network" "remote" {
  name                = "example-remote-vnet"
  address_space       = ["172.16.0.0/16"]
  location            = "Canada Central"
  resource_group_name = azurerm_resource_group.example.name
}

# DNS Zones

resource "azurerm_private_dns_zone" "blob_storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.canadacentral.azmk8s.io"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_dns_zone" "public" {
  name                = "mydomain.com"
  resource_group_name = azurerm_resource_group.example.name
}

# AAD Groups

resource "azuread_group" "hosting_k8s" {
  display_name     = "hosting-k8s"
  owners           = [data.azurerm_client_config.this.object_id]
  security_enabled = true
}

resource "azuread_group" "cloudoperationscn" {
  display_name     = "cloudoperationscn"
  owners           = [data.azurerm_client_config.this.object_id]
  security_enabled = true
}

resource "azuread_group" "aurora_general_cluster_user" {
  display_name     = "aurora-general-cluster-user"
  owners           = [data.azurerm_client_config.this.object_id]
  security_enabled = true
}

###########################################
### Cloud Native Environment Module #######
###########################################

# Manages the Cloud Native Environment.
#
# https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment
#
module "cloud_native_environment" {
  source = "../"

  azure_resource_attributes = {
    project     = "aur"
    environment = "dev"
    location    = azurerm_resource_group.example.location
    instance    = 0
  }
  service_principal_owners = [data.azurerm_client_config.this.object_id]

  ## Network ##
  vnet_address_space = ["172.26.0.0/23"]
  vnet_peers         = [azurerm_virtual_network.remote.id]

  subnets = {
    RouteServerSubnet = {
      address_prefixes      = ["172.26.0.0/27"]
      associate_route_table = false
      create_nsg            = false
    }
    infrastructure = {
      address_prefixes = ["172.26.0.32/27"]
    }
    apiserver = {
      address_prefixes        = ["172.26.0.64/27"]
      service_delegation_name = "Microsoft.ContainerService/managedClusters"
    }
    loadbalancer = {
      address_prefixes = ["172.26.0.96/27"]
    }
    general = {
      address_prefixes  = ["172.26.0.128/25"]
      service_endpoints = ["Microsoft.Storage"]
      service_endpoint_policy_definitions = [{
        scopes = [azurerm_resource_group.example.location]
      }]
    }
    gateway = {
      address_prefixes = ["172.26.1.0/27"]
    }
    system = {
      address_prefixes = ["172.26.1.32/27"]
    }
  }

  route_server_bgp_peers = [
    {
      name     = "example-vm-router"
      peer_asn = "64512"
      peer_ip  = "172.26.0.1"
    }
  ]

  ## AKS Infrastructure ##
  kubernetes_version = "1.27.3"
  cluster_sku_tier   = "Free"
  cluster_admins     = []

  dns_servers                   = ["172.0.0.1", "172.0.0.2"]
  cluster_linux_profile_ssh_key = local.cluster_ssh_key

  node_pools = {
    system = {
      vm_size = "Standard_D2s_v3"
    },
    general = {
      vm_size = "Standard_D2s_v3"
    },
    gateway = {
      vm_size = "Standard_D2s_v3"
    }
  }

  data_sources = {
    dns_zone_id = {
      azmk8s           = azurerm_private_dns_zone.aks.id
      blob_storage     = azurerm_private_dns_zone.blob_storage.id
      keyvault         = azurerm_private_dns_zone.keyvault.id
    }
    active_directory = {
      service_principal_id = {
        cicd_runner = data.azurerm_client_config.this.client_id
      }
      group_id = {
        cloudoperationscn           = azuread_group.cloudoperationscn.id
        hosting_k8s                 = azuread_group.hosting_k8s.id
        aurora_general_cluster_user = azuread_group.aurora_general_cluster_user.id
      }
      tenant_id       = data.azurerm_client_config.this.tenant_id
      subscription_id = data.azurerm_client_config.this.subscription_id
    }
  }

  tags = local.azure_tags
}
