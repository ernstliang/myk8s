#!/bin/bash
# 安装k8s

CUR=`pwd`
echo "CUR=$CUR"

# 创建安装目录
mkdir /k8s/etcd/{bin,cfg,ssl} -p
mkdir /k8s/kubernetes/{bin,cfg,ssl} -p

# 安装cfssl
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64

mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo

# 配置etcd的配置文件
cd $CUR/etcd/ca/
./etcd_ca.sh

# 配置k8s的配置文件
cd $CUR/k8s/ca/
./k8s_ca.sh

cd $CUR