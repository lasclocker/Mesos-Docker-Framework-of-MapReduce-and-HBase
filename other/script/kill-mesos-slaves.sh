#!/bin/bash

cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 pid=`ssh -n $line ps -ef | grep mesos- | awk '{print $2}'`
 echo $pid
 ssh -n $line kill -9 $pid  #! to use while,must use `ssh -n`,not only using `ssh`
done

