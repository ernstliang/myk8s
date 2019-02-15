#!/bin/bash
# k8s证书生成

# 生成k8s ca证书
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

# 生成api server证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server

# 生成k8s proxy证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

# 拷贝认证证书文件
cp *pem /k8s/kubernetes/ssl/