#!/bin/bash
# master to node
# 将flannel复制到node节点

# 两个节点ip
NODE1=172.16.35.10
NODE2=172.16.35.11

# 拷贝/k8s/etcd到各Node节点
scp -r /k8s/kubernetes $NODE1:/k8s
scp -r /k8s/kubernetes $NODE2:/k8s

# 复制flanneld.service
scp /usr/lib/systemd/system/flanneld.service  $NODE1:/usr/lib/systemd/system/flanneld.service
scp /usr/lib/systemd/system/flanneld.service  $NODE2:/usr/lib/systemd/system/flanneld.service