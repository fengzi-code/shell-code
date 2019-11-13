#!/bin/bash
#

#---------apr---------------

set -e
fun_apr() {
	apr_basedir=/usr/local/apr
	yum -y install gcc gcc-c++ openssl-devel wget wget-devel expat-devel
	# yum -y install pcre pcre-devel apr apr-devel apr-util apr-util-devel expat-devel
	mkdir -p /tmp/apr ${apr_basedir}
	cd /tmp/apr
	wget -c http://ftp.jaist.ac.jp/pub/apache//apr/apr-1.7.0.tar.gz
	tar xf apr-1.7.0.tar.gz
	cd apr-1.7.0
	./configure --prefix=${apr_basedir}
	make && make install
	if [[ $? -ne 0 ]]; then
		echo -e "\033[031m失败！\033[0m"
		exit
	fi
	rm -rf /tmp/apr
}

#---------apr---------------

#---------apr-util---------------
fun_apr_util() {
	apr_util_basedir=/usr/local/apr-util
	mkdir -p /tmp/apr-util ${apr_util_basedir}
	cd /tmp/apr-util
	wget -c http://ftp.jaist.ac.jp/pub/apache//apr/apr-util-1.6.1.tar.gz
	tar zxvf apr-util-1.6.1.tar.gz
	cd apr-util-1.6.1
	./configure --prefix=${apr_util_basedir} --with-apr=${apr_basedir}
	make && make install
	if [[ $? -ne 0 ]]; then
		echo -e "\033[031m失败！\033[0m"
		exit
	fi
	rm -rf /tmp/apr-util
}
#---------pcre---------------
fun_pcre() {
	pcre_basedir=/usr/local/pcre
	mkdir -p /tmp/pcre ${pcre_basedir}
	cd /tmp/pcre
	wget -c https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
	tar zxvf pcre-8.43.tar.gz
	cd pcre-8.43
	./configure --prefix=${pcre_basedir}
	make && make install
	if [[ $? -ne 0 ]]; then
		echo -e "\033[031m失败！\033[0m"
		exit
	fi
	rm -rf /tmp/pcre
}

#---------pcre---------------

# step1: 安装apr
fun_apr
# step2: 安装apr_util
fun_apr_util
# step3: 安装fun_pcre
fun_pcre

#---------------------------

apache_version="2.4.37"
basedir=/usr/local/apache_${apache_version}
temp_dir=/tmp/httpd_${apache_version}
conf_path=${basedir}/conf/httpd.conf
# http://ftp.jaist.ac.jp/pub/apache//httpd/httpd-2.4.39.tar.gz
down_url=http://mirrors.hust.edu.cn/apache//httpd/httpd-${apache_version}.tar.gz
install_cmd="-with-apr=${apr_basedir} -with-apr-util=${apr_util_basedir} -with-pcre=${pcre_basedir} --enable-so --enable-ssl --enable-cgi --enable-rewrite --with-zlib --enable-deflate --enable-expires --enable-headers --enable-modules=most --enable-mpms-shared=all --with-mpm=worker --enable-speling"

# --with-pcre                          #支持perl的正则表达式，不然会报错
# --enable-so                          #激活apache服务的DSO
# --enable-ssl                         #基于ssl加密传输
# --enable-cgi                         #开启CGI脚本
# --enable-rewrite                     # 提供基于URL规则的重写功能
# --with-zlib                          #支持压缩
# --enable-deflate                     #提供对内容的压缩传输编码支持，
# --enable-expires                     # 允许通过配置文件控制HTTP的Expires:和Cache-Control:头内容,对网站图片、js、css等内容，提供在客户端游览器缓存的设置
# --enable-headers                     #提供允许对HTTP请求头的控制
# --enable-modules=most                #支持大多数模块
# --enable-mpms-shared=all             #mpm模块的动态切换
# --with-mpm=worker                    #选择apache mpm的模式为worker模式
# --enable-speling                     #忽略URL大小写

if [ ! -d $basedir ]; then
	mkdir -p $basedir
fi
mkdir -p $temp_dir
cd $temp_dir

useradd -s /sbin/nologin -M apache

chown apache:apache -R $basedir
if [ ! -e "$temp_dir/httpd-${apache_version}.tar.gz" ]; then
	wget -c $down_url
else
	echo "文件已经存在"
	rm -rf ${basedir} $temp_dir/httpd-${apache_version}

fi
tar -zxvf httpd-${apache_version}.tar.gz
cd $temp_dir/httpd-${apache_version}

echo "./configure --prefix=$basedir ${install_cmd}"
./configure --prefix=$basedir ${install_cmd}

sleep 1
make -j$(cat /proc/cpuinfo | grep "cpu cores" | awk '{print $4}' | head -1) && make install
if [[ $? -ne 0 ]]; then
	echo -e "\033[031m失败！\033[0m"
	exit
fi
sleep 1
echo 'ServerName localhost:80' >>${conf_path}

#-------------------------启动脚本----------------------------------------------------
#https://blog.csdn.net/yuesichiu/article/details/51485147

# [Unit]  #<==启动顺序与依赖关系
# Description=The Apache HTTP Server #<==Description当前服务的简单描述
# After=network.target remote-fs.target nss-lookup.target	#<==服务启动顺序,在此三服务之后启动
#
#
# #Wants=sshd-keygen.service #<==弱依赖服务,表示httpd启动失败或停止不影响sshd服务继续执行
# Requiress=sshd-keygen.service #<==强依赖服务,httpd启动失败或异常退出，那么sshd.service也必须退出。
# Wants字段与Requires字段只涉及依赖关系，与启动顺序无关，默认情况下是同时启动的。
#
#
# Documentation=man:httpd(8)	#<==给出文档位置
# Documentation=man:apachectl(8)	#<==给出文档位置

# [Service]	#<==启动行为
# Type=notify #<==服务类型，可选有forking、notify、simple等
#
# -----------------------------------------------------------
# simple（默认值）：ExecStart字段启动的进程为主进程
# forking：以fork方式启动，此时父进程将会退出，子进程将成为主进程（后台运行）
# oneshot：类似于simple，但只执行一次，Systemd 会等它执行完，才启动其他服务
# dbus：类似于simple，但会等待 D-Bus 信号后启动
# notify：类似于simple，启动结束后会发出通知信号，然后 Systemd 再启动其他服务
# idle：类似于simple，但是要等到其他任务都执行完，才会启动该服务。
# ------------------------------------------------------------
#
# EnvironmentFile=/etc/sysconfig/httpd #<==环境变量等的配置文件
# 所有的启动设置之前，都可以加上一个连词号（-），表示”抑制错误”，即发生错误的时候，不影响其他命令的执行。比如，EnvironmentFile=-/etc/sysconfig/httpd（注意等号后面的那个连词号），就表示即使/etc/sysconfig/httpd文件不存在，也不会抛出错误。
# ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND #<==定义启动进程时执行的命令,变量$OPTIONS就来自EnvironmentFile字段指定的环境参数文件,以下的变量也是
# ExecReload=/usr/sbin/httpd $OPTIONS -k graceful #<==重启服务时执行的命令
# ExecStop=/bin/kill -WINCH ${MAINPID} #<==停止服务时执行的命令,#此处的${MAINPID}为特殊变量，对应着相应服务的主进程ID
# #ExecStartPre字段：启动服务之前执行的命令
# #ExecStartPost字段：启动服务之后执行的命令
# #ExecStopPost字段：停止服务之后执行的命令
# KillSignal=SIGCONT
# PrivateTmp=true 临时目录独占
# -----------------------------------------------------------------
# KillMode=control-group  字段可以设置的值如下。
# control-group（默认值）：当前控制组里面的所有子进程，都会被杀掉
# process：只杀主进程
# mixed：主进程将收到 SIGTERM 信号，子进程收到 SIGKILL 信号
# none：没有进程会被杀掉，只是执行服务的 stop 命令。
# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
# Restart=no  字段可以设置的值如下。
#no（默认值）：退出后不会重启
#on-success：只有正常退出时（退出状态码为0），才会重启
#on-failure：非正常退出时（退出状态码非0），包括被信号终止和超时，才会重启
#on-abnormal：只有被信号终止和超时，才会重启
#on-abort：只有在收到没有捕捉到的信号终止时，才会重启
#on-watchdog：超时退出，才会重启
#always：不管是什么退出原因，总是重启
#-----------------------------------------------------------------
#
#RestartSec字段：表示 Systemd 重启服务之前，需要等待的秒数

# [Install]
# WantedBy=multi-user.target

echo '
#OPTIONS=
LANG=C
' >/etc/sysconfig/httpd

cat >/usr/lib/systemd/system/httpd.service <<EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=forking
EnvironmentFile=/etc/sysconfig/httpd
ExecStart=${basedir}/bin/httpd -k start
ExecReload=${basedir}/bin/httpd \$OPTIONS -k graceful
ExecStop=${basedir}/bin/httpd -k stop
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

#-------------------------启动脚本----------------------------------------------------

echo "PATH=\$PATH:$basedir/bin" >>/etc/profile
source /etc/profile
#systemctl start httpd.service
#查看编译参数 cat /usr/local/apache_2.4.3.7/build/config.nice
echo "apache 安装完毕~~~~~"

# # 监听端口
# Listen 80
# ---------------------------------------------
# #此选项主要用指定Apache服务的运行用户和用户组，默认为：daemon
# <IfModule unixd_module>
# User daemon
# Group daemon
# </IfModule>
# ---------------------------------------------

# ---------------------------------------------
# #此选项主要用指定Apache服务管理员通知邮箱地址，选择默认值
# ServerAdmin you@example.com
# ---------------------------------------------

# ---------------------------------------------
# #对用户对根目录下所有的访问权限控制，默认Apache对根目录访问都是拒绝访问
# <Directory />
#     AllowOverride none
#     Require all denied
# </Directory>
# ---------------------------------------------

# ---------------------------------------------
# #Apache网站默认发布目录
# DocumentRoot "/usr/local/apache_2.4.37/htdocs"
# #设置/usr/local/apache_2.4.37/htdocs目录权限
# <Directory "/usr/local/apache_2.4.37/htdocs">
#     Options Indexes FollowSymLinks
#     AllowOverride None
#     Require all granted
# </Directory>
# ---------------------------------------------

# ---------------------------------------------
# #Apache的默认首页设置
# <IfModule dir_module>
#     DirectoryIndex index.html
# </IfModule>
# ---------------------------------------------

# ---------------------------------------------
# #对.ht文件访问控制，默认为具有访问权限
# <Files ".ht*">
#     Require all denied
# </Files>
# ---------------------------------------------

# ---------------------------------------------
# #错误日志访问日志路径和格式化
# ErrorLog "logs/error_log"
# LogLevel warn
# <IfModule log_config_module>
#     LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
#     LogFormat "%h %l %u %t \"%r\" %>s %b" common
#     <IfModule logio_module>
#       # You need to enable mod_logio.c to use %I and %O
#       LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
#     </IfModule>
#     CustomLog "logs/access_log" common
# </IfModule>
# ---------------------------------------------

# ---------------------------------------------
# #URL重定向，别名，脚本别名等相关设置
# <IfModule alias_module>
#     ScriptAlias /cgi-bin/ "/usr/local/apache_2.4.37/cgi-bin/"
# </IfModule>
# <IfModule cgid_module>
# </IfModule>
# <Directory "/usr/local/apache_2.4.37/cgi-bin">
#     AllowOverride None
#     Options None
#     Require all granted
# </Directory>
# ---------------------------------------------

# <IfModule headers_module>
#     RequestHeader unset Proxy early
# </IfModule>
# <IfModule mime_module>
#     TypesConfig conf/mime.types
#     AddType application/x-compress .Z
#     AddType application/x-gzip .gz .tgz
# </IfModule>
# <IfModule proxy_html_module>
# Include conf/extra/proxy-html.conf
# </IfModule>
# <IfModule ssl_module>
# SSLRandomSeed startup builtin
# SSLRandomSeed connect builtin
# </IfModule>
# ServerName localhost:80
