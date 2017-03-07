#!/usr/bin/env bash

set -e

sudo apt-get install -y petname

# Shamelessly ripped from juju-solutions/kubernetes-jenkins repository

MAXIMUM_WAIT_SECONDS=3600

# Run a command in a loop waiting for specific output use MAXIMUM_WAIT_SECONDS.
function run_and_wait() {
  local cmd=$1
  local match=$2
  local sleep_seconds=${3:-5}
  local start_time=`date +"%s"`
  # Run the command in a loop looking for output.
  until $(${cmd} | grep -q "${match}"); do 
    # Check the time so this does not loop forever.
    check_time ${start_time} ${MAXIMUM_WAIT_SECONDS}
    sleep ${sleep_seconds}
  done
}

# The check_time function requires two parameters start_time and max_seconds.
function check_time() {
  local start_time=$1
  local maximum_seconds=$2
  local current_time=`date +"%s"`
  local difference=$(expr ${current_time} - ${start_time})
  # When the difference is greater than maximum seconds, exit this script.
  if [[ ${difference} -gt ${maximum_seconds} ]]; then
    echo "The process is taking more than ${maximum_seconds} seconds!"
    # End this script because too much time has passed.
    exit 3
  fi
}

KUBE_RANDOM=$(petname)
JENK_RANDOM=$(petname)

# READ cloud/region, and optional credential
echo "Enter your cloud of choice (eg: google/us-central1):"
read USER_CLOUD

# Cloud is required
if [ -z "${USER_CLOUD}" ]; then
    echo "Missing cloud details."
    exit 1
fi

# Credential is optional
echo "[optional] Enter your credential (eg: work):"
read USER_CREDENTIAL

if [ ! -z "${USER_CREDENTIAL}" ]; then
   CLOUD_CREDENTIAL="--credential=${USER_CREDENTIAL}"
fi

juju add-model jenkins-${JENK_RANDOM} ${USER_CLOUD} ${CLOUD_CREDENTIAL}
juju add-model kubernetes-${KUBE_RANDOM} ${USER_CLOUD} ${CLOUD_CREDENTIAL}

juju switch kubernetes-${KUBE_RANDOM}
juju deploy canonical-kubernetes

juju switch jenkins-${JENK_RANDOM}
juju deploy jenkins.yaml

echo "Set the Jenkins admin password:"
read -s JENK_PASSWORD

# If no admin password was specified within the timeout period, it's "admin"
juju config jenkins password=${JENK_PASSWORD:=admin}

echo "Waiting for kubernetes deployment convergence"
# When deployment is complete, run copy_kubernetes_credentials.sh
run_and_wait "juju status -m kubernetes-${KUBE_RANDOM}" "Kubernetes master running" 15

echo "Inserting kubernetes credentials"
./copy_kubernetes_credentials.sh kubernetes-${KUBE_RANDOM}

echo "Dont forget to enlist dockerhub password in the job!"
