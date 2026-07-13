resource "nutanix_protection_policy_v2" "policy" {
  for_each = var.protection_policies

  name        = each.value.name
  description = each.value.description

  dynamic "replication_configurations" {
    for_each = each.value.replication_configurations != null ? each.value.replication_configurations : []
    content {
      source_location_label = replication_configurations.value.source_location_label
      remote_location_label = replication_configurations.value.remote_location_label

      schedule {
        recovery_point_objective_time_seconds         = replication_configurations.value.schedule.recovery_point_objective_time_seconds
        recovery_point_type                           = replication_configurations.value.schedule.recovery_point_type
        sync_replication_auto_suspend_timeout_seconds = replication_configurations.value.schedule.sync_replication_auto_suspend_timeout_seconds
        start_time                                    = replication_configurations.value.schedule.start_time

        dynamic "retention" {
          for_each = replication_configurations.value.schedule.retention != null ? [replication_configurations.value.schedule.retention] : []
          content {
            dynamic "linear_retention" {
              for_each = retention.value.linear_retention != null ? [retention.value.linear_retention] : []
              content {
                # TODO: local_retention_count is not supported in nutanix provider 2.3.1. Use 'local' instead.
                # local_retention_count  = linear_retention.value.local_retention_count
                local = linear_retention.value.local_retention_count
                # TODO: remote_retention_count is not supported in nutanix provider 2.3.1. Use 'remote' instead.
                # remote_retention_count = linear_retention.value.remote_retention_count
                remote = linear_retention.value.remote_retention_count
              }
            }

            dynamic "auto_rollup_retention" {
              for_each = retention.value.auto_rollup_retention != null ? [retention.value.auto_rollup_retention] : []
              content {
                # TODO: local_snapshot_interval_type and local_snapshot_frequency are not supported as flat arguments in nutanix provider 2.3.1.
                # Use nested 'local' block with 'snapshot_interval_type' and 'frequency' instead.
                # local_snapshot_interval_type  = auto_rollup_retention.value.local_snapshot_interval_type
                # local_snapshot_frequency      = auto_rollup_retention.value.local_snapshot_frequency
                local {
                  snapshot_interval_type = auto_rollup_retention.value.local_snapshot_interval_type
                  frequency              = auto_rollup_retention.value.local_snapshot_frequency
                }
                # TODO: remote_snapshot_interval_type and remote_snapshot_frequency are not supported as flat arguments in nutanix provider 2.3.1.
                # Use nested 'remote' block with 'snapshot_interval_type' and 'frequency' instead.
                # remote_snapshot_interval_type = auto_rollup_retention.value.remote_snapshot_interval_type
                # remote_snapshot_frequency     = auto_rollup_retention.value.remote_snapshot_frequency
                remote {
                  snapshot_interval_type = auto_rollup_retention.value.remote_snapshot_interval_type
                  frequency              = auto_rollup_retention.value.remote_snapshot_frequency
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "replication_locations" {
    for_each = each.value.replication_locations != null ? each.value.replication_locations : []
    content {
      label                 = replication_locations.value.label
      domain_manager_ext_id = replication_locations.value.domain_manager_ext_id
      is_primary            = replication_locations.value.is_primary

      dynamic "replication_sub_location" {
        for_each = replication_locations.value.replication_sub_location != null ? [replication_locations.value.replication_sub_location] : []
        content {
          # TODO: cluster_ext_ids as a flat attribute is not supported in nutanix provider 2.3.1.
          # Use nested 'cluster_ext_ids' block with 'cluster_ext_ids' list instead.
          # cluster_ext_ids = replication_sub_location.value.cluster_ext_ids
          cluster_ext_ids {
            cluster_ext_ids = replication_sub_location.value.cluster_ext_ids
          }
        }
      }
    }
  }

  category_ids = each.value.category_ids
}

resource "nutanix_recovery_plan" "plan" {
  for_each = var.recovery_plans

  name        = each.value.name
  description = each.value.description

  dynamic "stage_list" {
    for_each = each.value.stage_list != null ? each.value.stage_list : []
    content {
      stage_uuid      = stage_list.value.stage_uuid
      delay_time_secs = stage_list.value.delay_time_secs

      dynamic "stage_work" {
        for_each = stage_list.value.stage_work != null ? [stage_list.value.stage_work] : []
        content {
          dynamic "recover_entities" {
            for_each = stage_work.value.recover_entities != null ? [stage_work.value.recover_entities] : []
            content {
              dynamic "entity_info_list" {
                for_each = recover_entities.value.entity_info_list != null ? recover_entities.value.entity_info_list : []
                content {
                  dynamic "categories" {
                    for_each = entity_info_list.value.categories != null ? [entity_info_list.value.categories] : []
                    content {
                      name  = categories.value.name
                      value = categories.value.value
                    }
                  }
                  any_entity_reference_kind = entity_info_list.value.any_entity_reference_kind
                  any_entity_reference_uuid = entity_info_list.value.any_entity_reference_uuid
                  any_entity_reference_name = entity_info_list.value.any_entity_reference_name
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "parameters" {
    for_each = each.value.parameters != null ? [each.value.parameters] : []
    content {
      dynamic "network_mapping_list" {
        for_each = parameters.value.network_mapping_list != null ? parameters.value.network_mapping_list : []
        content {
          dynamic "availability_zone_network_mapping_list" {
            for_each = network_mapping_list.value.availability_zone_network_mapping_list != null ? network_mapping_list.value.availability_zone_network_mapping_list : []
            content {
              dynamic "recovery_network" {
                for_each = availability_zone_network_mapping_list.value.recovery_network != null ? [availability_zone_network_mapping_list.value.recovery_network] : []
                content {
                  name = recovery_network.value.name
                  # TODO: 'uuid' is not supported as a direct argument on recovery_network in nutanix provider 2.3.1.
                  # Use 'virtual_network_reference' block instead.
                  # uuid = recovery_network.value.uuid
                }
              }

              dynamic "test_network" {
                for_each = availability_zone_network_mapping_list.value.test_network != null ? [availability_zone_network_mapping_list.value.test_network] : []
                content {
                  name = test_network.value.name
                  # TODO: 'uuid' is not supported as a direct argument on test_network in nutanix provider 2.3.1.
                  # Use 'virtual_network_reference' block instead.
                  # uuid = test_network.value.uuid
                }
              }

              availability_zone_url = availability_zone_network_mapping_list.value.availability_zone_url
            }
          }
        }
      }

      # dynamic "floating_ip_assignment_list" {
      #   for_each = parameters.value.floating_ip_assignment_list != null ? parameters.value.floating_ip_assignment_list : []
      #   content {
      #     # TODO: 'vm_uuid' is not supported as a direct argument on floating_ip_assignment_list in nutanix provider 2.3.1.
      #     # Use 'availability_zone_url' and 'vm_ip_assignment_list' with nested 'vm_reference' block instead.
      #     # vm_uuid = floating_ip_assignment_list.value.vm_uuid
      #
      #     # TODO: 'test_floating_ip_config' is not supported as a direct block on floating_ip_assignment_list in nutanix provider 2.3.1.
      #     # It should be nested under 'vm_ip_assignment_list' instead.
      #     # dynamic "test_floating_ip_config" {
      #     #   for_each = floating_ip_assignment_list.value.test_floating_ip_config != null ? [floating_ip_assignment_list.value.test_floating_ip_config] : []
      #     #   content {
      #     #     ip                          = test_floating_ip_config.value.ip
      #     #     should_allocate_dynamically = test_floating_ip_config.value.should_allocate_dynamically
      #     #   }
      #     # }
      #
      #     # TODO: 'recovery_floating_ip_config' is not supported as a direct block on floating_ip_assignment_list in nutanix provider 2.3.1.
      #     # It should be nested under 'vm_ip_assignment_list' instead.
      #     # dynamic "recovery_floating_ip_config" {
      #     #   for_each = floating_ip_assignment_list.value.recovery_floating_ip_config != null ? [floating_ip_assignment_list.value.recovery_floating_ip_config] : []
      #     #   content {
      #     #     ip                          = recovery_floating_ip_config.value.ip
      #     #     should_allocate_dynamically = recovery_floating_ip_config.value.should_allocate_dynamically
      #     #   }
      #     # }
      #   }
      # }
    }
  }
}

resource "nutanix_recovery_points_v2" "recovery_point" {
  for_each = var.recovery_points

  name                = each.value.name
  expiration_time     = each.value.expiration_time
  status              = each.value.status
  recovery_point_type = each.value.recovery_point_type

  dynamic "vm_recovery_points" {
    for_each = each.value.vm_recovery_points != null ? each.value.vm_recovery_points : []
    content {
      vm_ext_id           = vm_recovery_points.value.vm_ext_id
      name                = vm_recovery_points.value.name
      expiration_time     = vm_recovery_points.value.expiration_time
      status              = vm_recovery_points.value.status
      recovery_point_type = vm_recovery_points.value.recovery_point_type
    }
  }

  dynamic "volume_group_recovery_points" {
    for_each = each.value.volume_group_recovery_points != null ? each.value.volume_group_recovery_points : []
    content {
      volume_group_ext_id = volume_group_recovery_points.value.volume_group_ext_id
      # TODO: 'name' is not supported as an input argument on volume_group_recovery_points in nutanix provider 2.3.1 (read-only attribute).
      # name                = volume_group_recovery_points.value.name
      # TODO: 'expiration_time' is not supported as an input argument on volume_group_recovery_points in nutanix provider 2.3.1 (read-only attribute).
      # expiration_time     = volume_group_recovery_points.value.expiration_time
      # TODO: 'status' is not supported as an input argument on volume_group_recovery_points in nutanix provider 2.3.1 (read-only attribute).
      # status              = volume_group_recovery_points.value.status
      # TODO: 'recovery_point_type' is not supported as an input argument on volume_group_recovery_points in nutanix provider 2.3.1 (read-only attribute).
      # recovery_point_type = volume_group_recovery_points.value.recovery_point_type
    }
  }
}

# Note: The following resources have minimal documentation in the provider.
# Implementation is based on likely arguments. Adjust as needed based on actual provider capabilities.

resource "nutanix_recovery_point_replicate_v2" "replicate" {
  for_each = var.recovery_point_replicates

  # Primary identifier for the recovery point to replicate
  ext_id = each.value.ext_id

  # TODO: 'cluster_ext_id' is not supported as an argument on nutanix_recovery_point_replicate_v2 in nutanix provider 2.3.1.
  # cluster_ext_id = each.value.cluster_ext_id

  # Prism Central ext_id if needed for cross-PC replication
  # Note: This field may not be supported - verify against provider docs
  pc_ext_id = each.value.pc_ext_id
}

resource "nutanix_recovery_point_restore_v2" "restore" {
  for_each = var.recovery_point_restores

  # Recovery point identifier to restore from
  ext_id = each.value.ext_id

  # Target cluster for restore operation
  cluster_ext_id = each.value.cluster_ext_id
}

resource "nutanix_restore_protected_resource_v2" "restore_resource" {
  for_each = var.restore_protected_resources

  # Protected resource identifier
  ext_id = each.value.ext_id

  # Target cluster for restore
  cluster_ext_id = each.value.cluster_ext_id
}

resource "nutanix_promote_protected_resource_v2" "promote_resource" {
  for_each = var.promote_protected_resources

  # Protected resource identifier to promote
  ext_id = each.value.ext_id
}
