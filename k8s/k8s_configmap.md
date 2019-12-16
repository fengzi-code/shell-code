### 1. 创建

1.1 命令行创建1

```bash
# kubectl create configmap 名字 --from-literal=key=v --from-literal=key=v
# kubectl edit cm 名字
kubectl create configmap nginx-config --from-literal=nginx_port=80 --from-literal=server_name=www.xiazaibei.com
```

```yaml
# 容器yaml样例,此变量只在pod启动时加载     
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
        ports:
        - name: httpd
          containerPort: 80
        env:
        - name: nginx_port      # 容器里的变量名
          valueFrom:
            configMapKeyRef:
              name: nginx-config
              key: nginx_port       # configmap里的变量名,将赋值给容器里的变量
        - name: server_name      # 容器里的变量名
          valueFrom:
            configMapKeyRef:
              name: nginx-config
              key: server_name       # configmap里的变量名,将赋值给容器里的变量
```

2.2  命令行创建2

```bash
cat nginx-conf.conf

    server{
        listen 80;
        root /data/web/html/;
        location / {
            proxy_pass http://127.0.0.1:1234;
        }
    }
# kubectl create configmap 名字 --from-file=文件名
kubectl create configmap nginx-conf --from-file=./nginx-conf.conf

```

```yaml
# 容器yaml样例,文件实时生效    
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
        ports:
        - name: httpd
          containerPort: 80
        volumeMounts:       # configmap是一个特殊的存储卷,所以需要在容器内挂载
        - name: nginx-conf
          mountPath: /etc/nginx/conf.d/
          readOnly: true    # 不允许从容器内部修改
      volumes:
      - name: nginx-conf
        configMap:
          name: nginx-conf      # configmap名字

```

3. secret 创建

```bash
kubectl create secret generic nginx-port --from-literal=nginx_port=80 

kubectl describe secret nginx-port
kubectl get secret nginx-port -o yaml
```


4. 挂载文件

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: settings
  namespace: default
data:
  fluentd.tpl: |
    {{range .configList}}
      <source>
        @type tail
        tag docker.{{ $.containerId }}.{{ .Name }}
        path {{ .HostDir }}/{{ .File }}

        <parse>
        {{if .Stdout}}
        @type json
        {{else}}
        @type {{ .Format }}
        {{end}}
        {{ $time_key := "" }}
        {{if .FormatConfig}}
        {{range $key, $value := .FormatConfig}}
        {{ $key }} {{ $value }}
        {{end}}
        {{end}}
        {{ if .EstimateTime }}
        estimate_current_event true
        {{end}}
        keep_time_key true
        </parse>

        read_from_head true
        pos_file /pilot/pos/{{ $.containerId }}.{{ .Name }}.pos
      </source>

      <filter docker.{{ $.containerId }}.{{ .Name }}>
        @type record_transformer
        enable_ruby true
        <record>
          host "#{Socket.gethostname}"
          {{range $key, $value := .Tags}}
          {{ $key }} {{ $value }}
          {{end}}

          {{if eq $.output "elasticsearch"}}
          _target {{if .Target}}{{.Target}}-${time.strftime('%Y.%m.%d')}{{else}}{{ .Name }}-${time.strftime('%Y.%m.%d')}{{end}}
          {{else}}
          _target {{if .Target}}{{.Target}}{{else}}{{ .Name }}{{end}}
          {{end}}

          {{range $key, $value := $.container}}
          {{ $key }} {{ $value }}
          {{end}}
          new_log ${record["log"].scan(/^$/).last}
        </record>
      </filter>
    {{end}}
```


```yaml
          ports:
            - containerPort: 80
          volumeMounts:
          - name: settings
            mountPath: /pilot/fluentd.tpl
            subPath: fluentd.tpl

      volumes:
        - name: settings
          configMap:
            name: fluentd.tpl
```