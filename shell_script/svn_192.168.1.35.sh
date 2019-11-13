#!/bin/bash
bak_time=$(date +%Y%m%d)
bak_dir1=/data_backup/192.168.1.35_svn
bak_dir2=$bak_dir1/$bak_time
ip=192.168.1.35
mkdir -p $bak_dir2
find $bak_dir1 -type d -name '20*' -mtime +1 -exec rm -rf {} \;
scp -r $ip:/opt/svn $bak_dir2/
#scp -r $ip:/opt/svn/passwd $bak_dir2/
scp -r $ip:/etc/httpd/conf.d/subversion.conf $bak_dir2/
