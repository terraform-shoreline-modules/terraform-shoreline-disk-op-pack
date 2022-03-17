
#NOTE: This is passed in via the SHORELINE_URL env var.
#        SHORELINE_TOKEN is also required.
#variable "shoreline_url" {
#  type        = string
#  #default     = "https://test.us.api.shoreline-test4.io"
#  description = "The API URL for the shoreline service."
#}

variable "prefix" {
  type        = string
  description = "A prefix to isolate multiple instances of the module with different parameters."
  default     = ""
}

variable "resource_query" {
  type        = string
  description = "The set of hosts/pods/containers monitored and affected by this module."
}

variable "pvc_regex" {
  type        = string
  description = "A regular expression to match and select the monitored disk volumes (PVC)."
}

variable "mount_regex" {
  type        = string
  description = "A regular expression to match and select the monitored disk volumes (mountpoint)."
}

variable "disk_threshold" {
  type        = number
  description = "The high-water-mark, as a percentage, above which the disk volume is resized."
  default     = 80
}

variable "increment" {
  type        = number
  description = "The amount to increase the disk volume size when it fills."
  default     = 10
}

variable "max_size" {
  type        = number
  description = "Maximum size to grow the disk volume by."
  default     = 100
}

variable "check_interval" {
  type        = number
  description = "Frequency in seconds to check the disk size."
  default     = 60
}

variable "resize_script_path" {
  type        = string
  description = "Destination (on selected resources) for the resize script."
  default     = "/agent/scripts"
}
