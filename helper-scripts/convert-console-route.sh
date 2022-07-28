#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
YAML_DIR=${SCRIPT_DIR}/../yaml

export DNS_RECORD_TYPE="CNAME"
export INGRESS_HOST=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [[ "$INGRESS_HOST" == "" ]]; then
  export INGRESS_HOST=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  export DNS_RECORD_TYPE="A"
fi
if [[ "$INGRESS_HOST" == "" ]]; then
  echo "ERROR: There was an issue getting the istio ingress service hostname or ip"
  exit 1
fi

export CONSOLE_ROUTE="$(oc get routes -n openshift-console console -o go-template='{{.spec.host}}')"

# Copy default cert from openshift-ingress namespace to istioapi
kubectl get secret router-certs-default -n openshift-ingress -o "jsonpath={.data['tls\.key']}" | base64 -d > /tmp/openshift-default.key
kubectl get secret router-certs-default -n openshift-ingress -o "jsonpath={.data['tls\.crt']}" | base64 -d > /tmp/openshift-default.crt
# TRICKY: Certs go in istio-system, not the target namespace with the gateway, virtualservice, destinations rules!
oc create -n istio-system secret tls default-credential --key=/tmp/openshift-default.key --cert=/tmp/openshift-default.crt

echo "Converting $CONSOLE_ROUTE to istio"
cat ${YAML_DIR}/console-istioapi.yaml | envsubst | oc apply -f -
if [[ $? -ne 0 ]]; then
  echo "ERROR: Something went wrong with configuring ${YAML_DIR}/console-istioapi.yaml"
  exit 1
fi

echo "Converted console route. Try:"
echo "curl -I -k https://${CONSOLE_ROUTE}"
