#!/bin/bash

set -e

# 1. Must be connected to the VPN
# 2. Need the command "brew", not sure where I got this from originally...
# 3. Make sure /etc/krb5.conf has:
#   [libdefaults]
#      dns_canonicalize_hostname = fallback

if ! klist -s; then
  echo "Log into kerberos (should be your laptop password):"
  kinit ${USER}@IPA.REDHAT.COM
fi

# Need to create, or retrieve a token to add to your cluster so you can pull the daily image
# If you have one already (made with the description we specified in this script...)
tokens=$(curl --negotiate -u : https://employee-token-manager.registry.redhat.com/v1/tokens -s | jq)
if echo "$tokens" | grep -qi "Using Istio developer build images"; then
  echo "Token already exists, using that"
else
  tokens=$(curl --negotiate -u : -X POST -H 'Content-Type: application/json' --data '{"description":"Using Istio developer build images"}' https://employee-token-manager.registry.redhat.com/v1/tokens -s | jq)
fi
username="$(echo "$tokens" | jq '.[0].credentials.username' | tr -d '"')"
password="$(echo "$tokens" | jq '.[0].credentials.password' | tr -d '"')"

# Add the token to the pull secret file
oc get secret/pull-secret -n openshift-config -o json | jq -r '.data.".dockerconfigjson"' | base64 -d > authfile
podman login --authfile authfile --username "${username}" --password "${password}" brew.registry.redhat.io
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=authfile

# This didn't work for me, not even sure if it's in the right namespace
oc apply -f - <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: brew-registry
spec:
  repositoryDigestMirrors:
  - mirrors:
    - brew.registry.redhat.io
    source: registry.redhat.io
  - mirrors:
    - brew.registry.redhat.io
    source: registry.stage.redhat.io
  - mirrors:
    - brew.registry.redhat.io
    source: registry-proxy.engineering.redhat.com
EOF

# Get the latest daily pipeline build
latest_build=$(brew list-builds --package=istio-rhel8-operator-metadata-container --owner=exd-cpaas-bot-prod  | tail -1 | awk '{print $1}')
echo "Latest Build: $latest_build"

url=$(curl -sS http://external-ci-coldstorage.datahub.redhat.com/cvp/cvp-redhat-operator-bundle-image-validation-test/${latest_build}/ | grep href | tail -1 | grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' |   sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i')

cvpTestReport=$(curl -sS ${url}cvp-test-report.html)
indexImage=$( echo "$cvpTestReport" | grep -i "Index image v4." | tail -1)
image=$(echo "$indexImage" | awk '{print $5}')
image=${image%<\/div>}
version=$(echo "$indexImage" | grep "v4\.[0-9][0-9]" -o)

# Swap the internal hostname with a public one
# TODO: This can be done via the ImageContentSourcePolicy object, but it didn't work for me
image=$(echo "$image" | sed 's#registry-proxy.engineering.redhat.com#brew.registry.redhat.io#')

echo "Using image $image for OCP Version $version"

oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: quay-iib
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  displayName: Service Mesh Daily Build
  publisher: Daily Build
  image: "${image}"
  updateStrategy:
    registryPoll:
      interval: "30m"
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator
  namespace: openshift-operators
spec:
  channel: stable
  source: quay-iib
  installPlanApproval: Automatic
  name: servicemeshoperator
  sourceNamespace: openshift-marketplace
EOF

echo "Successfully installed the latest OSSM Daily Build!"
