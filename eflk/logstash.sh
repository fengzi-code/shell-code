#!/bin/bash

logstatsh_version="7.0.0"
logstatsh_ver_end=''
install_dir=/opt/soft
logstatsh_CONF=$install_dir/logstash-$logstatsh_ver$logstatsh_ver_end/config
es_add='http://192.168.128.131:9200'
ipdz=$(ifconfig | grep broadcast|awk '{print $2}'|head -n 1)

https://artifacts.elastic.co/downloads/logstash/logstash-7.0.0.tar.gz

yum tar wget -y
wget -c https://artifacts.elastic.co/downloads/logstash/logstash-$logstatsh_version$logstatsh_ver_end.tar.gz

mkdir -p $install_dir
mkdir -p /var/log/logstash
mkdir -p /opt/soft/logstash-7.0.0/config/conf.d
tar zxf logstash-$logstatsh_version$logstatsh_ver_end.tar.gz -C $install_dir

echo "
node.name: logstash-node1    #节点名称，
path.config: /opt/soft/logstash-7.0.0/config/conf.d    #配置文件目录
config.test_and_exit: false    # 这个是启动时测试配置文件然后退出，false即可
config.reload.automatic: true  # 是否自动重载配置文件
config.reload.interval: 3s   # 检查配置文件改变的时间间隔
config.debug: false
http.host: \"$ipdz\"  # 监听地址，尽量设为内网地址
http.port: 9600-9700  # 监听端口范围
log.level: info    # 日志级别，日志将写到下面的目录
path.logs: /var/log/logstash   # 这是logstash运行时产生的日志的目
" >> $install_dir/logstash-$logstatsh_version$logstatsh_ver_end/config/logstash.yml

echo "切换到$install_dir/logstash-$logstatsh_version$logstatsh_ver_end/bin 目录下执行文件"
ecoo '请自行配置规则文件'