# vagrant操作
## vagrant安装
- 下载最新版vagrant: [官网](https://www.vagrantup.com)
- 安装virtualbox: [官网](https://www.virtualbox.org/)

## 创建vagrant虚拟机
使用Vagrantfile文件

```
$ vagrant up
```

### 依赖的box下载
通过vagrant通常会比较慢，可以通过离线的方式(迅雷等其他下载工具)先下载box文件，添加到vagrant中<br>
如centos7.3的box下载地址:[https://vagrantcloud.com/bento/boxes/centos-7.3/versions/201708.22.0/providers/virtualbox.box](https://vagrantcloud.com/bento/boxes/centos-7.3/versions/201708.22.0/providers/virtualbox.box
)<br>

添加到vagrant

```
$ vagrant box add bento/centos-7.3 virtualbox.box
```

### 查看box列表

```
$ vagrant box list
```

### 查看vagrant虚拟机状态

```
$ vagrant global-status
```

### 登录到vagrant创建的虚拟机
登录使用vagrant ssh命令，多个虚拟机的情况下需要指定虚拟机如下:<br>

```
$ vagrant ssh 911734d
```

注：911734d是虚拟机的id可以通过`vagrant global-status`查看<br>

vagrant的centos镜像<br>
初始密码账户可能是：

| 账户 | 密码 |
| --- | --- |
| vagrant | vagrant |
| root | vagrant |

## 停止虚拟机

```
$ vagrant halt
```

## 删除虚拟机

```
$ vagrant destroy
```

注：vagrant destroy只会删除虚拟机本身，也即你在Virtualbox将看不到该虚拟机，但是不会删除该虚拟机所使用的box。