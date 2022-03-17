# Action to calculate the percentage filled on the selected resources and disk.
resource "shoreline_action" "pvc_autoscale_check_disk" {
  name = "${var.prefix}check_disk"
  description = "Check disk utilization by regex, returns percent used."
  # Parameters passed in: the regular expression to select disk volumes (PVCs).
  params = [ "DISK_REGEX" ]
  # Extract the percentage used for the matching disk and retun it.
  command = "`exit $(df -h | grep \"$DISK_REGEX\" | awk '{ print $5 }' | sed 's/.$//')`"
  # Select the shell to run 'command' with.
  shell = "/bin/sh"

  # UI / CLI annotation informational messages:
  start_short_template    = "Checking disk size."
  error_short_template    = "Error checking disk size."
  complete_short_template = "Finished checking disk size."
  start_long_template     = "Checking disk ${var.pvc_regex} size."
  error_long_template     = "Error checking disk ${var.pvc_regex} size."
  complete_long_template  = "Finished checking disk ${var.pvc_regex} size."

  enabled = true
}

# Action to perform the resize
resource "shoreline_action" "pvc_autoscale_resize_pvc" {
  name = "${var.prefix}resize_pvc"
  description = "Resize Persistent Volume Claim (PVC)"
  # Run the resize script (which was copied by the pvc_autoscale_resize_script file object).
  command = "`cd ${var.resize_script_path} && chmod +x ./resize_pvc.sh && ./resize_pvc.sh`"
  # Parameters for:
  #    volume matching regular expression
  #    amount to increment the size by
  #    maximum size to let the volume grow to
  params = ["PVC_REGEX", "PVC_INCREMENT", "PVC_MAX_SIZE"]
  resource_query = "${var.resource_query}"

  # UI / CLI annotation informational messages:
  start_short_template    = "Resizing disk."
  error_short_template    = "Error resizing disk."
  complete_short_template = "Finished resizing disk."
  start_long_template     = "Resizing disk ${var.pvc_regex} up by ${var.increment}, limit: ${var.max_size}."
  error_long_template     = "Error resizing disk ${var.pvc_regex} up by ${var.increment}, limit: ${var.max_size}."
  complete_long_template  = "Finished resizing disk ${var.pvc_regex} up by ${var.increment}, limit: ${var.max_size}."

  enabled = true
}

# Action to perform the resize manually
resource "shoreline_action" "pvc_autoscale_resize_pvc_manual" {
  name = "${var.prefix}resize_pvc_manual"
  description = "Resize Persistent Volume Claim (PVC) manually"
  # Run the resize script (which was copied by the pvc_autoscale_resize_script file object).
  command = "`cd ${var.resize_script_path} && chmod +x ./resize_pvc.sh && ./resize_pvc.sh $PVC_POD_NAME $PVC_NAMESPACE`"
  # Parameters for:
  #    volume matching regular expression
  #    amount to increment the size by
  #    maximum size to let the volume grow to
  #    pod name to execute the resize on
  #    k8s namespace to execute the resize in
  params = ["PVC_REGEX", "PVC_INCREMENT", "PVC_MAX_SIZE", "PVC_POD_NAME", "PVC_NAMESPACE"]
  resource_query = "${var.resource_query}"

  # UI / CLI annotation informational messages:
  start_short_template    = "Resizing disk."
  error_short_template    = "Error resizing disk."
  complete_short_template = "Finished resizing disk."
  start_long_template     = "Resizing disk."
  error_long_template     = "Error resizing disk."
  complete_long_template  = "Finished resizing disk."

  enabled = true
}

