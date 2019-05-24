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

# 配置非root用户的docker权限
usermod -aG docker ${USER}

