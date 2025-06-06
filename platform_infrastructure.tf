locals {
  bill_of_landing_managed_identity_id = "/subscriptions/99999999-9999-9999-9999-999999999999/resourcegroups/example-management-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/finance-reports-management"
}

# Deploys Azure resources for the in-cluster platform components.
#
# https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-platform-infrastructure
#
module "platform_infrastructure" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-platform-infrastructure.git?ref=v2.0.0"

  azure_resource_attributes = var.azure_resource_attributes
  naming_convention         = var.naming_convention
  user_defined              = var.user_defined

  service_principal_owners = var.service_principal_owners

  cluster_node_resource_group_id = module.infrastructure.cluster_node_resource_group_id
  cluster_identity_object_id     = module.infrastructure.user_assigned_identity_kubelet_principal_id

  networking_ids = {
    dns_zones = {
      cert_manager = var.data_sources.dns_zone_id.cert_manager
      blob_storage = var.data_sources.dns_zone_id.blob_storage
    }
    subnets = {
      infrastructure = var.vnet_id == null ? module.network[0].vnet_subnets["infrastructure"].id : var.subnet_ids["infrastructure"]
    }
  }

  grafana_sso_sp = {
    members = {
      viewer = var.grafana_sp.members.viewer
      editor = var.grafana_sp.members.editor
      admin  = var.grafana_sp.members.admin
    }
  }

  bill_of_landing_managed_identity_id = var.azure_resource_attributes.project == "mgmt" ? local.bill_of_landing_managed_identity_id : null

  tags = local.tags
}
