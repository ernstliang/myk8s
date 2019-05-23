# kubeadm部署安装kubernetes

## 集群环境准备
集群多样，简单使用vagrant创建虚拟机集群用于验证


## 安装docker


## 安装kubeadm
[官网链接](https://kubernetes.io/zh/docs/setup/independent/install-kubeadm/)

可以使用`install_kubeadm.sh`脚本一键安装kubeadm

### 命令行安装kubeadm,kubelet和Kubectl
1. 配置kubernetes.repo

```
# 配置源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

2. 安装kubelet、kubeadm、kubectl

```
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
```

3. 开机自启kubelet

```
systemctl enable --now kubelet
```


## 生成kubeadm默认配置文件

```
$ kubeadm config print init-defaults > kubeadm.yaml
```

需要修改kubeadm.yaml配置

修改`control-plane`(master节点)的`advertiseAddress`

```
localAPIEndpoint:
  advertiseAddress: 192.168.0.100
  bindPort: 6443
```

配置子网段

```
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
```

使用flannel网络插件就配置`podSubnet`为`10.244.0.0/16`网段

## 