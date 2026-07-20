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


  # ---------------------------------------------------------------------------
  # Factored output value expressions
  #
  # This larger output value is defined once here and referenced from both its
  # individual `output` block and the aggregate `output "outputs"` (spec §7.6
  # contract). Terraform cannot reference one output from another, so this local
  # is the shared single source of truth. Behaviour is unchanged.
  # ---------------------------------------------------------------------------

  # PE cluster lifecycle (issue 589) — factored output value expressions,
  # referenced from both the individual `output` blocks and the aggregate
  # `output "outputs"` (spec §7.6 contract) so the two never drift.
  out_clusters = {
    for k, v in nutanix_cluster_v2.cluster : k => {
      id     = v.id
      ext_id = v.ext_id
      name   = v.name
    }
  }

  out_cluster_ids = {
    for k, v in nutanix_cluster_v2.cluster : k => v.ext_id
  }

  out_cluster_node_additions = {
    for k, v in nutanix_cluster_add_node_v2.node_addition : k => {
      id             = v.id
      cluster_ext_id = v.cluster_ext_id
    }
  }

  out_node_discoveries = {
    for k, v in nutanix_clusters_discover_unconfigured_nodes_v2.node_discovery : k => {
      id                 = v.id
      ext_id             = v.ext_id
      unconfigured_nodes = v.unconfigured_nodes
    }
  }

  out_node_network_fetches = {
    for k, v in nutanix_clusters_unconfigured_node_networks_v2.node_network_fetch : k => {
      id                       = v.id
      ext_id                   = v.ext_id
      nodes_networking_details = v.nodes_networking_details
    }
  }

  # Summary of PE protection/recovery resources (used by output "pe_summary").
  out_pe_summary = {
    clusters = {
      total = length(data.nutanix_clusters_v2.clusters.cluster_entities)
      names = [for cluster in data.nutanix_clusters_v2.clusters.cluster_entities : cluster.name]
    }
    cluster_lifecycle = {
      clusters_managed     = length(nutanix_cluster_v2.cluster)
      node_additions       = length(nutanix_cluster_add_node_v2.node_addition)
      node_discoveries     = length(nutanix_clusters_discover_unconfigured_nodes_v2.node_discovery)
      node_network_fetches = length(nutanix_clusters_unconfigured_node_networks_v2.node_network_fetch)
      hosts_discovered     = var.enable_data_lookups ? length(try(data.nutanix_hosts_v2.hosts[0].host_entities, [])) : 0
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
