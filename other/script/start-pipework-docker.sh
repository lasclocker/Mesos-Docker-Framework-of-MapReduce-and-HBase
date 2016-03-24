#!/bin/bash

pipefile=junli_pipework.sh || { echo "*** error ***"; exit 1; }
while read line;
do
 echo $line
 ssh -n $line ./$pipefile
done < mesos-slaves-ipfile.txt
