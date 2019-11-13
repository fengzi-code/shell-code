#!/bin/bash
#ssh-keygen -t rsa
#ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.1.2 -p 1355

lujin=$(pwd)
ssh-keygen -t rsa

#Mail.Mzj25

cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

echo "请下载私钥到需要登陆的机器上"
yum install -y lrzsz
sz /root/.ssh/id_rsa
echo "删除服务器私钥"
rm -rf /root/.ssh/id_rsa
echo "修改sshd_config文件.关闭密码登陆修改端口为12306"
cp /etc/ssh/sshd_config  /etc/ssh/sshd_config.$(date +%F)
echo "
StrictModes yes
PubkeyAuthentication yes
PasswordAuthentication no
Port 12306" >> /etc/ssh/sshd_config

systemctl restart sshd.service

cd $lujin
rm -rf "$0"