#!/bin/bash

touken=$(curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":
"2.0","method":"user.login","params":{"user":"admin","password":"zabbixSL..99"},"auth":
null,"id":0}' http://127.0.0.1/api_jsonrpc.php | grep -Po 'result.+id' | cut -f3 -d '"')

curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method": "host.get","params": {"output":["hostid","host"],"selectInterfaces": ["interfaceid","ip"]},"id": 0,"auth":"'$touken'"}' http://127.0.0.1/api_jsonrpc.php >hostall.txt
cat -v hostall.txt | grep -v "\^M" >hostall1.txt
sed -i 's/]},{/\n/g' hostall1.txt
hostall=$(cat hostall1.txt | grep -v "bj-linshi" | grep -v "219.135")
rm -rf *.txt hostall.sh
hostid=$(echo -e "$hostall" | grep -Po hostid.+host | cut -f3 -d '"')
host=$(echo -e "$hostall" | grep -Po host\".+interfaces | cut -f3 -d '"')
interfaceid=$(echo -e "$hostall" | grep -Po interfaceid.+ip | cut -f3 -d '"')
ipid=$(echo -e "$hostall" | grep -Po ip.+\} | cut -f3 -d '"')

#获取监控模板ID
chishu=$(echo -e "$hostid" | wc -l)

for ((i = 1; i <= ${chishu}; i++)); do
   hostid1=$(echo $hostid | cut -f${i} -d " ")
   echo $hostid1
   curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"item.get","params":{"output":"itemids","hostids":"'$hostid1'","search":{"key_":"system.cpu.util[,idle]"}},"auth":"'$touken'","id": 0}' http://127.0.0.1/api_jsonrpc.php >>cpu_user.txt

   curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"item.get","params":{"output":"itemids","hostids":"'$hostid1'","search":{"key_":"system.cpu.load[all,avg1]"}},"auth":"'$touken'","id": 0}' http://127.0.0.1/api_jsonrpc.php >>cpu_load.txt

   curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"item.get","params":{"output":"itemids","hostids":"'$hostid1'","search":{"key_":"vm.memory.size[used]"}},"auth":"'$touken'","id": 0}' http://127.0.0.1/api_jsonrpc.php >>memory_used.txt
   curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"item.get","params":{"output":"itemids","hostids":"'$hostid1'","search":{"key_":"net.if.in[eth0]"}},"auth":"'$touken'","id": 0}' http://127.0.0.1/api_jsonrpc.php >>network_in.txt
   curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"item.get","params":{"output":"itemids","hostids":"'$hostid1'","search":{"key_":"net.if.out[eth0]"}},"auth":"'$touken'","id": 0}' http://127.0.0.1/api_jsonrpc.php >>network_out.txt

   curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"item.get","params":{"output":"itemids","hostids":"'$hostid1'","search":{"key_":"tcp.status[established]"}},"auth":"'$touken'","id": 0}' http://127.0.0.1/api_jsonrpc.php >>tcp_established.txt

done

#-----------------------cpu_user_hig--------------------------------

time_from_num=$(date +%Y-%m-%d -d "-1 day")
time_from_num=$(date -d $time_from_num +%s)
time_till_num=$(($time_from_num + 86400 - 1))
#echo $time_from_num|awk '{print strftime("%Y/%m/%d-%H:%M:%S",$0)}'
#echo $time_till_num|awk '{print strftime("%Y/%m/%d-%H:%M:%S",$0)}'

xh=0
for ((ii = 1; ii <= 6; ii++)); do
   if [ $xh -eq 0 ]; then
      itemids=$(cat cpu_user.txt | grep jsonrpc | cut -f10 -d '"')
      zabbix_key="system.cpu.util[,idle]"
   elif [ $xh -eq 1 ]; then
      itemids=$(cat cpu_load.txt | grep jsonrpc | cut -f10 -d '"')
      zabbix_key="system.cpu.load[all,avg1]"
   elif [ $xh -eq 2 ]; then
      itemids=$(cat memory_used.txt | grep jsonrpc | cut -f10 -d '"')
      zabbix_key="vm.memory.size[used]"
   elif [ $xh -eq 3 ]; then
      itemids=$(cat network_in.txt | grep jsonrpc | cut -f10 -d '"')
      zabbix_key="net.if.in[eth0]"
   elif [ $xh -eq 4 ]; then
      itemids=$(cat network_out.txt | grep jsonrpc | cut -f10 -d '"')
      zabbix_key="net.if.out[eth0]"
   elif [ $xh -eq 5 ]; then
      itemids=$(cat tcp_established.txt | grep jsonrpc | cut -f10 -d '"')
      zabbix_key="tcp.status[established]"
   fi
   chishu1=$(echo -e "$itemids" | wc -l)
   echo $xh

   for ((i = 1; i <= ${chishu1}; i++)); do

      # hostid1=$(echo $hostid | cut -f${i} -d " ")
      itemids1=$(echo $itemids | cut -f${i} -d " ")

      echo $zabbix_key
      if [ $zabbix_key = "vm.memory.size[used]" -o $zabbix_key = "net.if.in[eth0]" -o $zabbix_key = "net.if.out[eth0]" -o $zabbix_key = "tcp.status[established]" ]; then
         curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"history.get","params":{"history":3,"itemids":["'$itemids1'"],"time_from":"'$time_from_num'","time_till":"'$time_till_num'","output":"extend"},"auth": "'$touken'","id": 0}' http://127.0.0.1/api_jsonrpc.php >>cpu_user_id.txt
      else
         curl -s -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"history.get","params":{"history":0,"itemids":["'$itemids1'"],"time_from":"'$time_from_num'","time_till":"'$time_till_num'","output":"extend"},"auth": "'$touken'","id": 0}' http://127.0.0.1/api_jsonrpc.php >>cpu_user_id.txt
      #curl -i -X POST -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0","method":"history.get","params":{"history":3,"itemids":["29759"],"time_from":"1517068800","time_till":"1517155199","output":"extend"},"auth": "5033f59755e10b0e86c63c998be61aa4","id": 0}' http://127.0.0.1/api_jsonrpc.php

      fi

      if [ $zabbix_key = "system.cpu.util[,idle]" ]; then
         cpu_user_hig=$(sed -i 's/itemid/\n/g' cpu_user_id.txt && grep -Po 'value.+ns' cpu_user_id.txt | cut -f3 -d '"' | sort | head -1)
      else
         cpu_user_hig=$(sed -i 's/itemid/\n/g' cpu_user_id.txt && grep -Po 'value.+ns' cpu_user_id.txt | cut -f3 -d '"' | sort -hr | head -1)
      fi

      #-------------------平均数计算
      cpu_user_hig_pingjin=$(cat cpu_user_id.txt | sed 's/itemid/\n/g' | grep -Po 'value.+ns' | cut -f3 -d '"')
      pingjin_shu=$(echo -e "$cpu_user_hig_pingjin" | awk '{sum+=$1} END {print "", sum/NR}')

      #-------------------------平均数计算结束

      host_id=$(echo $host | cut -f${i} -d " ")
      echo $zabbix_key host $host_id >>cpu_user_hig.txt
      echo $zabbix_key cpu $cpu_user_hig >>cpu_user_hig.txt
      time=$(cat cpu_user_id.txt | grep $cpu_user_hig | head -1 | cut -f7 -d '"')
      time=$(echo $time | awk '{print strftime("%Y/%m/%d-%H:%M:%S",$0)}')
      echo $zabbix_key time $time >>cpu_user_hig.txt

      if [ $zabbix_key = "system.cpu.util[,idle]" ]; then
         echo $zabbix_key cpu_idel_pj $pingjin_shu >>cpu_user_hig.txt
      elif [ $zabbix_key = "system.cpu.load[all,avg1]" ]; then
         echo $zabbix_key cpu_load_pj $pingjin_shu >>cpu_user_hig.txt
      elif [ $zabbix_key = "vm.memory.size[used]" ]; then
         echo $zabbix_key memory_used_pj $pingjin_shu >>cpu_user_hig.txt
      elif [ $zabbix_key = "net.if.in[eth0]" ]; then
         echo $zabbix_key net_in_pj $pingjin_shu >>cpu_user_hig.txt
      elif [ $zabbix_key = "net.if.out[eth0]" ]; then
         echo $zabbix_key net_out_pj $pingjin_shu >>cpu_user_hig.txt
      elif [ $zabbix_key = "tcp.status[established]" ]; then
         echo $zabbix_key tcp_established_pj $pingjin_shu >>cpu_user_hig.txt
      fi

      rm -rf cpu_user_id.sh cpu_user_id.txt
      if [ $i -eq ${chishu1} ]; then
         xh=$((xh + 1))
      fi
   done
done
#--------------------------cpu_user_hig----------------------------------------
#mail -s "$(echo -e "Hello\nContent-Type: text/html; charset=utf-8")" lijingfeng@mzjmedia.net < lsdjf.html
time_from_num11=$(date +%Y-%m-%d -d "-1 day")
echo '<h1 align="center"> '$time_from_num11' 主机监控数据日报</h1>' >bb.txt
html_moban='<style type="text/css">
table.tftable {font-size:12px;color:#333333;width:100%;border-width: 1px;border-color: #9dcc7a;border-collapse: collapse;}
table.tftable th {font-size:12px;background-color:#abd28e;border-width: 1px;padding: 8px;border-style: solid;border-color: #9dcc7a;text-align:left;}
table.tftable tr {background-color:#bedda7;}
table.tftable td {font-size:12px;border-width: 1px;padding: 8px;border-style: solid;border-color: #9dcc7a;}
</style>

<table id="tfhover" class="tftable" border="1">
<tr><th>Host</th><th>cpu空闲率/%</th><th>平均值%</th><th>cpu最高负载</th><th>平均值</th><th>内存使用/G</th><th>平均值/G</th><th>最高流量(进)/Mb</th><th>平均值/Mb</th><th>最高流量(出)/Mb</th><th>平均值/Mb</th><th>最大TCP连接数</th><th>平均值</th></tr>'

echo $html_moban >>bb.txt

host=$(echo -e "$host" | sort)
chishu=$(echo -e "$host" | wc -l)

for ((i = 1; i <= ${chishu}; i++)); do
   host1=$(echo $host | cut -f${i} -d " ")
   echo $host1

   html_data=$(cat cpu_user_hig.txt | grep $host1 -A 3)
   cpu_user_add=$(echo -e "$html_data" | sed -n '2p' | cut -f3 -d " ")
   cpu_user_pj=$(echo -e "$html_data" | sed -n '4p' | cut -f3 -d " ")
   #cpu_user_time=$(echo -e "$html_data"| sed -n '3p'|cut -f3 -d " ")
   cpu_load_add=$(echo -e "$html_data" | sed -n '7p' | cut -f3 -d " ")
   cpu_load_pj=$(echo -e "$html_data" | sed -n '9p' | cut -f3 -d " ")
   #cpu_load_time=$(echo -e "$html_data"| sed -n '7p'|cut -f3 -d " ")
   memory_used_add=$(echo -e "$html_data" | sed -n '12p' | cut -f3 -d " ")
   memory_used_add=$(echo $memory_used_add | awk '{print $memory_used_add/1073741824}')
   memory_used_pj=$(echo -e "$html_data" | sed -n '14p' | cut -f3 -d " ")
   memory_used_pj=$(echo $memory_used_pj | awk '{print $0/1073741824}')
   #memory_used_time=$(echo -e "$html_data"| sed -n '11p'|cut -f3 -d " ")
   network_in_add=$(echo -e "$html_data" | sed -n '17p' | cut -f3 -d " ")
   network_in_add=$(echo $network_in_add | awk '{print $network_in_add/1000000}')
   network_in_pj=$(echo -e "$html_data" | sed -n '19p' | cut -f3 -d " ")
   network_in_pj=$(echo $network_in_pj | awk '{print $0/1000000}')
   #network_in_time=$(echo -e "$html_data"| sed -n '15p'|cut -f3 -d " ")
   network_out_add=$(echo -e "$html_data" | sed -n '22p' | cut -f3 -d " ")
   network_out_add=$(echo $network_out_add | awk '{print $network_out_add/1000000}')
   network_out_pj=$(echo -e "$html_data" | sed -n '24p' | cut -f3 -d " ")
   network_out_pj=$(echo $network_out_pj | awk '{print $0/1000000}')
   #network_out_time=$(echo -e "$html_data"| sed -n '19p'|cut -f3 -d " ")
   tcp_established_add=$(echo -e "$html_data" | sed -n '27p' | cut -f3 -d " ")
   tcp_established_pj=$(echo -e "$html_data" | sed -n '29p' | cut -f3 -d " ")
   #tcp_established_time=$(echo -e "$html_data"| sed -n '23p'|cut -f3 -d " ")
   echo "<tr><td>$host1</td><td>$cpu_user_add</td><td>$cpu_user_pj</td><td>$cpu_load_add</td><td>$cpu_load_pj</td><td>$memory_used_add</td><td>$memory_used_pj</td><td>$network_in_add</td><td>$network_in_pj</td><td>$network_out_add</td><td>$network_out_pj</td><td>$tcp_established_add</td><td>$tcp_established_pj</td></tr>" >>bb.txt
done
echo "</table>" >>bb.txt

#---------------------------------------------------------
#time_from_num_1=$(date +%Y%m%d -d "-1 day")000000

#sh getItemGraph.sh -U admin -P zabbixSL..99 -I xxxx -s time_from_num_1 -p 864398 -w 800

#-------------------------------------------------------------

#time_from_num=$(date +%Y-%m-%d -d "-1 day")

mail -s "$(echo -e "$time_from_num11 主机监控数据日报 \nContent-Type: text/html; charset=utf-8")" lijingfeng@mzjmedia.net <bb.txt
sleep 2
mail -s "$(echo -e "Hello\nContent-Type: text/html; charset=utf-8")" caifusheng@mzjmedia.net <bb.txt
sleep 3
mail -s "$(echo -e "Hello\nContent-Type: text/html; charset=utf-8")" liming@mzjmedia.com <bb.txt

rm -rf *.txt

# <tr><td>$$host1</td><td>$cpu_user_add</td><td>$cpu_user_time</td><td>$cpu_load_add</td><td>$cpu_load_time</td><td>$memory_used_add</td><td>$memory_used_time</td></tr>
