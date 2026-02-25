data "azuread_group" "cluster_admins" {
  count     = var.cluster_admins_group_object_id != null ? 1 : 0
  object_id = var.cluster_admins_group_object_id
}
