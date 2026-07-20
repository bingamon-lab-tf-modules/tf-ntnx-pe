data "nutanix_clusters_v2" "clusters" {}

# Host inventory (gated). Surfaces the physical hosts of the target Prism
# Central so cluster-lifecycle callers (issue 589) can cross-check node counts
# before forming or expanding a cluster. The clusters_v2 lookup already exists
# above; this adds the host-level view.
data "nutanix_hosts_v2" "hosts" {
  count = var.enable_data_lookups ? 1 : 0
}
