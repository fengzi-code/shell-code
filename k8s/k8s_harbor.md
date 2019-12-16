[toc]

#### 1. 方案1 (不推荐)
>https://hub.docker.com/  搜索 registry   
> docker pull registry

```bash
yum install docker-distribution  #yum安装
rpm -ql docker-distribution  # 查看安装了哪些文件.找出配置文件

# /etc/docker-distribution/registry/config.yml 配置文件路径
# /usr/bin/registry 执行程序路径
# /var/lib/registry 数据目录

```

配置文件

```yaml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory     #缓存到内存中
    filesystem:
        rootdirectory: /var/lib/registry    #数据目录
http:
    addr: :5000     #端口,没写IP表明监听所有IP
```

服务启动

```
systemctl start docker-distribution

```

#### 2. 方案2(harbor)
1. harbor需要借助docker compose 单机编排工具

```
yum  install yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum  install docker-ce
systemctl start docker

curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version



wget -c https://storage.googleapis.com/harbor-releases/release-1.8.0/harbor-offline-installer-v1.8.1.tgz
tar xf harbor-offline-installer-v1.8.1.tgz -C /usr/local/
cd /usr/local/harbor
vim harbor.yaml
./install.sh
```
#### 3. 方案3_k8s_pod方式