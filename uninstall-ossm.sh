#!/bin/bash

oc delete -f yaml/ossm-2.3/service-mesh-control-plane.yaml
oc delete -f yaml/ossm-2.3/service-mesh-installation.yaml
oc delete -n openshift-operators daemonsets.apps istio-cni-node-v2-3
oc delete -n openshift-operators daemonsets.apps istio-cni-node-v2-4
oc delete -n openshift-operators rs $(oc get -n openshift-operators replicasets.apps  | grep "istio-operator" | awk '{print $1}')
oc delete ns gwapi
oc delete ns istioapi
oc delete ns auto
oc delete ns scope
oc delete ns bookinfo
