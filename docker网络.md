# docker网络

## Veth Pair设备

查看容器在host上对应的Veth Pair设备

宿主机上执行

```
$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 94:c6:91:1f:6b:a3 brd ff:ff:ff:ff:ff:ff
3: wlo2: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 7c:76:35:5d:32:d9 brd ff:ff:ff:ff:ff:ff
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default
    link/ether 02:42:27:63:b3:41 brd ff:ff:ff:ff:ff:ff
5: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/ether 1a:3b:9e:55:26:ae brd ff:ff:ff:ff:ff:ff
6: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 6e:26:09:21:21:64 brd ff:ff:ff:ff:ff:ff
15: veth51938806@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether ce:99:0b:de:1e:d9 brd ff:ff:ff:ff:ff:ff link-netnsid 0
16: vethb0661c60@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether 1e:2f:ec:e7:a8:7b brd ff:ff:ff:ff:ff:ff link-netnsid 1
29: vethb61a87b5@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether 9e:a6:f7:4c:db:23 brd ff:ff:ff:ff:ff:ff link-netnsid 3
30: veth25aa5ec7@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether 36:81:a3:f1:33:0d brd ff:ff:ff:ff:ff:ff link-netnsid 4
31: vetha9800876@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether 5a:6d:6c:28:b2:b3 brd ff:ff:ff:ff:ff:ff link-netnsid 5
34: vethf54f7758@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether 86:c0:70:11:6f:48 brd ff:ff:ff:ff:ff:ff link-netnsid 2
```

容器内执行

```
$ docker exec -it e20805147667 bash -c 'cat /sys/class/net/eth0/iflink'
31
```

这里iflink里的`31`就对应的宿主机`ip link`输出的编号`31`的vetha9800876