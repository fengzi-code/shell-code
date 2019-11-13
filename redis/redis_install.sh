#!/bin/bash
redis_version="3.2.10"
redis_pwd=/opt/soft
redis_port=6379
redis_CONF=$redis_pwd/redis/etc
redis_log=/var/log/redis/$redis_port.log
#不设密码请注释下面这一行
redis_passwd="zc123456"
mkdir -p /var/log/redis/
mkdir -p $redis_pwd/redis
mkdir -p $redis_pwd/Source_code
mkdir -p $redis_pwd/redis/etc
wget "http://download.redis.io/releases/redis-$redis_version.tar.gz" -P $redis_pwd/Source_code/
cd $redis_pwd/Source_code/
tar xzvf redis-$redis_version.tar.gz
cd $redis_pwd/Source_code/redis-$redis_version
yum -y install gcc gcc-c++ make
make -j$(cat /proc/cpuinfo | grep "cpu cores" | awk '{print $4}' | head -1) || make MALLOC=libc -j$(cat /proc/cpuinfo | grep "cpu cores" | awk '{print $4}' | head -1)
make install PREFIX=$redis_pwd/redis
cp redis.conf $redis_CONF/$redis_port.conf
#哨兵配置文件
cp sentinel.conf $redis_CONF/sentinel_$redis_port.conf
echo "export PATH=$redis_pwd/redis/bin:\$PATH" >>/etc/profile
source /etc/profile
#----------------------------添加开机启动---------------
cp utils/redis_init_script /etc/init.d/redis-server
chmod a+x /etc/init.d/redis-server
sed -i '2i# chkconfig: - 90 95' /etc/init.d/redis-server
#单引号：shell处理命令时，对其中的内容不做任何处理。即此时是引号内的内容是sed命令所定义的格式。
#双引号：shell处理命令时，要对其中的内容进行算术扩展。
sed -i "s/REDISPORT=6379/REDISPORT=$redis_port/" /etc/init.d/redis-server
exec1="/usr/local/bin/redis-server"
exec2="$redis_pwd/redis/bin/redis-server"
#当变量中有很多/号时我们可以用#替换sed命令中的/
sed -i "s#EXEC=$exec1#EXEC=$exec2#" /etc/init.d/redis-server
sed -i "s#CLIEXEC=/usr/local/bin/redis-cli#CLIEXEC=$redis_pwd/redis/bin/redis-cli#" /etc/init.d/redis-server
sed -i 's#CONF="/etc/redis/${REDISPORT}.conf"#CONF=ggggg#' /etc/init.d/redis-server
sed -i "s#CONF=ggggg#CONF=\"$redis_CONF/\${REDISPORT}.conf\"#" /etc/init.d/redis-server
chkconfig --add redis-server
chkconfig --level 345 redis-server on
#----------------------------添加开机启动结束---------------
#配置下面的内核参数，否则Redis脚本在重启或停止redis时，将会报错，并且不能自动在停止服务前同步数据到磁盘上
echo "vm.overcommit_memory = 1" >>/etc/sysctl.conf
sysctl -p
sed -i 's/daemonize no/daemonize yes/' $redis_CONF/$redis_port.conf
sed -i "s#pidfile /var/run/redis_6379.pid#pidfile /var/run/redis_$redis_port.pid#" $redis_CONF/$redis_port.conf
sed -i "s#port 6379#port $redis_port#" $redis_CONF/$redis_port.conf
sed -i "s#logfile \"\"#logfile \"$redis_log\"#" $redis_CONF/$redis_port.conf
echo "requirepass $redis_passwd" >>$redis_CONF/$redis_port.conf
if [ "$redis_passwd" != " " ]; then
  sed -i "s#\$CLIEXEC -p \$REDISPORT shutdown#\$CLIEXEC -a $redis_passwd -p \$REDISPORT shutdown#" /etc/init.d/redis-server
fi
echo never >/sys/kernel/mm/transparent_hugepage/enabled
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >>/etc/rc.local
#redis-cli -h 127.0.0.1 -a ky2fehez8CGxb -p 6379
# select 2 选择数据库2
# Flushall  清空所有库所有键
# Flushdb  清空当前库所有键
# config set requirepass 654321  #将密码设置为654321
# CLIENT LIST ：返回所有连接到服务器的客户端信息和统计数据
# CLIENT KILL ip:port：关闭地址为ip:port的客户端
# config get *  查询所有的配置项
# config get save 获取指定配置项
# CONFIG RESTART ：重置 INFO 命令中的某些统计数据
# keys unreadAskForPriceCache* 匹配以unreadAskForPriceCache开头的key
# type unreadAskForPriceCache:295 查看key的类型
# del unreadAskForPriceCache:295 删除指定key
# bgrewriteaof 强制重写aof日志文件
# bgsave 和 save前者是后台保存rdb的快照，后者是显示的保存rdb的快照
# shutdown [save/nosave] 表示的是停止redis的数据库
# info memory : 查看redis的内存使用情况
# 主从复制的一个具体情况 info replication
# info persistence redis的持久化的情况
# Exist lind --判断键是否存在
# config get/set slowlog-log-slower-than 慢查询时间设置,单位是微秒
# config get/set slowlog-max-len 储存多少条慢查询的记录
# slowlog get 10 获取10条慢日志
