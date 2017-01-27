#!/bin/bash

# This script deploys a manifest YAML file to Kubernetes.

set -x 

MANIFEST=${1}

KUBECTL="/var/lib/jenkins/kubectl --kubeconfig=/var/lib/jenkins/.kube/config"

${KUBECTL} cluster-info
${KUBECTL} get nodes 
${KUBECTL} get pods,services,deployments,ingress --all-namespaces

echo "${KUBECTL} apply -f ${MANIFEST}"
sleep 5
${KUBECTL} get pods,services,deployments,ingress --all-namespaces

echo "Deployment of ${MANIFEST} complete `date`"
