#!/bin/bash

fun_confirm() {
    echo -e "\033[44;30m 确认按y，退出按其他键 \033[0m \c"
    read confirm
    if [ $confirm != 'y' ]; then
        echo "安装退出"
        exit
    fi
}

fun_env() {

    java_dir=$(echo $JAVA_HOME)

    if [ -z $java_dir ]; then
        echo '未安装java环境'
        exit
    fi

    mem=$(free -m | grep Mem | awk '{print $2}')
    if [ $mem -lt 1024 ]; then
        echo '内存检测出错或可用内存小于1G'
        exit
    fi

    dev_hd=$(df -m | grep -E '/$' | awk '{print $4}')
    if [ $dev_hd -lt 512 ]; then
        echo '可用空间小于512M'
        exit
    fi

    swap_size=$(free -m | grep Swap | awk '{print $2}')
    if [[ $swap_size -lt 512 ]] || [[ -z $swap_size ]]; then
        echo '交换空间小于512M,是否增加交换空间'
        fun_confirm
        echo '请稍候,增加交换空间中......'
        swap_dir=$(grep swap /etc/fstab | awk '{print $1}')
        if [ -n $swap_dir ]; then
            swapoff $swap_dir
            rm -rf $swap_dir
        fi
        sed -i "s?$swap_dir?#&?g" /etc/fstab
        #在前面加#号注释
        swap_dir='/var/swap'
        #-------------------增加交换分区----------------------

        dd if=/dev/zero of=$swap_dir bs=512 count=8388616
        mkswap $swap_dir
        swapon $swap_dir
        swapon -s
        #sed -i "s/vm.swappiness = 0/vm.swappiness = 10/g" /etc/sysctl.conf
        #0的时候表示最大限度使用物理内存
        echo "$swap_dir swap swap defaults 0 0" >>/etc/fstab
        sysctl -p
        #----------------------交换分区结束-----------------------------

    fi
    swap_size=$(free -m | grep Swap | awk '{print $2}')
    echo "java_home:" $java_dir
    echo '物理内存:' $mem
    echo '可用空间:' $dev_hd
    echo '可用交换分区:' $swap_size
    read -p "按回车键继续"
}

fun_install() {

    echo '
    [ENGINE]
    Response File Version=1.0.0.0.0
    [GENERIC]
    DECLINE_AUTO_UPDATES=true
    MOS_USERNAME=
    MOS_PASSWORD=<SECURE VALUE>
    AUTO_UPDATES_LOCATION=
    SOFTWARE_UPDATES_PROXY_SERVER=
    SOFTWARE_UPDATES_PROXY_PORT=
    SOFTWARE_UPDATES_PROXY_USER=
    SOFTWARE_UPDATES_PROXY_PASSWORD=<SECURE VALUE>
    ORACLE_HOME=/home/weblogic/Oracle/Middleware/Oracle_Home
    INSTALL_TYPE=WebLogic Server
    MYORACLESUPPORT_USERNAME=
    MYORACLESUPPORT_PASSWORD=<SECURE VALUE>
    DECLINE_SECURITY_UPDATES=true
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
    PROXY_HOST=
    PROXY_PORT=
    PROXY_USER=
    PROXY_PWD=<SECURE VALUE>
    COLLECTOR_SUPPORTHUB_URL=
    ' >/home/weblogic/wls.rsp

    echo '
    inventory_loc=/home/weblogic/oraInventory1
    #用户的组名称，根据实际的修改
    inst_group=weblogic
    ' >/home/weblogic/oraInst.loc

    chown -R weblogic:weblogic /home/weblogic

}

fun_create_domain() {

    mkdir -p /home/weblogic/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain
    chown -R weblogic:weblogic /home/weblogic

    cat >/home/weblogic/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain/demotest.py <<EOF
readTemplate("/home/weblogic/Oracle/Middleware/Oracle_Home/wlserver/common/templates/wls/wls.jar")

cd("Servers/AdminServer")

cmo.setName("AdminServer")

set("ListenAddress","")

set("ListenPort",7011)

cd("/Security/base_domain/User/weblogic")

cmo.setPassword("weblogic131")

setOption('OverwriteDomain', 'true')

setOption('ServerStartMode', 'prod');

writeDomain("/home/weblogic/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain")

closeTemplate()

exit()
EOF
}

exe_dir=$(pwd)

if [ $exe_dir != '/opt' ]; then
    echo '请将此脚本放至/opt目录下'
    exit
fi

fun_env

echo '请上传fmw_12.2.1.2.0_wls.jar文件至/opt'

read -p "按回车键继续"

groupadd weblogic
useradd -g weblogic weblogic
passwd weblogic

fun_install

su -s /bin/bash weblogic <<!
    java -jar /opt/fmw_12.2.1.2.0_wls.jar -silent -response /home/weblogic/wls.rsp -invPtrLoc /home/weblogic/oraInst.loc
!

su -s /bin/bash weblogic <<!
    /home/weblogic/Oracle/Middleware/Oracle_Home/wlserver/server/bin/setWLSEnv.sh
!

echo '是否创建域,按y创建,按其它键退出!'

fun_confirm

fun_create_domain

su -s /bin/bash weblogic <<!
    /home/weblogic/Oracle/Middleware/Oracle_Home/wlserver/common/bin/wlst.sh /home/weblogic/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain/demotest.py
!

mkdir -p /home/weblogic/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain/servers/AdminServer/security

echo 'username=weblogic
password=weblogic131' >/home/weblogic/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties

chown weblogic:weblogic -R /home/weblogic/

#/home/weblogic/Oracle/Middleware/Oracle_Home/wlserver/common/templates/scripts/wlst/basicWLSDomain.py

# ./startManagedWebLogic.sh proxy http://192.168.128.129:7011  -Djava.net.preferIPv4Stack=true
# /home/weblogic/Oracle/Middleware/Oracle_Home/oracle_common/common/bin/pack.sh -domain=/home/weblogic/Oracle/Middleware/user_projects/domains/testDomain -template=/opt/base_domain.jar -managed=true -template_name=“DOMAIN”
# /home/weblogic/Oracle/Middleware/Oracle_Home/oracle_common/common/bin/unpack.sh -domain=/home/weblogic/Oracle/Middleware/user_projects/domains/testDomain -template=/opt/base_domain.jar
# route add -host 239.192.0.0 dev eth0
#
#
#
#
# 为了解决在weblogic中jar包冲突的问题  你可以在WEB-INF下创建一个weblogic.xml
#
#
# '
# <?xml version="1.0"?>
# <weblogic-web-app
#  xmlns="http://www.bea.com/ns/weblogic/weblogic-web-app"
#  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
#  xsi:schemaLocation="http://www.bea.com/ns/weblogic/weblogic-web-app http://www.bea.com/ns/weblogic/weblogic-web-app/1.0/weblogic-web-app.xsd">
# <container-descriptor>
# <!-- 优先加载web工程中的jar包，默认为false-->
# <prefer-web-inf-classes>true</prefer-web-inf-classes>
# </container-descriptor>
# </weblogic-web-app>
# '
# yum groupinstall "X Window System" yum groupinstall "GNOME Desktop" "Graphical Administration Tools"
# yum install fwupdate-efi grub2-common
# export LANG="en_US.UTF-8" LANG="zh_CN.GB18030"  yum grouplist
# ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target
# 注册节点
# connect('weblogic','weblogic131','t3://168.168.128.129:9001')
# nmEnroll('/home/weblogic/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain/nodemanager')
# nodemanager/nodemanager.properties     SecureListener=true 改为false
