# Overview
This is a project to demo Istio Gateway with Gateway API in Openshift. It is experimental and still rapidly changing.
### What does it do?
 - Istio will be installed (control plane, CRDs, etc..)
 - Gateway API CRDs will be installed
 - Two additional Ingress Paths will be configured:
   1. Ingress via Gateway API with Istio
     - GWAPI Ingress objects and Envoy Proxy Deployments will exist in `gwapi` namespace
   2. Ingress via Istio API directly 
     - Istio API Ingress objects will exist in `istioapi` and associated Envoy Proxy Deployments will exist in `istio-system`
 - DNS Records are configured for the separate Ingresses:
   - `*.gwapi.<DOMAIN>` for GWAPI Istio Gateway Ingress
   - `*.istio.<DOMAIN>` for Istio API Gateway Ingress
 - The console route will be converted from Route Ingress to Istio API Ingress
 - The control plane (istiod) will exists in `istio-system`

# How to run Istio Demo:
**Warning:** Do not run this demo in a production environment. It is EXPERIMENTAL.
1. `./setup-itsio-example.sh`
    - See ENV Variables below if you want to further configure.
2. Run `./test-all-routes.sh`
   - This script will curl all available routes URLs created in the `istioapi` and `gwapi` namespaces, along with the new console route
Istio Ingress should now be operational with your cluster

# Env Variables:
- **ISTIO_HOST_NETWORKING**: If true, then Istio API will use host networking
- **GW_MANUAL_DEPLOYMENT**: If true, then a single deployment will be created by these scrpits instead of allowing istiod to auto create it. This changes the architecture from one-to-one gateway to deployment to many-to-one gateways to our manual deployment. This is more aligned with openshift-router architecture.
- **GW_HOST_NETWORKING**: If true, then Gateway API implementation will use host networking. Requires `GW_MANUAL_DEPLOYMENT` to be true
- **ISTIO_BM**: If true, then setup will use baremetal configurations.

# Debugging Tools in `./debug-scripts`
- `dump-envoy-config-istioapi.sh` & `dump-envoy-config-gwapi.sh`
  - Download the envoy configuration for each ingress
- `open-envoy-webpage-istioapi.sh` & `open-envoy-webpage-gwapi.sh`
  - Open the envoy configuration webpage for each ingress
 GWAPI Ingress objects and Envoy deployemnts will exist in `gwapi` namespace
