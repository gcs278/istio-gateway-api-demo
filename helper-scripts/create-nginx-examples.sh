#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
YAML_DIR=${SCRIPT_DIR}/../yaml
CERT_DIR=/tmp/istio-certs
mkdir -p $CERT_DIR

function create_certs() {
  TYPE="$1"
  CERT_DOMAIN="$2"
  NAMESPACE="$3"
  test -f ${CERT_DIR}/${TYPE}.${NAMESPACE}.key || openssl req -out ${CERT_DIR}/${TYPE}.${NAMESPACE}.csr -newkey rsa:2048 -nodes -keyout ${CERT_DIR}/${TYPE}.${NAMESPACE}.key -subj "/CN=${CERT_DOMAIN}/O=RedHat"
  if [[ $? -ne 0 ]]; then
    echo "ERROR: Cert generation for $CERT_DOMAIN failed!"
    exit 1
  fi
  test -f ${CERT_DIR}/${TYPE}.${NAMESPACE}.crt || openssl x509 -req -sha256 -days 365 -CA ${CERT_DIR}/ca.crt -CAkey ${CERT_DIR}/ca.key -set_serial 0 -in ${CERT_DIR}/${TYPE}.${NAMESPACE}.csr -out ${CERT_DIR}/${TYPE}.${NAMESPACE}.crt
  if [[ $? -ne 0 ]]; then
    echo "ERROR: Cert generation for $CERT_DOMAIN failed!"
    exit 1
  fi
  oc delete -n $NAMESPACE secret ${TYPE}-credential 2>/dev/null
  oc create -n $NAMESPACE secret tls ${TYPE}-credential --key=${CERT_DIR}/${TYPE}.${NAMESPACE}.key --cert=${CERT_DIR}/${TYPE}.${NAMESPACE}.crt
}

if [[ "$ISTIO_BM" == "true" ]]; then
  DOMAIN="$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})"
  export ISTIO_DOMAIN="istio.${DOMAIN:5}"
  export GWAPI_DOMAIN="gwapi.${DOMAIN:5}"
  # Don't create dnsrecords for BM since they won't do anything
else
  # Set up DNS for istioapi example
  DOMAIN="$(oc get ingresscontrollers.operator.openshift.io -n openshift-ingress-operator default -o go-template='{{.status.domain}}')"
  export ISTIO_DOMAIN="istio.${DOMAIN:5}"
  export GWAPI_DOMAIN="gwapi.${DOMAIN:5}"

  DNS_RECORD_TYPE="CNAME"
  INGRESS_HOST=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  if [[ "$INGRESS_HOST" == "" ]]; then
    INGRESS_HOST=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    DNS_RECORD_TYPE="A"
  fi
  if [[ "$INGRESS_HOST" == "" ]]; then
    echo "ERROR: There was an issue getting the istio ingress service hostname or ip"
    exit 1
  fi

  # Add wildcard to send dns requests to istio via istio api
  oc apply -f - <<EOF
apiVersion: ingress.operator.openshift.io/v1
kind: DNSRecord
metadata:
  name: istio-wildcard
  namespace: openshift-ingress-operator
  labels:
    ingresscontroller.operator.openshift.io/owning-ingresscontroller: default
spec:
  dnsName: "*.${ISTIO_DOMAIN}."
  recordTTL: 30
  recordType: ${DNS_RECORD_TYPE}
  targets:
  - ${INGRESS_HOST}
EOF
fi

# Create namespaces
oc create namespace istioapi --dry-run=client -o yaml | oc apply -f -
oc create namespace gwapi  --dry-run=client -o yaml | oc apply --overwrite=true -f -
oc adm policy add-scc-to-group anyuid system:serviceaccounts:istioapi
oc adm policy add-scc-to-group anyuid system:serviceaccounts:gwapi
oc create -n gwapi serviceaccount istio-ingressgateway-service-account
oc adm policy add-scc-to-user privileged -n gwapi -z istio-ingressgateway-service-account

GWAPI_SERVICE="gateway"
if [[ "$GW_MANUAL_DEPLOYMENT" == "true" ]]; then
  echo "GW_MANUAL_DEPLOYMENT is set. Using manual deployment for GWAPI"
  if [[ "$GW_HOST_NETWORKING" == "true" ]]; then
    echo "GW_HOST_NETWORKING is set. Using host networking for GWAPI"
    export GW_HOST_NETWORKING_YAML=$(cat <<-END
        ports:
        - containerPort: 80
          hostPort: 80
          protocol: TCP
        - containerPort: 443
          hostPort: 443
          protocol: TCP
END
)
  fi
  cat ${YAML_DIR}/gwapi-manual-deployment.yaml | envsubst | oc apply -f -
  if [[ $? -ne 0 ]]; then
    echo "ERROR: Something went wrong with configuring ${YAML_DIR}/gwapi-manual-deployment.yaml"
    exit 1
  fi
  GWAPI_SERVICE="gateway-manual"
  export GW_ADDRESSES_YAML=$(cat <<-END
addresses:
  - value: gateway-manual.gwapi.svc.cluster.local
    type: Hostname
END
)
fi

# Set up certs
# Create CA
test -f ${CERT_DIR}/ca.crt || openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=RedHat/CN=${ISTIO_DOMAIN}' -keyout ${CERT_DIR}/ca.key -out ${CERT_DIR}/ca.crt

# Istio API Certs
create_certs edge "edge.${ISTIO_DOMAIN}" istio-system
create_certs re "re.${ISTIO_DOMAIN}" istio-system
create_certs pass "pass.${ISTIO_DOMAIN}" istioapi

# Gateway API Certs
create_certs edge "edge.${GWAPI_DOMAIN}" gwapi
create_certs re "re.${GWAPI_DOMAIN}" gwapi
create_certs pass "pass.${GWAPI_DOMAIN}" gwapi

# Configure istioapi examples via istio api
cat ${YAML_DIR}/nginx-istioapi.yaml | envsubst | oc apply -f -
if [[ $? -ne 0 ]]; then
  echo "ERROR: Something went wrong with configuring ${YAML_DIR}/nginx-istioapi.yaml"
  exit 1
fi
cat ${YAML_DIR}/nginx-gwapi.yaml | envsubst | oc apply -f -
if [[ $? -ne 0 ]]; then
  echo "ERROR: Something went wrong with configuring ${YAML_DIR}/nginx-gwapi.yaml"
  exit 1
fi
#cat ${YAML_DIR}/echo-service-sleeper-istioapi.yaml | envsubst | oc apply -f -
cat ${YAML_DIR}/gwapi-features-examples.yaml | envsubst | oc apply -f -
if [[ $? -ne 0 ]]; then
  echo "ERROR: Something went wrong with configuring ${YAML_DIR}/nginx-gwapi.yaml"
  exit 1
fi


if [[ "$ISTIO_BM" != "true" ]]; then
  TIMEOUT=60
  while [[ "$GWAPI_LOADBALANCER_DOMAIN" == "" ]] && [[ "$GWAPI_LOADBALANCER_IP" == "" ]]; do
    # For AWS, it uses hostname, but for GCE, it uses IP
    GWAPI_LOADBALANCER_DOMAIN=$(oc -n gwapi get service $GWAPI_SERVICE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    GWAPI_LOADBALANCER_IP=$(oc -n gwapi get service $GWAPI_SERVICE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "Waiting for gateway api loadbalancer to get domain name"
    if [[ "$TIMEOUT" -lt 0 ]]; then
      echo "ERROR: Gateway API loadbalancer never got domain name"
      exit 1
    fi
    TIMEOUT=$((TIMEOUT-1))
    sleep 1
  done

  if [[ "$GWAPI_LOADBALANCER_DOMAIN" != "" ]]; then
    GWAPI_LOADBALANCER="$GWAPI_LOADBALANCER_DOMAIN"
    DNS_RECORD_TYPE="CNAME"
  else
    GWAPI_LOADBALANCER="$GWAPI_LOADBALANCER_IP"
    DNS_RECORD_TYPE="A"
  fi

  # Add wildcard to send dns requests to istio via gwapi
  oc apply -f - <<EOF
apiVersion: ingress.operator.openshift.io/v1
kind: DNSRecord
metadata:
  name: istio-gwapi-wildcard
  namespace: openshift-ingress-operator
  labels:
    ingresscontroller.operator.openshift.io/owning-ingresscontroller: default
spec:
  dnsName: "*.${GWAPI_DOMAIN}."
  recordTTL: 30
  recordType: ${DNS_RECORD_TYPE}
  targets:
  - ${GWAPI_LOADBALANCER}
EOF
fi

echo "ISITIO API:"
echo "curl -I http://http.${ISTIO_DOMAIN}"
echo "curl --cacert ${CERT_DIR}/ca.crt -I https://edge.${ISTIO_DOMAIN}"
echo "curl --cacert ${CERT_DIR}/ca.crt -I https://re.${ISTIO_DOMAIN}"
echo "curl --cacert ${CERT_DIR}/ca.crt -I https://pass.${ISTIO_DOMAIN}"
echo
echo "GWAPI:"
echo "curl -I http://http.${GWAPI_DOMAIN}"
echo "curl --cacert ${CERT_DIR}/ca.crt -I https://edge.${GWAPI_DOMAIN}"
echo "curl --cacert ${CERT_DIR}/ca.crt -I https://re.${GWAPI_DOMAIN}"
echo "curl --cacert ${CERT_DIR}/ca.crt -I https://pass.${GWAPI_DOMAIN}"
if [[ "$ISTIO_BM" == "true" ]]; then
  echo "WARNING: For baremetal you need to configure DNS yourself!"
fi
