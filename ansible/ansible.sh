yum -y install epel-release gcc openssl openssl-devel sshpass
yum install python-pip
pip install --upgrade setuptools
#---------------------------------------------------------------
wget -c http://releases.ansible.com/ansible/ansible-2.7.5.tar.gz
tar zxvf ansible-2.7.5.tar.gz
cd ansible-2.7.5
python setup.py install
mkdir -p /etc/ansible
cp /opt/ansible-2.7.5/examples/ansible.cfg /etc/ansible/
cp /opt/ansible-2.7.5/examples/hosts /etc/ansible/
#---------------------------------------------------------------
yum info ansible
yum install ansible
#---------------------------------------------------------------
pip install ansible
#---------------------------------------------------------------
/etc/ansible/ansible.cfg 主配置文件
/etc/ansible/hosts 主机清单
/etc/ansible/roles/ 存放角色的目录
/usr/bin/ansible 主程序
/usr/bin/ansible-doc 查看模块帮助文档,模块功能查看
/usr/bin/ansible-galaxy 下载上传优秀代码或角色的平台https://galaxy.ansible.com
#ansible-galaxy install geerlingguy.nginx
/usr/bin/ansible-playbook 剧本工具 自动化任务
/usr/bin/ansible-vault 文件加密工具
/usr/bin/ansible-console 控制台交互
#----------------------------------------------------------------
ansible 192.168.1.30 -m shell -a 'ls -lah /' -v 
 -m 模块名 -a 参数,建议用单引号 -v详细信息 -k 提示输入ssh密码 -C 检查并不执行 -T 超时时间 -u 远程执行的用户
#----------------------------------------------------------------
#ansible配置文件
#inventory      = /etc/ansible/hosts 主机列表配置文件
#library        = /usr/share/my_modules/ 库文件存放目录
#remote_tmp     = ~/.ansible/tmp 临时命令文件存放在远程主机的目录
#local_tmp      = ~/.ansible/tmp 临时命令文件存放在本机的目录
#forks          = 5 默认并发数
#sudo_user      = root 默认远程sudo用户
#ask_sudo_pass = True 每次执行命令是否询问ssh密码
#ask_pass      = True
#remote_port    = 22
#host_key_checking = False 检查对应主机的host_key,建议取消
#log_path = /var/log/ansible.log 日志文件目录
#----------------------------------------------------------------
#ansible-playbook -C hello.yml k/v键值对形式 一个name只能包含一个task任务
#核心元素
#hosts 执行的远程主机列表
#tasks 任务集
#varniables 内置变量或自定义变量在playbook中调用
#templates 模板
#handlers 和notity 结合使用,由特定条件触发的操作,满足执行否则不执行
#变量的使用 setup模块里的所有变量可以直接使用,/etc/ansible/hosts变量可以直接使用,命令中直接使用变量ansible-playbook -e 'yum_name=nginx' hello.yml
---
#test
- host: websrvs
  remoste_user: root
  vars:    #playbook中直接指定变量
    - yum_name: nginx
    - yum_name2: httpd

  tasks:    #任务集
    - name: hello    #任务名称1
      command: ls -lah /opt    #模块名:命令参数
      tags: showopt    #可以单独执行此剧本里的标签任务ansible -t showopt hello.yml
    - name: create new file    #任务名称2
      file: name=/opt/newfile state=touch    #模块名:命令参数
      ignore_errors: True    #忽略错误,继续执行
    - name: install package
      yum: name={{ yum_name }}    #变量,ansible-playbook -e 'yum_name=nginx' hello.yml
    - name: copy file
      copy: src=/opt/nginx.conf dest=/etc/nginx/ backup=yes
      notify: restart service    #当此任务发生了变化,通知handlers:restart service执行,notify可以触发多个handlers
    - name: start service
      service: name=nginx state=started enabled=yes

  handlers:
    - name: restart service
      service: name=nginx state=restarted

#----------------------------------------------------------------
#ansible-console
root@all (3)[f:5]$  root 用户 all主机清单 3代表all里面有几个主机 f:5 5个并发连接
cd websrvs 切换到web组 fork 10 更改10并发 command hostname command模块名 hostname 命令

#----------------------------------------------------------------
#变量文件专门用于存放变量,调用方法
- hosts: websrvs
  remoste_user: root
  vars_files:
    - vars.yml
  tasks:
    - name: instll pak
      yum: name={{ var1 }}
#
#变量文件 vars.yml
var1: httpd
var2: ningx

#----------------------------------------------------------------
#模板文件 templates
#nginx.conf.j2 文件内空
#worker_processes {{ ansible_processor_vcpus*2 }};
# {% for port in ports %} #for循环使用 ports 需要在使用的剧本文件里定义好
# listen {{ port }}
# {% endfor %}  #结束句
- host: websrvs
  remoste_user: root
  tasks:    #任务集
    - name: install package    #任务名称
      yum: name=nginx
    - name: copy templates for 7
      templates: src=nginx.conf7.j2 dest=/etc/nginx/nginx.conf
      when: ansible_distribution_major_version == "7"  # 当版本为7时执行此操作
    - name: copy templates for 6
      templates: src=nginx.conf6.j2 dest=/etc/nginx/nginx.conf
      when: ansible_distribution_major_version == "7"
    - name: start service
      service: name=nginx state=started enabled=yes
    - name: create some files
      file: name=/opt/{{ item }} state=touch  # 创建多个文件以列表中为名
      with_items:
        - file1
        - file2
        - file3
    - name: create some users
      user: name={{ item.name }} group={{ item.group }}   #迭代器变量使用
      with_items:
        -{ name: "user1", group: "g1" }
        -{ name: "user2", group: "g2" }
        -{ name: "user3", group: "g3" }

#----------------------------------------------------------------
#角色 模块化 | roles文件夹下 每个角色一个文件夹,变量 任务 模板 handel文件与角色目录同级
# /roles/nginx
#        files: 存放模块调用的文件
#        templates: 存放templates模块需要的模板文件
#        tasks: 任务定义,至少有一个main.yml 其它文件用include导入
#        handlers: 至少有一个main.yml 其它文件用include导入
#        vars: 定义变量,至少有一个main.yml 其它文件用include导入
#        meta: 定义特殊设定和依赖关系,至少有一个main.yml 其它文件用include导入
#        default:定义默认变量,至少有一个main.yml
#创建一个nginx角色
#1. 创建nginx用户和组 2. 安装nginx 3 修改配置文件 4 启动nginx
#task文件格式,每个任务一个文件,模块化.
#vars/main.yml 变量文件
username: nginx
groupname: nginx

#tasks/group.yml
-name: create group
  group: name=nginx
#tasks/user.yml
-name: create user
  user: name=nginx system=yes shell=/sbin/nologin group=nginx
#tasks/yum.yml
-name: install package
  yum: name=nginx
#tasks/start.yml
-name: start service
  service: name=nginx enabled=yes state=started
#tasks/restart.yml
-name: restart service
  service: name=nginx state=restarted

#templates文件格式,放在templates文件夹下名为nginx.conf.j2,修改配置文件如下定义
worker_processes {{ ansible_processor_vcpus*2 }};


#tasks/templ.yml
-name: copy conf
  service: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf
  notify: restart service  #触发handlers

#handlers/main.yml
-name: restart service
  service: name=nginx state=restarted

#tasks/copy.yml  mzj.com.conf放在files/
-name: copy config
  copy: src=mzj.com.conf dest=/etc/nginx/conf.d/ backup=yes

#tasks/mail.yml 定义剧本执行顺序
- include: group.yml
- include: user.yml
- include: yum.yml
- include: templ.yml
- include: start.yml
#- include: roles/httpd/tasks/copyfile.yml #调用其它角色的任务,文件路径记得是绝对路径

#在roles文件夹同级创建nginx_role.yml
- hosts: websrvs
  remoste_user: root
  roles:
    - nginx
#   - { role: httpd, tags: ['web','httpd'],when: ansible_distribution_major_version == "7" } 加标签,条件
#   - role: httpd 调用多个角色可添加一行

# ansible -t httpd nginx_role.yml 
# 
# 

