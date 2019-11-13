setenforce 0  # 临时关闭，重启后失效
systemctl stop firewalld.service  # 临时关闭，重启后失效

# 修改字符集，否则可能报 input/output error的问题，因为日志里打印了中文
localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
echo 'LANG="zh_CN.UTF-8"' > /etc/locale.conf
#准备 Python3 和 Python 虚拟环境
#1.1 安装依赖包
yum -y install wget sqlite-devel xz gcc automake zlib-devel openssl-devel epel-release git
#1.2 编译安装python
wget https://www.python.org/ftp/python/3.6.1/Python-3.6.1.tar.xz
tar xvf Python-3.6.1.tar.xz  && cd Python-3.6.1
./configure && make && make install
#1.3 建立 Python 虚拟环境
cd /opt
python3 -m venv py3
source /opt/py3/bin/activate
# 看到下面的提示符代表成功，以后运行 Jumpserver 都要先运行以上 source 命令，以下所有命令均在该虚拟环境中运行
#(py3) [root@localhost py3]
#1.4 自动载入 Python 虚拟环境配置
#此项仅为懒癌晚期的人员使用，防止运行 Jumpserver 时忘记载入 Python 虚拟环境导致程序无法运行。使用autoenv
cd /opt
git clone git://github.com/kennethreitz/autoenv.git
echo 'source /opt/autoenv/activate.sh' >> ~/.bashrc
source ~/.bashrc
#二. 安装 Jumpserver
#2.1 下载或 Clone 项目\
cd /opt/
git clone https://github.com/jumpserver/jumpserver.git && cd jumpserver && git checkout master
echo "source /opt/py3/bin/activate" > /opt/jumpserver/.env  # 进入 jumpserver 目录时将自动载入 python 虚拟环境

# 首次进入 jumpserver 文件夹会有提示，按 y 即可
# Are you sure you want to allow this? (y/N) y
# 2.2 安装依赖 RPM 包
cd /opt/jumpserver/requirements
yum -y install $(cat rpm_requirements.txt)  # 如果没有任何报错请继续
#2.3 安装 Python 库依赖
pip install -r requirements.txt  # 不要指定-i参数，因为镜像上可能没有最新的包，如果没有任何报错请继续

#2.4 安装 Redis, Jumpserver 使用 Redis 做 cache 和 celery broke
yum -y install redis
systemctl enable redis
systemctl start redis
#2.5 安装 MySQL
yum -y install mariadb mariadb-devel mariadb-server # centos7下安装的是mariadb
systemctl enable mariadb
systemctl start mariadb
#2.6 创建数据库 Jumpserver 并授权
mysql
create database jumpserver default charset 'utf8';
grant all on jumpserver.* to 'jumpserver'@'127.0.0.1' identified by 'weakPassword';
flush privileges;
#2.7 修改 Jumpserver 配置文件
cd /opt/jumpserver
cp config_example.py config.py
vi config.py
#2.8 生成数据库表结构和初始化数据
cd /opt/jumpserver/utils
bash make_migrations.sh
