#!/bin/bash
#适用于5.X

set -e
phpversion="5.6.30"
php_pwd=/usr/local
mkdir -p $php_pwd/php
mkdir -p $php_pwd/php/Source_code

wget -c "http://www.php.net/distributions/php-$phpversion.tar.gz" -P $php_pwd/Source_code/
cd $php_pwd/Source_code
tar -zxvf php-$phpversion.tar.gz
if [ -d "$php_pwd/Source_code/php-$phpversion" ]; then
    echo "php源码包解压成功"
else
    echo "php源码包解压失败！！！"
    exit 1
fi
cd $php_pwd/Source_code/php-$phpversion
echo "安装依赖包"
sleep 1
yum install -y libxml2 libxml2-devel openssl-devel libcurl-devel libjpeg-devel libpng-devel libicu-devel openldap-devel libmcrypt-devel freetype-devel gcc gcc-c++

# https://master.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
wget -c https://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz/download -O libmcrypt-2.5.8.tar.gz
tar zxvf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure
make && make install
export LD_LIBRARY_PATH=/lib/:/usr/lib/:/usr/local/lib

useradd -s /sbin/nologin -M www
echo "配置php"
sleep 1
cd $php_pwd/Source_code/php-$phpversion
./configure --prefix=$php_pwd/php --with-config-file-path=/etc --enable-mysqlnd --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir=/usr --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr/local/lib --enable-xml --disable-rpath --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt=/usr --with-gd --with-xmlrpc --with-gettext --enable-gd-native-ttf --with-openssl --with-mhash --enable-ftp --enable-intl --enable-bcmath --enable-exif --enable-soap --enable-shmop --enable-pcntl --disable-ipv6 --disable-debug --enable-sockets --enable-zip --enable-opcache --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-sockets --enable-calendar --enable-dom --with-libdir=lib64

sleep 1
make -j$(cat /proc/cpuinfo | grep "cpu cores" | awk '{print $4}' | head -1) && make install

sleep 1

echo "export PATH=$php_pwd/php/bin:\$PATH" >>/etc/profile
source /etc/profile
cp php.ini-production /etc/php.ini
cp $php_pwd/php/etc/php-fpm.conf.default $php_pwd/php/etc/php-fpm.conf

sed -i '/;pid/a\pid = /var/run/php-fpm.pid' $php_pwd/php/etc/php-fpm.conf

os_ver=$(cat /etc/redhat-release | grep -Po '[0-9]' | head -1)

if [ ${os_ver} == '7' ]; then
    cat >/usr/lib/systemd/system/php-fpm.service <<EOF
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
