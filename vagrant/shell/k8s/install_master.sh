#!/bin/bash
# 安装k8s的master节点

set -x

SERVER_TGZ=kubernetes-server-linux-amd64.tar.gz
echo "$SERVER_TGZ"

if [ ! -e $SERVER_TGZ ];then
    echo "$SERVER_TGZ is missing!!!"
    exit 1
fi

# 解压
SER_BIN=kubernetes/server/bin
if [ ! -e $SER_BIN ];then
    echo "Extract $SER_BIN"
    tar -zxf $SERVER_TGZ
fi

# 拷贝master组件
cp -f ${SER_BIN}/kube-scheduler ${SER_BIN}/kube-apiserver ${SER_BIN}/kube-controller-manager ${SER_BIN}/kubectl /k8s/kubernetes/bin/

# 部署TLS Bootstrapping Token
TOKEN=`head -c 16 /dev/urandom | od -An -t x | tr -d ' '`
echo "$TOKEN,kubelet-bootstrap,10001,\"system:kubelet-bootstrap\"" > /k8s/kubernetes/cfg/token.csv
# 缓存Token,Node节点部署时需要
echo "$TOKEN" > token.tmp

# api-server配置文件
cp -f kube-apiserver /k8s/kubernetes/cfg/
# kube-scheduler配置
cp -f kube-scheduler /k8s/kubernetes/cfg/
# kube-controller-manager配置
cp -f kube-controller-manager /k8s/kubernetes/cfg/

# kube-apiserver的systemd unit文件
cp -f kube-apiserver.service /usr/lib/systemd/system/
# kube-scheduler的systemd unit文件
cp -f kube-scheduler.service /usr/lib/systemd/system/
# kube-controller-manager的systemd unit文件
cp -f kube-controller-manager.service /usr/lib/systemd/system/

systemctl daemon-reload
# 启动apiserver
systemctl enable kube-apiserver
systemctl restart kube-apiserver

# 启动scheduler
systemctl enable kube-apiserver
systemctl restart kube-apiserver

# 启动controller-manager
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager

# 查看apiserver的运行状态
ps -ef | grep kube-apiserver

# 查看master服务状态
kubectl get cs,nodes
