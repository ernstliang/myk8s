#!/bin/bash
# 关闭防火墙和SELINUX
# 需要在root权限下运行

# 停止并关闭防火墙
systemctl stop firewalld && systemctl disable firewalld

# 临时关闭SELINUX
setenforce 0

# 永久关闭SELINUX
# vi /etc/selinux/config
# 修改 SELINUX=disabled
