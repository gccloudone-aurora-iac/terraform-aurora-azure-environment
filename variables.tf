######################
### Azure Resource ###
######################

variable "azure_resource_attributes" {
  description = "Attributes used to describe Azure resources"
  type = object({
    department_code = string
    owner           = string
    project         = string
    environment     = string
    location        = optional(string, "Canada Central")
    instance        = number
  })
  nullable = false
}

variable "user_defined" {
  description = "A user-defined field that describes the Azure resource."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.user_defined) >= 2 && length(var.user_defined) <= 15
    error_message = "The user-defined field must be between 2-15 characters long."
  }
}

variable "naming_convention" {
  type        = string
  default     = "oss"
  description = "Sets which naming convention to use. Accepted values: oss, gc"
  validation {
    condition     = var.naming_convention == "oss" || var.naming_convention == "gc"
    error_message = "The naming_convention field must either be 'oss' or 'gc'."
  }
}

variable "service_principal_owners" {
  description = "The Azure identities that will be configured as owners of the created Azure service principals."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Azure tags to assign to the Azure resources"
  type        = map(string)
  default     = {}
}

####################
### Data Sources ###
####################

variable "data_sources" {
  description = "The Azure resource IDs of existing resources that are required by the module."
  type = object({
    dns_zone_id = object({
      azmk8s       = string
      cert_manager = string
      blob_storage = string
      keyvault     = string
    })
    active_directory = object({
      service_principal_id = object({
        cicd_runner          = string
        cluster_admins_owner = string
      })
      group_id = object({
        aurora_general_cluster_user = string
      })
      tenant_id       = string
      subscription_id = string
    })
  })
}

#######################
### Virtual Network ###
#######################

variable "vnet_id" {
  description = "The id of the virtual network."
  type        = string
  default     = null
}

variable "vnet_address_space" {
  description = "The address space for the virtual network."
  type        = list(string)
}

variable "vnet_peers" {
  description = "A list of remote virtual network resource IDs to use as virtual network peerings."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue(flatten([
      for resource_id in var.vnet_peers : [
        can(regex("^/subscriptions/(.+)/resourceGroups/(.+)/providers/Microsoft.Network/virtualNetworks/(.+)", resource_id))
      ]
    ]))

    error_message = "Each element within var.vnet_peers must be a valid Azure Virtual Network resource ID."
  }
}

variable "dns_servers" {
  description = "The DNS servers to be used with VNet. If no values specified, this defaults to Azure DNS."
  type        = list(string)
  default     = ["172.20.48.4", "172.20.48.5"]
}

variable "ddos_protection_plan_id" {
  description = "The DDoS protection plan resoruce id"
  type        = string
  default     = null
}


variable "subnet_ids" {
  description = "The subnet ids for the virtual network."
  type        = map(string)
  default     = null
}

variable "subnets" {
  description = "The environment specific subnets to create in the virtual network."
  type = map(object({
    address_prefixes = list(string)

    nsg_id     = optional(string)
    create_nsg = optional(bool, true)
    extra_nsg_rules = optional(list(object({
      name                                       = string
      description                                = string
      protocol                                   = string                 # Tcp, Udp, Icmp, Esp, Ah or *
      access                                     = string                 # Allow or Deny
      priority                                   = number                 # The value can be between 100 and 4096
      direction                                  = string                 # Inbound or Outbound
      source_port_range                          = optional(string)       # between 0 and 65535 or * to match any
      source_port_ranges                         = optional(list(string)) # required if source_port_range is not specified
      destination_port_range                     = optional(string)       # between 0 and 65535 or * to match any
      destination_port_ranges                    = optional(list(string)) # required if destination_port_range is not specified
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string)) # required if source_address_prefix is not specified.
      source_application_security_group_ids      = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string)) #  required if destination_address_prefix is not specified
      destination_application_security_group_ids = optional(list(string))
    })), [])

    route_table_id        = optional(string)
    associate_route_table = optional(bool, true)

    service_endpoints = optional(list(string))
    service_endpoint_policy_definitions = optional(list(object({ # No policy is created if unspecified
      name        = optional(string)
      description = optional(string)
      service     = optional(string, "Microsoft.Storage")
      scopes      = list(string)
    })))

    service_delegation_name                       = optional(string)
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
  }))

  validation {
    condition = var.subnets != null ? (
      can(keys(var.subnets)) && (
        contains(keys(var.subnets), "RouteServerSubnet", []) &&
        contains(keys(var.subnets), "loadbalancer", []) &&
        contains(keys(var.subnets), "gateway", []) &&
        contains(keys(var.subnets), "system", []) &&
        contains(keys(var.subnets), "general", []) &&
        contains(keys(var.subnets), "infrastructure", [])
      )
    ) : true
    error_message = "Each Cloud Native Platform virtual network must contain the RouteServerSubnet, loadbalancer, gateway, system, general and infrastructure subnet."
  }

  validation {
    condition = var.subnets != null ? alltrue(flatten([
      for subnet in var.subnets : [
        for address_prefix in subnet.address_prefixes : [
          can(cidrhost(address_prefix, 0))
        ]
      ]
    ])) : true
    error_message = "The argument address_prefixes must be written in CIDR notation."
  }
}

variable "route_table_next_hop_ip_address" {
  description = "The next hop ip address to add to the standard route table."
  type        = string
}

variable "extra_route_table_rules" {
  description = "The environment specific security rules to add to the standard route table."
  type        = list(string)
  default     = []
}

### Route Server ###

variable "route_server_bgp_peers" {
  description = "The details for creating BGP peer(s) within the route server."
  type = list(object({
    name     = string
    peer_asn = number
    peer_ip  = string
  }))
}

##################################
### AKS Cluster Infrastructure ###
##################################

variable "kubernetes_version" {
  description = "The Kubernetes version used by the control plane & the default version for the agent nodes."
  type        = string
}

variable "cluster_sku_tier" {
  description = "The SKU of the AKS cluster."
  type        = string
}

variable "cluster_admins" {
  description = "A list of Object IDs of Azure Active Directory groups or users which should have Admin Role on the Cluster."
  type        = list(string)
  default     = []
}

variable "cluster_linux_profile_ssh_key" {
  description = "SSH public key to access cluster nodes"
  type        = string
  default     = null
}

variable "node_os_upgrade_channel" {
  description = "The upgrade channel for this Kubernetes Cluster Nodes' OS Image. Possible values are Unmanaged, SecurityPatch, NodeImage and None."
  type        = string
  default     = "NodeImage"
}

variable "custom_ca" {
  description = "Configure a custom Certificate Authority (CA) for the Cluster"
  type        = string
  default     = null
}

### Node Pools ###

variable "node_pools" {
  description = "Node Pools along with their respective configurations."
  type = map(
    object({
      vm_size                = string
      vnet_subnet_name       = optional(string)
      availability_zones     = optional(list(number))
      node_count             = optional(number)
      kubernetes_version     = optional(string)
      node_labels            = optional(map(string))
      node_taints            = optional(list(string))
      max_pods               = optional(number)
      enable_host_encryption = optional(bool)
      os_disk_size_gb        = optional(number)
      os_disk_type           = optional(string)
      os_type                = optional(string)
      vm_priority            = optional(string)
      eviction_policy        = optional(string)
      spot_max_price         = optional(string)

      upgrade_settings = optional(object({
        max_surge                     = optional(string, "33%")
        drain_timeout_in_minutes      = optional(number, 30)
        node_soak_duration_in_minutes = optional(number, 0)
      }), null)

      enable_auto_scaling    = optional(bool)
      auto_scaling_min_nodes = optional(number)
      auto_scaling_max_nodes = optional(number)
      mode                   = optional(string)
    })
  )
}

###############################
### Platform Infrastructure ###
###############################

variable "grafana_sp" {
  description = "Settings for the Grafana SSO service principal."
  type = object({
    members = object({
      viewer = optional(map(string), {})
      editor = optional(map(string), {})
      admin  = map(string)
    })
  })
  default = {
    members = {
      viewer = {}
      editor = {}
      admin  = {}
    }
  }
}
