#!/bin/bash
argv=$@
echo $argv
slave_hosts_copy=($argv)
length=${#slave_hosts_copy[@]}
echo $length

for((i=1;i<$length;i++));
do
        slave_hosts_ip[$[$i-1]]=${slave_hosts_copy[$i]}
done


image_name=$1


length=${#slave_hosts_ip[@]}
for((i=0;i<$length;i++));
	do
		has_ssh="ssh ${slave_hosts_ip[i]}"
		container_id=`$has_ssh docker ps -a -f name=mesos-* | grep $image_name | cut -d ' ' -f 1`
		if [ "$container_id" = ""];then
			continue
		else
			$has_ssh docker rm -f $container_id
		fi
	done
