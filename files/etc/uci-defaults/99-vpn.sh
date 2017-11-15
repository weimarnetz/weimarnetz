#!/bin/sh 

. /lib/functions.sh

#fixme

while true; do 
	uci delete network.@vtun_vpn[0]
	[ "$?" -eq 0 ] || break
	uci commit
done 

uci -m import network <<-EOF
config vtun_vpn
   list endpoint '2.v.weimarnetz.de'
   list endpoint '3.v.weimarnetz.de'
EOF
uci commit 
