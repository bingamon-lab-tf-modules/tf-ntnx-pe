data "nutanix_clusters_v2" "clusters" {}

data "nutanix_protection_policies_v2" "existing" {
  count = var.enable_data_lookups ? 1 : 0
}
