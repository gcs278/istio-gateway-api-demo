#!/bin/bash
set -eu

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
YAML_DIR=${SCRIPT_DIR}/../yaml
DEMO_YAML_DIR=${SCRIPT_DIR}/../yaml/demos
SERVICE_MESH_YAML=${DEMO_YAML_DIR}/service-mesh

# Domain that we already have a DNSRecord to route to our single Gateway
DOMAIN="$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})"
export GWAPI_DOMAIN="gwapi.${DOMAIN:5}"

oc create namespace bookinfo --dry-run=client -o yaml | oc apply -f -

# Create the services and deployments for the bookinfo microservice
# https://istio.io/latest/docs/examples/bookinfo/
oc apply -f ${SERVICE_MESH_YAML}/bookinfo.yaml

# The Bookinfo Gateway should use the existing GWAPI Ingress Gateway
export GW_ADDRESSES_YAML=$(cat <<-END
addresses:
  - value: istio-ingressgateway.gwapi.svc.cluster.local
    type: Hostname
END
)
cat ${SERVICE_MESH_YAML}/bookinfo-gateway.yaml | envsubst | oc apply -n gwapi -f -

# Create a httproute to route from Ingress Gateway into Mesh
oc apply -f ${SERVICE_MESH_YAML}/bookinfo-httproute.yaml

# Create a virtual Service to augument the Service Mesh to use V1
# This tells Istio to override the default service traffic routing, and
# send it to a specific service (V1)
# https://istio.io/latest/docs/tasks/traffic-management/request-routing/
oc apply -f ${SERVICE_MESH_YAML}/bookinfo-reviews-virtualservice.yaml
oc apply -f ${SERVICE_MESH_YAML}/bookinfo-service-versions-for-istioapi.yaml



echo "Navigate to http://book.${GWAPI_DOMAIN}/productpage"
