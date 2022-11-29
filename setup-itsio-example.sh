#! /usr/bin/env bash

set -eu

# ENV Defaults
set -a
: "${ISTIO_API_DEMO:=false}"
: "${ISTIO_HOST_NETWORKING:=false}"
: "${ISTIO_BM:=false}"
: "${ISTIO_CONVERT_CONSOLE:=false}"
: "${ISTIO_OSSM:=false}"
: "${ISTIO_OSSM_USE_DEFAULT_ENVOY_DEPLOYMENT:=true}"
: "${ISTIO_OSSM_SERVICE_MESH_EXAMPLE:=true}"
: "${GW_MANUAL_DEPLOYMENT:=false}"
: "${GW_HOST_NETWORKING:=false}"
set +a

echo "Environment Variables:"
for var in $(compgen -v); do
  if echo $var | grep -q 'ISTIO_\|GW_'; then
    echo " --> ${var}=${!var}"
  fi
done

# Validation
if [[ "${GW_HOST_NETWORKING}" == "true" ]] && [[ "${GW_MANUAL_DEPLOYMENT}" == "false" ]]; then
  echo "ERROR: If GW_HOST_NETWORKING=true then you must use GW_MANUAL_DEPLOYMENT=true"
  echo "       I haven't figured out a way for the GWAPI Auto Deployments to use hostports/hostnetworking"
  exit 1
fi
if [[ "${GW_MANUAL_DEPLOYMENT}" == "true" ]] && [[ "${ISTIO_OSSM_USE_DEFAULT_ENVOY_DEPLOYMENT}" == "true" ]]; then
  echo "ERROR: If GW_MANUAL_DEPLOYMENT=true then you must use ISTIO_OSSM_USE_DEFAULT_ENVOY_DEPLOYMENT=false"
  echo "       You can use the default OSSM Envoy Deployment and also use our manual gateway envoy deployment at the same time."
  exit 1
fi
if [[ "${ISTIO_OSSM_USE_DEFAULT_ENVOY_DEPLOYMENT}" != "true" ]]; then
  echo "ERROR: ISTIO_OSSM_USE_DEFAULT_ENVOY_DEPLOYMENT must be true"
  echo "       OSSM currently doesn't support Deployment Template injection, so auto-deployments won't work"
  exit 1
fi
if [[ "${ISTIO_HOST_NETWORKING}" == "true" ]] && [[ "${ISTIO_API_DEMO}" == "false" ]]; then
  echo "ERROR: If ISTIO_HOST_NETWORKING is true, then you must set ISTIO_API_DEMO to true"
  exit 1
fi
if [[ "${ISTIO_CONVERT_CONSOLE}" == "true" ]] && [[ "${ISTIO_API_DEMO}" == "false" ]]; then
  echo "ERROR: If ISTIO_CONVERT_CONSOLE is true, then you must set ISTIO_API_DEMO to true"
  exit 1
fi

read -p "Press enter to continue the installation"

HELPER="./helper-scripts"

# Install GW API CRDs
${HELPER}/install-gwapi.sh

# Install Istio via istioctl
if [[ "${ISTIO_OSSM=}" == "true" ]]; then
  ${HELPER}/install-service-mesh-operator.sh
  ${HELPER}/configure-service-mesh.sh
else
  ${HELPER}/install-istio.sh
fi

# Clear certs for new installation
rm -rf /tmp/istio-certs

# Configure ingress examples
${HELPER}/create-ingress-examples.sh "$@"

# Configure service mesh examples
if [[ "${ISTIO_OSSM_SERVICE_MESH_EXAMPLE:=}" == "true" && "${ISTIO_OSSM:=}" == "true" ]]; then
   ${HELPER}/create-service-mesh-example.sh 
fi

if [[ "${ISTIO_BM:=}" != "true" ]] && [[ "${ISTIO_CONVERT_CONSOLE:=}" == "true" ]]; then
  # Convert the console route to istio ingress
  ${HELPER}/convert-console-route.sh
fi
