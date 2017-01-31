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
juju add-model jenkins-${JENK_RANDOM} google/us-central1 --credential=work
juju add-model kubernetes-${KUBE_RANDOM} google/us-central1 --credential=work

juju switch kubernetes-${KUBE_RANDOM}
juju deploy canonical-kubernetes

juju switch jenkins-${JENK_RANDOM}
juju deploy bundle.yaml

echo "What jenkins admin password?"
read JENK_PASSWORD

juju config jenkins password=$JENK_PASSWORD

if [ ! -f './workspaces/workspace.tgz' ]; then
 "Creating workspace archive"
 cd workspaces
 tar cvfz workspace.tgz *
 cd ..
fi
echo "attaching workspace resource"
set +e
# This is known to fail, so try until it succeeds

until juju attach jenkins-workspace workspace=workspaces/workspace.tgz
do
  echo "Attach not successful, retrying in 3 seconds."
  sleep 3
done

# When deployment is complete, run copy_kubernetes_credentials.sh
run_and_wait "juju status -m kubernetes-${KUBE_RANDOM}" "Kubernetes master running" 15

echo "Inserting kubernetes credentials"
./copy_kubernetes_credentials.sh kubernetes-${KUBE_RANDOM}

echo "Dont forget to enlist dockerhub password in the job!"
