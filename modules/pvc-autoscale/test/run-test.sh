#!/bin/bash

# exit on any errors
set -e

############################################################
# Include general utility functions and test harness

. ./test-util.sh

############################################################
# Pre-flight validation

check_command kubectl


############################################################
# test specific Utility functions

get_disk_stats() {
  echo "pod | app='pvc-test' | \`df -h\`" | ${CLI} | grep tofill | sed -e 's/^.*|//'
}

get_disk_filled_pct() {
  echo "pod | app='pvc-test' | testpvc_check_disk('tofill')" | ${CLI} | grep -A1 'STATUS' | tail -n 1 | sed -e 's/^.*|//'
}

check_pvc_yaml() {
  echo "pod | app='shoreline' | limit=1 | \`ls /tmp/\`" | ${CLI} | grep "pvc_test.yaml"
}

check_pvc_pod() {
  echo "pod | app='pvc-test' | limit=1" | ${CLI} | grep "pvc-test"
}


############################################################
# setup

do_setup_terraform() {
  echo "Setting up terraform objects"
  # templatize namespace <cluster>-cust in pvc_test.yaml
  cat pvc_test.yaml.template | sed -e "s/\${CLUSTER}/${CLUSTER}/g" > pvc_test.yaml
  terraform init
  terraform apply --auto-approve
}

do_setup_kube() {
  echo "Setting up k8s objects (pv, pvc, pods)"
  # XXX should we pre-delete any existing: pod,pvc,pv -- just in case

  # dynamically wait for the yaml file to propagate
  echo "waiting for yaml file to propagate ..."
  used=0
  while [ ! check_pvc_yaml ]; do
    echo "  waiting..."
    sleep ${PAUSE_TIME}
    # timeout after maximum wait and fail
    used=$(( ${used} + ${PAUSE_TIME} ))
    if [ ${used} -gt ${MAX_WAIT} ]; then
      do_timeout "yaml propagation"
    fi
  done
  #check_pvc_yaml
  # unfortunately, shoreline pod doesn't have deployment/pv create permissions...
  #echo "pod | app='shoreline' | limit=1 | \`kubectl apply -f /tmp/pvc_test.yaml\`" | ${CLI}
  kubectl apply -f ./pvc_test.yaml
  # dynamically check for pod...
  echo "waiting for pvc-test pod creation ..."
  used=0
  until check_pvc_pod; do
    echo "  waiting..."
    sleep ${PAUSE_TIME}
    # timeout after maximum wait and fail
    used=$(( ${used} + ${PAUSE_TIME} ))
    if [ ${used} -gt ${MAX_WAIT} ]; then
      do_timeout "pod creation"
    fi
  done
  check_pvc_pod

  sleep 20
  
  echo " host | pod | app='pvc-test' | \`apt-get update\` " | ${CLI}
  echo " host | pod | app='pvc-test' | \`apt-get install -y jq\` " | ${CLI}
  echo " host | pod | app='pvc-test' | \`curl -LO https://dl.k8s.io/release/v1.20.0/bin/linux/amd64/kubectl\` " | ${CLI}
  echo " host | pod | app='pvc-test' | \`chmod +x kubectl; mv kubectl /bin/\` " | ${CLI}

  echo "a little quiet time for the pod to stabilize and register ..."
  sleep 20
}


############################################################
# cleanup

do_cleanup_kube() {
  echo "Cleaning up k8s objects (pv, pvc, pods)"
  kubectl -n pvc-test-ns delete pod,deployment,pvc,role,rolebinding --all
  #kubectl delete pv resize-test-pv # auto-deleted
  kubectl delete storageclass pvc-test-storage-class
  kubectl -n pvc-test-ns delete sa pvc-test-sa
}

############################################################
# actual tests

run_tests() {
  # verify that the pvc-test pod resource was created
  pods=`echo "pod | app='pvc-test' | count" | ${CLI} | grep -A1 'RESOURCE_COUNT' | tail -n1`

  # count alarms before we started
  pre_fired=`get_event_counts_fired pvc`
  pre_cleared=`get_event_counts_cleared pvc`
  #pre_total=`get_event_counts pvc | cut -d '|' -f 9`

  # get actual disk size (NOTE: k8s may give a much larger drive than requested)
  disk_stats=`get_disk_stats`
  # Filesystem      Size  Used Avail Use% Mounted on
  # /dev/nvme0n1p1   80G   69G   12G  86% /tofill
  # NOTE: we assume the size is in Gb
  echo "disk stats is ${disk_stats}"
  disk_size=`echo ${disk_stats} | tr -s ' ' | cut -d' ' -f 2 | tr -d 'G'`
  if echo "${disk_size}" | grep -e '[MK]'; then
    # round up to 1 Gb
    disk_size=1
  fi
  pre_fill=`get_disk_filled_pct`

  echo "disk size is ${disk_size}"
  # fill disk incrementally (to prevent timeout) to 35% with 1Gb files
  fill_files=$(( ( (${disk_size} * 35) / 100) ))
  if [ ${fill_files} -eq 0 ]; then
    fill_files=1
  fi
  echo "creating ${fill_files} * 1Gb fill files"
  for i in $(seq 1 ${fill_files}); do
    echo "  fill file ... /tofill/bar${i}"
    echo "pod | app='pvc-test' | \`head -c 1000000000 /dev/zero > /tofill/bar${i}\`" | ${CLI}
  done

  echo "waiting for resize alarm to fire ..."
  # verify that the alarm fired:
  post_fired=`get_event_counts_fired pvc`
  get_event_counts
  used=0
  while [ "${post_fired}" == "${pre_fired}" ]; do
    echo "  waiting..."
    sleep ${PAUSE_TIME}
    post_fired=`get_event_counts_fired pvc`
    # timeout after maximum wait and fail
    used=$(( ${used} + ${PAUSE_TIME} ))
    if [ ${used} -gt ${MAX_WAIT} ]; then
      do_timeout "alarm to fire"
    fi
  done

  echo "waiting for resize alarm to clear ..."
  post_cleared=`get_event_counts_cleared pvc`
  used=0
  while [ "${post_cleared}" == "${pre_cleared}" ]; do
    echo "  waiting..."
    sleep ${PAUSE_TIME}
    post_cleared=`get_event_counts_cleared pvc`
    # timeout after maximum wait and fail
    used=$(( ${used} + ${PAUSE_TIME} ))
    if [ ${used} -gt ${MAX_WAIT} ]; then
      do_timeout "alarm to clear"
    fi
  done

  pre_disk_size=`echo ${disk_stats} | tr -s ' ' | cut -d' ' -f 2 | tr -d 'G'`
  post_disk_stats=`get_disk_stats`
  post_disk_size=`echo ${post_disk_stats} | tr -s ' ' | cut -d' ' -f 2 | tr -d 'G'`
  if  [ "${post_disk_size}" == "${pre_disk_size}" ]; then
    echo -n -e "${RED}"
    echo "============================================================"
    echo "ERROR: Volume failed to grow!"
    echo "============================================================"
    echo -e "${NC}"
  else
    echo -n -e "${GREEN}"
    echo "============================================================"
    echo "Successfully resized from ${pre_disk_size} to ${post_disk_size}"
    echo "============================================================"
    echo -e "${NC}"
    RETURN_CODE=0
  fi
}

main "$@"


############################################################
# useful op commands

# testpvc_resize_pvc(PVC_REGEX="tofill", PVC_INCREMENT=1, PVC_MAX_SIZE=5, ALARM_NAMESPACE="pvc-test-ns", ALARM_POD_NAME="pvc-test-76cd5866b4-nq9tk")
# pod | app='pvc-test' | testpvc_check_disk('tofill') | `ls -lh /tofill/; echo; df -h`
# pod | app='pvc-test' | `for f in {1..3}; do echo $f; head -c 2000000000 /dev/zero > /tofill/bar$f; done`
# events | alarm_name =~ "pvc" | count
#   GROUP     | EVENT_TYPE | FIRED | CLEARED | TOTAL_COUNT 
#   group_all | ALARMS     | 1     | 0       | 1           
#   38        | ALARMS     | 1     | 0       | 1           

