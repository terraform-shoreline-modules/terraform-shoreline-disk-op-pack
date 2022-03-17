#!/bin/bash

# exit on any errors
set -e

TEST_ONLY=0

RETURN_CODE=1
# seconds to wait on k8s/alarms/etc
MAX_WAIT=240
# seconds to pause between checking k8s/alarms/etc
PAUSE_TIME=5

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


on_exit () {
  set +e
  echo -n -e "${RED}"
  echo "============================================================"
  echo "Test script failed."
  echo "============================================================"
  echo "Attempting cleanup..."
  echo -e "${NC}"
  do_cleanup
  exit 1
}
trap on_exit ERR
#trap on_exit EXIT

PATH=${PATH}:~/work/shoreline/cli/go/bin/
# PATH=${PATH}:~/work/shoreline/cli/go/bin CLI=`command -v oplang_cli`


############################################################
# Utility functions

banner() {
  echo -n -e "${1}"
  echo "============================================================"
  echo "${2}"
  echo "============================================================"
  echo -e "${NC}"
}

ok_banner() {
  banner "${GREEN}" "${1}"
}

error_banner() {
  banner "${RED}" "${1}"
}

pre_error() {
  error_banner "$1"
  exit 1
}

do_timeout() {
  error_banner "ERROR: Timed out waiting for $1"
  echo -n -e "${RED}"
  echo "Attempting cleanup..."
  echo -e "${NC}"
  do_cleanup
  exit 2
}

check_command() {
  command -v $1 > /dev/null || pre_error "missing command $1"
}

check_env() {
  env | grep -e "^$1=" ||  pre_error "missing env variable $1"
}

get_event_counts() {
  echo "events | name =~ '${1}' | count" | ${CLI} | grep "group_all" || echo 0
}

get_event_counts_cleared() {
  get_event_counts "${1}" | cut -d '|' -f 8 | tr -d ' ' || echo 0
}

get_event_counts_fired() {
  get_event_counts "${1}" | cut -d '|' -f 7 | tr -d ' ' || echo 0
}

check_pod_by_app() {
  echo "pod | app='${1}' | limit=1" | ${CLI} | grep "${1}"
}

count_pods_by_app() {
  echo "pod | app='${1}'" | ${CLI} | grep "${1}" | wc -l
}

#wait_for_condition() {
#  echo "waiting for ${1} ..."
#  used=0
#  until eval "$2"; do
#    echo "  waiting..."
#    sleep ${PAUSE_TIME}
#    # timeout after maximum wait and fail
#    used=$(( ${used} + ${PAUSE_TIME} ))
#    if [ ${used} -gt ${MAX_WAIT} ]; then
#      do_timeout "${1}"
#    fi
#  done
#}

#wait_while_condition() {
#  echo "waiting for ${1} ..."
#  used=0
#  while eval "$2"; do
#    echo "  waiting..."
#    sleep ${PAUSE_TIME}
#    # update condition
#    eval "${3}"
#    # timeout after maximum wait and fail
#    used=$(( ${used} + ${PAUSE_TIME} ))
#    if [ ${used} -gt ${MAX_WAIT} ]; then
#      do_timeout "${1}"
#    fi
#  done
#}


############################################################
# Pre-flight validation

check_command terraform
check_command oplang_cli
CLI=`command -v oplang_cli`

check_env SHORELINE_URL
check_env SHORELINE_TOKEN
check_env CLUSTER

############################################################
# setup

do_setup_terraform() {
  echo "Setting up terraform objects"
  terraform init
  terraform apply --auto-approve
}

do_setup() {
  do_setup_terraform
  do_setup_kube
}

############################################################
# cleanup

do_cleanup_terraform() {
  echo "Cleaning up terraform objects"
  terraform destroy --auto-approve
}

do_cleanup() {
  if [ "${TEST_ONLY}" == "0" ]; then
    do_cleanup_kube
    do_cleanup_terraform
  fi
}


############################################################
# main

do_all() {
  do_setup
  run_tests
  do_cleanup
  exit ${RETURN_CODE}
}

main() {
  case $1 in
         setup) do_setup ;;
       cleanup) do_cleanup ;;
    debug-test) TEST_ONLY=1; set -x; run_tests  ;;
     test-only) TEST_ONLY=1; run_tests  ;;
             *) do_all ;;
  esac
}

