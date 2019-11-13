#!/bin/bash
# backup all mysql db

#step0: defining env
DATE=`date +%Y%m%d%H`
DBHost=192.168.1.23
DBUser=root
DBPwd=root
BakDir=/data_backup/192.168.1.23_mysql/${DATE}
mkdir -p ${BakDir}
cd ${BakDir}

echo "################ starting backup all mysql db job at `date` ###############"
#step1: clearing up overdue files;
find /data_backup/192.168.1.23_mysql/* -type d -mtime +5 -exec rm -rf {} \;

#step2: export all DB name
/usr/local/mysql/bin/mysql -h"${DBHost}" -u${DBUser} -p${DBPwd} -e 'show databases\G' |grep Database |awk -F': ' '{print $2}' |egrep -v "information_schema|performance_schema" >db_1.23_info.txt 

#step3: starting job
for DataBase in $(cat db_1.23_info.txt)
do
        echo "`date` starting backup ${DataBase}"
        /usr/local/mysql/bin/mysqldump -R -B -h ${DBHost} -u${DBUser} -p${DBPwd}  --databases ${DataBase} | gzip > ${BakDir}/${DataBase}.sql.gz
done

chmod 640 ${BakDir}/*

echo "################ finished backup all mysql db job at `date` ###############"

