variable "enable_data_lookups" {
  description = "Enable data source lookups for existing resources"
  type        = bool
  default     = false
}

variable "protection_policies" {
  description = "Map of protection policies (v2) to create"
  type = map(object({
    name        = string
    description = optional(string)
    replication_configurations = optional(list(object({
      source_location_label = string
      remote_location_label = optional(string)
      schedule = object({
        recovery_point_objective_time_seconds         = number
        recovery_point_type                           = optional(string) # CRASH_CONSISTENT or APP_CONSISTENT
        sync_replication_auto_suspend_timeout_seconds = optional(number)
        start_time                                    = optional(string)
        retention = optional(object({
          linear_retention = optional(object({
            local_retention_count  = optional(number)
            remote_retention_count = optional(number)
          }))
          auto_rollup_retention = optional(object({
            local_snapshot_interval_type  = optional(string)
            local_snapshot_frequency      = optional(number)
            remote_snapshot_interval_type = optional(string)
            remote_snapshot_frequency     = optional(number)
          }))
        }))
      })
    })), [])
    replication_locations = optional(list(object({
      label                 = string
      domain_manager_ext_id = string
      is_primary            = optional(bool, false)
      replication_sub_location = optional(object({
        cluster_ext_ids = optional(list(string), [])
      }))
    })), [])
    category_ids = optional(list(string), [])
  }))
  default = {}
}

variable "protection_rules" {
  description = "Map of protection rules (v1) to create"
  type = map(object({
    name        = string
    description = string
    ordered_availability_zone_list = optional(list(object({
      cluster_uuid          = optional(string)
      availability_zone_url = optional(string)
    })), [])
    availability_zone_connectivity_list = optional(list(object({
      destination_availability_zone_index = optional(number)
      source_availability_zone_index      = optional(number)
      snapshot_schedule_list = optional(list(object({
        recovery_point_objective_secs = number
        snapshot_type                 = optional(string) # CRASH_CONSISTENT or APP_CONSISTENT
        local_snapshot_retention_policy = optional(object({
          num_snapshots                                  = optional(number)
          rollup_retention_policy_multiple               = optional(number)
          rollup_retention_policy_snapshot_interval_type = optional(string)
        }))
        auto_suspend_timeout_secs = optional(number)
        remote_snapshot_retention_policy = optional(object({
          num_snapshots                                  = optional(number)
          rollup_retention_policy_multiple               = optional(number)
          rollup_retention_policy_snapshot_interval_type = optional(string)
        }))
      })), [])
    })), [])
    category_filter = optional(object({
      type      = optional(string)
      kind_list = optional(list(string), [])
      params = optional(list(object({
        name   = string
        values = list(string)
      })), [])
    }))
  }))
  default = {}
}

variable "recovery_plans" {
  description = "Map of recovery plans (v1) to create"
  type = map(object({
    name        = string
    description = string
    stage_list = optional(list(object({
      stage_uuid      = optional(string)
      delay_time_secs = optional(number)
      stage_work = optional(object({
        recover_entities = optional(object({
          entity_info_list = optional(list(object({
            categories = optional(object({
              name  = optional(string)
              value = optional(string)
            }))
            any_entity_reference_kind = optional(string)
            any_entity_reference_uuid = optional(string)
            any_entity_reference_name = optional(string)
          })), [])
        }))
      }))
    })), [])
    parameters = optional(object({
      network_mapping_list = optional(list(object({
        availability_zone_network_mapping_list = optional(list(object({
          recovery_network = optional(object({
            name = optional(string)
            uuid = optional(string)
          }))
          test_network = optional(object({
            name = optional(string)
            uuid = optional(string)
          }))
          availability_zone_url = optional(string)
        })), [])
      })), [])
      floating_ip_assignment_list = optional(list(object({
        vm_uuid = optional(string)
        test_floating_ip_config = optional(object({
          ip                          = optional(string)
          should_allocate_dynamically = optional(bool)
        }))
        recovery_floating_ip_config = optional(object({
          ip                          = optional(string)
          should_allocate_dynamically = optional(bool)
        }))
      })), [])
    }))
  }))
  default = {}
}

variable "recovery_points" {
  description = "Map of recovery points (v2) to create"
  type = map(object({
    name                = optional(string)
    expiration_time     = optional(string)
    status              = optional(string, "COMPLETE")
    recovery_point_type = optional(string) # CRASH_CONSISTENT or APPLICATION_CONSISTENT
    vm_recovery_points = optional(list(object({
      vm_ext_id           = string
      name                = optional(string)
      expiration_time     = optional(string)
      status              = optional(string, "COMPLETE")
      recovery_point_type = optional(string)
    })), [])
    volume_group_recovery_points = optional(list(object({
      volume_group_ext_id = string
      name                = optional(string)
      expiration_time     = optional(string)
      status              = optional(string, "COMPLETE")
      recovery_point_type = optional(string)
    })), [])
  }))
  default = {}
}

variable "recovery_point_replicates" {
  description = "Map of recovery point replicate operations (v2)"
  type = map(object({
    ext_id         = string
    cluster_ext_id = optional(string)
    pc_ext_id      = optional(string)
  }))
  default = {}
}

variable "recovery_point_restores" {
  description = "Map of recovery point restore operations (v2)"
  type = map(object({
    ext_id         = string
    cluster_ext_id = optional(string)
  }))
  default = {}
}

variable "restore_protected_resources" {
  description = "Map of restore protected resource operations (v2)"
  type = map(object({
    ext_id         = string
    cluster_ext_id = optional(string)
  }))
  default = {}
}

variable "promote_protected_resources" {
  description = "Map of promote protected resource operations (v2)"
  type = map(object({
    ext_id = string
  }))
  default = {}
}
