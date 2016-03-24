#!/bin/bash

for line in `cat mesos-slaves-ipfile.txt`
do
        echo $line
        ssh $line docker pull fedora/apache
done

