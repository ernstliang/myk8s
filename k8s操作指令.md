# k8s操作指令

## Replication Controllers
### 创建RC
Kubernetes用 Replication Controllers 创建并管理复制的容器集合（实际上是复制的Pods）

```
$ kubectl create -f ./nginx-rc.yaml
replicationcontrollers/my-nginx
```

### 查看RC状态

```
$ kubectl get rc
NAME       DESIRED   CURRENT   READY   AGE
my-nginx   2         2         2       33m
```

### 删除RC

```
$ kubectl delete rc my-nginx
replicationcontrollers/my-nginx
```

### 扩展RC

```
# 减少
$ kubectl scale rc my-nginx --replicas=0
# 增加
$ kubectl scale rc my-nginx --replicas=2
```

创建RC之后创建Service需要来一套，重启RC创建的Pod

## 查看Labels
Kubernetes使用自定义的键值对（称为Labels）分类资源集合，例如pods和replicationcontroller

```
$ kubectl get pods -L app
NAME             READY   STATUS    RESTARTS   AGE   APP
my-nginx-4nn2b   1/1     Running   0          36m   nginx-x
my-nginx-gkzpk   1/1     Running   0          36m   nginx-x
nginx-1          1/1     Running   0          50m
```

### 查看RC的Label
pod模板带的label默认会被复制为replication controller的label。Kubernetes中所有的资源都支持labels

```
$ kubectl get rc my-nginx -L app
NAME       DESIRED   CURRENT   READY   AGE   APP
my-nginx   2         2         2       40m   nginx-x
```

pod模板的label会被用来创建 selector ，这个 selector 会匹配所有带这些labels的pods

```
$ kubectl get rc my-nginx -o template --template="{{.spec.selector}}"
map[app:nginx]
```

## 服务Service

