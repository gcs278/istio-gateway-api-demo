#!/bin/bash

set -e

# echo an error message before exiting
trap 'test $? -ne 0 && echo "ERROR: Script failed with exit code $?."' EXIT

# 1. Must be connected to the VPN
# 2. Need the command "brew", not sure where I got this from originally...
# 3. Make sure /etc/krb5.conf has:
#   [libdefaults]
#      dns_canonicalize_hostname = fallback
BASE_URL=employee-token-manager.registry.redhat.com
TOKEN_URL=https://${BASE_URL}/v1/tokens
if [[ $(dig +short "$BASE_URL") == "" ]]; then
  echo "ERROR: You need to connect to the VPN"
  exit 1
fi

if curl --negotiate -u : ${TOKEN_URL} -s | grep -qi "no authorization context provided"; then
  echo "No active kerberos ticket..."
  echo "Log into kerberos (should be your laptop password):"
  kinit ${USER}@IPA.REDHAT.COM
fi

# Need to create, or retrieve a token to add to your cluster so you can pull the daily image
# If you have one already (made with the description we specified in this script...)
tokens=$(curl --negotiate -u : ${TOKEN_URL} -s | jq)
if echo "$tokens" | grep -qi "Using Istio developer build images"; then
  echo "Token already exists, using that"
else
  tokens=$(curl --negotiate -u : -X POST -H 'Content-Type: application/json' --data '{"description":"Using Istio developer build images"}' ${TOKEN_URL} -s | jq)
fi
username="$(echo "$tokens" | jq '.[0].credentials.username' | tr -d '"')"
password="$(echo "$tokens" | jq '.[0].credentials.password' | tr -d '"')"

if [[ "$username" == "" ]] || [[ "$password" == "" ]]; then
  echo "ERROR: Something went wrong with getting token"
  exit 1
fi

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

if [ -z ${TARGET_OSSM_BUILD+x} ]; then
  # Get the latest daily pipeline build, according to the highest version
  latest_build=$(brew list-builds --package=istio-rhel8-operator-metadata-container --owner=exd-cpaas-bot-prod | awk '{print $1}' | sort -h | tail -1)
  echo "Latest Build: $latest_build"
  TARGET_OSSM_BUILD=${latest_build}
fi

url=$(curl -sS http://external-ci-coldstorage.datahub.redhat.com/cvp/cvp-redhat-operator-bundle-image-validation-test/${TARGET_OSSM_BUILD}/ | grep href | tail -1 | grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' |   sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i')

cvpTestReportFile="cvp-test-report"
fileList=$(curl -sS ${url})
if ! echo "$fileList" | grep -q "$cvpTestReportFile"; then
  echo "ERROR: Build $TARGET_OSSM_BUILD doesn't have ${url}${cvpTestReportFile}.html"
  echo "       Try setting TARGET_OSSM_BUILD to a specific OSSM build version"
  echo "       Versions can be found here: https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=74330"
  exit 1
fi

cvpTestReport=$(curl -sS "${url}${cvpTestReportFile}.html")
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
EOF

# Install subscription and operator
if [[ "$1" != "--nosub" ]]; then
  oc apply -f - << EOF
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

  while ! oc get deployment -n openshift-operators istio-operator &> /dev/null; do
    echo "Waiting for the istio-operator deployment to appear in openshift-operators namespace (this can take a long time)"
    sleep 5
  done

  echo "Waiting for istio-operator deployment to rollout"
  oc rollout status -w deployment -n openshift-operators istio-operator
fi

echo "Successfully installed the latest OSSM Daily Build!"
