#!/bin/bash

PORT=8080
SVC=showcow
NS=openfaas-fn
CLUSTER_IP=$(kubectl -n $NS get svc $SVC --output='jsonpath={.spec.clusterIP}')

kubectl run -i --rm --image=curlimages/curl --restart=Never test-curl -- -sSL http://"$CLUSTER_IP":"$PORT"

sleep 3
kubectl get pods --namespace=$NS
