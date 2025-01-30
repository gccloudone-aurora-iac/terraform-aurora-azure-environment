locals {
  maintenance_window_node_os = var.azure_resource_attributes.environment != "prod" ? {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Tuesday"

    start_time = "23:00" # 7:00 PM EST
    duration   = 5
    } : {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Wednesday"

    start_time = "23:00" # 7:00 PM EST
    duration   = 5
  }
}

# Creates an AAD group where all the members within the AAD groups will be assigned the Admin role on the AKS cluster created within the infrastructure module.
#
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group
#
# TODO: Michael to provide context on why this is necessary
resource "azuread_group" "cluster_admins" {
  display_name     = "${module.azure_resource_prefixes.prefix}-cluster-admins"
  owners           = [var.data_sources.active_directory.service_principal_id.gitlab_runner]
  members          = var.cluster_admins
  security_enabled = true
}

# Deploys Azure Kubernetes Service and its related infrastructure.
#
# https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-infrastructure
#
module "infrastructure" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-infrastructure.git?ref=v1.0.0"

  azure_resource_attributes = var.azure_resource_attributes

  cluster_sku_tier   = var.cluster_sku_tier
  cluster_admins     = [azuread_group.cluster_admins.object_id]
  kubernetes_version = var.kubernetes_version
  node_os_upgrade = {
    channel            = var.node_os_upgrade_channel
    maintenance_window = local.maintenance_window_node_os
  }

  cluster_vnet_id               = module.network.vnet_id
  cluster_linux_profile_ssh_key = var.cluster_linux_profile_ssh_key

  node_pools = local.node_pools

  networking_ids = {
    dns_zones = {
      azmk8s   = var.data_sources.dns_zone_id.azmk8s
      keyvault = var.data_sources.dns_zone_id.keyvault
    }
    subnets = {
      api_server     = module.network.vnet_subnets["apiserver"].id
      infrastructure = module.network.vnet_subnets["infrastructure"].id
    }
  }

  tags = local.tags
}
