output "protection_policies" {
  description = "Protection policies (v2) created"
  value = {
    for k, v in nutanix_protection_policy_v2.policy : k => {
      id                         = v.id
      ext_id                     = v.ext_id
      name                       = v.name
      description                = v.description
      replication_configurations = v.replication_configurations
      replication_locations      = v.replication_locations
      category_ids               = v.category_ids
    }
  }
}

output "protection_rules" {
  description = "Protection rules (v1) created"
  value = {
    for k, v in nutanix_protection_rule.rule : k => {
      id                                  = v.id
      name                                = v.name
      description                         = v.description
      ordered_availability_zone_list      = v.ordered_availability_zone_list
      availability_zone_connectivity_list = v.availability_zone_connectivity_list
      category_filter                     = v.category_filter
    }
  }
}

output "recovery_plans" {
  description = "Recovery plans (v1) created"
  value = {
    for k, v in nutanix_recovery_plan.plan : k => {
      id          = v.id
      name        = v.name
      description = v.description
      stage_list  = v.stage_list
      parameters  = v.parameters
    }
  }
}

output "recovery_points" {
  description = "Recovery points (v2) created"
  value = {
    for k, v in nutanix_recovery_points_v2.recovery_point : k => {
      id                           = v.id
      ext_id                       = v.ext_id
      name                         = v.name
      expiration_time              = v.expiration_time
      status                       = v.status
      recovery_point_type          = v.recovery_point_type
      vm_recovery_points           = v.vm_recovery_points
      volume_group_recovery_points = v.volume_group_recovery_points
    }
  }
}

output "recovery_point_replicates" {
  description = "Recovery point replicate operations (v2)"
  value = {
    for k, v in nutanix_recovery_point_replicate_v2.replicate : k => {
      id             = v.id
      ext_id         = v.ext_id
      cluster_ext_id = v.cluster_ext_id
    }
  }
}

output "recovery_point_restores" {
  description = "Recovery point restore operations (v2)"
  value = {
    for k, v in nutanix_recovery_point_restore_v2.restore : k => {
      id             = v.id
      ext_id         = v.ext_id
      cluster_ext_id = v.cluster_ext_id
    }
  }
}

output "restore_protected_resources" {
  description = "Restore protected resource operations (v2)"
  value = {
    for k, v in nutanix_restore_protected_resource_v2.restore_resource : k => {
      id             = v.id
      ext_id         = v.ext_id
      cluster_ext_id = v.cluster_ext_id
    }
  }
}

output "promote_protected_resources" {
  description = "Promote protected resource operations (v2)"
  value = {
    for k, v in nutanix_promote_protected_resource_v2.promote_resource : k => {
      id     = v.id
      ext_id = v.ext_id
    }
  }
}

output "pe_summary" {
  description = "Summary of Prism Element protection and recovery resources"
  value = {
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
    protection_rules = {
      total = length(nutanix_protection_rule.rule)
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
