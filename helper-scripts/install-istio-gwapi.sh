#!/bin/bash

DOWNLOAD_DIR="/tmp/istio-download"
rm -rf ${DOWNLOAD_DIR}
mkdir -p ${DOWNLOAD_DIR}

# Must do this for openshift to allow istio to work
oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system
oc adm policy add-scc-to-user privileged -n istio-system -z istio-ingressgateway-service-account

# Download istio again
cd ${DOWNLOAD_DIR}
curl -L https://istio.io/downloadIstio | sh -
if [[ $? -ne 0 ]]; then
  echo "ERROR: Failed to download istio"
  exit 1
fi
cd - > /dev/null

istioctl=$(find ${DOWNLOAD_DIR} -iname "istioctl" | head -1)
if [[ ! -f "$istioctl" ]]; then
  echo "ERROR: can't find istioctl at: $istioctl"
  exit 1
fi

if [[ "$ISTIO_HOST_NETWORKING" == "true" ]]; then
  hostNetArg="-f ../yaml/hostnet-overlay.yaml"
fi

# Install Istio for openshift
$istioctl install -y --set profile=openshift --set meshConfig.accessLogFile=/dev/stdout $hostNetArg

# Expose openshift route for istio
# Not really needed, since we make our own DNS records to circumvent openshift-router
oc -n istio-system expose svc/istio-ingressgateway --port=http2

# Install gateway api
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0" | kubectl apply -f -; }
