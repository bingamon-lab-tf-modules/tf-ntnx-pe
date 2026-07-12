################################################################################
# Remote Replication Example
# This example demonstrates cross-site replication for disaster recovery
################################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = ">= 2.4.2"
    }
  }
}

provider "nutanix" {
  username = var.nutanix_username
  password = var.nutanix_password
  endpoint = var.nutanix_endpoint
  insecure = true
  port     = 9440
}

################################################################################
# Variables
################################################################################

variable "nutanix_username" {
  description = "Nutanix Prism Central username"
  type        = string
}

variable "nutanix_password" {
  description = "Nutanix Prism Central password"
  type        = string
  sensitive   = true
}

variable "nutanix_endpoint" {
  description = "Nutanix Prism Central endpoint"
  type        = string
}

variable "primary_domain_manager_ext_id" {
  description = "Primary site domain manager external ID"
  type        = string
}

variable "primary_cluster_ext_id" {
  description = "Primary cluster external ID"
  type        = string
}

variable "dr_domain_manager_ext_id" {
  description = "DR site domain manager external ID"
  type        = string
}

variable "dr_cluster_ext_id" {
  description = "DR cluster external ID"
  type        = string
}

################################################################################
# Module
################################################################################

module "pe" {
  source = "../../module"

  # Protection policy with remote replication
  protection_policies = {
    cross-site-dr = {
      name        = "cross-site-dr-replication"
      description = "Cross-site replication for disaster recovery"

      replication_locations = [
        {
          label                 = "primary"
          domain_manager_ext_id = var.primary_domain_manager_ext_id
          is_primary            = true

          replication_sub_location = {
            cluster_ext_ids = [var.primary_cluster_ext_id]
          }
        },
        {
          label                 = "dr-site"
          domain_manager_ext_id = var.dr_domain_manager_ext_id
          is_primary            = false

          replication_sub_location = {
            cluster_ext_ids = [var.dr_cluster_ext_id]
          }
        }
      ]

      replication_configurations = [
        {
          source_location_label = "primary"
          remote_location_label = "dr-site"

          schedule = {
            recovery_point_type                   = "CRASH_CONSISTENT"
            recovery_point_objective_time_seconds = 3600 # 1 hour RPO

            retention = {
              linear_retention = {
                local_retention_count  = 24 # 24 local snapshots
                remote_retention_count = 48 # 48 remote snapshots
              }
            }
          }
        }
      ]
    }
  }

  # Protection rules for category-based protection
  protection_rules = {
    production-vms = {
      name        = "protect-production-vms"
      description = "Protection rule for production VMs"

      ordered_availability_zone_list = [
        {
          cluster_uuid = var.primary_cluster_ext_id
        },
        {
          cluster_uuid = var.dr_cluster_ext_id
        }
      ]

      availability_zone_connectivity_list = [
        {
          source_availability_zone_index      = 0
          destination_availability_zone_index = 1

          snapshot_schedule_list = [
            {
              recovery_point_objective_secs = 3600
              snapshot_type                 = "CRASH_CONSISTENT"

              local_snapshot_retention_policy = {
                num_snapshots = 24
              }

              remote_snapshot_retention_policy = {
                num_snapshots = 48
              }
            }
          ]
        }
      ]

      category_filter = {
        type      = "CATEGORIES_MATCH_ALL"
        kind_list = ["vm"]

        params = [
          {
            name   = "Environment"
            values = ["Production"]
          }
        ]
      }
    }
  }
}

################################################################################
# Outputs
################################################################################

output "protection_policies" {
  description = "Created protection policies"
  value       = module.pe.protection_policies
}

output "protection_policy_ids" {
  description = "Created protection policy IDs"
  value       = module.pe.protection_policy_ids
}

output "protection_rules" {
  description = "Created protection rules"
  value       = module.pe.protection_rules
}

output "protection_rule_ids" {
  description = "Created protection rule IDs"
  value       = module.pe.protection_rule_ids
}
