#!/bin/bash
i=0
cat mesos-slaves-ipfile.txt |
while read line
do
 echo $line
 slaveid=`ssh -n $line service docker stop`  #! to use while,must use `ssh -n`,not only using `ssh`
 let i++
 echo $i
done

