#!/bin/bash

# This script deploys a manifest YAML file to Kubernetes.

set -x 

MANIFEST=${1}

KUBE_PATH=/var/lib/jenkins
if [ ! -d ${KUBE_PATH} ]; then
  KUBE_PATH=.
fi
KUBECTL="${KUBE_PATH}/kubectl --kubeconfig=${KUBE_PATH}/.kube/config"

${KUBECTL} cluster-info
${KUBECTL} get nodes -o wide 
echo ""
${KUBECTL} get pods -o wide --all-namespaces
${KUBECTL} get services --all-namespaces
${KUBECTL} get deployments --all-namespaces
echo ""
echo "Deploying ${MANIFEST} to Kubernetes."
${KUBECTL} apply -f ${MANIFEST}
echo ""
sleep 5
${KUBECTL} get pods -o wide --all-namespaces
${KUBECTL} get services --all-namespaces
${KUBECTL} get deployments --all-namespaces

echo "Deployment of ${MANIFEST} complete `date`"
