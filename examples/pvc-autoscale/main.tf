
# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these parameters/secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# SHORELINE_URL   - The API url for your shoreline cluster, i.e. "https://<customer>.<region>.api.shoreline-<cluster>.io"
# SHORELINE_TOKEN - The alphanumeric access token for your cluster. (Typically from Okta.)

terraform {
  # Setting 0.13.1 as the minimum version. Older versions are missing significant features.
  required_version = ">= 0.13.1"

  required_providers {
    shoreline = {
      source  = "shorelinesoftware/shoreline"
      version = ">= 1.2.2"
    }
  }
}

provider "shoreline" {
  # provider configuration here
  retries = 2
}

module "pvc_autoscale" {
  # Location of the module
  source = "terraform-shoreline-modules/disk-op-pack/shoreline//modules/pvc-autoscale"

  # Prefix to allow multiple instances of the module, with different params
  prefix = "pvca_"

  # The set of hosts/pods/containers monitored and affected by this module.
  resource_query = "host | pod | app='pvc-autoscale-test'"

  # A regular expression to match and select the monitored disk volumes (PVC).
  pvc_regex = "my-disk-pvc"

  # A regular expression to match and select the monitored disk volumes (mountpoint).
  mount_regex = "my_disk"

  # The high-water-mark, as a percentage, above which the disk volume is resized.
  disk_threshold = 75

  # The amount to increase the disk volume size when it fills (in the units it was created with, e.g. Gb).
  increment = 5

  # Maximum size to grow the disk volume by (in the units it was created with, e.g. Gb).
  max_size = 100

  # Frequency in seconds to evaluate alarms.
  check_interval = 60

  # Destination (on selected resources) for the resize script.
  resize_script_path = "/agent/scripts"

  providers = { 
    shoreline = shoreline
  }
}
