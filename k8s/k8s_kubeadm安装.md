[toc]

#### 1. 安装前准备
```sh

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

#关闭selinux
setenforce 0
sed  -i s/SELINUX\=enforcing/SELINUX=disabled/g /etc/selinux/config

# 关闭交换空间
sed -i /swap/s/^/#/g /etc/fstab
swapoff -a

```

#### 2. 安装kubelet kubeadm

```sh
cd /etc/yum.repos.d/
wget "https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"


wget "https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg"
rpm --import yum-key.gpg
rm -f yum-key.gpg

cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=kubernetes repo
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
enabled=1
EOF

yum repolist

yum list docker-ce --showduplicates|grep "^doc"|sort -r

#yum install docker-ce-18.09.8-3.el7
yum install docker-ce kubelet kubeadm

# 增加镜像加速器
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://0by6hvzh.mirror.aliyuncs.com"]
}
EOF

systemctl start docker

rpm -ql kubelet     #查看一下安装选项
systemctl enable docker
systemctl enable kubelet


```

#### 3. kubeadm初始化


```sh


kubeadm init --kubernetes-version=1.15.0 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --image-repository='registry.aliyuncs.com/google_containers'

#复制出节点加入命令
kubeadm join 192.168.128.130:6443 --token l4xwam.9bt3f5al3r1t4j9j \
    --discovery-token-ca-cert-hash sha256:ad09f98a87c546f8732435b0e3be0ad59d5f23e2c7a7afe91f1d4cd2339be134
# 执行以下命令,以使用kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config

```

#### 4. 安装网络插件

```sh
mkdir -p /opt/kubernetes/yaml
cd /opt/kubernetes/yaml/
wget "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
kubectl apply -f kube-flannel.yml

```

#### 5. NODE节点安装

1. 重复步骤1 2
2. 复制步骤3中的加入节点命令运行

```sh
kubeadm join 192.168.128.130:6443 --token l4xwam.9bt3f5al3r1t4j9j \
    --discovery-token-ca-cert-hash sha256:ad09f98a87c546f8732435b0e3be0ad59d5f23e2c7a7afe91f1d4cd2339be134
```