# terraform-aurora-azure-environment

Manages the Cloud Native Environment.

## Usage

Examples for this module along with various configurations can be found in the [examples/](examples/) folder.

## Architectural Diagram

![CNP Architectural Diagram](assets/images/architectural-diagram.svg)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 3.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.26.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 3.3.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.26.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_argo_workflow_sso_sp"></a> [argo\_workflow\_sso\_sp](#module\_argo\_workflow\_sso\_sp) | git::https://github.com/gccloudone-aurora-iac/terraform-azure-service-principal.git | v2.0.0 |
| <a name="module_azure_resource_names"></a> [azure\_resource\_names](#module\_azure\_resource\_names) | git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-resource-names.git | v2.0.0 |
| <a name="module_grafana_azuread_oauth_sp"></a> [grafana\_azuread\_oauth\_sp](#module\_grafana\_azuread\_oauth\_sp) | git::https://github.com/gccloudone-aurora-iac/terraform-azure-service-principal.git | v2.0.0 |
| <a name="module_infrastructure"></a> [infrastructure](#module\_infrastructure) | git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-infrastructure.git | v2.0.0 |
| <a name="module_kubecost_sp"></a> [kubecost\_sp](#module\_kubecost\_sp) | git::https://github.com/gccloudone-aurora-iac/terraform-azure-service-principal.git | v2.0.0 |
| <a name="module_network"></a> [network](#module\_network) | git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-network.git | v2.0.1 |
| <a name="module_platform_infrastructure"></a> [platform\_infrastructure](#module\_platform\_infrastructure) | git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-platform-infrastructure.git | v2.0.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd_keyvault_id"></a> [argocd\_keyvault\_id](#input\_argocd\_keyvault\_id) | The Azure resource ID of the Azure Key Vault which contains the ArgoCD secrets. | `string` | n/a | yes |
| <a name="input_azure_resource_attributes"></a> [azure\_resource\_attributes](#input\_azure\_resource\_attributes) | Attributes used to describe Azure resources | <pre>object({<br>    project     = string<br>    environment = string<br>    location    = optional(string, "Canada Central")<br>    instance    = number<br>  })</pre> | n/a | yes |
| <a name="input_cluster_sku_tier"></a> [cluster\_sku\_tier](#input\_cluster\_sku\_tier) | The SKU of the AKS cluster. | `string` | n/a | yes |
| <a name="input_data_sources"></a> [data\_sources](#input\_data\_sources) | n/a | <pre>object({<br>    dns_zone_id = object({<br>      cloud_aurora_ca = string<br>      azmk8s           = string<br>      blob_storage     = string<br>      keyvault         = string<br>    })<br>    active_directory = object({<br>      service_principal_id = object({<br>        cicd_runner = string<br>      })<br>      tenant_id       = string<br>      subscription_id = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | The Kubernetes version used by the control plane & the default version for the agent nodes. | `string` | n/a | yes |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Node Pools along with their respective configurations. | <pre>map(<br>    object({<br>      vm_size                = string<br>      availability_zones     = optional(list(number))<br>      node_count             = optional(number)<br>      kubernetes_version     = optional(string)<br>      node_labels            = optional(map(string))<br>      node_taints            = optional(list(string))<br>      max_pods               = optional(number)<br>      enable_host_encryption = optional(bool)<br>      os_disk_size_gb        = optional(number)<br>      os_disk_type           = optional(string)<br>      os_type                = optional(string)<br>      vm_priority            = optional(string)<br>      eviction_policy        = optional(string)<br>      spot_max_price         = optional(string)<br>      upgrade_max_surge      = optional(string)<br>      enable_auto_scaling    = optional(bool)<br>      auto_scaling_min_nodes = optional(number)<br>      auto_scaling_max_nodes = optional(number)<br>    })<br>  )</pre> | n/a | yes |
| <a name="input_route_server_bgp_peers"></a> [route\_server\_bgp\_peers](#input\_route\_server\_bgp\_peers) | The details for creating BGP peer(s) within the route server. | <pre>list(object({<br>    name     = string<br>    peer_asn = number<br>    peer_ip  = string<br>  }))</pre> | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | The environment specific subnets to create in the virtual network. | <pre>map(object({<br>    address_prefixes = list(string)<br><br>    nsg_id     = optional(string)<br>    create_nsg = optional(bool, true)<br>    extra_nsg_rules = optional(list(object({<br>      name                                       = string<br>      description                                = string<br>      protocol                                   = string                 # Tcp, Udp, Icmp, Esp, Ah or *<br>      access                                     = string                 # Allow or Deny<br>      priority                                   = number                 # The value can be between 100 and 4096<br>      direction                                  = string                 # Inbound or Outbound<br>      source_port_range                          = optional(string)       # between 0 and 65535 or * to match any<br>      source_port_ranges                         = optional(list(string)) # required if source_port_range is not specified<br>      destination_port_range                     = optional(string)       # between 0 and 65535 or * to match any<br>      destination_port_ranges                    = optional(list(string)) # required if destination_port_range is not specified<br>      source_address_prefix                      = optional(string)<br>      source_address_prefixes                    = optional(list(string)) # required if source_address_prefix is not specified.<br>      source_application_security_group_ids      = optional(list(string))<br>      destination_address_prefix                 = optional(string)<br>      destination_address_prefixes               = optional(list(string)) #  required if destination_address_prefix is not specified<br>      destination_application_security_group_ids = optional(list(string))<br>    })), [])<br><br>    route_table_id        = optional(string)<br>    associate_route_table = optional(bool, true)<br><br>    service_endpoints                             = optional(list(string))<br>    service_delegation_name                       = optional(string)<br>    private_endpoint_network_policies_enabled     = optional(bool, true)<br>    private_link_service_network_policies_enabled = optional(bool, true)<br>  }))</pre> | n/a | yes |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | The address space for the virtual network. | `list(string)` | n/a | yes |
| <a name="input_cluster_admins"></a> [cluster\_admins](#input\_cluster\_admins) | A list of Object IDs of Azure Active Directory groups or users which should have Admin Role on the Cluster. | `list(string)` | `[]` | no |
| <a name="input_cluster_linux_profile_ssh_key"></a> [cluster\_linux\_profile\_ssh\_key](#input\_cluster\_linux\_profile\_ssh\_key) | SSH public key to access cluster nodes | `string` | `null` | no |
| <a name="input_ddos_protection_plan_id"></a> [ddos\_protection\_plan\_id](#input\_ddos\_protection\_plan\_id) | The DDoS protection plan resoruce id | `string` | `null` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | The DNS servers to be used with VNet. If no values specified, this defaults to Azure DNS. | `list(string)` | <pre>[<br>  "172.20.48.4",<br>  "172.20.48.5"<br>]</pre> | no |
| <a name="input_extra_route_table_rules"></a> [extra\_route\_table\_rules](#input\_extra\_route\_table\_rules) | The environment specific security rules to add to the standard route table. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Azure tags to assign to the Azure resources | `map(string)` | `{}` | no |
| <a name="input_vnet_peers"></a> [vnet\_peers](#input\_vnet\_peers) | A list of remote virtual network resource IDs to use as virtual network peerings. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_resource_group_id"></a> [backup\_resource\_group\_id](#output\_backup\_resource\_group\_id) | The name of the backup resource group. |
| <a name="output_cert_manager_identity_id"></a> [cert\_manager\_identity\_id](#output\_cert\_manager\_identity\_id) | The Azure resource ID of the cert-manager user-assigned managed identity. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The id of the public IP used by the route server |
| <a name="output_cluster_identity_object_id"></a> [cluster\_identity\_object\_id](#output\_cluster\_identity\_object\_id) | The identity details of the managed identity assigned to the cluster. |
| <a name="output_cluster_kubeconfig"></a> [cluster\_kubeconfig](#output\_cluster\_kubeconfig) | A Terraform object that contains kubeconfig info. |
| <a name="output_cluster_kubelet_identity"></a> [cluster\_kubelet\_identity](#output\_cluster\_kubelet\_identity) | The identity details of the user-assigned managed indeity assigned to the cluster's kublets. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the AKS cluster. |
| <a name="output_cluster_node_resource_group_id"></a> [cluster\_node\_resource\_group\_id](#output\_cluster\_node\_resource\_group\_id) | The resource group name that the created AKS cluster is in. |
| <a name="output_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#output\_cluster\_resource\_group\_id) | The resource group name that the created AKS cluster is in. |
| <a name="output_disk_encryption_key_vault_id"></a> [disk\_encryption\_key\_vault\_id](#output\_disk\_encryption\_key\_vault\_id) | The Azure resource ID of the Key Vault used to store the customer managed encryption key for the AKS cluster. |
| <a name="output_network_resource_group_id"></a> [network\_resource\_group\_id](#output\_network\_resource\_group\_id) | The id of the network resource group created. |
| <a name="output_node_pool_subnet_address_prefixes"></a> [node\_pool\_subnet\_address\_prefixes](#output\_node\_pool\_subnet\_address\_prefixes) | The node pool subnet address prefixes. |
| <a name="output_nsg_ids"></a> [nsg\_ids](#output\_nsg\_ids) | The resource ids of the network security groups created within this module. |
| <a name="output_platform_resource_group_id"></a> [platform\_resource\_group\_id](#output\_platform\_resource\_group\_id) | The name of the platform resource group. |
| <a name="output_platform_workflows_storage_account_id"></a> [platform\_workflows\_storage\_account\_id](#output\_platform\_workflows\_storage\_account\_id) | The ID of the workflows storage account. |
| <a name="output_route_server_id"></a> [route\_server\_id](#output\_route\_server\_id) | The ID of the Route Server. |
| <a name="output_route_server_ip_addresses"></a> [route\_server\_ip\_addresses](#output\_route\_server\_ip\_addresses) | The peer IP addresses of the Route Server. In other words, it is the private IPs of the route server. |
| <a name="output_route_server_public_ip_id"></a> [route\_server\_public\_ip\_id](#output\_route\_server\_public\_ip\_id) | The ID of the public IP used by the route server |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | The address space of the newly created virtual network |
| <a name="output_vault_identity_id"></a> [vault\_identity\_id](#output\_vault\_identity\_id) | The Azure resource ID of the Hashicorp Vault user-assigned managed identity. |
| <a name="output_velero_identity_id"></a> [velero\_identity\_id](#output\_velero\_identity\_id) | The Azure resource ID of the velero user-assigned managed identity. |
| <a name="output_velero_storage_account_id"></a> [velero\_storage\_account\_id](#output\_velero\_storage\_account\_id) | The ID of the Velero storage account. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | The id of the newly created virtual network |
| <a name="output_vnet_subnets"></a> [vnet\_subnets](#output\_vnet\_subnets) | The ids of subnets created inside the newly created virtual network |
<!-- END_TF_DOCS -->

## History

| Date       | Release | Change                                                                              |
| ---------- | ------- | ----------------------------------------------------------------------------------- |
| 2025-01-25 | v1.0.0  | initial commit                                                                      |
| 2025-10-08 | v2.0.1  | Uncomment custom velero role                                                        |
| 2025-10-20 | v2.0.2  | Add variable `cluster_support_plan`                                                 |
| 2025-10-20 | v2.0.3  | Pin minimum version of azurerm to 4.49.0                                            |
