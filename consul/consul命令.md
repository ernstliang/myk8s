# consul命令

## 启动k8s consul集群
  
创建pvc/pv本地盘符映射关系

```
$ kubectl create -f consul_pvc.yaml
```

创建consul的statefulset

```
$ kubectl create -f consul_statefulset.yaml
```

创建consul的服务

```
$ kubectl create -f consul_service.yaml
```

## 导出k8s consul的端口到前台

```
$ kubectl port-forward consul-0 8500:8500
Or
$ kubectl port-forward service/consul 8500:8500
```

可以查看本地命令，并且go-micro也可以注册微服务发现

```
$ consul catalog services/node
```