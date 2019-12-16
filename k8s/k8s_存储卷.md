
#### 1.临时存储 emptyDir


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
---
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: nginx-alpine-html
spec:
  replicas: 4
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
        - name: http
          containerPort: 80
        volumeMounts:
        - name: html  # 容器挂载名字和volumes中的name名字对应
          mountPath: /data/web/html/  # 容器中挂载位置
      volumes:      # 挂载需求,需和containers对齐
      - name: html  # 挂载名字
        emptyDir: {}    #挂载类型,此类型pod断开后挂载的文件会永久删除,一般作临时用



```

#### 2.宿主机存储 HostPath


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
---
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: nginx-alpine-html
spec:
  replicas: 4
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
        - name: html  # 容器挂载名字和volumes中的name名字对应
          mountPath: /data/web/html/  # 容器中挂载位置
      volumes:      # 挂载需求,需和containers对齐
      - name: html  # 挂载名字
        hostPath:    #挂载类型,宿主机挂载
          path: /data/pod/volumes   #宿主机目录
          type: DirectoryOrCreate   # 挂载类型,目录或者创建目录
```

#### 3.持久存储-NFS 共享存储

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
---
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: nginx-alpine-html
spec:
  replicas: 4
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
        - name: html  # 容器挂载名字和volumes中的name名字对应
          mountPath: /data/web/html/  # 容器中挂载位置
        env:
        - name: PROVISIONER_NAME
          value: fuseim.pri/ifs
        - name: NFS_SERVER
          value: harbor-1 #nfs 服务器地址
        - name: NFS_PATH
          value: /data/share/v1 #nfs 服务器挂载路径
      volumes:      # 挂载需求,需和containers对齐
      - name: html  # 挂载名字
        nfs:    #挂载类型,宿主机挂载
          server: harbor-1  # 服务器地址,需在node中做好hosts绑定
          path: /data/share/v1   #服务器挂载目录
```


#### 3.静态PV-NFS 共享存储

3.1 定义PV资源
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
  labels:
    name: pv001
    app: test-pv1
spec:
  nfs:
    path: /data/share/v1   # nfs服务器挂载目录
    server: harbor-1  # nfs服务器地址,需在node中做好hosts绑定
  accessModes: ["ReadWriteOnce","ReadOnlyMany","ReadWriteMany"]   # RWO - ReadWriteOnce  ROX - ReadOnlyMany  RWX - ReadWriteMany
  capacity:
    storage: 2Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv002
  labels:
    name: pv002
    app: test-pv2
spec:
  nfs:
    path: /data/share/v2   # nfs服务器挂载目录
    server: harbor-1  # nfs服务器地址,需在node中做好hosts绑定
  accessModes: ["ReadWriteOnce","ReadOnlyMany","ReadWriteMany"] 
  capacity:
    storage: 5Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv003
  labels:
    name: pv003
    app: test-pv3
spec:
  nfs:
    path: /data/share/v3   # nfs服务器挂载目录
    server: harbor-1  # nfs服务器地址,需在node中做好hosts绑定
  accessModes: ["ReadWriteOnce","ReadOnlyMany","ReadWriteMany"]  
  capacity:
    storage: 20Gi

```

3.2 定义PVC资源

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
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: h5-nginx-pvc
  namespace: default
spec:
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 6Gi
---
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: nginx-alpine-html
spec:
  replicas: 4
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
        - name: html  # 容器挂载名字和volumes中的name名字对应
          mountPath: /data/web/html/  # 容器中挂载位置
      volumes:      # 挂载需求,需和containers对齐
      - name: html  # 挂载名字
        persistentVolumeClaim:
          claimName: h5-nginx-pvc   # 和上面的pvc对应

```