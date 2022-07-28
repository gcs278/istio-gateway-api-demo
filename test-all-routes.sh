#!/bin/bash 

hosts_gwapi="$(oc get httproute -n gwapi --no-headers -o custom-columns="route:.spec.hostnames[0]") $(oc get tlsroute -n gwapi --no-headers -o custom-columns="route:.spec.hostnames[0]")"
hosts_istio="$(oc get VirtualService -n istioapi --no-headers -o custom-columns="route:.spec.hosts[0]")"

for j in ${hosts_istio} ${hosts_gwapi}; do
  echo "##### $j #####"
  if [[ "${j}" == http* ]]; then
    PROTO="http"
  else
    PROTO="https"
  fi

  cmd="curl -k -sS -I ${PROTO}://${j}"
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
