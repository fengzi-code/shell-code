[toc]
### 0. 常用命令

```sh
kubectl run nginx-deploy --image=nginx:1.14-alpine --port=80 --replicas=1
kubectl expose deployment/nginx-deploy --name=nginx --port=80 --target-port=80 --protocol=TCP   #把deployment控制器下的pod资源名叫nginx-deploy创建为服务,服务名叫nginx,映射端口80
dig -t A nginx @10.96.0.10 # yum install bund-utils
kubectl scale --replicas=3 deployment/nginx-deploy #扩容缩容
kubectl set image deployment/nginx-deploy nginx-deploy=ikubernetes/myapp:v2  # 更新pod中的镜像,容器名叫nginx-deploy
kubectl rollout undo deployment/nginx-deploy  #回滚镜像到上一个版本
kubectl rollout undo deployment/nginx-deploy --to-revision=2 #回滚镜像到指定版本 如果之前最后版本为5,回滚之后版本记录中版本2消失,变为版本6
kubectl rollout history deployment/nginx-deploy  #查看镜像滚动历史版本
kubectl patch deployment/nginx-deploy -p '{"spec":{"replicas":5}}' # 命令行修改副本数量
iptable -vnL -t nat
kubectl describe nodes my-node    # 查看节点my-node的详细信息
kubectl describe pods/my-pod      # 查看pod my-pod的详细信息
kubectl api-resources  # 查看资源类型
kubectl get deploy # 查看deploy资源下的所有控制器,默认查看default命名空间的
kubectl get pods --show-labels # 显示pod标签
kubectl created ns/prod # 创建生产环境命名空间
kubectl delete namespaces prod # 删除命名空间,空间下的所有资源将被删除,也可以这样写ns/prod
kubectl get ns/prod #查看prod命名空间的源码信息
# 每一个源码一般都由五个字段组成
kubectl created deplyt/nginx-dep --image=nginx:1.14-alpline # 创建一个容器
kubectl exec -it nginx
kubectl created service clusterip nginx-dep --tcp=80:80 # svc关联deplytment的标签,必须一样,要不不能关联
curl nginx-dep.default.svc.cluster.local. #nginx-dep为服务名称,default为命名空间,svc为固定格式,cluster.local为集群默认域名
kubectl explain pods.spce  # 查看pods资源的spce下的字段
kubectl label pods my-pod -n prod app=test # 给pod添加标签app
kubectl label pods my-pod -n prod app- # 给pod删除标签app
kubectl get pods --show-labels -l app=myapp # 显示app标签值为myapp的所有pod
kubectl get pods --show-labels -l "app in (myapp,nginx)" # 显示app标签值为myapp或nginx的所有pod




```
### 1. kubectl annotate  更新资源的注解
### 3. kubectl api-versions     输出服务端API版本
### 4. kubectl apply     声明式资源配置

```sh
# Usage:
  kubectl apply (-f FILENAME | -k DIRECTORY) [options]
```
### 5. kubectl attach     连接到正在运行的容器
### 6. kubectl autoscale     对replication controller进行自动伸缩
### 7. kubectl cluster-info     输出集群信息
### 8. kubectl config     修改kubeconfig配置文件
### 9. kubectl create     创建资源
### 10. kubectl delete     删除资源
### 11. kubectl describe    输出资源的详细信息
```bash
# Usage:
kubectl describe (-f FILENAME | TYPE [NAME_PREFIX | -l label] | TYPE/NAME) [options]
# Examples: 
kubectl describe nodes my-node    # 查看节点my-node的详细信息
kubectl describe pods my-pod      # 查看pod my-pod的详细信息

```
### 12. kubectl edit     编辑服务端的资源。
### 13. kubectl exec     在容器内部执行命令

```sh
# Usage:
kubectl exec POD [-c CONTAINER] -- COMMAND [args...] [options]
# Examples:
kubectl exec my-pod ls                         # 对my-pod执行ls命令
kubectl exec -t -i nginx-78f5d695bd-czm8z bash # 进入pod的shell，并打开伪终端和标准输入
```
### 14. kubectl expose     暴露为新的kubernetes service。
### 15. kubectl get     输出资源
```
# Usage:
  kubectl get
[(-o|--output=)](TYPE[.VERSION][.GROUP] [NAME | -l label] | TYPE[.VERSION][.GROUP]/NAME ...) [flags] 
[options]
# Examples: 
kubectl get services                          # 列出当前NS中所有service资源
kubectl get pods --all-namespaces             # 列出集群所有NS中所有的Pod
kubectl get pods -o wide                      # -o wide也比较常用，可以显示更多资源信息，比如pod的IP等
kubectl get deployment my-dep                 # 可以直接指定资源名查看
kubectl get deployment my-dep --watch         # --watch 参数可以监控资源的状态，在状态变换时输出。在跟踪服务部署情况时很有用
kubectl get pod my-pod -o yaml                # 查看yaml格式的资源配置，这里包括资实际的status，可以用--export排除
kubectl get pod my-pod -l app=nginx           # 查看所有带有标签app: nginx的pod

```
### 16. kubectl label     更新资源的label
### 17. kubectl logs     输出容器日志

```
# Usage:
  kubectl logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER] [options]
# Examples: 
kubectl logs my-pod                              
# 输出一个单容器pod my-pod的日志到标准输出
kubectl logs nginx-78f5d695bd-czm8z -c nginx     
# 输出多容器pod中的某个nginx容器的日志
kubectl logs -l app=nginx                        
# 输出所有包含app-nginx标签的pod日志
kubectl logs -f my-pod                           
# 加上-f参数跟踪日志，类似tail -f
kubectl logs my-pod  -p                          
# 输出该pod的上一个退出的容器实例日志。在pod容器异常退出时很有用
kubectl logs my-pod  --since-time=2018-11-01T15:00:00Z
# 指定时间戳输出日志            
kubectl logs my-pod  --since=1h 
# 指定时间段输出日志，单位s/m/h
```
### 19. kubectl patch     通过控制台输入更新资源中的字段
### 20. kubectl port-forward     将本地端口转发到Pod
### 21. kubectl proxy     启动代理服务器
### 22. kubectl replace     替换资源
### 23. kubectl rolling-update     执行滚动升级
### 24. kubectl run     指定镜像启动容器
### 25. kubectl scale     设置新的副本数
### 27. kubectl version     输出服务端和客户端的版本信息
### 28. kubectl cordon	    设定node不可使用
### 29. kubectl uncordon	    设定node可以使用
### 30. kubectl drain	    设定node进入维护模式






```
# 创建资源
kubectl run nginx --replicas=3 --labels="app=nginx-example" --image=nginx:1.10 --port=80
# kubectl get all
kubectl describe po-name

# 发布服务,target-port容器端口,--port节点端口
kubectl expose deployment nginx --port=88 --type=NodePort --target-port=80 --name=nginx-service


# Usage:
  kubectl logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER] [options]
# Examples: 
kubectl logs my-pod                              
# 输出一个单容器pod my-pod的日志到标准输出
kubectl logs nginx-78f5d695bd-czm8z -c nginx     
# 输出多容器pod中的某个nginx容器的日志
kubectl logs -l app=nginx                        
# 输出所有包含app-nginx标签的pod日志
kubectl logs -f my-pod                           
# 加上-f参数跟踪日志，类似tail -f
kubectl logs my-pod  -p                          
# 输出该pod的上一个退出的容器实例日志。在pod容器异常退出时很有用
kubectl logs my-pod  --since-time=2018-11-01T15:00:00Z
# 指定时间戳输出日志            
kubectl logs my-pod  --since=1h 
# 指定时间段输出日志，单位s/m/h
```