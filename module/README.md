# tf-ntnx-pe

## Table of Contents

## Overview

A description of the module goes here.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_nutanix"></a> [nutanix](#requirement\_nutanix) | >= 2.4.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nutanix"></a> [nutanix](#provider\_nutanix) | 2.4.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [nutanix_promote_protected_resource_v2.promote_resource](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/promote_protected_resource_v2) | resource |
| [nutanix_protection_policy_v2.policy](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/protection_policy_v2) | resource |
| [nutanix_protection_rule.rule](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/protection_rule) | resource |
| [nutanix_recovery_plan.plan](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/recovery_plan) | resource |
| [nutanix_recovery_point_replicate_v2.replicate](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/recovery_point_replicate_v2) | resource |
| [nutanix_recovery_point_restore_v2.restore](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/recovery_point_restore_v2) | resource |
| [nutanix_recovery_points_v2.recovery_point](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/recovery_points_v2) | resource |
| [nutanix_restore_protected_resource_v2.restore_resource](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/restore_protected_resource_v2) | resource |
| [nutanix_clusters_v2.clusters](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/clusters_v2) | data source |
| [nutanix_protection_policies_v2.existing](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/protection_policies_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_data_lookups"></a> [enable\_data\_lookups](#input\_enable\_data\_lookups) | Enable data source lookups for existing resources | `bool` | `false` | no |
| <a name="input_promote_protected_resources"></a> [promote\_protected\_resources](#input\_promote\_protected\_resources) | Map of promote protected resource operations (v2) | <pre>map(object({<br/>    ext_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_protection_policies"></a> [protection\_policies](#input\_protection\_policies) | Map of protection policies (v2) to create | <pre>map(object({<br/>    name        = string<br/>    description = optional(string)<br/>    replication_configurations = optional(list(object({<br/>      source_location_label = string<br/>      remote_location_label = optional(string)<br/>      schedule = object({<br/>        recovery_point_objective_time_seconds         = number<br/>        recovery_point_type                           = optional(string) # CRASH_CONSISTENT or APP_CONSISTENT<br/>        sync_replication_auto_suspend_timeout_seconds = optional(number)<br/>        start_time                                    = optional(string)<br/>        retention = optional(object({<br/>          linear_retention = optional(object({<br/>            local_retention_count  = optional(number)<br/>            remote_retention_count = optional(number)<br/>          }))<br/>          auto_rollup_retention = optional(object({<br/>            local_snapshot_interval_type  = optional(string)<br/>            local_snapshot_frequency      = optional(number)<br/>            remote_snapshot_interval_type = optional(string)<br/>            remote_snapshot_frequency     = optional(number)<br/>          }))<br/>        }))<br/>      })<br/>    })), [])<br/>    replication_locations = optional(list(object({<br/>      label                 = string<br/>      domain_manager_ext_id = string<br/>      is_primary            = optional(bool, false)<br/>      replication_sub_location = optional(object({<br/>        cluster_ext_ids = optional(list(string), [])<br/>      }))<br/>    })), [])<br/>    category_ids = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_protection_rules"></a> [protection\_rules](#input\_protection\_rules) | Map of protection rules (v1) to create | <pre>map(object({<br/>    name        = string<br/>    description = string<br/>    ordered_availability_zone_list = optional(list(object({<br/>      cluster_uuid          = optional(string)<br/>      availability_zone_url = optional(string)<br/>    })), [])<br/>    availability_zone_connectivity_list = optional(list(object({<br/>      destination_availability_zone_index = optional(number)<br/>      source_availability_zone_index      = optional(number)<br/>      snapshot_schedule_list = optional(list(object({<br/>        recovery_point_objective_secs = number<br/>        snapshot_type                 = optional(string) # CRASH_CONSISTENT or APP_CONSISTENT<br/>        local_snapshot_retention_policy = optional(object({<br/>          num_snapshots                                  = optional(number)<br/>          rollup_retention_policy_multiple               = optional(number)<br/>          rollup_retention_policy_snapshot_interval_type = optional(string)<br/>        }))<br/>        auto_suspend_timeout_secs = optional(number)<br/>        remote_snapshot_retention_policy = optional(object({<br/>          num_snapshots                                  = optional(number)<br/>          rollup_retention_policy_multiple               = optional(number)<br/>          rollup_retention_policy_snapshot_interval_type = optional(string)<br/>        }))<br/>      })), [])<br/>    })), [])<br/>    category_filter = optional(object({<br/>      type      = optional(string)<br/>      kind_list = optional(list(string), [])<br/>      params = optional(list(object({<br/>        name   = string<br/>        values = list(string)<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_recovery_plans"></a> [recovery\_plans](#input\_recovery\_plans) | Map of recovery plans (v1) to create | <pre>map(object({<br/>    name        = string<br/>    description = string<br/>    stage_list = optional(list(object({<br/>      stage_uuid      = optional(string)<br/>      delay_time_secs = optional(number)<br/>      stage_work = optional(object({<br/>        recover_entities = optional(object({<br/>          entity_info_list = optional(list(object({<br/>            categories = optional(object({<br/>              name  = optional(string)<br/>              value = optional(string)<br/>            }))<br/>            any_entity_reference_kind = optional(string)<br/>            any_entity_reference_uuid = optional(string)<br/>            any_entity_reference_name = optional(string)<br/>          })), [])<br/>        }))<br/>      }))<br/>    })), [])<br/>    parameters = optional(object({<br/>      network_mapping_list = optional(list(object({<br/>        availability_zone_network_mapping_list = optional(list(object({<br/>          recovery_network = optional(object({<br/>            name = optional(string)<br/>            uuid = optional(string)<br/>          }))<br/>          test_network = optional(object({<br/>            name = optional(string)<br/>            uuid = optional(string)<br/>          }))<br/>          availability_zone_url = optional(string)<br/>        })), [])<br/>      })), [])<br/>      floating_ip_assignment_list = optional(list(object({<br/>        vm_uuid = optional(string)<br/>        test_floating_ip_config = optional(object({<br/>          ip                          = optional(string)<br/>          should_allocate_dynamically = optional(bool)<br/>        }))<br/>        recovery_floating_ip_config = optional(object({<br/>          ip                          = optional(string)<br/>          should_allocate_dynamically = optional(bool)<br/>        }))<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_recovery_point_replicates"></a> [recovery\_point\_replicates](#input\_recovery\_point\_replicates) | Map of recovery point replicate operations (v2) | <pre>map(object({<br/>    ext_id         = string<br/>    cluster_ext_id = optional(string)<br/>    pc_ext_id      = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_recovery_point_restores"></a> [recovery\_point\_restores](#input\_recovery\_point\_restores) | Map of recovery point restore operations (v2) | <pre>map(object({<br/>    ext_id         = string<br/>    cluster_ext_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_recovery_points"></a> [recovery\_points](#input\_recovery\_points) | Map of recovery points (v2) to create | <pre>map(object({<br/>    name                = optional(string)<br/>    expiration_time     = optional(string)<br/>    status              = optional(string, "COMPLETE")<br/>    recovery_point_type = optional(string) # CRASH_CONSISTENT or APPLICATION_CONSISTENT<br/>    vm_recovery_points = optional(list(object({<br/>      vm_ext_id           = string<br/>      name                = optional(string)<br/>      expiration_time     = optional(string)<br/>      status              = optional(string, "COMPLETE")<br/>      recovery_point_type = optional(string)<br/>    })), [])<br/>    volume_group_recovery_points = optional(list(object({<br/>      volume_group_ext_id = string<br/>      name                = optional(string)<br/>      expiration_time     = optional(string)<br/>      status              = optional(string, "COMPLETE")<br/>      recovery_point_type = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_restore_protected_resources"></a> [restore\_protected\_resources](#input\_restore\_protected\_resources) | Map of restore protected resource operations (v2) | <pre>map(object({<br/>    ext_id         = string<br/>    cluster_ext_id = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pe_summary"></a> [pe\_summary](#output\_pe\_summary) | Summary of Prism Element protection and recovery resources |
| <a name="output_promote_protected_resources"></a> [promote\_protected\_resources](#output\_promote\_protected\_resources) | Promote protected resource operations (v2) |
| <a name="output_protection_policies"></a> [protection\_policies](#output\_protection\_policies) | Protection policies (v2) created |
| <a name="output_protection_policy_ids"></a> [protection\_policy\_ids](#output\_protection\_policy\_ids) | Map of protection policy keys to their IDs |
| <a name="output_protection_rule_ids"></a> [protection\_rule\_ids](#output\_protection\_rule\_ids) | Map of protection rule keys to their IDs |
| <a name="output_protection_rules"></a> [protection\_rules](#output\_protection\_rules) | Protection rules (v1) created |
| <a name="output_recovery_plan_ids"></a> [recovery\_plan\_ids](#output\_recovery\_plan\_ids) | Map of recovery plan keys to their IDs |
| <a name="output_recovery_plans"></a> [recovery\_plans](#output\_recovery\_plans) | Recovery plans (v1) created |
| <a name="output_recovery_point_ids"></a> [recovery\_point\_ids](#output\_recovery\_point\_ids) | Map of recovery point keys to their external IDs |
| <a name="output_recovery_point_replicates"></a> [recovery\_point\_replicates](#output\_recovery\_point\_replicates) | Recovery point replicate operations (v2) |
| <a name="output_recovery_point_restores"></a> [recovery\_point\_restores](#output\_recovery\_point\_restores) | Recovery point restore operations (v2) |
| <a name="output_recovery_points"></a> [recovery\_points](#output\_recovery\_points) | Recovery points (v2) created |
| <a name="output_restore_protected_resources"></a> [restore\_protected\_resources](#output\_restore\_protected\_resources) | Restore protected resource operations (v2) |
<!-- END_TF_DOCS -->
