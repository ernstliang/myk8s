# Helloworld

- commit 1.1<br>
简单配置文件helloworld.yaml<br>
`command`是可选参数，会覆盖docker容器里的`Entrypoint`****

```
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
spec: # specification of the pod’s contents
  restartPolicy: Never
  containers:
    - name: hello
      image: "ubuntu:14.04"
      command: ["/bin/echo","hello","world"]
```


- commit 1.2<br>
拆分command和args

```
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
spec: # specification of the pod’s contents
  restartPolicy: Never
  containers:
    - name: hello
      image: "ubuntu:14.04"
      command: ["/bin/echo"]
      args: ["hello", "my world"]
```

## Pod

### 创建pod

```
#> kubectl create -f ./helloworld.yaml
pod/hello-world created
```

### 增加配置文件检查

```
#> kubectl create -f ./helloworld.yaml --validate
pod/hello-world created
```

### 查看pod

```
#> kubectl get pods
NAME          READY   STATUS      RESTARTS   AGE
hello-world   0/1     Completed   0          5s
```

### 删除pod

```
#> kubectl delete pod/hello-world
pod "hello-world" deleted
```