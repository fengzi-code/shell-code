[TOC]
# 1.JVM优化

修改 weblogic\user_projects\domains\XX_domain\bin 下的
setDomainEnv.cmd 文件


```vim {class=line-numbers}
if [ "${JAVA_VENDOR}" = "Sun" ] ; then
        WLS_MEM_ARGS_64BIT="-Xms256m -Xmx512m"
        export WLS_MEM_ARGS_64BIT
        WLS_MEM_ARGS_32BIT="-Xms256m -Xmx512m"
        export WLS_MEM_ARGS_32BIT
else
        WLS_MEM_ARGS_64BIT="-Xms512m -Xmx512m"
        export WLS_MEM_ARGS_64BIT
        WLS_MEM_ARGS_32BIT="-Xms512m -Xmx512m"
        export WLS_MEM_ARGS_32BIT
fi
```

```vim {class=line-numbers}

-Xms 初始分配的内存
-Xmx 最大分配的内存
默认空余堆内存小于40%时，JVM就会增大堆直到-Xmx的最大限制；空余堆内存大于70%时， JVM会减少堆直到-Xms的最小限制
因此服务器一般设置-Xms、-Xmx相等以避免在每次GC 后调整堆的大小。
根据服务器内存调整,最好不要超过你物理内存的一半

```




2. 尽量开启本地 I/O
![enter image description here](http://www.cainiaogongju.com/images/img_cj/weblogic001.png)

3. 调整为生产模式.在域（如：mydomain）> 配置 > 常规选择生产模式.重启 weblogic 即可生效


4. 设置 Weblogic 数据库连接池连接数
```vim {class=line-numbers}
点击数据源，进入后选择连接池,设置初始容量：20最大容量：50容量 增长：5 
注意：为了减少新建连接的开销,将最小值和最大值设为一致   
```
5. 调优执行队列线程
```vim {class=line-numbers}
在这里，执行队列的线程数表示执行队列能够同时执行的操作的数量。但此值不是设的越大越好，应该恰到好处的去设置它，太小了，执行队列中将会积累很多待处理的任务，太大了，则会消耗大量的系统资源从而影响整体的性能。在产品模式下默认为25个执行线程。
（一般来说，其上限是每个CPU对应50个线程，其按照CPU个数线性增长.）
在域（如：mydomain）> 服务器 > server实例（如：myserver）> Execute Queue > weblogic.kernel.Defalt > 配置中修改线程计数
```

6. 调优TCP连接缓存数
```
默认值为50。当系统重载负荷时,这个值可能过小,日志中报Connection Refused,导致有效连接请求遭到拒绝,此时可以提高Accept Backlog 25%直到连接拒绝错误消失。
Login Timeout和SSL Login Timeout参数表示普通连接和SSL连接的超时时间,如果客户连接被服务器中断或者SSL容量大,可以尝试增加该值。
通过启动管理控制台，在域（如：mydomain）> 服务器 > server实例（如：myserver）>配置 > 调整下可配置“接受预备连接”。

```

7. 线程池

修改域下面conf里面的config.xml文件,修改为400： 

```vim {class=line-numbers}

<server> 
<name>AdminServer</name> 
<self-tuning-thread-pool-size-min>400</self-tuning-thread-pool-size-min> 
<self-tuning-thread-pool-size-max>400</self-tuning-thread-pool-size-max> 
<listen-address/> 
</server> 

```

8. 服务器-->选中服务--> 配置-->优化 --> 高级--> muxer类：weblogic.socket.NTSocketMuxer 改成：weblogic.socket.DevPollSocketMuxer
  weblogic版本是12c,服务器常常100%（多个cpu均是100%）。分析过当前的进程的状态，都是在GC。现象是CPU使用率上去以后就下不来了
