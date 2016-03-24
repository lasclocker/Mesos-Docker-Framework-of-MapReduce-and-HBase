#!/bin/bash

brctl addbr br0; \
ip addr add $3 dev br0; \
ip addr del $3 dev eth0; \
brctl addif br0 eth0; \
ip link set br0 up;\
ip route add default via $2 dev br0

vm=$(docker run -itd --privileged=true --net=none ubuntu /bin/bash)
pipework br0 $vm $1@$2


ifconfig br0 promisc
