#!/bin/bash

mvn install:install-file -DgroupId=org.apache.hadoop -DartifactId=hadoop-common -Dversion=2.5.1 -Dpackaging=jar -Dfile=/opt/mesos-docker-framework/third_classes/hadoop-common-2.5.1.jar
