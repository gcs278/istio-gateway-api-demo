#! /usr/bin/env bash

set -ue
thisdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
YAML_DIR=${thisdir}/../yaml
NAMESPACE="gwapi"


echo "Configuring Istiod control plane for Gateway API demo"
for i in {1..30}; do
  if oc apply -f ${YAML_DIR}/service-mesh-control-plane.yaml; then
    break
  else
    echo "Atempt #${i}: Failed to apply ${YAML_DIR}/service-mesh-control-plane.yaml..trying again."
    sleep 3
  fi
done

echo "Waiting for istiod deployment to rollout"
for i in {1..30}; do
  if oc rollout status -w deployment -n $NAMESPACE istiod-istio-ingress; then
   break
  else
    echo "Attempt #${i}: Waiting for istiod-istio-ingress to appear...trying again."
    sleep 3
  fi
done

echo "Waiting for istio-ingressgateway deployment to rollout"
oc rollout status -w deployment -n $NAMESPACE istio-ingressgateway

# Due to https://issues.redhat.com/browse/OSSM-1846, we manually patch the istiod deployment to allow Pilot to auto-create deployments/services for Gateway API (one per Gateway Object)
# This just enables the feature, but you have ISTIO_OSSM_USE_DEFAULT_ENVOY_DEPLOYMENT=true set, this doesn't matter
# NOTE: Due to service mesh not supporting deployment template injection, auto-deployment creation won't even work
oc -n $NAMESPACE patch deploy/istiod-istio-ingress --type=strategic --patch='{"spec":{"template":{"spec":{"containers":[{"name":"discovery","env":[{"name":"PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER","value":"true"}]}]}}}}'
