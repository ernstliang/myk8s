# 手动搭建k8s集群

## 初始化环境
### 设置关闭防火墙机SELINUX
关闭防火墙

```
systemctl stop firewalld && systemctl disable firewalld
```

关闭SELINUX

```
setenforce 0
vi /etc/selinux/config
修改 SELINUX=disabled
```

### 关闭Swap

```
swapoff -a && sysctl -w vm.swappiness=0
vi /etc/fstab
#/dev/mapper/cl-swap     swap                    swap    defaults        0 0
```

### 安装 Docker
配置docker源

```
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

`yum-config-manager` 系统默认没有安装这个命令，这个命令在yum-utils 包里，可以通过命令`yum -y install yum-utils`安装<br>

查看docker源版本

```
yum list docker-ce --showduplicates | sort -r
```

安装docker

```
yum install docker-ce -y
```

启动docker并配置开机启动

```
systemctl start docker && systemctl enable docker
```

设置docker所需参数

```
cat << EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl -p /etc/sysctl.d/k8s.conf
```

### 创建安装目录

```
mkdir /k8s/etcd/{bin,cfg,ssl} -p
mkdir /k8s/kubernetes/{bin,cfg,ssl} -p
```

### 安装配置cfssl

```
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64
mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
```

#### 创建etcd证书

```
cat << EOF | tee ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "www": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF
```

#### 创建etcd ca配置文件

```
cat << EOF | tee ca-csr.json
{
    "CN": "etcd CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Hangzhou",
            "ST": "Hangzhou"
        }
    ]
}
EOF
```

#### 创建etcd server证书

```
cat << EOF | tee server-csr.json
{
    "CN": "etcd",
    "hosts": [
    "172.16.35.10",
    "172.16.35.11",
    "172.16.35.12"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Hangzhou",
            "ST": "Hangzhou"
        }
    ]
}
EOF
```

#### 生成etcd ca证书和私钥

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
```

#### 拷贝etcd证书文件

```
cp ca*pem server*pem /k8s/etcd/ssl
```

#### 创建k8s CA证书

```
cat << EOF | tee ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF
```

```
cat << EOF | tee ca-csr.json
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Hangzhou",
            "ST": "Hangzhou",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
```

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
```

#### 生成API Server证书
master的host

```
cat << EOF | tee server-csr.json
{
    "CN": "kubernetes",
    "hosts": [
      "10.0.2.15",
      "127.0.0.1",
      "172.16.35.12",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Hangzhou",
            "ST": "Hangzhou",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
```

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server
```

#### 生成k8s proxy证书

```
cat << EOF | tee kube-proxy-csr.json
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "Hangzhou",
      "ST": "Hangzhou",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
```

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
```

### ssh-key认证
各个节点执行，生成ssh key

```
ssh-keygen
```

需要确保master ssh到node节点passwdless

```
ssh-copy-id 172.16.35.10
ssh-copy-id 172.16.35.11
```

Node1的ip: 172.16.35.10<br>
Node2的ip: 172.16.35.11<br>
Copy节点ssh密钥需要ssh登录密码

### 部署ETCD
#### 上传并解压etcd安装tar包
将etcd部署到/k8s/etcd目录下

```
tar -zxf etcd-v3.3.10-linux-amd64.tar.gz
cd etcd-v3.3.10-linux-amd64
cp etcd etcdctl /k8s/etcd/bin/
```

配置etcd配置文件

```
vim /k8s/etcd/cfg/etcd
```

注：vim未安装可以先`yum install -y vim`命令安装或者直接使用vi命令

```
#[Member]
ETCD_NAME="etcd01"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://172.16.35.12:2380"
ETCD_LISTEN_CLIENT_URLS="https://172.16.35.12:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://172.16.35.12:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://172.16.35.12:2379"
ETCD_INITIAL_CLUSTER="etcd01=https://172.16.35.12:2380,etcd02=https://172.16.35.10:2380,etcd03=https://172.16.35.11:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
```

#### 创建etcd的systemd unit文件

```
vim /usr/lib/systemd/system/etcd.service 
```

配置内容

```
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=/k8s/etcd/cfg/etcd
ExecStart=/k8s/etcd/bin/etcd \
--name=${ETCD_NAME} \
--data-dir=${ETCD_DATA_DIR} \
--listen-peer-urls=${ETCD_LISTEN_PEER_URLS} \
--listen-client-urls=${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
--advertise-client-urls=${ETCD_ADVERTISE_CLIENT_URLS} \
--initial-advertise-peer-urls=${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
--initial-cluster=${ETCD_INITIAL_CLUSTER} \
--initial-cluster-token=${ETCD_INITIAL_CLUSTER_TOKEN} \
--initial-cluster-state=new \
--cert-file=/k8s/etcd/ssl/server.pem \
--key-file=/k8s/etcd/ssl/server-key.pem \
--peer-cert-file=/k8s/etcd/ssl/server.pem \
--peer-key-file=/k8s/etcd/ssl/server-key.pem \
--trusted-ca-file=/k8s/etcd/ssl/ca.pem \
--peer-trusted-ca-file=/k8s/etcd/ssl/ca.pem
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

#### 启动etcd服务

```
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

#### 配置Node1和Node2的etcd服务

```
cd /k8s/ 
scp -r etcd 172.16.35.10:/k8s/
scp -r etcd 172.16.35.11:/k8s/
scp /usr/lib/systemd/system/etcd.service  172.16.35.10:/usr/lib/systemd/system/etcd.service
scp /usr/lib/systemd/system/etcd.service  172.16.35.11:/usr/lib/systemd/system/etcd.service 

修改各Node下的/k8s/etcd/cfg/etcd
ETCD_NAME="etcd02"
ETCD_NAME="etcd03"
...

Ip修改为各Node自己的ip
```

注：启动etcd需要同时启动二个节点，启动一个节点集群是无法正常启动的

#### 验证etcd集群是否正常运行
增加环境变量配置

```
root环境下
vi ~/.bash_profile
PATH:$PATH:/k8s/etcd/bin:/k8s/kubernetes/bin
更新环境变量
source ~/.bash_profile
```

检测etcd集群健康状况
```
etcdctl \
--ca-file=/k8s/etcd/ssl/ca.pem \
--cert-file=/k8s/etcd/ssl/server.pem \
--key-file=/k8s/etcd/ssl/server-key.pem \
--endpoints="https://172.16.35.12:2379,\
https://172.16.35.10:2379,\
https://172.16.35.11:2379" cluster-health
```


### 部署Flannel网络

#### 向etcd写入集群pod子网段信息

```
/k8s/etcd/bin/etcdctl \
--ca-file=/k8s/etcd/ssl/ca.pem --cert-file=/k8s/etcd/ssl/server.pem \
--key-file=/k8s/etcd/ssl/server-key.pem \
--endpoints="https://172.16.31.12:2379,\
https://172.16.35.10:2379,https://172.16.35.11:2379" \
set /coreos.com/network/config  '{ "Network": "10.24.0.0/16", "Backend": {"Type": "vxlan"}}'
```

#### 解压安装flannel

```
tar -zxf flannel-v0.10.0-linux-amd64.tar.gz -C /k8s/kubernetes/bin/
```

#### 配置flannel

```
vim /k8s/kubernetes/cfg/flanneld

增加:
FLANNEL_OPTIONS="--etcd-endpoints=https://172.16.35.12:2379,https://172.16.35.10:2379,https://172.16.35.11:2379 -etcd-cafile=/k8s/etcd/ssl/ca.pem -etcd-certfile=/k8s/etcd/ssl/server.pem -etcd-keyfile=/k8s/etcd/ssl/server-key.pem"
```

#### 创建flanneld的systemd unit文件

```
vim /usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network-online.target network.target
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/k8s/kubernetes/cfg/flanneld
ExecStart=/k8s/kubernetes/bin/flanneld --ip-masq $FLANNEL_OPTIONS
ExecStartPost=/k8s/kubernetes/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

- mk-docker-opts.sh 脚本将分配给 flanneld 的 Pod 子网网段信息写入 /run/flannel/subnet.env文件，后续 docker 启动时 使用这个文件中的环境变量配置 docker0 网桥；
- flanneld 使用系统缺省路由所在的接口与其它节点通信，对于有多个网络接口（如内网和公网）的节点，可以用 -iface 参数指定通信接口
- flanneld 运行时需要 root 权限；

#### 配置docker启动指定子网段

```
vim /usr/lib/systemd/system/docker.service

修改:
+ EnvironmentFile=/run/flannel/subnet.env
+ ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS
- ExecStart=/usr/bin/dockerd -H fd://
```

#### 将flannel部署到Node节点

```
# 两个节点ip
NODE1=172.16.35.10
NODE2=172.16.35.11

# 拷贝/k8s/etcd到各Node节点
scp -r /k8s/kubernetes $NODE1:/k8s
scp -r /k8s/kubernetes $NODE2:/k8s

# 复制flanneld.service
scp /usr/lib/systemd/system/flanneld.service  $NODE1:/usr/lib/systemd/system/flanneld.service
scp /usr/lib/systemd/system/flanneld.service  $NODE2:/usr/lib/systemd/system/flanneld.service
```

#### 启动flannel
注: 启动flannel前要关闭docker及相关的kubelet这样flannel才会覆盖docker0网桥

```
systemctl daemon-reload
systemctl stop docker
systemctl start flanneld
systemctl enable flanneld
systemctl start docker
```

### 部署k8s master节点
kubernetes master 节点运行如下组件：

- kube-apiserver
- kube-scheduler
- kube-controller-manager

kube-scheduler 和 kube-controller-manager 可以以集群模式运行，通过 leader 选举产生一个工作进程，其它进程处于阻塞模式。

#### 安装master组件

```
tar -zxf kubernetes-server-linux-amd64.tar.gz
SER_BIN=kubernetes/server/bin
cp -f ${SER_BIN}/kube-scheduler ${SER_BIN}/kube-apiserver ${SER_BIN}/kube-controller-manager ${SER_BIN}/kubectl /k8s/kubernetes/bin/
```

#### 生成TLS Bootstrapping Token
master和node节点需要使用相同的token

```
TOKEN=`head -c 16 /dev/urandom | od -An -t x | tr -d ' '`
echo "$TOKEN,kubelet-bootstrap,10001,\"system:kubelet-bootstrap\"" > /k8s/kubernetes/cfg/token.csv
# 缓存Token,Node节点部署时需要
echo "$TOKEN" > token.tmp
```

#### 部署api-server配置文件

```
vim /k8s/kubernetes/cfg/kube-apiserver
 
KUBE_APISERVER_OPTS="--logtostderr=true \
--v=4 \
--etcd-servers=https://172.16.35.12:2379,https://172.16.35.10:2379,https://172.16.35.11:2379 \
--bind-address=172.16.35.12 \
--secure-port=6443 \
--advertise-address=172.16.35.12 \
--allow-privileged=true \
--service-cluster-ip-range=10.24.0.0/24 \
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota,NodeRestriction \
--authorization-mode=RBAC,Node \
--enable-bootstrap-token-auth \
--token-auth-file=/k8s/kubernetes/cfg/token.csv \
--service-node-port-range=30000-50000 \
--tls-cert-file=/k8s/kubernetes/ssl/server.pem  \
--tls-private-key-file=/k8s/kubernetes/ssl/server-key.pem \
--client-ca-file=/k8s/kubernetes/ssl/ca.pem \
--service-account-key-file=/k8s/kubernetes/ssl/ca-key.pem \
--etcd-cafile=/k8s/etcd/ssl/ca.pem \
--etcd-certfile=/k8s/etcd/ssl/server.pem \
--etcd-keyfile=/k8s/etcd/ssl/server-key.pem"
```

#### apiserver systemd unit文件

```
vim /usr/lib/systemd/system/kube-apiserver.service

[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/k8s/kubernetes/cfg/kube-apiserver
ExecStart=/k8s/kubernetes/bin/kube-apiserver $KUBE_APISERVER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

#### 部署scheduler配置文件

```
vim /k8s/kubernetes/cfg/kube-scheduler

KUBE_SCHEDULER_OPTS="--logtostderr=true --v=4 --master=127.0.0.1:8080 --leader-elect"
```

#### kube-scheduler的systemd unit文件

```
vim /usr/lib/systemd/system/kube-scheduler.service

[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=/k8s/kubernetes/cfg/kube-scheduler
ExecStart=/k8s/kubernetes/bin/kube-scheduler $KUBE_SCHEDULER_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
```

#### 部署controller-manager配置文件

```
vim /k8s/kubernetes/cfg/kube-controller-manager

KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=true \
--v=4 \
--master=127.0.0.1:8080 \
--leader-elect=true \
--address=127.0.0.1 \
--service-cluster-ip-range=10.24.0.0/16 \
--cluster-name=kubernetes \
--cluster-signing-cert-file=/k8s/kubernetes/ssl/ca.pem \
--cluster-signing-key-file=/k8s/kubernetes/ssl/ca-key.pem  \
--root-ca-file=/k8s/kubernetes/ssl/ca.pem \
--service-account-private-key-file=/k8s/kubernetes/ssl/ca-key.pem"
```

#### kube-controller-manager的systemd unit文件

```
vim /usr/lib/systemd/system/kube-controller-manager.service

[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=/k8s/kubernetes/cfg/kube-scheduler
ExecStart=/k8s/kubernetes/bin/kube-scheduler $KUBE_SCHEDULER_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
```

#### 启动master组件

```
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
```

#### 查看master服务状态

```
kubectl get cs,nodes

NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true"}
etcd-1               Healthy   {"health":"true"}
etcd-2               Healthy   {"health":"true"}
```


### 部署node节点
kubernetes work 节点运行如下组件：

- docker
- kubelet
- kube-proxy


#### 安装node组件

```
BIN=kubernetes/node/bin
# 拷贝master节点node组件
cp $BIN/kubelet $BIN/kube-proxy /k8s/kubernetes/bin/
# 拷贝node组件
scp $BIN/kubelet $BIN/kube-proxy $NODE1:/k8s/kubernetes/bin/
scp $BIN/kubelet $BIN/kube-proxy $NODE2:/k8s/kubernetes/bin/
```

#### 生成bootstrap和kube-proxy的配置文件

```
vim environment.sh

#!/bin/bash

set -x

#创建kubelet bootstrapping kubeconfig
BOOTSTRAP_TOKEN=`cat token.tmp`
KUBE_APISERVER="https://172.16.35.12:6443"
#设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/k8s/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig
 
#设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
 
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
 
# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
 
#----------------------
 
# 创建kube-proxy kubeconfig文件
 
kubectl config set-cluster kubernetes \
  --certificate-authority=/k8s/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
 
kubectl config set-credentials kube-proxy \
  --client-certificate=/k8s/kubernetes/ssl/kube-proxy.pem \
  --client-key=/k8s/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
 
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
 
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

在master节点上运行上面脚本生成配置文件，并拷贝配置文件到所有node节点

```
# 拷贝bootstrap.kubeconfig kube-proxy.kubeconfig到所有node节点
cp bootstrap.kubeconfig kube-proxy.kubeconfig kubelet.config kubelet kube-proxy /k8s/kubernetes/cfg/
scp bootstrap.kubeconfig kube-proxy.kubeconfig kubelet.config kubelet kube-proxy $NODE1:/k8s/kubernetes/cfg/
scp bootstrap.kubeconfig kube-proxy.kubeconfig kubelet.config kubelet kube-proxy $NODE2:/k8s/kubernetes/cfg/
```

#### kubelet配置
kubelet参数配置模板

```
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 172.16.35.12
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS: ["10.24.0.10"]
clusterDomain: cluster.local.
failSwapOn: false
authentication:
  anonymous:
    enabled: true
```

- address:节点的ip
- clusterDNS:指定dns的ip，kube-dns的clusterip 可通过`kubectl get service --namespace=kube-system`查看
- port：10250是kubectl发起鉴权证书的csr请求的端口

kubelet的配置文件

```
KUBELET_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=172.16.35.12 \
--kubeconfig=/k8s/kubernetes/cfg/kubelet.kubeconfig \
--bootstrap-kubeconfig=/k8s/kubernetes/cfg/bootstrap.kubeconfig \
--config=/k8s/kubernetes/cfg/kubelet.config \
--cert-dir=/k8s/kubernetes/ssl \
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"
```

--hostname-override:node节点的ip<br>

kubelet的systemd unit文件

```
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service
 
[Service]
EnvironmentFile=/k8s/kubernetes/cfg/kubelet
ExecStart=/k8s/kubernetes/bin/kubelet $KUBELET_OPTS
Restart=on-failure
KillMode=process
 
[Install]
WantedBy=multi-user.target
```

#### 将kubelet-bootstrap用户绑定到系统集群角色

```
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
```

注意这个指令默认连接localhost:8080端口，可以在master上操作

#### 启动kubelet

```
systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet 
```

#### master接受kubelet CSR请求
可以手动或自动 approve CSR 请求，推荐使用自动方式<br>
演示使用手动方式：

```
kubectl get csr
```

接受node

```
kubectl certificate approve node-csr-_ZX6yd5GQzdajU4ni2ChEGveadAUpV-X5bgGLiu82Iw
```

自动审批方式：<br>
参考:<br>
1. [https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#approval-controller](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#approval-controller)<br>
2. [https://www.sadlar.cn/2018/05/25/kubetnetes-自动签署新node节点的csr请求以及后续的续期](https://www.sadlar.cn/2018/05/25/kubetnetes-%E8%87%AA%E5%8A%A8%E7%AD%BE%E7%BD%B2%E6%96%B0node%E8%8A%82%E7%82%B9%E7%9A%84csr%E8%AF%B7%E6%B1%82%E4%BB%A5%E5%8F%8A%E5%90%8E%E7%BB%AD%E7%9A%84%E7%BB%AD%E6%9C%9F/)

#### 配置kube-proxy
kube-proxy 运行在所有 node节点上，它监听 apiserver 中 service 和 Endpoint 的变化情况，创建路由规则来进行服务负载均衡<br>

Kube-proxy配置文件

```
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=172.16.35.12 \
--cluster-cidr=10.24.0.0/16 \
--kubeconfig=/k8s/kubernetes/cfg/kube-proxy.kubeconfig"
```

--hostname-override:node节点的ip<br>
--cluster-cidr:同kube-apiserver和kube-controller-manager的--service-cluster-ip-range，同kube-dns所在网段<br>

Kube-proxy的systemd unit文件

```
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=/k8s/kubernetes/cfg/kube-proxy
ExecStart=/k8s/kubernetes/bin/kube-proxy $KUBE_PROXY_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

#### 启动kube-proxy

```
systemctl enable kube-proxy
systemctl restart kube-proxy
```

#### 查看node列表

```
kubectl get nodes

NAME           STATUS   ROLES    AGE     VERSION
172.16.35.10   Ready    node     6h49m   v1.13.0
172.16.35.12   Ready    master   27h     v1.13.0
```

#### 设置node或master的节点标签

```
kubectl label node 172.16.35.12  node-role.kubernetes.io/master='master'
kubectl label node 172.16.35.10  node-role.kubernetes.io/node='node'
```

删除node的标签

```
kubectl label node 172.16.35.12 node-role.kubernetes.io/node-
```