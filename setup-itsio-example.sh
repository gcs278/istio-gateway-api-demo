#!/bin/bash

HELPER="./helper-scripts"

# Install Istio and Gateway API
${HELPER}/install-istio-gwapi.sh $@

# Clear certs for new installation
rm -rf /tmp/istio-certs

# Configure nginx examples
${HELPER}/create-nginx-examples.sh $@

if [[ "$ISTIO_BM" != "true" ]]; then
  # Convert the console route to istio ingress
  ${HELPER}/convert-console-route.sh
fi
