#!/bin/bash
#开发测试环境初始化脚本
#文件存于监控服务器/opt/soft/web/file
lujin=$(pwd)
#-------------------修改计算机名host----------------------
read -p "请输入修改的计算机名: " DOMAIN
hostnamectl --static set-hostname $DOMAIN
cp /etc/hosts /etc/hosts.$(date +%F)
sed -i 's/127.0.0.1/127.0.0.1 '$DOMAIN' /g' /etc/hosts
hostname
echo 修改host
echo "192.168.1.11 server21.mzj
192.168.1.12 server12.mzj
192.168.1.13 server13.mzj
192.168.1.14 server14.mzj
192.168.1.15 server15.mzj
192.168.1.16 server16.mzj
192.168.1.17 server17.mzj
192.168.1.18 server18.mzj
192.168.1.19 server19.mzj
192.168.1.14 eureka.eagle.mzj.net
192.168.1.14 rabbitmq.eagle.mzj.net
192.168.1.14 redis.eagle.mzj.net
192.168.1.14 zipkin.eagle.mzj.net
192.168.1.11 mysql.eagle.mzj.net
192.168.1.35 svn.eagle.mzj.net
192.168.1.14 apigw.eagle.mzj.net" >> /etc/hosts
cat /etc/hosts
echo 修改host结束
#-------------------结束修改计算机名host----------------------
echo "修改系统密码,请输入新密码!"
passwd root
yum -y update
echo "系统更新完毕!"
#-------------------JAVA安装开始----------------------
echo JAVA安装开始
yum -y install wget
wget http://192.168.1.23/jdk-8u144-linux-x64.tar.gz -P /tmp/csh/
cd /tmp/csh
mkdir -p /usr/java
tar zxvf /tmp/csh/jdk-8u144-linux-x64.tar.gz -C /usr/java
cp /etc/profile /etc/profile.bak.$(date +%F)
echo "#JAVA" >> /etc/profile
echo "export JAVA_HOME=/usr/java/jdk1.8.0_144" >> /etc/profile
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile
echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile
source /etc/profile
echo $JAVA_HOME
java -version
echo JAVA安装结束,如果能显示java路径表示安装成功.
#-------------------JAVA安装结束----------------------
#-------------------关闭防火墙---------------------
echo 关闭防火墙
systemctl stop firewalld.service
systemctl disable firewalld.service
echo 关闭防火墙结束
#-------------------关闭防火墙结束---------------------
#-------------------修改连接数---------------------
echo 修改连接数
cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F) && \
echo "# /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
*        soft            nproc      655350
*        hard            nproc      655350
*        soft            nofile      655350
*        hard            nofile      655350
*        soft            sigpending  128484
*        hard            sigpending  128484
*        soft            stack    128484
*        hard            stack    128484
" > /etc/security/limits.conf
cp /etc/sysctl.conf /etc/sysctl.conf.$(date +%F) && \
echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
vm.swappiness = 0
net.ipv4.neigh.default.gc_stale_time=120
# see details in https://help.aliyun.com/knowledge_detail/39428.html
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_announce=2
# see details in https://help.aliyun.com/knowledge_detail/41334.html
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
### ##############################################
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range= 1025 65535
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog=16384
net.ipv4.tcp_max_orphans=16384" > /etc/sysctl.conf
sysctl -p
echo 修改连接数结束
#-------------------修改连接数结束---------------------
#-------------------增加交换分区----------------------
#dd if=/dev/zero of=/var/swap bs=512 count=8388616
#mkswap /var/swap
#swapon /var/swap
#swapon -s
#echo "/var/swap swap swap defaults 0 0" >> /etc/fstab
#sed -i "s/vm.swappiness = 0/vm.swappiness = 10/g" /etc/sysctl.conf
#sysctl -p
#----------------------交换分区结束-----------------------------
#-------------------关闭selinux----------------------
echo selinux关闭开始
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
/usr/sbin/sestatus -v
echo selinux关闭结束
#-------------------结束关闭selinux----------------------
#-------------------------wxapi初始化------------------------------------------------------------
wget http://192.168.1.23/wxapi/fonts/fonts.tar.gz -P /usr/java/jdk1.8.0_144/jre/lib/fonts/
cd /usr/java/jdk1.8.0_144/jre/lib/fonts/
tar zxvf fonts.tar.gz -C /usr/java/jdk1.8.0_144/jre/lib/fonts/
yum -y install mkfontscale
mkfontscale
mkfontdir
rm -rf /usr/java/jdk1.8.0_144/jre/lib/security/local_policy.jar /usr/java/jdk1.8.0_144/jre/lib/security/US_export_policy.jar
wget http://192.168.1.23/wxapi/jre/lib/security/local_policy.jar -P /usr/java/jdk1.8.0_144/jre/lib/security/
wget http://192.168.1.23/wxapi/jre/lib/security/US_export_policy.jar -P /usr/java/jdk1.8.0_144/jre/lib/security/
#-------------------------wxapi初始化结束------------------------------------------------------------
cd $lujin
source /etc/profile
rm -rf /tmp/csh
shutdown -r &
echo "服务器将于45秒后重启,如需取消请输入shutdown -c"
sleep 1
rm -rf "$0"