check "protection_policies_have_locations" {
  assert {
    condition = alltrue([
      for k, v in var.protection_policies :
      length(v.replication_locations) >= 2
    ])
    error_message = "Protection policies should have at least 2 replication locations."
  }
}

check "protection_policies_have_primary" {
  assert {
    condition = alltrue([
      for k, v in var.protection_policies :
      anytrue([for loc in v.replication_locations : loc.is_primary == true])
    ])
    error_message = "Protection policies should have exactly one primary replication location."
  }
}

check "recovery_plans_have_stages" {
  assert {
    condition = alltrue([
      for k, v in var.recovery_plans :
      length(v.stage_list) > 0
    ])
    error_message = "Recovery plans should have at least one stage defined."
  }
}

check "protection_policies_valid_rpo_type" {
  assert {
    condition = alltrue(flatten([
      for k, v in var.protection_policies : [
        for config in v.replication_configurations :
        config.schedule.recovery_point_type == null ||
        contains(["CRASH_CONSISTENT", "APP_CONSISTENT"], config.schedule.recovery_point_type)
      ]
    ]))
    error_message = "Protection policy recovery_point_type must be CRASH_CONSISTENT or APP_CONSISTENT."
  }
}

check "recovery_points_valid_status" {
  assert {
    condition = alltrue([
      for k, v in var.recovery_points :
      v.status == null || contains(["COMPLETE", "PENDING", "FAILED"], v.status)
    ])
    error_message = "Recovery point status must be COMPLETE, PENDING, or FAILED."
  }
}

check "recovery_points_valid_type" {
  assert {
    condition = alltrue([
      for k, v in var.recovery_points :
      v.recovery_point_type == null ||
      contains(["CRASH_CONSISTENT", "APPLICATION_CONSISTENT"], v.recovery_point_type)
    ])
    error_message = "Recovery point type must be CRASH_CONSISTENT or APPLICATION_CONSISTENT."
  }
}

# ---------------------------------------------------------------------------
# PE cluster lifecycle (v2) assertions — issue 589
# ---------------------------------------------------------------------------

check "clusters_have_valid_redundancy_factor" {
  assert {
    condition = alltrue([
      for k, v in var.clusters :
      v.config == null || v.config.redundancy_factor == null ||
      contains([1, 2, 3], v.config.redundancy_factor)
    ])
    error_message = "Cluster config.redundancy_factor, when set, must be 1, 2, or 3."
  }
}

check "cluster_node_additions_have_nodes" {
  assert {
    condition = alltrue([
      for k, v in var.cluster_node_additions :
      length(v.node_params.node_list) >= 1
    ])
    error_message = "Each cluster_node_addition must supply at least one node in node_params.node_list."
  }
}

check "node_network_fetches_have_nodes" {
  assert {
    condition = alltrue([
      for k, v in var.node_network_fetches :
      length(v.node_list) >= 1
    ])
    error_message = "Each node_network_fetch must supply at least one node in node_list."
  }
}
