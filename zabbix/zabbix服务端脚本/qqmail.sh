#!/bin/sh
export LANG=en_US.UTF-8
FILE=/opt/soft/zabbix_server/share/zabbix/alertscripts/mailtmp.txt
echo "$3" >$FILE
dos2unix -k $FILE
/bin/mail -s "$2" $1 < $FILE

