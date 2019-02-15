#!/bin/bash

set -x

TOKEN=`cat token.tmp`
# echo "$TOKEN"

# TOKEN=`head -c 16 /dev/urandom | od -An -t x | tr -d ' '`
# echo $TOKEN

# FLANNEL_TGZ=flannel-v0.10.0-linux-amd64.tar.gz

# if [ ! -e "$FLANNEL_TGZ" ];then
#     echo "$FLANNEL_TGZ missing"
#     exit 1
# fi

# echo "success"