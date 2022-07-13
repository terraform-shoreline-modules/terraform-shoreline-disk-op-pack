# Notebook for pvc-autoscale module
resource "shoreline_notebook" "pvc_autoscale_notebook" {
  name = "${var.prefix}pvc_autoscale_notebook"
  description = "Notebook for checking disk usgae and PVC autoscale."
  data = file("${path.module}/data/pvc_autoscale_notebook.json")
}
