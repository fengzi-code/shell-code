#!/bin/bash

#Zabbix

ZBD_USER=zabbix
ZDB_PSW=123456
Z_VER=4.2.1
Z_SOFT=zabbix-$Z_VER.tar.gz
# Z_URL=http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/$Z_VER/$Z_SOFT
Z_URL=http://jaist.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$Z_VER/$Z_SOFT
Z_ARGS="--enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 --enable-java"
Z_DIR="/usr/local/zabbix"
Z_SERVER=$Z_DIR/sbin/zabbix_server
Ip_add=$(ip a | grep "global" | awk '{print $2}' | awk -F"/" '{print $1}')
#----------------------------------------------------------------------------------------------------------------

function install_zabbix_server() {
    if [[ -f $Z_SERVER ]]; then
        echo -e "\033[33m您已安装过zabbix_server,请卸载后重试！\033[0m"
        exit 0
    fi

    java_dir=$(echo $JAVA_HOME)
    if [ -z $java_dir ]; then
        echo '未安装java环境'
        exit
    fi

    # 启动mysql
    . /etc/profile
    netstat -tnlp | grep 3306
    if [[ $? -eq 0 ]]; then
        echo -e "\mysqld已启动！\033[0m"
    else
        systemctl start mysqld
    fi

    yum -y install wget libevent-devel net-snmp-devel libxml2-devel libcurl-deve libevent libevent-devel gcc gcc-c++
    if [[ ! -f $Z_SOFT ]]; then
        wget -c $Z_URL
    fi

    tar -xf $Z_SOFT
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mzabbix-${Z_VER}解压失败，请检查文件是否存在！\033[0m"
        exit 1
    fi

    cd zabbix-$Z_VER

    grep "zabbix" /etc/group

    if [[ $? -ne 0 ]]; then
        groupadd zabbix
        useradd -g zabbix zabbix
        usermod -s /sbin/nologin zabbix
    fi

    #创建zabbix数据库;

    $Mysql_dir/bin/mysql -u$DB_USER -p$DB_PSW -e "use zabbix;"
    if [[ $? -ne 0 ]]; then
        $Mysql_dir/bin/mysql -u$DB_USER -p$DB_PSW -e "create database zabbix charset=utf8;"
    fi

    #给zabbix数据库授权给zabbix用户;
    $Mysql_dir/bin/mysql -u$DB_USER -p$DB_PSW -e "grant all on zabbix.* to zabbix@'%' identified by '$ZDB_PSW'"
    $Mysql_dir/bin/mysql -u$DB_USER -p$DB_PSW -e "grant all on zabbix.* to zabbix@'localhost' identified by '$ZDB_PSW'"
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31m数据库授权失败！\033[0m"
        exit 1
    fi
    #导入zabbix数据到数据库;
    $Mysql_dir/bin/mysql -u$ZBD_USER -p$ZDB_PSW zabbix <database/mysql/schema.sql
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mschema数据库导入失败，请检查数据库用户名是否正确！\033[0m"
        exit 1
    fi

    $Mysql_dir/bin/mysql -u$ZBD_USER -p$ZDB_PSW zabbix <database/mysql/images.sql
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mimages数据库导入失败，请检查数据库用户名是否正确！\033[0m"
        exit 1
    fi

    $Mysql_dir/bin/mysql -u$ZBD_USER -p$ZDB_PSW zabbix <database/mysql/data.sql
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mdata数据库导入失败，请检查数据文件是否存在以及用户名是否正确！\033[0m"
        exit 1
    fi

    #预编译zabbix-server;
    ./configure --prefix=${Z_DIR} ${Z_ARGS}
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mzabbix-${Z_VER}预编译失败！\033[0m"
        exit 1
    fi

    make && make install
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mzabbix-${Z_VER}编译安装失败！\033[0m"
        exit 1
    fi

    ln -s $Z_DIR/sbin/zabbix_* /usr/local/sbin/

    #Zabbix server安装完毕,
    cd ${Z_DIR}/etc/
    cp zabbix_server.conf zabbix_server.conf.bak
    #------修改zabbix_server配置文件如下：--------------------------
    #LogFile=/tmp/zabbix_server.log 默认无需更改

    #DBHost=localhost 将默认localhost改成：127.0.0.1
    sed -i 's/# DBHost=localhost/DBHost=127.0.0.1/g' $Z_DIR/etc/zabbix_server.conf
    #DBName=zabbix  默认为zabbix 无需更改
    #DBUser=zabbix  默认为zabbix 无需更改

    #DBPassword=    更改密码为:123456 
    sed -i "s/# DBPassword=/DBPassword=$ZDB_PSW/g" $Z_DIR/etc/zabbix_server.conf
    #--------------------------------------------------------------

    #同时cp zabbix_server启动脚本至/etc/init.d/目录，启动zabbix_server, Zabbix_server默认监听端口为10051。
    cd -
    #cd  zabbix-$Z_VER
    cp misc/init.d/tru64/zabbix_server /etc/init.d/zabbix_server
    chmod o+x /etc/init.d/zabbix_server

    #安装zabbix-WEB端
    rm -rf $N_DIR/html/*
    cp -a frontends/php/* $N_DIR/html/
    chmod 757 $N_DIR/html/conf

    #修改php.ini配置文件
    #修改时区;
    sed -i '/date.timezone/i date.timezone = PRC' $Php_dir/php.ini
    sed -i 's/post_max_size = 8M/post_max_size = 16M/' $Php_dir/php.ini
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' $Php_dir/php.ini
    sed -i 's/max_input_time = 60/max_input_time = 300/' $Php_dir/php.ini

    #重启zabbix
    ln -s $Mysql_dir/lib/libmysqlclient.so.20 /usr/lib/
    ldconfig
    /etc/init.d/zabbix_server restart

    sleep 10s

    netstat -tnlp | grep 10051
    if [[ $? -eq 0 ]]; then
        echo -e "\033[32mzabbix-${Z_VER}服务端安装成功,zabbix数据库密码是:${ZDB_PSW} 请登录WEB端进行安装配置！\033[0m"

    fi

}

function install_zabbix_agent() {
    yum install gcc gcc-c++ pcre pcre-devel wget tar -y
    sleep 3s
    if [[ ! -f $Z_SOFT ]]; then
        wget -c $Z_URL
    fi

    grep "zabbix" /etc/group

    if [[ $? -ne 0 ]]; then
        groupadd zabbix
        useradd -g zabbix zabbix
        usermod -s /sbin/nologin zabbix
    fi

    tar -xf $Z_SOFT
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mzabbix-${Z_VER}解压失败，请检查文件是否存在！\033[0m"
        exit 1
    fi

    cd zabbix-$Z_VER

    ./configure --prefix=${Z_DIR} --enable-agent
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mzabbix-Agent-预编译失败！\033[0m"
        exit 1
    fi

    make && make install
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31mzabbix-Agent编译安装失败！\033[0m"
        exit 1
    fi

    sed -i 's/Hostname=Zabbix server/Hostname=127.0.0.1/' $Z_DIR/etc/zabbix_agentd.conf

    ln -s $Z_DIR/sbin/zabbix_* /usr/local/sbin/

    #拷贝zabbix_Agent启动文件
    cp misc/init.d/tru64/zabbix_agentd /etc/init.d/zabbix_agentd

    chmod o+x /etc/init.d/zabbix_agentd

    /etc/init.d/zabbix_agentd start

    ps -ef | grep zabbix_agent

    echo -e "\033[33m请手工修改Agent端配置文件：/usr/local/zabbix/etc/zabbix_agentd.conf
    LogFile=/tmp/zabbix_agentd.log   (默认无需修改)
    Server=127.0.0.1                （zabbix_server端IP地址）       
    ServerActive=127.0.0.1          （zabbix_server端IP地址）
    Hostname = 127.0.0.1            （Agent端IP地址）
    其他保持默认即可！\033[0m"
}

function install_zabbix_nginx_conf() {
    # zabbix_nginx 配置文件
    mkdir -p /var/log/nginx
    cat >/etc/nginx/conf.d/zabbix.conf <<EOF
server {
    listen       80;
    server_name  $Ip_add;
    index index.html index.htm index.php;
    root $N_DIR/html/;
    access_log  /var/log/nginx/zabbix_access.log;
    error_log   /var/log/nginx/zabbix_error.log;
    error_page   500 502 503 504  /50x.html;

     location ~ \.php$ {
       fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $N_DIR/html/\$fastcgi_script_name;

        }
        location ~ /\.ht {
                deny  all;
        }

}
EOF

}
z_pwd=$(pwd)
# 安装mysql
chmod a+x ./*.sh
netstat -tnlp | grep 3306
if [[ $? -eq 0 ]]; then
    echo -e "\mysqld已启动！\033[0m"
else
    cd $z_pwd && . ./mysql-src.sh
fi

cd $z_pwd && . ./php_7.x_install.sh

cd $z_pwd && . ./nginx_install.sh
# 调用各脚本中的变量
DB_USER=$mysql_USER
DB_PSW=$mysql_PSW
Mysql_dir=$basedir
Php_dir=$php_ini
N_DIR=$nginx_dir/nginx

cd $z_pwd
install_zabbix_server
install_zabbix_nginx_conf
systemctl restart nginx
systemctl restart php-fpm


# 复制本地电脑C:\Windows\Fonts\simkai.ttf（楷体）上传到zabbix服务器网站目录的fonts目录下/usr/local/nginx/html/fonts/
# mv DejaVuSans.ttf DejaVuSans.ttf.bak
# mv SIMKAI.TTF DejaVuSans.ttf