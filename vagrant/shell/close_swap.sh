#!/bin/bash
# 关闭swap，k8s安装需要

#临时关闭swap
swapoff -a && sysctl -w vm.swappiness=0

#永久关闭swap
# vi /etc/fstab
# 注释 #/dev/mapper/cl-swap     swap                    swap    defaults        0 0