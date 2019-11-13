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
[16 ] 172.18.197.170   22     app-17           [mzjdevops] 
[17 ] 172.18.197.160   22     elk-devops-01    [mzjdevops] 
[18 ] 172.18.245.102   22     ELS-01           [mzjdevops] None
[19 ] 172.18.197.114   22     ELS-02           [mzjdevops] None
[20 ] 172.18.197.113   22     ELS-03           [mzjdevops] None
[21 ] 172.18.197.128   22     h5-03            [mzjdevops] 
[22 ] 172.18.197.161   22     h5-04            [mzjdevops] 
[23 ] 172.18.197.164   22     h5api-01         [mzjdevops] 
[24 ] 172.18.197.115   22     h5api-02         [mzjdevops] 
[25 ] 172.18.245.91    22     jenkins-01       [mzjdevops] None
[26 ] 172.18.197.133   22     jiankong         [mzjdevops] None
[27 ] 172.18.197.131   22     job-01           [mzjdevops] None
[28 ] 172.18.197.126   22     job-02           [mzjdevops] None
[29 ] 172.18.197.136   22     job-03           [mzjdevops] None
[30 ] 172.18.197.168   22     job-04           [mzjdevops] 
[31 ] 172.18.197.129   22     jumpserver-01    [mzjdevops] None
[32 ] 172.18.197.116   22     mg-01            [mzjdevops] 
[33 ] 172.18.197.117   22     mg-02            [mzjdevops] 
[34 ] 172.18.245.101   22     MQ-01            [mzjdevops] None
[35 ] 172.18.245.98    22     MQ-02            [mzjdevops] None
[36 ] 172.18.197.169   22     storm-01         [mzjdevops] 
[37 ] 123.207.0.202    1529   tx-hn-app-01     [mzjdevops] 10.0.1.6
[38 ] 123.207.0.202    1530   tx-hn-app-02     [mzjdevops] 10.0.1.10
[39 ] 123.207.0.202    1531   tx-hn-app-03     [mzjdevops] 10.0.1.14
[40 ] 123.207.0.202    1533   tx-hn-db-01      [mzjdevops] 10.0.3.6
[41 ] 123.207.0.202    1532   tx-hn-els-01     [mzjdevops] 10.0.3.14
[42 ] 123.207.0.202    1522   tx-hn-eureka-01  [mzjdevops] 10.0.1.5
[43 ] 123.207.0.202    1524   tx-hn-H5-01      [mzjdevops] 10.0.1.7
[44 ] 123.207.0.202    1525   tx-hn-H5-02      [mzjdevops] 10.0.1.13
[45 ] 123.207.0.202    1526   tx-hn-Job-01     [mzjdevops] 10.0.1.8
[46 ] 123.207.0.202    1527   tx-hn-Job-02     [mzjdevops] 10.0.1.4
[47 ] 123.207.0.202    1523   tx-hn-manager-01 [mzjdevops] 10.0.1.11
[48 ] 123.207.0.202    1528   tx-hn-mq-01      [mzjdevops] 10.0.1.9
[49 ] 123.207.0.202    1534   tx-hn-redis-01   [mzjdevops] 10.0.3.7
[50 ] 172.18.197.127   22     ver-01           [mzjdevops] None
[51 ] 172.18.245.89    22     外网服务器            [mzjdevops] None
[52 ] 172.18.245.88    22     数据库服务器           [mzjdevops] None
')


fun_weifuwu () {
curl  http://123.207.0.202:1110/eureka/apps |awk -F"(<ap)|(port)" '{print $2}' |awk -F"(p>)|(</a)" '{print $2}' >a.txt

curl  http://123.207.0.202:1110/eureka/apps |awk -F"(<instanceId)|(rt>)" '{print $2}' |awk -F"(:)|(0</ins)" '{print $2}' > b.txt


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

		read -p "输入回滚模块序号,如:1.请输入:  " xuhao
                fuwu_name=$(echo -e "${fuwu}" | tr 'A-Z' 'a-z'| grep "序号  $xuhao. " |awk '{print $3}')
                fuwu_port=$(echo -e "${fuwu}" | tr 'A-Z' 'a-z'| grep "序号  $xuhao. " |awk '{print $4}')
					
				if [ $fuwu_name = "eagle-wxuserinfo" ]
				then
				   fuwu_name=eagle-wxuserInfo
				fi
        echo -e "微服务名称:\033[0m \033[44;37m $fuwu_name \033[0m \033[42;37m 端口号:\033[0m \033[44;37m $fuwu_port \033[0m \033[42;37m"
                      
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
					read -p "请输入你要回滚的服务器.输入IP地址:" ipdz
				#sv_port=$(echo -e "${server_name}" | grep -w $ipdz |awk '{print $4}')
				#ipdz=$(echo -e "${server_name}" | grep -w $ipdz |awk '{print $3}')
				sv_port=22
				
 
} 


fun_ver () {

	DIR_SRC=eagle-services
	DIR_DST=/home/eagle/eagle-services
	project_name=$fuwu_name		
		
				
ssh -p $sv_port ${ipdz} "ls ${DIR_DST}/bak/${project_name}_bak" > a.txt

echo -e "\033[42;37m 可以回滚的版本！ \033[0m" 
fuwu=$(cat -n a.txt)
rm -rf a.txt
echo -e "${fuwu}"

read -p "输入回滚的版本序号,如:1.请输入:  " xuhao
                fuwu_name=$(echo -e "${fuwu}" | grep -w "$xuhao" |awk '{print $2}')
echo -e "\033[42;37m 选择的版本为 \033[0m \033[44;37m $fuwu_name \033[0m \033[42;37m 请确认 \033[0m"				

}

fun_fuifu () {
ssh -p $sv_port ${ipdz} "cd ${DIR_DST}/${project_name} && sh stop.sh"

ssh -p $sv_port ${ipdz} "rf -rf ${DIR_DST}/${project_name}/*"

ssh -p $sv_port ${ipdz} "cp -r ${DIR_DST}/bak/${project_name}_bak/${fuwu_name}/ ${DIR_DST}/${project_name}/*"

ssh -p $sv_port ${ipdz} "cd ${DIR_DST}/${project_name} && sh start.sh &"
}







fun_weifuwu
# step2: 选择服务

fun_service_select
fun_confirm
# step3: 显示运行的服务器
fun_fuwu_host
# step4: 输入需要回滚的服务器
fun_fuwu_IP
fun_confirm
# step5: 版本选择

fun_ver
fun_confirm
# step7: 发布到远程服务器

fun_fuifu







