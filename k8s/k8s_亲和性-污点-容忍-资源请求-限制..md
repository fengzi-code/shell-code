


#### 1. 亲和性
```yaml
# https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
spec:
  selector:
    matchLabels:
      app: web-store
  replicas: 3
  template:
    metadata:
      labels:
        app: web-store
    spec:
      nodeSelector:     # 节点选择器
        nodename: 150       # 运行在标签nodename值为150的节点上
      affinity:
        podAntiAffinity:    # pod反亲和性
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:          # 不和app=web-store标签的pod运行在一个节点
              - key: app
                operator: In
                values:
                - web-store
            topologyKey: "kubernetes.io/hostname"       # 节点用这个标签作为判断
        podAffinity:        # pod亲和性
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:     # 和app=store标签的pod运行在一个节点
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: web-app
        image: nginx:1.12-alpine


```

#### 2. 污点与容忍

> NoSchedule: 只会影响新的 pod 调度
> PreferNoSchedule：NoSchedule 的软策略版本，表示尽量不调度到污点节点上去
> NoExecute：影响所有pod调度,已运行在此节点的没有容忍的pod将被驱逐

```bash
# kubectl taint nodes 节点名 key=值:污点类型
kubectl taint nodes 192.168.0.150 dev=192.168.0.150:NoExecute   #给节点192.168.0.150打上NoExecute污点

[root@localhost yaml]# kubectl get po -A -o wide
NAMESPACE     NAME                                 READY   STATUS    RESTARTS   AGE     IP           NODE            NOMINATED NODE   READINESS GATES
default       nginx-alpine-html-764bc6b45c-82vnf   1/1     Running   0          10s     172.17.8.3   192.168.0.151   <none>           <none>
default       nginx-alpine-html-764bc6b45c-g6vmr   1/1     Running   0          10s     172.17.8.4   192.168.0.151   <none>           <none>
default       nginx-alpine-html-764bc6b45c-g7h6q   1/1     Running   0          10s     172.17.8.6   192.168.0.151   <none>           <none>
default       nginx-alpine-html-764bc6b45c-vt6tb   1/1     Running   0          10s     172.17.8.5   192.168.0.151   <none>           <none>
kube-system   coredns-79756b8dff-jpph6             1/1     Running   0          2m24s   172.17.8.2   192.168.0.151   <none>           <none>

# 所有pod都没有运行在150的节点上


```

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-alpine-html
  namespace: default
spec:
  replicas: 4
  selector:
    matchLabels:
      app: nginx-alpine-html
  template:
    metadata:
      labels:
        app: nginx-alpine-html
    spec:
      containers:
      - name: nginx-alpine-html
        image: registry.cn-hangzhou.aliyuncs.com/k8s_xzb/nginx-alpine:curl
        ports:
        - name: http
          containerPort: 80
      tolerations:        # 容忍度
        - key: "dev"     #
          operator: "Equal"
          value: 192.168.0.150
          effect: "NoExecute"
# 对于 tolerations 属性的写法，其中的 key、value、effect 与 Node 的 Taint 设置需保持一致， 还有以下几点说明：
# 如果 operator 的值是 Exists，则 value 属性可省略
# 如果 operator 的值是 Equal，则表示其 key 与 value 之间的关系是 equal(等于)
# 如果不指定 operator 属性，则默认值为 Equal
# 另外，还有两个特殊值：
# 空的 key 如果再配合 Exists 就能匹配所有的 key 与 value，也是是能容忍所有 node 的所有 Taints空的 effect 匹配所有的 effect
# 再次apply,150节点上已经可以运行此pod了
```

> 删除污点
> kubectl taint nodes 192.168.0.150 dev-

#### 3. 资源请求-限制
- cpu
   - 1核cpu=10000m 微核

```yaml
# kubectl explain deployment.spec.template.spec.containers.resources
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: nginx-alpine-html
  namespace: default
spec:
  replicas: 4
  selector: 
    matchLabels:
      app: nginx-alpine-html
  template:
    metadata:
      labels:
        app: nginx-alpine-html
    spec:
      containers:
      - name: nginx-alpine-html
        image: registry.cn-hangzhou.aliyuncs.com/k8s_xzb/nginx-alpine:1.14
        ports:
        - name: http
          containerPort: 80
        resources:
          requests:     #资源请求
            memory: "64Mi"      #内存清楚，容器启动的初始可用数量
            cpu: "250m"     #Cpu请求，容器启动的初始可用数量
          limits:       #资源最大限制的设置
            memory: "128Mi"     #内存限制，单位可以为Mib/Gib，将用于docker run --memory参数
            cpu: "500m"     #Cpu的限制，单位为core数，将用于docker run --cpu-shares参数
```