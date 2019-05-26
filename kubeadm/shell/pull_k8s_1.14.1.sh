#!/bin/bash

echo ""
echo "================================================================="
echo "Pull Kubernetes v1.14.1 Images from ccr.ccs.tencentyun.com ......"
echo "================================================================="
echo ""

#腾讯云的镜像仓库
TKE_REGISTRY=ccr.ccs.tencentyun.com/ernstliang
K8S_REGISTRY=k8s.gcr.io

# 镜像列表
# tke上的镜像名 => k8s.gcr.io下的镜像名
IMAGES=(
    'kube-apiserver:v1.14.1             kube-apiserver:v1.14.1'
    'kube-scheduler:v1.14.1             kube-scheduler:v1.14.1'
    'kube-proxy:v1.14.1                 kube-proxy:v1.14.1'
    'kube-controller-manager:v1.14.1    kube-controller-manager:v1.14.1'
    'pause:3.1                          pause:3.1'
    'kube-etcd:3.3.10                   etcd:3.3.10'
    'kube-coredns:1.3.1                 coredns:1.3.1'
)

# coredns镜像
# COREDNS_REGISTRY=coredns
# IMAGE_COREDNS=coredns:1.3.1

for image in "${IMAGES[@]}";do
    vs=($image)
    echo "${vs[@]}"

    # 删除已存在的镜像
    # docker rmi ${K8S_REGISTRY}/${vs[1]}

    # docker pull镜像
    docker pull ${TKE_REGISTRY}/${vs[0]}

    # docker tag重命名镜像
    docker tag ${TKE_REGISTRY}/${vs[0]} ${K8S_REGISTRY}/${vs[1]}

    # 删除tke的镜像tag
    docker rmi ${TKE_REGISTRY}/${vs[0]}
done

# 下载coredns镜像
# docker pull ${COREDNS_REGISTRY}/${IMAGE_COREDNS}
# docker tag ${COREDNS_REGISTRY}/${IMAGE_COREDNS} ${K8S_REGISTRY}/${IMAGE_COREDNS}
# docker rmi ${COREDNS_REGISTRY}/${IMAGE_COREDNS}

echo ""
echo "================================================================="
echo "Pull Kubernetes v1.14.1 Images FINISHED."
echo "================================================================="
echo ""