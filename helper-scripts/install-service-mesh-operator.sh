#! /usr/bin/env bash

VERSION="2.3"

set -ue
thisdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
YAML_DIR=${thisdir}/../yaml/ossm-${VERSION}

echo "Installing Openshift Service Mesh Operator"
oc apply -f ${YAML_DIR}/service-mesh-installation.yaml

while ! oc get deployment -n openshift-operators istio-operator &> /dev/null; do
  echo "Waiting for the istio-operator deployment to appear in openshift-operators namespace (this can take a long time)"
  sleep 5
done

echo "Waiting for istio-operator deployment to rollout"
oc rollout status -w deployment -n openshift-operators istio-operator

# Uncomment if we decide to install Jaeger
#while ! oc get deployment -n openshift-distributed-tracing jaeger-operator &> /dev/null; do
#  echo "Waiting for the jaeger-operator deployment to appear in openshift-distributed-tracing namespace"
#  sleep 5
#done

#echo "Waiting for jaeger-operator deployment to rollout"
#oc rollout status -w deployment -n openshift-distributed-tracing jaeger-operator
