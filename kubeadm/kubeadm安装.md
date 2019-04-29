# kubeadm安装

```
NAME                           READY   STATUS             RESTARTS   AGE
coredns-fb8b8dccf-kck2j        0/1     CrashLoopBackOff   584        2d1h
coredns-fb8b8dccf-lzn84        0/1     CrashLoopBackOff   583        2d1h
etcd-nuc7                      1/1     Running            0          2d9h
kube-apiserver-nuc7            1/1     Running            0          2d9h
kube-controller-manager-nuc7   1/1     Running            1          2d9h
kube-flannel-ds-amd64-rrvr5    1/1     Running            0          2d9h
kube-proxy-gbkhb               1/1     Running            0          2d9h
kube-scheduler-nuc7            1/1     Running            1          2d9h
```


### 加入集群

```
kubeadm join 192.168.0.100:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:9d167516c469a4da2346609173d1a09ba0e048f787e7fe8159244f6371a784d6
```

#### token过期

重新创建token

```
$ kubeadm token create
j9aeuu.ycgbb1z6cq6a2pb6
```

列出token列表

```
$ kubeadm token list
TOKEN                     TTL       EXPIRES                USAGES                   DESCRIPTION   EXTRA GROUPS
j9aeuu.ycgbb1z6cq6a2pb6   23h       2019-04-28T07:34:27Z   authentication,signing   <none>        system:bootstrappers:kubeadm:default-node-token
```

获取ca证书sha256编码hash值

```
$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```



