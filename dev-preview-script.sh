#!/bin/bash
mkdir -p /tmp/istio-demo
cd /tmp/istio-demo
oc kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.5.1" | oc apply -f -;
oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system

export ISTIO_VERSION=1.15.1
wget https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux-amd64.tar.gz
tar xzvf istio-${ISTIO_VERSION}-linux-amd64.tar.gz
cd istio-${ISTIO_VERSION}
export PATH=$PWD/bin:$PATH
istioctl install --set profile=minimal -y --set meshConfig.accessLogFile=/dev/stdout
#istioctl verify-install
oc create namespace demo-gateway
oc adm policy add-scc-to-group anyuid system:serviceaccounts:demo-gateway
oc apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway
  namespace: demo-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: demo
    hostname: "*.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
oc create namespace demo-app 
oc new-app -n demo-app --name foo-app https://github.com/openshiftdemos/cakephp-ingress-demo#foo
oc apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: http
  namespace: demo-app
spec:
  parentRefs:
  - name: gateway
    namespace: demo-gateway
  hostnames: ["http.example.com"]
  rules:
  - backendRefs:
    - name: foo-app
      port: 8080
EOF
oc wait -n demo-gateway --for=condition=ready gateways.gateway.networking.k8s.io gateway
export INGRESS_HOST=$(oc get gateways.gateway.networking.k8s.io gateway -n demo-gateway -ojsonpath='{.status.addresses[*].value}')
curl -I -H "Host: http.example.com" $INGRESS_HOST


cd -
