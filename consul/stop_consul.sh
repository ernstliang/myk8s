#!/bin/bash
#停止k8s consul集群

#delete service/consul
kubectl get services
kubectl delete service/consul

#delete statefulset/consul
kubectl get statefulset
kubectl delete statefulset/consul

#delete pv/pvc
kubectl get pvc
kubectl get pv

kubectl delete pvc/data-consul-0
kubectl delete pvc/data-consul-1
kubectl delete pvc/data-consul-2

kubectl delete pv/data-consul-0
kubectl delete pv/data-consul-1
kubectl delete pv/data-consul-2