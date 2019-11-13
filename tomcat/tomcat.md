2、安装vim和lrzsz：yum install -y vim lrzsz。

3、找到tomcat8的官方下载地址：http://tomcat.apache.org/download-80.cgi。


4、使用rz上传解压到/usr/local中，可以改名为tomcat8。



5、进入tomcat8/bin目录，使用vim编辑Catalina.sh文件，设置JVM参数。

![](https://img-blog.csdn.net/20171227094214272?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYTUxNTU1NzU5NV94emI=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

![](https://img-blog.csdn.net/20180828150100229?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2E1MTU1NTc1OTVfeHpi/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

-server ： 适合服务器端运行

-Xms ： 设置初始内存值【最小内存值】

-Xmx ：设置最大内存值

-XX:NewSize ： 设置新生代大小

-XX:PermSize ：设置永久代大小

-XX:MaxTenuringThreshold ：设置垃圾的最大年龄。

      若值为0则Young对象满后不会进入Survivor区而直接进入Tenured代，适合老年代较多的应用。若值较大则Young对象满后会在Survivor多次复制，对象存活时间更长，增加对象回收几率。

-XX:NewRatio ：即Tenured和Young的比值，此时Young = Eden + 2 * Survivor 占Total的1/3【Perm不属于Total】。

XX:+DisableExplicitGC ：忽略系统GC且不会触发任何GC，即system.gc()成为空的调用。

6、执行./startup.sh，出现tomcat启动标志。

![](https://img-blog.csdn.net/20171227101632824?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYTUxNTU1NzU5NV94emI=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

7、在浏览器中输入<span style="color:#ff0000;">IP:8080</span>查看是否启动成功，也可以进入logs查看Catalina日志。

![](https://img-blog.csdn.net/20171227101931666?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYTUxNTU1NzU5NV94emI=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

8、若首次开启时防火墙没有设置，则会出现访问不了的情况，此时<span style="color:#ff0000;">vim /etc/sysconfig/iptables，开启8080端口，然后重启防火墙：service iptables restart</span>。

![](https://img-blog.csdn.net/20171227102114011?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYTUxNTU1NzU5NV94emI=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

9、再次访问<span style="color:#ff0000;">IP:8080</span>，出现tomcat首页即开启成功。


</div>