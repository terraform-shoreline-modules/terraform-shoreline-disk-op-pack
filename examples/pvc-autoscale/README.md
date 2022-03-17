# Shoreline PVC Autoscale Op Pack

<table role="table" style="vertical-align: middle;">
  <thead>
    <tr style="background-color: #fff">
      <th style="padding: 6px 13px; border: 1px solid #B1B1B1; text-align: center;" colspan="3">Provider Support</th>
    </tr>
  </thead>
  <tbody>
    <tr style="background-color: #E2E2E2">
      <td style="padding: 6px 13px; border: 1px solid #B1B1B1; text-align: center;">AWS</td>
      <td style="padding: 6px 13px; border: 1px solid #B1B1B1; text-align: center;">Azure</td>
      <td style="padding: 6px 13px; border: 1px solid #B1B1B1; text-align: center;">GCP</td>
    </tr>
    <tr>
      <td style="padding-top: 6px; vertical-align: bottom; border: 1px solid #B1B1B1; text-align: center;"><svg xmlns="http://www.w3.org/2000/svg" style="width: 1.5rem; height: 1.5rem;" fill="none" viewBox="0 0 24 24" stroke="#6CB169"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg></td>
      <td style="vertical-align: bottom; border: 1px solid #B1B1B1; text-align: center;"><svg xmlns="http://www.w3.org/2000/svg" style="width: 1.5rem; height: 1.5rem;" fill="none" viewBox="0 0 24 24" stroke="#C65858"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg></td>
      <td style="padding-top: 6px; vertical-align: bottom; border: 1px solid #B1B1B1; text-align: center;"><svg xmlns="http://www.w3.org/2000/svg" style="width: 1.5rem; height: 1.5rem;" fill="none" viewBox="0 0 24 24" stroke="#6CB169"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg></td>
    </tr>  
  </tbody>
</table>

-> Azure does not currently support resizing attached volumes.

The PVC Autoscale Op Pack is a collection of Shoreline objects to monitor, alert, and automatically resize kubernetes persistent volumes. 

Automatically resize a kubernetes persistent-volume, up to a maximum size, 
by a certain increment, when it exceeds a maximum percentage filled.

Kubernetes provides persistent storage via persistent-volumes and persistent-volume-claims.
However, out of the box, it doesn't adaptively manage the size of those volumes.
So applications like ElasticSearch, RabbitMQ, Kafka, MySql, etc. will inevitably run out of space periodically.
This leaves users having to manually monitor and expand the volumes as data grows,
or significantly oversizing volumes for future growth (and paying for capacity they don't need yet).

But you can have the best of both worlds, by automatically growing your volumes along with need.


## Requirements

The following tools are required on the monitored resources, with appropriate permissions:

1. The 'df'  command.
1. The 'kubectl' command with appropriate PV/PVC permissions.

## Usage

The following example sets up the Op Pack to resize a kubernetes persistent volume when it nears capacity.

```hcl
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
```

## Manual command examples

These commands use Shoreline's expressive [Op language](https://docs.shoreline.io/op) to retrieve fleet-wide data using the generated actions from the PVC Autoscaler module.

-> These commands can be executed within the [Shoreline CLI](https://docs.shoreline.io/installation#cli) or [Shoreline Notebooks](https://docs.shoreline.io/ui/notebooks).

-> See the [shoreline action resource](https://registry.terraform.io/providers/shorelinesoftware/shoreline/latest/docs/resources/action) and the [Shoreline Actions](https://docs.shoreline.io/actions) documentation for details.


### Manually check used percentage of disk '/tofill'

```
op> pods | name =~ "pvc-test" | testpvc_check_disk("tofill")
```

### Manually list pods with used percentage of disk '/tofill' is greater than 30 percent

```
op> pods | name =~ "pvc-test" | filter( testpvc_check_disk('tofill') >= 30 )
```

### Show PVC alarms that have triggered

```
op> events | name =~ 'pvc'
```

