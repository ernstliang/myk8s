# Service Mesh

## 演进
1. 控制逻辑与业务逻辑耦合    
	缺点：
	- 业务逻辑凌乱，代码难维护
2. 公共库    
	优点：
	- 解耦
	- 消除重复  
	缺点：
	- 成本（人力-学习、时间-部署维护）
	- 语言绑定
	- 有侵入
3. 代理
	优点：
	- 思路正确  
	缺点：
	- 功能简陋
4. sidecar 2013~2015
5. Service Mesh 2016~2017，sidecar的网络拓扑
6. Service Mesh V2 2018~至今

## 定义
本质：基础设施层
功能：请求分发
产品形态：一组网络代理
特点：应用透明

所谓ServiceMesh就是一个用来进行请求转发的基础设施层，它通常是以sidecar的形式部署，并且对应用透明

ServiceMesh是sidecar的网络拓扑模式

## 产品形态
1. 数据平面（所有sidecar组合）
2. 控制平面（管理控制sidecar网络）

## 主要功能
1. 流量控制  
	- 路由（灰度发布、蓝绿部署、AB测试）
	- 流量转移
	- 弹性（超时、重试、熔断）
	- 测试（故障注入、流量镜像）
2. 策略  
	- 流量限制
	- 黑白名单
3. 网络安全  
	- 授权及身份认证
4. 可观测性
	- 指标收集和展示
	- 日志收集
	- 分布式追踪

## ServiceMesh与Kubernetes的关系
Kubernetes
	- 目标：解决容器编排与调度的问题
	- 本质上是管理应用生命周期（调度器）
	- 给予ServiceMesh支持和帮助
ServiceMesh
	- 目标：解决服务间网络通讯的问题
	- 本质上是管理服务通讯（sidecar代理）
	- 是对Kubernetes网络功能方面的扩展和延伸

## ServiceMesh与API网关的异同
- 功能有重叠，但角色不同
	- API网关（负载均衡、服务发现、流量控制）
- ServiceMesh在应用内部，API网关在应用之上（边界）

## ServiceMesh技术标准
- UDPA统一的数据平面API（Universal Data Planel API）
- SMI(Service Mesh Interface) 控制平面