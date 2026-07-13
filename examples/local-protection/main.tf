################################################################################
# Local Protection Example
# This example demonstrates local data protection with hourly snapshots
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
  description = "Domain manager (Prism Central) external ID"
  type        = string
}

variable "cluster_ext_id" {
  description = "Cluster external ID for local protection"
  type        = string
}

################################################################################
# Module
################################################################################

module "pe" {
  source = "../../module"

  # Protection policies for local snapshots
  protection_policies = {
    hourly-local = {
      name        = "hourly-local-protection"
      description = "Hourly local snapshots with 24-hour retention"

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
            recovery_point_objective_time_seconds = 3600 # 1 hour

            retention = {
              linear_retention = {
                local_retention_count = 24 # Keep 24 hourly snapshots
              }
            }
          }
        }
      ]
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
