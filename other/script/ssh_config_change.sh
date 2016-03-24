#!/bin/bash
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 scp ssh_config $line:/
 slaveid=`ssh -n $line docker ps -a -q`  #! to use while,must use `ssh -n`,not only using `ssh`
 echo $slaveid
 ssh -n $line docker exec $slaveid cp /opt/ssh_config /etc/ssh/ssh_config #! notice that every `ssh` in `while`, must use `ssh -n`
done
