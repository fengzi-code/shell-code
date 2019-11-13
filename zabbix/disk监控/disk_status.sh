#/bin/sh
#zabbix 监控硬盘IO读写,需要iostat支持
Device=$1
DISK=$2
case $DISK in
         rrqm)
            iostat -dxkt |grep "\b$Device\b"|tail -1|awk '{print $2}'
            ;;
         wrqm)
            iostat -dxkt |grep "\b$Device\b"|tail -1|awk '{print $3}'
            ;;
          rps)
            iostat -dxkt |grep "\b$Device\b"|tail -1|awk '{print $4}'
            ;;
          wps)
            iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $5}'
            ;;
        rKBps)
            iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $6}'
            ;;
        wKBps)
            iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $7}'
            ;;
        avgrq-sz)
            iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $8}'
            ;;
        avgqu-sz)
            iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $9}'
            ;;
        await)
            iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $10}'
            ;;
        svctm)
            iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $11}'
            ;;
         util)
            iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $12}'
            ;;
esac

