#! /usr/bin/env bash

kill $(lsof -i :15000 | tail -1 | awk '{print $2}') &> /dev/null
POD=$(oc get -n gwapi pod --no-headers | grep -i gateway | awk '{print $1}' | head -1)
oc port-forward --address 127.0.0.1 -n gwapi pod/${POD} 15000:15000 &

while true; do
  curl http://localhost:15000/config_dump && break
  sleep 1
done

kill $(jobs -p)
