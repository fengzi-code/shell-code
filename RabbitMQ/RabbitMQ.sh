#!/bin/bash
mq_ver="3.6.12"
mq_user='admin'
mq_paswd='Mzj-Baidu-180525'
yum -y install epel-release
yum -y update
yum -y install erlang socat
erl -version
cd /tmp
wget https://www.rabbitmq.com/releases/rabbitmq-server/v$mq_ver/rabbitmq-server-$mq_ver-1.el7.noarch.rpm
rpm –import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
rpm -Uvh rabbitmq-server-$mq_ver-1.el7.noarch.rpm
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
systemctl status rabbitmq-server
#启动RabbitMQ Web管理控制台
rabbitmq-plugins enable rabbitmq_management
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq/
#添加用户
rabbitmqctl add_user $mq_user $mq_paswd
rabbitmqctl set_user_tags $mq_user administrator
rabbitmqctl set_permissions -p / $mq_user ".*" ".*" ".*"
