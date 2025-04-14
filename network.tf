# Manages the Cloud Native Platform network resources.
#
# https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-network
#
module "network" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-network.git?ref=v2.0.0"

  azure_resource_attributes = var.azure_resource_attributes
  naming_convention         = var.naming_convention
  user_defined              = var.user_defined

  # virtual network
  vnet_address_space      = var.vnet_address_space
  vnet_peers              = var.vnet_peers
  dns_servers             = var.dns_servers
  ddos_protection_plan_id = var.ddos_protection_plan_id

  # subnets
  subnets                         = var.subnets
  route_table_next_hop_ip_address = var.route_table_next_hop_ip_address
  extra_route_table_rules         = var.extra_route_table_rules

  # BGP
  route_server_bgp_peers = var.route_server_bgp_peers

  tags = local.tags
}
