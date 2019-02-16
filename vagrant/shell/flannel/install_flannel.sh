#!/bin/bash
# 部署flannel网络脚本

FLANNEL_TGZ=flannel-v0.10.0-linux-amd64.tar.gz

# 向etcd写入集群Pod网段信息
/k8s/etcd/bin/etcdctl \
--ca-file=/k8s/etcd/ssl/ca.pem --cert-file=/k8s/etcd/ssl/server.pem \
--key-file=/k8s/etcd/ssl/server-key.pem \
--endpoints="https://172.16.31.12:2379,\
https://172.16.35.10:2379,https://172.16.35.11:2379" \
set /coreos.com/network/config  '{ "Network": "10.24.0.0/16", "Backend": {"Type": "vxlan"}}'

# 解压flannel并安装
if [ ! -e "$FLANNEL_TGZ" ];then
    echo "$FLANNEL_TGZ missing"
    exit 1
fi

tar -zxf $FLANNEL_TGZ -C /k8s/kubernetes/bin/

# 配置flannel
cp -f flanneld /k8s/kubernetes/cfg/

# 配置flanneld systemd文件
cp -f flanneld.service /usr/lib/systemd/system/

# 需要先手动修改docker.service里指定子网段的配置
# 这里假设已经修改

# 启动flannel服务
# 注意启动flannel前要关闭docker及相关的kubelet这样flannel才会覆盖docker0网桥
systemctl daemon-reload
systemctl stop docker
systemctl start flanneld
systemctl enable flanneld
systemctl start docker