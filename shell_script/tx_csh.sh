#!/bin/bash
#初始化脚本
lujin=$(pwd)
#-------------------修改计算机名host----------------------
read -p "请输入修改的计算机名: " DOMAIN
hostnamectl --static set-hostname $DOMAIN
cp /etc/hosts /etc/hosts.$(date +%F)
sed -i 's/127.0.0.1/127.0.0.1 '$DOMAIN' /g' /etc/hosts
hostname
echo 修改host
echo '
10.0.2.3 els.eagle.mzj.net
10.0.1.5 eureka.eagle.mzj.net
10.0.1.5 eureka01.eagle.mzj.net
10.0.1.5 svn.eagle.mzj.net
10.0.3.3 apigw.eagle.mzj.net
10.0.1.9 rabbitmq.eagle.mzj.net
10.0.3.6 mysql.eagle.mzj.net
10.0.3.7 redis.eagle.mzj.net
10.0.3.4 elk.eagle.mzj.net
10.0.3.6   mysql.eagle.mzj.net
10.0.3.7   redis.eagle.mzj.net' >> /etc/hosts
cat /etc/hosts
echo 修改host结束
#-------------------结束修改计算机名host----------------------
echo "修改系统密码,请输入新密码!"
passwd root
yum -y update && echo "系统更新完毕!"
#-------------------JAVA安装开始----------------------
echo JAVA安装开始
wget http://10.0.1.5:8877/jdk-8u144-linux-x64.tar.gz -P /tmp/csh/
wget http://10.0.1.5:8877/limits.conf -P /tmp/csh/
wget http://10.0.1.5:8877/sysctl.conf -P /tmp/csh/
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
cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F) && /bin/cp -rf /tmp/csh/limits.conf /etc/security/limits.conf
cp /etc/sysctl.conf /etc/sysctl.conf.$(date +%F) && /bin/cp -rf /tmp/csh/sysctl.conf /etc/sysctl.conf
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
wget http://10.0.1.5:8877/zabbix-3.4.4.tar.gz -P /tmp/csh/
cd /tmp/csh
tar zxvf zabbix-3.4.4.tar.gz -C /tmp/csh/
yum -y install pcre-devel gcc gcc-c++
cd /tmp/csh/zabbix-3.4.4
./configure --enable-agent --prefix=/usr/local/zabbix_agent && make &&make install
cp /tmp/csh/zabbix-3.4.4/misc/init.d/tru64/zabbix_agentd /etc/init.d/zabbix_agent
sed -i '2i# chkconfig: - 95 95' /etc/init.d/zabbix_agent
sed -i 's/\/usr\/local\/sbin\/zabbix_agentd/\/usr\/local\/zabbix_agent\/sbin\/zabbix_agentd/g' /etc/init.d/zabbix_agent
chkconfig --add zabbix_agent
chkconfig --level 345 zabbix_agent on
chmod +x /etc/init.d/zabbix_agent
useradd -s /sbin/nologin zabbix && chown zabbix:zabbix /etc/init.d/zabbix_agent
cp /usr/local/zabbix_agent/etc/zabbix_agentd.conf /usr/local/zabbix_agent/etc/zabbix_agentd.conf.$(date +%F)
ipdz=$(ip a show eth0 |grep "inet " |awk '{print $2}' |awk -F"/" '{print $1}')
sed -i 's/Server=127.0.0.1/Server=120.78.187.221/g' /usr/local/zabbix_agent/etc/zabbix_agentd.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=120.78.187.221/g' /usr/local/zabbix_agent/etc/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix server/Hostname=$(hostname)_$ipdz/g" /usr/local/zabbix_agent/etc/zabbix_agentd.conf
sed -i 's/PidFile=\/tmp\/zabbix_agentd.pid//g' /usr/local/zabbix_agent/etc/zabbix_agentd.conf
sed -i "12 a PidFile=/tmp/zabbix_agentd.pid" /usr/local/zabbix_agent/etc/zabbix_agentd.conf
#PidFile=/tmp/zabbix_agentd.pid
#-------------------------zabbux增加tcp监控------------------------------------------------------------
echo "Include=/usr/local/zabbix_agent/etc/zabbix_agentd.conf.d/*.conf" >> /usr/local/zabbix_agent/etc/zabbix_agentd.conf
mkdir -p /usr/local/zabbix_agent/scripts/
wget http://10.0.1.5:8877/tcp_conn_status.sh -P /usr/local/zabbix_agent/scripts/
wget http://10.0.1.5:8877/tcp-status-params.conf -P /usr/local/zabbix_agent/etc/zabbix_agentd.conf.d/
chmod +x /usr/local/zabbix_agent/scripts/tcp_conn_status.sh
echo  '请将zbx_tcp_templates.xml模板导入zabbix web端'
#-------------------------zabbix结束tcp监控------------------------------------------------------------
#-------------------------开始nginx监控------------------------------------------------------------
echo UserParameter=nginx[*],/usr/local/zabbix_agent/scripts/nginx_chek.sh \"\$1\" >> /usr/local/zabbix_agent/etc/zabbix_agentd.conf
wget http://10.0.1.5:8877/nginx_chek.sh -P /usr/local/zabbix_agent/scripts/
echo 请在nginx.conf中添加以下内容
echo location /mzj-nginx_status
echo        {
    echo                stub_status on;
    echo                access_log off;
    echo                allow 127.0.0.1;
    echo                deny all;
echo        }
#-------------------------结束ginx监控---------------------------------------------------------------
#-------------------------开始java监控------------------------------------------------------------
echo 请在start.sh中添加以下内容
echo "mzj readonly" > /usr/java/jdk1.8.0_144/jmxremote.access
echo "mzj Mzj@q.com" > /usr/java/jdk1.8.0_144/jmxremote.password
chmod 600 /usr/java/jdk1.8.0_144/jmxremote*
echo "请在启动脚本中添加以下内容
nohup java -jar -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=1$SERVICE_PORT -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=true -Djava.rmi.server.hostname=$ipdz -Dcom.sun.management.jmxremote.password.file=$JAVA_HOME/jmxremote.password -Dcom.sun.management.jmxremote.access.file=$JAVA_HOME/jmxremote.access"
echo '请在zabbix服务端中开启zabbix_java 并配置'
#-------------------------结束java监控------------------------------------------------------------
#-------------------------wxapi初始化------------------------------------------------------------
wget http://10.0.1.5:8877/wxapi/fonts/fonts.tar.gz -P /usr/java/jdk1.8.0_144/jre/lib/fonts/
cd /usr/java/jdk1.8.0_144/jre/lib/fonts/
tar zxvf fonts.tar.gz -C /usr/java/jdk1.8.0_144/jre/lib/fonts/
mkdir -p /usr/share/fonts/chinese
cd  /usr/share/fonts/chinese
wget http://219.135.214.61:4999/msyhbd.ttf -P /usr/share/fonts/chinese/
wget http://219.135.214.61:4999/msyh.ttf -P /usr/share/fonts/chinese/
yum install -y fontconfig mkfontscale
cd  /usr/share/fonts/chinese
mkfontscale
mkfontdir
fc-list
mkfontscale
mkfontdir
rm -rf /usr/java/jdk1.8.0_144/jre/lib/security/local_policy.jar /usr/java/jdk1.8.0_144/jre/lib/security/US_export_policy.jar
wget http://10.0.1.5:8877/wxapi/jre/lib/security/local_policy.jar -P /usr/java/jdk1.8.0_144/jre/lib/security/
wget http://10.0.1.5:8877/wxapi/jre/lib/security/US_export_policy.jar -P /usr/java/jdk1.8.0_144/jre/lib/security/
#-------------------------wxapi初始化结束------------------------------------------------------------
echo "UserParameter=cpu.status[*],/usr/local/zabbix_agent/scripts/cpu_conn_status.sh \$1" >>  /usr/local/zabbix_agent/etc/zabbix_agentd.conf.d/tcp-status-params.conf
wget http://219.135.214.61:4999/cpu_conn_status.sh -P /usr/local/zabbix_agent/scripts/
chown zabbix:zabbix -R /usr/local/zabbix_agent/
chmod +x /usr/local/zabbix_agent/scripts/*.sh
#-----------------------------------cpu使用率安装完毕-------------------------------------------------------------
cd $lujin
source /etc/profile
rm -rf /tmp/csh
shutdown -r &
echo "服务器将于45秒后重启,如需取消请输入shutdown -c"
sleep 1
rm -rf "$0"
