#!/bin/bash

set -e
phpversion="7.2.13"
php_pwd=/usr/local
php_ini=/etc
mkdir -p  $php_pwd/php
mkdir -p $php_pwd/Source_code

yum install wget -y
wget -c "http://www.php.net/distributions/php-$phpversion.tar.gz" -P $php_pwd/Source_code/
cd $php_pwd/Source_code
tar -zxvf php-$phpversion.tar.gz
if [ -d "$php_pwd/Source_code/php-$phpversion" ];then
    echo "php源码包解压成功"
else
    echo "php源码包解压失败！！！"
    exit 1
fi
cd $php_pwd/Source_code/php-$phpversion
echo "安装依赖包"
sleep 1
yum -y install gcc gcc-c++ libxml2 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel libzip libzip-devel openldap openldap-devel wget
# 解决 ldap 错误
cp -frp /usr/lib64/libldap* /usr/lib/
useradd -s /sbin/nologin -M www
echo "配置php"
sleep 1
cd $php_pwd/Source_code/php-$phpversion
./configure --prefix=$php_pwd/php --with-config-file-path=/etc --with-mysql-sock=/tmp/mysql.sock --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-inline-optimization --disable-debug --disable-rpath --enable-shared --enable-soap --with-libxml-dir --with-xmlrpc --with-openssl --with-mhash --with-pcre-regex --with-sqlite3 --with-zlib --enable-bcmath --with-iconv --with-bz2 --enable-calendar --with-curl --with-cdb --enable-dom --enable-exif --enable-fileinfo --enable-filter --with-pcre-dir --enable-ftp --with-gd --with-openssl-dir --with-jpeg-dir --with-png-dir --with-zlib-dir --with-freetype-dir  --with-gettext --with-gmp --with-mhash --enable-json --enable-mbstring --enable-mbregex --enable-mbregex-backtrack --with-libmbfl --with-onig --enable-pdo --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-zlib-dir --with-pdo-sqlite --with-readline --enable-session --enable-shmop --enable-simplexml --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --enable-wddx --with-libxml-dir --with-xsl --enable-zip --enable-mysqlnd-compression-support --with-pear --enable-opcache --with-ldap

sleep 1
-lcrypto -lcrypt
# 添加 ldap 相关参数
sed -i 's/-lcrypto -lcrypt/-lcrypto -lcrypt -llber/' $php_pwd/Source_code/php-$phpversion/Makefile
make -j$(cat /proc/cpuinfo | grep "cpu cores" |awk '{print $4}'|head -1) && make install

sleep 1

echo "export PATH=$php_pwd/php/bin:\$PATH" >> /etc/profile
source /etc/profile
cp php.ini-production $php_ini/php.ini
cp $php_pwd/php/etc/php-fpm.conf.default $php_pwd/php/etc/php-fpm.conf
cp $php_pwd/php/etc/php-fpm.d/www.conf.default $php_pwd/php/etc/php-fpm.d/www.conf

sed -i '/;pid/a\pid = /var/run/php-fpm.pid' $php_pwd/php/etc/php-fpm.conf

os_ver=`cat /etc/redhat-release|grep -Po '[0-9]'|head -1`

if [ ${os_ver} == '7' ];then
    cat > /usr/lib/systemd/system/php-fpm.service << EOF
[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/var/run/php-fpm.pid
EnvironmentFile=-/etc/sysconfig/php-fpm
ExecStart=${php_pwd}/php/sbin/php-fpm
ExecReload=/bin/kill -USR2 \$MAINPID
ExecStop=/bin/kill -SIGINT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable php-fpm
    # systemctl start php-fpm
else
    cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod a+x /etc/init.d/php-fpm
    chkconfig --add php-fpm
    chkconfig --level 345 php-fpm on
    #service php-fpm start
fi



