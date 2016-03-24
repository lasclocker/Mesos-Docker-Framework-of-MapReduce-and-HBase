#!/bin/bash
image_name="hadoop_on_constellation"
mount_dir_on_host="/"
mount_dir_on_container="/opt"
start_which="start-all.sh"
ip1="10.37.0.19"
ip2="10.37.0.29"
ip3="10.37.0.28"
ip4="10.37.0.85"
ip5="10.37.0.89"
ip6="10.37.0.92"
ip7="10.62.43.85"
ip8="10.62.43.82"
#ip9="10.62.43.83"
#ip10="10.62.43.84"

./start-mesos-docker-hadoop.sh $image_name $mount_dir_on_host $mount_dir_on_container $start_which $ip1 $ip2 $ip3 $ip4 $ip5 $ip6 $ip7 $ip8
