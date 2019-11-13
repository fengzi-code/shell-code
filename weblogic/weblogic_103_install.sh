#!/bin/bash




fun_confirm () {
    echo -e "\033[44;30m 确认按y，退出按其他键 \033[0m \c"
    read confirm
    if [ $confirm != 'y' ]; then
        echo "安装退出"
        exit
    fi
}

fun_env() {
    
    java_dir=`echo $JAVA_HOME`

    if [ -z $java_dir ];then
        echo '未安装java环境'
        exit
    fi

    mem=`free -m|grep Mem|awk '{print $2}'`
    if [ $mem -lt 1024 ];then
        echo '内存检测出错或可用内存小于1G'
        exit
    fi
    
    dev_hd=`df -m|grep -E '/$'|awk '{print $4}'`
    if [ $dev_hd -lt 512 ];then
        echo '可用空间小于512M'
        exit
    fi
    
    
    swap_size=`free -m|grep Swap|awk '{print $2}'`
    if [[ $swap_size -lt 512 ]] || [[ -z $swap_size ]];then
        echo '交换空间小于512M,是否增加交换空间'
        fun_confirm
        echo '请稍候,增加交换空间中......'
        swap_dir=`grep swap /etc/fstab |awk '{print $1}'`
        if [ -n $swap_dir ];then
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
        echo "$swap_dir swap swap defaults 0 0" >> /etc/fstab
        sysctl -p
        #----------------------交换分区结束-----------------------------
        
    fi
    swap_size=`free -m|grep Swap|awk '{print $2}'`
    echo "java_home:" $java_dir
    echo '物理内存:' $mem
    echo '可用空间:' $dev_hd
    echo '可用交换分区:' $swap_size
    read -p "按回车键继续"
}

fun_install() {
echo '根据提示进行选择或者下一步安装完成'
echo '中间件位置请输入  /home/weblogic/Oracle/Middleware'
su -s /bin/bash weblogic<<!
java -jar /opt/wls1036_generic.jar
!



}

fun_install_2() {

echo '根据提示进行选择或者下一步安装完成'


/home/weblogic/Oracle/Middleware/wlserver_10.3/common/bin/config.sh

}

exe_dir=`pwd`

if [ $exe_dir != '/opt' ];then
    echo '请将此脚本放至/opt目录下'
    exit
fi

fun_env



echo '请上传wls1036_generic.jar文件至/opt'

read -p "按回车键继续"

groupadd weblogic
useradd -g weblogic weblogic
passwd weblogic

fun_install




echo '是否创建域,按y创建,按其它键退出!'
echo '用户名填weblogic,密码填weblogic131'

fun_confirm

fun_install_2



mkdir -p /home/weblogic/Oracle/Middleware/user_projects/domains/base_domain/servers/AdminServer/security/

echo 'username=weblogic
password=weblogic131' > /home/weblogic/Oracle/Middleware/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties

chown weblogic:weblogic -R /home/weblogic/

echo '其它的操作参照weblogic12c'

# 为了解决在weblogic中jar包冲突的问题  你可以在WEB-INF下创建一个weblogic.xml
# 
# 
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

# yum groupinstall "X Window System" yum groupinstall "GNOME Desktop" "Graphical Administration Tools"
# yum install fwupdate-efi grub2-common
# export LANG="en_US.UTF-8" LANG="zh_CN.GB18030"  yum grouplist
# ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target
# 注册节点
# connect('weblogic','weblogic131','t3://168.168.128.129:9001')
# nmEnroll('/home/weblogic/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain/nodemanager')
# nodemanager/nodemanager.properties     SecureListener=true 改为false



