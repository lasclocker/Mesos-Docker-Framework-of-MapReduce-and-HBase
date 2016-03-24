#!/bin/bash

#notice that not using while loop, should use for loop,eg: for ip in total_ip;

constellation="hadoop_on_constellation.tar"
hdfs="hadoop_on_docker.tar"
ssh $ip docker load < $hdfs
ssh $ip docker load < $constellation
