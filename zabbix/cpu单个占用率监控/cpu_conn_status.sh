#!/bin/bash
#zabbix 取单个cpu占用率
cpu_id=$1

aa=$(cat /proc/stat | grep cpu$cpu_id)
#user、nice、system、idle、iowait、irq、softirq、stealstolen、guest
cpu_user=$(echo $aa |cut -f2 -d " ")
cpu_nice=$(echo $aa |cut -f3 -d " ")
cpu_system=$(echo $aa |cut -f4 -d " ")
cpu_idle2=$(echo $aa |cut -f5 -d " ")
cpu_iowait=$(echo $aa |cut -f6 -d " ")
cpu_irq=$(echo $aa |cut -f7 -d " ")
cpu_softirq=$(echo $aa |cut -f8 -d " ")
cpu_stealstolen=$(echo $aa |cut -f9 -d " ")
cpu_guest=$(echo $aa |cut -f10 -d " ")
cpu_total2=$[ cpu_user + cpu_nice + cpu_system + cpu_idle2 + cpu_iowait + cpu_irq + cpu_softirq + cpu_stealstolen + cpu_guest ]

mkdir -p /tmp/cpuinfo/

cpu_total1=$(cat /tmp/cpuinfo/cpu_total_$cpu_id.txt)
cpu_idle1=$(cat /tmp/cpuinfo/cpu_idle_$cpu_id.txt)

if [ -z "$cpu_total1" ];then
    
    echo "没有记录值"
else
    cpu_total=$[ cpu_total2 - cpu_total1 ]
    cpu_idle=$[ cpu_idle2 - cpu_idle1 ]
    cpu_idle=$[ cpu_total - cpu_idle ]
    #    echo $cpu_idle $cpu_total
    pcpu=$(echo "$cpu_total $cpu_idle"| awk '{printf ("%.2f\n",100*($2/$1))}')
fi
#echo $cpu_total2
echo $cpu_total2 > /tmp/cpuinfo/cpu_total_$cpu_id.txt
echo $cpu_idle2 > /tmp/cpuinfo/cpu_idle_$cpu_id.txt

echo $pcpu

