#!/bin/bash -v
# etcd部署

# 解压etcd二进制安装包
if [ ! -e "etcd-v3.3.10-linux-amd64.tar.gz" ];then
    echo "etcd-v3.3.10-linux-amd64.tar.gz missing!!!"
    exit 1
fi

# 解压etcd二进制包
tar -zxf etcd-v3.3.10-linux-amd64.tar.gz

# 拷贝etcd程序
cp -f etcd-v3.3.10-linux-amd64/etcd etcd-v3.3.10-linux-amd64/etcdctl /k8s/etcd/bin/

# 部署etcd的systemd unit文件
cp -f etcd.service /usr/lib/systemd/system

# 启动etcd服务
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd