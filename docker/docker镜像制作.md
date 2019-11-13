[toc]

# 1. 基础镜像准备
1.1 最小化安装 centos7x64 操作系统
1.2 卸载不必要的文件
> yum remove -y iwl* *firmware* --exclude=kernel-firmware
1.3 安装一些常用软件
```
yum install wget lrzsz net-tools lsof tcpdump iotop
```
1.4 清除yum缓存
```
yum clean all
yum clean allrm -rf /var/cache/yum
```
1.5 打包文件系统

```
tar --numeric-owner --exclude=/proc --exclude=/sys --exclude=/mnt --exclude=/var/cache --exclude=/usr/share/{foomatic,backgrounds,perl5,fonts,cups,qt4,groff,kde4,icons,pixmaps,emacs,gnome-background-properties,sounds,gnome,games,desktop-directories} --exclude=/var/log -zcvf /mnt/CentOS-7-BaseImage.tar.gz /
```
# 2. 基础镜像制作
2.1 上传系统压缩包到宿主机
2.2 安装docker环境
2.3 导入镜像包
> cat /mnt/CentOS-7-BaseImage.tar.gz | docker import - centos-tar:7.4.1708

2.4 验证
> docker images

# 3. 镜像更新

3.1 Dockerfile 常用命令

```dockerfile
FROM centos 
# 指定构建使用的基础镜像
MAINTAINER 
# 创建者信息
WORKDIR /root 
# 启动后的目录
ENV REFRESHED_AT='2018-08-09' java_home='/opt/jdk1.8' 
# 设置环境变量,=号时可以设置多个变量,可用转义符进行换行,定义的变量可被此行以后的命令引用
ADD [source][destination] 
# 和copy一样,但会自动处理压缩包,当tar文件为url时不会自动解压
copy [path][destination] 
# 单纯的复制文件进容器,src必须为dockerfile上下文的路径.src为目录时会复制目录下的所有递归文件,但不会复制目录本身,当src有多个路径或有通配符时,dest必须以/结尾的目录,dest不存在会自动创建
VOLUME [ "/data", "/opt/data" ]:  
# 将宿主机目录/opt/data挂载到容器/data目录
EXPOSE 3000 
# 容器暴露的端口,在启动容器时需要通过-P，宿主机会分配一个随机端口转发到容器的3000端口.此命令可以暴露多个端口
RUN yum install -y lrzsz  
# RUN命令执行命令并创建新的镜像层，通常用于安装软件包,时间点为docker biud构建镜像时,run可以有多个

# CMD命令可被docker run 命令行的参数所覆盖,如ls /root
CMD ["/bin/httpd","-f","-h $DOC_ROOT"] 
# 使用 exec 执行，启动完后为pid 1 的子进程；不能使用sh的通配符或管道或shell变量等,所以这里的$DOC_ROOT启动时会报错.但可以使用 CMD ["/bin/sh","-c","/bin/httpd -f -h $DOC_ROOT"] 即可解决,现在启动的来shell的子进程
CMD /bin/httpd -f -h $DOC_ROOT 
# 在 /bin/sh 中执行，提供给需要交互的应用；
ENTRYPOINT /bin/httpd -f -h $DOC_ROOT  
# 配置容器启动时的执行命令,不会被docker run命令后面的命令行参数替换

CMD ["/bin/httpd","-f","-h $DOC_ROOT"] 
ENTRYPOINT ["/bin/sh","-c"] 
# CMD 和 ENTRYPOINT组合使用时 cmd中的内容将作为参数传递给ENTRYPOINT使用,结合起来就是 /bin/sh -c "/bin/httpd -f -h $DOC_ROOT"

HEALTHCHECK --start-period=3s CMD wget -o - -q http://${IP:-0.0.0.0}:${PROT:-80}
# 健康检查


FROM nginx:${nginx_tga}
ARG nginx_tga="1.14-alpine"
docker build --build-arg nginx_tag="1.13-alpine" -t myweb:v1.18 ./
# build 时改变dockerfile里的参数值


ONBUILD ADD . /app/src
# 如果别的dockerfile文件是基于你这个作为基础镜像时被执行,自身dockerfile时不会被执行


```

3.2 Dockerfile centos示例

```dockerfile
## Set the base image to docker.io/centos  基于docker.io/centos镜像
FROM docker.io/centos:latest
# File Author / Maintainer  作者信息
MAINTAINER lijingfeng
# Install necessary tools  安装一些依赖的包,中文支持
RUN yum install -y lrzsz which kde-l10n-Chinese glibc-common net-tools
RUN localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# 设置环境变量
ENV LC_ALL zh_CN.UTF-8
ENV LANG zh_CN.UTF-8
# Expose ports  开放80端口出来
# EXPOSE 80
# Set the default command to execute when creating a new container  这里是因为防止服务启动后容器会停止的情况，所以需要多执行一句tail命令
ENTRYPOINT /usr/sbin/init
# ENTRYPOINT /usr/local/nginx/sbin/nginx && tail -f /etc/passwd
# 启动后的目录
WORKDIR /root
```

3.3 Dockerfile alpine示例

```dockerfile
## Set the base image to docker.io/centos  基于docker.io/centos镜像
FROM alpine:latest
# File Author / Maintainer  作者信息
MAINTAINER lijingfeng
# Install necessary tools  安装一些依赖的包,中文支持
RUN yum install -y kde-l10n-Chinese glibc-common net-tools
RUN localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# 设置环境变量
ENV LC_ALL zh_CN.UTF-8
ENV LANG zh_CN.UTF-8
# Expose ports  开放80端口出来
# EXPOSE 80
# Set the default command to execute when creating a new container  这里是因为防止服务启动后容器会停止的情况，所以需要多执行一句tail命令
ENTRYPOINT /usr/sbin/init
# ENTRYPOINT /usr/local/nginx/sbin/nginx && tail -f /etc/passwd
# 启动后的目录
WORKDIR /root
```


3.4 提交镜像

> docker build -t centos7:v2 .   # -t 指定tag 镜像名:版本  dockerfile路径
