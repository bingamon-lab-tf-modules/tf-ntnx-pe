check "protection_policies_have_locations" {
  assert {
    condition = alltrue([
      for k, v in var.protection_policies :
      length(v.replication_locations) == 0 || length(v.replication_locations) >= 1
    ])
    error_message = "Protection policies with replication configured should have at least 1 replication location."
  }
}

check "protection_policies_have_primary" {
  assert {
    condition = alltrue([
      for k, v in var.protection_policies :
      length(v.replication_locations) == 0 || anytrue([for loc in v.replication_locations : loc.is_primary == true])
    ])
    error_message = "Protection policies with replication locations should have exactly one primary replication location."
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
        contains(["CRASH_CONSISTENT", "APP_CONSISTENT", "APPLICATION_CONSISTENT"], config.schedule.recovery_point_type)
      ]
    ]))
    error_message = "Protection policy recovery_point_type must be CRASH_CONSISTENT, APP_CONSISTENT, or APPLICATION_CONSISTENT."
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

# A protection policy's category_keys must resolve against the map passed in
# from the security_governance landing zone.
#
# A check rather than a variable validation: var.category_ids comes from
# ANOTHER landing zone's output, so on a clean-slate apply its keys are not
# known at validate time. This reports the mismatch at plan time with the
# offending key named, instead of failing inside a for-expression.
check "protection_policy_category_keys_resolve" {
  assert {
    condition = alltrue(flatten([
      for k, v in var.protection_policies : [
        for ck in v.category_keys : contains(keys(var.category_ids), ck)
      ]
    ]))
    error_message = "A protection policy 'category_keys' entry is not in var.category_ids. Check the security_governance landing zone is enabled and the key matches a category it manages."
  }
}

