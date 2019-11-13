#!/bin/bash
bak_time=$(date +%Y%m%d)
bak_dir1=/data_backup/192.168.1.31_xiaoyaoji
bak_dir2=$bak_dir1/$bak_time
ip=192.168.1.31
DBHost=192.168.1.11
DBUser=root
DBPwd=rootMzj@123
DataBase=xiaoyaoji

mkdir -p $bak_dir2
ssh -t -p 22 root@$ip "tar -czvf /opt/apidoc.tar.gz /opt/apache-tomcat-8.5.20-api --exclude /opt/apache-tomcat-8.5.20-api/logs"
scp -r $ip:/opt/apidoc.tar.gz $bak_dir2/
ssh -t -p 22 root@$ip "rm -rf /opt/apidoc.tar.gz"

/usr/local/mysql/bin/mysqldump -h ${DBHost} -u${DBUser} -p${DBPwd}  --databases ${DataBase} > ${bak_dir2}/${DataBase}.sql

find $bak_dir1 -type d -name '20*' -mtime +5 -exec rm -rf {} \;
