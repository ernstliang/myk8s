# statefulset配置mysql主从

mysql-statefulset.yaml配置参考mysql官方提供的statefulset配置文件改动生成

## statefulset部署mysql主从集群

1. 使用`mysql-local-pv.yaml`配置创建Local Persistent Volume本地持久化存储，使用本地持久化存储pv需要先创建，同时因为是验证性测试这里使用的是系统里的目录作为持久化存储目录，生产环境里绝对不应该这样使用，原则一个pv一块磁盘。
2. 使用`mysql-storage-class.yaml`创建Local Persistent Volume与pvc绑定使用的storageclass，并设置延迟绑定，延迟到pod调度时。
3. 使用`mysql-configmap.yaml`创建mysql的配置文件信息，配置主从参数，配置从服务器自读等。
4. 使用`mysql-secret.yaml`创建数据库默认root密码的加密信息，这里设置的是`12345678`，`password`的值是通过base64加密的
5. 使用`mysql-svc.yaml`生成mysql的service信息，其中包括访问主mysql使用的Headless Service和访问从mysql的ClusterIp Service，这里先与statefulset之前创建，是因为配置从mysql服务器时需要请求上一个mysql服务器获取数据备份或slave配置信息。
6. 使用`mysql-statefulset.yaml`创建主从mysql数据库集群

以上步骤执行的命令都为:

```
$ kubectl apply -f xxx.yaml
```

整个过程顺利大概需要几分钟，如果出现`pending`或`CrashLoopBackOff`，需要先定位到是那个pod里失败了，然后查`describe`和`logs`查看具体错误原因并解决。

查看所有Pod信息

这里mysql-1启动失败了

```
$ kubectl get pods
NAME      READY   STATUS                  RESTARTS   AGE
mysql-0   2/2     Running                 0          10m
mysql-1   0/2     Init:CrashLoopBackOff   6          8m6s
```

先查看是pod里那个container失败，这里看是clone-mysql创建后一直在crash

```
$ kubectl describe pod mysql-1
Events:
  Type     Reason     Age                  From                Message
  ----     ------     ----                 ----                -------
  ...
  Normal   Created    8h (x5 over 8h)      kubelet, node-nuc7  Created container clone-mysql
  Warning  BackOff    7h57m (x26 over 8h)  kubelet, node-nuc7  Back-off restarting failed container
  Normal   Scheduled  8m15s                default-scheduler   Successfully assigned default/mysql-1 to node-nuc7
```

然后再查看具体容器的日志信息

```
$ kubectl logs mysql-1 clone-mysql
...
Ncat: Could not resolve hostname "mysql-0.mysql": Name or service not known. QUITTING.
+ xtrabackup --prepare --target-dir=/var/lib/mysql
xtrabackup version 2.4.4 based on MySQL server 5.7.13 Linux (x86_64) (revision id: df58cf2)
xtrabackup: cd to /var/lib/mysql
xtrabackup: Error: cannot open ./xtrabackup_checkpoints
xtrabackup: error: xtrabackup_read_metadata()
xtrabackup: This target seems not to have correct metadata...
InnoDB: Number of pools: 1
InnoDB: Operating system error number 2 in a file operation.
InnoDB: The error means the system cannot find the path specified.
xtrabackup: Warning: cannot open ./xtrabackup_logfile. will try to find.
InnoDB: Operating system error number 2 in a file operation.
InnoDB: The error means the system cannot find the path specified.
  xtrabackup: Fatal error: cannot find ./xtrabackup_logfile.
xtrabackup: Error: xtrabackup_init_temp_log() failed.
```
这个错误是因为mysql的service未配置(没有调用mysql-svc.yaml)导致从服务器查询上一台服务器的dns失败导致的。

创建mysql-svc.yaml后等待mysql-1重新启动后发现mysql集群已经正常启动

```
$ kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   2/2     Running   0          15m
mysql-1   2/2     Running   0          12m
mysql-2   2/2     Running   0          86s
```

部署完成。

然后验证下主从的配置是否生效

exec到mysql-1登陆并创建一个数据库

```
$ kubectl exec -it mysql-0 -- bash
root@mysql-0:/#
root@mysql-0:/# mysql -uroot -p
Enter password:

mysql> show databases;
+------------------------+
| Database               |
+------------------------+
| information_schema     |
| mysql                  |
| performance_schema     |
| sys                    |
| xtrabackup_backupfiles |
+------------------------+
5 rows in set (0.01 sec)

mysql> create database my_test_db character set utf8 collate utf8_general_ci;
Query OK, 1 row affected (0.00 sec)
```

然后登陆另一台数据库查看新建的数据库是否已创建

```
$ kubectl exec -it mysql-1 -- bash
root@mysql-1:/# mysql -uroot -p
Enter password:

mysql> show databases;
+------------------------+
| Database               |
+------------------------+
| information_schema     |
| my_test_db             |
| mysql                  |
| performance_schema     |
| sys                    |
| xtrabackup_backupfiles |
+------------------------+
6 rows in set (0.01 sec)
```

`my_test_db`数据库已经在mysql-1中创建，主从同步验证完成。

## 参考资料

- [极客时间-深入剖析Kubernetes](https://time.geekbang.org/column/article/41217)
