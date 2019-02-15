#!/bin/bash
# 部署node节点
# master节点执行脚本

set -x

# 两个node节点ip
NODE1=172.16.35.10
NODE2=172.16.35.11
NODE_TGZ=kubernetes-node-linux-amd64.tar.gz

# k8s node节点
if [ ! -e $NODE_TGZ ];then
    echo "$NODE_TGZ is missing!!!"
    exit 1
fi

BIN=kubernetes/node/bin
echo "BIN=$BIN"
if [ ! -d $BIN ];then
    echo "Extract $NODE_TGZ"
    tar -zxf $NODE_TGZ
fi

# 拷贝master节点node组件
cp $BIN/kubelet $BIN/kube-proxy /k8s/kubernetes/bin/
# 拷贝node组件
scp $BIN/kubelet $BIN/kube-proxy $NODE1:/k8s/kubernetes/bin/
scp $BIN/kubelet $BIN/kube-proxy $NODE2:/k8s/kubernetes/bin/

# 执行environment.sh
chmod +x environment.sh
./environment.sh

# 拷贝bootstrap.kubeconfig kube-proxy.kubeconfig到所有node节点
cp bootstrap.kubeconfig kube-proxy.kubeconfig kubelet.config kubelet kube-proxy /k8s/kubernetes/cfg/
scp bootstrap.kubeconfig kube-proxy.kubeconfig kubelet.config kubelet kube-proxy $NODE1:/k8s/kubernetes/cfg/
scp bootstrap.kubeconfig kube-proxy.kubeconfig kubelet.config kubelet kube-proxy $NODE2:/k8s/kubernetes/cfg/

# 拷贝kubelet的systemd unit文件
cp kubelet.service kube-proxy.service /usr/lib/systemd/system/
scp kubelet.service kube-proxy.service $NODE1:/usr/lib/systemd/system/
scp kubelet.service kube-proxy.service $NODE2:/usr/lib/systemd/system/

# 将kubelet-bootstrap用户绑定到系统集群角色
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap

# 启动master节点的kubelet
systemctl daemon-reload

systemctl start kubelet
systemctl enable kubelet 

systemctl enable kube-proxy
systemctl restart kube-proxy