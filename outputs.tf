##########################
### Resource Group IDs ###
##########################

## Network ##
output "network_resource_group_id" {
  description = "The id of the network resource group created."
  value       = var.vnet_id == null ? module.network[0].resource_group_id : null
}

## Infrastructure ##
output "cluster_resource_group_id" {
  description = "The resource group name that the created AKS cluster is in."
  value       = module.infrastructure.cluster_resource_group_id
}

output "cluster_node_resource_group_id" {
  description = "The resource group name that the created AKS cluster is in."
  value       = module.infrastructure.cluster_node_resource_group_id
}

## Platform Infrastructure ##
output "platform_resource_group_id" {
  description = "The name of the platform resource group."
  value       = module.platform_infrastructure.platform_resource_group_name
}

output "backup_resource_group_id" {
  description = "The name of the backup resource group."
  value       = module.platform_infrastructure.backup_resource_group_name
}

###############
### Network ###
###############

output "network" {
  description = "The outputs of the environment_network module."
  value       = var.vnet_id == null ? module.network[0] : null
}

output "vnet_id" {
  description = "The id of the newly created virtual network"
  value       = var.vnet_id == null ? null : var.vnet_id
}

output "nsg_ids" {
  description = "The resource ids of the network security groups created within this module."
  value       = var.vnet_id == null ? module.network[0].nsg_ids : null
}

output "route_table_id" {
  description = "The address space of the newly created virtual network"
  value       = var.vnet_id == null ? module.network[0].route_table_id : null
}

output "vnet_subnets" {
  description = "The ids of subnets created inside the newly created virtual network"
  value       = var.vnet_id == null ? module.network[0].vnet_subnets : null
}

output "node_pool_subnet_address_prefixes" {
  description = "The node pool subnet address prefixes."
  value       = { for nodepool_name, nodepool in local.node_pools : nodepool_name => nodepool.vnet_subnet_name != null ? var.vnet_id == null ? module.network[0].vnet_subnets[nodepool.vnet_subnet_name].address_prefixes : null : var.vnet_id == null ? module.network[0].vnet_subnets[nodepool_name].address_prefixes : null }
}

## Route Server ##

output "route_server_id" {
  description = "The ID of the Route Server."
  value       = var.vnet_id == null ? module.network[0].route_server_id : null
}

output "route_server_ip_addresses" {
  description = "The peer IP addresses of the Route Server. In other words, it is the private IPs of the route server."
  value       = var.vnet_id == null ? module.network[0].route_server_ip_addresses : null
}

output "route_server_public_ip_id" {
  description = "The ID of the public IP used by the route server"
  value       = var.vnet_id == null ? module.network[0].route_server_public_ip_id : null
}

###############
### Cluster ###
###############

output "infrastructure" {
  description = "The outputs of the environment_infrastructure module."
  value       = module.infrastructure
}

output "cluster_id" {
  description = "The id of the public IP used by the route server"
  value       = module.infrastructure.cluster_id
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = module.infrastructure.cluster_name
}

output "cluster_kubelet_identity" {
  description = "The identity details of the user-assigned managed indeity assigned to the cluster's kublets."
  value       = module.infrastructure.cluster_kubelet_identity
}

output "cluster_identity_object_id" {
  description = "The identity details of the managed identity assigned to the cluster."
  value       = module.infrastructure.cluster_identity_object_id
}

output "disk_encryption_key_vault_id" {
  description = "The Azure resource ID of the Key Vault used to store the customer managed encryption key for the AKS cluster."
  value       = module.infrastructure.disk_encryption_key_vault_id
}

output "cluster_kubeconfig" {
  description = "A Terraform object that contains kubeconfig info."
  value       = module.infrastructure.cluster_kubeconfig
}

###############################
### Platform Infrastructure ###
###############################

output "platform_infrastructure" {
  description = "The outputs of the platform_infrastructure module."
  value       = module.platform_infrastructure
}

## Identities ##

output "velero_identity_id" {
  description = "The Azure resource ID of the velero user-assigned managed identity."
  value       = module.platform_infrastructure.velero_identity_id
}

output "cert_manager_identity_id" {
  description = "The Azure resource ID of the cert-manager user-assigned managed identity."
  value       = module.platform_infrastructure.cert_manager_identity_id
}

output "cert_manager_identity_client_id" {
  description = "The Azure client ID of the cert-manager user-assigned managed identity."
  value       = module.platform_infrastructure.cert_manager_identity_client_id
}

output "argo_workflows_sso_sp" {
  description = "Azure service principal used for SSO when logging into Argo Workflows."
  value       = module.platform_infrastructure.argo_workflows_sso_sp
}

output "grafana_sso_sp" {
  description = "Azure service principal used for SSO when logging into Grafana."
  value       = module.platform_infrastructure.grafana_sso_sp
}

output "kubecost_sp" {
  description = "Azure service principal used to access accurate Microsoft Azure billing data."
  value       = module.platform_infrastructure.kubecost_sp
}

## Storage Accounts ##

output "velero_storage_account_id" {
  description = "The ID of the Velero storage account."
  value       = module.platform_infrastructure.velero_storage_account_id
}

output "argo_workflows_storage_account_id" {
  description = "The ID of the workflows storage account."
  value       = module.platform_infrastructure.argo_workflows_storage_account_id
}
