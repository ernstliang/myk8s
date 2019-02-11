# docker for mac替换默认虚拟机
参考链接:
[https://blog.csdn.net/Mr0o0rM/article/details/80683115](https://blog.csdn.net/Mr0o0rM/article/details/80683115)

## 替换默认虚拟机的原因
docker在OSX的实现方式，是首先创建一个linux的虚拟机，在将docker放入到虚拟机中实现，而对于linux虚拟机，与OSX之间的通信，目前版本采用/var/run/docker.sock这种socket文件来通信，在OSX宿机中自然ping不通docker容器。

## 使用docker-machine创建默认linux虚拟机
下载boot2docker.iso耗时会比较长，请耐心等待

```
$ docker-machine create vmdocker
Creating CA: /Users/xliang/.docker/machine/certs/ca.pem
Creating client certificate: /Users/xliang/.docker/machine/certs/cert.pem
Running pre-create checks...
(vmdocker) Image cache directory does not exist, creating it at /Users/xliang/.docker/machine/cache...
(vmdocker) No default Boot2Docker ISO found locally, downloading the latest release...
(vmdocker) Latest release for github.com/boot2docker/boot2docker is v18.09.1
(vmdocker) Downloading /Users/xliang/.docker/machine/cache/boot2docker.iso from https://github.com/boot2docker/boot2docker/releases/download/v18.09.1/boot2docker.iso...
(vmdocker) 0%....10%....20%....30%....40%....50%....60%....70%....80%....90%....100%
Creating machine...
(vmdocker) Copying /Users/xliang/.docker/machine/cache/boot2docker.iso to /Users/xliang/.docker/machine/machines/vmdocker/boot2docker.iso...
(vmdocker) Creating VirtualBox VM...
(vmdocker) Creating SSH key...
(vmdocker) Starting the VM...
(vmdocker) Check network to re-create if needed...
(vmdocker) Found a new host-only adapter: "vboxnet1"
(vmdocker) Waiting for an IP...
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with boot2docker...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env vmdocker
```

### 查看默认虚拟机

```
$ docker-machine ls
NAME       ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER     ERRORS
vmdocker   -        virtualbox   Running   tcp://192.168.99.100:2376           v18.09.1
```

## 切换docker环境

```
$ eval $(docker-machine env vmdocker)
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/xliang/.docker/machine/machines/vmdocker"
export DOCKER_MACHINE_NAME="vmdocker"
# Run this command to configure your shell:
# eval $(docker-machine env vmdocker)
```

### 查看docker-machine的ip

```
$ docker-machine ip vmdocker
192.168.99.100
```

## 路由
执行route命令，把192.168.99.100作为网关，将docker容器的ip段，路由到此IP上

```
$ sudo route -n add -net 172.17.0.0/16 192.168.99.100
Password:
add net 172.17.0.0: gateway 192.168.99.100
```

