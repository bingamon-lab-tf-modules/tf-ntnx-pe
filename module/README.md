# tf-ntnx-pe

## Table of Contents

## Overview

Prism Element protection and recovery resources for the Nutanix Cloud Platform:
protection policies (v2), recovery plans, recovery points, and the associated
replicate / restore / promote operations.

Protection is expressed exclusively through `nutanix_protection_policy_v2`
(input `protection_policies`). The legacy v1 protection resource was removed ahead
of the Q4-CY2026 provider deprecation; there is no dual v1/v2 path.

## PE Cluster Lifecycle (v2)

This module also owns the Prism-Element **cluster lifecycle** (issue 589) — four
provider-2.4.2 resource families, each driven by a map input that defaults to `{}`:

| Input | Resource | Kind |
|---|---|---|
| `clusters` | `nutanix_cluster_v2` | **Create/manage a real PE cluster** |
| `cluster_node_additions` | `nutanix_cluster_add_node_v2` | One-shot action: add node(s) to a cluster |
| `node_discoveries` | `nutanix_clusters_discover_unconfigured_nodes_v2` | One-shot action: discover unconfigured nodes |
| `node_network_fetches` | `nutanix_clusters_unconfigured_node_networks_v2` | One-shot action: fetch node network info |

Because every map defaults to `{}`, a caller that passes none of them (e.g. the
`backup_recovery` LZ) plans **zero** cluster resources — the existing consumer
contract is unaffected.

### ⚠️ Destroy semantics — read before use

- **`clusters` (`nutanix_cluster_v2`) creates a REAL Prism-Element cluster.**
  Running `tofu destroy`, or removing a key from the `clusters` map, **DESTROYS
  that cluster.** This must never be reachable from a casually-edited YAML
  default. Populate `clusters` only deliberately, and only behind the
  `prism_central` landing zone's `lz_enable_prism_central` flag (default `false`)
  plus an explicit non-empty map. Keep it `{}` everywhere else.
- **The other three families are imperative one-shot ACTIONS.** `add_node`
  executes a cluster expansion; `discover` / `network_fetch` write their results
  into state. They are **not idempotent** — to run an action again, add a **new
  `for_each` map key**; re-editing an existing entry does not re-run cleanly.
  `tofu destroy` does **not** undo them: it forgets the action from state but
  leaves the added nodes / physical hardware in place.

### When to use Foundation vs `cluster_v2`

- Use **Foundation** (`foundation_image_nodes`, LZ 0) for **bare-metal imaging**:
  it images raw nodes and forms a cluster *as part of imaging*. That is the entry
  point for hardware that has never run AOS.
- Use **`cluster_v2`** (this module, via the `prism_central` LZ) for **API-driven
  formation/expansion of already-imaged nodes** — nodes that are imaged and
  discoverable but not yet joined to a cluster, or an existing cluster you want to
  expand. Do **not** use `cluster_v2` to re-image bare metal.

Together with Foundation (imaging, LZ 0) and PC deploy (LZ 1) this closes the
"100% lifecycle from bare metal" goal: image nodes → form/expand clusters →
deploy/register Prism Central.

### Placement rationale (why here)

- **Module = `tf-ntnx-pe`.** This is the Prism-Element-scoped module by name and
  charter, and it already carries the `nutanix_clusters_v2` lookup these resources
  reason about. A dedicated `tf-ntnx-cluster` repo would be a 14th repository for
  four resources with heavy cluster-lookup overlap. New inputs default to `{}`, so
  the module's other consumer (`backup_recovery`) is untouched.
- **Landing zone = `prism_central`** (issue 588). Cluster formation/expansion is
  Infrastructure-team work in the same dependency band as PC deploy
  (foundation → prism_central → …). The `backup_recovery` LZ — the other
  `tf-ntnx-pe` consumer — is an **Operations** LZ and must **not** gain
  cluster-mutation power, so the cluster inputs are wired only through
  `prism_central`, never through `backup_recovery`.
- **Rejected: the `foundation` LZ.** Foundation's contract is SOPS-encrypted
  imaging JSON — a different plane and shape from API-driven cluster management.

### Migrating legacy v1 protection to `protection_policies`

Map the legacy v1 concepts onto the `protection_policies` (v2) input:

| Legacy v1 attribute | `protection_policy_v2` |
|---|---|
| `ordered_availability_zone_list` | `replication_locations` (`domain_manager_ext_id`, `replication_sub_location.cluster_ext_ids`) |
| `availability_zone_connectivity_list.snapshot_schedule_list` | `replication_configurations.schedule` |
| `recovery_point_objective_secs` | `recovery_point_objective_time_seconds` |
| `snapshot_type` | `recovery_point_type` |
| `local_snapshot_retention_policy` / `remote_snapshot_retention_policy` | `retention` (`linear_retention` / `auto_rollup_retention`) |
| `auto_suspend_timeout_secs` | `sync_replication_auto_suspend_timeout_seconds` |
| `category_filter` (name/value params) | `category_ids` (Prism Central category ext-ids — a shape change) |

**State migration.** The legacy v1 protection resource and
`nutanix_protection_policy_v2` are different resource types, so `tofu state mv`
between them is **not** possible. A consumer that still holds legacy v1 state must
create the v2 policy (or `tofu import nutanix_protection_policy_v2.policy["<key>"]
<ext_id>`), then `tofu state rm` the old resource and delete it from configuration.
For this module the expected impact is nil — every consumer sets the protection map
to `{}`, so no live state holds the legacy address.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_nutanix"></a> [nutanix](#requirement\_nutanix) | >= 2.4.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nutanix"></a> [nutanix](#provider\_nutanix) | 2.4.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [nutanix_cluster_add_node_v2.node_addition](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/cluster_add_node_v2) | resource |
| [nutanix_cluster_v2.cluster](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/cluster_v2) | resource |
| [nutanix_clusters_discover_unconfigured_nodes_v2.node_discovery](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/clusters_discover_unconfigured_nodes_v2) | resource |
| [nutanix_clusters_unconfigured_node_networks_v2.node_network_fetch](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/clusters_unconfigured_node_networks_v2) | resource |
| [nutanix_promote_protected_resource_v2.promote_resource](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/promote_protected_resource_v2) | resource |
| [nutanix_protection_policy_v2.policy](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/protection_policy_v2) | resource |
| [nutanix_recovery_plan.plan](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/recovery_plan) | resource |
| [nutanix_recovery_point_replicate_v2.replicate](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/recovery_point_replicate_v2) | resource |
| [nutanix_recovery_point_restore_v2.restore](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/recovery_point_restore_v2) | resource |
| [nutanix_recovery_points_v2.recovery_point](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/recovery_points_v2) | resource |
| [nutanix_restore_protected_resource_v2.restore_resource](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/restore_protected_resource_v2) | resource |
| [nutanix_clusters_v2.clusters](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/clusters_v2) | data source |
| [nutanix_hosts_v2.hosts](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/hosts_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_node_additions"></a> [cluster\_node\_additions](#input\_cluster\_node\_additions) | Map of node-addition ACTIONS via nutanix\_cluster\_add\_node\_v2 — expands an<br/>EXISTING cluster (cluster\_ext\_id) with the nodes in node\_params.node\_list.<br/><br/>ONE-SHOT ACTION SEMANTICS: this is imperative — applying it executes an<br/>expansion. Re-running against the same nodes is not idempotent; to add more<br/>nodes later, use a NEW for\_each map key. `tofu destroy` does NOT remove the<br/>added nodes (it only forgets the action from state). Default {}. | <pre>map(object({<br/>    cluster_ext_id                = string<br/>    should_skip_add_node          = optional(bool)<br/>    should_skip_pre_expand_checks = optional(bool)<br/>    config_params = optional(object({<br/>      is_compute_only                = optional(bool)<br/>      is_never_schedulable           = optional(bool)<br/>      is_nos_compatible              = optional(bool)<br/>      should_skip_discovery          = optional(bool)<br/>      should_skip_imaging            = optional(bool)<br/>      should_validate_rack_awareness = optional(bool)<br/>      target_hypervisor              = optional(string)<br/>    }))<br/>    node_params = object({<br/>      hyperv_sku                  = optional(string)<br/>      should_skip_host_networking = optional(bool)<br/>      node_list = list(object({<br/>        block_id                  = optional(string)<br/>        hypervisor_hostname       = optional(string)<br/>        hypervisor_type           = optional(string)<br/>        hypervisor_version        = optional(string)<br/>        model                     = optional(string)<br/>        node_position             = optional(string)<br/>        node_uuid                 = optional(string)<br/>        nos_version               = optional(string)<br/>        current_network_interface = optional(string)<br/>        is_light_compute          = optional(bool)<br/>        is_robo_mixed_hypervisor  = optional(bool)<br/>        cvm_ip = optional(object({<br/>          ipv4 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>          ipv6 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>        }))<br/>        hypervisor_ip = optional(object({<br/>          ipv4 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>          ipv6 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>        }))<br/>        ipmi_ip = optional(object({<br/>          ipv4 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>          ipv6 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>        }))<br/>      }))<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_clusters"></a> [clusters](#input\_clusters) | Map of PE clusters to CREATE/MANAGE via nutanix\_cluster\_v2 (one entry per<br/>cluster). Each entry needs a non-empty name and at least one node in<br/>nodes.node\_list (with a controller\_vm\_ip; host\_ip optional).<br/><br/>DESTROY SEMANTICS — READ BEFORE USE: nutanix\_cluster\_v2 CREATE forms a REAL<br/>Prism-Element cluster and `tofu destroy` (or removing a map key) DESTROYS<br/>that cluster. This must NEVER be reachable from a casually-edited YAML<br/>default — keep this map empty ({}) unless you deliberately intend to<br/>form/expand a cluster, and gate it behind the LZ enable flag<br/>(588's lz\_enable\_prism\_central, default false). Use nutanix\_cluster\_v2 for<br/>API-driven formation/expansion of already-imaged nodes; use Foundation<br/>(foundation\_image\_nodes) for bare-metal imaging that forms a cluster during<br/>imaging. Default {}. | <pre>map(object({<br/>    name                   = string<br/>    categories             = optional(list(string))<br/>    cluster_profile_ext_id = optional(string)<br/>    container_name         = optional(string)<br/>    dryrun                 = optional(bool)<br/>    expand                 = optional(string)<br/>    config = optional(object({<br/>      cluster_arch                 = optional(string)<br/>      cluster_function             = optional(list(string))<br/>      redundancy_factor            = optional(number)<br/>      operation_mode               = optional(string)<br/>      encryption_in_transit_status = optional(string)<br/>    }))<br/>    network = optional(object({<br/>      fqdn                       = optional(string)<br/>      key_management_server_type = optional(string)<br/>      nfs_subnet_white_list      = optional(list(string))<br/>    }))<br/>    nodes = object({<br/>      node_list = list(object({<br/>        hypervisor_hostname            = optional(string)<br/>        is_compute_only                = optional(bool)<br/>        is_light_compute               = optional(bool)<br/>        is_never_scheduleable          = optional(bool)<br/>        should_skip_add_node           = optional(bool)<br/>        should_skip_discovery          = optional(bool)<br/>        should_skip_host_networking    = optional(bool)<br/>        should_skip_imaging            = optional(bool)<br/>        should_skip_pre_expand_checks  = optional(bool)<br/>        should_validate_rack_awareness = optional(bool)<br/>        controller_vm_ip = object({<br/>          ipv4 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>          ipv6 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>        })<br/>        host_ip = optional(object({<br/>          ipv4 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>          ipv6 = optional(object({<br/>            value         = string<br/>            prefix_length = optional(number)<br/>          }))<br/>        }))<br/>      }))<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_data_lookups"></a> [enable\_data\_lookups](#input\_enable\_data\_lookups) | Enable data source lookups for existing resources | `bool` | `false` | no |
| <a name="input_node_discoveries"></a> [node\_discoveries](#input\_node\_discoveries) | Map of unconfigured-node DISCOVERY actions via<br/>nutanix\_clusters\_discover\_unconfigured\_nodes\_v2. `ext_id` is the target<br/>cluster's external id to discover against; results land in state<br/>(unconfigured\_nodes).<br/><br/>ONE-SHOT ACTION SEMANTICS: discovery is imperative and writes its result to<br/>state. Re-discover = a NEW for\_each key. `tofu destroy` does nothing to the<br/>physical nodes. Default {}. | <pre>map(object({<br/>    ext_id                = string<br/>    address_type          = optional(string)<br/>    interface_filter_list = optional(list(string))<br/>    is_manual_discovery   = optional(bool)<br/>    timeout               = optional(number)<br/>    uuid_filter_list      = optional(list(string))<br/>    ip_filter_list = optional(list(object({<br/>      ipv4 = optional(object({<br/>        value         = string<br/>        prefix_length = optional(number)<br/>      }))<br/>      ipv6 = optional(object({<br/>        value         = string<br/>        prefix_length = optional(number)<br/>      }))<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_node_network_fetches"></a> [node\_network\_fetches](#input\_node\_network\_fetches) | Map of unconfigured-node NETWORK-INFO fetch actions via<br/>nutanix\_clusters\_unconfigured\_node\_networks\_v2. `ext_id` is the target<br/>cluster's external id; node\_list identifies the unconfigured nodes to fetch<br/>network details for; results land in state (nodes\_networking\_details).<br/><br/>ONE-SHOT ACTION SEMANTICS: this fetch is imperative and writes its result to<br/>state. Re-fetch = a NEW for\_each key. `tofu destroy` does nothing to the<br/>physical nodes. Default {}. | <pre>map(object({<br/>    ext_id       = string<br/>    expand       = optional(string)<br/>    request_type = optional(string)<br/>    node_list = list(object({<br/>      block_id                  = optional(string)<br/>      current_network_interface = optional(string)<br/>      hypervisor_type           = optional(string)<br/>      hypervisor_version        = optional(string)<br/>      model                     = optional(string)<br/>      node_position             = optional(string)<br/>      node_uuid                 = optional(string)<br/>      nos_version               = optional(string)<br/>      is_compute_only           = optional(bool)<br/>      is_light_compute          = optional(bool)<br/>      is_robo_mixed_hypervisor  = optional(bool)<br/>      cvm_ip = optional(object({<br/>        ipv4 = optional(object({<br/>          value         = string<br/>          prefix_length = optional(number)<br/>        }))<br/>        ipv6 = optional(object({<br/>          value         = string<br/>          prefix_length = optional(number)<br/>        }))<br/>      }))<br/>      hypervisor_ip = optional(object({<br/>        ipv4 = optional(object({<br/>          value         = string<br/>          prefix_length = optional(number)<br/>        }))<br/>        ipv6 = optional(object({<br/>          value         = string<br/>          prefix_length = optional(number)<br/>        }))<br/>      }))<br/>      ipmi_ip = optional(object({<br/>        ipv4 = optional(object({<br/>          value         = string<br/>          prefix_length = optional(number)<br/>        }))<br/>        ipv6 = optional(object({<br/>          value         = string<br/>          prefix_length = optional(number)<br/>        }))<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_promote_protected_resources"></a> [promote\_protected\_resources](#input\_promote\_protected\_resources) | Map of promote protected resource operations (v2) | <pre>map(object({<br/>    ext_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_protection_policies"></a> [protection\_policies](#input\_protection\_policies) | Map of protection policies (v2) to create | <pre>map(object({<br/>    name        = string<br/>    description = optional(string)<br/>    replication_configurations = optional(list(object({<br/>      source_location_label = string<br/>      remote_location_label = optional(string)<br/>      schedule = object({<br/>        recovery_point_objective_time_seconds         = number<br/>        recovery_point_type                           = optional(string) # CRASH_CONSISTENT or APP_CONSISTENT<br/>        sync_replication_auto_suspend_timeout_seconds = optional(number)<br/>        start_time                                    = optional(string)<br/>        retention = optional(object({<br/>          linear_retention = optional(object({<br/>            local_retention_count  = optional(number)<br/>            remote_retention_count = optional(number)<br/>          }))<br/>          auto_rollup_retention = optional(object({<br/>            local_snapshot_interval_type  = optional(string)<br/>            local_snapshot_frequency      = optional(number)<br/>            remote_snapshot_interval_type = optional(string)<br/>            remote_snapshot_frequency     = optional(number)<br/>          }))<br/>        }))<br/>      })<br/>    })), [])<br/>    replication_locations = optional(list(object({<br/>      label                 = string<br/>      domain_manager_ext_id = string<br/>      is_primary            = optional(bool, false)<br/>      replication_sub_location = optional(object({<br/>        cluster_ext_ids = optional(list(string), [])<br/>      }))<br/>    })), [])<br/>    category_ids = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_recovery_plans"></a> [recovery\_plans](#input\_recovery\_plans) | Map of recovery plans (v1) to create | <pre>map(object({<br/>    name        = string<br/>    description = string<br/>    stage_list = optional(list(object({<br/>      stage_uuid      = optional(string)<br/>      delay_time_secs = optional(number)<br/>      stage_work = optional(object({<br/>        recover_entities = optional(object({<br/>          entity_info_list = optional(list(object({<br/>            categories = optional(object({<br/>              name  = optional(string)<br/>              value = optional(string)<br/>            }))<br/>            any_entity_reference_kind = optional(string)<br/>            any_entity_reference_uuid = optional(string)<br/>            any_entity_reference_name = optional(string)<br/>          })), [])<br/>        }))<br/>      }))<br/>    })), [])<br/>    parameters = optional(object({<br/>      network_mapping_list = optional(list(object({<br/>        availability_zone_network_mapping_list = optional(list(object({<br/>          recovery_network = optional(object({<br/>            name = optional(string)<br/>            uuid = optional(string)<br/>          }))<br/>          test_network = optional(object({<br/>            name = optional(string)<br/>            uuid = optional(string)<br/>          }))<br/>          availability_zone_url = optional(string)<br/>        })), [])<br/>      })), [])<br/>      floating_ip_assignment_list = optional(list(object({<br/>        vm_uuid = optional(string)<br/>        test_floating_ip_config = optional(object({<br/>          ip                          = optional(string)<br/>          should_allocate_dynamically = optional(bool)<br/>        }))<br/>        recovery_floating_ip_config = optional(object({<br/>          ip                          = optional(string)<br/>          should_allocate_dynamically = optional(bool)<br/>        }))<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_recovery_point_replicates"></a> [recovery\_point\_replicates](#input\_recovery\_point\_replicates) | Map of recovery point replicate operations (v2) | <pre>map(object({<br/>    ext_id         = string<br/>    cluster_ext_id = optional(string)<br/>    pc_ext_id      = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_recovery_point_restores"></a> [recovery\_point\_restores](#input\_recovery\_point\_restores) | Map of recovery point restore operations (v2) | <pre>map(object({<br/>    ext_id         = string<br/>    cluster_ext_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_recovery_points"></a> [recovery\_points](#input\_recovery\_points) | Map of recovery points (v2) to create | <pre>map(object({<br/>    name                = optional(string)<br/>    expiration_time     = optional(string)<br/>    status              = optional(string, "COMPLETE")<br/>    recovery_point_type = optional(string) # CRASH_CONSISTENT or APPLICATION_CONSISTENT<br/>    vm_recovery_points = optional(list(object({<br/>      vm_ext_id           = string<br/>      name                = optional(string)<br/>      expiration_time     = optional(string)<br/>      status              = optional(string, "COMPLETE")<br/>      recovery_point_type = optional(string)<br/>    })), [])<br/>    volume_group_recovery_points = optional(list(object({<br/>      volume_group_ext_id = string<br/>      name                = optional(string)<br/>      expiration_time     = optional(string)<br/>      status              = optional(string, "COMPLETE")<br/>      recovery_point_type = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_restore_protected_resources"></a> [restore\_protected\_resources](#input\_restore\_protected\_resources) | Map of restore protected resource operations (v2) | <pre>map(object({<br/>    ext_id         = string<br/>    cluster_ext_id = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ids"></a> [cluster\_ids](#output\_cluster\_ids) | Map of cluster keys to their external IDs |
| <a name="output_cluster_node_additions"></a> [cluster\_node\_additions](#output\_cluster\_node\_additions) | Node-addition actions (v2) applied, keyed by map key |
| <a name="output_clusters"></a> [clusters](#output\_clusters) | PE clusters (v2) managed by this module (id, ext\_id, name per key) |
| <a name="output_node_discoveries"></a> [node\_discoveries](#output\_node\_discoveries) | Unconfigured-node discovery results (v2), keyed by map key |
| <a name="output_node_network_fetches"></a> [node\_network\_fetches](#output\_node\_network\_fetches) | Unconfigured-node network-info fetch results (v2), keyed by map key |
| <a name="output_outputs"></a> [outputs](#output\_outputs) | Aggregate of all module outputs (spec §7.6 contract, consumed by the landing zone as module.<x>.outputs). |
| <a name="output_pe_summary"></a> [pe\_summary](#output\_pe\_summary) | Summary of Prism Element protection and recovery resources |
| <a name="output_promote_protected_resources"></a> [promote\_protected\_resources](#output\_promote\_protected\_resources) | Promote protected resource operations (v2) |
| <a name="output_protection_policies"></a> [protection\_policies](#output\_protection\_policies) | Protection policies (v2) created |
| <a name="output_protection_policy_ids"></a> [protection\_policy\_ids](#output\_protection\_policy\_ids) | Map of protection policy keys to their IDs |
| <a name="output_recovery_plan_ids"></a> [recovery\_plan\_ids](#output\_recovery\_plan\_ids) | Map of recovery plan keys to their IDs |
| <a name="output_recovery_plans"></a> [recovery\_plans](#output\_recovery\_plans) | Recovery plans (v1) created |
| <a name="output_recovery_point_ids"></a> [recovery\_point\_ids](#output\_recovery\_point\_ids) | Map of recovery point keys to their external IDs |
| <a name="output_recovery_point_replicates"></a> [recovery\_point\_replicates](#output\_recovery\_point\_replicates) | Recovery point replicate operations (v2) |
| <a name="output_recovery_point_restores"></a> [recovery\_point\_restores](#output\_recovery\_point\_restores) | Recovery point restore operations (v2) |
| <a name="output_recovery_points"></a> [recovery\_points](#output\_recovery\_points) | Recovery points (v2) created |
| <a name="output_restore_protected_resources"></a> [restore\_protected\_resources](#output\_restore\_protected\_resources) | Restore protected resource operations (v2) |
<!-- END_TF_DOCS -->
