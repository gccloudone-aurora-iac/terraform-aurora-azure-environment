locals {

  // Add vnet_subnet_id value within each entry in var.node_pools
  // If vnet_subnet_name is set, use that vnet_subnet_id,
  // otherwise use the same subnet that the name of the node pool is
  node_pools = {
    for nodepool_name, nodepool in var.node_pools :
    nodepool_name => nodepool.vnet_subnet_name != null ? merge({ vnet_subnet_id = module.network.vnet_subnets_name_id[nodepool.vnet_subnet_name] }, nodepool) : merge({ vnet_subnet_id = module.network.vnet_subnets_name_id[nodepool_name] }, nodepool)
  }

  tags = merge(var.tags, { ModuleName = "terraform-aurora-azure-environment" }, { ModuleVersion = "v1.0.0" })
}
