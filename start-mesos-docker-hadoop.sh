#!/bin/bash

argv=$@
echo $argv
slave_hosts_copy=($argv)
length=${#slave_hosts_copy[@]}
echo $length


empty=" "

#must not forget masknet num, eg:255.255.255.192 -> /26, 255.255.255.224 -> /27
declare -A host_container_ip_dict=(["Node-0"]="10.37.0.40/26" 
                                   ["Node-1"]="10.37.0.41/26"
                                   ["Node-2"]="10.37.0.42/26"
                                   ["Node-3"]="10.37.0.75/26"
                                   ["Node-4"]="10.37.0.76/26"
                                   ["Node-5"]="10.37.0.77/26"
                                   ["cc01"]="10.62.43.90/27"
                                   ["cc02"]="10.62.43.91/27"
                                   ["cc03"]="10.62.43.92/27"
                                   ["cc04"]="10.62.43.93/27")


image_name=$1
mount_dir_on_host=$2
mount_dir_on_container=$3

for((i=3;i<$length;i++));
do
        slave_hosts_ip[$[$i-3]]=${slave_hosts_copy[$i]}
done


#配置pipework, 生成hosts文件.
num=0
length=${#slave_hosts_ip[@]}
for((i=0;i<$length;i++));
        do
                has_ssh="ssh ${slave_hosts_ip[i]}"
                container_id=`$has_ssh docker ps -f name=mesos-* | grep $image_name | cut -d ' ' -f 1`
		if [ "$container_id" = "" ]; then
			continue
		else
			echo "pipework ${slave_hosts_ip[i]}"
			container_ip=${host_container_ip_dict["${slave_hosts_ip[i]}"]} ###new add
			active_slave_ip[$num]=${slave_hosts_ip[i]}
			all_container_id[$num]=$container_id
			gateway=`$has_ssh ip route | head -1 | cut -d ' ' -f 3` ###new add
			$has_ssh pipework br0 $container_id $container_ip@$gateway  ###new add
			$has_ssh ifconfig br0 promisc  ###new add
			hname=`$has_ssh docker exec $container_id cat /etc/hostname` ###new add
			container_ip_tmp=`echo $container_ip | cut -d / -f 1`
	                hnameip=$container_ip_tmp$empty$hname ###new add
			$has_ssh docker exec $container_id echo $hnameip >> hosts ###new add
			let num++
		fi
		
        done

#生成slaves文件
i=0
allSlaveHostNames=""
line_break="\n"
while read line
do
    slaveHostName=`echo $line | cut -d ' ' -f 1`   # obtain ip
    if [ $slaveHostName != "master" ];then
        allSlaveHostNames=$allSlaveHostNames$slaveHostName$line_break
    fi
    let i+=1
done < hosts
echo -e $allSlaveHostNames > slaves
echo "/etc/hosts :"
cat hosts
echo "hadoop/etc/hadoop/slaves :"
cat slaves
#配置Hadoop每个节点的网络.
echo "configure Hadoop network ..."
length=${#all_container_id[@]}
for((i=0;i<$length;i++));
        do
		scp hosts ${active_slave_ip[$i]}:$mount_dir_on_host
		scp slaves ${active_slave_ip[$i]}:$mount_dir_on_host
		has_ssh="ssh ${active_slave_ip[i]}"
		$has_ssh docker exec ${all_container_id[$i]} cp $mount_dir_on_container/hosts /etc/hosts
		$has_ssh docker exec ${all_container_id[$i]} cp $mount_dir_on_container/slaves /home/hadoop251/hadoop/etc/hadoop/slaves
		$has_ssh rm $mount_dir_on_host/hosts $mount_dir_on_host/slaves
        done
rm hosts slaves -rf
