

#!/bin/bash
#########################################################################
# File Name: weixin.sh
# Author: fengzi
# Email: 
# Created Time: Sun 24 Jul 2017 05:48:14 AM CST
#########################################################################
# Functions: send messages to wechat app
# set variables
CropID='  '
Secret='   '
GURL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$CropID&corpsecret=$Secret"
#get acccess_token
Gtoken=$(/usr/bin/curl -s -G $GURL | awk -F\" '{print $10}')
PURL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$Gtoken"
#

function body() {  
        local appId=1000002
        local userId=$1                           
        local partyId=1                      
        local msg=$(echo "$@" | cut -d" " -f3-)   
    printf '{\n'  
        printf '\t"touser":"'"$userId"\"",\n"  
        printf '\t"toparty":"'"$partyId"\"",\n"  
        printf '\t"msgtype": "text",'"\n"  
        printf '\t"agentid":"'"$appId"\"",\n"  
        printf '\t"text":{\n'  
        printf '\t\t"content":"'"$msg"\"  
        printf '\n\t},\n'  
        printf '\t"safe":"0"\n'  
        printf '}\n'  
}  
body $1 $2 $3  
/usr/bin/curl --data-ascii "$(body $1 $2 $3)" $PURL  
