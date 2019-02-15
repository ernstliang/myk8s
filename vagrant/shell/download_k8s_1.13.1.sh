#!/bin/bash
# 下载k8s 1.13.1版本二进制文件包

wget https://dl.k8s.io/v1.13.1/kubernetes-server-linux-amd64.tar.gz
wget https://dl.k8s.io/v1.13.1/kubernetes-node-linux-amd64.tar.gz
wget https://dl.k8s.io/v1.13.1/kubernetes-client-linux-amd64.tar.gz

wget https://github.com/etcd-io/etcd/releases/download/v3.3.10/etcd-v3.3.10-linux-amd64.tar.gz
wget https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz