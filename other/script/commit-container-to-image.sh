#!/bin/bash

image_name="10.37.0.72:5000/emc/mapreduce_on_docker"
echo "commit image is $image_name ???"
echo "(yes/no)?"
read line
if [ $line != "yes" ];then
 exit 1
fi

cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 slaveid=`ssh -n $line docker ps -f name=mesos-* | grep $image_name | cut -d ' ' -f 1`
 echo $slaveid
 ssh -n $line docker commit $slaveid $image_name #! notice that every `ssh` in `while`, must use `ssh -n`
done

