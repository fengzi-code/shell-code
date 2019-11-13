
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
[15 ] 172.18.197.165   22     app-16           [mzjdevops] newmedia
[16 ] 172.18.197.179   22     app-17           [mzjdevops] 
[17 ] 172.18.197.188   22     app-18           [mzjdevops] 
[18 ] 172.18.197.185   22     app-19           [mzjdevops] 
[19 ] 172.18.197.180   22     app-20           [mzjdevops] 
[20 ] 172.18.197.178   22     app-21           [mzjdevops] 
[21 ] 172.18.197.184   22     app-22           [mzjdevops] 
[22 ] 172.18.197.170   22     bd-01            [mzjdevops] 
[23 ] 172.18.197.190   22     db-01            [mzjdevops] 
[24 ] 172.18.197.160   22     elk-devops-01    [mzjdevops] 
[25 ] 172.18.245.102   22     els-01           [mzjdevops] 
[26 ] 172.18.197.114   22     els-02           [mzjdevops] 
[27 ] 172.18.197.113   22     els-03           [mzjdevops] 
[28 ] 172.18.197.115   22     els-04           [mzjdevops] 
[29 ] 172.18.197.191   22     fans-01          [mzjdevops] 
[30 ] 172.18.197.192   22     fans-02          [mzjdevops] 
[31 ] 172.18.197.193   22     fans-03          [mzjdevops] 
[32 ] 172.18.197.194   22     fans-04          [mzjdevops] 
[33 ] 172.18.197.164   22     h5-01            [mzjdevops] 
[34 ] 172.18.197.181   22     h5-02            [mzjdevops] 
[35 ] 172.18.197.128   22     h5-03            [mzjdevops] 
[36 ] 172.18.197.161   22     h5-04            [mzjdevops] 
[37 ] 172.18.245.91    22     jenkins-01       [mzjdevops] None
[38 ] 172.18.197.133   22     jiankong         [mzjdevops] None
[39 ] 172.18.197.131   22     job-01           [mzjdevops] None
[40 ] 172.18.197.126   22     job-02           [mzjdevops] None
[41 ] 172.18.197.136   22     job-03           [mzjdevops] None
[42 ] 172.18.197.168   22     job-04           [mzjdevops] 
[44 ] 172.18.197.182   22     mail             [mzjdevops] 
[45 ] 172.18.197.116   22     mg-01            [mzjdevops] 
[46 ] 172.18.197.117   22     mg-02            [mzjdevops] 
[47 ] 172.18.245.101   22     MQ-01            [mzjdevops] None
[48 ] 172.18.245.98    22     MQ-02            [mzjdevops] None
[49 ] 172.18.197.187   22     mzj-01           [mzjdevops] jira wiki
[50 ] 172.18.197.195   22     mzj-02           [mzjdevops] 
[51 ] 172.18.197.169   22     storm-01         [mzjdevops] 
[52 ] 172.18.197.183   22     storm-02         [mzjdevops] 
[53 ] 172.18.197.189   22     storm-03         [mzjdevops] 
[72 ] 172.18.197.127   22     ver-01           [mzjdevops] None
[73 ] 172.18.197.186   22     w7-01            [mzjdevops] 
')


fuwu=$(echo '
序号 ------- ---Job------------ --端口#
序号 1.     EAGLE-HB             7040
序号 2.     EAGLE-MONITOR        7030
序号 3.     EAGLE-STATISTICS     7020
序号 4.     EAGLE-TASK           7010
序号 5.     EAGLE-USERWEIGHT     7050
序号 6.     EAGLE-WEIGHT         7060
序号 7.     EAGLE-ADDISPLAY      7070
序号 8.     EAGLE-WECHAT-EXECUTOR 7040
序号 9.     EAGLE-STATISTICS-EXECUTOR 7020
序号 10.    EAGLE-MONITOR-EXECUTOR 7030
序号 11.    EAGLE-BD-EXECUTOR 9020
')



fun_weifuwu () {
echo -e ${fuwu}

}

fun_git_url () {
git_url_all="git@gl.mzjmedia.net:jobs/eagle-hb.git
git@gl.mzjmedia.net:jobs/eagle-task.git
git@gl.mzjmedia.net:jobs/eagle-userweight.git
git@gl.mzjmedia.net:jobs/eagle-weight.git
git@gl.mzjmedia.net:jobs/eagle-ad-executor.git
git@gl.mzjmedia.net:jobs/eagle-monitor-executor.git
git@gl.mzjmedia.net:jobs/eagle-scalestat-executor.git
git@gl.mzjmedia.net:jobs/eagle-statistics-executor.git
git@gl.mzjmedia.net:jobs/eagle-wechat-executor.git
git@gl.mzjmedia.net:jobs/eagle-addisplay.git
git@gl.mzjmedia.net:jobs/eagle-job-common.git
git@gl.mzjmedia.net:BD/eagle-bd-executor.git
"
git_url=$(echo -e "${git_url_all}" | grep $fuwu_name.git |awk '{print $1}')
}





fun_service_select () {
		clear
		#printf "\033c"
		echo  "${fuwu}" 

		read -p "输入发布模块序号,如:1.请输入:  " xuhao
                fuwu_name=$(echo "${fuwu}" | tr 'A-Z' 'a-z'| grep -w "序号 $xuhao. " |awk '{print $3}')
                fuwu_port=$(echo "${fuwu}" | tr 'A-Z' 'a-z'| grep -w "序号 $xuhao. " |awk '{print $4}')
			echo -e "微服务名称:\033[0m \033[44;37m $fuwu_name \033[0m \033[42;37m 端口号:\033[0m \033[44;37m $fuwu_port \033[0m \033[42;37m"

				echo -e "\033[41;30m 是否需要更换端口.确认请按y，不需要按回车键 \033[0m \c"
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

if [ -a /tmp/$fuwu_name.port ] 
	then
	cat /tmp/$fuwu_name.port
else

echo -e "$server_name" |grep '172.18'|cut -f2 -d ']'|sed s'/ 22 /:/'|cut -f1 -d "[" |sed s/[[:space:]]//g> server.txt
echo -e "\033[42;37m 正在检测安装了 \033[0m \033[44;37m $fuwu_name \033[0m \033[42;37m 的服务器 \033[0m" 
for host_ali in $(cat server.txt)
do
	host_ali1=$(echo -e "$host_ali" |cut -f1 -d ':')
	host_ali2=$(echo -e "$host_ali" |cut -f2 -d ':')
port_num=`ssh -t -q -p 22 root@$host_ali1 "ps -ef|grep $fuwu_name |grep -v 'grep'|wc -l"`
#ssh -t  -p 22 root@$host_ali1 "$cmd" >cccc.txt
port_num=$(echo $port_num|sed s/[[:space:]]//g)
  
if [ $port_num -gt 0 ]
        	then
        	echo "$host_ali1 $host_ali2 $fuwu_port" >> /tmp/$fuwu_name.port
fi
done

echo -e "\033[42;37m 项目被关闭的主机不会在此列出 \033[0m" 
echo -e "\033[42;37m 目前 \033[0m \033[44;37m $fuwu_name \033[0m \033[42;37m 开启的服务器 \033[0m"
cat /tmp/$fuwu_name.port

rm server.txt -rf
fi
}



fun_fuwu_IP () {
					read -p "请输入你要发布到哪个服务器.输入IP地址:" ipdz
 
} 


fun_mvn () {

#svn checkout http://219.135.214.58:8888/svn/mzj/V2/trunk/mzj-microservice/eagle-jobs/  --username produsr001 --password Mzj@123! && cd eagle-jobs &&  mvn package -Dmaven.test.skip=true && cd $lujin
cd /apps/deploy/git/eagle-jobs/$fuwu_name && git checkout . && git clean -xdf && git pull $git_url && mvn package -Dmaven.test.skip=true && cd $lujin
echo "完毕"
}



fun_script () {


							DIR_SRC=git/eagle-jobs
							DIR_DST=/home/eagle/eagle-jobs
							project_name=$fuwu_name
  
							if [ $fuwu_name == "eagle-task" ]
							then
								XPOST="curl -X GET http://localhost:$fuwu_port/weChatUser/stop && echo 端口关闭"   
								Xmxnum=-Xmx1024m
							elif [ $fuwu_name == "eagle-hb" ]
						    then
								XPOST="curl -X GET http://localhost:$fuwu_port/heartbeat/stop && echo 端口关闭"   
								Xmxnum=-Xmx1024m

							 elif [ $fuwu_name == "eagle-userweight" ]
							then
								XPOST="curl -X GET http://localhost:$fuwu_port/userWeight/stop && echo 端口关闭"   
								Xmxnum=-Xmx1024m

							elif [ $fuwu_name == "eagle-weight" ]
							then
								XPOST="curl -X GET http://localhost:$fuwu_port//weight/stop && echo 端口关闭"   
								Xmxnum=-Xmx1024m
							elif [ $fuwu_name == "eagle-monitor" ]
							then
								  
								Xmxnum=-Xmx2048m
								
							elif [ $fuwu_name == "eagle-statistics" ]
							then
								  
								Xmxnum=-Xmx3072m

							fi


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
nohup java -jar -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=1$fuwu_port -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=true -Djava.rmi.server.hostname=$ipdz -Dcom.sun.management.jmxremote.password.file=$JAVA_HOME/jmxremote.password -Dcom.sun.management.jmxremote.access.file=$JAVA_HOME/jmxremote.access -Xms512m ${Xmxnum} ${project_name}-0.1.jar --port=${fuwu_port} --spring.profiles.active=prod --cache=true --is.record.log=true --logging.level.root=WARN --logging.file=/home/eagle/eagle-jobs/${project_name}/log/${project_name}.log >/dev/null &
echo "启动完毕"
exit
EOF






        cat > ${DIR_SRC}/${project_name}/target/${stopsh} << EOF
#!/bin/bash

#pro_num=\`ps -ef | grep ${project_name} | grep -v grep |grep -v tail | awk '{print \$2}'\`

pro_num=\`netstat -lpn |grep java |grep ${fuwu_port} |awk '{print \$7}'|cut -f1 -d "/" |sort -u\`

echo "------process num ="\$pro_num

${XPOST}

kill -9 \$pro_num
echo "------killed eagle-ad process"
exit
EOF

        #清理文档目录
        cat > ${DIR_SRC}/${project_name}/target/clear.sh << EOF
#!/bin/bash
find /home/eagle/eagle-jobs/bak/  -type d -name "*_bak" -mtime +7 -exec rm -rf {} \; || true
mkdir -p /home/eagle/eagle-jobs/bak/${project_name}_bak
mkdir -p $JAVA_HOME
cp -a /home/eagle/eagle-jobs/${project_name}   /home/eagle/eagle-jobs/bak/${project_name}_bak/${project_name}_`date +%Y%m%d_%H%M%S`_bak || true
rm -rf  /home/eagle/eagle-jobs/${project_name}/lib/*.jar || true
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
 
	 
		ssh ${ipdz} "chmod 755 ${DIR_DST}/${project_name}/*.sh && cd ${DIR_DST}/${project_name} && sh ${stopsh}"
		ssh ${ipdz} "chmod 755 ${DIR_DST}/${project_name}/*.sh && cd ${DIR_DST}/${project_name} && sh ${startsh} &"
		
}


fun_rizhi () {
user_rizhi=$(whoami)
time_rizhi=$(date +%Y-%m-%d/%T)
echo ${time_rizhi} ${project_name} user:${user_rizhi} update to ${ipdz}:${fuwu_port}  >> /apps/deploy/deploy.log
}


fun_common () {
cd /apps/deploy/git/eagle-jobs/eagle-job-common && git checkout . && git clean -xdf && git pull git@gl.mzjmedia.net:jobs/eagle-job-common.git && mvn clean install -Dmaven.test.skip=true && cd $lujin
}




lujin=$(pwd)
# step1: 显示服务
fun_weifuwu
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
fun_confirm
# step6: 生成远程脚本
fun_script
# step7: 发布到远程服务器
fun_deploy
# step8: 写入日志
fun_rizhi



