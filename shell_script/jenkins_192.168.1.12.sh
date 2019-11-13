#!/bin/bash
bak_time=$(date +%Y%m%d)
bak_dir1=/data_backup/192.168.1.12_jenkins
bak_dir2=$bak_dir1/$bak_time
ip=192.168.1.12
mkdir -p $bak_dir2
ssh -t -p 22 root@$ip "tar -czvf /home/jenkins/backup/jenkins_bakup.tar.gz /home/jenkins/backup/*`date +%Y-%m-%d`*"
scp -r $ip:/home/jenkins/backup/jenkins_bakup.tar.gz $bak_dir2/
ssh -t -p 22 root@$ip "rm -rf /home/jenkins/backup/jenkins_bakup.tar.gz"
find $bak_dir1 -type d -name '20*' -mtime +5 -exec rm -rf {} \;
