#!/bin/bash
#Zabbix agent
SERVICE="Zabbix agent"
DAEMON=/usr/local/zabbix_agent/sbin/zabbix_agentd
PIDFILE=/tmp/zabbix_agentd.pid

case $1 in
  'start')
    if [ -x ${DAEMON} ]
    then
      $DAEMON
      # Error checking here would be good...
      echo "${SERVICE} started."
    else
      echo "Can't find file ${DAEMON}."
      echo "${SERVICE} NOT started."
    fi
  ;;
  'stop')
    if [ -s ${PIDFILE} ]
    then
    pro_num=`ps -ef | grep zabbix_agent | grep -v grep|grep -v '/bin/bash'|grep -v '/bin/sh'| awk '{print $2}'`
    echo $pro_num
    kill -9 $pro_num
    echo "${SERVICE} terminated."
    rm -f ${PIDFILE}
    fi
  ;;
  'restart')
    $0 stop
    sleep 1
    $0 start
  ;;
  *)
    echo "Usage: $0 start|stop|restart"
    ;;
esac