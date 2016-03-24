#!/bin/bash

argv=$@
slave_hosts_copy=($argv)
length=${#slave_hosts_copy[@]}

if [ $length -eq 1 ] && [ "$1" == "--help" ]; then
 echo "Usage: ./start-framework ARG."
 echo "ARG:"
 echo "   MapReduce"
 echo "   Hbase"
 exit 1
fi

if [ $length -ne 1 ] || [ "$1" != "MapReduce" ] && [ "$1" != "Hbase" ]; then
 echo $1
 echo "Framework: Parameter setting error. See './start-framework.sh --help'."
 exit 1
fi

frameworkName=$1

nohup java -Djava.library.path=/opt/mesos/build/src/.libs/  -classpath third_classes/*:target/cf-tutorial-mesos-docker-1.0-SNAPSHOT-jar-with-dependencies.jar com.codefutures.tutorial.mesos.docker.ExampleFramework $frameworkName > mapreduce.log 2>&1 &
