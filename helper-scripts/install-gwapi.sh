#! /usr/bin/env bash

set -eu

# Install gateway api
echo "Installing Gateway API CRDs"
oc kustomize "https://github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.6.1" | oc apply -f -; 
