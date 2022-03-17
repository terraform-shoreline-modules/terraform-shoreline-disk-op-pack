# Push the script that actually performs the resize to the selected nodes.
resource "shoreline_file" "pvc_autoscale_resize_script" {
  name = "${var.prefix}resize_script"
  description = "Script to resize kubernetes PVC disks."
  input_file = "${path.module}/data/resize_pvc.sh"              # source file (relative to this module)
  destination_path = "${var.resize_script_path}/resize_pvc.sh"  # where it is copied to on the selected resources
  resource_query = "${var.resource_query}"                      # which resources to copy to
  enabled = true
}

