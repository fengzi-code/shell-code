#!/bin/bash
#请提前安装好jdk
es_version="7.0.0"
# 如下载地址不带后缀可留空
es_ver_end='-linux-x86_64'
install_dir=/opt/soft
es_CONF=$install_dir/elasticsearch-$es_version/config
Source_dir=$install_dir/Source_code/es
down_url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$es_version$es_ver_end.tar.gz"
#cluster.name ，集群的名称标识将会被用于群集的自动发现。如果在同一个网络上的正在运行多个群集，则需要确保该集群的所有节点上使用的是相同的名称。
cluster_name='es_jiquan'
#node.name: node-1  节点名称
node_name='node-1'
#node.master ，允许此节点可以作为主节点（默认启用）。
node_master='true'
#node.data ， 允许此节点可以用来存储数据（默认启用）。
node_data='true'
#path.data ， 索引数据存储的路径，可以配置多个位置
path_data='/data/es_data'
#path.logs ， 日志文件路径
path_logs='/data/es_logs'
#discovery.zen.ping.unicast.hosts ， 集群的初始清单
ipdz=$(ifconfig | grep broadcast|awk '{print $2}'|head -n 1)
discovery_zen_ping_unicast_hosts=$ipdz
network_host=$ipdz
http_port='9200'
transport_tcp_port='9300'
javahome=$(echo $JAVA_HOME)
if [ -z $javahome ]; then
    echo 'jdk未安装或未设置全局环境变量'
    exit
fi
id es
if [ $? -ne 0 ]; then
    useradd -s /sbin/nologin -M es
fi
mkdir -p $Source_dir
mkdir -p $path_data
mkdir -p $path_logs
chown es:es -R $path_data
chown es:es -R $path_logs
yum install wget -y

if [ -f $Source_dir/elasticsearch-$es_version$es_ver_end.tar.gz ]; then
    echo '文件已存在'
else
    wget $down_url -P $Source_dir
fi

tar xzvf $Source_dir/elasticsearch-$es_version$es_ver_end.tar.gz -C $install_dir
chown es:es -R $install_dir
#-----------------添加启动项-----------------------
cat >/etc/init.d/elasticsearch <<'EOF'
#!/bin/bash
#chkconfig: 2345 80 05
#description: es
export JAVA_HOME=java_home1
export JAVA_BIN=java_home2
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH
case $1 in
start)
#下面的“<<!”是切换用户后，待执行的命令，执行完后使用“!”来进行结束
    su -s /bin/bash es<<!
    elasticsearch -d
exit
!
#上面的“!”是以上面的对应起来，并且顶格放置，这是语法
    echo "es startup"
    ;;
stop)
    es_pid=`ps aux|grep elasticsearch | grep -v 'grep elasticsearch' | awk '{print $2}'`
    kill -9 $es_pid
    echo "es stopup"
    ;;
restart)
    es_pid=`ps aux|grep elasticsearch | grep -v 'grep elasticsearch' | awk '{print $2}'`
    kill -9 $es_pid
    echo "es stopup"
    sleep 1
    su -s /bin/bash es<<!
    elasticsearch -d
!
    echo "es startup"
    ;;
*)
    echo "start|stop|restart"
    ;;
esac
EOF
#-----------------添加启动项-----------------------
#. /etc/init.d/functions
sed -i "s#java_home1#$javahome#" /etc/init.d/elasticsearch
sed -i "s#java_home2#$javahome/bin#" /etc/init.d/elasticsearch
sed -i "s#elasticsearch -d#$install_dir/elasticsearch-$es_version/bin/elasticsearch -d#" /etc/init.d/elasticsearch
echo 'vm.max_map_count=655360' >>/etc/sysctl.conf
sysctl -p
chmod u+x /etc/init.d/elasticsearch
chkconfig --add elasticsearch
echo "
cluster.name: $cluster_name
node.master: $node_master
node.data: $node_data
#node.ingest: true
node.name: $node_name
path.data: $path_data
#path.repo: [\"/opt/mzjbackup\"]
path.logs: $path_logs
network.host: $network_host
http.port: $http_port
discovery.zen.ping.unicast.hosts: [\"$network_host\"]
#gateway.recover_after_nodes: 1
transport.tcp.port: $transport_tcp_port
#http.cors.enabled: true
#http.cors.allow-origin: \"*\"
" >>$es_CONF/elasticsearch.yml
#关闭整个集群
#curl -XPOST http://localhost:9200/_cluster/nodes/_shutdown -u elastic
#关闭单个节点
#curl -XPOST  http://127.0.0.1:9200/_cluster/nodes/2ens0yuEQ12G6ct1UDpihQ/_shutdown -u elastic
#健康状态检查 http://127.0.0.1:9200/_cluster/health
echo "
elasticsearch 启动命令
service elasticsearch start
"
#------------------------head插件----------------------------------------------
# 不建议安装,可使用谷歌浏览器插件 ElasticSearch Head
es_head_install() {
    nodejs_ver='9.9.0'
    nodejs_dir='/opt/soft'
    nodejs_Source_dir=$nodejs_dir/Source_code/node_js
    nodejs_down_url="https://nodejs.org/dist/v$nodejs_ver/node-v$nodejs_ver-linux-x64.tar.xz"
    wget $nodejs_down_url -P $nodejs_Source_dir
    mkdir -p $nodejs_Source_dir
    cd $nodejs_Source_dir
    xz -d node-v$nodejs_ver-linux-x64.tar.xz
    tar xvf $nodejs_Source_dir/node-v$nodejs_ver-linux-x64.tar -C $install_dir
    echo "
export NODE_HOME=$install_dir/node-v$nodejs_ver-linux-x64
export PATH=\$PATH:\$NODE_HOME/bin
export NODE_PATH=\$NODE_HOME/lib/node_modules
    " >>/etc/profile
    . /etc/profile
    wget https://github.com/mobz/elasticsearch-head/archive/master.zip
    yum clean all
    yum -y install unzip
    mv master.zip $nodejs_dir
    cd $nodejs_dir
    unzip master.zip
    cd elasticsearch-head-master
    npm install
    npm install phantomjs-prebuilt@ --ignore-scripts
    #npm run start
    echo "
http.cors.enabled: true
http.cors.allow-origin: \"*\"
    " >>$es_CONF/elasticsearch.yml
    #nohup npm run start &
}
echo -e "\033[44;30m 是否安装head插件,确认按y，退出按其他键 \033[0m \c"
read confirm
if [ $confirm = 'y' ]; then
    es_head_install
    echo "
请用以下命令刷新一下环境变量
. /etc/profile
elasticsearch 启动命令
service elasticsearch start
elasticsearch-head 启动命令
cd $nodejs_dir/elasticsearch-head-master && nohup npm run start &
    "
fi

es_ver_1=$(echo $es_version | cut -d'.' -f1)
if [ $es_ver_1 -gt 6 ]; then
    echo "
cluster.initial_master_nodes: ["$node_name"]
" >>$es_CONF/elasticsearch.yml
fi
echo 修改连接数
cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F) &&
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
" >/etc/security/limits.conf
#------------------------head插件----------------------------------------------
#修改jvm.options 的堆内存大小 -Xms1g -Xmx1g
#1、通俗的解释：
#     在Elasticsearch中，文档归属于一种类型(type),而这些类型存在于索引(index)中, 索引名称必须是小写
#     Relational DB -> Database(数据库) -> Table(表) -> Row(行记录) -> Column(字段)
#     Elasticsearch -> Indice(索引)   -> Type  -> Document -> Field

# 2、分片shards：
#     数据量特大，没有足够大的硬盘空间来一次性存储，且一次性搜索那么多的数据，响应跟不上es提供把数据进行分片存储，这样方便进行拓展和提高吞吐

# 3、副本replicas：
#     分片的拷贝，当主分片不可用的时候，副本就充当主分片进行使用

# 4、Elasticsearch中的每个索引分配5个主分片和1个副本
# 如果你的集群中至少有两个节点，你的索引将会有5个主分片和另外5个复制分片（1个完全拷贝），这样每个索引总共就有10个分片。