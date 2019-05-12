# kubernetes

> 容器本身没有价值，有价值的是"容器编排"

## pod

### 启动一个一次性的pod

```
$ kubectl run -i --tty --image busybox dns-test --restart=Never --rm /bin/sh 
```

### PodPreset


创建PodPreset提示错误:

```
$ kubectl apply -f preset.yaml
error: unable to recognize "preset.yaml": no matches for kind "PodPreset" in version "settings.k8s.io/v1alpha1"
```

开启PodPreset:

```
在使用PodPreset对象时,发现并未生效,最终才知道是因为当初安装时未启用 Pod Preset.然后参考[https://kubernetes.io/docs/concepts/workloads/pods/podpreset/#enable-pod-preset] 
修改 [/etc/kubernetes/manifests/kube-apiserver.yaml] 中的spec.containers.command: 
修改原[ - --runtime-config=api/all=true]为[- --runtime-config=api/all=true,settings.k8s.io/v1alpha1=true], 
新加一行[- --enable-admission-plugins=PodPreset] 
可以等自动生效也可以强制重启[systemctl restart kubelet]. 
然后再重新创建,就可以在pod中看见spec.containers.env.name:DB_PORT等信息了
```