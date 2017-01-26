#!/bin/bash 

# This script requires 1 parameter, the Juju model running kubernetes.

set -x 

if [ -z "${1}" ]; then
  echo "Enter the Juju model running Kubernetes: "
  read KUBERNETES_MODEL
else 
  KUBERNETES_MODEL=${1}
fi
if [ -z "${2}" ]; then
  JENKINS_MODEL=$(juju switch)
else
  JENKINS_MODEL=${2}
fi

echo "Change to the Kubernetes model ${KUBERNETES_MODEL}"
juju switch ${KUBERNETES_MODEL}
echo "Copying the Kubernetes credentials."
juju scp kubernetes-master/0:config .kube/config
juju scp kubernetes-master/0:kubectl ./kubectl

tar -cvzf kubernetes_credentials.tgz .kube/config kubectl

echo "Change to the Jenkins model ${JENKINS_MODEL}"
juju switch ${JENKINS_MODEL}
JENKINS_HOME=/var/lib/jenkins
echo "Uploading the Kubernetes to ${JENKINS_HOME}"
juju scp kubernetes_credentials.tgz jenkins/0:kubernetes_credentials.tgz
juju run --unit jenkins/0 "tar -xvzf /home/ubuntu/kubernetes_credentials.tgz -C ${JENKINS_HOME}"
juju run --unit jenkins/0 "chown -vR jenkins:jenkins ${JENKINS_HOME}/.kube"
juju run --unit jenkins/0 "chown -R jenkins:jenkins ${JENKINS_HOME}/kubectl"

echo "${0} complete on `date`"
