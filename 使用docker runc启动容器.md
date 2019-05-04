# 使用docker runc启动容器
模拟docker daemon启动容器的过程，了解容器的启动

## 创建容器标准包
这部分由containerd的bundle模块实现，将docker进行转换成容器标准包

```
$ mkdir my_container
$ cd my_container
$ mkdir roots
$ docker export $(docker create busybox) | tar -C rootfs -vxf - 
```

通过上述命令将busybox镜像解压缩到指定的rootfs目录中

## 创建容器配置文件

```
$ runc spec
$ ls
config.json  rootfs
```

此时会生成一个名为config.json的配置文件，该文件和Docker容器的配置文件类似，主要包含容器挂载信息、平台信息、进程信息等容器启动依赖的所有数据。

## 通过runc启动容器

```
# runc run busybox2
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 sh
    6 root      0:00 ps
```

注: runc需root权限运行

宿主机上运行ps

```
# ps -ef | grep busybox
root      7061 23893  1 15:45 pts/0    00:00:00 runc run busybox2
```