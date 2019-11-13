#!/bin/bash


#服务器名字
server_name=$(echo '服务器名字IP对应表
[0  ] 172.18.245.99    22     app-01           [mzjdevops] 
[1  ] 172.18.245.95    22     app-02           [mzjdevops] 
[2  ] 172.18.245.100   22     app-03           [mzjdevops] 
[3  ] 172.18.245.96    22     app-04           [mzjdevops] 
[4  ] 172.18.245.97    22     app-05           [mzjdevops] 
[5  ] 172.18.197.130   22     app-06           [mzjdevops] None
[6  ] 172.18.197.137   22     app-07           [mzjdevops] None
[7  ] 172.18.197.132   22     app-08           [mzjdevops] None
[8  ] 172.18.197.134   22     app-09           [mzjdevops] None
[9  ] 172.18.197.138   22     app-10           [mzjdevops] None
[10 ] 172.18.197.135   22     app-11           [mzjdevops] None
[11 ] 172.18.197.156   22     app-12           [mzjdevops] 
[12 ] 172.18.197.158   22     app-13           [mzjdevops] 
[13 ] 172.18.197.159   22     app-14           [mzjdevops] 
[14 ] 172.18.197.157   22     app-15           [mzjdevops] 
[15 ] 172.18.197.160   22     elk-devops-01    [mzjdevops] 
[16 ] 172.18.245.102   22     ELS-01           [mzjdevops] None
[17 ] 172.18.197.114   22     ELS-02           [mzjdevops] None
[18 ] 172.18.197.113   22     ELS-03           [mzjdevops] None
[19 ] 172.18.197.115   22     h5-02            [mzjdevops] 
[20 ] 172.18.197.128   22     h5-03            [mzjdevops] 
[21 ] 172.18.197.161   22     h5-04            [mzjdevops] 
[22 ] 172.18.245.91    22     jenkins-01       [mzjdevops] None
[23 ] 172.18.197.133   22     jiankong         [mzjdevops] None
[24 ] 172.18.197.131   22     job-01           [mzjdevops] None
[25 ] 172.18.197.126   22     job-02           [mzjdevops] None
[26 ] 172.18.197.136   22     job-03           [mzjdevops] None
[27 ] 172.18.197.129   22     jumpserver-01    [mzjdevops] None
[28 ] 172.18.197.116   22     mg-01            [mzjdevops] 
[29 ] 172.18.197.117   22     mg-02            [mzjdevops] 
[30 ] 172.18.245.101   22     MQ-01            [mzjdevops] None
[31 ] 172.18.245.98    22     MQ-02            [mzjdevops] None
[32 ] 123.207.0.202    1529   tx-hn-app-01     [mzjdevops] 
[33 ] 123.207.0.202    1530   tx-hn-app-02     [mzjdevops] 
[34 ] 123.207.0.202    1531   tx-hn-app-03     [mzjdevops] 
[35 ] 123.207.0.202    1533   tx-hn-db-01      [mzjdevops] 
[36 ] 123.207.0.202    1532   tx-hn-els-01     [mzjdevops] 
[37 ] 123.207.0.202    1522   tx-hn-eureka-01  [mzjdevops] 
[38 ] 123.207.0.202    1524   tx-hn-H5-01      [mzjdevops] 
[39 ] 123.207.0.202    1525   tx-hn-H5-02      [mzjdevops] 
[40 ] 123.207.0.202    1526   tx-hn-Job-01     [mzjdevops] 
[41 ] 123.207.0.202    1527   tx-hn-Job-02     [mzjdevops] 
[42 ] 123.207.0.202    1523   tx-hn-manager-01 [mzjdevops] 
[43 ] 123.207.0.202    1528   tx-hn-mq-01      [mzjdevops] 
[44 ] 123.207.0.202    1534   tx-hn-redis-01   [mzjdevops] 
[45 ] 172.18.197.127   22     ver-01           [mzjdevops] None
[46 ] 172.18.245.89    22     外网服务器            [mzjdevops] None
[47 ] 172.18.245.88    22     数据库服务器           [mzjdevops] None
')



fun_weifuwu () {
curl  http://172.18.245.95:1110/eureka/apps |awk -F"(<ap)|(port)" '{print $2}' |awk -F"(p>)|(</a)" '{print $2}' >a.txt

curl  http://172.18.245.95:1110/eureka/apps |awk -F"(<instanceId)|(rt>)" '{print $2}' |awk -F"(:)|(0</ins)" '{print $2}' > b.txt


cat b.txt |grep -v "^$" |awk ' !x[$0]++' |grep -v "instanceId"> bb.txt
cat a.txt |grep -v "^$" |grep -v 'pps'|awk ' !x[$0]++' >aa.txt
chishu=$(cat aa.txt|wc -l)
  for((i=1;i<=${chishu};i++));
      do
         awb=$(sed -n ${i}p aa.txt)
         bwb=$(sed -n ${i}p bb.txt)
		 sed -i "${i}s/${awb}/序号 ${i}. ${awb} ${bwb}0/" aa.txt
	done
sed -i '1i序号 --- -----微服务------------------ -端口-----#' aa.txt												
echo -e "${fuwu}" >> aa.txt
fuwu=$(column -t aa.txt) 
rm -rf a.txt b.txt aa.txt bb.txt

}


fun_service_select () {
		clear
		#printf "\033c"
		echo -e "${fuwu}" 

		read -p "输入发布模块序号,如:1.请输入:  " xuhao
                fuwu_name=$(echo -e "${fuwu}" | tr 'A-Z' 'a-z'| grep "序号  $xuhao. " |awk '{print $3}')
                fuwu_port=$(echo -e "${fuwu}" | tr 'A-Z' 'a-z'| grep "序号  $xuhao. " |awk '{print $4}')
					
				if [ $fuwu_name = "eagle-wxuserinfo" ]
				then
				   fuwu_name=eagle-wxuserInfo
				fi
        echo -e "微服务名称:\033[0m \033[44;37m $fuwu_name \033[0m \033[42;37m 端口号:\033[0m \033[44;37m $fuwu_port \033[0m \033[42;37m"
        echo -e "\033[41;30m 是否需要更换端口.需要请按y，不需要按回车键 \033[0m \c"
				
				 	read port1
					if [ "$port1" = 'y' ]; then
						echo -e "\033[44;30m 请输入端口号: \033[0m \c"
						read port1
						fuwu_port=$port1
						port2="jia"
					echo -e "微服务名称:\033[0m \033[44;37m $fuwu_name \033[0m \033[42;37m 端口号:\033[0m \033[44;37m $fuwu_port \033[0m \033[42;37m"
						fi
		
               
}




fun_confirm () {
	echo -e "\033[44;30m 确认按y，退出按其他键 \033[0m \c"
	read confirm
        if [ $confirm != 'y' ]; then
                echo "安装退出"
				exit
        fi
}



fun_fuwu_host () {

curl -s http://172.18.245.95:1110/eureka/apps/$fuwu_name |grep instanceId | awk -F'>' '{print $2}'|awk -F':' '{print $1}' >a.txt

					   
												chishu=$(cat a.txt|wc -l)

                                                for((i=1;i<=${chishu};i++));
                                                do
                                                ipwb=$(sed -n ${i}p a.txt)

                                                server_name1=$(echo "$server_name" | grep ${ipwb} |awk '{print $5}')

                                                sed -i "${i}s/${ipwb}/${ipwb} ${server_name1}/" a.txt
                                                done
	

echo -e "\033[42;37m 项目被关闭的主机不会在此列出 \033[0m" 
echo -e "\033[42;37m 目前 \033[0m \033[44;37m $fuwu_name \033[0m \033[42;37m 开启的服务器 \033[0m"
cat a.txt 
rm -rf a.txt
}




fun_fuwu_IP () {
					read -p "请输入你要发布到哪个服务器.输入IP地址:" ipdz
 
} 







fun_mvn () {

#svn checkout http://219.135.214.58:8888/svn/mzj/V2/trunk/mzj-microservice/eagle-services  --username produsr001 --password Mzj@123! && cd eagle-services &&  mvn package -Dmaven.test.skip=true && cd $lujin
cd /apps/deploy/git/eagle-services/$fuwu_name && git checkout . && git clean -xdf && git pull $git_url && mvn package -Dmaven.test.skip=true && cd $lujin
echo "完毕"
}


fun_script () {
	DIR_SRC=git/eagle-services
	DIR_DST=/home/eagle/eagle-services
	project_name=$fuwu_name		
		
				if [ "$port2" != "jia" ]; then
				startsh="start.sh"
				stopsh="stop.sh"
					else
					 startsh=start${fuwu_port}.sh
					 stopsh=stop${fuwu_port}.sh
						fi
		
        cat > ${DIR_SRC}/${project_name}/target/${startsh} << EOF
#!/bin/bash
source /etc/profile
nohup java -jar -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=1$fuwu_port -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=true -Djava.rmi.server.hostname=$ipdz -Dcom.sun.management.jmxremote.password.file=$JAVA_HOME/jmxremote.password -Dcom.sun.management.jmxremote.access.file=$JAVA_HOME/jmxremote.access -Xms1024m -Xmx1024m ${project_name}-0.1.jar --profiles=prod --defaultZone="http://eureka01.eagle.mzj.net:1110/eureka,http://eureka02.eagle.mzj.net:1110/eureka" --logging.level.root=WARN --port=${fuwu_port} --logging.file=/home/eagle/eagle-services/${project_name}/log/${project_name}.log >/dev/null &
echo "启动完毕"
exit
EOF






        cat > ${DIR_SRC}/${project_name}/target/${stopsh} << EOF
#!/bin/bash
#pro_num=\`ps -ef | grep ${project_name} | grep -v grep |grep -v tail | awk '{print \$2}'\`
pro_num=\`netstat -lpn |grep java |grep ${fuwu_port} |awk '{print \$7}'|cut -f1 -d "/" |sort -u\`
echo "------process num ="\$pro_num

curl -s --connect-timeout 3 -X POST http://localhost:${fuwu_port}/shutdown && echo 端口关闭

kill -9 \$pro_num
echo "------killed eagle-ad process"
exit
EOF

        #清理文档目录
        cat > ${DIR_SRC}/${project_name}/target/clear.sh << EOF
#!/bin/bash
find /home/eagle/eagle-services/bak/  -type d -name "*_bak" -mtime +7 -exec rm -rf {} \; || true
mkdir -p /home/eagle/eagle-services/bak/${project_name}_bak
mkdir -p $JAVA_HOME
cp -r /home/eagle/eagle-services/${project_name}   /home/eagle/eagle-services/bak/${project_name}_bak/${project_name}_`date +%Y%m%d_%H%M%S`_bak || true
rm -rf  /home/eagle/eagle-services/${project_name}/lib/*.jar || true
mkdir -p log
echo "mzj readonly" > $JAVA_HOME/jmxremote.access
echo "mzj Mzj@q.com" > $JAVA_HOME/jmxremote.password
chmod 600 $JAVA_HOME/jmxremote*
echo "清理完毕"
exit
EOF

}


fun_deploy () {
        ssh $ipdz "[ ! -d ${DIR_DST}/${project_name} ];mkdir -p ${DIR_DST}/${project_name}"
        scp -r ${DIR_SRC}/${project_name}/target/clear.sh $ipdz:${DIR_DST}/${project_name}/ 
        ssh ${ipdz} "chmod 755 ${DIR_DST}/${project_name}/*.sh;cd ${DIR_DST}/${project_name} && sh clear.sh &" 
        scp -r ${DIR_SRC}/${project_name}/target/lib ${DIR_SRC}/${project_name}/target/*.sh ${DIR_SRC}/${project_name}/target/*.jar $ipdz:${DIR_DST}/${project_name} 
	if [ $fuwu_name = eagle-wxapi ];then
		scp -r /apps/deploy/git/imageFile ${ipdz}:/home/eagle/eagle-services/eagle-wxapi
		scp -r /apps/deploy/git/*.jar ${ipdz}:/usr/java/jdk1.8.0_144/jre/lib/security/
		fi		
		if [ "$port2" != "jia" ]; then
				ssh ${ipdz} "chmod 755 ${DIR_DST}/${project_name}/*.sh && cd ${DIR_DST}/${project_name} && sh ${stopsh}"
						fi
		ssh ${ipdz} "chmod 755 ${DIR_DST}/${project_name}/*.sh && cd ${DIR_DST}/${project_name} && sh ${startsh} &"
		
}

fun_rizhi () {
user_rizhi=$(whoami)
time_rizhi=$(date +%Y-%m-%d/%T)
echo ${time_rizhi} ${project_name} user:${user_rizhi} update to ${ipdz}:${fuwu_port}  >> deploy.log
}

fun_queren () {
        echo -e "\033[44;30m 确认按y，退出按其他键 \033[0m \c"
        read confirm
        if [ $confirm != 'y' ]; then
                echo "不打包"
                            
        fi
}

fun_weifuwu1 () {
fuwu="
序号  ---  -----微服务------------------  -端口-----#
序号  1.   EAGLE-SCALE                    2120
序号  2.   EAGLE-ELS                      2160
序号  3.   CONFIG-SERVER                  1130
序号  4.   EAGLE-SCREENDATA               3170
序号  5.   EAGLE-OSS                      2190
序号  6.   EAGLE-MAPAPI                   3160
序号  7.   EAGLE-WXUSERINFO               3130
序号  8.   EAGLE-WXMANAGER                3110
序号  9.   EAGLE-AD                       2180
序号  10.  EAGLE-WIKI                     3210
序号  11.  EAGLE-WXUSER                   3120
序号  12.  EAGLE-HEARTBEAT                2130
序号  13.  EAGLE-HEALTH                   2140
序号  14.  EAGLE-WXAPI                    3140
序号  15.  EAGLE-SYSMANAGER               3150
序号  16.  EAGLE-HROA                     3180
序号  17.  EAGLE-BD                       3170
"
}

fun_git_url () {
git_url_all="git@gl.mzjmedia.net:services/eagle-health.git
git@gl.mzjmedia.net:services/eagle-heartbeat.git
git@gl.mzjmedia.net:services/eagle-hroa.git
git@gl.mzjmedia.net:services/eagle-mapapi.git
git@gl.mzjmedia.net:services/eagle-oss.git
git@gl.mzjmedia.net:services/eagle-scale.git
git@gl.mzjmedia.net:services/eagle-sysmanager.git
git@gl.mzjmedia.net:services/eagle-wxapi.git
git@gl.mzjmedia.net:services/eagle-wxmanager.git
git@gl.mzjmedia.net:services/eagle-wxuser.git
git@gl.mzjmedia.net:services/eagle-wxuserInfo.git
git@gl.mzjmedia.net:services/eagle-els.git
git@gl.mzjmedia.net:services/eagle-wiki.git
git@gl.mzjmedia.net:services/eagle-screendata.git
git@gl.mzjmedia.net:BD/eagle-bd.git
"
git_url=$(echo -e "${git_url_all}" | grep $fuwu_name.git |awk '{print $1}')
}

fun_common () {
cd /apps/deploy/git/eagle-services/eagle-commons && git checkout . && git clean -xdf && git pull git@gl.mzjmedia.net:manage/eagle-commons.git && mvn clean install -Dmaven.test.skip=true && cd $lujin
}

lujin=$(pwd)
# step1: 显示服务
#fun_weifuwu
fun_weifuwu1
# step2: 选择服务

fun_service_select
fun_confirm
# step3: 显示运行的服务器
fun_fuwu_host
# step4: 输入需要更新的服务器
fun_fuwu_IP
fun_confirm
# step5: 取git地址
echo -e "\033[44;30m 是否进行mvn clean install \033[0m \c"
        read confirm
        if [ $confirm == 'y' ]; then
           fun_common

        fi
# step5: 取git地址
fun_git_url

# step5: 源码打包
echo -e "\033[44;30m 是否进行源码打包.确认按y，不打包按其他键 \033[0m \c"
        read confirm
        if [ $confirm == 'y' ]; then
           fun_mvn

        fi

#fun_mvn
fun_confirm
# step6: 生成远程脚本
fun_script
# step7: 发布到远程服务器
fun_deploy
# step8: 写入日志
fun_rizhi



