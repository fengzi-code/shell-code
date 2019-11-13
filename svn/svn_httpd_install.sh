#!/bin/bash
#开启ssl yum install openssl mod_ssl -y

yum install httpd mod_dav_svn mod_ssl -y
yum install subversion -y



echo '
#LoadModule dav_svn_module     modules/mod_dav_svn.so
#LoadModule authz_svn_module   modules/mod_authz_svn.so
 
<Location /svn>
    DAV svn
    SVNListParentPath on
    SVNPath /opt/svn
    AuthType Basic
    Satisfy Any
    AuthName "Subversion repos"
    AuthUserFile /opt/svn/svn-passwd.conf
#   项目太多,权限配置在每个项目的conf目录下配置
#   AuthzSVNAccessFile /opt/svn/svn-auth.conf
    Require valid-user
</Location>
'  >/etc/httpd/conf.d/subversion.conf





#----------------------------创建版本库-------------------
mkdir -p  /opt/svn
svnadmin create /opt/svn/cdb-config
svnadmin create /opt/svn/PM
svnadmin create /opt/svn/mzj-msconfig
svnadmin create /opt/svn/test-document




htpasswd -bc /opt/svn/svn-passwd.conf cdbadmin zdbQW125gz

htpasswd -b /opt/svn/passwd slinych 123456
#echo '
#[/]
#zsadmin = rw

#[op:/] 
#fz22 =rw
#@fz = rw
#* = 
#这里的 @ 表示接下来的是一个组名，不是用户名。*表示除了上面提到的那些人之外的其余所有人
#' > /opt/svn/svn-auth.conf
chown -R apache:apache /opt/svn



# svnserve --version 查看版本
# svnadmin create /opt/svn/file 创建版本库
# svnserve -d -r /opt/svn/file /opt/svn/file1 后台启动svn
# # --------password.conf---------------
# [users]
# lili = 111111
# # --------password.conf--------------
# 
# # # --------authz.conf--------------
# [aliases]
# [groups]
# [/]
# lili=rw
# 
# # # --------authz.conf--------------
# 
# 
# --------svnserve.conf---------------
# [general]
#匿名访问的权限，可以是read,write,none,默认为read
#anon-access=none
#使授权用户有写权限
#auth-access=write
#密码数据库的路径
#password-db=passwd
#访问控制文件
#authz-db=authz
#认证命名空间，subversion会在认证提示里显示，并且作为凭证缓存的关键字
#realm=/opt/svn/repositories
# --------svnserve.conf---------------