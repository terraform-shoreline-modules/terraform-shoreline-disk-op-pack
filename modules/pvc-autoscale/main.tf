################################################################################
# Module: pvc_autoscale
# 
# Automatically resize a kubernetes persistent-volume, up to a maximum size, 
# by a certain increment, when it exceeds a maximum percentage filled.
#
# Example usage:
#
#   module "pvc_autoscale" {
#     # Location of the module:
#     source             = "./config"
#   
#     # Namespace to allow multiple instances of the module, with different params:
#     prefix             = "pvc_resize_bookstore_"
#   
#     # Resource query to select the affected resources:
#     resource_query     = "bookstore"
#   
#     # Regular expresssion to select the affected disk:
#     pvc_regex          = "data-volume"
#   
#     # Maximum percentage filled before the disk is enlarged:
#     disk_threshold     = 80
#   
#     # Amount to increase the size of the disk by: 
#     increment          = 10
#   
#     # Maximum size to allow the disk to grow to:
#     max_size           = 100
#   
#     # Destination of the resize script on the selected resources:
#     resize_script_path = "/agent/scripts"
#   }

################################################################################

terraform {
  required_providers {
    shoreline = {
      source  = "shorelinesoftware/shoreline"
    }
  }
}

## provider config is given by caller
#
#provider "shoreline" {
#  # provider configuration here
#  #url = "${var.shoreline_url}"
#  retries = 2
#  #debug = true
#}


