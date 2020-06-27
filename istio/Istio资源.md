# Istio资源

## 动态路由

- 虚拟服务（Virtual Service）
  - 定义路由规则
  - 描述满足条件的请求去哪
- 目标规则（Destination Rule）
  - 定义子集、策略
  - 描述到达目标的请求如何处理



## Virtual Service和Destination Rule的应用场景

- 按服务版本路由
- 按比例切分流量
- 根据匹配规则进行路由
- 定义各种策略（负载均衡、连接池等）

VirtualService hosts的官方说明：

The destination hosts to which traffic is being sent. Could be a DNS name with wildcard prefix or an IP address.

DestinationRule host的说明：

The name of a service from the service registry. Service names are looked up from the platform’s service registry (e.g., Kubernetes services, Consul services, etc.)



样式说明：

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: wordpress-vs # 虚拟服务名
  namespace: default
spec:
  hosts:
  - wordpress-dr # 目标规则名
  http:
  - route:
    - destination:
        host: wordpress-svc # 服务发现中注册的服务名，如k8s中的服务名
        subset: v1 # 目标规则中定义的子集名
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: wordpress-dr # 目标规则名
  namespace: default
spec:
  host: wordpress-svc # 服务发现中注册的服务名，如k8s中的服务名
  subsets:
  - labels:
      version: v1 # 子集版本
    name: v1 # 子集名
```





## 网关（gateway）

> 网关只定义入口点，不定义路由，路由需要通过virtual service

- 一个运行在网格边缘的负载均衡器
- 接收外部请求，转发给网格内的服务（控制流量）
- 配置对外端口、协议与内部服务的映射关系

### 网关的应用场景

- 暴露网格内服务给外界访问
- 访问安全（HTTPS、mTLS等）
- 统一应用入口、API聚合

样式说明:

```yaml
# 
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: wordpress-gateway # 网关名
spec:
  selector:
    istio: ingressgateway # 选择istio的ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "wordpress.xxx.com"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: wordpress-gateway # 虚拟服务名
spec:
  hosts:
  - "wordpress.xxx.com"
  gateways:
  - wordpress-gateway # 指定网关
  http:
  - match: # 设置匹配规则
    - uri:
        prefix: /
    route:
    - destination:
        host: wordpress-svc # 服务发现中注册的服务名，如k8s中的服务名
        subset: v1 # 目标规则中定义的子集名
```



## 服务入口（Service Entry）

- 把外部服务添加到网格内
- 管理到外部服务的请求
- 扩展网格



### 关闭出流量可访问权限（outboundTrafficPolicy = REGISTRY_ONLY )

mode: ALLOW_ANY => mode: REGISTRY_ONLY

```shell
kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
```



测试：

```shell
# 安装测试程序
kubectl apply -f samples/sleep/sleep.yaml
# 测试请求
kubectl exec -it sleep-666475687f-sm8zg -c sleep curl http://httpbin.org/ip
error code: 1020
# 关闭出流量访问
kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
# 再次测试请求
kubectl exec -it sleep-666475687f-sm8zg -c sleep curl http://httpbin.org/ip
无返回
# 注册
```

