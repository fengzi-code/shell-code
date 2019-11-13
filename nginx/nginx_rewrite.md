# 301跳转设置：
```ruby
server {
listen 80;
server_name 123.com;
rewrite ^/(.*) http://456.com/$1 permanent;
access_log off;
}


server {
   listen 80;
   server_name a.com;
   location = / {
       return 301 b.com$request_uri;
   }
}


server  
        {  
            listen       80;  
            server_name www.test.com www.test.com.cn;  
            index index.html index.htm index.php;  
            root /home/wwwroot;  
      
            if ($host = 'www.test.com.cn' ) {  
                    rewrite ^/(.*)$ http://www.test.com/$1 permanent;  
            }  
            if ($host = 'test.com' ) {  
                    rewrite ^/(.*)$ http://www.test.com/$1 permanent;  
            }  
            if ($host = 'test.com.cn' ) {  
                    rewrite ^/(.*)$ http://www.test.com/$1 permanent;  
            }


```

# 302跳转设置：
```ruby
 server {
listen 80;
server_name 123.com;
rewrite ^/(.*) http://456.com/$1 redirect;
access_log off;
}​

```


# 307跳转设置：

```
server {
    server_name example.com;
    listen 80;
    return 307 https://$server_name$request_uri;
#    return 307 https://example.com$request_uri;
}
```


last – 基本上都用这个Flag。
break – 中止Rewirte，不在继续匹配
redirect – 返回临时重定向的HTTP状态302
permanent – 返回永久重定向的HTTP状态301

Nginx的重定向用到了Nginx的HttpRewriteModule，下面简单解释以下如何使用的方法：
rewrite命令

nginx的rewrite相当于apache的rewriterule(大多数情况下可以把原有apache的rewrite规则加上引号就可以直接使用)，它可以用在server,location 和IF条件判断块中,命令格式如下：
rewrite 正则表达式 替换目标 flag标记
flag标记可以用以下几种格式：
last – 基本上都用这个Flag。
break – 中止Rewirte，不在继续匹配
redirect – 返回临时重定向的HTTP状态302
permanent – 返回永久重定向的HTTP状态301

 

特别注意：

last和break用来实现URL重写，浏览器地址栏的URL地址不变，但是在服务器端访问的路径发生了变化；

redirect和permanent用来实现URL跳转，浏览器地址栏会显示跳转后的URL地址；


例如下面这段设定nginx将某个目录下面的文件重定向到另一个目录,$2对应第二个括号(.*)中对应的字符串：
```
location /download/ {
　　rewrite ^(/download/.*)/m/(.*)\..*$ $1/nginx-rewrite/$2.gz break;
}
```
nginx重定向的IF条件判断

在server和location两种情况下可以使用nginx的IF条件判断，条件可以为以下几种：
正则表达式

如：
匹配判断
~ 为区分大小写匹配; !~为区分大小写不匹配
~* 为不区分大小写匹配；!~为不区分大小写不匹配
例如下面设定nginx在用户使用ie的使用重定向到/nginx-ie目录下：
```
if ($http_user_agent ~ MSIE) {
　　rewrite ^(.*)$ /nginx-ie/$1 break;
}

```
文件和目录判断
-f和!-f判断是否存在文件
-d和!-d判断是否存在目录
-e和!-e判断是否存在文件或目录
-x和!-x判断文件是否可执行
例如下面设定nginx在文件和目录不存在的时候重定向：
```
if (!-e $request_filename) {
　　proxy_pass http://127.0.0.1;
}
return
```
返回http代码，例如设置nginx防盗链：

```
location ~* \.(gif|jpg|png|swf|flv)$ {
　　valid_referers none blocked www.test.com www.test1.com;
　　if ($invalid_referer) {
　　return 404;
　　}
} 
```