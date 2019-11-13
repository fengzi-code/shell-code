#/bin/sh
vhost=$1
nodes=$2


info=$(curl -s -i -u admin:admin "http://localhost:15672/api/nodes"|sed 's/partitions/\\n/g'|grep  $vhost.log)
#info=$(curl -s -i -u admin:admin "http://localhost:15672/api/nodes"|sed 's/partitions/\\n/g'|grep  mq-01.log)

#echo -e "$info" | grep mq-01.log


			echo -e "$info" | grep $vhost.log |grep -Po $nodes\".+$nodes|cut -f2 -d ':' |cut -f1 -d ','

			#echo -e "$info" |grep mq-01.log|grep -Po disk_free\".+disk_free|cut -f2 -d ':' |cut -f1 -d ','