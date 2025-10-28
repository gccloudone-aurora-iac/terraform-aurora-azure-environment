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
resource "azuread_group" "cluster_admins" {
  display_name     = "${module.azure_resource_names.active_directory_group_name}-cluster-admins"
  owners           = [var.data_sources.active_directory.service_principal_id.cluster_admins_owner]
  members          = var.cluster_admins
  security_enabled = true
}

# Deploys Azure Kubernetes Service and its related infrastructure.
#
# https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-infrastructure
#
module "infrastructure" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-infrastructure.git?ref=v2.0.5"

  azure_resource_attributes = var.azure_resource_attributes
  naming_convention         = var.naming_convention
  user_defined              = var.user_defined

  cluster_sku_tier     = var.cluster_sku_tier
  cluster_admins       = [azuread_group.cluster_admins.object_id]
  cluster_support_plan = var.cluster_support_plan
  kubernetes_version   = var.kubernetes_version
  node_os_upgrade = {
    channel            = var.node_os_upgrade_channel
    maintenance_window = local.maintenance_window_node_os
  }

  cluster_vnet_id               = var.vnet_id == null ? module.network[0].vnet_id : var.vnet_id
  cluster_linux_profile_ssh_key = var.cluster_linux_profile_ssh_key

  custom_ca = var.custom_ca

  node_pools = local.node_pools

  networking_ids = {
    dns_zones = {
      azmk8s   = var.data_sources.dns_zone_id.azmk8s
      keyvault = var.data_sources.dns_zone_id.keyvault
    }
    subnets = {
      api_server     = var.vnet_id == null ? module.network[0].vnet_subnets["apiserver"].id : var.subnet_ids["apiserver"]
      infrastructure = var.vnet_id == null ? module.network[0].vnet_subnets["infrastructure"].id : var.subnet_ids["infrastructure"]
    }
  }

  vnet_integration_enabled = var.vnet_integration_enabled

  tags = local.tags
}
