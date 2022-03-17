# Alarm that triggers when the selected disk exceeds the chosen size.
resource "shoreline_alarm" "pvc_autoscale_disk_alarm" {
  name = "${var.prefix}disk_alarm"
  description = "Alarm on kubernetes PVC growing larger than a percentage threshold."
  # The query that triggers the alarm: is the disk usage greater than a percentage threshold.
  fire_query  = "${shoreline_action.pvc_autoscale_check_disk.name}('${var.mount_regex}') >= ${var.disk_threshold}"
  # The query that ends the alarm: is the disk usage lower than the percentage threshold.
  clear_query = "${shoreline_action.pvc_autoscale_check_disk.name}('${var.mount_regex}') < ${var.disk_threshold}"
  # How often is the alarm evaluated. This is a more slowly changing metric, so every 60 seconds is fine.
  check_interval_sec = "${var.check_interval}"
  # User-provided resource selection
  resource_query = "${var.resource_query}"

  # UI / CLI annotation informational messages:
  fire_short_template = "Disk (PVC) approaching capacity threshold."
  resolve_short_template = "Disk (PVC) below capacity threshold."
  # include relevant parameters, in case the user has multiple instances on different volumes/resources
  fire_long_template = "Disk (PVC ${var.pvc_regex}) approaching capacity threshold ${var.disk_threshold} on ${var.resource_query}"
  resolve_long_template = "Disk (PVC ${var.pvc_regex}) below capacity threshold ${var.disk_threshold} on ${var.resource_query}"

  # low-frequency, and a linux command, so compiling won't help
  compile_eligible = false

  # alarm is raised local to a resource (vs global)
  raise_for = "local"
  # raised on a linux command (not a standard metric)
  metric_name = "check_disk"
  # threshold value
  condition_value = "${var.disk_threshold}"
  # fires when above the threshold
  condition_type = "above"
  # general type of alarm ("metric", "custom", or "system check")
  family = "custom"

  enabled = true
}

