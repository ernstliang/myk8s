# docker

- 容器技术的兴起源于PaaS技术的普及
- Docker项目通过"容器镜像"，解决了应用打包这个根本性难题

## docker容器的本质

容器其实是一种沙盒技术。顾名思义，沙盒就是能像集装箱一样，把应用封装起来，使应用与应用之间有边界相互隔离互不干扰，而装进集装箱里的应用，也能够被方便的搬来搬去。

**容器技术的核心功能，就是通过约束和修改进程的动态表现，从而为其创造出一个"边界"。**

Linux下的docker容器，使用Namespace技术修改进程视图，使用Cgroups技术制造约束条件。

- Namespace是Linux内核用来隔离内核资源的方式。通过Namespace可以让一些进程只能看到与自己相关的一部分资源，而另外一些进程只能看到与它们自己相关的资源，两拨进程根本就感觉不到对方的存在。
- Cgroups是Control Group的缩写，是Linux内核提供的一种可以限制、记录、隔离进程组(process group)、所使用的物理资源(如cpu memory i/o等)的机制。

下面通过一个简单的例子来分析

首先，运行一个简单的容器:

```
$ docker run -it busybox /bin/sh
/ #
```

再运行`ps`命令查看进程

```
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 /bin/sh
    6 root      0:00 ps
```

可以看到，docker里最先执行的/bin/sh是容器内部的第1号进程，以及刚刚执行的ps指令，两个进程已经被docker隔离在了一个与宿主机完全独立的世界当中。

而其实这个/bin/sh却是运行在宿主机当中

```
$ ps -ef 
...
root      4167     1  3 4月21 ?       09:57:57 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
root      4166     1  0 4月21 ?       00:31:31 /usr/bin/containerd
root       672  4166  0 21:35 ?        00:00:00 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/5a6ad26e9b2daf29c4259bfb924d9cbb95bb
root       690   672  0 21:35 pts/0    00:00:00 /bin/sh
...
```

- pid=690 运行的/bin/sh
- pid=672 containerd-shim是一个真实运行的容器的真实垫片载体，每启动一个容器都会起一个新的containerd-shim
- pid=4166 containerd是容器技术标准化之后的产物，为了能够兼容OCI标准，将容器运行时及其管理功能从Docker Daemon剥离。向上为Docker Daemon提供gRPC接口，使Daemon屏蔽下面的结构变化，确保向下兼容。向下通过containerd-shim结合runc，使得引擎可以独立升级，避免之前Docker Daemon升级会导致所有容器不可用的问题
- pid=4167 Docker Daemon从Docker 1.11版本开始已经和Docker Client分离，独立成一个二进制程序，启动方式`dockerd`。其基本功能和定位没有变化，和一般的CS架构系统一样，守护进程负责和Docker Client交互，并管理Docker镜像、容器。

从上面两种进程的对比可以看出，docker其实就是对被隔离的应用的进程空间做了手脚，使得这些进程只能看到重新计算过的进程编号，如/bin/sh pid=1。可实际上在宿主机操作系统里，还是原来的进程编号 pid=690

这种技术就是Linux里的Namespace机制。它可以通过Linux系统中创建进程的系统调用clone()的一个可选参数设置。

```
int pid = clone(main_function, stack_size, SIGCHLD, NULL);
```

当我们在clone中指定CLONE_NEWPID参数时，

```
int pid = clone(main_function, stack_size, CLONE_NEWPID | SIGCHLD, NULL);
```

新创建的进程将会"看到"一个全新的进程空间，在这个进程空间里，它的pid是1。然而在宿主机的进程空间中，它的pid还是真实的数值，比如：pid=690。

当然除了上面提到的PID Namespace，Linux系统中还提供了Mount、UTS、IPC、NetWork、User等Namespace，用来对进程的上下文进行隔离封装。

**这就是Linux容器最基本的实现原理。**

所谓Docker容器就是在创建容器进程时，指定了这个进程所需要启动的一组Namespace参数。这样，容器就只能看到当前Namespace所限定的资源、文件、设备、状态、或者配置。而对宿主机及其他不相干的程序，它就完全看不到。

所以:

***容器从本质上来说只是一个特殊的进程***

### 限制

上面讲了容器通过设置Namespace对应用进行了"隔离"，但这个"隔离"并不像虚拟机一样彻底。

首先，容器是运行在宿主机上的一个特殊进程，那么多个容器之间使用的就还是同一个宿主机的操作系统内核。

尽管你可以在容器里通过Mount Namespace单独挂载其他不同版本的操作系统文件，比如CentOS或者Ubuntu，但这并不能改变共享宿主机内核的事实，这就意味着，如果要在Windows宿主机上运行Linux容器，或者在低版本的Linux宿主机上运行高版本的Linux容器，都是行不通的。

其次，在Linux内核中，有很多资源和对象是不能被Namespace化的，最典型的例子就是：时间

这就意味着，如果你的容器中的程序使用settimeofday(2)系统调用修改了时间，整个宿主机的时间都会被随之修改，这显然不符合用户的预期。相比于在虚拟机里面可以随便折腾的自由度，在容器里部署应用的时候，“什么能做，什么不能做”，就是用户必须考虑的一个问题。

容器作为一个进程与宿主机上其他的进程是共享宿主机的资源的（比如CPU、内存等），这就意味着，当前容器的资源随时可能被其他进程占用，同时当前容器也可以吃光所有宿主机的资源。这些情况，显然不是一个"沙盒"应该表现出来的合理行为。

因此需要使用Linux Cgroups(Linux内核中用来为进程设置资源限制的一个重要功能)来限制一个进程组能够使用的资源上限，包括CPU、内存、磁盘、网络带宽等等。

## 参考资料
- [极客空间-深入剖析Kubernetes](https://time.geekbang.org/column/article/14642)
- [CGroup介绍](https://www.cnblogs.com/caoxiaojian/p/5633430.html)
- [Namespace介绍](http://www.cnblogs.com/sparkdev/p/9365405.html)
- [docker、containerd、runc、docker-shm](https://www.jianshu.com/p/52c0f12b0294)
