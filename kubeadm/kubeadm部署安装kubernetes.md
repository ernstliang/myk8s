# kubeadm部署安装kubernetes

集群环境准备<br>
集群多样，简单使用vagrant创建虚拟机集群用于验证，但需要机器内存足够，vagrant集群搭建参考`../vagrant`<br>
或者局域网内配置几台centos机器，下面步骤都是基于centos环境上配置的

## 1.安装docker
使用shell目录下的`install_docker.sh`脚本一键安装docker

```
# ./install_docker.sh
```

检查ip_forward设置

```
# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
```

## 2.安装kubeadm
[官网链接](https://kubernetes.io/zh/docs/setup/independent/install-kubeadm/)

### 2.1 前置条件设置

- 把SELinux设置成permissive，setenforce 0或者修改`/etc/selinux/config`文件永久生效
- 设置`net.bridge.bridge-nf-call-iptables`为1
- 关闭sweap

```
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

- 确认`br_netfilter`是否已开启

```
$ lsmod | grep br_netfilter
$ modprobe br_netfilter
```


### 2.2 [新] 脚本安装
使用shell目录下的`install_kubeadm.sh`脚本一键安装kubeadm

```
# ./install_kubeadm.sh
```

### 2.3 [旧] 命令行安装kubeadm,kubelet和Kubectl
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

kubeadm和kubernetes的版本相关，需要根据kubernetes的版本选用kubeadm版本
指定安装 1.14.1-0
显示所有kubectl的版本
yum list kubectl —showduplicates
yum install kubectl-1.14.1-0
yum install kubelet-1.14.1-0
yum install kubeadm-1.14.1-0
```

3. 开机自启kubelet

```
systemctl enable --now kubelet
```

## 3.下载kubernetes镜像-1.14.1

使用shell目录下的`pull_k8s_1.14.1.sh`脚本一键下载kubernetes v1.14.1版本镜像

```
$ ./pull_k8s_1.14.1.sh
```

由于kubernetes的镜像墙内下载不了，可以使用国内的镜像服务(如:腾讯云镜像服务、aliyun镜像服务等)，自己写Dockerfile指定需要下载的镜像打包出自己的镜像，然后通过`docker tag`重命名成需要的镜像。

## 4.安装kubernetes
开始使用kubeadm安装kubernetes集群

### 4.1 安装master

#### hostname设置

hostname设置不规范`kubeadm init`时可能会报错，不能使用'_'

```
name: Invalid value: "k8s_master": a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for
 validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
```

设置hostname

```
# hostnamectl set-hostname <newhostname>

修改/etc/hosts修改主机名为 <newhostname>
```


#### 生成kubeadm默认配置文件

```
$ kubeadm config print init-defaults > kubeadm.yaml
```

需要修改kubeadm.yaml配置

修改`control-plane`(master节点)的`advertiseAddress`，我这边master的ip为`192.168.0.100`

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

#### 配置master

```
# kubeadm init --config kubeadm.yaml
```

安装成功后会输出如下类似信息

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubeadm join 192.168.0.100:6444 --token xxx --discovery-token-ca-cert-hash xxx
```

注：这里拷贝admin.conf命令需要执行，不然`kubectl`指令调用会提示错误

```
# kubectl get pods
Unable to connect to the server: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
```

前置步骤做完了，这里一般都会成功，如果还失败请根据错误提示自查。

前面步骤执行完后master节点已经快完成了，这是通过命令查看信息会得到如下信息

```
# kubectl get pods -n kube-system

NAME                           READY   STATUS             RESTARTS   AGE
coredns-fb8b8dccf-kck2j        0/1     Pending            0          2d1h
coredns-fb8b8dccf-lzn84        0/1     Pending            0          2d1h
etcd-nuc7                      1/1     Running            0          2d9h
kube-apiserver-nuc7            1/1     Running            0          2d9h
kube-controller-manager-nuc7   1/1     Running            1          2d9h
kube-proxy-gbkhb               1/1     Running            0          2d9h
kube-scheduler-nuc7            1/1     Running            1          2d9h
```

这是因为网络插件还未安装，coredns一直处于pending状态

安装网络插件flannel

```
# kubectl apply -f yaml/kube-flannel.yml
```

安装完网络插件后，coredns就会进入调度状态，这里选用flannel作为网络插件，当然也可以选用calico,weave等插件

安装calico网络插件

[calico官网](https://docs.projectcalico.org/v3.8/getting-started/kubernetes/)

```
下载calico yaml文件
# wget https://docs.projectcalico.org/v3.8/manifests/calico.yaml

修改calico yaml文件中的pod子网段
- name: CALICO_IPV4POOL_CIDR
  value: "192.168.0.0/16"
To kubeadm初始化master时指定的子网段
- name: CALICO_IPV4POOL_CIDR
  value: "10.244.0.0/16"

安装calico网络插件
# kubectl apply -f calico.yaml
```

如果调度完成后coredns一直处于`CrashLoopBackOff`状态

```
# kubectl get pods -n kube-system
NAME                           READY   STATUS             RESTARTS   AGE
coredns-fb8b8dccf-kck2j        0/1     CrashLoopBackOff   5        2d2h
coredns-fb8b8dccf-lzn84        0/1     CrashLoopBackOff   5        2d2h
```

这时就需要查看pod的日志具体分析

```
# kubectl -n kube-system logs coredns-fb8b8dccf-kck2j
```

例如错误信息如下:

```
k8s.io/dns/pkg/dns/dns.go:150: Failed to list *v1.Service: Get https://10.96.0.1:443/api/v1/services?resourceVersion=0: dial tcp 10.96.0.1:443: getsockopt: no route to host
```

这很可能是主机的 iptables 规则混乱了

需要重置下iptables规则:

```
 # systemctl stop kubelet
 # systemctl stop docker
 # iptables --flush
 # iptables -t nat --flush
 # systemctl start kubelet
 # systemctl start docker
```

通过Taint/Toleration调整master执行Pod的策略

默认情况下master是不允许运行用户pod的，而kubernetes做到这一点，依靠的是kubernetes的Taint/Toleration机制。

Taint/Toleration原理:一旦某个节点被加上了一个Taint，即被“打上了污点”，那么所有Pod就都不能在这个节点上运行，除非，有个别Pod声明自己能“容忍”这个“污点”，即声明Toleration，它才可以再这个节点上运行。

如果想要一个单节点的kubernetes，就需要删除master的这个Taint

```
$ kubectl taint nodes --all node-role.kubernetes.io/master-
```

### 4.2 新节点加入集群

新节点必须先执行`安装docker` `安装kubeadm`步骤

```
# kubeadm join ip:port --token xxx --discovery-token-ca-cert-hash xxx
```

这就是前面`kubeadm init`步骤成功后输出的加入集群的命令，若执行后无响应切无日志输出，可以设置日志等级`-v 3`查看

#### 错误处理

错误1:

```
Failed to request cluster info, will try again: [Get https://192.168.0.100:6443/api/v1/namespaces/kube-public/configmaps/cluster-info: dial tcp 192.168.0.100:6443: getsockopt: no route to host
```

错误原因: master节点开着防火墙

错误2：

```
I0524 21:05:58.645342    6831 token.go:147] [discovery] Failed to request cluster info, will try again: [Get https://192.168.0.100:6443/api/v1/namespaces/kube-public/configmaps/cluster-info: x509: certificate has expired or is not yet valid]
```

错误原因：新节点无法根据输入的ca信息无法调通master的apiserver，master和node节点时间不同步，可以安装ntp同步时间

检查：
检查token是否过期

```
# kubeadm token list
```

根据输出查看对应的token是否还在有效期内

token过期的处理

```
# kubeadm token create
```

生成新的token

检查ca证书sha256编码hash值

```
$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```

比较生成的hash值和join命令中输入的hash值是否一致

```
kubeadm join 192.168.5.100:6443 --token 6japvh.1zn6j06ztr0oj146 --discovery-token-ca-cert-hash e32b8c6ade80b75b59a4d45735ab6790633700a8d9052c51fc72e13c206a48c5
[preflight] Running pre-flight checks
error execution phase preflight: couldn't validate the identity of the API Server: invalid public key hash, expected "format:value"
```

discovery-hash格式错误: => sha256:e32b8c6ade80b75b59a4d45735ab6790633700a8d9052c51fc72e13c206a48c5

错误3：

前置检测报cri错误无法连接`unix:///var/run/docker.sock`，这是docker启动失败了，检测docker相关配置文件是否正确，`/etc/docker/daemon.json`, `/etc/containerd/config.toml`

错误4：

```
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR CRI]: container runtime is not running: output: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
, error: exit status 1
	[ERROR Service-Docker]: docker service is not active, please run 'systemctl start docker.service'
	[ERROR IsDockerSystemdCheck]: cannot execute 'docker info': exit status 1
	[ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
	[ERROR SystemVerification]: failed to get docker info: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
```

启动crio失败，错误原因没有找到`/usr/bin/runc`

```
time="2019-05-23 21:10:16.395633725-04:00" level=fatal msg="invalid --runtime value "stat /usr/bin/runc: no such file or directory""
```  

`runc`应该是安装了的只是路径问题导致没找到，通过`which`查找

```
# which runc
/usr/sbin/runc
```

软链`runc`到`/usr/bin/runc`

```
# ln -s /usr/sbin/runc /usr/bin/runc
```

启动`crio`

```
# systemctl restart crio
```