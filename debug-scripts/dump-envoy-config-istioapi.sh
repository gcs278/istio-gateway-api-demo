#! /usr/bin/env bash
kill $(lsof -i :15000 | tail -1 | awk '{print $2}') &> /dev/null


POD=$(oc get -n istio-system pod --no-headers | grep istio-ingressgateway | awk '{print $1}')
oc port-forward --address 127.0.0.1 -n istio-system pod/${POD} 15000:15000 &

while true; do
  curl http://localhost:15000/config_dump && break
  sleep 1
done

kill $(jobs -p)
