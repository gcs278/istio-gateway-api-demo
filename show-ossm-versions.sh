#!/bin/bash

echo "OSSM Istio Operator Version:"
oc get -n openshift-operators pod $(oc get pods -n openshift-operators | grep istio-operator | awk '{print $1}')  -o jsonpath='{.spec.containers[*].env[?(@.name=="OPERATOR_CONDITION_NAME")].value}'
echo
echo "OSSM Istio SMCP Version:"
oc get smcp -n gwapi istio-ingress  -o jsonpath='{.status.operatorVersion}'
echo
