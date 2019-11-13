

MySQL数据库自身提供的主从复制功能可以方便的实现数据的多处自动备份，实现数据库的拓展。多个数据备份不仅可以加强数据的安全性，通过实现读写分离还能进一步提升数据库的负载性能。

下图就描述了一个多个数据库间主从复制与读写分离的模型(来源网络)：

![](https://images2015.cnblogs.com/blog/1043616/201612/1043616-20161213151157558-1150305350.jpg)

在一主多从的数据库体系中，多个从服务器采用异步的方式更新主数据库的变化，业务服务器在执行写或者相关修改数据库的操作是在主服务器上进行的，读操作则是在各从服务器上进行。如果配置了多个从服务器或者多个主服务器又涉及到相应的负载均衡问题，关于负载均衡具体的技术细节还没有研究过，今天就先简单的实现一主一从的主从复制功能。

Mysql主从复制的实现原理图大致如下(来源网络)：

![](https://images2015.cnblogs.com/blog/1043616/201612/1043616-20161213151808011-1732852037.jpg)

MySQL之间数据复制的基础是二进制日志文件（binary log file）。一台MySQL数据库一旦启用二进制日志后，其作为master，它的数据库中所有操作都会以&ldquo;事件&rdquo;的方式记录在二进制日志中，其他数据库作为slave通过一个I/O线程与主服务器保持通信，并监控master的二进制日志文件的变化，如果发现master二进制日志文件发生变化，则会把变化复制到自己的中继日志中，然后slave的一个SQL线程会把相关的&ldquo;事件&rdquo;执行到自己的数据库中，以此实现从数据库和主数据库的一致性，也就实现了主从复制。

<span style="font-size: 14pt;">**实现MySQL主从复制需要进行的配置：**</span>

*   主服务器：

    *   开启二进制日志
    *   配置唯一的server-id
    *   获得master二进制日志文件名及位置
    *   创建一个用于slave和master通信的用户账号

*   从服务器：

    *   配置唯一的server-id

具体实现过程如下：

<span style="font-size: 14pt; color: #ff0000;">一、准备工作：</span>

1.主从数据库版本最好一致

2.主从数据库内数据保持一致

主数据库：182.92.172.80 /linux

从数据库：123.57.44.85 /linux

<span style="font-size: 14pt; color: #ff0000;">二、主数据库master修改：</span>

**1.修改mysql配置**

找到主数据库的配置文件my.cnf(或者my.ini)，我的在/etc/mysql/my.cnf,在[mysqld]部分插入如下两行：

<div class="cnblogs_code">
<pre><span style="color: #ff0000;">[</span><span style="color: #ff0000;">mysqld</span><span style="color: #ff0000;">]</span>
<span style="color: #ff00ff;">log</span><span style="color: #808080;">-</span>bin<span style="color: #808080;">=</span>mysql<span style="color: #808080;">-</span><span style="color: #000000;">bin #开启二进制日志
server</span><span style="color: #808080;">-</span>id<span style="color: #808080;">=</span><span style="color: #800000; font-weight: bold;">1</span> #设置server<span style="color: #808080;">-</span>id</pre>
</div>

**2.重启mysql，创建用于同步的用户账号**

打开mysql会话shell&gt;mysql -hlocalhost -uname -ppassword

创建用户并授权：用户：rel1密码：slavepass

<div class="cnblogs_code">
<pre>mysql<span style="color: #808080;">&gt;</span> <span style="color: #0000ff;">CREATE</span> <span style="color: #ff00ff;">USER</span> <span style="color: #ff0000;">'</span><span style="color: #ff0000;">repl</span><span style="color: #ff0000;">'</span>@<span style="color: #ff0000;">'</span><span style="color: #ff0000;">123.57.44.85</span><span style="color: #ff0000;">'</span> IDENTIFIED <span style="color: #0000ff;">BY</span> <span style="color: #ff0000;">'</span><span style="color: #ff0000;">slavepass</span><span style="color: #ff0000;">'</span><span style="color: #000000;">;#创建用户
mysql</span><span style="color: #808080;">&gt;</span> <span style="color: #0000ff;">GRANT</span> <span style="color: #0000ff;">REPLICATION</span> SLAVE <span style="color: #0000ff;">ON</span> <span style="color: #808080;">*</span>.<span style="color: #808080;">*</span> <span style="color: #0000ff;">TO</span> <span style="color: #ff0000;">'</span><span style="color: #ff0000;">repl</span><span style="color: #ff0000;">'</span>@<span style="color: #ff0000;">'</span><span style="color: #ff0000;">123.57.44.85</span><span style="color: #ff0000;">'</span><span style="color: #000000;">;#分配权限
mysql</span><span style="color: #808080;">&gt;</span>flush <span style="color: #0000ff;">privileges</span>;   #刷新权限</pre>
</div>

**3.查看master状态，记录二进制文件名(mysql-bin.000003)和位置(73)：**

<div class="cnblogs_code">
<pre>mysql <span style="color: #808080;">&gt;</span><span style="color: #000000;"> SHOW MASTER STATUS;
</span><span style="color: #808080;">+</span><span style="color: #008080;">--</span><span style="color: #008080;">----------------+----------+--------------+------------------+</span>
<span style="color: #808080;">|</span> <span style="color: #0000ff;">File</span>             <span style="color: #808080;">|</span> Position <span style="color: #808080;">|</span> Binlog_Do_DB <span style="color: #808080;">|</span> Binlog_Ignore_DB <span style="color: #808080;">|</span>
<span style="color: #808080;">+</span><span style="color: #008080;">--</span><span style="color: #008080;">----------------+----------+--------------+------------------+</span>
<span style="color: #808080;">|</span> mysql<span style="color: #808080;">-</span>bin.<span style="color: #800000; font-weight: bold;">000003</span> <span style="color: #808080;">|</span> <span style="color: #800000; font-weight: bold;">73</span>       <span style="color: #808080;">|</span> test         <span style="color: #808080;">|</span> manual,mysql     <span style="color: #808080;">|</span>
<span style="color: #808080;">+</span><span style="color: #008080;">--</span><span style="color: #008080;">----------------+----------+--------------+------------------+</span></pre>
</div>

<span style="font-size: 14pt; color: #ff0000;">二、从服务器slave修改：</span>

**1.修改mysql配置**

同样找到my.cnf配置文件，添加server-id

<div class="cnblogs_code">
<pre><span style="color: #ff0000;">[</span><span style="color: #ff0000;">mysqld</span><span style="color: #ff0000;">]</span><span style="color: #000000;">
server</span><span style="color: #808080;">-</span>id<span style="color: #808080;">=</span><span style="color: #800000; font-weight: bold;">2</span> #设置server<span style="color: #808080;">-</span>id，必须唯一</pre>
</div>

**2.重启mysql，打开mysql会话，执行同步SQL语句**(需要主服务器主机名，登陆凭据，二进制文件的名称和位置)：

<div class="cnblogs_code">
<pre>mysql<span style="color: #808080;">&gt;</span> CHANGE MASTER <span style="color: #0000ff;">TO</span>
    <span style="color: #808080;">-&gt;</span>     MASTER_HOST<span style="color: #808080;">=</span><span style="color: #ff0000;">'</span><span style="color: #ff0000;">182.92.172.80</span><span style="color: #ff0000;">'</span><span style="color: #000000;">,
    </span><span style="color: #808080;">-&gt;</span>     MASTER_USER<span style="color: #808080;">=</span><span style="color: #ff0000;">'</span><span style="color: #ff0000;">rep1</span><span style="color: #ff0000;">'</span><span style="color: #000000;">,
    </span><span style="color: #808080;">-&gt;</span>     MASTER_PASSWORD<span style="color: #808080;">=</span><span style="color: #ff0000;">'</span><span style="color: #ff0000;">slavepass</span><span style="color: #ff0000;">'</span><span style="color: #000000;">,
    </span><span style="color: #808080;">-&gt;</span>     MASTER_LOG_FILE<span style="color: #808080;">=</span><span style="color: #ff0000;">'</span><span style="color: #ff0000;">mysql-bin.000003</span><span style="color: #ff0000;">'</span><span style="color: #000000;">,
    </span><span style="color: #808080;">-&gt;</span>     MASTER_LOG_POS<span style="color: #808080;">=</span><span style="color: #800000; font-weight: bold;">73</span>;</pre>
</div>

**3.启动slave同步进程：**

<div class="cnblogs_code">
<pre>mysql<span style="color: #808080;">&gt;</span>start slave;</pre>
</div>

4.查看slave状态：

<div class="cnblogs_code">
<pre>mysql<span style="color: #808080;">&gt;</span><span style="color: #000000;"> show slave status\G;
</span><span style="color: #808080;">***************************</span> <span style="color: #800000; font-weight: bold;">1</span>. row <span style="color: #808080;">***************************</span><span style="color: #000000;">
               Slave_IO_State: Waiting </span><span style="color: #0000ff;">for</span> master <span style="color: #0000ff;">to</span><span style="color: #000000;"> send event
                  Master_Host: </span><span style="color: #800000; font-weight: bold;">182.92</span>.<span style="color: #800000; font-weight: bold;">172.80</span><span style="color: #000000;">
                  Master_User: rep1
                  Master_Port: </span><span style="color: #800000; font-weight: bold;">3306</span><span style="color: #000000;">
                Connect_Retry: </span><span style="color: #800000; font-weight: bold;">60</span><span style="color: #000000;">
              Master_Log_File: mysql</span><span style="color: #808080;">-</span>bin.<span style="color: #800000; font-weight: bold;">000013</span><span style="color: #000000;">
          Read_Master_Log_Pos: </span><span style="color: #800000; font-weight: bold;">11662</span><span style="color: #000000;">
               Relay_Log_File: mysqld</span><span style="color: #808080;">-</span>relay<span style="color: #808080;">-</span>bin.<span style="color: #800000; font-weight: bold;">000022</span><span style="color: #000000;">
                Relay_Log_Pos: </span><span style="color: #800000; font-weight: bold;">11765</span><span style="color: #000000;">
        Relay_Master_Log_File: mysql</span><span style="color: #808080;">-</span>bin.<span style="color: #800000; font-weight: bold;">000013</span><span style="color: #000000;"><span style="color: #ff0000;">
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes</span>
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
        ...</span></pre>
</div>

当Slave_IO_Running和Slave_SQL_Running都为YES的时候就表示主从同步设置成功了。接下来就可以进行一些验证了，比如在主master数据库的test数据库的一张表中插入一条数据，在slave的test库的相同数据表中查看是否有新增的数据即可验证主从复制功能是否有效，还可以关闭slave（mysql&gt;stop slave;）,然后再修改master，看slave是否也相应修改（停止slave后，master的修改不会同步到slave），就可以完成主从复制功能的验证了。

还可以用到的其他相关参数：

master开启二进制日志后默认记录所有库所有表的操作，可以通过配置来指定只记录指定的数据库甚至指定的表的操作，具体在mysql配置文件的[mysqld]可添加修改如下选项：

<div class="cnblogs_code">
<pre><span style="color: #000000;"># 不同步哪些数据库  
binlog</span><span style="color: #808080;">-</span>ignore<span style="color: #808080;">-</span>db <span style="color: #808080;">=</span><span style="color: #000000;"> mysql  
binlog</span><span style="color: #808080;">-</span>ignore<span style="color: #808080;">-</span>db <span style="color: #808080;">=</span><span style="color: #000000;"> test  
binlog</span><span style="color: #808080;">-</span>ignore<span style="color: #808080;">-</span>db <span style="color: #808080;">=</span><span style="color: #000000;"> information_schema  

# 只同步哪些数据库，除此之外，其他不同步  
binlog</span><span style="color: #808080;">-</span>do<span style="color: #808080;">-</span>db <span style="color: #808080;">=</span> game  </pre>
</div>

如之前查看master状态时就可以看到只记录了test库，忽略了manual和mysql库。
