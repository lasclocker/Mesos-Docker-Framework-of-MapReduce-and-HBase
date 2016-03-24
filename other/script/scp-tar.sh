#!/bin/bash
constellation="hadoop_on_constellation.tar"
hdfs="hadoop_on_docker.tar"
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 scp $hdfs $constellation $line:
done

