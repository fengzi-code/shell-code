[toc]

## 一、环境准备

以下文章本着 多写代码少哔哔 的原则，会主要以实际操作为主，不会过多介绍每步细节动作，如果纯小白想要更详细的了解，可以参考 这里

环境总共 5 台虚拟机，2 个 master，3 个 etcd 节点，master 同时也作为 node 负载 pod，在分发证书等阶段将在另外一台主机上执行，该主机对集群内所有节点配置了 ssh 秘钥登录

![](https://www.centos.bz/wp-content/uploads/2017/07/1-45.png)

网络方案这里采用性能比较好的 Calico，集群开启 RBAC，RBAC 相关可参考：[https](https://www.centos.bz/tag/https/)://mritd.me/2017/07/17/kubernetes-rbac-chinese-translation/

## 二、证书相关处理

### 2.1、证书说明

由于 Etcd 和 Kubernetes 全部采用 TLS 通讯，所以先要生成 TLS 证书，证书生成工具采用 cfssl，具体使用方法这里不再详细阐述，生成证书时可在任一节点完成，这里在宿主机执行，证书列表如下

![](https://www.centos.bz/wp-content/uploads/2017/07/2-37.png)

### 2.2、CFSSL 工具安装和证书生成

```bash
#!/bin/sh
set -e

wget -c https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget -c https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget -c https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x *-amd64
mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo

cat >ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "87600h"
        },
        "profiles": {
            "kubernetes": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

cat >ca-csr.json <<EOF
 {
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

cat >server-csr.json <<EOF
 {
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "192.168.128.140",
      "192.168.128.141",
      "192.168.128.142",
      "kubernetes-master",
      "kubernetes-node1",
      "k8s.baidu.com"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server

cat >admin-csr.json <<EOF
 {
    "CN": "admin",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "system:masters",
            "OU": "System"
        }
    ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

cat >kube-proxy-csr.json <<EOF
 {
    "CN": "system:kube-proxy",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

```




生成后证书列表如下

├── admin.csr
├── admin-csr.json
├── admin-key.pem
├── admin.pem
├── ca-config.json
├── ca.csr
├── ca-csr.json
├── ca-key.pem
├── ca.pem
├── kube-proxy.csr
├── kube-proxy-csr.json
├── kube-proxy-key.pem
├── kube-proxy.pem
├── server.csr
├── server-csr.json
├── server-key.pem
└── server.pem

### 2.3、etcd 集群安装


![](paste_image/2019-06-19-19-54-42.png)

下载地址: https://github.com/etcd-io/etcd/releases


mkdir -p /opt/kubernetes/{bin,cfg,ssl}
cp server.pem server-key.pem ca.pem  ca-key.pem /opt/kubernetes/ssl/


wget -c https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz

tar zxvf etcd-v3.3.13-linux-amd64.tar.gz
cd etcd-v3.3.13-linux-amd64
mv etcd* /opt/kubernetes/bin/


```
cat > /opt/kubernetes/cfg/etcd <<EOF
# [member]
# etcd名称
ETCD_NAME="etcd01"
# 服务运行数据保存的路径
ETCD_DATA_DIR="/var/lib/etcd/etcd01.etcd"
# 监听的同伴通信的地址
ETCD_LISTEN_PEER_URLS="https://192.168.1.11:2380"
# 监听的客户端服务地址
ETCD_LISTEN_CLIENT_URLS="https://192.168.1.11:2379,http://127.0.0.1:2379"


# [cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.1.11:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.1.11:2379"
ETCD_INITIAL_CLUSTER="etcd01=https://192.168.1.11:2380,etcd02=https://192.168.1.12:2380,etcd03=https://192.168.1.13:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF


```

```
cat > /usr/lib/systemd/system/etcd.service <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=-/opt/kubernetes/cfg/etcd
ExecStart=/opt/kubernetes/bin/etcd \
--name=${ETCD_NAME} \
--data-dir=${ETCD_DATA_DIR} \
--listen-peer-urls=${ETCD_LISTEN_PEER_URLS} \
--listen-client-urls=${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
--advertise-client-urls=${ETCD_ADVERTISE_CLIENT_URLS} \
--initial-advertise-peer-urls=${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
--initial-cluster=${ETCD_INITIAL_CLUSTER} \
--initial-cluster-token=${ETCD_INITIAL_CLUSTER_TOKEN} \
--initial-cluster-state=new \
--cert-file=/opt/kubernetes/ssl/server.pem \
--key-file=/opt/kubernetes/ssl/server-key.pem \
--peer-cert-file=/opt/kubernetes/ssl/server.pem \
--peer-key-file=/opt/kubernetes/ssl/server-key.pem \
--trusted-ca-file=/opt/kubernetes/ssl/ca.pem \
--peer-trusted-ca-file=/opt/kubernetes/ssl/ca.pem
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

```

systemctl start etcd
systemctl enable etcd

把相关文件复制到其它的服务器，然后修改配置文件启动服务

### 2.5、生成 token 及 kubeconfig





生成 [token](https://www.centos.bz/tag/token/) 如下

<pre>`export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
cat &gt; token.csv &lt;&lt;EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
`</pre>

创建 kubelet bootstrapping kubeconfig 配置，对于 node 节点，api server 地址为本地 [nginx](https://www.centos.bz/category/web-server/nginx/) 监听的 127.0.0.1:6443，如果想把 master 也当做 node 使用，那么 master 上 api server 地址应该为 masterIP:6443，因为在 master 上没必要也无法启动 [nginx](https://www.centos.bz/tag/nginx-2/) 来监听 127.0.0.1:6443(6443 已经被 master 上的 api server 占用了)

所以以下配置只适合 node 节点，如果想把 master 也当做 node，那么需要重新生成下面的 kubeconfig 配置，并把 api server 地址修改为当前 master 的 api server 地址

<pre>`export KUBE_APISERVER="https://127.0.0.1:6443"
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=k8s-root-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
`</pre>

创建 kube-proxy kubeconfig 配置，同上面一样，如果想要把 master 当 node 使用，需要修改 api server

<pre>`# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=k8s-root-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
`</pre>

## 三、部署 HA ETCD

### 3.1、安装 Etcd

ETCD 直接采用 rpm 安装，RPM 可以从 Fedora 官方仓库 获取 spec 文件自己 build，或者直接从 rpmFind 网站 搜索

<pre>`# 下载 rpm 包
wget ftp://195.220.108.108/[linux](https://www.centos.bz/tag/linux/)/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/e/etcd-3.1.9-1.fc27.x86_64.rpm
# 分发并安装 rpm
for IP in `seq 1 3`; do
    scp etcd-3.1.9-1.fc27.x86_64.rpm root@192.168.1.1$IP:~
    ssh root@192.168.1.1$IP rpm -ivh etcd-3.1.9-1.fc27.x86_64.rpm
done
`</pre>

### 3.2、分发证书

<pre>`for IP in `seq 1 3`;do
    ssh root@192.168.1.1$IP mkdir /etc/etcd/ssl
    scp *.pem root@192.168.1.1$IP:/etc/etcd/ssl
    ssh root@192.168.1.1$IP chown -R etcd:etcd /etc/etcd/ssl
    ssh root@192.168.1.1$IP chmod -R 755 /etc/etcd
done
`</pre>

### 3.3、修改配置

rpm 安装好以后直接修改 /etc/etcd/etcd.conf 配置文件即可，其中单个节点配置如下(其他节点只是名字和 IP 不同)

<pre>`# [member]
ETCD_NAME=etcd1
ETCD_DATA_DIR="/var/lib/etcd/etcd1.etcd"
ETCD_WAL_DIR="/var/lib/etcd/wal"
ETCD_SNAPSHOT_COUNT="100"
ETCD_HEARTBEAT_INTERVAL="100"
ETCD_ELECTION_TIMEOUT="1000"
ETCD_LISTEN_PEER_URLS="https://192.168.1.11:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.1.11:2379,http://127.0.0.1:2379"
ETCD_MAX_SNAPSHOTS="5"
ETCD_MAX_WALS="5"
#ETCD_CORS=""

# [cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.1.11:2380"
# if you use different ETCD_NAME (e.g. test), set ETCD_INITIAL_CLUSTER value for this name, i.e. "test=http://..."
ETCD_INITIAL_CLUSTER="etcd1=https://192.168.1.11:2380,etcd2=https://192.168.1.12:2380,etcd3=https://192.168.1.13:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.1.11:2379"
#ETCD_DISCOVERY=""
#ETCD_DISCOVERY_SRV=""
#ETCD_DISCOVERY_FALLBACK="proxy"
#ETCD_DISCOVERY_PROXY=""
#ETCD_STRICT_RECONFIG_CHECK="false"
#ETCD_AUTO_COMPACTION_RETENTION="0"

# [proxy]
#ETCD_PROXY="off"
#ETCD_PROXY_FAILURE_WAIT="5000"
#ETCD_PROXY_REFRESH_INTERVAL="30000"
#ETCD_PROXY_DIAL_TIMEOUT="1000"
#ETCD_PROXY_WRITE_TIMEOUT="5000"
#ETCD_PROXY_READ_TIMEOUT="0"

# [security]
ETCD_CERT_FILE="/etc/etcd/ssl/etcd.pem"
ETCD_KEY_FILE="/etc/etcd/ssl/etcd-key.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-root-ca.pem"
ETCD_AUTO_TLS="true"
ETCD_PEER_CERT_FILE="/etc/etcd/ssl/etcd.pem"
ETCD_PEER_KEY_FILE="/etc/etcd/ssl/etcd-key.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-root-ca.pem"
ETCD_PEER_AUTO_TLS="true"

# [logging]
#ETCD_DEBUG="false"
# examples for -log-package-levels etcdserver=WARNING,security=[DEBUG](https://www.centos.bz/tag/debug/)
#ETCD_LOG_PACKAGE_LEVELS=""
`</pre>

### 3.4、启动及验证

配置修改后在每个节点进行启动即可，注意，Etcd 哥哥节点间必须保证时钟同步，否则会造成启动失败等错误

<pre>`systemctl daemon-reload
systemctl start etcd
systemctl enable etcd
`</pre>

启动成功后验证节点状态

<pre>`export ETCDCTL_API=3
etcdctl --cacert=/etc/etcd/ssl/etcd-root-ca.pem --cert=/etc/etcd/ssl/etcd.pem --key=/etc/etcd/ssl/etcd-key.pem --endpoints=https://192.168.1.11:2379,https://192.168.1.12:2379,https://192.168.1.13:2379 endpoint health
`</pre>

最后截图如下，警告可忽略

![](https://www.centos.bz/wp-content/uploads/2017/07/5-6.jpg)

## 四、部署 HA Master

### 4.1、HA Master 简述

目前所谓的 Kubernetes HA 其实主要的就是 API Server 的 HA，master 上其他组件比如 controller-manager 等都是可以通过 Etcd 做选举；而 API Server 只是提供一个请求接收服务，所以对于 API Server 一般有两种方式做 HA；一种是对多个 API Server 做 vip，另一种使用 nginx 反向代理，本文采用 nginx 方式，以下为 HA 示意图

![](https://www.centos.bz/wp-content/uploads/2017/07/6-4.jpg)

master 之间除 api server 以外其他组件通过 etcd 选举，api server 默认不作处理；在每个 node 上启动一个 nginx，每个 nginx 反向代理所有 api server，node 上 kubelet、kube-proxy 连接本地的 nginx 代理端口，当 nginx 发现无法连接后端时会自动踢掉出问题的 api server，从而实现 api server 的 HA

### 4.2、部署前预处理

一切以偷懒为主，所以我们仍然采用 rpm 的方式来安装 kubernetes 各个组件，关于 rpm 获取方式可以参考 How to build Kubernetes RPM，以下文章默认认为你已经搞定了 rpm

<pre>`# 分发 rpm
for IP in `seq 1 3`; do
    scp kubernetes*.rpm root@192.168.1.1$IP:~; 
    ssh root@192.168.1.1$IP yum install -y conntrack-tools socat
    ssh root@192.168.1.1$IP rpm -ivh kubernetes*.rpm
done
`</pre>

rpm 安装好以后还需要进行分发证书配置等

<pre>`for IP in `seq 1 3`;do
    ssh root@192.168.1.1$IP mkdir /etc/kubernetes/ssl
    scp *.pem root@192.168.1.1$IP:/etc/kubernetes/ssl
    scp *.kubeconfig root@192.168.1.1$IP:/etc/kubernetes
    scp token.csv root@192.168.1.1$IP:/etc/kubernetes
    ssh root@192.168.1.1$IP chown -R kube:kube /etc/kubernetes/ssl
done
`</pre>

最后由于 api server 会写入一些日志，所以先创建好相关目录，并做好授权，防止因为权限错误导致 api server 无法启动

<pre>`for IP in `seq 1 3`;do
    ssh root@192.168.1.1$IP mkdir /var/log/kube-audit  
    ssh root@192.168.1.1$IP chown -R kube:kube /var/log/kube-audit
    ssh root@192.168.1.1$IP chmod -R 755 /var/log/kube-audit
done
`</pre>

### 4.3、修改 master 配置

rpm 安装好以后，默认会生成 /etc/kubernetes 目录，并且该目录中会有很多配置，其中 config 配置文件为通用配置，具体文件如下

<pre>`➜  kubernetes tree
.
├── apiserver
├── config
├── controller-manager
├── kubelet
├── proxy
└── scheduler

0 directories, 6 files
`</pre>

master 需要编辑 config、apiserver、controller-manager、scheduler这四个文件，具体修改如下

*   config 通用配置
<pre>`###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=2"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=true"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=http://127.0.0.1:8080"
`</pre>

*   apiserver 配置(其他节点只有 IP 不同)
<pre>`###
# kubernetes system config
#
# The following values are used to configure the kube-apiserver
#

# The address on the local server to listen to.
KUBE_API_ADDRESS="--advertise-address=192.168.1.11 --insecure-bind-address=127.0.0.1 --bind-address=192.168.1.11"

# The port on the local server to listen on.
KUBE_API_PORT="--insecure-port=8080 --secure-port=6443"

# Port minions listen on
# KUBELET_PORT="--kubelet-port=10250"

# Comma separated list of nodes in the etcd cluster
KUBE_ETCD_SERVERS="--etcd-servers=https://192.168.1.11:2379,https://192.168.1.12:2379,https://192.168.1.13:2379"

# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"

# default admission control policies
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"

# Add your own!
KUBE_API_ARGS="--authorization-mode=RBAC \
                --runtime-config=rbac.authorization.k8s.io/v1beta1 \
                --anonymous-auth=false \
                --kubelet-https=true \
                --experimental-bootstrap-token-auth \
                --token-auth-file=/etc/kubernetes/token.csv \
                --service-node-port-range=30000-50000 \
                --tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem \
                --tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
                --client-ca-file=/etc/kubernetes/ssl/k8s-root-ca.pem \
                --service-account-key-file=/etc/kubernetes/ssl/k8s-root-ca.pem \
                --etcd-quorum-read=true \
                --storage-backend=etcd3 \
                --etcd-cafile=/etc/etcd/ssl/etcd-root-ca.pem \
                --etcd-certfile=/etc/etcd/ssl/etcd.pem \
                --etcd-keyfile=/etc/etcd/ssl/etcd-key.pem \
                --enable-swagger-ui=true \
                --apiserver-[count](https://www.centos.bz/tag/count/)=3 \
                --audit-log-maxage=30 \
                --audit-log-maxbackup=3 \
                --audit-log-maxsize=100 \
                --audit-log-path=/var/log/kube-audit/audit.log \
                --[event](https://www.centos.bz/tag/event/)-ttl=1h"
`</pre>

*   controller-manager 配置
<pre>`###
# The following values are used to configure the kubernetes controller-manager

# defaults from config and apiserver should be adequate

# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS="--address=0.0.0.0 \
                              --service-cluster-ip-range=10.254.0.0/16 \
                              --cluster-name=kubernetes \
                              --cluster-signing-cert-file=/etc/kubernetes/ssl/k8s-root-ca.pem \
                              --cluster-signing-key-file=/etc/kubernetes/ssl/k8s-root-ca-key.pem \
                              --service-account-private-key-file=/etc/kubernetes/ssl/k8s-root-ca-key.pem \
                              --root-ca-file=/etc/kubernetes/ssl/k8s-root-ca.pem \
                              --leader-elect=true \
                              --node-monitor-grace-period=40s \
                              --node-monitor-period=5s \
                              --pod-eviction-timeout=5m0s"
`</pre>

*   scheduler 配置
<pre>`###
# kubernetes scheduler config

# default config should be adequate

# Add your own!
KUBE_SCHEDULER_ARGS="--leader-elect=true --address=0.0.0.0"
`</pre>

其他 master 节点配置相同，只需要修改以下 IP 地址即可，修改完成后启动 api server

<pre>`systemctl daemon-reload
systemctl start kube-apiserver
systemctl start kube-controller-manager
systemctl start kube-scheduler
systemctl enable kube-apiserver
systemctl enable kube-controller-manager
systemctl enable kube-scheduler
`</pre>

各个节点启动成功后，验证组件状态(kubectl 在不做任何配置的情况下默认链接本地 8080 端口)如下，其中 etcd 全部为 Unhealthy 状态，并且提示 remote error: tls: bad certificate 这是个 bug，不影响实际使用，具体可参考 [issue](https://www.centos.bz/tag/issue/)

![](https://www.centos.bz/wp-content/uploads/2017/07/7-5.jpg)

## 五、部署 Node

### 5.1、部署前预处理

部署前分发 rpm 以及证书、token 等配置

<pre>`# 分发 rpm
for IP in `seq 4 5`;do
    scp kubernetes-node-1.6.7-1.el7.centos.x86_64.rpm kubernetes-client-1.6.7-1.el7.centos.x86_64.rpm root@192.168.1.1$IP:~; 
    ssh root@192.168.1.1$IP yum install -y conntrack-tools socat
    ssh root@192.168.1.1$IP rpm -ivh kubernetes-node-1.6.7-1.el7.centos.x86_64.rpm kubernetes-client-1.6.7-1.el7.centos.x86_64.rpm
done
# 分发证书等配置文件
for IP in `seq 4 5`;do
    ssh root@192.168.1.1$IP mkdir /etc/kubernetes/ssl
    scp *.pem root@192.168.1.1$IP:/etc/kubernetes/ssl
    scp *.kubeconfig root@192.168.1.1$IP:/etc/kubernetes
    scp token.csv root@192.168.1.1$IP:/etc/kubernetes
    ssh root@192.168.1.1$IP chown -R kube:kube /etc/kubernetes/ssl
done
`</pre>

### 5.2、修改 node 配置

node 节点上配置文件同样位于 /etc/kubernetes 目录，node 节点只需要修改 config、kubelet、proxy 这三个配置文件，修改如下

*   config 通用配置

注意: config 配置文件(包括下面的 kubelet、proxy)中全部未 定义 API Server 地址，因为 kubelet 和 kube-proxy 组件启动时使用了 &#8211;require-kubeconfig 选项，该选项会使其从 *.kubeconfig 中读取 API Server 地址，而忽略配置文件中设置的；所以配置文件中设置的地址其实是无效的

<pre>`###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=2"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=true"

# How the controller-manager, scheduler, and proxy find the apiserver
# KUBE_MASTER="--master=http://127.0.0.1:8080"
`</pre>

kubelet 配置

<pre>`###
# kubernetes kubelet (minion) config

# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
KUBELET_ADDRESS="--address=192.168.1.14"

# The port for the info server to serve on
# KUBELET_PORT="--port=10250"

# You may leave this blank to use the actual hostname
KUBELET_HOSTNAME="--hostname-override=docker4.node"

# location of the api-server
# KUBELET_API_SERVER=""

# Add your own!
KUBELET_ARGS="--cgroup-driver=cgroupfs \
              --cluster-dns=10.254.0.2 \
              --resolv-conf=/etc/resolv.conf \
              --experimental-bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \
              --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
              --require-kubeconfig \
              --cert-dir=/etc/kubernetes/ssl \
              --cluster-domain=cluster.local. \
              --hairpin-mode promiscuous-bridge \
              --serialize-[image](https://www.centos.bz/tag/image/)-pulls=false \
              --pod-infra-container-image=gcr.io/google_containers/pause-amd64:3.0"
`</pre>

proxy 配置

<pre>`###
# kubernetes proxy config

# default config should be adequate

# Add your own!
KUBE_PROXY_ARGS="--bind-address=192.168.1.14 \
                  --hostname-override=docker4.node \
                  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \
                  --cluster-cidr=10.254.0.0/16"
`</pre>

5.3、创建 ClusterRoleBinding

由于 kubelet 采用了 TLS Bootstrapping，所有根绝 RBAC 控制策略，kubelet 使用的用户 kubelet-bootstrap 是不具备任何访问 API 权限的，这是需要预先在集群内创建 ClusterRoleBinding 授予其 system:node-bootstrapper Role

<pre>`# 在任意 master 执行即可
kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --user=kubelet-bootstrap
`</pre>

### 5.4、创建 nginx 代理

根据上面描述的 master HA 架构，此时所有 node 应该连接本地的 nginx 代理，然后 nginx 来负载所有 api server；以下为 nginx 代理相关配置

<pre>`# 创建配置目录
mkdir -p /etc/nginx

# 写入代理配置
cat &lt;&lt; EOF &gt;&gt; /etc/nginx/nginx.conf
error_log stderr notice;

worker_processes auto;
events {
  multi_accept on;
  use epoll;
  worker_connections 1024;
}

stream {
    upstream kube_apiserver {
        least_conn;
        server 192.168.1.11:6443;
        server 192.168.1.12:6443;
        server 192.168.1.13:6443;
    }

    server {
        listen        0.0.0.0:6443;
        proxy_pass    kube_apiserver;
        proxy_timeout 10m;
        proxy_connect_timeout 1s;
    }
}
EOF

# 更新权限
chmod +r /etc/nginx/nginx.conf
`</pre>

为了保证 nginx 的可靠性，综合便捷性考虑，node 节点上的 nginx 使用 docker 启动，同时 使用 systemd 来守护， systemd 配置如下

<pre>`cat &lt;&lt; EOF &gt;&gt; /etc/systemd/system/nginx-proxy.service
[Unit]
Description=kubernetes apiserver docker wrapper
Wants=docker.socket
After=docker.service

[Service]
User=root
PermissionsStartOnly=true
ExecStart=/usr/bin/docker run -p 127.0.0.1:6443:6443 \\
                              -v /etc/nginx:/etc/nginx \\
                              --name nginx-proxy \\
                              --net=host \\
                              --restart=on-failure:5 \\
                              --memory=512M \\
                              nginx:1.13.3-alpine
ExecStartPre=-/usr/bin/docker rm -f nginx-proxy
ExecStop=/usr/bin/docker stop nginx-proxy
Restart=always
RestartSec=15s
TimeoutStartSec=30s

[Install]
WantedBy=multi-user.target
EOF
`</pre>

最后启动 nginx，同时可以使用 kubectl 测试 api server 负载情况

<pre>`systemctl daemon-reload
systemctl start nginx-proxy
systemctl enable nginx-proxy
`</pre>

启动成功后如下

![](https://www.centos.bz/wp-content/uploads/2017/07/8-5.jpg)

kubectl 测试联通性如下

![](https://www.centos.bz/wp-content/uploads/2017/07/9-3.jpg)

### 5.5、添加 Node

一起准备就绪以后就可以启动 node 相关组件了

<pre>`systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet
`</pre>

由于采用了 TLS Bootstrapping，所以 kubelet 启动后不会立即加入集群，而是进行证书申请，从日志中可以看到如下输出

<pre>`Jul 19 14:15:31 docker4.node kubelet[18213]: I0719 14:15:31.810914   18213 feature_gate.go:144] feature gates: map[]
Jul 19 14:15:31 docker4.node kubelet[18213]: I0719 14:15:31.811025   18213 bootstrap.go:58] Using bootstrap kubeconfig to generate TLS client cert, key and kubeconfig file
`</pre>

此时只需要在 master 允许其证书申请即可

<pre>`# 查看 csr
➜  kubernetes kubectl get csr
NAME        AGE       REQUESTOR           CONDITION
csr-l9d25   2m        kubelet-bootstrap   Pending
# 签发证书
➜  kubernetes kubectl certificate approve csr-l9d25
certificatesigningrequest "csr-l9d25" approved
# 查看 node
➜  kubernetes kubectl get node
NAME           STATUS    AGE       VERSION
docker4.node   Ready     26s       v1.6.7
`</pre>

最后再启动 kube-proxy 组件即可

<pre>`systemctl start kube-proxy
systemctl enable kube-proxy
`</pre>

### 5.6、Master 开启 Pod 负载

Master 上部署 Node 与单独 Node 部署大致相同，只需要修改 bootstrap.kubeconfig、kube-proxy.kubeconfig 中的 API Server 地址即可

![](https://www.centos.bz/wp-content/uploads/2017/07/10-3.jpg)

然后修改 kubelet、proxy 配置启动即可

<pre>`systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet
systemctl start kube-proxy
systemctl enable kube-proxy
`</pre>

最后在 master 签发一下相关证书

<pre>`kubectl certificate approve csr-z090b
`</pre>

整体部署完成后如下

![](https://www.centos.bz/wp-content/uploads/2017/07/11-4.jpg)

## 六、部署 Calico

网路组件这里采用 Calico，Calico 目前部署也相对比较简单，只需要创建一下 yml 文件即可，具体可参考 Calico 官方文档

Cliaco 官方文档要求 kubelet 启动时要配置使用 cni 插件 &#8211;network-plugin=cni，同时 kube-proxy 使用 &#8211;masquerade-all 启动，所以需要修改所有 kubelet 和 proxy 配置文件增加这两项，以下默认为这两项已经调整完毕，这里不做演示

<pre>`# 获取相关 Cliaco.yml
wget http://docs.projectcalico.org/v2.3/getting-started/kubernetes/installation/hosted/calico.yaml

# 修改 Etcd 相关配置，以下列出主要修改部分(etcd 证书内容需要被 base64 转码)

sed -i 's@.*etcd_endpoints:.*@\ \ etcd_endpoints:\ \"https://192.168.1.11:2379,https://192.168.1.12:2379,https://192.168.1.13:2379\"@gi' calico.yaml

export ETCD_CERT=`cat /etc/etcd/ssl/etcd.pem | base64 | tr -d '\n'`
export ETCD_KEY=`cat /etc/etcd/ssl/etcd-key.pem | base64 | tr -d '\n'`
export ETCD_CA=`cat /etc/etcd/ssl/etcd-root-ca.pem | base64 | tr -d '\n'`

sed -i "s@.*etcd-cert:.*@\ \ etcd-cert:\ ${ETCD_CERT}@gi" calico.yaml
sed -i "s@.*etcd-key:.*@\ \ etcd-key:\ ${ETCD_KEY}@gi" calico.yaml
sed -i "s@.*etcd-ca:.*@\ \ etcd-ca:\ ${ETCD_CA}@gi" calico.yaml

sed -i 's@.*etcd_ca:.*@\ \ etcd_ca:\ "/calico-secrets/etcd-ca"@gi' calico.yaml
sed -i 's@.*etcd_cert:.*@\ \ etcd_cert:\ "/calico-secrets/etcd-cert"@gi' calico.yaml
sed -i 's@.*etcd_key:.*@\ \ etcd_key:\ "/calico-secrets/etcd-key"@gi' calico.yaml

sed -i 's@192.168.0.0/16@10.254.64.0/18@gi' calico.yaml
`</pre>

执行部署操作，注意，在开启 RBAC 的情况下需要单独创建 ClusterRole 和 ClusterRoleBinding

<pre>`kubectl create -f calico.yaml
kubectl apply -f http://docs.projectcalico.org/v2.3/getting-started/kubernetes/installation/rbac.yaml
`</pre>

部署完成后如下

![](https://www.centos.bz/wp-content/uploads/2017/07/12-1.jpg)

最后测试一下跨主机通讯

<pre>`# 创建 deployment
cat &lt;&lt; EOF &gt;&gt; demo.deploy.yml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: demo-deployment
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
      - name: demo
        image: mritd/demo
        ports:
        - containerPort: 80
EOF
kubectl create -f demo.deploy.yml
`</pre>

exec 到一台主机 pod 内 ping 另一个不同 node 上的 pod 如下

![](https://www.centos.bz/wp-content/uploads/2017/07/13-1.jpg)

## 七、部署 DNS

### 7.1、DNS 组件部署

DNS 部署目前有两种方式，一种是纯手动，另一种是使用 Addon-manager，目前个人感觉 Addon-manager 有点繁琐，所以以下采取纯手动部署 DNS 组件

DNS 组件相关文件位于 kubernetes addons 目录下，把相关文件下载下来然后稍作修改即可

<pre>`# 获取文件
mkdir dns &amp;&amp; cd dns
wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/kubedns-cm.yaml
wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/kubedns-sa.yaml
wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/kubedns-svc.yaml.sed
wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/kubedns-controller.yaml.sed
mv kubedns-controller.yaml.sed kubedns-controller.yaml
mv kubedns-svc.yaml.sed kubedns-svc.yaml
# 修改配置
sed -i 's/$DNS_DOMAIN/cluster.local/gi' kubedns-controller.yaml
sed -i 's/$DNS_SERVER_IP/10.254.0.2/gi' kubedns-svc.yaml
# 创建(我把所有 yml 放到的 dns 目录中)
kubectl create -f ../dns
`</pre>

接下来测试 DNS，测试方法创建两个 deployment 和 svc，通过在 pod 内通过 svc 域名方式访问另一个 deployment 下的 pod，相关测试的 deploy、svc 配置在这里不在展示，基本情况如下图所示

![](https://www.centos.bz/wp-content/uploads/2017/07/14-1.jpg)

![](https://www.centos.bz/wp-content/uploads/2017/07/15.jpg)

### 7.2、DNS 自动扩容部署

关于 DNS 自动扩容详细可参考https://kubernetes.io/docs/tasks/administer-cluster/dns-horizontal-autoscaling/

以下直接操作

首先获取 Dns horizontal autoscaler 配置文件

<pre>`wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns-horizontal-autoscaler/dns-horizontal-autoscaler-rbac.yaml
wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns-horizontal-autoscaler/dns-horizontal-autoscaler.yaml

然后直接 kubectl create -f 即可，DNS 自动扩容计算公式为 replicas = max( ceil( cores * 1/coresPerReplica ) , ceil( nodes * 1/nodesPerReplica ) )，如果想调整 DNS 数量(负载因子)，只需要调整 ConfigMap 中对应参数即可，具体计算细节参考上面的官方文档




