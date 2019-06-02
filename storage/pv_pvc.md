# PV PVC StorageClass

TODO：<br>
1. rook ceph集群搭建<br>
2. Dynamic Provisioning练习

## 概念
PVC: PersistentVolumeClaim 描述的是Pod希望使用的持久化存储的属性，比如：Volume的存储大小、可读写权限等。

PV: PersistentVolume 描述持久化存储数据卷，比如：一个NFS的挂载目录或者是ceph

PVC和PV的设计跟“面向对象”的思想完全一致

PVC可以理解为持久化存储的“接口”，它提供了某种持久化存储的描述，但不提供具体的实现。
PV则可以理解为持久化存储的实现。

kubernetes中有一个专门处理持久化存储的控制器：Volume Controller

Volume Controller又维护着多个控制循环，其中有一个专门处理PV和PVC绑定的循环：PersistentVolumeController

而所谓将一个PV和PVC进行“绑定”，其实就是将这个PV对象的名字填写在了PVC对象的spec.volumeName字段上。从而使kubernetes通过PVC能找到对应的PV

容器的Volume: 就是将一个宿主机的目录，跟容器里的目录绑定挂载在一起(bind mount)

持久化的Volume: 指宿主机上目录具有“持久性”，即这个目录里的内容，既不会因为容器的删除而被清理，也不会跟当前宿主机绑定，这样当这个容器被重新调度到其他节点后任然能够挂载并访问到这个Volume里的内容。

所以hostpath、emptyDir都不是持久化Volume，emptyDir会随着Pod的删除而被清理，hostpath被绑定在某个节点上。

kubernetes处理“持久化”宿主机目录的过程可以形象的称为“两阶段处理”

- 一阶段：Attach，将远程磁盘挂载到宿主机，可用参数nodeName(宿主机名)，AttachDetachController
- 二阶段：Mount，将磁盘格式化并挂载到Volume宿主机的目录，可用参数dir(Volume宿主机的目录)，VolumeManagerReconciler

准备好“持久化”宿主机目录后就可以通过CRI里的Mounts参数将Volume的目录传递给docker，为Pod挂载这个持久化目录了，相当于执行下面的docker命令

```
docker run -v /var/lib/kubelet/pods/<Pod 的 ID>/volumes/kubernetes.io~<Volume 类型 >/<Volume 名字 >:/< 容器内的目标目录 > 我的镜像 ...
```

控制循环：

- kube-controller-manager: kubernetes的主控制，位与master节点
- Kubelet Sync Loop：各节点上的kubelet主控制循环
- Volume Controller：专门处理持久化存储的控制器，属于kube-controller-manager
- PersistentVolumeController：专门处理PV和PVC绑定的循环，由Volume Controller维护
- AttachDetachController：处理kubernetes持久化宿主机目录的Attach阶段，由Volume Controller维护，
- VolumeManagerReconciler：处理kubernetes持久化宿主机目录的Mount阶段，需要在Pod所处的宿主机上，所以是kubelet组件的一部分，但独立于kubelet主循环，是一个单独的goroutine。

volume的处理和kubelet主循环解耦，是基于kubelet的一个主要设计原则，就是它的主控制循环绝对不可以被block。

kubernetes有两套创建PV的机制：static provisioning 和 dynamic provisioning

dynamic provisioning机制依赖于StorageClass对象，StorageClass的作用就是创建PV的模板。主要包括：

- PV的属性，比如存储类型、volume的大小等
- 创建需要用到的存储插件，比如ceph等

kubernetes根据用户提供的PVC找到一个对应的StorageClass，然后用这个StorageClass声明的存储插件创建需要的PV。

kubernetes只会将StorageClass相同的PVC和PV进行绑定

StorageClass并不是为dynamic provisioning设计的，static provisioning也一样适用，用户可以手动指定StorageClass来控制PVC和PV的绑定

Local Persistent Volume: 针对那些希望直接使用宿主机上的本地磁盘目录，而不依赖于远程存储服务，来提供持久化存储的volume的应用而设计。使用本地磁盘目录尤其是SSD盘的好处就是它的读写性能会远大于远程存储

Local Persisten Volume的两个难点：

- 如何把本地磁盘抽象成PV
- 调度器如何保证Pod始终能被正确的调度到它所请求的LocalPersistentVolume所在的节点上

首先，绝对不应该把宿主机上的目录当做PV使用，因为这种本地目录的存储行为完全不可控，应用可能将磁盘写满从而导致宿主机宕机，所以Local Persistent Volume对应的存储介质一定是一块额外挂载在宿主机上的磁盘或块设备。即一个PV一块盘

其次，相比于正常的PV，一旦这些节点宕机且不能恢复时，Local Persistent Volume的数据就丢失，这就要求使用Local PV的应用必须具备数据备份和恢复的能力。

对于正常的PV，kubernetes的调度是先将Pod调度到某个节点上，然后再通过“两阶段处理”来“持久化”这个节点上的Volume目录，进而完成Volume目录与容器的绑定。可对于Local PV来说，节点上可用的磁盘必须是运维人员事先准备好的，而且它们的挂载情况可以完全不同，同时不是所有节点都配置了Local PV，所以这种情况下需要先根据Local PV的信息来调度Pod，这就是在调度时考虑Volume分布，它需要用到Local PV里一个非常重要的特性：延迟绑定

延迟绑定：将“持久化”的Volume“绑定”延迟到Pod调度的时候，可以通过设置StorageClass的volumeBindingMode=WaitFirstConsumer生效

## CSI（Container Storage Interface）

kubernetes => External Components => CSI plugin

CSI插件体系的设计思想，就是把Provision阶段，以及kubernetes里的一部分存储管理功能，从主干代码中剥离出来，做成了几个单独的组件。这些组件通过Watch API监听kubernetes里与存储相关的事件变化，比如PVC的创建，来执行具体的存储管理动作。

前面的“两阶段处理”Attach和Mount就可以通过CSI插件来完成，这套外部组件(External Components)主要包括3部分：

- Driver Register，负责将插件注册到kubelet里面
- External Provisioner，负责的正是Provision阶段
- External Attacher，负责的正是Attach阶段

External Components虽然是外部组件，但依然是由kubernetes社区开发和维护的

CSI插件：一个插件只有一个二进制文件，但它会以gRPC的方式对外提供三个服务，CSI Identity、CSI Controller和CSI Node


## 附录

Bind Mount：mount --bind 是将一个目录（或文件）中的内容挂载到另一个目录（或文件）上，用法是：

```
# mount --bind olddir newdir
```

