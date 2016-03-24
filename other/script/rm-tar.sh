#!/bin/bash
constellation="hadoop_on_constellation.tar"
hdfs="hadoop_on_docker.tar"
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 ssh -n $line rm -f $constellation $hdfs  #! notice that every `ssh` in `while`, must use `ssh -n`
 echo "remove done."
done

