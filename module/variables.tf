variable "enable_data_lookups" {
  description = "Enable data source lookups for existing resources"
  type        = bool
  default     = false
}

##################################################
# Cross-landing-zone inputs
##################################################

# Categories are owned by the security_governance landing zone. This module
# cannot depend on them directly, so the caller passes that landing zone's
# category_ids output in here. A protection policy then names a category by
# KEY (category_keys) instead of carrying a per-Prism-Central UUID, and
# OpenTofu gets a real dependency edge: categories -> protection policies.
variable "category_ids" {
  description = "Map of category key => ext_id, supplied by the caller from the security_governance landing zone's category_ids output. Referenced by a protection policy's 'category_keys'. Empty when that landing zone is disabled, in which case policies must use raw category_ids."
  type        = map(string)
  default     = {}
}

# Prism Central's own ext_id, used as the default domain_manager_ext_id for any
# replication_location that omits one. Mirrors the fallback tf-ntnx-pc already
# implements, and keeps the PC UUID out of YAML: a single-site policy just says
# is_primary and lets this fill in.
variable "domain_manager_ext_id" {
  description = "Prism Central (domain manager) ext_id, used as the default for replication_locations that omit domain_manager_ext_id. Supplied by the caller so config never carries the PC UUID."
  type        = string
  default     = null
}

variable "protection_policies" {
  description = "Map of protection policies (v2) to create"
  type = map(object({
    name        = string
    description = optional(string)
    replication_configurations = optional(list(object({
      source_location_label = string
      remote_location_label = optional(string)
      schedule = object({
        recovery_point_objective_time_seconds         = number
        recovery_point_type                           = optional(string) # CRASH_CONSISTENT or APPLICATION_CONSISTENT (APP_CONSISTENT auto-mapped)
        sync_replication_auto_suspend_timeout_seconds = optional(number)
        start_time                                    = optional(string)
        retention = optional(object({
          linear_retention = optional(object({
            local_retention_count  = optional(number)
            remote_retention_count = optional(number)
          }))
          auto_rollup_retention = optional(object({
            local_snapshot_interval_type  = optional(string)
            local_snapshot_frequency      = optional(number)
            remote_snapshot_interval_type = optional(string)
            remote_snapshot_frequency     = optional(number)
          }))
        }))
      })
    })), [])
    replication_locations = optional(list(object({
      label = string
      # Omit to default to var.domain_manager_ext_id (this Prism Central) —
      # which is what a single-site, local-retention policy wants.
      domain_manager_ext_id = optional(string, null)
      is_primary            = optional(bool, false)
      replication_sub_location = optional(object({
        cluster_ext_ids = optional(list(string), [])
      }))
    })), [])
    # Workloads this policy protects. Supply EITHER:
    #   category_keys -- keys into var.category_ids, resolved to ext_ids. This
    #     is the maintainable form: tag a VM with the category and it is
    #     protected on the next sync, with no change to this config. New
    #     workloads cannot be silently missed.
    #   category_ids  -- literal category ext_ids. Escape hatch for a category
    #     not managed by the security_governance landing zone (a built-in
    #     SYSTEM category, for instance).
    category_keys = optional(list(string), [])
    category_ids  = optional(list(string), [])
  }))
  default = {}

}

variable "recovery_plans" {
  description = "Map of recovery plans (v1) to create"
  type = map(object({
    name        = string
    description = string
    stage_list = optional(list(object({
      stage_uuid      = optional(string)
      delay_time_secs = optional(number)
      stage_work = optional(object({
        recover_entities = optional(object({
          entity_info_list = optional(list(object({
            categories = optional(object({
              name  = optional(string)
              value = optional(string)
            }))
            any_entity_reference_kind = optional(string)
            any_entity_reference_uuid = optional(string)
            any_entity_reference_name = optional(string)
          })), [])
        }))
      }))
    })), [])
    parameters = optional(object({
      network_mapping_list = optional(list(object({
        availability_zone_network_mapping_list = optional(list(object({
          recovery_network = optional(object({
            name = optional(string)
            uuid = optional(string)
          }))
          test_network = optional(object({
            name = optional(string)
            uuid = optional(string)
          }))
          availability_zone_url = optional(string)
        })), [])
      })), [])
      floating_ip_assignment_list = optional(list(object({
        vm_uuid = optional(string)
        test_floating_ip_config = optional(object({
          ip                          = optional(string)
          should_allocate_dynamically = optional(bool)
        }))
        recovery_floating_ip_config = optional(object({
          ip                          = optional(string)
          should_allocate_dynamically = optional(bool)
        }))
      })), [])
    }))
  }))
  default = {}
}

variable "recovery_points" {
  description = "Map of recovery points (v2) to create"
  type = map(object({
    name                = optional(string)
    expiration_time     = optional(string)
    status              = optional(string, "COMPLETE")
    recovery_point_type = optional(string) # CRASH_CONSISTENT or APPLICATION_CONSISTENT
    vm_recovery_points = optional(list(object({
      vm_ext_id           = string
      name                = optional(string)
      expiration_time     = optional(string)
      status              = optional(string, "COMPLETE")
      recovery_point_type = optional(string)
    })), [])
    volume_group_recovery_points = optional(list(object({
      volume_group_ext_id = string
      name                = optional(string)
      expiration_time     = optional(string)
      status              = optional(string, "COMPLETE")
      recovery_point_type = optional(string)
    })), [])
  }))
  default = {}
}

variable "recovery_point_replicates" {
  description = "Map of recovery point replicate operations (v2)"
  type = map(object({
    ext_id         = string
    cluster_ext_id = optional(string)
    pc_ext_id      = optional(string)
  }))
  default = {}
}

variable "recovery_point_restores" {
  description = "Map of recovery point restore operations (v2)"
  type = map(object({
    ext_id         = string
    cluster_ext_id = optional(string)
  }))
  default = {}
}

variable "restore_protected_resources" {
  description = "Map of restore protected resource operations (v2)"
  type = map(object({
    ext_id         = string
    cluster_ext_id = optional(string)
  }))
  default = {}
}

variable "promote_protected_resources" {
  description = "Map of promote protected resource operations (v2)"
  type = map(object({
    ext_id = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# PE cluster lifecycle (v2) — issue 589
#
# DANGER: these four resource families mutate physical Prism-Element clusters.
# Every map defaults to {} so a caller that passes nothing (e.g. the
# backup_recovery LZ) plans zero cluster resources. Only the prism_central LZ
# should ever populate them, behind its lz_enable_prism_central flag.
# ---------------------------------------------------------------------------

variable "clusters" {
  description = <<-EOT
    Map of PE clusters to CREATE/MANAGE via nutanix_cluster_v2 (one entry per
    cluster). Each entry needs a non-empty name and at least one node in
    nodes.node_list (with a controller_vm_ip; host_ip optional).

    DESTROY SEMANTICS — READ BEFORE USE: nutanix_cluster_v2 CREATE forms a REAL
    Prism-Element cluster and `tofu destroy` (or removing a map key) DESTROYS
    that cluster. This must NEVER be reachable from a casually-edited YAML
    default — keep this map empty ({}) unless you deliberately intend to
    form/expand a cluster, and gate it behind the LZ enable flag
    (588's lz_enable_prism_central, default false). Use nutanix_cluster_v2 for
    API-driven formation/expansion of already-imaged nodes; use Foundation
    (foundation_image_nodes) for bare-metal imaging that forms a cluster during
    imaging. Default {}.
  EOT
  type = map(object({
    name                   = string
    categories             = optional(list(string))
    cluster_profile_ext_id = optional(string)
    container_name         = optional(string)
    dryrun                 = optional(bool)
    expand                 = optional(string)
    config = optional(object({
      cluster_arch                 = optional(string)
      cluster_function             = optional(list(string))
      redundancy_factor            = optional(number)
      operation_mode               = optional(string)
      encryption_in_transit_status = optional(string)
    }))
    network = optional(object({
      fqdn                       = optional(string)
      key_management_server_type = optional(string)
      nfs_subnet_white_list      = optional(list(string))
    }))
    nodes = object({
      node_list = list(object({
        hypervisor_hostname            = optional(string)
        is_compute_only                = optional(bool)
        is_light_compute               = optional(bool)
        is_never_scheduleable          = optional(bool)
        should_skip_add_node           = optional(bool)
        should_skip_discovery          = optional(bool)
        should_skip_host_networking    = optional(bool)
        should_skip_imaging            = optional(bool)
        should_skip_pre_expand_checks  = optional(bool)
        should_validate_rack_awareness = optional(bool)
        controller_vm_ip = object({
          ipv4 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
          ipv6 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
        })
        host_ip = optional(object({
          ipv4 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
          ipv6 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
        }))
      }))
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      trimspace(v.name) != "" && length(v.nodes.node_list) >= 1
    ])
    error_message = "Each cluster must have a non-empty name and at least one node in nodes.node_list (cluster_v2 create forms a REAL PE cluster; keep this map {} unless forming/expanding one)."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.clusters : [
        for n in v.nodes.node_list : [
          can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", try(n.controller_vm_ip.ipv4.value, "0.0.0.0"))),
          can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", try(n.host_ip.ipv4.value, "0.0.0.0"))),
        ]
      ]
    ]))
    error_message = "controller_vm_ip.ipv4.value and host_ip.ipv4.value (where set) must be dotted-quad IPv4 addresses."
  }
}

variable "cluster_node_additions" {
  description = <<-EOT
    Map of node-addition ACTIONS via nutanix_cluster_add_node_v2 — expands an
    EXISTING cluster (cluster_ext_id) with the nodes in node_params.node_list.

    ONE-SHOT ACTION SEMANTICS: this is imperative — applying it executes an
    expansion. Re-running against the same nodes is not idempotent; to add more
    nodes later, use a NEW for_each map key. `tofu destroy` does NOT remove the
    added nodes (it only forgets the action from state). Default {}.
  EOT
  type = map(object({
    cluster_ext_id                = string
    should_skip_add_node          = optional(bool)
    should_skip_pre_expand_checks = optional(bool)
    config_params = optional(object({
      is_compute_only                = optional(bool)
      is_never_schedulable           = optional(bool)
      is_nos_compatible              = optional(bool)
      should_skip_discovery          = optional(bool)
      should_skip_imaging            = optional(bool)
      should_validate_rack_awareness = optional(bool)
      target_hypervisor              = optional(string)
    }))
    node_params = object({
      hyperv_sku                  = optional(string)
      should_skip_host_networking = optional(bool)
      node_list = list(object({
        block_id                  = optional(string)
        hypervisor_hostname       = optional(string)
        hypervisor_type           = optional(string)
        hypervisor_version        = optional(string)
        model                     = optional(string)
        node_position             = optional(string)
        node_uuid                 = optional(string)
        nos_version               = optional(string)
        current_network_interface = optional(string)
        is_light_compute          = optional(bool)
        is_robo_mixed_hypervisor  = optional(bool)
        cvm_ip = optional(object({
          ipv4 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
          ipv6 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
        }))
        hypervisor_ip = optional(object({
          ipv4 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
          ipv6 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
        }))
        ipmi_ip = optional(object({
          ipv4 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
          ipv6 = optional(object({
            value         = string
            prefix_length = optional(number)
          }))
        }))
      }))
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.cluster_node_additions :
      trimspace(v.cluster_ext_id) != "" && length(v.node_params.node_list) >= 1
    ])
    error_message = "Each cluster_node_addition must set a non-empty cluster_ext_id and at least one node in node_params.node_list."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.cluster_node_additions : [
        for n in v.node_params.node_list :
        can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", try(n.cvm_ip.ipv4.value, "0.0.0.0")))
      ]
    ]))
    error_message = "cvm_ip.ipv4.value (where set) must be a dotted-quad IPv4 address."
  }
}

variable "node_discoveries" {
  description = <<-EOT
    Map of unconfigured-node DISCOVERY actions via
    nutanix_clusters_discover_unconfigured_nodes_v2. `ext_id` is the target
    cluster's external id to discover against; results land in state
    (unconfigured_nodes).

    ONE-SHOT ACTION SEMANTICS: discovery is imperative and writes its result to
    state. Re-discover = a NEW for_each key. `tofu destroy` does nothing to the
    physical nodes. Default {}.
  EOT
  type = map(object({
    ext_id                = string
    address_type          = optional(string)
    interface_filter_list = optional(list(string))
    is_manual_discovery   = optional(bool)
    timeout               = optional(number)
    uuid_filter_list      = optional(list(string))
    ip_filter_list = optional(list(object({
      ipv4 = optional(object({
        value         = string
        prefix_length = optional(number)
      }))
      ipv6 = optional(object({
        value         = string
        prefix_length = optional(number)
      }))
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.node_discoveries : trimspace(v.ext_id) != ""
    ])
    error_message = "Each node_discovery must set a non-empty ext_id (the target cluster external id)."
  }
}

variable "node_network_fetches" {
  description = <<-EOT
    Map of unconfigured-node NETWORK-INFO fetch actions via
    nutanix_clusters_unconfigured_node_networks_v2. `ext_id` is the target
    cluster's external id; node_list identifies the unconfigured nodes to fetch
    network details for; results land in state (nodes_networking_details).

    ONE-SHOT ACTION SEMANTICS: this fetch is imperative and writes its result to
    state. Re-fetch = a NEW for_each key. `tofu destroy` does nothing to the
    physical nodes. Default {}.
  EOT
  type = map(object({
    ext_id       = string
    expand       = optional(string)
    request_type = optional(string)
    node_list = list(object({
      block_id                  = optional(string)
      current_network_interface = optional(string)
      hypervisor_type           = optional(string)
      hypervisor_version        = optional(string)
      model                     = optional(string)
      node_position             = optional(string)
      node_uuid                 = optional(string)
      nos_version               = optional(string)
      is_compute_only           = optional(bool)
      is_light_compute          = optional(bool)
      is_robo_mixed_hypervisor  = optional(bool)
      cvm_ip = optional(object({
        ipv4 = optional(object({
          value         = string
          prefix_length = optional(number)
        }))
        ipv6 = optional(object({
          value         = string
          prefix_length = optional(number)
        }))
      }))
      hypervisor_ip = optional(object({
        ipv4 = optional(object({
          value         = string
          prefix_length = optional(number)
        }))
        ipv6 = optional(object({
          value         = string
          prefix_length = optional(number)
        }))
      }))
      ipmi_ip = optional(object({
        ipv4 = optional(object({
          value         = string
          prefix_length = optional(number)
        }))
        ipv6 = optional(object({
          value         = string
          prefix_length = optional(number)
        }))
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.node_network_fetches :
      trimspace(v.ext_id) != "" && length(v.node_list) >= 1
    ])
    error_message = "Each node_network_fetch must set a non-empty ext_id and at least one node in node_list."
  }
}
