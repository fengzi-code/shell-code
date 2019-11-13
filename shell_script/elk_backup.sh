#!/bin/bash

DATE=`date +%Y%m%d`
cd /apps/backup/

#具体配置信息
elasticdump --ignore-errors=true  --scrollTime=120m  --bulk=true --input=http://localhost:9200/.kibana   --output=${DATE}_data.json  --type=data
 
#导出mapping信息
elasticdump --ignore-errors=true  --scrollTime=120m  --bulk=true --input=http://localhost:9200/.kibana   --output=${DATE}_mapping.json  --type=mapping  

#####################################
#恢复
#导入mapping
#elasticdump --input=mapping.json  --output=http://localhost:9000/.kibana --type=mapping
#导入具体的kibana配置信息
#elasticdump --input=data.json  --output=http://localhost:9200/.kibana --type=data
