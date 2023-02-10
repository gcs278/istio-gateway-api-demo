#! /usr/bin/env bash

hosts_gwapi="$(oc get httproute -A --no-headers -o custom-columns="route:.spec.hostnames[0]") $(oc get tlsroute -A --no-headers -o custom-columns="route:.spec.hostnames[0]")"
hosts_istio="$(oc get VirtualService -n istioapi --no-headers -o custom-columns="route:.spec.hosts[0]")"

for j in ${hosts_istio} ${hosts_gwapi}; do
  if [[ "$j" == "<none>" ]]; then
    continue
  fi
  PAGE=""
  PROTO="http"
  URL="${j}"
  HOST_ARG=""
  echo "##### $j #####"
  if [[ "${j}" == re.* ]] || [[ "${j}" == pass.* ]] || [[ "${j}" == edge.* ]]; then
    PROTO="https"
  fi

  if [[ "${j}" == book* ]]; then
    PAGE="productpage"
  fi

  # This means we don't have DNS, so have to curl with resolve
  if [[ "${URL}" == *fake.com ]]; then
    gateway=$(echo "${URL}" | awk -F'.' '{print $2}')
    gateway_ns=$(echo "${URL}" | awk -F'.' '{print $3}')
    HOST_ARG="-HHost:${URL}"
    URL=$(oc get gateway -n $gateway_ns $gateway -o jsonpath='{.status.addresses[0].value}')
  fi

  cmd="curl ${HOST_ARG} -k -sS -I ${PROTO}://${URL}/${PAGE}"
  echo $cmd
  if [[ "$1" == "-h" ]]; then
    $cmd
  else
    echo -n " -> "
    $cmd | head -1
  fi
done

#echo "##### Console Route #####"
#cmd="curl -k -sS -I https://console-openshift-console.${DOMAIN}"
#echo $cmd
#echo -n " -> "
#$cmd | head -1
