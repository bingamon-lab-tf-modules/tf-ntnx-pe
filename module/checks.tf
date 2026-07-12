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
