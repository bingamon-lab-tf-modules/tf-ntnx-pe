data "nutanix_clusters_v2" "clusters" {}

# Existing protection state (gated). These lookups surface the current
# protection posture of the target Prism Central so callers can reconcile
# against what already exists before creating new policies or recovery points.
data "nutanix_protection_policies_v2" "existing" {
  count = var.enable_data_lookups ? 1 : 0
}

data "nutanix_recovery_points_v2" "existing" {
  count = var.enable_data_lookups ? 1 : 0
}

# Host inventory (gated). Surfaces the physical hosts of the target Prism
# Central so cluster-lifecycle callers (issue 589) can cross-check node counts
# before forming or expanding a cluster. The clusters_v2 lookup already exists
# above; this adds the host-level view.
data "nutanix_hosts_v2" "hosts" {
  count = var.enable_data_lookups ? 1 : 0
}
