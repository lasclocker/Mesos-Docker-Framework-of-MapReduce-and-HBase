#!/bin/bash

start_file=start-slave-docker-mesos.sh
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 ssh -n $line ./$start_file  #! to use while,must use `ssh -n`,not only using `ssh`
 echo "sleep 1"
 sleep 1
done

