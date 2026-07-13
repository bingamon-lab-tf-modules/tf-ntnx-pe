################################################################################
# Recovery Plan Example
# This example demonstrates DR recovery plan configuration
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

variable "primary_availability_zone_url" {
  description = "Primary availability zone URL"
  type        = string
}

variable "dr_availability_zone_url" {
  description = "DR availability zone URL"
  type        = string
}

variable "primary_subnet_uuid" {
  description = "Primary site subnet UUID"
  type        = string
}

variable "dr_subnet_uuid" {
  description = "DR site subnet UUID"
  type        = string
}

################################################################################
# Module
################################################################################

module "pe" {
  source = "../../module"

  # Recovery plan for DR failover
  recovery_plans = {
    app-tier-recovery = {
      name        = "application-tier-recovery"
      description = "Recovery plan for application tier VMs"

      # Stage list defines recovery order
      stage_list = [
        {
          delay_time_secs = 0

          stage_work = {
            recover_entities = {
              entity_info_list = [
                {
                  # Recover database tier first
                  categories = {
                    name  = "AppTier"
                    value = "Database"
                  }
                }
              ]
            }
          }
        },
        {
          delay_time_secs = 60 # Wait 60 seconds before next stage

          stage_work = {
            recover_entities = {
              entity_info_list = [
                {
                  # Then recover application tier
                  categories = {
                    name  = "AppTier"
                    value = "Application"
                  }
                }
              ]
            }
          }
        },
        {
          delay_time_secs = 30

          stage_work = {
            recover_entities = {
              entity_info_list = [
                {
                  # Finally recover web tier
                  categories = {
                    name  = "AppTier"
                    value = "Web"
                  }
                }
              ]
            }
          }
        }
      ]

      # Network mappings for failover
      parameters = {
        network_mapping_list = [
          {
            availability_zone_network_mapping_list = [
              {
                availability_zone_url = var.primary_availability_zone_url

                recovery_network = {
                  name = "primary-network"
                  uuid = var.primary_subnet_uuid
                }
              },
              {
                availability_zone_url = var.dr_availability_zone_url

                recovery_network = {
                  name = "dr-network"
                  uuid = var.dr_subnet_uuid
                }
              }
            ]
          }
        ]
      }
    }
  }
}

################################################################################
# Outputs
################################################################################

output "recovery_plans" {
  description = "Created recovery plans"
  value       = module.pe.recovery_plans
}

output "recovery_plan_ids" {
  description = "Created recovery plan IDs"
  value       = module.pe.recovery_plan_ids
}
