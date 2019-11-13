
[toc]

# 1. 安装docker

## 1.1 常用命令

```bash
yum install docker -y  #安装
docker version  # 查看版本
systemctl enable docker # 开机启动
systemctl start docker # 运行docker
docker help # 帮助
docker images # 查看系统中的镜像
docker search mysql # 从远程仓库搜索镜像
docker pull docker.io/ansible/centos7-ansible # 拉取镜像,按层级下载
docker ps  # 查看运行的容器-a 看所有运行过的容器
docker inspect 688353a31fde # 查看镜像详细信息
docker history 688353a31fde # 列出镜像各个层（layer）的创建信息,history --no-trunc更详细
docker run -tid 688353a31fde /bin/bash # 运行镜像,-t让docker分配一个伪终端并绑定到容器的标准输入上, -i则让容器的标准输入保持打开,-d后台运行
docker run -tid -v /data/mysql:/tmp/data 688353a31fde /bin/bash  #挂宿主机目录至容器
docker run -tid --name nginx2 --volumes-from nginx1 688353a31fde #复制其它容器中的卷
docker exec -it -u root 22f8d9d46e92 /bin/bash # 以root用户启动,--privileged 取得root权限

docker run -ti 688353a31fde /bin/bash home/start.sh #启动后运行脚本
docker --privileged # 超级权限启动
docker run --privileged --network=none -itd f0d03f0a3e26 /usr/sbin/init
docker run --rm -e DOC_ROOT='/opt/data' httpd:1.18 printenv  #修改或增加容器中的DOC_ROOT变量,打印容器中的所有变量,启动完后删除容器

```
## 1.2 提升docker官方镜像速度

```
vim  /etc/docker/daemon.json
增加如下配置
{
  "registry-mirrors": ["https://0by6hvzh.mirror.aliyuncs.com"]
}
重新加载生效
systemctl daemon-reload
systemctl restart docker
```
## 1.3. docker 五种网络模式
### 1.3.1 none 模式
这种网络模式下容器只有lo回环网络，none网络可以在容器创建时通过--network=none来指定。这种类型的网络没有办法联网，封闭的网络能很好的保证容器的安全性。使用none模式时容器没有网卡、IP、路由等信息。需要我们自己为Docker容器添加网卡、配置IP等
### 1.3.2 host网络
通过命令--network=host指定，host表示容器共享宿主机的ip和端口号。容器中不会虚拟自己的网卡和ip，当你查看容器ip的时候，其实是宿主机的ip。
如：创建nginx容器
docker run -tid --net=host --name nginx nginx:1.13.12
你访问主机的http://ip:80其实就是容器的80端口，不用做端口映射了
### 1.3.3 bridge网络
使用--net=bridge指定，默认设置 ，此模式会为每一个容器分配、设置IP等，并将容器连接到一个docker0虚拟网桥，通过docker0网桥以及Iptables nat表配置与宿主机通信。
### 1.3.4 container模式
使用--net=container:NAME_or_ID指定，创建的容器不会创建自己的网卡，配置自己的IP，而是和一个指定的容器共享IP、端口范围。
### 1.3.5 user-defined模式
用户自定义模式主要可选的有三种网络驱动：bridge、overlay、macvlan。bridge驱动用于创建类似于前面提到的bridge网络;overlay和macvlan驱动用于创建跨主机的网络。

# 2.docker bridge网络配置
docker默认提供了一个隔离的内网环境，启动时会建立一个docker0的虚拟网卡，每个容器都是连接到docker0网卡上的。而docker0的ip段为172.17.0.1，若想让容器与宿主机同一网段的其他机器访问，就必须在启动docker的时候将某个端口映射到宿主机的端口上才行，例如：docker run -itd -p 22 centos。这是我们所不能接受的，想想每个应用都要绞尽脑汁的去设置端口，因为不能重复，如果应用有多端口那更是不堪设想啊。所以为了让容器与宿主机同一个网段，我们需要建立自己的桥接网络。

2.1 下载安装桥接管理工具
```
yum install bridge-utils
```
2.2 配置物理网卡
> cat /etc/sysconfig/network-scripts/ifcfg-eno16777736
```py
TYPE=Ethernet
BOOTPROTO=static
NAME=eno16777736
ONBOOT=yes
BRIDGE="br0"
IPADDR=192.168.128.129
NETMASK=255.255.255.0
GATEWAY=192.168.128.2
```
2.3 配置桥接网卡
> cp /etc/sysconfig/network-scripts/ifcfg-eno16777736 /etc/sysconfig/network-scripts/ifcfg-br0
> cat /etc/sysconfig/network-scripts/ifcfg-br0
```py
DEVICE=br0
ONBOOT=yes
BOOTPROTO=static
TYPE="Bridge"
IPADDR=192.168.128.129
NETMASK=255.255.255.0
GATEWAY=192.168.128.2
DNS1=8.8.8.8
```
2.4 删除docker默认自带桥接

```bash
systemctl stop docker
ip link set dev docker0 down
brctl delbr docker0
```
2.5 重启网络
```
systemctl restart network
ping www.baidu.com # 测试连通
```

# 3.docker 容器桥接模式配置静态IP

3.1 安装pipework工具
```
yum install unzip wget -y
wget https://github.com/jpetazzo/pipework/archive/master.zip
unzip master.zip
cp pipework-master/pipework /usr/local/bin/
rm pipework-master/ -rf
rm master.zip -f
```
3.2 修改docker桥接网卡
> grep -vE "^#|^$" /etc/sysconfig/docker   # 在--selinux-enabled后面加上 -b=br0
```
OPTIONS='--selinux-enabled -b=br0 --log-driver=journald --signature-verification=false'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi
```
> systemctl restart docker.service

3.3 配置静态IP

```
docker run -itd --net=none --name=jenkins docker.io/jenkinsci/blueocean /bin/bash
pipework br0 jenkins 192.168.128.11/24@192.168.128.2

docker exec -it jenkins ip a  # 查看ip
ping 192.168.128.11 #测试生效
```