#### 1. 安装准备

- 下载yaml文件
> 记得开启科学上网
> curl -# -o coredns.yaml https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed
> 各版本对应关系 https://github.com/coredns/deployment/blob/master/kubernetes/CoreDNS-k8s_version.md

- 修改coredns配置

```bash
sed -i "s#REVERSE_CIDRS#in-addr.arpa ip6.arpa#" coredns.yaml
sed -i "s#CLUSTER_DOMAIN#cluster.local#" coredns.yaml       #cluster.local需和你kubelet配置的cluster-domain保持一致
sed -i "s#UPSTREAMNAMESERVER#/etc/resolv.conf#" coredns.yaml
sed -i "s#FEDERATIONS##" coredns.yaml
sed -i "s#STUBDOMAINS##" coredns.yaml
sed -i "s#CLUSTER_DNS_IP#10.10.10.2#" coredns.yaml      # 此IP需和你kubelet配置的IP一致
sed -i "s#coredns/coredns:1.6.5#registry.cn-hangzhou.aliyuncs.com/k8s_xzb/coredns:1.6.5#" coredns.yaml
# 删除kube-dns的deployment或replication controller
# kubectl delete --namespace=kube-system deployment kube-dns
# 运行脚本文件
# ./deploy.sh -r 10.10.10.0/24 -i 10.10.10.2  -d cluster.local -t coredns.yaml.sed -s >coredns.yaml
kubectl apply -f coredns.yaml
limits memory改成合适的内存容量，比如170Mi

kubectl logs -f pod/coredns-86c8ccfbb8-8t99j    # 查询pod中使用的dns版本

# service名.空间.svc.集群域名       nginx-alpine-service.default.svc.cluster.local
```


```shell
.:53 {
    errors  #errors官方没有明确解释，后面研究
    health {    # 健康检查，提供了指定端口（默认为8080）
      lameduck 5s
    }
    ready
    kubernetes dukang.local in-addr.arpa ip6.arpa {
      pods insecure
      fallthrough in-addr.arpa ip6.arpa
    }
    prometheus :9153
    forward . /etc/resolv.conf
    cache 30    # 这允许缓存两个响应结果，一个是肯定结果（即，查询返回一个结果）和否定结果（查询返回“没有这样的域”），具有单独的高速缓存大小和TTLs。
    loop
    reload
    loadbalance
}
# log stdout:日志中间件配置为将日志写入STDOUT

```