#!/bin/bash
name_dl=$1
messages=$2

info=$(curl -s -i -u admin:admin "http://localhost:15672/api/queues"|sed 's/messages_details/\\n/g')

info=$(echo -e "$info"|grep -v spring |grep name)

name=$(echo -e "$info" |grep -Po name.*message_bytes_paged_out |cut -f3 -d '"')

messages_ready=$(echo -e "$info" |grep -Po messages_ready.*reductions_details |cut -f6 -d '"'|cut -f2 -d ':'|cut -f1 -d ',')

messages_unack=$(echo -e "$info" |grep -Po messages_unacknowledged\":.*messages_ready_details |cut -f2 -d ':'|cut -f1 -d ',')

messages_total=$(echo -e "$info" |grep -Po messages\":.*messages_unacknowledged_details |cut -f2 -d ':'|cut -f1 -d ',')

host=$(echo -e "$info" |grep -Po rabbit@mq.*arguments |cut -f1 -d '"')


hs=$(echo -e "$name" |grep -n ^$name_dl$ | cut -f1 -d ':')

if [ $messages = "messages_ready" ]
then
	echo -e "$messages_ready" |sed -n "${hs}p"
elif [ $messages = "messages_unack" ]
then
	echo -e "$messages_unack" |sed -n "${hs}p"
elif [ $messages = "messages_total" ]
then
	echo -e "$messages_total" |sed -n "${hs}p"
fi


