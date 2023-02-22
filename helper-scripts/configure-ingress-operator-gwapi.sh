#!/bin/bash

set -e

# Install OSSM Daily 2.4
./install-ossm-daily-build.sh 

# TO BE REMOVED WHEN OSSM 2.4 istio-proxyv2 image starts working! This effectively pulls images from community maistra
oc replace -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  annotations:
    alm-examples: "[\n  {\n    \"apiVersion\": \"maistra.io/v2\",\n    \"kind\": \"ServiceMeshControlPlane\",\n
      \   \"metadata\": {\n      \"name\": \"basic\",\n      \"namespace\": \"control-plane-namespace\"\n
      \   },\n    \"spec\": {\n      \"version\": \"v2.4\",\n      \"tracing\": {\n
      \       \"type\": \"Jaeger\",\n        \"sampling\": 10000\n      },\n      \"policy\":
      {\n         \"type\": \"Istiod\"\n      },\n      \"telemetry\": {\n         \"type\":
      \"Istiod\"\n      },\n      \"addons\": {\n        \"jaeger\": {\n          \"install\":
      {\n            \"storage\": {\n              \"type\": \"Memory\"\n            }\n
      \         }\n        },\n        \"prometheus\": {\n          \"enabled\": true\n
      \       },\n        \"kiali\": {\n          \"enabled\": true\n        },\n
      \       \"grafana\": {\n          \"enabled\": true\n        }\n      }\n    }\n
      \ },\n  {\n    \"apiVersion\": \"maistra.io/v1\",\n    \"kind\": \"ServiceMeshMemberRoll\",\n
      \   \"metadata\": {\n      \"name\": \"default\",\n      \"namespace\": \"control-plane-namespace\"\n
      \   },\n    \"spec\": {\n      \"members\": [\n        \"your-project\",\n        \"another-of-your-projects\"
      \n      ]\n    }\n  },\n  {\n    \"apiVersion\": \"maistra.io/v1\",\n    \"kind\":
      \"ServiceMeshMember\",\n    \"metadata\": {\n      \"name\": \"default\",\n
      \     \"namespace\": \"application-namespace\"\n    },\n    \"spec\": {\n      \"controlPlaneRef\":
      {\n        \"name\": \"basic\",\n        \"namespace\": \"control-plane-namespace\"\n
      \     }\n    }\n  }\n]"
    capabilities: Seamless Upgrades
    categories: OpenShift Optional, Integration & Delivery
    certified: "false"
    containerImage: quay.io/maistra-dev/istio-ubi8-operator:2.4-latest
    createdAt: 2022-12-19T14:03:48EST
    description: The Maistra Operator enables you to install, configure, and manage
      an instance of Maistra service mesh. Maistra is based on the open source Istio
      project.
    olm.operatorGroup: global-operators
    olm.operatorNamespace: openshift-operators
    olm.skipRange: '>=1.0.2 <2.4.0-0'
    olm.targetNamespaces: ""
    operators.openshift.io/infrastructure-features: '[]'
    repository: https://github.com/maistra/istio-operator
    support: Red Hat, Inc.
  labels:
    operatorframework.io/arch.amd64: supported
  name: servicemeshoperator.v2.4.0
  namespace: openshift-operators
spec:
  apiservicedefinitions: {}
  cleanup:
    enabled: false
  customresourcedefinitions:
    owned:
    - description: An Istio control plane installation
      displayName: Istio Service Mesh Control Plane
      kind: ServiceMeshControlPlane
      name: servicemeshcontrolplanes.maistra.io
      specDescriptors:
      - description: Specify the version of the control plane you want to install
        displayName: Control Plane Version
        path: version
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:General
        - urn:alm:descriptor:com.tectonic.ui:select:v2.4
        - urn:alm:descriptor:com.tectonic.ui:select:v2.3
        - urn:alm:descriptor:com.tectonic.ui:select:v2.2
        - urn:alm:descriptor:com.tectonic.ui:select:v2.1
      - description: Enable mTLS for communication between control plane components
        displayName: Control Plane Security
        path: security.controlPlane.mtls
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:General
        - urn:alm:descriptor:com.tectonic.ui:booleanSwitch
      - description: Set to true to install Prometheus
        displayName: Install Prometheus
        path: addons.prometheus.enabled
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:metrics
        - urn:alm:descriptor:com.tectonic.ui:booleanSwitch
      - description: Enable mTLS for communcation between services in the mesh
        displayName: Data Plane Security
        path: security.dataPlane.mtls
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:General
        - urn:alm:descriptor:com.tectonic.ui:booleanSwitch
      - description: Set to true to install Kiali
        displayName: Install Kiali
        path: addons.kiali.enabled
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:visualization
        - urn:alm:descriptor:com.tectonic.ui:booleanSwitch
      - description: Set to true to install Grafana
        displayName: Install Grafana
        path: addons.grafana.enabled
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:visualization
        - urn:alm:descriptor:com.tectonic.ui:booleanSwitch
      - description: Select the provider to use for tracing
        displayName: Tracing provider
        path: tracing.type
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:tracing
        - urn:alm:descriptor:com.tectonic.ui:select:None
        - urn:alm:descriptor:com.tectonic.ui:select:Jaeger
        - urn:alm:descriptor:com.tectonic.ui:select:Stackdriver
      - description: Set storage type for Jaeger (applies only when Jaeger is selected
          as the tracing provider)
        displayName: Jaeger Storage Type
        path: addons.jaeger.install.storage.type
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:tracing
        - urn:alm:descriptor:com.tectonic.ui:select:Memory
        - urn:alm:descriptor:com.tectonic.ui:select:Elasticsearch
      - description: Select "Mixer" when deploying a control plane version less than
          "v2.0" or when planning to install 3scale adapter
        displayName: Type of Policy
        path: policy.type
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:Policy
        - urn:alm:descriptor:com.tectonic.ui:select:Istiod
        - urn:alm:descriptor:com.tectonic.ui:select:Mixer
      - description: Set to true to install the Istio 3Scale adapter (applies only
          when Policy type is set to Mixer)
        displayName: Install 3Scale Adapter
        path: addons.3scale.enabled
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:Policy
        - urn:alm:descriptor:com.tectonic.ui:booleanSwitch
      - description: Select "Mixer" when deploying a control plane version less than
          "v2.0"
        displayName: Type of Telemetry
        path: telemetry.type
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:Telemetry
        - urn:alm:descriptor:com.tectonic.ui:select:Istiod
        - urn:alm:descriptor:com.tectonic.ui:select:Mixer
      - description: Set the default compute resource requests and limits for control
          plane components
        displayName: Default Resource Requirements
        path: runtime.defaults.container.resources
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:resourceRequirements
        - urn:alm:descriptor:com.tectonic.ui:advanced
      statusDescriptors:
      - description: Status of components deployed by this ServiceMeshControlPlane
          resource
        displayName: Components
        path: readiness.components
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:podStatuses
      version: v2
    - description: Marks the containing namespace as a member of the referenced Service
        Mesh
      displayName: Istio Service Mesh Member
      kind: ServiceMeshMember
      name: servicemeshmembers.maistra.io
      specDescriptors:
      - description: The namespace of the ServiceMeshControlPlane to which this namespace
          belongs
        displayName: Namespace
        path: controlPlaneRef.namespace
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:Service_Mesh_Control_Plane
        - urn:alm:descriptor:io.kubernetes:Project
      - description: The name of the ServiceMeshControlPlane to which this namespace
          belongs
        displayName: Name
        path: controlPlaneRef.name
        x-descriptors:
        - urn:alm:descriptor:com.tectonic.ui:fieldGroup:Service_Mesh_Control_Plane
        - urn:alm:descriptor:com.tectonic.ui:text
      version: v1
    - description: A list of namespaces in Service Mesh
      displayName: Istio Service Mesh Member Roll
      kind: ServiceMeshMemberRoll
      name: servicemeshmemberrolls.maistra.io
      version: v1
  description: |-
    Maistra is a platform that provides behavioral insight and operational control over a service mesh, providing a uniform way to connect, secure, and monitor microservice applications.

    ### Overview

    Maistra Service Mesh, based on the open source [Istio](https://istio.io/) project, adds a transparent layer on existing
    distributed applications without requiring any changes to the service code. You add Maistra Service Mesh
    support to services by deploying a special sidecar proxy throughout your environment that intercepts all network
    communication between microservices. You configure and manage the service mesh using the control plane features.

    Maistra Service Mesh provides an easy way to create a network of deployed services that provides discovery,
    load balancing, service-to-service authentication, failure recovery, metrics, and monitoring. A service mesh also
    provides more complex operational functionality, including A/B testing, canary releases, rate limiting, access
    control, and end-to-end authentication.

    ### Core Capabilities

    Maistra Service Mesh supports uniform application of a number of key capabilities across a network of services:

    + **Traffic Management** - Control the flow of traffic and API calls between services, make calls more reliable,
      and make the network more robust in the face of adverse conditions.

    + **Service Identity and Security** - Provide services in the mesh with a verifiable identity and provide the
      ability to protect service traffic as it flows over networks of varying degrees of trustworthiness.

    + **Policy Enforcement** - Apply organizational policy to the interaction between services, ensure access policies
      are enforced and resources are fairly distributed among consumers. Policy changes are made by configuring the
      mesh, not by changing application code.

    + **Telemetry** - Gain understanding of the dependencies between services and the nature and flow of traffic between
      them, providing the ability to quickly identify issues.

    ### Joining Projects Into a Mesh

    Once an instance of Maistra Service Mesh has been installed, it will only exercise control over services within its own
    project.  Other projects may be added into the mesh using one of two methods:

    1. A **ServiceMeshMember** resource may be created in other projects to add those projects into the mesh.  The
      **ServiceMeshMember** specifies a reference to the **ServiceMeshControlPlane** object that was used to install
      the control plane.  The user creating the **ServiceMeshMember** resource must have permission to *use* the
      **ServiceMeshControlPlane** object.  The adminstrator for the project containing the control plane can grant
      individual users or groups the *use* permissions.

    2. A **ServiceMeshMemberRoll** resource may be created in the project containing the control plane.  This resource
      contains a single *members* list of all the projects that should belong in the mesh.  The resource must be named
      *default*.  The user creating the resource must have *edit* or *admin* permissions for all projects in the
      *members* list.

    ### More Information

    * [Documentation](https://maistra.io/)
    * [Bugs](https://issues.redhat.com/projects/MAISTRA)
  displayName: Maistra Service Mesh
  icon:
  - base64data: |-
      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
    mediatype: image/png
  install:
    spec:
      clusterPermissions:
      - rules:
        - apiGroups:
          - monitoring.coreos.com
          resources:
          - servicemonitors
          verbs:
          - get
          - create
        - apiGroups:
          - ""
          resources:
          - services/finalizers
          verbs:
          - '*'
        - apiGroups:
          - ""
          resources:
          - configmaps
          - endpoints
          - namespaces
          - persistentvolumeclaims
          - pods
          - replicationcontrollers
          - secrets
          - serviceaccounts
          - services
          - events
          verbs:
          - '*'
        - apiGroups:
          - apps
          - extensions
          resources:
          - daemonsets
          - deployments
          - deployments/finalizers
          - ingresses
          - ingresses/status
          - replicasets
          - statefulsets
          verbs:
          - '*'
        - apiGroups:
          - autoscaling
          resources:
          - horizontalpodautoscalers
          verbs:
          - '*'
        - apiGroups:
          - policy
          resources:
          - poddisruptionbudgets
          verbs:
          - '*'
        - apiGroups:
          - admissionregistration.k8s.io
          resources:
          - mutatingwebhookconfigurations
          - validatingwebhookconfigurations
          verbs:
          - '*'
        - apiGroups:
          - apiextensions.k8s.io
          resources:
          - customresourcedefinitions
          verbs:
          - '*'
        - apiGroups:
          - certmanager.k8s.io
          resources:
          - clusterissuers
          verbs:
          - '*'
        - apiGroups:
          - networking.k8s.io
          resources:
          - networkpolicies
          - ingresses
          verbs:
          - '*'
        - apiGroups:
          - rbac.authorization.k8s.io
          resources:
          - clusterrolebindings
          - clusterroles
          - rolebindings
          - roles
          verbs:
          - '*'
        - apiGroups:
          - authentication.istio.io
          resources:
          - '*'
          verbs:
          - '*'
        - apiGroups:
          - config.istio.io
          resources:
          - '*'
          verbs:
          - '*'
        - apiGroups:
          - networking.istio.io
          resources:
          - '*'
          verbs:
          - '*'
        - apiGroups:
          - rbac.istio.io
          resources:
          - '*'
          verbs:
          - '*'
        - apiGroups:
          - security.istio.io
          resources:
          - '*'
          verbs:
          - '*'
        - apiGroups:
          - jaegertracing.io
          resources:
          - jaegers
          verbs:
          - '*'
        - apiGroups:
          - kiali.io
          resources:
          - kialis
          verbs:
          - '*'
        - apiGroups:
          - maistra.io
          resources:
          - '*'
          verbs:
          - '*'
        - apiGroups:
          - authentication.maistra.io
          resources:
          - '*'
          verbs:
          - '*'
        - apiGroups:
          - rbac.maistra.io
          resources:
          - '*'
          verbs:
          - '*'
        - apiGroups:
          - route.openshift.io
          resources:
          - routes
          - routes/custom-host
          verbs:
          - '*'
        - apiGroups:
          - authorization.k8s.io
          resources:
          - subjectaccessreviews
          verbs:
          - create
        - apiGroups:
          - network.openshift.io
          resources:
          - clusternetworks
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - config.openshift.io
          resources:
          - networks
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - image.openshift.io
          resources:
          - imagestreams
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - network.openshift.io
          resources:
          - netnamespaces
          verbs:
          - get
          - list
          - watch
          - update
        - apiGroups:
          - k8s.cni.cncf.io
          resources:
          - network-attachment-definitions
          verbs:
          - create
          - delete
          - get
          - list
          - patch
          - watch
        - apiGroups:
          - security.openshift.io
          resourceNames:
          - privileged
          resources:
          - securitycontextconstraints
          verbs:
          - use
        - apiGroups:
          - ""
          resources:
          - nodes
          - nodes/proxy
          verbs:
          - get
          - list
          - watch
        - apiGroups:
          - authentication.k8s.io
          resources:
          - tokenreviews
          verbs:
          - create
        - nonResourceURLs:
          - /metrics
          verbs:
          - get
        serviceAccountName: istio-operator
      deployments:
      - name: istio-operator
        spec:
          replicas: 1
          selector:
            matchLabels:
              name: istio-operator
          strategy: {}
          template:
            metadata:
              annotations:
                olm.relatedImage.v2_0.3scale-istio-adapter: quay.io/3scale/3scale-istio-adapter:v2.0.0
                olm.relatedImage.v2_0.cni: registry.redhat.io/openshift-service-mesh/istio-cni-rhel8:2.0.11
                olm.relatedImage.v2_0.grafana: docker.io/maistra/grafana-ubi8:2.0.10
                olm.relatedImage.v2_0.mixer: docker.io/maistra/mixer-ubi8:2.0.10
                olm.relatedImage.v2_0.pilot: docker.io/maistra/pilot-ubi8:2.0.10
                olm.relatedImage.v2_0.prometheus: docker.io/maistra/prometheus-ubi8:2.0.10
                olm.relatedImage.v2_0.proxy-init: docker.io/maistra/proxy-init-centos7:2.0.10
                olm.relatedImage.v2_0.proxyv2: docker.io/maistra/proxyv2-ubi8:2.0.10
                olm.relatedImage.v2_0.wasm-cacher: docker.io/maistra/pilot-ubi8:2.0.10
                olm.relatedImage.v2_1.cni: quay.io/maistra-dev/istio-cni-ubi8:2.1-latest
                olm.relatedImage.v2_1.grafana: registry.redhat.io/openshift-service-mesh/grafana-rhel8:2.3.1
                olm.relatedImage.v2_1.pilot: quay.io/maistra-dev/pilot-ubi8:2.1-latest
                olm.relatedImage.v2_1.prometheus: registry.redhat.io/openshift-service-mesh/prometheus-rhel8:2.3.1
                olm.relatedImage.v2_1.proxyv2: quay.io/maistra-dev/proxyv2-ubi8:2.1-latest
                olm.relatedImage.v2_1.rls: quay.io/maistra-dev/ratelimit-ubi8:2.1-latest
                olm.relatedImage.v2_1.wasm-cacher: quay.io/maistra-dev/pilot-ubi8:2.1-latest
                olm.relatedImage.v2_2.cni: quay.io/maistra-dev/istio-cni-ubi8:2.2-latest
                olm.relatedImage.v2_2.grafana: registry.redhat.io/openshift-service-mesh/grafana-rhel8:2.3.1
                olm.relatedImage.v2_2.pilot: quay.io/maistra-dev/pilot-ubi8:2.2-latest
                olm.relatedImage.v2_2.prometheus: registry.redhat.io/openshift-service-mesh/prometheus-rhel8:2.3.1
                olm.relatedImage.v2_2.proxyv2: quay.io/maistra-dev/proxyv2-ubi8:2.2-latest
                olm.relatedImage.v2_2.rls: quay.io/maistra-dev/ratelimit-ubi8:2.2-latest
                olm.relatedImage.v2_2.wasm-cacher: quay.io/maistra-dev/pilot-ubi8:2.2-latest
                olm.relatedImage.v2_3.cni: quay.io/maistra-dev/istio-cni-ubi8:2.3-latest
                olm.relatedImage.v2_3.grafana: registry.redhat.io/openshift-service-mesh/grafana-rhel8:2.3.1
                olm.relatedImage.v2_3.pilot: quay.io/maistra-dev/pilot-ubi8:2.3-latest
                olm.relatedImage.v2_3.prometheus: registry.redhat.io/openshift-service-mesh/prometheus-rhel8:2.3.1
                olm.relatedImage.v2_3.proxyv2: quay.io/maistra-dev/proxyv2-ubi8:2.3-latest
                olm.relatedImage.v2_3.rls: quay.io/maistra-dev/ratelimit-ubi8:2.3-latest
                olm.relatedImage.v2_4.cni: quay.io/maistra-dev/istio-cni-ubi8:2.4-latest
                olm.relatedImage.v2_4.grafana: registry.redhat.io/openshift-service-mesh/grafana-rhel8:2.3.1
                olm.relatedImage.v2_4.pilot: quay.io/maistra-dev/pilot-ubi8:2.4-latest
                olm.relatedImage.v2_4.prometheus: registry.redhat.io/openshift-service-mesh/prometheus-rhel8:2.3.1
                olm.relatedImage.v2_4.proxyv2: quay.io/maistra-dev/proxyv2-ubi8:2.4-latest
                olm.relatedImage.v2_4.rls: quay.io/maistra-dev/ratelimit-ubi8:2.4-latest
              creationTimestamp: null
              labels:
                name: istio-operator
            spec:
              containers:
              - args:
                - --zap-devel
                - --zap-level
                - debug
                command:
                - istio-operator
                - --config
                - /etc/operator/olm/config.properties
                env:
                - name: WATCH_NAMESPACE
                - name: POD_NAME
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.name
                - name: OPERATOR_NAME
                  value: istio-operator
                image: quay.io/maistra-dev/istio-ubi8-operator:2.4-latest
                imagePullPolicy: Always
                name: istio-operator
                ports:
                - containerPort: 11999
                  name: validation
                  protocol: TCP
                - containerPort: 60000
                  name: metrics
                  protocol: TCP
                resources: {}
                volumeMounts:
                - mountPath: /etc/operator/olm
                  name: operator-olm-config
                  readOnly: true
                - mountPath: /tmp/k8s-webhook-server/serving-certs
                  name: webhook-tls-volume
                  readOnly: true
                - mountPath: /usr/local/share/istio-operator/templates/
                  name: smcp-templates
                  readOnly: true
              serviceAccountName: istio-operator
              volumes:
              - downwardAPI:
                  defaultMode: 420
                  items:
                  - fieldRef:
                      fieldPath: metadata.annotations
                    path: config.properties
                name: operator-olm-config
              - name: webhook-tls-volume
                secret:
                  optional: true
                  secretName: maistra-operator-serving-cert
              - configMap:
                  name: smcp-templates
                  optional: true
                name: smcp-templates
    strategy: deployment
  installModes:
  - supported: false
    type: OwnNamespace
  - supported: false
    type: SingleNamespace
  - supported: false
    type: MultiNamespace
  - supported: true
    type: AllNamespaces
  keywords:
  - istio
  - maistra
  - servicemesh
  links:
  - name: Maistra Service Mesh
    url: https://maistra.io/
  - name: Istio
    url: https://istio.io/
  - name: Operator Source Code
    url: https://github.com/Maistra/istio-operator
  - name: Bugs
    url: https://issues.redhat.com/projects/MAISTRA
  maintainers:
  - email: istio-feedback@redhat.com
    name: Red Hat, OpenShift Service Mesh
  maturity: alpha
  provider:
    name: Red Hat, Inc.
  replaces: maistraoperator.v2.3.0
  version: 2.4.0-0
EOF

# Add cluster-admin to cluster-ingress-operator
oc adm policy add-cluster-role-to-user cluster-admin -z ingress-operator -n openshift-ingress-operator

# Since we are doing a cluster build, you need to update the cluster role
oc replace -f ~/src/github.com/openshift/cluster-ingress-operator/manifests/00-cluster-role.yaml

# Enable feature gate
oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: FeatureGate
metadata:
  name: cluster
spec:
  customNoUpgrade:
    enabled:
    - GatewayAPI
  featureSet: CustomNoUpgrade
EOF

# this is what tells the CIO to turn on the smcp
oc apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: openshift-gateway
spec:
  controllerName: "openshift.io/gateway-controller"
EOF
