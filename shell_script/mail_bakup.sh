#!/bin/bash
bak_time=$(date +%Y%m%d)
bak_dir1=/data1/backups/mail
bak_dir2=$bak_dir1/$bak_time
mkdir -p $bak_dir2
ip=172.18.197.182
scp -r $ip:/opt/zimbra/ssl $bak_dir2/
scp -r $ip:/opt/zimbra/backup/ldap.bak $bak_dir2/
find $bak_dir1 -type d -name '20*' -mtime +5 -exec rm -rf {} \;
