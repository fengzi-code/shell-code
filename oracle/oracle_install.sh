#!/bin/bash
#环境检测

fun_confirm () {
    echo -e "\033[44;30m 确认按y，退出按其他键 \033[0m \c"
    read confirm
    if [ $confirm != 'y' ]; then
        echo "安装退出"
        exit
    fi
}

fun_env() {
    
    mem=`free -m|grep Mem|awk '{print $2}'`
    if [ $mem -lt 1024 ];then
        echo '内存检测出错或可用内存小于1G'
        exit
    fi
    
    dev_hd=`df -m|grep -E '/$'|awk '{print $4}'`
    if [ $dev_hd -lt 5120 ];then
        echo '可用空间小于5G'
        exit
    fi
    
    
    swap_size=`free -m|grep Swap|awk '{print $2}'`
    if [[ $swap_size -lt 2048 ]] || [[ -z $swap_size ]];then
        echo '交换空间小于2G,是否增加交换空间'
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
    echo '物理内存:' $mem
    echo '可用空间:' $dev_hd
    echo '可用交换分区:' $swap_size
    read -p "按回车键继续"
}


fun_install_1 () {

    DOMAIN=oracle_db1
    hostnamectl --static set-hostname $DOMAIN
    hostname $DOMAIN
    cp /etc/hosts /etc/hosts.$(date +%F)
    #sed -i 's/127.0.0.1/127.0.0.1 '$DOMAIN' /g' /etc/hosts
    ipdz=`ip a |grep global|awk '{print $2}'|cut -f1 -d/`
    echo "$ipdz $DOMAIN" >> /etc/hosts

    echo '关闭防火墙'
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    echo '关闭防火墙结束'

    echo 'selinux关闭开始'
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    /usr/sbin/sestatus -v
    echo 'selinux关闭结束'

    groupadd oinstall
    groupadd dba
    useradd -g oinstall -G dba -m oracle
    echo "请输入oracle密码!"
    passwd oracle

    mkdir -p /opt/oracle

    #    //$ORACLE_HOME 安装目录
    mkdir -p /opt/oracle/product/112010/db_1
    #//存放数据库目录
    mkdir /opt/oracle/oradata
    #数据库创建及使用过程中的日志目录                                
    mkdir /opt/oracle/inventory
    #数据恢复目录
    mkdir /opt/oracle/flash_recovery_area
    #修改安装目录权限
    chown -R oracle:oinstall /opt/oracle
    chmod -R 775 /opt/oracle


    echo '
    # by oracle
    kernel.shmall=2097152
    kernel.shmmax=1073741824
    fs.aio-max-nr=1048576
    fs.file-max=6815744
    kernel.shmmni=4096
    kernel.sem=250 32000 100 128
    net.ipv4.ip_local_port_range=9000 65500
    net.core.rmem_default=262144
    net.core.rmem_max=4194304
    net.core.wmem_default=262144
    net.core.wmem_max=1048576
    ' >> /etc/sysctl.conf
    sysctl -p


    echo '修改连接数'
    cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F) && \
    echo "
    # by oracle
    oracle           soft     nproc          2047
    oracle           hard    nproc          16384
    oracle           soft     nofile          1024
    oracle           hard    nofile          65536
    oracle           soft     stack           10240
    " >> /etc/security/limits.conf

    #关联设置
    echo "
    # by oracle --------------

    session required  /lib64/security/pam_limits.so
    session required   pam_limits.so
    " >> /etc/pam.d/login

    echo '

    # by oracle --------------

    if [ $USER = "oracle" ]; then
    if [ $SHELL = "/bin/ksh" ]; then
    ulimit -p 16384
    ulimit -n 65536
    else
    ulimit -u 16384 -n 65536
    fi
    fi
    # oracle end ------------
    ' >> /etc/profile

    echo '
    # For Oracle
    export  ORACLE_BASE=/opt/oracle
    export  ORACLE_HOME=/opt/oracle/product/112010/db_1
    export  ORACLE_SID=orcl
    export  PATH=$PATH:$HOME/bin:$ORACLE_HOME/bin
    export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib
     
    if [ $USER = "oracle" ]; then
    if [ $SHELL = "/bin/ksh" ]; then
    ulimit -p 16384
    ulimit -n 65536
    else
    ulimit -u 16384 -n 65536
    fi
    umask 022
    fi
    ' >> /home/oracle/.bash_profile

    source /home/oracle/.bash_profile
    read -p "按回车键继续"

}

fun_install_2 () {
    yum clean all
    yum install binutils-2.* compat-libstdc++-33* elfutils-libelf-0.* elfutils-libelf-devel-* gcc-4.* gcc-c++-4.* glibc-2.* glibc-common-2.* glibc-devel-2.* glibc-headers-2.* ksh-2* libaio-0.* libaio-devel-0.* libgcc-4.* libstdc++-4.* libstdc++-devel-4.* make-3.* sysstat-7.* unixODBC-2.* unixODBC-devel-2.* pdksh* unzip -y
    echo '请将linux.x64_11gR2_database压缩文件上传至/opt目录下'
    read -p "按回车键继续"
    unzip linux.x64_11gR2_database_1of2.zip
    unzip linux.x64_11gR2_database_2of2.zip
    read -p "按回车键继续"
}

fun_install_3 () {
    cp /opt/database/response/db_install.rsp /opt/database/response/db_install.rsp.$(date +%F)
    sed -i "s?oracle.install.option=?oracle.install.option=INSTALL_DB_SWONLY?g" /opt/database/response/db_install.rsp
    sed -i "s?ORACLE_HOSTNAME=?ORACLE_HOSTNAME=$DOMAIN?g" /opt/database/response/db_install.rsp
    sed -i "s?UNIX_GROUP_NAME=?UNIX_GROUP_NAME=oinstall?g" /opt/database/response/db_install.rsp
    sed -i "s?INVENTORY_LOCATION=?INVENTORY_LOCATION=/opt/oracle/inventory?g" /opt/database/response/db_install.rsp
    sed -i "s?SELECTED_LANGUAGES=?SELECTED_LANGUAGES=en,zh_CN?g" /opt/database/response/db_install.rsp
    sed -i "s?ORACLE_HOME=?ORACLE_HOME=/opt/oracle/product/112010/db_1?g" /opt/database/response/db_install.rsp
    sed -i "s?ORACLE_BASE=?ORACLE_BASE=/opt/oracle?g" /opt/database/response/db_install.rsp
    sed -i "s?oracle.install.db.InstallEdition=?oracle.install.db.InstallEdition=EE?g" /opt/database/response/db_install.rsp
    sed -i "s?oracle.install.db.DBA_GROUP=?oracle.install.db.DBA_GROUP=dba?g" /opt/database/response/db_install.rsp
    sed -i "s?oracle.install.db.OPER_GROUP=?oracle.install.db.OPER_GROUP=oinstall?g" /opt/database/response/db_install.rsp
    sed -i "s?oracle.install.db.config.starterdb.type=?oracle.install.db.config.starterdb.type=GENERAL_PURPOSE?g" /opt/database/response/db_install.rsp
    sed -i "s?oracle.install.db.config.starterdb.globalDBName=?oracle.install.db.config.starterdb.globalDBName=orcl?g" /opt/database/response/db_install.rsp
    sed -i "s?oracle.install.db.config.starterdb.SID=?oracle.install.db.config.starterdb.SID=orcl?g" /opt/database/response/db_install.rsp
    sed -i "s?oracle.install.db.config.starterdb.memoryLimit=?oracle.install.db.config.starterdb.memoryLimit=800?g" /opt/database/response/db_install.rsp
    sed -i "s?oracle.install.db.config.starterdb.password.ALL=?oracle.install.db.config.starterdb.password.ALL=oracle?g" /opt/database/response/db_install.rsp
    sed -i "s?DECLINE_SECURITY_UPDATES=?DECLINE_SECURITY_UPDATES=true?g" /opt/database/response/db_install.rsp

    cat /opt/database/response/db_install.rsp | awk 'NR==29 || NR==37 || NR==42 || NR==47 || NR==78 || NR==83 || NR==88 || NR==99 || NR==142 || NR==147 || NR==160 || NR==165 || NR==170 || NR==200 || NR==233 || NR==385'

    read -p "按回车键继续"
    su -s /bin/bash oracle<<!
    /opt/database/runInstaller -silent -responseFile /opt/database/response/db_install.rsp -ignorePrereq
    # cat /opt/oracle/product/112010/db_1/network/admin/listener.ora
!
    install_num=`ps -ef|grep 'oracle.installer'|wc -l`
    while [ $install_num -ge 1 ]
    do
      sleep 5
      install_num=`ps -ef|grep 'oracle.installer'|grep -v 'grep'|wc -l`
    done
    read -p "执行完以上两个脚本后,按回车键继续"
    su -s /bin/bash oracle<<!
    /opt/oracle/product/112010/db_1/bin/netca /silent /responseFile /opt/database/response/netca.rsp
    # cat /opt/oracle/product/112010/db_1/network/admin/listener.ora
!
    # /opt/oracle/inventory/orainstRoot.sh
    # /opt/oracle/product/112010/db_1/root.sh
    #sed -i "s?GDBNAME?#&?g" /opt/database/response/dbca.rsp
    sed -i "s?orcl11g.us.oracle.com?orcl?g" /opt/database/response/dbca.rsp
    sed -i "s?orcl11.us.oracle.com?orcl?g" /opt/database/response/dbca.rsp
    sed -i "s?orcl11g?orcl?g" /opt/database/response/dbca.rsp
    sed -i "s?#GDBNAME?GDBNAME?g" /opt/database/response/dbca.rsp
    oracle_passwd='QAZWSX..55'
    sed -i "s?\"password\"?\"$oracle_passwd\"?g" /opt/database/response/dbca.rsp
    sed -i "s?#SYSPASSWORD?SYSPASSWORD?g" /opt/database/response/dbca.rsp
    sed -i "s?#SYSTEMPASSWORD?SYSTEMPASSWORD?g" /opt/database/response/dbca.rsp
    sed -i "s?#SYSMANPASSWORD?SYSMANPASSWORD?g" /opt/database/response/dbca.rsp
    sed -i "s?#DBSNMPPASSWORD?DBSNMPPASSWORD?g" /opt/database/response/dbca.rsp
    sed -i "s?DATAFILEJARLOCATION =?&/opt/oracle/oradata?g" /opt/database/response/dbca.rsp
    sed -i "s?#DATAFILEJARLOCATION?DATAFILEJARLOCATION?g" /opt/database/response/dbca.rsp
    sed -i "s?#RECOVERYAREADESTINATION=?RECOVERYAREADESTINATION =/opt/oracle/flash_recovery_area?g" /opt/database/response/dbca.rsp
    sed -i "s?#US7ASCII?UTF8?g" /opt/database/response/dbca.rsp
    sed -i "s?#NATIONALCHARACTERSET= \"UTF8\"?NATIONALCHARACTERSET= \"ZHS16GBK\"?g" /opt/database/response/dbca.rsp
    mem_orcl=`echo $mem | awk '{printf ("%.0f\n",$1*0.8)}'`
    sed -i "s?800?$mem_orcl?g" /opt/database/response/dbca.rsp
    cp /opt/database/stage/Components/oracle.rdbms.install.seeddb/11.2.0.1.0/1/DataFiles/Expanded/filegroup1/Seed_Database.* /opt/oracle/oradata/
    su -s /bin/bash oracle<<!
    /opt/oracle/product/112010/db_1/bin/dbca -silent -responseFile /opt/database/response/dbca.rsp
!
    sed -i "s?=\$1?=\$ORACLE_HOME?" /opt/oracle/product/112010/db_1/bin/dbstart
    sed -i "s?=\$1?=\$ORACLE_HOME?" /opt/oracle/product/112010/db_1/bin/dbshut
    sed -i "s?:N?:Y?" /etc/oratab

} 

exe_dir=`pwd`

if [ $exe_dir != '/opt' ];then
    echo '请将此脚本放至/opt目录下'
    exit
fi


fun_env

fun_install_1

fun_install_2

fun_install_3

echo '安装完毕!'




# sqlplus / as sysdba
# Sqlplus gdag/1@192.168.128.130/orcl as sysdba


# 创建临时表空间：
# create temporary tablespace gdag_temp tempfile '/opt/oracle/oradata/gdag_temp.bdf' size 100m reuse autoextend on next 20m maxsize unlimited;  
# 创建表空间：
# create tablespace gdag datafile '/opt/oracle/oradata/gdag.dbf' size 100M reuse autoextend on next 40M maxsize unlimited default storage(initial 128k next 128k minextents 2 maxextents unlimited);

# 创建用户和密码，指定上边创建的临时表空间和表空间
# create user gdag identified by 1 default tablespace gdag temporary tablespace gdag_temp;

# 赋予权限
# grant dba to gdag;
# grant connect,resource to gdag;
# grant select any table to gdag;
# grant delete any table to gdag;
# grant update any table to gdag;
# grant insert any table to gdag;
# 
# imp gdag/1@192.168.128.130/orcl file=/opt/oracle/oradata/20161122yntk.dmp log=/tmp/yx_base.log full=y
# 
# create or replace directory dump_dir as 'D:\fzb';
# impdp gd_base/11@192.168.xx.xx/oanet  directory=dump_dir dumpfile=gd_base.DMP schemas=gd_base
# 
# 查询oracle系统用户的默认表空间和临时表空间 select default_tablespace,temporary_tablespace from dba_users;
# 查看当前用户的角色 select * from user_role_privs;
# 查看当前用户的系统权限和表级权限 select * from user_sys_privs;  select * from user_tab_privs; 
#  查看用户下所有的表 select * from user_tables; 


# 查看表空间物理文件的名称及大小
# SELECT tablespace_name, 
# file_id, 
# file_name, 
# autoextensible,
# round(bytes / (1024 * 1024), 0) total_space 
# FROM dba_data_files 
# ORDER BY tablespace_name;


# 查看数据库的版本
# SELECT version 
# FROM product_component_version 
# WHERE substr(product, 1, 6) = 'Oracle';

# 查询oracle表空间的使用情况
# SELECT created, log_mode, log_mode FROM v$database; 
# --1G=1024MB 
# --1M=1024KB 
# --1K=1024Bytes 
# --1M=11048576Bytes 
# --1G=1024*11048576Bytes=11313741824Bytes 
# SELECT a.tablespace_name "表空间名", 
# total / (1024 * 1024) "表空间大小(M)", 
# free / (1024 * 1024) "表空间剩余大小(M)", 
# (total - free) / (1024 * 1024) "表空间使用大小(M)", 
# round((total - free) / total, 4) * 100 "使用率 %" 
# FROM (SELECT tablespace_name, SUM(bytes) free 
# FROM dba_free_space 
# GROUP BY tablespace_name) a, 
# (SELECT tablespace_name, SUM(bytes) total 
# FROM dba_data_files 
# GROUP BY tablespace_name) b 
# WHERE a.tablespace_name = b.tablespace_name 

# 查看当前使用的数据库的名字:
# select name from v$database;
# 查看当前数据库实例：
# select instance_name from v$instance
# 查询数据库服务名（service_name）：
# select value from v$parameter where name='service_name'
# 查询数据库域名（dimain）：
# select value from v$parameter where name='db_domain'
# 
# 查询sga、pga的使用率
# select name,total,round(total-free,2) used, round(free,2) free,round((total-free)/total*100,2) pctused from 
# (select 'SGA' name,(select sum(value/1024/1024) from v$sga) total,
# (select sum(bytes/1024/1024) from v$sgastat where name='free memory')free from dual)
# union
# select name,total,round(used,2)used,round(total-used,2)free,round(used/total*100,2)pctused from (
# select 'PGA' name,(select value/1024/1024 total from v$pgastat where name='aggregate PGA target parameter')total,
# (select value/1024/1024 used from v$pgastat where name='total PGA allocated')used from dual);