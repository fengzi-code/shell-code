

#master  1 4�� 8G 192.168.1.25  k8s-master
#minion  1 4�� 12G  192.168.1.26  k8s-node-1
#minion  1 4�� 8G 192.168.1.36  k8s-node-2

swapoff -a

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

#kubernetes yumԴ
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
EOF

sysctl --system



yum install -y docker
systemctl enable docker
systemctl start docker

yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && sudo systemctl start kubelet


kube-apiserver-amd64:v1.9.6
kube-controller-manager-amd64:v1.9.6
kube-scheduler-amd64:v1.9.6

echo "proxy=http://192.168.6.53:1080" >> /etc/yum.conf

cat >> /etc/profile <<EOF
http_proxy=http://192.168.6.53:1080/
ftp_proxy=http://192.168.6.53:1080/
export http_proxy
export ftp_proxy
EOF

source /etc/profile



mkdir -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://192.168.6.53:1080" "NO_PROXY=localhost,172.16.0.0/16,127.0.0.1,10.244.0.0/16,192.168.0.0/16"
EOF


cat > /etc/systemd/system/docker.service.d/https-proxy.conf <<EOF
[Service]
Environment="HTTPS_PROXY=https://192.168.6.53:1080" "NO_PROXY=localhost,172.16.0.0/16,127.0.0.1,10.244.0.0/16,192.168.0.0/16"
EOF

systemctl daemon-reload && systemctl restart docker




location ^~/grg-mange-base/wxapi/weChatUser/ {
    proxy_pass http://192.168.1.28:1120/wxapi/weChatUser/;
    proxy_redirect default;
    proxy_set_header Host $host;
    proxy_set_header X - Real - IP $remote_addr;
    proxy_set_header X - Forwarded - Host $host;
    proxy_set_header X - Forwarded - Server $host;
    proxy_set_header X - Forwarded - For $proxy_add_x_forwarded_for;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    
}