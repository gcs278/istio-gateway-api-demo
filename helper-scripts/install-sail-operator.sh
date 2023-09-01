#! /usr/bin/env bash

set -ue
thisdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
YAML_DIR=${thisdir}/../yaml/sail-operator

echo "Installing Sail Operator"
oc apply -f ${YAML_DIR}/sail-operator-installation.yaml

while ! oc get deployment -n openshift-operators istio-operator &> /dev/null; do
  echo "Waiting for the istio-operator deployment to appear in openshift-operators namespace (this can take a long time)"
  sleep 5
done

echo "Waiting for sail-operator deployment to rollout"
oc rollout status -w deployment -n openshift-operators istio-operator
