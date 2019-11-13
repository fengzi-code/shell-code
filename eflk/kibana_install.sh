#!/bin/bash

kibana_version="7.0.0"
kibana_ver_end='-linux-x86_64'
kibana_port='5601'
install_dir=/opt/soft
kibana_CONF=$install_dir/kibana-$kibana_version$kibana_ver_end/config
es_add='http://192.168.128.131:9200'
ipdz=$(ifconfig | grep broadcast|awk '{print $2}'|head -n 1)

yum install ipa-gothic-fonts xorg-x11-fonts-100dpi xorg-x11-fonts-75dpi xorg-x11-utils xorg-x11-fonts-cyrillic xorg-x11-fonts-Type1 xorg-x11-fonts-misc wget -y

wget -c https://artifacts.elastic.co/downloads/kibana/kibana-$kibana_version$kibana_ver_end.tar.gz
mkdir -p $install_dir
tar zxf kibana-$kibana_version$kibana_ver_end.tar.gz -C $install_dir

echo "
server.port: $kibana_port
server.host: \"$ipdz\"
elasticsearch.hosts: [\"$es_add\"]
# 日常用的ping超时
elasticsearch.pingTimeout: 1500
# 连接es超时时间
elasticsearch.requestTimeout: 30000
#  es鉴权用户
# elasticsearch.username: \"user\"
# es鉴权密码
# elasticsearch.password: \"pass\"
i18n.locale: \"zh-CN\"
logging.timezone: \"Asia/Shanghai\"
" >> $kibana_CONF/kibana.yml

echo '请至bin目录执行kibana'
