#!/bin/bash

echo "check docker daemon ..."
docker_daemon_file=start-docker-daemon.sh
cat all-mesos-slaves-hostname.txt |
while read line
do
 echo $line
 pid=`ssh -n $line ps -ef | grep "docker -d --insecure-registry" | awk '{print $2}'`
 if [ "$pid" = "" ];then
  ssh -n $line ./$docker_daemon_file #only repair once
 fi
done
echo "docker daemon ok"

echo "sleep 3"

echo "check mesos slaves service ..."
start_file=start-only-slave-docker-mesos.sh
cat all-mesos-slaves-hostname.txt |
while read line
do
 echo $line
 #notice that, if not mesos-, pid="" in bash,but not "" in shell
 pid=`ssh -n $line ps -ef | grep mesos- | awk '{print $2}'` 
 if [ "$pid" = "" ];then
  ssh -n $line rm /tmp/mesos/meta/slaves/* -rf  #remove the last slave info,then the slave can register master ok.
  ssh -n $line ./$start_file #only repair once
 fi
done
echo "mesos slaves service ok"

echo "sleep 3"
#sleep 3

echo "check pipework network service ..."
pipefile=junli_pipework.sh || { echo "*** error ***"; exit 1; }
while read line;
do
 echo $line
 net=`ssh -n $line ifconfig eth0 | grep 'inet addr'`
 if [ "$net" != "" ];then
 ssh -n $line ./$pipefile
 fi
done < all-mesos-slaves-hostname.txt
echo "pipework network service ok"

echo "sleep 3"
#sleep
