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

## Overlay Network

Node1:

```
$ ip route
default via 192.168.0.1 dev eno1 proto static metric 100
10.244.0.0/24 dev cni0 proto kernel scope link src 10.244.0.1
10.244.1.0/24 via 10.244.1.0 dev flannel.1 onlink
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1
192.168.0.0/24 dev eno1 proto kernel scope link src 192.168.0.100 metric 100
```

```
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.0.1     0.0.0.0         UG    100    0        0 eno1
10.244.0.0      0.0.0.0         255.255.255.0   U     0      0        0 cni0
10.244.1.0      10.244.1.0      255.255.255.0   UG    0      0        0 flannel.1
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.0.0     0.0.0.0         255.255.255.0   U     100    0        0 eno1
```

```  
$ ifconfig
cni0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
        inet 10.244.0.1  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::6c26:9ff:fe21:2164  prefixlen 64  scopeid 0x20<link>
        ether 6e:26:09:21:21:64  txqueuelen 1000  (Ethernet)
        RX packets 4931137  bytes 488981984 (466.3 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 5289945  bytes 1357446709 (1.2 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

查找flannel.1对应的节点ip

```
$ ip neigh show dev flannel.1
10.244.1.0 lladdr c2:2b:f8:ab:bd:a8 PERMANENT
bridge fdb show flannel.1 | grep c2:2b:f8:ab:bd:a8
c2:2b:f8:ab:bd:a8 dev flannel.1 dst 192.168.0.101 self permanent
```


Node2:

```
$ ip route
default via 192.168.0.1 dev enp1s0 proto static metric 100
10.244.0.0/24 via 10.244.0.0 dev flannel.1 onlink
10.244.1.0/24 dev cni0 proto kernel scope link src 10.244.1.1
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1
192.168.0.0/24 dev enp1s0 proto kernel scope link src 192.168.0.101 metric 100
```

```
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.0.1     0.0.0.0         UG    100    0        0 enp1s0
10.244.0.0      10.244.0.0      255.255.255.0   UG    0      0        0 flannel.1
10.244.1.0      0.0.0.0         255.255.255.0   U     0      0        0 cni0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.0.0     0.0.0.0         255.255.255.0   U     100    0        0 enp1s0
```

```
$ ifconfig
cni0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
        inet 10.244.1.1  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::d00e:99ff:fe06:f653  prefixlen 64  scopeid 0x20<link>
        ether d2:0e:99:06:f6:53  txqueuelen 1000  (Ethernet)
        RX packets 20  bytes 4082 (3.9 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 31  bytes 3942 (3.8 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

Container1: 10.244.0.30
Container2: 10.244.1.6
从Container1到Container2的路径

