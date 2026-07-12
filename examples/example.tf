################################################################################
# tf-ntnx-pe — Example
#
# Demonstrates the three core protection and recovery building blocks together:
#   * a local protection policy with an asynchronous hourly schedule
#   * a recovery point capturing a single VM
#   * a recovery plan (v1) with an ordered stage list
#
# Scenario-specific variations live alongside this file:
#   * ./local-protection    — local snapshots only
#   * ./remote-replication  — cross-site replication
#   * ./recovery-plan       — multi-stage DR failover
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

variable "domain_manager_ext_id" {
  description = "Domain manager (Prism Central) external ID hosting the protected cluster"
  type        = string
}

variable "cluster_ext_id" {
  description = "Cluster external ID for local protection"
  type        = string
}

variable "protected_vm_ext_id" {
  description = "External ID of the VM to capture in the recovery point"
  type        = string
}

################################################################################
# Module
################################################################################

module "pe" {
  source = "git::https://github.com/bingamon-lab-tf-modules/tf-ntnx-pe.git//module?ref=v0.1.0"

  # One local protection policy — asynchronous hourly schedule (RPO 3600s),
  # 24-hour linear retention.
  protection_policies = {
    hourly_local = {
      name        = "hourly-local-protection"
      description = "Hourly local snapshots with 24-hour linear retention"

      replication_locations = [
        {
          label                 = "primary"
          domain_manager_ext_id = var.domain_manager_ext_id
          is_primary            = true

          replication_sub_location = {
            cluster_ext_ids = [var.cluster_ext_id]
          }
        }
      ]

      replication_configurations = [
        {
          source_location_label = "primary"

          schedule = {
            recovery_point_type                   = "CRASH_CONSISTENT"
            recovery_point_objective_time_seconds = 3600 # 1 hour (asynchronous)

            retention = {
              linear_retention = {
                local_retention_count = 24 # keep 24 hourly snapshots
              }
            }
          }
        }
      ]
    }
  }

  # One recovery point capturing a single VM.
  recovery_points = {
    app_vm = {
      name                = "app-vm-recovery-point"
      recovery_point_type = "CRASH_CONSISTENT"

      vm_recovery_points = [
        {
          vm_ext_id = var.protected_vm_ext_id
        }
      ]
    }
  }

  # One recovery plan (v1) with an ordered stage list.
  recovery_plans = {
    app_tier = {
      name        = "application-tier-recovery"
      description = "Recover the application tier VMs in a single ordered stage"

      stage_list = [
        {
          delay_time_secs = 0

          stage_work = {
            recover_entities = {
              entity_info_list = [
                {
                  categories = {
                    name  = "AppTier"
                    value = "Database"
                  }
                }
              ]
            }
          }
        }
      ]

      # parameters is required by the provider (min 1 block). Network mappings
      # are environment-specific; see ./recovery-plan for a full failover map.
      parameters = {}
    }
  }
}

################################################################################
# Outputs
################################################################################

output "protection_policy_ids" {
  description = "Created protection policy IDs"
  value       = module.pe.protection_policy_ids
}

output "recovery_point_ids" {
  description = "Created recovery point external IDs"
  value       = module.pe.recovery_point_ids
}

output "recovery_plan_ids" {
  description = "Created recovery plan IDs"
  value       = module.pe.recovery_plan_ids
}
