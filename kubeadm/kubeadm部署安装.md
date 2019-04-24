# kubeadm部署安装kubernetes

## 安装kubeadm



## 生成kubeadm默认配置文件

```
$ kubeadm config print-default > kubeadm.yaml
```

需要修改kubeadm.yaml配置

```
localAPIEndpoint:
  advertiseAddress: 192.168.0.100
  bindPort: 6443
```

```
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
```

使用flannel网络插件就配置`podSubnet`为`10.244.0.0/16`网段

## 