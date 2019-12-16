## 11. dashboard安装(安装到node)

1. 创建应用


``` bash
# 注意修改镜像地址
# https://github.com/kubernetes/dashboard
# https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
# v2 版本
# https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta6/aio/deploy/recommended.yaml
```
```yaml
# 记得修改镜像地址和打开nodeprot
# ------------------- Dashboard Secret ------------------- #

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kube-system
type: Opaque

---
# ------------------- Dashboard Service Account ------------------- #

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard    # 创建sa用户给pod用
  namespace: kube-system        # 属于kube-system命名空间

---
# ------------------- Dashboard Role & Role Binding ------------------- #

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
rules:
  # 对各种资源授与权限.
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create"]
  # Allow Dashboard to create 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create"]
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
  verbs: ["get", "update", "delete"]
  # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["kubernetes-dashboard-settings"]
  verbs: ["get", "update"]
  # Allow Dashboard to get metrics from heapster.
- apiGroups: [""]
  resources: ["services"]
  resourceNames: ["heapster"]
  verbs: ["proxy"]
- apiGroups: [""]
  resources: ["services/proxy"]
  resourceNames: ["heapster", "http:heapster:", "https:heapster:"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubernetes-dashboard-minimal      
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard-minimal          # 与上面的role绑定
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard        # 绑定上面的sa帐户,使其拥有权限
  namespace: kube-system

---
# ------------------- Dashboard Deployment ------------------- #

kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
      - name: kubernetes-dashboard
        image: registry.cn-hangzhou.aliyuncs.com/k8s_xzb/dashboard:v1.10.1
        ports:
        - containerPort: 8443
          protocol: TCP
        args:
          - --auto-generate-certificates
          # Uncomment the following line to manually specify Kubernetes API server Host
          # If not specified, Dashboard will attempt to auto discover the API server and connect
          # to it. Uncomment only if the default does not work.
          # - --apiserver-host=http://my-address:port
        volumeMounts:
        - name: kubernetes-dashboard-certs
          mountPath: /certs
          # Create on-disk volume to store exec logs
        - mountPath: /tmp
          name: tmp-volume
        livenessProbe:
          httpGet:
            scheme: HTTPS
            path: /
            port: 8443
          initialDelaySeconds: 30
          timeoutSeconds: 30
      volumes:
      - name: kubernetes-dashboard-certs
        secret:
          secretName: kubernetes-dashboard-certs        # 与secret绑定
      - name: tmp-volume
        emptyDir: {}
      serviceAccountName: kubernetes-dashboard      # 让pod与sa帐户绑定
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule

---
# ------------------- Dashboard Service ------------------- #

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001
  selector:
    k8s-app: kubernetes-dashboard
```

```bash
# 创建应用
kubectl apply -f kubernetes-dashboard.yaml
# 查看 是否创建正常
kubectl get svc,no,pod,rc -n kube-system -o wide
# 如有问题删除创建的信息重来
kubectl delete -f kubernetes-dashboard.yaml
```

2. 解决chrome等浏览器拒绝访问

```bash
#生成证书 替换官方证书,解决chrome等浏览器拒绝访问
cd /opt/kubernetes/cfg
openssl genrsa -out dashboard.key 2048 
openssl req -new -out dashboard.csr -key dashboard.key -subj '/CN=192.168.0.151'
openssl x509 -req  -days 3650 -in dashboard.csr -signkey dashboard.key -out dashboard.crt 
#删除原有的证书secret
kubectl delete secret kubernetes-dashboard-certs -n kube-system
#创建新的证书secret
kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kube-system
# 删除不需要的文件
rm -f dashboard.*
#查看pod
kubectl get pod -n kube-system
#重启pod
kubectl delete pod kubernetes-dashboard-66746d749c-pnmrs -n kube-system

```

3. 令牌访问

```bash
# 创建ServiceAccount
kubectl create serviceaccount dashboard-admin -n kube-system
# 绑定相关role
kubectl create clusterrolebinding dashboard-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 获取ServiceAccount使用的Secret
kubectl describe sa dashboard-admin -n kube-system
# 获取token
kubectl describe secret dashboard-admin-token-mlbnl  -n kube-system
# 使用获取到的token进行登陆
```

4. kubeconfig访问

此认证方式相对麻烦，此处才用RBAC中的特性set-credentials
如果不适用上述方式，则需要使用k8s的ca对新用户进行签证，Secret中使用签发的证书
此处才用上方部分权限中的token
为了省事，此处直接才用上方的SeriveAccount
如不想使用，请重复上方 创建ServiceAccount 绑定相关role 获取ServiceAccount使用的Secret

```bash
# 取出tocken dashboard-admin-token-mlbnl 为ServiceAccount使用的Secret
DASH_TOCKEN=$(kubectl get secret -n kube-system dashboard-admin-token-mlbnl -o jsonpath={.data.token}|base64 -d)
# 增加服务器地址
kubectl config set-cluster kubernetes --server=192.168.0.130:6443 --kubeconfig=/opt/kubernetes/cfg/dashbord-admin.conf
# 导入tocken
kubectl config set-credentials dashboard-admin --token=$DASH_TOCKEN --kubeconfig=/opt/kubernetes/cfg/dashbord-admin.conf
# 设置上下文
kubectl config set-context dashboard-admin@kubernetes --cluster=kubernetes --user=dashboard-admin --kubeconfig=/opt/kubernetes/cfg/dashbord-admin.conf
# 导入上下文
kubectl config use-context dashboard-admin@kubernetes --kubeconfig=/opt/kubernetes/cfg/dashbord-admin.conf111
```


<!-- eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJkYXNoYm9hcmQtYWRtaW4tdG9rZW4tODJoNXAiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGFzaGJvYXJkLWFkbWluIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiZjNjZWM5ZTUtZmM0Ny00MTliLTk3YWQtMTMzNWJhZjhiMzE1Iiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmUtc3lzdGVtOmRhc2hib2FyZC1hZG1pbiJ9.lzHrYtPakKPYaK0h_xwESKgDqriUA5zQIG7edvfTLj73eoW9NXRGDF2abIELU5Kn2-G8CPp47qad93DltHCreYNq3yEVZNpt_xmo5DO7VNyJkGfDTERK5ask71uW9ZSfqMOxvLzu_nGYF3lsEzH-bW4PwTeAG7sQV2rdcg3rmhDEEvHXbvM18vHJulBt1sFLojP18GdLy5znCpvdcOZwiaYXiQBznWfxUp-DFNZJdAlNknhyblxmtS8djSmcTuQoVEGd6hzDiCw9bBdzfeiCLmeIVtdAN0IuNlB3jgCwE0H8Qka00XiQxAbHmEE_NyJQD5pWUllgJdE5B9rMUtKT1Q -->