#!/bin/bash

oc delete gatewayclasses.gateway.networking.k8s.io --all

oc delete smcp -A --all
oc delete subscription servicemeshoperator -n openshift-operators
oc delete -n openshift-operators daemonsets.apps istio-cni-node-v2-3
oc delete -n openshift-operators daemonsets.apps istio-cni-node-v2-4
oc delete -n openshift-operators rs $(oc get -n openshift-operators replicasets.apps  | grep "istio-operator" | awk '{print $1}')
oc delete ns gwapi
oc delete ns istioapi
oc delete ns auto
oc delete ns scope
oc delete ns bookinfo
oc delete gateway -A --all
oc delete httproute -A --all
oc delete deployment -n openshift-ingress nginx
oc delete deployment -n openshift-ingress nginx-ssl

oc delete gatewayclasses.gateway.networking.k8s.io --all
