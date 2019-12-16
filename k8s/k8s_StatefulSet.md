### 1. statefulset

```shell
StatefulSet
1. 稳定且唯一的网络标识符;
2. 稳定且持久的存储;
3. 有序平滑的部署和扩展;
4. 有序平滑的终止和删除;
5. 有序的滚动更新;

三个组件 headless(无头服务,不能定义集权IP),statefulset,volumeclaimtemplate

nslookup pod_name.service_name.ns_name.svc.cluster.local
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-alpine-service
  namespace: default
spec:
  selector:
    app: nginx-alpine-html
    release: canary
  ports:
  - name: http
    port: 80
    targetPort: 80
  clusterIP: None       # 不能分配集权IP,headless(无头服务,不能定义集权IP)
---
apiVersion: apps/v1
kind: StatefulSet       # 类型为statefulset
metadata: 
  name: nginx-alpine-html
spec:
  serviceName: nginx-alpine-html
  replicas: 3
  selector: 
    matchLabels:
      app: nginx-alpine-html
      release: canary
  template:
    metadata:
      labels:
        app: nginx-alpine-html
        release: canary
    spec:
      containers:
      - name: nginx-alpine-html
        image: registry.cn-hangzhou.aliyuncs.com/k8s_xzb/nginx-alpine:1.14
        imagePullPolicy: IfNotPresent
        ports:
        - name: httpd
          containerPort: 80
        volumeMounts:
        - name: nginx-data  # 容器挂载名字和volumes中的name名字对应
          mountPath: /data/web/html/  # 容器中挂载位置
  volumeClaimTemplates:      # volumeclaimtemplate pv模板
  - metadata:
      name: nginx-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 2Gi
```

### 2. 分区更新

```bash
kubectl patch sts nginx-alpine-html -p '{"spec:"{"updateStrategy":{"rollingUpdate":{"partition":4}}}}'  # 容器标识符大于等于4的将更新

kubectl set image sts/nginx-alpine-html nginx-alpine-html=registry.cn-hangzhou.aliyuncs.com/k8s_xzb/nginx-alpine:1.15  # 大于4的将更新为1.15

kubectl patch sts nginx-alpine-html -p '{"spec:"{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'  # 全部更新?
```