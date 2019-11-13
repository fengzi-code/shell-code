1. 阿里云申请一年免费证书 Symantec 免费版 SSL

2. 下载证书 apache版本
得到以下三个文件:
证书私钥 1745379_mail.mzjmedia.net.key
证书链 1745379_mail.mzjmedia.net_chain.crt
证书公钥 1745379_mail.mzjmedia.net_public.crt

3. 阿里云提交工单申请根证书文件 ov-root.cer
下载根证书 ov-root.cer

4. 上传4个证书文件

5. 合并证书链
cat ov-root.cer >> 1745379_mail.mzjmedia.net_chain.crt

6.校验证书
命令格式 zmcertmgr verifycrt comm 私钥 公钥 带根证书的证书链
/opt/zimbra/bin/zmcertmgr verifycrt comm 1745379_mail.mzjmedia.net.key 1745379_mail.mzjmedia.net_public.crt 1745379_mail.mzjmedia.net_chain.crt

显示如下表明通过校验
** Verifying 1745379_mail.mzjmedia.net_public.crt against 1745379_mail.mzjmedia.net.key
Certificate (1745379_mail.mzjmedia.net_public.crt) and private key (1745379_mail.mzjmedia.net.key) match.
Valid Certificate: 1745379_mail.mzjmedia.net_public.crt: OK

7.复制私钥到/opt/zimbra/ssl/zimbra/commercial

备份原先的私钥
mv /opt/zimbra/ssl/zimbra/commercial/commercial.key /opt/zimbra/ssl/zimbra/commercial/commercial.key.bak

复制新私钥
cp 1745379_mail.mzjmedia.net.key /opt/zimbra/ssl/zimbra/commercial/commercial.key


8. 更新证书
命令格式 /opt/zimbra/bin/zmcertmgr deploycrt comm 公钥 合并根证书的证书链

/opt/zimbra/bin/zmcertmgr deploycrt comm 1745379_mail.mzjmedia.net_public.crt 1745379_mail.mzjmedia.net_chain.crt

显示如下,不报错表示更新成功.

** Verifying 1745379_mail.mzjmedia.net_public.crt against /opt/zimbra/ssl/zimbra/commercial/commercial.key
Certificate (1745379_mail.mzjmedia.net_public.crt) and private key (/opt/zimbra/ssl/zimbra/commercial/commercial.key) match.
Valid Certificate: 1745379_mail.mzjmedia.net_public.crt: OK
** Copying 1745379_mail.mzjmedia.net_public.crt to /opt/zimbra/ssl/zimbra/commercial/commercial.crt
** Appending ca chain 1745379_mail.mzjmedia.net_chain.crt to /opt/zimbra/ssl/zimbra/commercial/commercial.crt
** Importing certificate /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt to CACERTS as zcs-user-commercial_ca...done.
** NOTE: mailboxd must be restarted in order to use the imported certificate.
** Saving server config key zimbraSSLCertificate...done.
** Saving server config key zimbraSSLPrivateKey...done.
** Installing mta certificate and key...done.
** Installing slapd certificate and key...done.
** Installing proxy certificate and key...done.
** Creating pkcs12 file /opt/zimbra/ssl/zimbra/jetty.pkcs12...done.
** Creating keystore file /opt/zimbra/mailboxd/etc/keystore...done.
** Installing CA to /opt/zimbra/conf/ca...done.

9. 重启zimbra
切换用户 
su zimbra -
/opt/zimbra/bin/zmcontrol restart