#!/bin/bash

eth0_ip_maskNum=`ip addr show eth0 | grep -o inet.*brd | cut -d ' ' -f 2`
gateway=`ip route | head -1 | cut -d ' ' -f 3`

brctl addbr br0
ip addr add $eth0_ip_maskNum dev br0
ip addr del $eth0_ip_maskNum dev eth0
brctl addif br0 eth0
ip link set br0 up
ip route add default via $gateway dev br0


#vm=$(docker run -itd --privileged=true --net=none ubuntu /bin/bash)
#pipework br0 $vm $1@$2


#ifconfig br0 promisc
