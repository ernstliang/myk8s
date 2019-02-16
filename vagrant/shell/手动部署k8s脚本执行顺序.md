# 手动部署k8s脚本执行顺序

## 1.基础环境配置

- 关闭防火墙及SELINUX简单处理 stop_firewalld_selinux.sh，永久关闭SELINUX需手动修改
- 关闭swap close_swap.sh，永久关闭需要手动修改

## 2.下载k8s组件及docker安装

- 下载k8s组件1.13.1版本 download_k8s_1.13.1.sh
- 安装docker install_docker.sh

## 3.设置master节点到node节点ssh passwdless

## 4.k8s安装目录创建及etcd证书和k8s证书配置
1. 下载安装cfssl
2. 进入etcd/ca目录etcd_ca.sh生成证书
3. 进入k8s/ca目录k8s_ca.sh生成证书

## 5.搭建etcd集群
1. 部署master节点etcd_deployment.sh
2. master上配置node节点的etcd环境etcd_dispatch.sh
3. etcd需要同时启动两台才能成功

## 6.部署flannel
1. 修改docker.service启动参数配置指定子网络网段
2. master安装flannel install_flannel.sh
3. node节点安装flannel dispatch_flannel.sh

## 7.部署k8s组件
1. 安装master节点 install_master.sh
2. 生成bootstrap.kubeconfig和kube-proxy.kubeconfig environment.sh
3. 安装node节点 install_node.sh

