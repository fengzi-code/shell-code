#!/bin/sh
#ssh-keygen -t rsa
#ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.1.2 -p 1355
# create self-signed server certificate:
#服务端证书制作
read -p "Enter your domain [www.example.com]: " DOMAIN
echo "Create server key..."
openssl genrsa -des3 -out $DOMAIN.key 1024
echo "Create server certificate signing request..."
SUBJECT="/C=US/ST=Mars/L=iTranswarp/O=iTranswarp/OU=iTranswarp/CN=$DOMAIN"
openssl req -new -subj $SUBJECT -key $DOMAIN.key -out $DOMAIN.csr
echo "Remove password..."
mv $DOMAIN.key $DOMAIN.origin.key
openssl rsa -in $DOMAIN.origin.key -out $DOMAIN.key
echo "Sign SSL certificate..."
openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
#客户端证书制作
openssl genrsa -des3 -out $DOMAIN.client.key 1024
echo "Create server certificate signing request..."
SUBJECT="/C=US/ST=Mars/L=iTranswarp/O=iTranswarp/OU=iTranswarp/CN=$DOMAIN"
openssl req -new -subj $SUBJECT -key $DOMAIN.client.key -out $DOMAIN.client.csr
echo "Remove password..."
mv $DOMAIN.client.key $DOMAIN.origin.client.key
openssl rsa -in $DOMAIN.origin.client.key -out $DOMAIN.client.key
echo "Sign SSL certificate..."
openssl x509 -req -days 3650 -in $DOMAIN.client.csr -signkey $DOMAIN.client.key -out $DOMAIN.client.crt
openssl pkcs12 -export -clcerts -in $DOMAIN.client.crt -inkey $DOMAIN.client.key -out $DOMAIN.client.p12
#删除多余文件
rm -rf $DOMAIN.client.csr $DOMAIN.client.key $DOMAIN.origin.client.key $DOMAIN.origin.key $DOMAIN.csr
echo "TODO:"
echo "Copy $DOMAIN.crt to /opt/soft/nginx/ssl/$DOMAIN.crt"
echo "Copy $DOMAIN.key to /opt/soft/nginx/ssl/$DOMAIN.key"
echo "Copy $DOMAIN.client.crt to /opt/soft/nginx/ssl/$DOMAIN.client.crt"
echo "Add configuration in nginx:"
echo "server {"
echo "    ..."
echo "    listen 443;"
echo "    ssl on;"
echo "    ssl_verify_client on;"
echo "    ssl_certificate     /opt/soft/nginx/ssl/$DOMAIN.crt;"
echo "    ssl_certificate_key /opt/soft/nginx/ssl/$DOMAIN.key;"
echo "    ssl_client_certificate /opt/soft/nginx/ssl/$DOMAIN.client.crt;"
echo "    ssl_protocols           SSLv2 SSLv3 TLSv1;"
echo "}"





