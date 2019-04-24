# dashboard

Github: [dashboard](https://github.com/kubernetes/dashboard)

[Create sample user](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user)

## 创建dashboard

```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```

## 启动

```
$ kubectl proxy
```

## 获取dashboard登录token

```
$ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```