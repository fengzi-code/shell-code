


# 生成密钥


```
keytool -genkey -alias weblogicHL -keyalg RSA -keypass keypass123 -keystore identity.jks -storepass storepass123 -validity 3650 -dname "C=CN, ST=bj, L=bj, O=bonc, OU=bonc, CN=192.168.128.129"

keytool -export -alias weblogicHL -file root.cer -keystore identity.jks

keytool -import -alias weblogicHL -trustcacerts -file root.cer -keystore trust.jks


```

# 密钥库配置

```
定制标识密钥库：/home/weblogic/jksHL/identity.jks
定制信任密钥库：/home/weblogic/jksHL/trust.jks
定制标识/信任密钥类型：jks
定制标识/信任密钥短语: storepass123
```

# ssl 配置

```
私有密钥别名：weblogicHL
私有密钥密码短语：keypass123

高级下勾起 使用 JSSE SSL
```

# 检查

查看config.xml文件是否true,启用ssl

```
<ssl>
      <enabled>true</enabled>
</ssl>
```

启动有文件锁定时

```

find . -name '*.DAT' -print -exec rm {} \;
find . -name '*.lok' -print -exec rm {} \;

```


openssl genrsa -out user-key.pem 1024

openssl req -new -out user-req.csr -key user-key.pem -subj "/C=CN/ST=bj/L=bj/O=test/OU=test/CN=192.168.128.129"

openssl x509 -req -in user-req.csr -out user-cert.pem -signkey user-key.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -days 3650

