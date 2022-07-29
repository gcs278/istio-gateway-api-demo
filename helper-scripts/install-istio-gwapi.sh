#! /usr/bin/env bash

set -eu

thisdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
pushd "$thisdir" > /dev/null 2>&1

DOWNLOAD_DIR="/tmp/istio-download"
mkdir -p "$DOWNLOAD_DIR"

: "${ISTIO_HOST_NETWORKING:=""}"

# Must do this for openshift to allow istio to work
oc create namespace istio-system --dry-run=client -o yaml | oc apply -f -
oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system
oc adm policy add-scc-to-user privileged -n istio-system -z istio-ingressgateway-service-account

: "${ISTIO_RELEASE:=https://github.com/istio/istio/releases/download/1.14.2/istio-1.14.2-linux-amd64.tar.gz}"

if [[ ! -x "$DOWNLOAD_DIR/bin/istioctl" ]]; then
    echo "Downloading and extracting $ISTIO_RELEASE"
    curl -Ls -o istio.tar.gz --output-dir "$DOWNLOAD_DIR" "$ISTIO_RELEASE"
    tar -C "$DOWNLOAD_DIR" --strip-components=1 -xvpf "$DOWNLOAD_DIR/istio.tar.gz"
fi

if [[ ! -x "$DOWNLOAD_DIR/bin/istioctl" ]]; then
    echo "istioctl not found in $DOWNLOAD_DIR/bin";
    exit 1
fi

PATH="$DOWNLOAD_DIR/bin:$PATH"

if [[ "$ISTIO_HOST_NETWORKING" == "true" ]]; then
  hostNetArg="-f $thisdir/../yaml/hostnet-overlay.yaml"
fi

# Install Istio for openshift
istioctl install -y --set profile=openshift --set meshConfig.accessLogFile=/dev/stdout ${hostNetArg:-}

# Expose openshift route for istio
# Not really needed, since we make our own DNS records to circumvent openshift-router
oc -n istio-system expose svc/istio-ingressgateway --port=http2

# Install gateway api
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0" | kubectl apply -f -; }
