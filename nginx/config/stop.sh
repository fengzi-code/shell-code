#!/bin/bash

pro_num=`ps -ef | grep eagle-wxsimulator | grep -v grep | awk '{print $2}'`

echo "------process num ="$pro_num

kill -9 $pro_num
echo "------killed eagle-task process"
