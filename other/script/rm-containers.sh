#!/bin/bash
cat mesos-slaves-ipfile.txt |
while read line
do 
 echo $line
 slaveid=`ssh -n $line docker ps -a -q`  #! to use while,must use `ssh -n`,not only using `ssh`
 echo $slaveid
 if [ ! -z "$slaveid" ]; then
  ssh -n $line docker rm -f $slaveid #! notice that every `ssh` in `while`, must use `ssh -n`
  echo "remove done."
 fi
done
