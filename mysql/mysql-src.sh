#!/bin/bash
#build lnmp_mysql_yum
set -e
currentdirectory=$(pwd)
mysqlversion="5.7.24"
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
mysql_url=https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-boost-$mysqlversion.tar.gz
mysql_USER='root'
mysql_PSW='JieYngGame#mysql'
#check user and group
id mysql
if [ $? -ne 0 ]; then
    useradd -s /sbin/nologin -M mysql
fi
#check dir
mkdir -pv $basedir/{conf,run,data,logs} /var/log/mysql
chown -R mysql:mysql $basedir /var/log/mysql
if [ ! -z "$(rpm -qa | grep mysql)" ]; then
    rpm_qa_mysql=$(rpm -qa | grep mysql)
    for i in ${rpm_qa_mysql}; do
        rpm -e $i --nodeps
    done
fi
if [ ! -z "$(rpm -qa | grep mariadb)" ]; then
    rpm_qa_mariadb=$(rpm -qa | grep mariadb)
    for i in ${rpm_qa_mariadb}; do
        rpm -e $i --nodeps
    done
fi
if [ -e "/etc/my.cnf" ]; then
    rm -rf "/etc/my.cnf"
fi
if [ -e "/etc/my.cnf.d" ]; then
    rm -rf "/etc/my.cnf.d"
fi
if [ -e "/var/log/mysqld.log" ]; then
    rm -rf "/var/log/mysqld.log"
fi
if [ -e "/var/run/mysqld/mysqld.pid" ]; then
    rm -rf "/var/run/mysqld/mysqld.pid"
fi
if [ -e "/tmp/mysql.sock" ]; then
    rm -rf "/tmp/mysql.sock"
fi
if [ -e "/var/mysql/lib/" ]; then
    rm -rf "/var/mysql/lib/"
fi
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g;s/^SELINUXTYPE/#SELINUXTYPE/g' /etc/selinux/config
setenforce 0
systemctl stop firewalld
systemctl disable firewalld
#yum -y install gcc gcc-c++ ncurses ncurses-devel cmake (简化依赖包)
yum -y install gcc gcc-c++ autoconf automake zlib libxml ncurses ncurses-devel libtool* libgcrypt* \
    cmake openssl openssl-devel bison bison-devel perl-Data-Dumper libaio wget

if [ -e "mysql-boost-$mysqlversion.tar.gz" ]; then
    #pkg_path="$currentdirectory/mysql-boost-$mysqlversion.tar.gz"
    echo "当前目录存在源码压缩包，不下载"
    if [ -e "$currentdirectory/mysql-$mysqlversion" ]; then
        rm -rf "$currentdirectory/mysql-$mysqlversion"
    fi
else
    wget $mysql_url
fi
if [ -e "mysql-boost-$mysqlversion.tar.gz" ]; then
    tar -zxf "mysql-boost-$mysqlversion.tar.gz"
else
    echo "源码包文件不存在"
    exit 1
fi
cd "$currentdirectory/mysql-$mysqlversion"
cmake . \
    -DCMAKE_INSTALL_PREFIX=$basedir \
    -DMYSQL_DATADIR=$datadir \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_SYSTEMD=1 \
    -DWITH_BOOST=$currentdirectory/mysql-$mysqlversion/boost \
    -DSYSCONFDIR=/etc \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_FEDERATED_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DENABLED_LOCAL_INFILE=1 \
    -DENABLE_DTRACE=0 \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EMBEDDED_SERVER=1 \
    -DWITH_SSL=system \
    -DWITH_ZLIB=system

make -j$(cat /proc/cpuinfo | grep "cpu cores" | awk '{print $4}' | head -1) && make install

#cmake . \
#-DCMAKE_INSTALL_PREFIX=/www/lnmp/mysql \ #安装目录
#-DMYSQL_DATADIR=/www/lnmp/mysql/data \ #数据存放目录
#-DDOWNLOAD_BOOST=1 \  #自动下载 boost
#-DWITH_BOOST=/root/$mysqlversion/boost \  #并将其放在 /root/$mysqlversion/boost
#-DSYSCONFDIR=/etc \  #配置文件路径
#-DWITH_INNOBASE_STORAGE_ENGINE=1 \  #支持InnoDB引擎
#-DWITH_PARTITION_STORAGE_ENGINE=1 \  #支持存储引擎
#-DWITH_FEDERATED_STORAGE_ENGINE=1 \  #支持FEDERATED引擎
#-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \  #支持BLACKHOLE引擎
#-DWITH_MYISAM_STORAGE_ENGINE=1 \  #支持MYISAM引擎
#-DENABLED_LOCAL_INFILE=1 \  #启用加载本地数据,可以使用load data infile命令从本地导入文件
#-DENABLE_DTRACE=0 \  #是否启用dtrace
#-DDEFAULT_CHARSET=utf8 \  #默认字符集
#-DDEFAULT_COLLATION=utf8_general_ci \  #默认编码
#-DWITH_EMBEDDED_SERVER=1 \ #嵌入式服务器支持
#-DWITH_SSL=system \ #启用ssl库支持（安全套接层
#-DWITH_ZLIB=system #启用libz库支持

cat >/etc/my.cnf <<EOF
[client]
port            = 3306
socket          = /tmp/mysql.sock
[mysqld]
port            = 3306
basedir = $basedir
datadir = $datadir
socket=/tmp/mysql.sock
symbolic-links=0
#请在防火墙允许指定的IP连接此端口.其它阻止
bind-address=0.0.0.0
log-error=/var/log/mysql/mysqld.log
pid-file=/tmp/mysql.pid
#开启慢查询日志
slow_query_log = 1
#超出次设定值的SQL即被记录到慢查询日志
long_query_time = 6
slow_query_log_file = /var/log/mysql/slow.log
lower_case_table_names=1
#--------------------------------------
#打开binlog日志
log-bin=$datadir/mysql-bin
#主服务器唯一ID
server-id=123456
#可以被从库同步的库
#binlog-do-db=HA
#不可以被从服务器复制的库
#binlog-ignore-db=mysql
#跳过外部锁定
#skip-external-locking
#指定索引缓冲区的大小
#key_buffer_size = 128M
#Server接受的数据包大小,设置过小将导致单个记录超过限制后写入数据库失败，且后续记录写入也将失败
#max_allowed_packet = 10M
#高速缓存的大小
#table_open_cache = 256
#默认1M
#sort_buffer_size = 1M
#默认1M
#read_buffer_size = 1M
#默认8M
#myisam_sort_buffer_size = 8M
#当客户端断开之后，服务器处理此客户的线程将会缓存起来以响应下一个客户而不是销毁
#thread_cache_size = 8
#查询缓存,很少有相同的查询，最好不要使用
#query_cache_size= 16M
#最大连接（用户）数
#max_connections = 3000
#连接最大空闲时长
#wait_timeout = 30
#关闭交互式连接前等待的秒数
#interactive_timeout = 30
#max_connect_errors = 9
#long_query_time = 1
#tmp_table_size = 16M
####################----------从服务器配置--------#####################
#server_id=20
#服务器ID
#default-time-zone = '+8:00'
#mysql时区
#log_bin=mysql3306_bin
#binlog日志
#binlog_format=mixed
#relay_log=mysql3306_relay
#elay-log日志
#read_only=ON
#只读
#innodb_file_per_table=ON
#InnoDB为独立表空间模式
#replicate_do_db=jy_game
#需要同步的库
#symbolic-links=0
#支持符号链接,即数据库或表可以存储在my.cnf中指定datadir之外的分区或目录
####################----------从服务器配置--------#####################
EOF

rm $datadir/* -rf
touch /var/log/mysql/mysqld.log
chown mysql:mysql /var/log/mysql/mysqld.log
#初始化
echo '初始化开始-------------------------------------------------'

$basedir/bin/mysqld --initialize-insecure --user=mysql --basedir=$basedir --datadir=$datadir

echo '初始化结束-------------------------------------------------'

echo "PATH=$basedir/bin:$basedir/lib:\$PATH " >>/etc/profile
source /etc/profile

os_ver=$(cat /etc/redhat-release | grep -Po '[0-9]' | head -1)

if [ ${os_ver} == '7' ]; then
    cp -rp $basedir/usr/lib/systemd/system/mysqld.service /usr/lib/systemd/system/
    sed -i "s#^PIDFile.*#PIDFile=/tmp/mysql.pid#" /usr/lib/systemd/system/mysqld.service
    sed -i "s#^ExecStart=.*#ExecStart=$basedir/bin/mysqld --daemonize --pid-file=/tmp/mysql.pid \$MYSQLD_OPTS#" /usr/lib/systemd/system/mysqld.service
    sed -i '/ExecStartPre=/s/^/#/' /usr/lib/systemd/system/mysqld.service
    systemctl enable mysqld
    # systemctl start mysqld
else
    cp -rp $basedir/support-files/mysql.server /etc/init.d/mysqld
    sed -i '2i# chkconfig: - 95 95' /etc/init.d/mysqld
    chkconfig --add mysqld
    chkconfig --level 345 mysqld on
    #service mysqld start
fi

. /etc/profile

echo -e "\033[44;30m 是否更新mysql密码,确认按y，退出按其他键 \033[0m \c" 
read confirm
if [ $confirm = 'y' ]; then
    systemctl start mysqld
    mysql -u$mysql_USER -e "update mysql.user set authentication_string=password('$mysql_PSW') where user='$mysql_USER';" >>/dev/null 2>&1
    mysql -u$mysql_USER -e "flush privileges;"
fi


#update mysql.user set authentication_string=password('JieYngGame#mysql') where user='root';
#use mysql;
#update user set host = '%' where user = 'root';
#flush privileges;
#导出数据库 mysqldump -R -B -h 127.0.0.1 -ujumpserver -pjumpsereee.com  --databases jumpserver > /tmp/jumpserver.sql
#CREATE DATABASE jira DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
#CREATE USER 'phpmywind'@'localhost' IDENTIFIED BY 'Mzj-WeB-81o8';
#GRANT ALL ON jira.* TO 'jira'@'localhost';
#source D:/www/sql/back.sql;
#GRANT SELECT ON `mzj-manager`.* TO 'scaleuser'@'%';
#CREATE USER 'fansread'@'%' IDENTIFIED BY 'FaNsRead_020';
#GRANT SELECT ON *.* TO 'fansread'@'%';
#GRANT SELECT ON `mzj\_sellfans`.* TO 'fansread'@'%';
#编译参数查询 cat your_mysql_dir/bin/mysqlbug |grep configure

# -----------------------------主从配置------------------------------------
# CREATE USER 'slave'@'192.168.128.%' IDENTIFIED BY '123456';  #创建同步用户
# GRANT REPLICATION SLAVE ON *.* TO 'slave'@'192.168.128.%';   #分配权限
# flush privileges;   #刷新权限

# SHOW MASTER STATUS; #查看master状态

#------从库操作

# 执行同步SQL语句
# CHANGE MASTER TO
#     MASTER_HOST='192.168.128.128',
#     MASTER_USER='slave',
#     MASTER_PASSWORD='123456',
#     MASTER_LOG_FILE='mysql-bin.000001',
#     MASTER_LOG_POS=765;
# start slave;    #启动slave同步进程
# show slave status\G;    #查看slave状态
# -----------------------------主从配置结束------------------------------------

# SELECT * FROM dept;
# 查询职员表中职位是’SALESMAN’的职员：
# SELECT ename, sal, job FROM emp WHERE job = 'SALESMAN';
# 查询部门10下的员工信息
# SELECT * FROM emp WHERE deptno = 10;
# 查询职员表中在2002年1月1号以后入职的职员信息
# SELECT ename, sal, hiredate FROM emp WHERE hiredate>to_date('2002-1-1','YYYY-MM-DD');
# 查询薪水大于1000并且职位是’CLERK’的职员信息
# SELECT ename, sal, job FROM emp WHERE sal> 1000 AND job = 'CLERK';
# 查询职员姓名中第二个字符是‘A’的员工信息,% 表示0到多个字符   _ 标识单个字符
# SELECT ename, job FROM emp WHERE ename LIKE '_A%';
# 查询职位是MANAGER或者CLERK的员工
# SELECT ename, job FROM emp WHERE job IN ('MANAGER', 'CLERK');
# 查询不是部门10或20的员工
# SELECT ename, job FROM emp WHERE deptno NOT IN (10, 20);
# 查询薪水在1500-3000之间的职员信息  BETWEEN…AND…操作符用来查询符合某个值域范围条件的数据
# SELECT ename, sal FROM emp WHERE sal BETWEEN 1500 AND 3000;
# 查询哪些职员的奖金数据为空  比较的时候不能使用”=”号，必须使用IS NULL,相反还有IS NOT NULL
# SELECT ename, sal, comm FROM emp WHERE comm IS NULL;
# 查询薪水比职位是“SALESMAN”的人高的员工信息，比任意一个SALESMAN高都行. ALL和ANY，表示“全部”和“任一”，不能单独使用，需要配合单行比较操作符>、>=、<、<=一起使用。其中：
# > ANY : 大于最小
# < ANY：小于最大
# > ALL：大于最大
# < ALL：小于最小
# SELECT empno, ename, job, sal, deptno FROM emp WHERE sal> ANY (SELECT sal FROM emp WHERE job = 'SALESMAN');
# 查询年薪大于10w元的员工记录
# SELECT ename, sal, job FROM empWHERE sal * 12 >100000;
# 查询员工的部门编码，去掉重复值 用DISTINCT过滤重复
# SELECT DISTINCT deptno FROM emp;
# 对职员表按薪水排序 ORDER BY必须出现在SELECT中的最后一个子句 ASC用来指定升序排序，DESC用来指定降序排序
# SELECT ename, sal FROM emp ORDER BY sal DESC;
# 对职员表中的职员排序，先按照部门编码正序排列，再按照薪水降序排列 多列排序时，不管正序还是倒序，每个列需要单独设置排序方式
# SELECT ename, deptno, sal FROM emp ORDER BY deptno ASC, sal DESC;
# 获得机构下全部职员的平均薪水和薪水总和 AVG和SUM函数用来统计列或表达式的平均值和和值，这两个函数只能操作数字类型，并忽略NULL值。
# SELECT AVG(sal) avg_sal, SUM(sal)  sum_sal  FROM emp;
# 连接查询
# SELECT table1.column, table2.column FROM table1, table2 WHERE table1.column1 = table2.column2;
# 笛卡尔积指做关联操作的每个表的每一行都和其它表的每一行做组合
# SELECT COUNT(*) FROM emp; --14条记录
# SELECT COUNT(*) FROM dept; --4条记录
# SELECT emp.ename, dept.dname FROM emp, dept; --56条记录
# 查询职员的姓名、职位以及所在部门的名字和所在城市，使用两个相关的列做等值操作
# SELECT e.ename, e.job, d.dname, d.loc
# FROM emp e, dept d
# WHERE e.deptno = d.deptno;
# 也可以写成内连接
# SELECT e.ename, e.job, d.dname, d.loc
# FROM emp e JOIN dept d
# ON(e.deptno = d.deptno);
# 内连接返回两个表中所有满足连接条件的数据记录,外链接相反,把没有职员的部门和没有部门的职员查出来
# SELECT table1.column, table2.column
# FROM table1 [LEFT | RIGHT | FULL] JOIN table2
# ON table1.column1 = table2.column2;
# 全连接 除了返回两个表中满足连接条件的记录，还会返回不满足连接条件的所有其它行
# SELECT e.ename, d.dname
# FROM emp e FULL OUTER JOIN dept d
# ON e.deptno = d.deptno;
# 自连接是通过将表用别名虚拟成两个表的方式实现，可以是等值或不等值连接。例如查出每个职员的经理名字，以及他们的职员编码
# SELECT worker.empnow_empno, worker.enamew_ename, manager.empnom_empno, manager.enamem_ename
# FROM emp worker join emp manager
# ON worker.mgr = manager.empno;
