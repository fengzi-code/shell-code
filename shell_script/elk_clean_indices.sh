#/bin/bash
#author: john li 
#created at 2017/9/15 16:00

if test ! -f "/var/log/elkDailyDel.log" ;then
    touch /var/log/elkDailyDel.log
fi
#请将该行当中的localhost:9200改成你自己elasticsearch服务对应的Ip及端口
indices=$(curl -s "localhost:9200/_cat/indices?v"|grep 'logstash'|awk '{print $3}') 
#可将60改成你所需要的时间段，改成40则保留最近40天的日志数据，以此类推
sixtyDaysAgo=$(date -d "$(date "+%Y%m%d") -14 days" "+%s") 
function DelOrNot(){
    if [ $(($1-$2)) -ge 0 ] ;then
        echo 1
    else
        echo 0
    fi
}
for index in ${indices}
do
    indexDate=`echo ${index}|cut -d '-' -f 2|sed 's/\./-/g'`
    indexTime=`date -d "${indexDate}" "+%s"`
    if [ `DelOrNot ${indexTime} ${sixtyDaysAgo}` -eq 0 ] ;then
    #请将下行当中的localhost:9200改成你自己elasticsearch服务对应的Ip及端口
        delResult=`curl -s -XDELETE "localhost:9200/${index}"` 
        echo "delResult is ${delResult}" >> /var/log/elkDailyDel.log
        if [ `echo ${delResult}|grep 'acknowledged'|wc -l` -eq 1 ] ;then
            echo "${index} had already been deleted!" >> /var/log/elkDailyDel.log
        else
            echo "there is something wrong happend when deleted ${index}" >> /var/log/elkDailyDel.log
        fi
    fi
done
