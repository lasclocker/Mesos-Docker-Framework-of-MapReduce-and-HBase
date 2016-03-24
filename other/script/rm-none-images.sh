#!/bin/bash
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 ssh -n $line docker rmi $(ssh -n $line docker images | grep "<none>" | awk '{print $3}')
 echo "remove done."
done

