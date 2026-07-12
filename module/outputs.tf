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

output "protection_policy_ids" {
  description = "Map of protection policy keys to their IDs"
  value = {
    for k, v in nutanix_protection_policy_v2.policy : k => v.id
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

output "recovery_plan_ids" {
  description = "Map of recovery plan keys to their IDs"
  value = {
    for k, v in nutanix_recovery_plan.plan : k => v.id
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

output "recovery_point_ids" {
  description = "Map of recovery point keys to their external IDs"
  value = {
    for k, v in nutanix_recovery_points_v2.recovery_point : k => v.ext_id
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
  value       = local.out_pe_summary
}

# ---------------------------------------------------------------------------
# Aggregate output (spec §7.6 contract)
# ---------------------------------------------------------------------------
output "outputs" {
  description = "Aggregate of all module outputs (spec §7.6 contract, consumed by the landing zone as module.<x>.outputs)."
  value = {
    protection_policies = {
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
    protection_policy_ids = {
      for k, v in nutanix_protection_policy_v2.policy : k => v.id
    }
    recovery_plans = {
      for k, v in nutanix_recovery_plan.plan : k => {
        id          = v.id
        name        = v.name
        description = v.description
        stage_list  = v.stage_list
        parameters  = v.parameters
      }
    }
    recovery_plan_ids = {
      for k, v in nutanix_recovery_plan.plan : k => v.id
    }
    recovery_points = {
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
    recovery_point_ids = {
      for k, v in nutanix_recovery_points_v2.recovery_point : k => v.ext_id
    }
    recovery_point_replicates = {
      for k, v in nutanix_recovery_point_replicate_v2.replicate : k => {
        id             = v.id
        ext_id         = v.ext_id
        cluster_ext_id = v.cluster_ext_id
      }
    }
    recovery_point_restores = {
      for k, v in nutanix_recovery_point_restore_v2.restore : k => {
        id             = v.id
        ext_id         = v.ext_id
        cluster_ext_id = v.cluster_ext_id
      }
    }
    restore_protected_resources = {
      for k, v in nutanix_restore_protected_resource_v2.restore_resource : k => {
        id             = v.id
        ext_id         = v.ext_id
        cluster_ext_id = v.cluster_ext_id
      }
    }
    promote_protected_resources = {
      for k, v in nutanix_promote_protected_resource_v2.promote_resource : k => {
        id     = v.id
        ext_id = v.ext_id
      }
    }
    pe_summary = local.out_pe_summary
  }
}
