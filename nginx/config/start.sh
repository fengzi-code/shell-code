#!/bin/bash
nohup java -jar -Xms64m -Xmx256m eagle-wxsimulator-0.1.jar --profiles=uat --defaultZone=http://eureka.eagle.mzj.net:1110/eureka --logging.level.root=INFO --logging.file=/home/eagle/eagle-services/eagle-wxsimulator/log/eagle-wxsimulator.log >/dev/null &
