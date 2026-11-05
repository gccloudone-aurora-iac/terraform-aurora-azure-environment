# Configures the PIM for the cluster_admins AAD group
# Requires the RoleManagementPolicy.ReadWrite.AzureADGroup Microsoft Graph API permissions.
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group_role_management_policy
#
resource "azuread_group_role_management_policy" "cluster_admins_member" {
  group_id = local.cluster_admins_group_id
  role_id  = "member"

  activation_rules {
    maximum_duration      = "PT8H"
    require_justification = true
    require_ticket_info   = false

    require_approval = var.pim_approvers != null

    require_multifactor_authentication = true

    dynamic "approval_stage" {
      for_each = var.pim_approvers == null ? [] : [var.pim_approvers]
      content {
        primary_approver {
          object_id = approval_stage.value
          type      = "groupMembers"
        }
      }
    }
  }

  eligible_assignment_rules {
    expiration_required = true
    expire_after        = "P365D"
  }

  active_assignment_rules {
    expiration_required                = true
    expire_after                       = "P15D"
    require_justification              = true
    require_multifactor_authentication = true
  }

  notification_rules {
    eligible_activations {
      admin_notifications {
        notification_level    = "All"
        default_recipients    = true
        additional_recipients = var.pim_notification_recipients
      }
      approver_notifications {
        notification_level    = "All"
        default_recipients    = true
        additional_recipients = []
      }
      assignee_notifications {
        notification_level    = "All"
        default_recipients    = true
        additional_recipients = []
      }
    }
    active_assignments {
      admin_notifications {
        notification_level    = "All"
        default_recipients    = true
        additional_recipients = var.pim_notification_recipients
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.pim_approvers != local.cluster_admins_group_id
      error_message = "The PIM approver group must not be the cluster admins group"
    }
  }
}

# Configures who can be eligible for PIM activation
#
# Requires the PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup Microsoft Graph API permissions.
#
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/privileged_access_group_eligibility_schedule
#
resource "azuread_privileged_access_group_eligibility_schedule" "cluster_admins" {
  for_each = toset(var.cluster_admins)

  group_id        = local.cluster_admins_group_id
  principal_id    = each.value
  assignment_type = "member"
  duration        = "P365D"
  justification   = "Eligible for AKS cluster-admin via PIM (managed by Terraform)"

  depends_on = [azuread_group_role_management_policy.cluster_admins_member]
}