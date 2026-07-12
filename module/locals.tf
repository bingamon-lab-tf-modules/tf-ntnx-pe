locals {
  # Filter synchronous protection policies (RPO = 0)
  sync_protection_policies = {
    for k, v in var.protection_policies : k => v
    if length(v.replication_configurations) > 0 && anytrue([
      for config in v.replication_configurations :
      config.schedule.recovery_point_objective_time_seconds == 0
    ])
  }

  # Filter asynchronous protection policies (RPO > 0)
  async_protection_policies = {
    for k, v in var.protection_policies : k => v
    if length(v.replication_configurations) > 0 && alltrue([
      for config in v.replication_configurations :
      config.schedule.recovery_point_objective_time_seconds > 0
    ])
  }

  # Filter policies using linear retention
  linear_retention_policies = {
    for k, v in var.protection_policies : k => v
    if length(v.replication_configurations) > 0 && anytrue([
      for config in v.replication_configurations :
      config.schedule.retention != null && config.schedule.retention.linear_retention != null
    ])
  }

  # Filter policies using auto rollup retention
  auto_rollup_retention_policies = {
    for k, v in var.protection_policies : k => v
    if length(v.replication_configurations) > 0 && anytrue([
      for config in v.replication_configurations :
      config.schedule.retention != null && config.schedule.retention.auto_rollup_retention != null
    ])
  }

  # Map of protection policy names to their IDs for reference
  protection_policy_ids = {
    for k, v in nutanix_protection_policy_v2.policy : k => v.id
  }

  # Map of recovery plan names to their IDs for reference
  recovery_plan_ids = {
    for k, v in nutanix_recovery_plan.plan : k => v.id
  }

  # Map of recovery point names to their ext_ids for reference
  recovery_point_ext_ids = {
    for k, v in nutanix_recovery_points_v2.recovery_point : k => v.ext_id
  }

  # Cluster name to ext_id lookup map (when data lookups enabled)
  clusters = var.enable_data_lookups ? {
    for cluster in try(data.nutanix_clusters_v2.clusters.cluster_entities, []) :
    cluster.name => cluster.ext_id
  } : {}

  # Existing protection policy name to ext_id map (when data lookups enabled)
  existing_protection_policies = var.enable_data_lookups ? {
    for policy in try(data.nutanix_protection_policies_v2.existing[0].protection_policies, []) :
    policy.name => policy.ext_id
  } : {}
}
