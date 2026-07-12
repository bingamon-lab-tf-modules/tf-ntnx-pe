##################################################
# Unit Tests: PE cluster lifecycle (v2) — issue 589
##################################################

#########################
# Provider
#########################

provider "nutanix" {
  username     = "dummy"
  password     = "dummy"
  endpoint     = "dummy.local"
  port         = 9440
  insecure     = true
  wait_timeout = 1
}

#########################
# Mock Data (Nutanix Provider)
#########################

mock_provider "nutanix" {

  # Cluster inventory lookup (data.nutanix_clusters_v2.clusters — always read).
  mock_data "nutanix_clusters_v2" {
    defaults = {
      cluster_entities = []
    }
  }

  # Existing protection policies lookup (gated by enable_data_lookups).
  mock_data "nutanix_protection_policies_v2" {
    defaults = {
      protection_policies = []
    }
  }

  # Existing recovery points lookup (gated by enable_data_lookups).
  mock_data "nutanix_recovery_points_v2" {
    defaults = {
      recovery_points = []
    }
  }

  # Host inventory lookup (gated by enable_data_lookups — issue 589).
  mock_data "nutanix_hosts_v2" {
    defaults = {
      host_entities = []
    }
  }
}

#########################
# Tests
#########################

# Test 1: Empty configuration plans zero cluster-lifecycle resources.
run "empty_cluster_config" {
  command = plan

  assert {
    condition     = output.pe_summary.cluster_lifecycle.clusters_managed == 0
    error_message = "Expected 0 managed clusters for an empty configuration"
  }

  assert {
    condition     = output.pe_summary.cluster_lifecycle.node_additions == 0
    error_message = "Expected 0 node additions for an empty configuration"
  }

  assert {
    condition     = length(output.cluster_ids) == 0
    error_message = "Expected no cluster ids for an empty configuration"
  }
}

# Test 2: A cluster_v2 create plus a node-addition action plan and expose their
# id maps.
run "cluster_create_and_node_addition" {
  command = plan

  variables {
    clusters = {
      pe1 = {
        name = "lab-pe-cluster-1"
        config = {
          cluster_function  = ["AOS"]
          redundancy_factor = 2
        }
        nodes = {
          node_list = [
            {
              hypervisor_hostname = "node-a"
              controller_vm_ip = {
                ipv4 = {
                  value = "192.168.1.11"
                }
              }
              host_ip = {
                ipv4 = {
                  value = "192.168.1.21"
                }
              }
            }
          ]
        }
      }
    }

    cluster_node_additions = {
      expand_pe1 = {
        cluster_ext_id = "00000000-0000-0000-0000-0000000000d1"
        node_params = {
          node_list = [
            {
              hypervisor_type = "AHV"
              cvm_ip = {
                ipv4 = {
                  value = "192.168.1.12"
                }
              }
            }
          ]
        }
      }
    }
  }

  assert {
    condition     = output.pe_summary.cluster_lifecycle.clusters_managed == 1
    error_message = "Expected exactly 1 managed cluster"
  }

  assert {
    condition     = length(output.cluster_ids) == 1
    error_message = "Expected exactly 1 cluster id"
  }

  assert {
    condition     = contains(keys(output.cluster_ids), "pe1")
    error_message = "Expected a cluster id keyed by pe1"
  }

  assert {
    condition     = output.pe_summary.cluster_lifecycle.node_additions == 1
    error_message = "Expected exactly 1 node addition"
  }

  assert {
    condition     = contains(keys(output.cluster_node_additions), "expand_pe1")
    error_message = "Expected a node addition keyed by expand_pe1"
  }
}

# Test 3: Discovery and network-fetch actions plan together.
run "discovery_and_network_fetch" {
  command = plan

  variables {
    node_discoveries = {
      d1 = {
        ext_id              = "00000000-0000-0000-0000-0000000000d1"
        is_manual_discovery = true
      }
    }

    node_network_fetches = {
      n1 = {
        ext_id = "00000000-0000-0000-0000-0000000000d1"
        node_list = [
          {
            node_uuid = "00000000-0000-0000-0000-0000000000e1"
            cvm_ip = {
              ipv4 = {
                value = "192.168.1.31"
              }
            }
          }
        ]
      }
    }
  }

  assert {
    condition     = output.pe_summary.cluster_lifecycle.node_discoveries == 1
    error_message = "Expected exactly 1 node discovery"
  }

  assert {
    condition     = output.pe_summary.cluster_lifecycle.node_network_fetches == 1
    error_message = "Expected exactly 1 node network fetch"
  }

  assert {
    condition     = contains(keys(output.node_discoveries), "d1")
    error_message = "Expected a discovery result keyed by d1"
  }
}

# Test 4: A cluster with an empty node_list trips the clusters variable
# validation (name + >= 1 node).
run "cluster_without_nodes_fails" {
  command = plan

  variables {
    clusters = {
      bad = {
        name = "no-nodes-cluster"
        nodes = {
          node_list = []
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

# Test 5: A cluster whose controller_vm_ip is not a dotted-quad IPv4 trips the
# clusters IP-format validation.
run "cluster_bad_cvm_ip_fails" {
  command = plan

  variables {
    clusters = {
      bad = {
        name = "bad-ip-cluster"
        nodes = {
          node_list = [
            {
              controller_vm_ip = {
                ipv4 = {
                  value = "not-an-ip"
                }
              }
            }
          ]
        }
      }
    }
  }

  expect_failures = [var.clusters]
}

# Test 6: A node-addition with an empty cluster_ext_id trips the
# cluster_node_additions validation.
run "node_addition_missing_cluster_ext_id_fails" {
  command = plan

  variables {
    cluster_node_additions = {
      bad = {
        cluster_ext_id = ""
        node_params = {
          node_list = [
            {
              hypervisor_type = "AHV"
            }
          ]
        }
      }
    }
  }

  expect_failures = [var.cluster_node_additions]
}
