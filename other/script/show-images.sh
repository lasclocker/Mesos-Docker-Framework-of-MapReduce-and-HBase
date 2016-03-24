#!/bin/bash
i=0
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 slaveid=`ssh -n $line docker images -q`  #! to use while,must use `ssh -n`,not only using `ssh`
 echo $slaveid
 let i++
 echo $i
done

