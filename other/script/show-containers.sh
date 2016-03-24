#!/bin/bash
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 slaveid=`ssh -n $line docker ps -a`  #! to use while,must use `ssh -n`,not only using `ssh`
 echo $slaveid
done
