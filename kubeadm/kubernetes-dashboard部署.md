# kubernetes-dashboard部署

## 创建dashboard的用户


### 取token

```
kubectl describe secret/$(kubectl get secret -n kube-system | grep admin | awk '{print $1}') -n kube-system
```