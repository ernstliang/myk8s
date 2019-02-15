#!/bin/bash
# 配置etcd配置文件和证书
# 注：需要先修改server-csr.json里的host为集群的ip

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server

# 拷贝证书文件到/k8s/etcd/cfg目录
cp -f ca*pem server*pem /k8s/etcd/ssl