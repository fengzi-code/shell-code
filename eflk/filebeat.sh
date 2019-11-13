#!/bin/bash

filebeat_version="7.0.0"
filebeat_ver_end='-linux-x86_64'
install_dir=/opt/soft
logstatsh_add='"192.168.128.129:5044","192.168.128.129:5044"'

mkdir -p $install_dir/filebeat-$filebeat_version$filebeat_ver_end/config
mkdir -p /var/log/filebeat

wget -c https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$filebeat_version$filebeat_ver_end.tar.gz

tar zxf filebeat-7.0.0-linux-x86_64.tar.gz -C $install_dir

cp $install_dir/filebeat-$filebeat_version$filebeat_ver_end/filebeat.yml $install_dir/filebeat-$filebeat_version$filebeat_ver_end/filebeat.yml.bak

echo "
filebeat.config.inputs:
  enabled: true
  path: $install_dir/filebeat-$filebeat_version$filebeat_ver_end/config/*.yml
  reload.enabled: true
  reload.period: 10s

filebeat.config.modules:
  index.number_of_shards: 1

setup.kibana:
output.logstash:
  hosts: [$logstatsh_add]
  loadbalance: true
  compression_level: 6

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
" > $install_dir/filebeat-$filebeat_version$filebeat_ver_end/filebeat.yml


echo "
- type: log
  enabled: true
  paths:
    - /tmp/nginx_logs/*.log
  fields:
    gpcskin_type: nginx_access
- type: log
  enabled: true
  paths:
    - /var/log/messages*
    - /var/log/secure*
    - /var/log/cron*
  fields:
    gpcskin_type: syslog
" > $install_dir/filebeat-$filebeat_version$filebeat_ver_end/config/filebeat_input.yml



# net.ipv4.ip_forward=1   增加IP转发规则

# filebeat:
# prospectors:
# - input_type: log #指定输入类型
# paths:
# - /data/logs/nginx/*.log #支持基本的正则,所有golang glob都支持,支持/var/log/*/*.log
# input_type: log
# document_type: nginx #类型事件，被用于设置输出文档的type字段，默认是log
# encoding: utf-8
# close_inactive: 1m #启动选项时，如果在制定时间没有被读取，将关闭文件句柄
# scan_frequency: 5s #检查指定用于收获的路径中的新文件的频率,默认10s
# fields:            #可选字段，选择额外的字段进行输出,可以是标量值，元组，字典等嵌套类型
# nginx_id: web-nodejs
# fields_under_root: true #如果值为ture，那么上面的可选字段存储在输出文档的顶级位置
# close_removed: true
# tail_files: true                          #如果此选项设置为true,将在每个文件的末尾开始读取新文件，而不是开头
# tags: 'web-nginx'                         #列表中添加标签，用过过滤
# spool_size: 1024                          #事件发送的阀值，超过阀值，强制刷新网络连接
# idle_timeout: 5s                          #事件发送的超时时间，即使没有超过阀值，也会强制刷新网络连接
# registry_file: /var/lib/filebeat/registry #注册表文件的名称，如果使用相对路径，则被认为是相对于数据路径
# output:
# logstash:
# enabled: true
# hosts: ["192.168.6.108:5044"]
# worker: 4
# bulk_max_size: 1024
# compression_level: 6
# loadbalance: false
# index: filebeat
# backoff.max: 120s