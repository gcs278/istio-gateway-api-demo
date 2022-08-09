#! /usr/bin/env bash

set -eu

# Install gateway api
echo "Installing Gateway API CRDs"
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || { kubectl kustomize "https://github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.5.0" | kubectl apply -f -; }
