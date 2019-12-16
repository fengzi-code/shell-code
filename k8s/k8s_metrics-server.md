
#### metrics-server安装与配置

- 相关网站
   - 官方文件 https://github.com/kubernetes-incubator/metrics-server
   - k8s 版本 https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/metrics-server
- 下载yaml文件
```shell
# curl  -o es-service.yaml  https://raw.githubusercontent.com/kubernetes/kubernetes/release-1.15/cluster/addons/fluentd-elasticsearch/es-service.yaml
for x in auth-delegator.yaml \
auth-reader.yaml \
metrics-apiservice.yaml \
metrics-server-deployment.yaml \
metrics-server-service.yaml \
resource-reader.yaml;
do wget -c https://raw.githubusercontent.com/kubernetes-sigs/metrics-server/master/deploy/1.8%2B/$x;
done

```

- 修改yaml文件
   - 修改metrics-server-deployment.yaml文件
   ```yaml
   # 修改参数和镜像地址
   - name: metrics-server
        image: registry.cn-hangzhou.aliyuncs.com/k8s_xzb/metrics-server-amd64:v0.3.6
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
          - --metric-resolution=30s
          - --kubelet-insecure-tls
          - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
   ```
- 修改apiserver启动参数,开启聚合服务
```shell
# 在kube-apiserver配置文件添加如下参数
# 注意更改自己的证书,客户端需为proxy的证书
# --requestheader-allowed-names= 不验证证书中角色名字，直接验证角色权限
--runtime-config=api/all=true \
--proxy-client-cert-file=/opt/kubernetes/ssl/kube-proxy.pem \
--proxy-client-key-file=/opt/kubernetes/ssl/kube-proxy-key.pem \
--requestheader-client-ca-file=/opt/kubernetes/ssl/ca.pem \
--requestheader-allowed-names= \
--requestheader-extra-headers-prefix=X-Remote-Extra- \
--requestheader-group-headers=X-Remote-Group \
--requestheader-username-headers=X-Remote-User
```

- master上添加路由表
1. 由于metrics-server服务调用的时候是集群IP,如果二进制安装的master没有安装proxy组件,不能访问集群IP, kubeadm安装的可以忽略
2. 当使用 kubectl get apiservices v1beta1.metrics.k8s.io -o yaml 查看时发现不能连接
3. 使用命令 `ip route add 集群IP子网 via 能连接集群IP的NODE节点IP`   添加路由表
```bash
# 临时添加 
# route add 10.10.10.0 mask 255.255.255.0 192.168.0.150
ip route add 10.10.10.0/24 via 192.168.0.150
# 永久添加
echo 'ip route add 10.10.10.0/24 via 192.168.0.150' >> /etc/rc.local
chmod  755  /etc/rc.d/rc.local
```
- 运行pod
```shell
cd /opt/yaml/metrics-server
kubectl apply -f .
```
- 查看运行状况,显示如下则表明正常
```shell
kubectl top node
# NAME            CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# 192.168.0.150   104m         2%     598Mi           16%
# 192.168.0.151   99m          2%     595Mi           16%
# 192.168.0.152   97m          2%     633Mi           17%
```