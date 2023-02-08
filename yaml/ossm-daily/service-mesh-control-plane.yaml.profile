apiVersion: v1
kind: Namespace
metadata:
  name: gwapi
---
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: gwapi
  namespace: gwapi
spec:
  profiles:
  - gateway-controller
  proxy:
    accessLogging:
      envoyService:
        enabled: true
      file:
        name: /dev/stdout
  runtime:
    components:
      pilot:
        container:
          env:
            PILOT_GATEWAY_API_CONTROLLER_NAME: openshift.io/gateway-controller
            PILOT_ENABLE_GATEWAY_API: "true"
            PILOT_ENABLE_GATEWAY_API_STATUS: "true"
            PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER: "true"
  version: v2.4
  techPreview:         # [1]
    controlPlaneMode:
      ClusterScoped
---
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: gwapi
spec:
  members:
  - gwapi
  - bookinfo
---
