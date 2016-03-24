#!/bin/bash

for line in `cat mesos-slaves-ipfile.txt`
do
	echo $line
	ssh $line mkdir -p /usr/share/ca-certificates/emc
	scp /usr/share/ca-certificates/emc/* $line:/usr/share/ca-certificates/emc
	ssh $line "echo -e \"emc/EMC_CA.cer\nemc/EMC_SSL.cer\" >> /etc/ca-certificates.conf"
	ssh $line update-ca-certificates
	ssh $line service docker restart
	ssh $line docker pull busybox
done

