# Overview
This is a project to demo Istio Gateway with Gateway API in Openshift. It is experimental and still rapidly changing.
### What does it do?
 - Istio will be installed (control plane, CRDs, etc..)
   - See `ISTIO_OSSM` for details on how it's installed.
 - Gateway API CRDs will be installed
 - Two additional Ingress Paths will be configured:
   1. Ingress via Gateway API with Istio (if `ISTIO_API_DEMO` is true)
     - GWAPI Ingress objects and Envoy Proxy Deployments will exist in `gwapi` namespace
   2. Ingress via Istio API directly 
     - Istio API Ingress objects will exist in `istioapi` and associated Envoy Proxy Deployments will exist in `istio-system`
 - DNS Records are configured for the separate Ingresses:
   - `*.gwapi.<DOMAIN>` for GWAPI Istio Gateway Ingress
   - `*.istio.<DOMAIN>` for Istio API Gateway Ingress (if `ISTIO_API_DEMO` is true)
 - The console route will be converted from Route Ingress to Istio API Ingress (if `ISTIO_CONVERT_CONSOLE` is true)
 - The control plane (istiod) will exists in `istio-system` if `ISTIO_OSSM` is false, otherwise it will exists in `gwapi` if `ISTIO_OSSM` is true

# How to run Istio Demo:
**Warning:** Do not run this demo in a production environment. It is EXPERIMENTAL.
1. `./setup-itsio-example.sh`
    - See ENV Variables below if you want to further configure.
2. Run `./test-all-routes.sh`
   - This script will curl all available routes URLs created in the `istioapi` and `gwapi` namespaces, along with the new console route
Istio Ingress should now be operational with your cluster

# Env Variables:
| Variable              | Description     | Default               |
|-----------------------|-----------------|-------------------|
| `ISTIO_API_DEMO`        | Scripts will also create a demo with Istio API Objects (not Gateway API). | `false` |
| `ISTIO_HOST_NETWORKING` | Istio API will use host networking. Requires `ISTIO_API_DEMO` to be true. | `false` |
| `ISTIO_BM` | All setup will use baremetal configurations. | `false` |
| `ISTIO_CONVERT_CONSOLE` | Sripts will convert the console route to Istio Gateway using Istio API. | `false` |
| `ISTIO_OSSM` | Openshift Service Mesh will be installed and be utilized for the control plane instead of using `istioctl`. | `false` |
| `ISTIO_OSSM_USE_DEFAULT_ENVOY_DEPLOYMENT` | All Gateway API objects will use the default single Envoy Proxy created by OSSM's Istiod (istio-system/istio-ingressgateway). | `true` |
| `GW_MANUAL_DEPLOYMENT` | A single Envoy Deployment will be created by these scripts instead of allowing istiod to auto create it. This changes the architecture from one-to-one gateway to deployment to many-to-one gateways to our manual deployment. | `false` |
| `GW_HOST_NETWORKING`   | Gateway API implementation will use host networking. Requires `GW_MANUAL_DEPLOYMENT` to be true. | `false` |

# Debugging Tools in `./debug-scripts`
- `dump-envoy-config-istioapi.sh` & `dump-envoy-config-gwapi.sh`
  - Download the envoy configuration for each ingress
- `open-envoy-webpage-istioapi.sh` & `open-envoy-webpage-gwapi.sh`
  - Open the envoy configuration webpage for each ingress
 GWAPI Ingress objects and Envoy deployments will exist in `gwapi` namespace
