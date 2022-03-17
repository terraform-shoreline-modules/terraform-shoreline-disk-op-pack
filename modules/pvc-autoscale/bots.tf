# Bot that fires the resize action when the disk exceeds the chosen threshold.
resource "shoreline_bot" "pvc_autoscale_disk_bot" {
  name = "${var.prefix}disk_bot"
  description = "Disk utilization handler bot"
  # If the disk is filled more than the threshold, increase it's size.
  # NOTE: Use a reference to the action and alarm, to ensure they are created and available before the bot.
  command = "if ${shoreline_alarm.pvc_autoscale_disk_alarm.name} then ${shoreline_action.pvc_autoscale_resize_pvc.name}('${var.pvc_regex}', ${var.increment}, ${var.max_size}) fi"

  # general type of bot this can be "standard" or "custom"
  family = "custom"

  enabled = true
}

