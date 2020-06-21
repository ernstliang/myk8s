# Istio安装部署
#istio #k8s

- Istio 1.5支持的kubernetes版本
	- 1.14 ~ 1.16
- Kubernetes环境
	- 本地（Docker Desktop、Minikube、VM），方便
	- 云平台，成本高
	- 在线Playground（katacoda、play-with-k8s.com），适合体验

## 下载Istio

- 下载
  - `curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.5.5 sh -`
  - 最新版为1.6.3（2020-06-21）
- 把istioctl加入环境变量
  - 配置安装目录`mv istio-1.5.5 /opt`
  - 进入下载目录`cd /opt/istio-1.5.5`
  - 修改`vim ~/.bashrc`，`export PATH=/opt/istio-1.5.5/bin:$PATH`,`source ~/.bashrc`
  - 查看istio是否配置完成`istioctl version`

## 安装Istio

- 安装
  - 1.5.x  `istioctl manifest apply --set profile=demo`
  - 1.6.x `istioctl install --set profile=demo`
- 查看istio的资源
  - 查看crd `kubectl get crd |grep istio`
  - 查看api资源 `kubectl api-resources| grep istio`
- 通过kubectl apply -f 安装
  - `$ istioctl manifest generate > ${HOME}/generated-manifest.yaml`
  - `$ kubectl apply -f ${HOME}/generated-manifest.yaml`
- 验证安装
  - `$ istioctl verify-install -f ${HOME}/generated-manifest.yaml`
  - 官方dashboard查看 `istioctl dashboard kiali`

