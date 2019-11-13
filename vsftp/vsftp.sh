yum install vsftpd -y
#vi /etc/vsftpd/vsftpd.conf在配置文件中找到“anonymous_enable=YES”，将"YES"改为"No"，将匿名登录禁用。
chkconfig vsftpd on
#创建用户此用户就是用来登录ftp服务器用的。
useradd ftpuser
passwd ftpuser
#设置FTP用户的账号，例如账号为“ftpuser1”，目录为/home/ftpuser1，且设置不允许通过ssh登录。
useradd -d /home/ftpuser -s /sbin/nologin ftpuser
passwd ftpuser

# /etc/vsftpd/vsftpd.conf　　主配置文件

# /etc/vsftpd/ftpusers　　黑名单

# /etc/vsftpd/vsftpd_conf_migrate.sh　　迁移脚本

# /etc/vsftpd/user_list　　用户列表，与userlist_enbale和userlist_deny选项密切相关，详见http://blog.csdn.net/bluishglc/article/details/42273197


anonymous_enable=NO
#是否允许anonymous登录FTP服务器，默认设置为YES（允许）
local_enable=YES
#是否允许本地用户登录FTP服务器，默认设置为YES（允许）
write_enable=YES
#是否允许用户对FTP服务器具有写权限，默认设置为YES（允许）
local_umask=022
#设置本地用户的文件生成掩码，默认为022
#anon_upload_enable=YES
#是否允许匿名用户上传文件，默认设置为YES（允许）。
#anon_mkdir_write_enable=YES
#是否允许匿名用户创建新文件夹。默认设置为YES（允许）
dirmessage_enable=YES
#是否激活目录欢迎信息功能，当用户首次访问服务器上的某个目录时，FTP服务器将显示欢迎信息。默认情况下，欢迎信息是通过目录下的.message文件获得的。
xferlog_enable=YES
#是否启用上传和下载记录日志的功能。
connect_from_port_20=NO
#默认情况下，FTP PORT主动模式进行数据传输时使用20端口(ftp-data)。YES使用，NO不使用
listen_port=2121
#ftp监听端口
ftp_data_port=2122
#指定主动模式的端口
pasv_enable=YES
#FTP  PASV被动模式被启用
pasv_min_port=2123
#设定在PASV模式下，建立数据传输所可以使用port范围的下界
pasv_max_port=2131
#设定在PASV模式下，建立数据传输所可以使用port范围的上界
xferlog_std_format=YES
#是否采用标准格式记录日志
ascii_upload_enable=YES
#当设置为YES时，表示允许使用ASCII方式上传
ascii_download_enable=YES
#当设置为YES时，表示允许使用ASCII方式下载文件
chroot_local_user=YES
#不允许所有用户访问家目录及子目录以外的目录
chroot_list_enable=YES
#chroot_list_file=/etc/vsftpd/chroot_list
#不允许某些用户访问家目录及子目录以外的目录
#当chroot_local_user=YES时，则chroot_list中用户可以访问所有目录
#当chroot_local_user=NO时，则chroot_list中用户不可以访问家目录及子目录以外的目录

ls_recurse_enable=YES
#是否允许使用ls -R等命令
listen=YES
#开启ipv4监听
listen_ipv6=NO
#开启ipv6监听
pam_service_name=vsftpd
#使用pam模块控制，vsftpd文件在/etc/pam.d目录下
#userlist_enable=YES
#userlist_deny=NO
#userlist_file=/etc/vsftpd/user_list
tcp_wrappers=YES
#tcp_wrappers是linux中一个安全机制[TCP_wrappers防火墙]，是否允许TCP_wrappers管理
allow_writeable_chroot=YES
#如果用户被限定在了其主目录下，如果检查发现还有写权限，就会报该错误。此参数修复这个错误
#anon_upload_enable=YES
#允许匿名上传文件
#anon_mkdir_write_enable=YES
#允许匿名建立文件夹（默认也被注释了）
#anon_other_write_enable=YES
#允许匿名删除和修改上传的文件；
#ssl
ssl_enable=YES
#是否启用 SSL,默认为no
allow_anon_ssl=NO
#是否允许匿名用户使用SSL
force_local_data_ssl=YES
#非匿名用户传输数据时是否加密
force_local_logins_ssl=YES
#非匿名用户登陆时是否加密
ssl_tlsv1=YES
#是否激活tls v1加密,默认yes
ssl_sslv2=NO
#是否激活sslv2加密,默认no
ssl_sslv3=NO
#是否激活sslv3加密,默认no
rsa_cert_file=/etc/vsftpd/ssl/ftp.xiazaibei.com.crt
#rsa证书的位置
rsa_private_key_file=/etc/vsftpd/ssl/ftp.xiazaibei.com.key
