#!/bin/bash
cat > /etc/yum.repos.d/gitlab-ce.repo<< EOF
[gitlab-ce]
name=gitlab-ce
baseurl=http://mirrors.zju.edu.cn/gitlab-ce/yum/el7/
repo_gpgcheck=0
gpgcheck=0
enabled=1
gpgkey=https://packages.gitlab.com/gpg.key
EOF
sudo yum makecache
sudo yum install -y gitlab-ce
/bin/cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.bak
#修改访问网址
sed -i 's/http:\/\/gitlab.example.com/http:\/\/gitlab.baidu.com/g' /etc/gitlab/gitlab.rb
#配置发送邮箱
cat >> /etc/gitlab/gitlab.rb << EOF
gitlab_rails['smtp_enable'] = true
gitlab_rails['gitlab_email_from'] = "mzjops@163.com"
gitlab_rails['gitlab_email_reply_to'] = "mzjops163.com"
user["git_user_email"] = "mzjops@163.com"
gitlab_rails['smtp_address'] = "smtp.163.com"
gitlab_rails['smtp_port'] = 994
gitlab_rails['smtp_user_name'] = "mzjops@163.com"
gitlab_rails['smtp_password'] = "1q2w3e4r5t"
gitlab_rails['smtp_domain'] = "163.com"
gitlab_rails['smtp_authentication'] = :login
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
EOF
###邮件测试
#gitlab-rails console
#Notify.test_email('235546@qq.com', '测试一下', '邮件正文').deliver_now
############################qq邮箱配置
#gitlab_rails['smtp_enable'] = true
#gitlab_rails['smtp_address'] = "smtp.qq.com"
#gitlab_rails['smtp_port'] = 465
#gitlab_rails['smtp_user_name'] = "******@qq.com"
#gitlab_rails['smtp_password'] = "授权码"
#gitlab_rails['smtp_domain'] = "smtp.qq.com"
#gitlab_rails['smtp_enable_starttls_auto'] = true
#gitlab_rails['smtp_authentication'] = "login"
#gitlab_rails['smtp_tls'] = true
# gitlab_rails['gitlab_email_from'] = '******@qq.com'
# 汉化
# 查看当前版本
ver=$(cat /opt/gitlab/embedded/service/gitlab-rails/VERSION)
yum install -y git
#git clone https://gitlab.com/xhang/gitlab.git
git clone https://gitlab.com/xhang/gitlab.git -b v${ver}-zh
/bin/cp ./gitlab/* /opt/gitlab/embedded/service/gitlab-rails/  -rf
#汉化结束
gitlab-ctl reconfigure
gitlab-ctl start
###不低于4G内存