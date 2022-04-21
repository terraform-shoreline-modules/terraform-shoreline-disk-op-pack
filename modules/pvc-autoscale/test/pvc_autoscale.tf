 
terraform {
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


locals {
  prefix          = "testpvc_"
}

module "pvc_autoscale" {
  #url = "${var.shoreline_url}"
  #source             = "terraform-shoreline-modules/disk-op-pack/shoreline//modules/pvc-autoscale"
  source             = "../"
  prefix             = "${local.prefix}"
  pvc_regex          = "resize-test-pvc"
  mount_regex        = "tofill"
  disk_threshold     = 30
  increment          = 10
  max_size           = 200
  # check more frequently to speed up test
  check_interval     = 10
  resource_query     = "pods | app='pvc-test'"
  resize_script_path = "/tmp"

  providers = { 
    shoreline = shoreline
  }
}

# Push the script that creates the pv, pvc, and pod.
resource "shoreline_file" "pvc_test_yaml" {
  name = "${local.prefix}pvc_test_yaml"
  description = "k8s yaml config to create test disk and pod."
  input_file = "${path.module}/pvc_test.yaml"
  destination_path = "/tmp/pvc_test.yaml"
  resource_query = "pods | app='shoreline'"
  enabled = true
}

