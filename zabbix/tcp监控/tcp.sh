#!/bin/bash
#zabbix tcp sh
echo "Include=/usr/local/zabbix_agent/etc/zabbix_agentd.conf.d/*.conf" >> /usr/local/zabbix_agent/etc/zabbix_agentd.conf && \
mkdir -p /usr/local/zabbix_agent/scripts/ && \
wget http://172.18.245.91:8877/tcp_conn_status.sh -P /usr/local/zabbix_agent/scripts/ && \
wget http://172.18.245.91:8877/tcp-status-params.conf -P /usr/local/zabbix_agent/etc/zabbix_agentd.conf.d/ && \
#chown -R zabbix:zabbix /usr/local/zabbix_agent/scripts/ && \
chmod +x /usr/local/zabbix_agent/scripts/tcp_conn_status.sh && \
/usr/local/zabbix_agent/sbin/zabbix restart && \
/usr/local/zabbix_agent/sbin/zabbix_agentd -t "tcp.status[listen]" && \
rm -rf /tmp/tcp_status.txt
