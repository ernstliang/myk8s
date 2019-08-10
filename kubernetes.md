# kubernetes

> 容器本身没有价值，有价值的是"容器编排"

## pod

### Lable

#### 查看label

```
# Show nodes labels
$ kubectl get nodes --show-labels

# Show pods labels
$ kubectl get pods --show-labels
```

#### 设置label

```
# Update node 'n1' with the label 'disktype' and the value 'ssd'
	kubectl label node n1 disktype=ssd

# Update pod 'foo' with the label 'unhealthy' and the value 'true'.
  kubectl label pods foo unhealthy=true

# Update pod 'foo' with the label 'status' and the value 'unhealthy', overwriting any existing value.
  kubectl label --overwrite pods foo status=unhealthy

# Update all pods in the namespace
  kubectl label pods --all status=unhealthy

# Update a pod identified by the type and name in "pod.json"
  kubectl label -f pod.json status=unhealthy

# Update pod 'foo' only if the resource is unchanged from version 1.
  kubectl label pods foo status=unhealthy --resource-version=1

# Update pod 'foo' by removing a label named 'bar' if it exists.
  # Does not require the --overwrite flag.
  kubectl label pods foo bar-
```

给'node-nuc7'打上标签'disktype'='ssd'

```
$ kubectl label node node-nuc7 disktype=ssd
```

Use 'nodeSelector' label ssd

```
...
spec:
  nodeSelector:
    disktype: ssd
...
```

### 启动一个一次性的pod

```
$ kubectl run -i --tty --image busybox dns-test --restart=Never --rm /bin/sh 
```

### 查看pod的yaml配置

```
$ kubectl get pod foo -o yaml
```

### Use 'hostAliases' set pod's host

```
...
spec:
  hostAliases:
    - ip: "10.1.1.12"
      hostnames:
      - "yt.remote"
      - "hz.molo.com"
...
```

### Use 'shareProcessNamespace' 共享pod里容器的PID Namespace

```
...
spec:
  shareProcessNamespace: true
...
```

### Secret

使用文件创建secret对象

```
cat password.txt
12345678

$ kubectl create secret generic pass --from-file=./password.txt
```

使用yaml文件创建secret对象

```
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  user: YWRtaW4K
  pass: aWZld3YzMnFjd3ZlCg==
```

```
data value 部分需要base64加密
$ echo "admin" | base64
YWRtaW4K
base64解密
$ echo "YWRtaW4K" | base64 -d
admin 

$ kubectl apply -f secret.yaml
```

> 通过挂载方式进入到容器里的secret，一旦对etcd里的数据被更新，volume里的数据也会被更新，这是由kubelet组件维护的



### PodPreset

创建PodPreset提示错误:

```
$ kubectl apply -f preset.yaml
error: unable to recognize "preset.yaml": no matches for kind "PodPreset" in version "settings.k8s.io/v1alpha1"
```

开启PodPreset:

```
在使用PodPreset对象时,发现并未生效,最终才知道是因为当初安装时未启用 Pod Preset.
然后参考[https://kubernetes.io/docs/concepts/workloads/pods/podpreset/#enable-pod-preset]
修改 [/etc/kubernetes/manifests/kube-apiserver.yaml]中的spec.containers.command: 
修改原[ - --runtime-config=api/all=true]
为[- --runtime-config=api/all=true,settings.k8s.io/v1alpha1=true], 
新加一行[- --enable-admission-plugins=PodPreset] 
可以等自动生效也可以强制重启[systemctl restart kubelet]. 
然后再重新创建,就可以在pod中看见spec.containers.env.name:DB_PORT等信息了
```

被PodPreset修改过的Pod对象yaml文件中会有标记

```
metadata:
  annotations:
	  ...
		podpreset.admission.kubernetes.io/podpreset-allow-database: "6706536"
```