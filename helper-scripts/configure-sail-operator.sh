#! /usr/bin/env bash

set -ue
thisdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
YAML_DIR=${thisdir}/../yaml/sail-operator
NAMESPACE="gwapi"

echo "Configuring istiod control plane for Gateway API demo"
for i in {1..30}; do
  if oc apply -f ${YAML_DIR}/istio-operator.yaml; then
    break
  else
    echo "Atempt #${i}: Failed to apply ${YAML_DIR}/istio-operator.yaml..trying again."
    sleep 3
  fi
done

# This is the istio control plane (istiod)
echo "Waiting for istiod deployment to rollout"
for i in {1..30}; do
  if oc rollout status -w deployment -n $NAMESPACE istiod; then
   break
  else
    echo "Attempt #${i}: Waiting for istiod to appear...trying again."
    sleep 3
  fi
done

