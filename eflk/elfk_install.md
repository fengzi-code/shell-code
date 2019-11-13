[TOC]


# 部署要求



服务/应用|ip|port|软件版本|服务器
---|---|---|---|---
elasticsearch|192.168.128.131|9200/9300|7.0.0|centos7.5
kibana|192.168.128.128|5601|7.0.0|centos7.5
logstash_1|192.168.128.129|9600/5044|7.0.0|centos7.5
filebeat_1|168.168.128.130| |7.0.0|centos7.5
1. 流程图如下
---

![2019-05-22-15-59-47](/assets/2019-05-22-15-59-47.png)

# 1. elasticsearch安装配置
1. 安装前请准备好jdk 1.8以上环境,运行本文末的elasticsearch_install.sh文件进行安装
2. 安装好后运行```service elasticsearch start```启动
3. 主要配置如下
```yml
# es集权名字
cluster.name: es_jiquan
# 允许此节点可以作为主节点（默认启用）
node.master: true
# 允许此节点可以用来存储数据（默认启用）
node.data: true
# 节点名称
node.name: node-1
# 数据存放路径
path.data: /data/es_data
# 日志存放路径
path.logs: /data/es_logs
# 监听IP
network.host: 192.168.128.131
# 监听端口
http.port: 9200
# 设置集群中master节点的初始列表，可以通过这些节点来自动发现新加入集群的节点,多个用逗号分开
discovery.zen.ping.unicast.hosts: ["192.168.128.131"]
# 节点之间通信端口
transport.tcp.port: 9300
# 设置一系列符合主节点条件的节点的主机名或 IP 地址来引导启动集群,7.0新增参数
cluster.initial_master_nodes: [node-1]
```

# 2. kibana安装配置
1. 在服务器上下载kibana文件,解压
```
wget -c https://artifacts.elastic.co/downloads/kibana/kibana-7.0.0-linux-x86_64.tar.gz
tar zxf kibana-7.0.0-linux-x86_64.tar.gz
```
2. 找到安装目录下的bin目录,运行 kibana文件即可
3. 主要配置如下:
```yml
server.port: 5601
server.host: "192.168.128.128"
# es 地址
elasticsearch.hosts: ["http://192.168.128.131:9200"]
elasticsearch.pingTimeout: 1500
elasticsearch.requestTimeout: 30000
# 配置kibana显示中文
i18n.locale: "zh-CN"
# 配置kibana日志时区,解决kibana自身日志少8小时
logging.timezone: "Asia/Shanghai"
```


# 3. logstash安装配置
1. 安装前请准备好java1.8以上环境,在服务器上下载logstash安装文件,解压即可.
```
wget -c https://artifacts.elastic.co/downloads/logstash/logstash-7.0.0.tar.gz
tar zxf logstash-7.0.0.tar.gz
```
2. 切换到安装目录的bin目录下执行 logstash
3. 常用命令集
```yml
logstash-plugin list --verbose # 查看所有插件版本
logstash -t -f ../config/test.conf   # 检测配置是否正确
```
4. config/logstash.yml 主要配置如下:
```yml
node.name: logstash-node1    #节点名称，
path.config: /opt/soft/logstash-7.0.0/config/conf.d    #日志配置文件目录
config.test_and_exit: false    # 这个是启动时测试配置文件然后退出，false即可
config.reload.automatic: true  # 是否自动重载配置文件
config.reload.interval: 3s   # 检查配置文件改变的时间间隔
config.debug: false
http.host: "192.168.128.129"  # 监听地址
http.port: 9600-9700  # 监听端口范围
log.level: info    # logstash本身日志级别
path.logs: /var/log/logstash   # logstash运行时产生的日志的目录
```
5. conf.d下日志规则文件如下

  ```python
  input {
    beats {   # 使用filebeat传输日志
      host => "192.168.128.129"   # 监听IP
      port => 5044    # 监听端口
    }
  }

  #-----------------不使用filebeat采集请使用如下规则------------------------
  # input { # 读取事件源
  #   file {  # 从文件读取
  #     type => "syslog" # 类型,可用于过滤器进行条件判断
  #     path => [ "/var/log/messages*", "/var/log/secure*", "/var/log/cron*"] #数组类型，文件路径，基于glob匹配语法
  #     start_position => "beginning" #读取位置,此表示从起始位置
  #   }
  # }
  #-----------------不使用filebeat采集请使用如上规则------------------------

  filter {
    mutate {
          # remove_tag是移除一些标签，标签可能来自filebeat定义，值是一个列表
          remove_tag => ["agent", "ecs", "[log][offset]", "[input][type]", "@version", "tags"]
    }
    if [fields][gpcskin_type] == "syslog" {
    #   这里的[fields][gpcskin_type] 对应 filebeat里的自定义字段
        grok {    # grok正则插件
            match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
            # match可以设置多个，上面的失效后会执行下一个match，上面的match是将message按后面的格式输出，每一个%{}里放着一对键值，前面的大写是grok正则，后面小写的是变量名，拿第1个%{}里举例说明，SYSLOGTIMESTAMP会匹配出一个系统日志时间，然后放到syslog_time里,在kibana里显示是syslog_time:%{syslog_time},后面的syslog_time放的就是前面正则匹配的值(这个值有可能被后面的插件格式化)
            # 注意! SYSLOGTIMESTAMP等是grok内置正则规则变量,可到vendor/bundle/jruby/2.5.0/gems/logstash-patterns-core-4.1.2/patterns/grok-patterns文件查看
            add_field => [ "received_at", "%{@timestamp}" ]
            # 增加字段`received_at`，把@timestamp赋值给左边的字段,@timestamp是logstash内置字段,表示logstash读取输入源日志的时间
            add_field => [ "received_from", "%{syslog_hostname}" ]

        }
        syslog_pri { }    # syslog_pri是一个系统日志处理模块
        date {    # 这是一个日期时间插件
            match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
            # 匹配syslog_timestamp中的内容以MMM  d HH:mm:ss和MMM dd HH:mm:ss格式的时间
            # 默认将匹配到的时间赋值给@timestamp,重新赋值后@timestamp的时间就变成日志本身记录的写入时间了.方便kibana进行时间排序使用,日志本身记录的写入时间比logstash读取的时间要准确
            # 经过重新赋值,received_at字段变成读取日志的时间,%{@timestamp}字段变成写入日志的时间了
        }
        mutate {
          # remove_field是移除字段，值是一个列表
          #remove_field => [ "offset","beat","@version","input_type"]
          remove_field => ["syslog_facility", "syslog_facility_code", "syslog_severity_code", "host"]
        }
    }

    else if [fields][gpc_type] == "nginx_access" {
      grok {
              # 根据自己的nginx日志写正则匹配
              match => { "message" => "\[TIME:%{TIMESTAMP_ISO8601:[@metadata][access_time]}\] \| \[CDN:%{IPV4:proxy_ip}, USER:%{DATA:real_ip}\] \| \[URL:%{DATA:url}\] \| \[REFERER:%{DATA:referer}\] \| \[REQUEST:%{USER:remote_user} %{DATA:request}\] \| \[STATUS:%{NUMBER:http_code} %{NUMBER:body_bytes_sent}\] \| \[USER_AGENT:%{GREEDYDATA:agent}\]" }
              add_field => [ "received_at", "%{@timestamp}" ]
              add_field => [ "received_from", "%{[host][name]}" ]
        }
        # 如果真实IP为空，使用代理IP替换真实IP(因内网上网通过NAT方式访问，只会记录其WAN口IP)
        date {
          match => ["[@metadata][access_time]", "ISO8601"]
        }
        if [real_ip] == "-" {
            mutate {
                # 将real_ip的值替换为proxy_ip的值
                replace => { "real_ip" => "%{proxy_ip}" }
            }
        }
        # 使用geoip模块显示ip归属地，经纬度等信息
        geoip {
            # 待处理数据来自哪个变量
            source => "real_ip"  
            # 将real_ip的值给到geoip
            target => "geoip"    
            # database => "/usr/share/GeoIP/GeoLiteCity.dat" 不指定路径默认使用logstash自带的数据库
            # 增加字段，具体字段含义请上geoip查
            add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
            add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
            remove_field => ["[geoip][continent_code]","[geoip][region_code]","[geoip][country_code2]","[geoip][ip]","[geoip][timezone]","[geoip][latitude]","[geoip][longitude]"]

        }
        mutate {
            # 将列表左边的字符转换为float类型
            convert => [ "[geoip][coordinates]", "float"]
            remove_field => ["host"]
        }
    } 
    
    else {
      drop { }
    }

  }
  }
  output {
      elasticsearch {
          hosts => ["192.168.128.131:9200"]
          # es 地址
          index => "logstash-%{[fields][gpcskin_type]}-%{+YYYY.MM.dd}"
          #   存储在es里的索引名字
      }
  }

  ```




  # 4. filebeat安装配置
  1. 在服务器上下载filebeat安装文件,解压即可.
  ```
  wget -c https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.0.0-linux-x86_64.tar.gz
  tar zxf filebeat-7.0.0-linux-x86_64.tar.gz
  # 开启IP转发
  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
  sysctl -p
  ```
  2. 切换到安装目录下执行 filebeat -e -c filebeat.yml
  3. 常用命令集
  ```yml
  filebeat test config 测试配置文件
  ```
  4. filebeat.yml配置文件如下

    ```yml
    filebeat.config.inputs:     # 输入模块
      enabled: true     #开启监控
      path: /opt/soft/filebeat-7.0.0-linux-x86_64/config/*.yml    #此目录下的所有输入规则
      reload.enabled: true      # 自动重新加载规则
      reload.period: 10s      # 检测规则时间

    filebeat.config.modules:
      index.number_of_shards: 1   # 设置一个索引的碎片数量

    setup.kibana:   # kibana配置
    output.logstash:  # logstash配置,有多个会进行分配
      hosts: ["192.168.128.129:5044"]
      # hosts: ["192.168.128.129:5044","192.168.128.139:5044"]
      loadbalance: true   # 开启logstash负载均横
      compression_level: 6    # 数据压缩级别

    processors:   # 将事件发送到配置的输出之前处理事件
        #  - add_host_metadata:
        #  - add_cloud_metadata:
    logging.level: warning    # filebeat本身日志输出级别
    logging.to_files: true    # 将日志写入文件
    logging.files:
      path: /var/log/filebeat
      name: filebeat
      keepfiles: 7
      permissions: 0644
    ```

5. 新建一个config目录,只写输入规则内容:

    ```yml
    
    - type: log   # 指定输入类型,log(默认)或者stdin
      enabled: true # 开启输入监控
      paths:  # 路径,可列多个
        - /tmp/nginx_logs/*.log   # 日志路径
      fields:     # 自定义字段将其添加到输出
        gpcskin_type: nginx_access
    - type: log
      enabled: true
      paths:
        - /var/log/messages*
        - /var/log/secure*
        - /var/log/cron*
      fields:
        gpcskin_type: syslog
    ```

# 5. 扩展配置

##### 1. kibana 用户认证
  * 安装nginx（略)
  * 安装密码生成工具
  ```bash
  yum install httpd-tools
  mkdir -p /opt/soft/kibana-7.0.0-linux-x86_64/nginx_passwd
  # 用户名 mzjadmin 密码123456 自行更改
  htpasswd -c -b /opt/soft/kibana-7.0.0-linux-x86_64/nginx_passwd/kibana.passwd mzjadmin 123456
  ```
  * 增加nginx配置文件
  ```nginx
server {
        listen       80;
        server_name  kibana.abc.com;

        location / {
            auth_basic "kibana login auth";
            auth_basic_user_file /opt/soft/kibana-7.0.0-linux-x86_64/nginx_passwd/kibana.passwd;
            proxy_pass http://127.0.0.1:5601;
            proxy_redirect off;
        }
    }
  ```
  * 修改kibana配置文件,为安全修改监听地址为本机
  ```
  server.host: "127.0.0.1"
  ```
  * 本机hosts文件绑定kibana.abc.com域名
  ```
  192.168.128.128 kibana.abc.com
  ```
  * 启动kibana和nginx,使用域名http://kibana.abc.com 访问
  * 需要更精准的日志角色权限控制,可以使用X-Pack插件(要钱钱)
##### 2. kibana https双向证书
  * 请自行在nginx和本机导入证书,确保无证书者不能访问
  * 配置好证书后使用https://kibana.abc.com
  * 以下为双向证书生成脚本
  
  ```bash
  #!/bin/sh
  #服务端证书制作
  read -p "Enter your domain [www.example.com]: " DOMAIN
  echo "Create server key..."
  openssl genrsa -des3 -out $DOMAIN.key 1024
  echo "Create server certificate signing request..."
  SUBJECT="/C=US/ST=Mars/L=iTranswarp/O=iTranswarp/OU=iTranswarp/CN=$DOMAIN"
  openssl req -new -subj $SUBJECT -key $DOMAIN.key -out $DOMAIN.csr
  echo "Remove password..."
  mv $DOMAIN.key $DOMAIN.origin.key
  openssl rsa -in $DOMAIN.origin.key -out $DOMAIN.key
  echo "Sign SSL certificate..."
  openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
  #客户端证书制作
  openssl genrsa -des3 -out $DOMAIN.client.key 1024
  echo "Create server certificate signing request..."
  SUBJECT="/C=US/ST=Mars/L=iTranswarp/O=iTranswarp/OU=iTranswarp/CN=$DOMAIN"
  openssl req -new -subj $SUBJECT -key $DOMAIN.client.key -out $DOMAIN.client.csr
  echo "Remove password..."
  mv $DOMAIN.client.key $DOMAIN.origin.client.key
  openssl rsa -in $DOMAIN.origin.client.key -out $DOMAIN.client.key
  echo "Sign SSL certificate..."
  openssl x509 -req -days 3650 -in $DOMAIN.client.csr -signkey $DOMAIN.client.key -out $DOMAIN.client.crt
  openssl pkcs12 -export -clcerts -in $DOMAIN.client.crt -inkey $DOMAIN.client.key -out $DOMAIN.client.p12
  #删除多余文件
  rm -rf $DOMAIN.client.csr $DOMAIN.client.key $DOMAIN.origin.client.key $DOMAIN.origin.key $DOMAIN.csr
  echo "TODO:
        Copy $DOMAIN.crt to /opt/soft/nginx/ssl/$DOMAIN.crt
        Copy $DOMAIN.key to /opt/soft/nginx/ssl/$DOMAIN.key
        Copy $DOMAIN.client.crt to /opt/soft/nginx/ssl/$DOMAIN.client.crt
        Add configuration in nginx:
        server {
            ...
            listen 443;
            ssl on;
            ssl_verify_client on;
            ssl_certificate     /opt/soft/nginx/ssl/$DOMAIN.crt;
            ssl_certificate_key /opt/soft/nginx/ssl/$DOMAIN.key;
            ssl_client_certificate /opt/soft/nginx/ssl/$DOMAIN.client.crt;
            ssl_protocols           SSLv2 SSLv3 TLSv1;
        }
"
  ```


##### 3. kibana 日志报警
  * 报警插件 sentinl 安装
  官方暂时还未提供 7.x 以上版本的 sentinl,有更新之后再补充此文档




# 6. 相关附件

#### 1. elasticsearch_install.sh脚本

