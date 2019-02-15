#!/bin/bash
#安装docker
#需要root权限运行

# 安装yum-config-manager
yum -y install yum-utils

# 配置docker的源
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 查看docker源版本信息
yum list docker-ce --showduplicates | sort -r

# 安装docker
yum install docker-ce -y

# 启动docker并配置开机启动
systemctl start docker && systemctl enable docker

# 设置docker参数
echo "net.ipv4.ip_forward = 1" > k8s.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> k8s.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> k8s.conf

# 移动配置文件
mv k8s.conf /etc/sysctl.d/

# 加载配置文件
sysctl -p /etc/sysctl.d/k8s.conf