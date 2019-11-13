#!/bin/bash
#请提前安装好jdk
resin_version="4.0.54"
resin_pwd=/opt/soft
resin_CONF=$resin_pwd/resin/conf

mkdir -p  $resin_pwd/resin
mkdir -p $resin_pwd/resin/Source_code
mkdir -p $resin_CONF
wget -c "http://caucho.com/download/resin-$resin_version.tar.gz" -P $resin_pwd/resin/Source_code/
cd $resin_pwd/resin/Source_code/
tar xzvf resin-$resin_version.tar.gz
cd $resin_pwd/resin/Source_code/resin-$resin_version
yum -y install gcc gcc-c++ openssl openssl-devel
./configure --prefix=$resin_pwd/resin
make -j$(cat /proc/cpuinfo | grep "cpu cores" |awk '{print $4}'|head -1) || make MALLOC=libc -j$(cat /proc/cpuinfo | grep "cpu cores" |awk '{print $4}'|head -1)
make install


#----------------------------开机启动------------------------
cat > /etc/init.d/resin << 'EOF'
#!/bin/bash
# chkconfig: 2345 90 10
RESIN_HOME="resin_dir"
CONSOLE="resin_log_dir"
export RESIN_HOME
JAVA="java_bin_dir"
if test -z "$JAVA_EXE"; then
  JAVA_EXE="$JAVA"
fi
if test ! -x "$JAVA_EXE"; then
  if test -n "$JAVA_HOME"; then
    JAVA_EXE="$JAVA_HOME/bin/java"
  fi
fi
if test ! -x "${JAVA_EXE}"; then
  JAVA_EXE=java
fi
RESIN_EXE="${RESIN_HOME}/bin/resinctl"
if ! test -f "${RESIN_EXE}"; then
  RESIN_EXE="${JAVA_EXE} -jar ${RESIN_HOME}/lib/resin.jar"
fi
START_CMD="start-all"
ARGS="$ARGS $RESIN_CONF $RESIN_LOG $RESIN_ROOT $RESIN_LICENSE"
ARGS="$ARGS $JOIN_CLUSTER $SERVER"
if test -r /lib/lsb/init-functions; then
  . /lib/lsb/init-functions
fi
type log_daemon_msg 1> /dev/null 2> /dev/null
if test "$?" != 0; then
  log_daemon_msg () {
      if [ -z "$1" ]; then
          return 1
      fi
      if [ -z "$2" ]; then
          echo -n "$1:"
          return
      fi
      echo -n "$1: $2"
  }
fi  
type log_end_msg 1> /dev/null 2> /dev/null
if test "$?" != 0; then
  log_end_msg () {
      [ -z "$1" ] && return 1
      if [ $1 -eq 0 ]; then
        echo " ."
      else
        echo " failed!"
      fi
    return $1
  }
fi
case "$1" in
  start)
  log_daemon_msg "Starting resin"
  if test -n "$USER"; then
      su $USER -c """$RESIN_EXE $ARGS $START_ARGS $START_CMD""" 1>> $CONSOLE 2>> $CONSOLE
  else
      errors=`$RESIN_EXE $ARGS $START_CMD 2>&1`
      if [ $? != 0 ]; then
    log_daemon_msg $errors
      fi
  fi
  log_end_msg $?
  ;;
  stop)
  log_daemon_msg "Stopping resin"
  if test -n "$USER"; then
      su $USER -c """$RESIN_EXE $ARGS shutdown""" 1>> $CONSOLE 2>> $CONSOLE
  else
      errors=`$RESIN_EXE $ARGS shutdown 2>&1`
      if [ $? != 0 ]; then
    log_daemon_msg $errors
      fi
  fi
  log_end_msg $?
  ;;
  status)
        $RESIN_EXE $ARGS status || exit 3
  ;;
  restart)
  $0 stop
  sleep 1
  $0 start
  ;;
  *)
  echo "Usage: $0 {start|stop|status|restart}"
  exit 1
esac
exit 0

EOF
#----------------------------开机启动------------------------


sed -i "s#resin_dir#$resin_pwd/resin#" /etc/init.d/resin
sed -i "s#resin_log_dir#$resin_pwd/resin/log/console.log#" /etc/init.d/resin
java_bin=`echo $JAVA_HOME`
sed -i "s#java_bin_dir#$java_bin/bin/java#" /etc/init.d/resin
chmod u+x /etc/init.d/resin
chkconfig --add resin
