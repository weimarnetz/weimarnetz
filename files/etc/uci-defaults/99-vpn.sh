#!/bin/sh 

. /lib/functions.sh

[ -z $(uci_get network vtun_vpn keep) ] && {
	uci_remove network vtun_vpn
	uci -m import network <<-EOF
	config vtun_vpn
	        list endpoint '2.v.weimarnetz.de'
	        list endpoint '3.v.weimarnetz.de'
	EOF
	uci commit 
}
