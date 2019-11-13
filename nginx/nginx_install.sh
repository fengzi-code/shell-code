#!/bin/bash
set -e
nginxversion="1.13.9"
nginx_dir=/usr/local
nginx_conf_path=$nginx_dir/nginx/nginx.conf
nginx_url=http://nginx.org/download/nginx-$nginxversion.tar.gz
if [ ! -d $nginx_dir ];then
    mkdir -p $nginx_dir
fi
cd $nginx_dir
yum -y install pcre pcre-devel zlib zlib-devel gcc gcc-c++ autoconf automake make openssl-devel wget
useradd -s /sbin/nologin -M nginx
mkdir -p /etc/nginx/conf.d /etc/nginx/default.d
chown nginx:nginx -R /etc/nginx
if [ ! -e "$nginx_dir/nginx-$nginxversion.tar.gz" ];then
    wget -c $nginx_url
else
    echo "文件已经存在"
    if [ -d "$nginx_dir/nginx-$nginxversion" ];then
        rm -rf $nginx_dir/nginx-$nginxversion
    fi
fi
tar -zxf nginx-$nginxversion.tar.gz
cd $nginx_dir/nginx-$nginxversion
./configure --prefix=$nginx_dir/nginx --user=nginx --group=nginx --with-http_stub_status_module --with-http_ssl_module --with-http_realip_module --with-http_sub_module --with-http_gzip_static_module --with-ipv6 --conf-path=$nginx_conf_path 
# --add-module=/opt/headers-more-nginx-module-0.33
sleep 1
make -j$(cat /proc/cpuinfo | grep "cpu cores" |awk '{print $4}'|head -1) && make install
sleep 1
#-------------------------启动脚本----------------------------------------------------

fun_6_service (){
echo '#! /bin/bash
# chkconfig: - 85 15
DESC="nginx daemon"
NAME=nginx
DAEMON=$PATH/sbin/$NAME
#CONFIGFILE=/etc/nginx/$NAME.conf
PIDFILE=$PATH/logs/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME
set -e
[ -x "$DAEMON" ] || exit 0
do_start() {
$DAEMON -c $CONFIGFILE || echo -n "nginx already running"
}
do_stop() {
$DAEMON -s stop || echo -n "nginx not running"
}
do_reload() {
$DAEMON -s reload || echo -n "nginx can’t reload"
}
case "$1" in
start)
echo -n "Starting $DESC: $NAME"
do_start
echo "."
;;
stop)
echo -n "Stopping $DESC: $NAME"
do_stop
echo "."
;;
reload|graceful)
echo -n "Reloading $DESC configuration..."
do_reload
echo "."
;;
restart)
echo -n "Restarting $DESC: $NAME"
do_stop
do_start
echo "."
;;
*)
echo "Usage: $SCRIPTNAME {start|stop|reload|restart}" >&2
exit 3
;;
esac
exit 0' > /etc/init.d/nginx
}

#-------------------------启动脚本----------------------------------------------------

echo "PATH=\$PATH:$nginx_dir/nginx/sbin" >> /etc/profile
# 在匹配行后加入一行
sed -i '/http {/a\    include \/etc\/nginx\/conf.d\/*.conf;' ${nginx_conf_path}
source /etc/profile

os_ver=`cat /etc/redhat-release|grep -Po '[0-9]'|head -1`

if [ ${os_ver} == '7' ];then
    cat > /usr/lib/systemd/system/nginx.service << EOF
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=${nginx_dir}/nginx/logs/nginx.pid
ExecStartPre=${nginx_dir}/nginx/sbin/nginx -t
ExecStart=${nginx_dir}/nginx/sbin/nginx -c ${nginx_conf_path}
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable nginx
    # systemctl start nginx
else
	fun_6_service
    sed -i 'N;2aPATH='$nginx_dir'/nginx' /etc/init.d/nginx
	sed -i 'N;2aCONFIGFILE='$nginx_conf_path'' /etc/init.d/nginx
	chmod +x /etc/init.d/nginx
	chkconfig --add nginx
	chkconfig --level 345 nginx on
	#service nginx start
fi



echo "nginx 安装完毕~~~~~"


# '''active connections – 活跃的连接数量
# server accepts handled requests — 总共处理了xxx个连接 , 成功创建xxx次握手, 总共处理了xxx个请求
# reading — 读取客户端的连接数.
# writing — 响应数据到客户端的数量
# waiting — 开启 keep-alive 的情况下,这个值等于 active – (reading+writing), 意思就是 Nginx 已经处理完正在等候下一次请求指令的驻留连接.



#     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
#                       '$status $body_bytes_sent "$http_referer" '
#                       '"$http_user_agent" "$http_x_forwarded_for" "$host" '
#                       '"$upstream_addr" $upstream_status $upstream_response_time $request_time';




# $remote_addr, $http_x_forwarded_for 记录客户端IP地址
# $remote_user 记录客户端用户名称
# $request 记录请求的URL和HTTP协议
# $status 记录请求状态
# $body_bytes_sent 发送给客户端的字节数，不包括响应头的大小； 该变量与Apache模块mod_log_config里的“%B”参数兼容。
# $bytes_sent 发送给客户端的总字节数。
# $connection 连接的序列号。
# $connection_requests 当前通过一个连接获得的请求数量。
# $msec 日志写入时间。单位为秒，精度是毫秒。
# $pipe 如果请求是通过HTTP流水线(pipelined)发送，pipe值为“p”，否则为“.”。
# $http_referer 记录从哪个页面链接访问过来的
# $http_user_agent 记录客户端浏览器相关信息
# $request_length 请求的长度（包括请求行，请求头和请求正文）。
# $request_time 请求处理时间，单位为秒，精度毫秒； 从读入客户端的第一个字节开始，直到把最后一个字符发送给客户端后进行日志写入为止。
# $time_iso8601 ISO8601标准格式下的本地时间。
# $time_local 通用日志格式下的本地时间。

# 1、轮询是upstream的默认分配方式，即每个请求按照时间顺序轮流分配到不同的后端服务器，如果某个后端服务器down掉后，能自动剔除。

# 2、weight 轮询的加强版，即可以指定轮询比率，weight和访问几率成正比，主要应用于后端服务器异质的场景下。

# 3、ip_hash 每个请求按照访问ip（即Nginx的前置服务器或者客户端IP）的hash结果分配，这样每个访客会固定访问一个后端服务器，可以解决session一致问题。

# 4、fair fair顾名思义，公平地按照后端服务器的响应时间（rt）来分配请求，响应时间短即rt小的后端服务器优先分配请求。
# 5、url_hash 与ip_hash类似，但是按照访问url的hash结果来分配请求，使得每个url定向到同一个后端服务器，主要应用于后端服务器为缓存时的场景下。
# '''