##################################################
# Unit Tests: Prism Element protection & recovery
##################################################

#########################
# Provider
#########################

provider "nutanix" {
  username     = "dummy"
  password     = "dummy"
  endpoint     = "dummy.local"
  port         = 9440
  insecure     = true
  wait_timeout = 1
}

#########################
# Mock Data (Nutanix Provider)
#########################

mock_provider "nutanix" {

  # Cluster inventory lookup (data.nutanix_clusters_v2.clusters — always read).
  mock_data "nutanix_clusters_v2" {
    defaults = {
      cluster_entities = []
    }
  }

  # Existing protection policies lookup (gated by enable_data_lookups).
  mock_data "nutanix_protection_policies_v2" {
    defaults = {
      protection_policies = []
    }
  }

  # Existing recovery points lookup (gated by enable_data_lookups).
  mock_data "nutanix_recovery_points_v2" {
    defaults = {
      recovery_points = []
    }
  }
}

#########################
# Tests
#########################

# Test 1: Empty configuration plans zero resources.
run "empty_config" {
  command = plan

  assert {
    condition     = output.pe_summary.protection_policies.total == 0
    error_message = "Expected 0 protection policies for an empty configuration"
  }

  assert {
    condition     = output.pe_summary.recovery_plans.total == 0
    error_message = "Expected 0 recovery plans for an empty configuration"
  }

  assert {
    condition     = output.pe_summary.recovery_points.total == 0
    error_message = "Expected 0 recovery points for an empty configuration"
  }

  assert {
    condition     = length(output.protection_policy_ids) == 0
    error_message = "Expected no protection policy ids for an empty configuration"
  }
}

# Test 2: A protection policy plus a recovery point expose their id maps.
run "protection_policy_and_recovery_point" {
  command = plan

  variables {
    protection_policies = {
      dr = {
        name        = "cross-site-dr"
        description = "Cross-site replication policy"

        replication_locations = [
          {
            label                 = "primary"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a1"
            is_primary            = true
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b1"]
            }
          },
          {
            label                 = "dr-site"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a2"
            is_primary            = false
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b2"]
            }
          }
        ]

        replication_configurations = [
          {
            source_location_label = "primary"
            remote_location_label = "dr-site"
            schedule = {
              recovery_point_type                   = "CRASH_CONSISTENT"
              recovery_point_objective_time_seconds = 3600
              retention = {
                linear_retention = {
                  local_retention_count  = 24
                  remote_retention_count = 48
                }
              }
            }
          }
        ]
      }
    }

    recovery_points = {
      app_vm = {
        name                = "app-vm-recovery-point"
        recovery_point_type = "CRASH_CONSISTENT"
        vm_recovery_points = [
          {
            vm_ext_id = "00000000-0000-0000-0000-0000000000c1"
          }
        ]
      }
    }
  }

  assert {
    condition     = output.pe_summary.protection_policies.total == 1
    error_message = "Expected exactly 1 protection policy"
  }

  assert {
    condition     = length(output.protection_policy_ids) == 1
    error_message = "Expected exactly 1 protection policy id"
  }

  assert {
    condition     = contains(keys(output.protection_policy_ids), "dr")
    error_message = "Expected a protection policy id keyed by dr"
  }

  assert {
    condition     = length(output.recovery_point_ids) == 1
    error_message = "Expected exactly 1 recovery point id"
  }

  assert {
    condition     = contains(keys(output.recovery_point_ids), "app_vm")
    error_message = "Expected a recovery point id keyed by app_vm"
  }
}

# Test 3: A recovery plan with an ordered stage list plans and exposes its id.
run "recovery_plan_with_stages" {
  command = plan

  variables {
    recovery_plans = {
      app_tier = {
        name        = "application-tier-recovery"
        description = "Recover the application tier VMs"
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
        # parameters is required by the provider (min 1 block); network
        # mappings are environment-specific (see examples/recovery-plan).
        parameters = {}
      }
    }
  }

  assert {
    condition     = output.pe_summary.recovery_plans.total == 1
    error_message = "Expected exactly 1 recovery plan"
  }

  assert {
    condition     = length(output.recovery_plan_ids) == 1
    error_message = "Expected exactly 1 recovery plan id"
  }

  assert {
    condition     = contains(keys(output.recovery_plan_ids), "app_tier")
    error_message = "Expected a recovery plan id keyed by app_tier"
  }
}

# Test 4: Enabling data lookups plans cleanly against the mocked lookups.
run "data_lookups_enabled" {
  command = plan

  variables {
    enable_data_lookups = true
  }

  assert {
    condition     = output.pe_summary.clusters.total == 0
    error_message = "Expected 0 clusters from the empty mocked cluster inventory"
  }

  assert {
    condition     = length(output.protection_policy_ids) == 0
    error_message = "Expected no created protection policies when only lookups are enabled"
  }
}

# Test 5: A protection policy with fewer than two replication locations trips
# the checks.tf location assertion. (One location and one configuration keep
# the config schema-valid so the plan proceeds and the check is what fails.)
run "protection_policy_missing_locations" {
  command = plan

  variables {
    protection_policies = {
      lonely = {
        name = "single-location-policy"
        replication_locations = [
          {
            label                 = "primary"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a1"
            is_primary            = true
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b1"]
            }
          }
        ]
        replication_configurations = [
          {
            source_location_label = "primary"
            schedule = {
              recovery_point_type                   = "CRASH_CONSISTENT"
              recovery_point_objective_time_seconds = 3600
            }
          }
        ]
      }
    }
  }

  expect_failures = [check.protection_policies_have_locations]
}

# Test 6: A protection policy with no primary replication location trips the
# checks.tf primary assertion (two locations keep the location-count check
# satisfied so only the primary check fails).
run "protection_policy_missing_primary" {
  command = plan

  variables {
    protection_policies = {
      no_primary = {
        name = "no-primary-policy"
        replication_locations = [
          {
            label                 = "primary"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a1"
            is_primary            = false
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b1"]
            }
          },
          {
            label                 = "dr-site"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a2"
            is_primary            = false
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b2"]
            }
          }
        ]
        replication_configurations = [
          {
            source_location_label = "primary"
            remote_location_label = "dr-site"
            schedule = {
              recovery_point_type                   = "CRASH_CONSISTENT"
              recovery_point_objective_time_seconds = 3600
            }
          }
        ]
      }
    }
  }

  expect_failures = [check.protection_policies_have_primary]
}

# Test 7: Multiple protection policies plan together and are all reported.
run "multiple_protection_policies" {
  command = plan

  variables {
    protection_policies = {
      primary_dr = {
        name = "primary-dr"
        replication_locations = [
          {
            label                 = "primary"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a1"
            is_primary            = true
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b1"]
            }
          },
          {
            label                 = "dr-site"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a2"
            is_primary            = false
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b2"]
            }
          }
        ]
        replication_configurations = [
          {
            source_location_label = "primary"
            remote_location_label = "dr-site"
            schedule = {
              recovery_point_type                   = "CRASH_CONSISTENT"
              recovery_point_objective_time_seconds = 3600
            }
          }
        ]
      }
      secondary_dr = {
        name = "secondary-dr"
        replication_locations = [
          {
            label                 = "primary"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a3"
            is_primary            = true
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b3"]
            }
          },
          {
            label                 = "dr-site"
            domain_manager_ext_id = "00000000-0000-0000-0000-0000000000a4"
            is_primary            = false
            replication_sub_location = {
              cluster_ext_ids = ["00000000-0000-0000-0000-0000000000b4"]
            }
          }
        ]
        replication_configurations = [
          {
            source_location_label = "primary"
            remote_location_label = "dr-site"
            schedule = {
              recovery_point_type                   = "CRASH_CONSISTENT"
              recovery_point_objective_time_seconds = 7200
            }
          }
        ]
      }
    }
  }

  assert {
    condition     = output.pe_summary.protection_policies.total == 2
    error_message = "Expected exactly 2 protection policies"
  }

  assert {
    condition     = length(output.protection_policy_ids) == 2
    error_message = "Expected exactly 2 protection policy ids"
  }
}
