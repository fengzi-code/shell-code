[TOC]

## 一、location用法总结

location可以把不同方式的请求，定位到不同的处理方式上.

#### 1.location的用法

```vim {class=line-numbers}
location ~* /js/.*/\.js
以 = 开头，表示精确匹配；如只匹配根目录结尾的请求，后面不能带任何字符串。
以^~ 开头，表示uri以某个常规字符串开头，不是正则匹配
以~ 开头，表示区分大小写的正则匹配;
以~* 开头，表示不区分大小写的正则匹配
以/ 开头，通用匹配, 如果没有其它匹配,任何请求都会匹配到
```

**&nbsp;location&nbsp;的匹配顺序是&ldquo;先匹配正则，再匹配普通&rdquo;。**

矫正：&nbsp;location&nbsp;的匹配顺序其实是&ldquo;先匹配普通，再匹配正则&rdquo;。我这么说，大家一定会反驳我，因为按&ldquo;先匹配普通，再匹配正则&rdquo;解释不了大家平时习惯的按&ldquo;先匹配正则，再匹配普通&rdquo;的实践经验。这里我只能暂时解释下，造成这种误解的原因是：正则匹配会覆盖普通匹配。



#### 2.location用法举例

<div>location正则写法：</div>
<div>

1.  精确匹配 / ，主机名后面不能带任何字符串</div>
``` {class=line-numbers}
location = / {
[ configuration A ]
}
```
![](https://images2017.cnblogs.com/blog/1209537/201802/1209537-20180207154718107-303132193.png)</div>

&nbsp; &nbsp; &nbsp; 
2.  所有的地址都以 / 开头，所以这条规则将最后匹配到默认请求

<pre><span style="font-size: 14px;"># 但是正则和最长字符串会优先匹配</span></pre>

```{class=line-numbers}
location / {
[ configuration B ]
}
```
例：
```
  location / { 
          proxy_pass http://server_pools;
        } 
#这条规则只有其他不符合要求才能匹配到；将是最后匹配到的，匹配度最低，上面实现的功能是：比如网站是www.blog.com；后面什么都不输入的时候，
其他的规则也不匹配的时候，最后交给负载均衡池的服务器
``` 

3.  匹配任何以 /documents/ 开头的地址，匹配符合以后，还要继续往下搜索
_# 只有后面的正则表达式没有匹配到时，这一条才会采用这一条_

```{class=line-numbers}
location /documents/ {
[ configuration C ]
}
```
例：
```{class=line-numbers}
location  /static/
       {
        rewrite ^  http://www.abc.com ;      
       }
#上面实现的功能：假设网站域名为www.blog.com；那么配置上面的功能是输入www.blog.com/static/时，不管static后面是什么页面（页面也可以不存在），
那么最终会同样跳转到www.abc.com这个网站。
```

4. 匹配任何以 /documents/ 开头的地址，匹配符合以后，还要继续往下搜索
_# 只有后面的正则表达式没有匹配到时，这一条才会采用这一条_

```{class=line-numbers}
location ~ /documents/Abc {
[ configuration CC ]
}
``` 

5. 匹配任何以 /images/ 开头的地址，匹配符合以后，停止往下搜索正则，采用这一条。

```
location ^~ /images/ {
[ configuration D ]
}

```

6. 匹配所有以 gif,jpg或jpeg 结尾的请求
_# 然而，所有请求 /images/ 下的图片会被 config D 处理，因为 ^~ 到达不了这一条正则_
```{class=line-numbers}
location ~* \.(gif|jpg|jpeg)$ {
[ configuration E ]
}
```
例：

![](https://images2017.cnblogs.com/blog/1209537/201802/1209537-20180207164332341-2033946883.png)

7. 字符匹配到 /images/，继续往下，会发现 ^~ 存在
```{class=line-numbers}
location /images/ {
[ configuration F ]
}
```
8.# 最长字符匹配到 /images/abc，继续往下，会发现 ^~ 存在
&nbsp; _# F与G的放置顺序是没有关系的_
```{class=line-numbers}
location /images/abc {
[ configuration G ]
}
``` 
9. 只有去掉 config D 才有效：先最长匹配 config G 开头的地址，继续往下搜索，匹配到这一条正则，采用
```{class=line-numbers}
location ~ /images/abc/ {
[ configuration H ]
}
```

<div>顺序 no优先级：</div>
<div>(location =) &gt; (location 完整路径) &gt; (location ^~ 路径) &gt; (location ~,~* 正则顺序) &gt; (location 部分起始路径) &gt; (/)</div>
</div>
<div>
<div>上面的匹配结果：</div>

```{class=line-numbers}
按照上面的location写法，以下的匹配示例成立：
/ -> config A
精确完全匹配，即使/index.html也匹配不了
/downloads/download.html -> config B
匹配B以后，往下没有任何匹配，采用B
/images/1.gif -> configuration D
匹配到F，往下匹配到D，停止往下
/images/abc/def -> config D
最长匹配到G，往下匹配D，停止往下
你可以看到 任何以/images/开头的都会匹配到D并停止，FG写在这里是没有任何意义的，H是永远轮不到的，这里只是为了说明匹配顺序
/documents/document.html -> config C
匹配到C，往下没有任何匹配，采用C
/documents/1.jpg -> configuration E
匹配到C，往下正则匹配到E
/documents/Abc.jpg -> config CC
最长匹配到C，往下正则顺序匹配到CC，不会往下到E
```
#### 3、实际使用建议

<div>
<div>所以实际使用中，个人觉得至少有三个匹配规则定义，如下：</div>

```{class=line-numbers}
#直接匹配网站根，通过域名访问网站首页比较频繁，使用这个会加速处理，官网如是说。
#这里是直接转发给后端应用服务器了，也可以是一个静态首页
# 第一个必选规则location = / {
proxy_pass  http://tomcat:8080/index
}
# 第二个必选规则是处理静态文件请求，这是nginx作为http服务器的强项
# 有两种配置模式，目录匹配或后缀匹配,任选其一或搭配使用
location ^~ /static/ {
root /webroot/static/;
}
location ~* \.(gif|jpg|jpeg|png|css|js|ico)$ {
root /webroot/res/;
}
#第三个规则就是通用规则，用来转发动态请求到后端应用服务器
#非静态文件请求就默认是动态请求，自己根据实际把握#毕竟目前的一些框架的流行，带.php,.jsp后缀的情况很少了
location / {
proxy_pass  http://tomcat:8080/
}
http://tengine.taobao.org/book/chapter_02.html
http://nginx.org/en/docs/http/ngx_http_rewrite_module.html
```

## 二、Rewrite用法总结

### &nbsp; &nbsp; &nbsp;1.rewrite的定义

<div>&nbsp; &nbsp; &nbsp;rewrite功能就是使用nginx提供的全局变量或自己设置的变量，结合正则表达式和标志位实现url重写以及重定向。</div>

```{class=line-numbers}
rewrite只能放在 server{}, location{}, if{}中，并且只能对域名后边的除去传递的参数外的字符串起作用。
例如 http://seanlook.com/a/we/index.php?id=1&u=str 只对/a/we/index.php重写。

```

### &nbsp; &nbsp;2.rewirte的&nbsp;**语法**

 &nbsp;&nbsp;&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; rewrite regex replacement [flag];
<div>&nbsp;</div>
<div>&nbsp; &nbsp; &nbsp; &nbsp; 如果相对域名或参数字符串起作用，可以使用全局变量匹配，也可以使用proxy_pass反向代理。</div>
<div>&nbsp; &nbsp; &nbsp; &nbsp;从上 表明看rewrite和location功能有点像，都能实现跳转。主要区别在于rewrite是在**同一域名内**更改获取资源的路径，而location是对一类路径做控制访问或反向代理，**可以proxy_pass到其他机器**。</div>
<div>&nbsp;</div>
<div>很多情况下rewrite也会写在location里，它们的执行顺序是：</div>


```{class=line-numbers}
1 执行server块的rewrite指令
2 执行location匹配
3 执行选定的location中的rewrite指令

```

<div>如果其中某步URI被重写，则重新循环执行1-3，直到找到真实存在的文件；循环超过10次，则返回500 Internal Server Error错误。</div>

#### flag标志位

*   last&nbsp;: 相当于Apache的[L]标记，表示完成rewrite
*   break&nbsp;: 停止执行当前虚拟主机的后续rewrite指令集
*   redirect&nbsp;: 返回302临时重定向，地址栏会显示跳转后的地址
*   permanent&nbsp;: 返回301永久重定向，地址栏会显示跳转后的地址
<div>因为301和302不能简单的只返回状态码，还必须有重定向的URL，这就是return指令无法返回301,302的原因了。</div>
<div>这里 last 和 break 区别有点难以理解：</div>

1.  last一般写在server和if中，而break一般使用在location中
2.  last不终止重写后的url匹配，即新的url会再从server走一遍匹配流程，而break终止重写后的匹配
3.  break和last都能组织继续执行后面的rewrite指令

### 3.rewrite常用正则

*   .&nbsp;： 匹配除换行符以外的任意字符
*   ?&nbsp;： 重复0次或1次
*   +&nbsp;： 重复1次或更多次
*   *&nbsp;： 重复0次或更多次
*   \d&nbsp;：匹配数字
*   ^&nbsp;： 匹配字符串的开始
*   $&nbsp;： 匹配字符串的结束
*   {n}&nbsp;： 重复n次
*   {n,}&nbsp;： 重复n次或更多次
*   [c]&nbsp;： 匹配单个字符c
*   [a-z]&nbsp;： 匹配a-z小写字母的任意一个
<div>小括号()之间匹配的内容，可以在后面通过$1来引用，$2表示的是前面第二个()里的内容。正则里面容易让人困惑的是\转义特殊字符。</div>


#### rewrite实例

```python {class=line-numbers}
例1：
http {
# 定义image日志格式
log_format imagelog '[$time_local] ' $image_file ' ' $image_type ' ' $body_bytes_sent ' ' $status;
# 开启重写日志
rewrite_log on;
 
server {
root /home/www;
 
location / {
# 重写规则信息
error_log logs/rewrite.log notice;
# 注意这里要用‘’单引号引起来，避免{}
rewrite '^/images/([a-z]{2})/([a-z0-9]{5})/(.*)\.(png|jpg|gif)$' /data?file=$3.$4;
# 注意不能在上面这条规则后面加上“last”参数，否则下面的set指令不会执行
set $image_file $3;
set $image_type $4;
}
 
location /data {
# 指定针对图片的日志格式，来分析图片类型和大小
access_log logs/images.log mian;
root /data/images;
# 应用前面定义的变量。判断首先文件在不在，不在再判断目录在不在，如果还不在就跳转到最后一个url里
try_files /$arg_file /image404.html;
}
location = /image404.html {
# 图片不存在返回特定的信息
return 404 "image not found\n";
}
}
 
对形如/images/ef/uh7b3/test.png的请求，重写到/data?file=test.png，于是匹配到location /data，先看/data/images/test.png文件存不存在，如果存在则正常响应，如果不存在则重写tryfiles到新的image404 location，直接返回404状态码。

例2：
rewrite ^/images/(.*)_(\d+)x(\d+)\.(png|jpg|gif)$ /resizer/$1.$4?width=$2&height=$3? last;
对形如/images/bla_500x400.jpg的文件请求，重写到/resizer/bla.jpg?width=500&height=400地址，并会继续尝试匹配location。

``` 

#### if指令与全局变量

<div>

##### if判断指令**语法**

<div>&nbsp; &nbsp; &nbsp;if (condition)</div>
<div>&nbsp; &nbsp; &nbsp; {...}</div>
<div>对给定的条件condition进行判断。如果为真，大括号内的rewrite指令将被执行，if条件(conditon)可以是如下任何内容：</div>

``` {class=line-numbers}
当表达式只是一个变量时，如果值为空或任何以0开头的字符串都会当做false
直接比较变量和内容时，使用=或!=
~  正则表达式匹配
~* 不区分大小写的匹配
!~  区分大小写的不匹配
-f和!-f  用来判断是否存在文件
-d和!-d  用来判断是否存在目录
-e和!-e  用来判断是否存在文件或目录
-x和!-x  用来判断文件是否可执行
```

<div>例如：</div>


```python {class=line-numbers}
如果用户设备为IE浏览器的时候，重定向
if ($http_user_agent ~ MSIE) {
rewrite ^(.*)$ /msie/$1 break;
} //如果UA包含"MSIE"，rewrite请求到/msid/目录下
 
if ($http_cookie ~* "id=([^;]+)(?:;|$)") {
set $id $1;
} //如果cookie匹配正则，设置变量$id等于正则引用部分
 
if ($request_method = POST) {
return 405;
} //如果提交方法为POST，则返回状态405（Method not allowed）。return不能返回301,302
 
if ($slow) {
limit_rate 10k;
} //限速，$slow可以通过 set 指令设置
 
if (!-f $request_filename){
break;
proxy_pass http://127.0.0.1;
} //如果请求的文件名不存在，则反向代理到localhost 。这里的break也是停止rewrite检查
 
if ($args ~ post=140){
rewrite ^ http://example.com/ permanent;
} //如果query string中包含"post=140"，永久重定向到example.com
 
location ~* \.(gif|jpg|png|swf|flv)$ {
valid_referers none blocked www.jefflei.comwww.leizhenfang.com;
if ($invalid_referer) {
return 404;
} //防盗链
}

```

##### 全局变量

<div>下面是可以用作if判断的全局变量</div>
</div>

*   $args&nbsp;： #这个变量等于请求行中的参数，同$query_string
*   $content_length&nbsp;： 请求头中的Content-length字段。
*   $content_type&nbsp;： 请求头中的Content-Type字段。
*   $document_root&nbsp;： 当前请求在root指令中指定的值。
*   $host&nbsp;： 请求主机头字段，否则为服务器名称。
*   $http_user_agent&nbsp;： 客户端agent信息
*   $http_cookie&nbsp;： 客户端cookie信息
*   $limit_rate&nbsp;： 这个变量可以限制连接速率。
*   $request_method&nbsp;： 客户端请求的动作，通常为GET或POST。
*   $remote_addr&nbsp;： 客户端的IP地址。
*   $remote_port&nbsp;： 客户端的端口。
*   $remote_user&nbsp;： 已经经过Auth Basic Module验证的用户名。
*   $request_filename&nbsp;： 当前请求的文件路径，由root或alias指令与URI请求生成。
*   $scheme&nbsp;： HTTP方法（如http，https）。
*   $server_protocol&nbsp;： 请求使用的协议，通常是HTTP/1.0或HTTP/1.1。
*   $server_addr&nbsp;： 服务器地址，在完成一次系统调用后可以确定这个值。
*   $server_name&nbsp;： 服务器名称。
*   $server_port&nbsp;： 请求到达服务器的端口号。
*   $request_uri&nbsp;： 包含请求参数的原始URI，不包含主机名，如：&rdquo;/foo/bar.php?arg=baz&rdquo;。
*   $uri&nbsp;： 不带请求参数的当前URI，$uri不包含主机名，如&rdquo;/foo/bar.html&rdquo;。
*   $document_uri&nbsp;： 与$uri相同。

例：

``` {class=line-numbers}
http://localhost:88/test1/test2/test.php
$host：localhost
$server_port：88
$request_uri：http://localhost:88/test1/test2/test.php
$document_uri：/test1/test2/test.php
$document_root：/var/www/html
$request_filename：/var/www/html/test1/test2/test.php

```