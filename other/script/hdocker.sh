#!/bin/bash

#docker network configure
function networkConfigure() {
	local slaves_hostIP=(${!1})
	if [ -f "/etc/hdocker_networkConfigure" ]; then
		rm /etc/hdocker_networkConfigure
	fi
	echo ${slaves_hostIP[@]} >> /etc/hdocker_networkConfigure
	length=${#slaves_hostIP[@]}
	for((i=0;i<$length;i++));
	do
		if [ $i -eq 0 ]; then
			has_ssh=
		else
			has_ssh="ssh ${slaves_hostIP[i]}"
		fi
		$has_ssh ifconfig docker0 172.17.$[$i+1].1 netmask 255.255.255.0
		$has_ssh service docker restart
		outIP=${slaves_hostIP[i]}
		for((k=0;k<$length;k++));
		do
			if [ ${slaves_hostIP[k]} != $outIP ]; then
				$has_ssh route add -net 172.17.$[$k+1].0 netmask 255.255.255.0 gw ${slaves_hostIP[k]}
			fi
		done
		$has_ssh iptables -t nat -F POSTROUTING
		$has_ssh iptables -t nat -A POSTROUTING -s 172.17.$[$i+1].0/24 ! -d 172.17.0.0/16 -j  MASQUERADE
	done
}

#hadoop configure on all nodes
function hadoopConfigure() {
	Hadoop_tarName=$1
	local slaves_hostIP=(${!2})
	local slaves_hostsName=(${!3})
	if [ -f "/etc/hdocker_hadoopConfigure" ]; then
		rm /etc/hdocker_hadoopConfigure
	fi
	echo $Hadoop_tarName >> /etc/hdocker_hadoopConfigure
	echo ${slaves_hostsName[@]} >> /etc/hdocker_hadoopConfigure
	
	Hadoop_userName=hadoop251
	HADOOP_INSTALL=/home/$Hadoop_userName/hadoop
	if [ ! -f "/tmp/$Hadoop_tarName.tar" ]; then
		echo "/tmp/$Hadoop_tarName.tar doesn't exist!"
		exit
	fi

	echo "docker load < /tmp/$Hadoop_tarName.tar"
	docker load < /tmp/$Hadoop_tarName.tar
	name=`docker run -d -it -h ${slaves_hostsName[0]} $Hadoop_tarName`
	docker rename $name ${slaves_hostsName[0]}

	length=${#slaves_hostIP[@]}
	for((i=1;i<$length;i++));
	do
		echo "scp /tmp/$Hadoop_tarName.tar ${slaves_hostIP[$i]}:/tmp/"
		scp /tmp/$Hadoop_tarName.tar ${slaves_hostIP[$i]}:/tmp/
		echo "ssh ${slaves_hostIP[$i]} docker load < /tmp/$Hadoop_tarName.tar"
		ssh ${slaves_hostIP[$i]} docker load < /tmp/$Hadoop_tarName.tar
		name=`ssh ${slaves_hostIP[$i]} docker run -d -it -h ${slaves_hostsName[$i]} $Hadoop_tarName`
		ssh ${slaves_hostIP[$i]} docker rename $name ${slaves_hostsName[$i]}
		ssh ${slaves_hostIP[$i]} rm /tmp/$Hadoop_tarName.tar
	done

	slaves=""
	for((i=1;i<$length;i++));
	do
		slave_tmp="${slaves_hostsName[$i]}\n"
		slaves=$slaves$slave_tmp
	done
	echo -e $slaves > slaves

	master_ip=`docker exec ${slaves_hostsName[0]} sudo ifconfig eth0 | grep 'inet addr' | cut -d : -f 2 | cut -d ' ' -f 1`
	hosts_str="$master_ip ${slaves_hostsName[0]}\n"
	for((i=1;i<$length;i++));
	do
		tmp_ip=`ssh ${slaves_hostIP[$i]} docker exec ${slaves_hostsName[$i]} sudo ifconfig eth0 | grep 'inet addr' | cut -d : -f 2 | cut -d ' ' -f 1`
		tmp_ip_all="$tmp_ip ${slaves_hostsName[$i]}\n"
		hosts_str=$hosts_str$tmp_ip_all
	done
	echo -e $hosts_str > hosts
	master_full_id=`docker inspect -f   '{{.Id}}' ${slaves_hostsName[0]}`
	sudo cp hosts slaves /var/lib/docker/aufs/mnt/$master_full_id/root
	docker exec ${slaves_hostsName[0]} cp /root/hosts /etc/hosts
	docker exec ${slaves_hostsName[0]} cp /root/slaves $HADOOP_INSTALL/etc/hadoop/slaves
	docker exec ${slaves_hostsName[0]} rm /root/hosts /root/slaves

	for((i=1;i<$length;i++));
	do
		slave1_full_id=`ssh ${slaves_hostIP[$i]} docker inspect -f   '{{.Id}}' ${slaves_hostsName[$i]}`
		scp hosts ${slaves_hostIP[$i]}:/var/lib/docker/aufs/mnt/$slave1_full_id/root
		scp slaves ${slaves_hostIP[$i]}:/var/lib/docker/aufs/mnt/$slave1_full_id/root
		ssh ${slaves_hostIP[$i]} docker exec ${slaves_hostsName[$i]} cp /root/hosts /etc/hosts
		ssh ${slaves_hostIP[$i]} docker exec ${slaves_hostsName[$i]} cp /root/slaves $HADOOP_INSTALL/etc/hadoop/slaves
		ssh ${slaves_hostIP[$i]} docker exec ${slaves_hostsName[$i]} rm /root/hosts /root/slaves
	done
	docker exec ${slaves_hostsName[0]} su - $Hadoop_userName $HADOOP_INSTALL/sbin/start-all.sh
}

#enter all hosts' ip
function host_ip() {
	tmp=$1
	echo "hosts Num :"
	read line
	n=$line
	for((i=0;i<n;i++));
	do
		echo "host_ip  $[$i+1] :"
		read line
		slaves_hostIP[i]=$line
	done
	
	go_exit $tmp slaves_hostIP[@]
}

#ensure your node name
function node_name_go_exit() {
	tmp=$1
	local slaves_hostIP=(${!2})
	local slaves_hostsName=(${!3})
	echo "all node_name right(yes/no) :"
	read line
	if [ $line == "no" ] || [ $line == "n" ]; then
		echo "please enter again :"
		node_name $tmp slaves_hostIP[@]
	elif [ $line == "yes" ] || [ $line == "y" ]; then	
		echo "only image name(not including .tar, notice that the file should be in /tmp directory) :"
		read line
		if [ $tmp == "h" ]; then
			echo "now hadoop configure..."
			hadoopConfigure $line slaves_hostIP[@] slaves_hostsName[@]
		else
			echo "now network configure..."
			networkConfigure slaves_hostIP[@]
			echo "now hadoop configure..."
			hadoopConfigure $line slaves_hostIP[@] slaves_hostsName[@]
		fi
	else
		node_name_go_exit $tmp slaves_hostIP[@] slaves_hostsName[@]
	fi
}

#enter all nodes' names
function node_name() {
	tmp=$1
	local slaves_hostIP=(${!2})
	echo "nodes Num :"
	read line
	n=$line
	for((i=0;i<n;i++));
	do
		echo "node_name  $[$i+1] :"
		read line
		slaves_hostsName[i]=$line
	done
	node_name_go_exit $tmp slaves_hostIP[@] slaves_hostsName[@]
}

#ensure your hosts' ip
function go_exit() {
	tmp=$1
	local slaves_hostIP=(${!2})
	echo "all host_ip right(yes/no) :"
	read line
	if [ $line == "no" ] || [ $line == "n" ]; then
		echo "please enter again :"
		host_ip $tmp
		
	elif [ $line == "yes" ] || [ $line == "y" ]; then
		if [ $tmp == "n" ]; then
			echo "now network configure..."
			networkConfigure slaves_hostIP[@]
		elif [ $tmp == "h" ] || [ $tmp == "nh" ]; then
			node_name $tmp slaves_hostIP[@]
		fi
	else
		go_exit $tmp slaves_hostIP[@]
	fi
}
function all_input() {
	tmp=$1
	host_ip $tmp
}

#start all containers
function start_containers() {
	local slaves_hostIP=(${!1})
	local slaves_hostsName=(${!2})
	length=${#slaves_hostIP[@]}
	for((i=0;i<$length;i++));
	do
		if [ $i -eq 0 ]; then
			has_ssh=
		else
			has_ssh="ssh ${slaves_hostIP[i]}"
		fi
		$has_ssh docker start ${slaves_hostsName[i]}
	done
}

#stop all containers
function stop_containers() {
	local slaves_hostIP=(${!1})
	local slaves_hostsName=(${!2})
	length=${#slaves_hostIP[@]}
	for((i=0;i<$length;i++));
	do
		if [ $i -eq 0 ]; then
			has_ssh=
		else
			has_ssh="ssh ${slaves_hostIP[i]}"
		fi
		$has_ssh docker stop ${slaves_hostsName[i]}
	done
}

#remove all containers
function rm_containers() {
	local slaves_hostIP=(${!1})
	local slaves_hostsName=(${!2})
	length=${#slaves_hostIP[@]}
	for((i=0;i<$length;i++));
	do
		if [ $i -eq 0 ]; then
			has_ssh=
		else
			has_ssh="ssh ${slaves_hostIP[i]}"
		fi
		$has_ssh docker rm ${slaves_hostsName[i]}
	done
}

#remove all images
function rmi_images() {
	tarPath=$1
	local slaves_hostIP=(${!2})
	length=${#slaves_hostIP[@]}
	for((i=0;i<$length;i++));
	do
		if [ $i -eq 0 ]; then
			has_ssh=
		else
			has_ssh="ssh ${slaves_hostIP[i]}"
		fi
		$has_ssh docker rmi $tarPath
	done
}

#remove all docker networkConfigure
function remove_networkConfigure() {
	local slaves_hostIP=(${!1})
	length=${#slaves_hostIP[@]}
	for((i=0;i<$length;i++));
	do
		if [ $i -eq 0 ]; then
			has_ssh=
		else
			has_ssh="ssh ${slaves_hostIP[i]}"
		fi
		outIP=${slaves_hostIP[i]}
		for((k=0;k<$length;k++));
		do
			if [ ${slaves_hostIP[k]} != $outIP ]; then
				$has_ssh route del -net 172.17.$[$k+1].0 netmask 255.255.255.0 gw ${slaves_hostIP[k]}
			fi
		done
		$has_ssh iptables -F
	done

}

#
function start_configure_containers() {
	local slaves_hostIP=(${!1})
	local slaves_hostsName=(${!2})
	Hadoop_userName=hadoop251
	HADOOP_INSTALL=/home/$Hadoop_userName/hadoop
	master_ip=`docker exec ${slaves_hostsName[0]} sudo ifconfig eth0 | grep 'inet addr' | cut -d : -f 2 | cut -d ' ' -f 1`
	hosts_str="$master_ip ${slaves_hostsName[0]}\n"
	length=${#slaves_hostIP[@]}
	for((i=1;i<$length;i++));
	do
		tmp_ip=`ssh ${slaves_hostIP[$i]} docker exec ${slaves_hostsName[$i]} sudo ifconfig eth0 | grep 'inet addr' | cut -d : -f 2 | cut -d ' ' -f 1`
		tmp_ip_all="$tmp_ip ${slaves_hostsName[$i]}\n"
		hosts_str=$hosts_str$tmp_ip_all
	done
	echo -e $hosts_str > hosts
	master_full_id=`docker inspect -f   '{{.Id}}' ${slaves_hostsName[0]}`
	sudo cp hosts /var/lib/docker/aufs/mnt/$master_full_id/root
	docker exec ${slaves_hostsName[0]} cp /root/hosts /etc/hosts
	docker exec ${slaves_hostsName[0]} rm /root/hosts

	for((i=1;i<$length;i++));
	do
		slave1_full_id=`ssh ${slaves_hostIP[$i]} docker inspect -f   '{{.Id}}' ${slaves_hostsName[$i]}`
		scp hosts ${slaves_hostIP[$i]}:/var/lib/docker/aufs/mnt/$slave1_full_id/root
		ssh ${slaves_hostIP[$i]} docker exec ${slaves_hostsName[$i]} cp /root/hosts /etc/hosts
		ssh ${slaves_hostIP[$i]} docker exec ${slaves_hostsName[$i]} rm /root/hosts
	done
	docker exec ${slaves_hostsName[0]} su - $Hadoop_userName $HADOOP_INSTALL/sbin/start-all.sh
}


#**********program entry
startTime=`date '+%Y-%m-%d %H:%M:%S'`
if [ $# -eq 0 ]; then
	echo "See './hdocker.sh --help'."
elif [ $1 == "-h" ] || [ $1 == "--help" ] || [ $1 == "--h" ] || [ $1 == "-help" ]; then
	echo "=== hadoop on docker help info ==="
	echo 
	echo "********an example********"
	echo
	echo "hosts Num :"
	echo "4"
	echo "host_ip :"
	echo -e "10.62.43.54\n10.62.43.55\n10.62.43.56\n10.62.43.57"
	echo "nodes Num :"
	echo "4"
	echo "node_name :"
	echo -e "master\nslave1\nslave2\nslave3"
	echo "only image name(not including .tar, notice that the file should be in /tmp directory) :"
	echo "hadoop_on_docker:V5"
	echo 
	echo 
	echo "--------Parameters:"
	echo
	echo "  sc   -> stop all containers"
	echo "  rc   -> rm all containers"
	echo "  ri   -> rmi all images"
	echo "  rn   -> remove all networkConfigure"
	echo "  rh   -> remove hadoop configure"
	echo "  ra   -> remove all configure(***)"
    echo "  n    -> network configure"
    echo "  h    -> hadoop configure"
    echo "  nh   -> both network and hadoop configure(*****)"
	echo "  sttc -> start containers and configure /etc/hosts(*******)"
	echo
elif [ $1 == "sc" ] || [ $1 == "rc" ] || [ $1 == "ri" ] || [ $1 == "rn" ] || [ $1 == "rh" ] || [ $1 == "sttc" ] || [ $1 == "ra" ]; then
	read line < /etc/hdocker_networkConfigure
	slaves_hostIP=($line)
	i=0
	while read line
	do
		tmp[$i]=$line
		let i+=1
	done < /etc/hdocker_hadoopConfigure
	tarPath=${tmp[0]}
	slaves_hostsName=(${tmp[1]})
	
	if [ $1 == "sc" ]; then
		echo "now stop containers..."
		stop_containers slaves_hostIP[@] slaves_hostsName[@]
	elif [ $1 == "rc" ]; then
		echo "now remove containers..."
		rm_containers slaves_hostIP[@] slaves_hostsName[@]
	elif [ $1 == "ri" ]; then
		echo "now remove images..."
		rmi_images $tarPath slaves_hostIP[@]
	elif [ $1 == "rn" ]; then
		echo "now remove network configure..."
		remove_networkConfigure slaves_hostIP[@]
		if [ -f "/etc/hdocker_networkConfigure" ]; then
			rm /etc/hdocker_networkConfigure
		fi
	elif [ $1 == "rh" ]; then
		echo "now stop containers..."
		stop_containers slaves_hostIP[@] slaves_hostsName[@]
		echo "now remove containers..."
		rm_containers slaves_hostIP[@] slaves_hostsName[@]
		echo "now remove images..."
		rmi_images $tarPath slaves_hostIP[@]
		if [ -f "/etc/hdocker_hadoopConfigure" ]; then
			rm /etc/hdocker_hadoopConfigure
		fi
	elif [ $1 == "ra" ]; then
		echo "now stop containers..."
		stop_containers slaves_hostIP[@] slaves_hostsName[@]
		echo "now remove containers..."
		rm_containers slaves_hostIP[@] slaves_hostsName[@]
		echo "now remove images..."
		rmi_images $tarPath slaves_hostIP[@]
		echo "now remove network configure..."
		remove_networkConfigure slaves_hostIP[@]
		if [ -f "/etc/hdocker_networkConfigure" ]; then
			rm /etc/hdocker_networkConfigure
		fi
		if [ -f "/etc/hdocker_hadoopConfigure" ]; then
			rm /etc/hdocker_hadoopConfigure
		fi
	elif [ $1 == "sttc" ]; then
		echo "now start containers and configure /etc/hosts..."
		start_containers slaves_hostIP[@] slaves_hostsName[@]
		start_configure_containers slaves_hostIP[@] slaves_hostsName[@]
	fi
elif [ $1 == "n" ] || [ $1 == "h" ] || [ $1 == "nh" ]; then
	all_input $1
else
	echo "See './hdocker.sh --help'."
fi
endTime=`date '+%Y-%m-%d %H:%M:%S'`
echo "<-start : $startTime"
echo "->end : $endTime"

