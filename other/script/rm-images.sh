#!/bin/bash
slaveimage="10.37.0.72:5000/emc/mapreduce_on_docker_v1"
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
# slaveimage=`ssh -n $line docker images -q`  #! to use while,must use `ssh -n`,not only using `ssh`
# echo $slaveimage
 #if [ ! -z "$slaveimage" ]; then #slaveimage != empty
  ssh -n $line docker rmi -f $slaveimage #! notice that every `ssh` in `while`, must use `ssh -n`
  echo "remove done."
# fi
done
