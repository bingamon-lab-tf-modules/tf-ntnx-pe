# ---------------------------------------------------------------------------
# PE cluster lifecycle (v2) — issue 589
#
# Four provider-2.4.2 resource families that manage the Prism-Element cluster
# lifecycle. Each is driven by a map var that defaults to {}, so this whole file
# plans zero resources unless a caller (the prism_central LZ) populates a map.
#
# DANGER: nutanix_cluster_v2 CREATE forms a REAL cluster; destroy DESTROYS it.
# The other three are imperative one-shot ACTIONS (add-node / discover / fetch)
# whose results are recorded in state; destroy does not undo them. See the
# variable descriptions and README for the full destroy / when-to-use guidance.
# ---------------------------------------------------------------------------

# CREATE/MANAGE a Prism-Element cluster (or expand one via the `expand` field).
resource "nutanix_cluster_v2" "cluster" {
  for_each = var.clusters

  name                   = each.value.name
  categories             = each.value.categories
  cluster_profile_ext_id = each.value.cluster_profile_ext_id
  container_name         = each.value.container_name
  dryrun                 = each.value.dryrun
  expand                 = each.value.expand

  dynamic "config" {
    for_each = each.value.config != null ? [each.value.config] : []
    content {
      cluster_arch                 = config.value.cluster_arch
      cluster_function             = config.value.cluster_function
      redundancy_factor            = config.value.redundancy_factor
      operation_mode               = config.value.operation_mode
      encryption_in_transit_status = config.value.encryption_in_transit_status
    }
  }

  dynamic "network" {
    for_each = each.value.network != null ? [each.value.network] : []
    content {
      fqdn                       = network.value.fqdn
      key_management_server_type = network.value.key_management_server_type
      nfs_subnet_white_list      = network.value.nfs_subnet_white_list
    }
  }

  nodes {
    dynamic "node_list" {
      for_each = each.value.nodes.node_list
      content {
        hypervisor_hostname            = node_list.value.hypervisor_hostname
        is_compute_only                = node_list.value.is_compute_only
        is_light_compute               = node_list.value.is_light_compute
        is_never_scheduleable          = node_list.value.is_never_scheduleable
        should_skip_add_node           = node_list.value.should_skip_add_node
        should_skip_discovery          = node_list.value.should_skip_discovery
        should_skip_host_networking    = node_list.value.should_skip_host_networking
        should_skip_imaging            = node_list.value.should_skip_imaging
        should_skip_pre_expand_checks  = node_list.value.should_skip_pre_expand_checks
        should_validate_rack_awareness = node_list.value.should_validate_rack_awareness

        controller_vm_ip {
          dynamic "ipv4" {
            for_each = node_list.value.controller_vm_ip.ipv4 != null ? [node_list.value.controller_vm_ip.ipv4] : []
            content {
              value         = ipv4.value.value
              prefix_length = ipv4.value.prefix_length
            }
          }
          dynamic "ipv6" {
            for_each = node_list.value.controller_vm_ip.ipv6 != null ? [node_list.value.controller_vm_ip.ipv6] : []
            content {
              value         = ipv6.value.value
              prefix_length = ipv6.value.prefix_length
            }
          }
        }

        dynamic "host_ip" {
          for_each = node_list.value.host_ip != null ? [node_list.value.host_ip] : []
          content {
            dynamic "ipv4" {
              for_each = host_ip.value.ipv4 != null ? [host_ip.value.ipv4] : []
              content {
                value         = ipv4.value.value
                prefix_length = ipv4.value.prefix_length
              }
            }
            dynamic "ipv6" {
              for_each = host_ip.value.ipv6 != null ? [host_ip.value.ipv6] : []
              content {
                value         = ipv6.value.value
                prefix_length = ipv6.value.prefix_length
              }
            }
          }
        }
      }
    }
  }
}

# ACTION: add node(s) to an existing cluster (one-shot expansion).
resource "nutanix_cluster_add_node_v2" "node_addition" {
  for_each = var.cluster_node_additions

  cluster_ext_id                = each.value.cluster_ext_id
  should_skip_add_node          = each.value.should_skip_add_node
  should_skip_pre_expand_checks = each.value.should_skip_pre_expand_checks

  dynamic "config_params" {
    for_each = each.value.config_params != null ? [each.value.config_params] : []
    content {
      is_compute_only                = config_params.value.is_compute_only
      is_never_schedulable           = config_params.value.is_never_schedulable
      is_nos_compatible              = config_params.value.is_nos_compatible
      should_skip_discovery          = config_params.value.should_skip_discovery
      should_skip_imaging            = config_params.value.should_skip_imaging
      should_validate_rack_awareness = config_params.value.should_validate_rack_awareness
      target_hypervisor              = config_params.value.target_hypervisor
    }
  }

  node_params {
    hyperv_sku                  = each.value.node_params.hyperv_sku
    should_skip_host_networking = each.value.node_params.should_skip_host_networking

    dynamic "node_list" {
      for_each = each.value.node_params.node_list
      content {
        block_id                  = node_list.value.block_id
        hypervisor_hostname       = node_list.value.hypervisor_hostname
        hypervisor_type           = node_list.value.hypervisor_type
        hypervisor_version        = node_list.value.hypervisor_version
        model                     = node_list.value.model
        node_position             = node_list.value.node_position
        node_uuid                 = node_list.value.node_uuid
        nos_version               = node_list.value.nos_version
        current_network_interface = node_list.value.current_network_interface
        is_light_compute          = node_list.value.is_light_compute
        is_robo_mixed_hypervisor  = node_list.value.is_robo_mixed_hypervisor

        dynamic "cvm_ip" {
          for_each = node_list.value.cvm_ip != null ? [node_list.value.cvm_ip] : []
          content {
            dynamic "ipv4" {
              for_each = cvm_ip.value.ipv4 != null ? [cvm_ip.value.ipv4] : []
              content {
                value         = ipv4.value.value
                prefix_length = ipv4.value.prefix_length
              }
            }
            dynamic "ipv6" {
              for_each = cvm_ip.value.ipv6 != null ? [cvm_ip.value.ipv6] : []
              content {
                value         = ipv6.value.value
                prefix_length = ipv6.value.prefix_length
              }
            }
          }
        }

        dynamic "hypervisor_ip" {
          for_each = node_list.value.hypervisor_ip != null ? [node_list.value.hypervisor_ip] : []
          content {
            dynamic "ipv4" {
              for_each = hypervisor_ip.value.ipv4 != null ? [hypervisor_ip.value.ipv4] : []
              content {
                value         = ipv4.value.value
                prefix_length = ipv4.value.prefix_length
              }
            }
            dynamic "ipv6" {
              for_each = hypervisor_ip.value.ipv6 != null ? [hypervisor_ip.value.ipv6] : []
              content {
                value         = ipv6.value.value
                prefix_length = ipv6.value.prefix_length
              }
            }
          }
        }

        dynamic "ipmi_ip" {
          for_each = node_list.value.ipmi_ip != null ? [node_list.value.ipmi_ip] : []
          content {
            dynamic "ipv4" {
              for_each = ipmi_ip.value.ipv4 != null ? [ipmi_ip.value.ipv4] : []
              content {
                value         = ipv4.value.value
                prefix_length = ipv4.value.prefix_length
              }
            }
            dynamic "ipv6" {
              for_each = ipmi_ip.value.ipv6 != null ? [ipmi_ip.value.ipv6] : []
              content {
                value         = ipv6.value.value
                prefix_length = ipv6.value.prefix_length
              }
            }
          }
        }
      }
    }
  }
}

# ACTION: discover unconfigured nodes reachable from a cluster (one-shot).
resource "nutanix_clusters_discover_unconfigured_nodes_v2" "node_discovery" {
  for_each = var.node_discoveries

  ext_id                = each.value.ext_id
  address_type          = each.value.address_type
  interface_filter_list = each.value.interface_filter_list
  is_manual_discovery   = each.value.is_manual_discovery
  timeout               = each.value.timeout
  uuid_filter_list      = each.value.uuid_filter_list

  dynamic "ip_filter_list" {
    for_each = each.value.ip_filter_list
    content {
      dynamic "ipv4" {
        for_each = ip_filter_list.value.ipv4 != null ? [ip_filter_list.value.ipv4] : []
        content {
          value         = ipv4.value.value
          prefix_length = ipv4.value.prefix_length
        }
      }
      dynamic "ipv6" {
        for_each = ip_filter_list.value.ipv6 != null ? [ip_filter_list.value.ipv6] : []
        content {
          value         = ipv6.value.value
          prefix_length = ipv6.value.prefix_length
        }
      }
    }
  }
}

# ACTION: fetch network info of unconfigured nodes (one-shot).
resource "nutanix_clusters_unconfigured_node_networks_v2" "node_network_fetch" {
  for_each = var.node_network_fetches

  ext_id       = each.value.ext_id
  expand       = each.value.expand
  request_type = each.value.request_type

  dynamic "node_list" {
    for_each = each.value.node_list
    content {
      block_id                  = node_list.value.block_id
      current_network_interface = node_list.value.current_network_interface
      hypervisor_type           = node_list.value.hypervisor_type
      hypervisor_version        = node_list.value.hypervisor_version
      model                     = node_list.value.model
      node_position             = node_list.value.node_position
      node_uuid                 = node_list.value.node_uuid
      nos_version               = node_list.value.nos_version
      is_compute_only           = node_list.value.is_compute_only
      is_light_compute          = node_list.value.is_light_compute
      is_robo_mixed_hypervisor  = node_list.value.is_robo_mixed_hypervisor

      dynamic "cvm_ip" {
        for_each = node_list.value.cvm_ip != null ? [node_list.value.cvm_ip] : []
        content {
          dynamic "ipv4" {
            for_each = cvm_ip.value.ipv4 != null ? [cvm_ip.value.ipv4] : []
            content {
              value         = ipv4.value.value
              prefix_length = ipv4.value.prefix_length
            }
          }
          dynamic "ipv6" {
            for_each = cvm_ip.value.ipv6 != null ? [cvm_ip.value.ipv6] : []
            content {
              value         = ipv6.value.value
              prefix_length = ipv6.value.prefix_length
            }
          }
        }
      }

      dynamic "hypervisor_ip" {
        for_each = node_list.value.hypervisor_ip != null ? [node_list.value.hypervisor_ip] : []
        content {
          dynamic "ipv4" {
            for_each = hypervisor_ip.value.ipv4 != null ? [hypervisor_ip.value.ipv4] : []
            content {
              value         = ipv4.value.value
              prefix_length = ipv4.value.prefix_length
            }
          }
          dynamic "ipv6" {
            for_each = hypervisor_ip.value.ipv6 != null ? [hypervisor_ip.value.ipv6] : []
            content {
              value         = ipv6.value.value
              prefix_length = ipv6.value.prefix_length
            }
          }
        }
      }

      dynamic "ipmi_ip" {
        for_each = node_list.value.ipmi_ip != null ? [node_list.value.ipmi_ip] : []
        content {
          dynamic "ipv4" {
            for_each = ipmi_ip.value.ipv4 != null ? [ipmi_ip.value.ipv4] : []
            content {
              value         = ipv4.value.value
              prefix_length = ipv4.value.prefix_length
            }
          }
          dynamic "ipv6" {
            for_each = ipmi_ip.value.ipv6 != null ? [ipmi_ip.value.ipv6] : []
            content {
              value         = ipv6.value.value
              prefix_length = ipv6.value.prefix_length
            }
          }
        }
      }
    }
  }
}
