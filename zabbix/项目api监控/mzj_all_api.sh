#!/bin/bash
#mzj_project_status
host_url=$1
http_agr=$2
end_code='{"status":"ok"}'
info=`curl "${http_agr}://127.0.0.1/opshb" -H "Host:${host_url}" -L -k -s`
#echo $info
if [ "${info}" == "${end_code}" ]; then
    echo 1
else
    echo 0
fi



'wget http://219.135.214.61:4999/mzj_project_status.sh -P /usr/local/zabbix_agent/scripts/ && chmod +x /usr/local/zabbix_agent/scripts/*.sh && chown zabbix:zabbix /usr/local/zabbix_agent/scripts/*.sh && echo "UserParameter=mzj_project_status[*],/usr/local/zabbix_agent/scripts/mzj_project_status.sh \$1 \$2" >> /usr/local/zabbix_agent/etc/zabbix_agentd.conf.d/tcp-status-params.conf && /etc/init.d/zabbix_agent restart'



sh .remote_cmd.sh 172.18.197.161:22 '/usr/bin/rm -rf /etc/init.d/zabbix_agent && wget http://219.135.214.61:4999/zabbix_agent -P /etc/init.d/ && chmod +x /etc/init.d/zabbix_agent && chown zabbix:zabbix /etc/init.d/zabbix_agent'



sh .remote_cmd.sh ali '/usr/bin/rm -rf /etc/init.d/zabbix_agent && wget http://219.135.214.61:4999/zabbix_agent -P /etc/init.d/ && chmod +x /etc/init.d/zabbix_agent && chown zabbix:zabbix /etc/init.d/zabbix_agent && echo 9653542 > /tmp/zabbix_agentd.pid'

sh .remote_cmd.sh tx '/usr/bin/rm -rf /etc/init.d/zabbix_agent && wget http://219.135.214.61:4999/zabbix_agent -P /etc/init.d/ && chmod +x /etc/init.d/zabbix_agent && chown zabbix:zabbix /etc/init.d/zabbix_agent'


#!/usr/bin

find /usr/local/nginx/imageFile/ -type d -name `date -d '-1 day' +%F` -exec rm -rf {} \;

