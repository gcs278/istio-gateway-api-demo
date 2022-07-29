#!/usr/bin/env bash

set -eu

if ! command -v istioctl &> /dev/null; then
    echo "istioctl not found"
    exit 2
fi

istioctl x uninstall --skip-confirmation --purge
oc get namespace istio-system &> /dev/null && oc delete namespace istio-system
