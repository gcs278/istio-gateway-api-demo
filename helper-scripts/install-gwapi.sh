#! /usr/bin/env bash

set -eu

# Install gateway api
echo "Installing Gateway API CRDs"
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0" | kubectl apply -f -; }
