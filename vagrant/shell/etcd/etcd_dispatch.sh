#!/bin/bash
# master节点派发etcd二进制和配置文件到node节点
# 需要master节点下的/k8s/etcd已经配置完成
# master到各节点ssh是passwdless

# 两个节点ip
NODE1=172.16.35.10
NODE2=172.16.35.11

# 拷贝/k8s/etcd到各Node节点
scp -r /k8s/etcd $NODE1:/k8s
scp -r /k8s/etcd $NODE2:/k8s

# 拷贝etcd.service
scp /usr/lib/systemd/system/etcd.service  $NODE1:/usr/lib/systemd/system/etcd.service
scp /usr/lib/systemd/system/etcd.service  $NODE2:/usr/lib/systemd/system/etcd.service

# 拷贝各自Node的etcd配置文件
scp etcd02 $NODE1:/k8s/etcd/cfg/etcd
scp etcd03 $NODE2:/k8s/etcd/cfg/etcd
