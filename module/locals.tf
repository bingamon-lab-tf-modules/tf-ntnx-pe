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

  # Existing recovery point name to ext_id map (when data lookups enabled).
  # Recovery points may be unnamed, so entries without a name are skipped.
  existing_recovery_points = var.enable_data_lookups ? {
    for rp in try(data.nutanix_recovery_points_v2.existing[0].recovery_points, []) :
    rp.name => rp.ext_id if rp.name != null
  } : {}

  # ---------------------------------------------------------------------------
  # Factored output value expressions
  #
  # This larger output value is defined once here and referenced from both its
  # individual `output` block and the aggregate `output "outputs"` (spec §7.6
  # contract). Terraform cannot reference one output from another, so this local
  # is the shared single source of truth. Behaviour is unchanged.
  # ---------------------------------------------------------------------------

  # Summary of PE protection/recovery resources (used by output "pe_summary").
  out_pe_summary = {
    clusters = {
      total = length(data.nutanix_clusters_v2.clusters.cluster_entities)
      names = [for cluster in data.nutanix_clusters_v2.clusters.cluster_entities : cluster.name]
    }
    protection_policies = {
      total                       = length(nutanix_protection_policy_v2.policy)
      sync_policies_count         = length(local.sync_protection_policies)
      async_policies_count        = length(local.async_protection_policies)
      linear_retention_count      = length(local.linear_retention_policies)
      auto_rollup_retention_count = length(local.auto_rollup_retention_policies)
    }
    recovery_plans = {
      total = length(nutanix_recovery_plan.plan)
    }
    recovery_points = {
      total = length(nutanix_recovery_points_v2.recovery_point)
    }
    operations = {
      replicates        = length(nutanix_recovery_point_replicate_v2.replicate)
      restores          = length(nutanix_recovery_point_restore_v2.restore)
      resource_restores = length(nutanix_restore_protected_resource_v2.restore_resource)
      resource_promotes = length(nutanix_promote_protected_resource_v2.promote_resource)
    }
  }
}
