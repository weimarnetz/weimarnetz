#!/bin/sh

. /usr/lib/weimarnetz/ipsystem.sh

log_dhcp() {
	logger -s -t ffwizard_dhcp "$@"
}

setup_dhcp() {
	local cfg_dhcp="$1"
	local ipaddr="$2"
	local ipv6="$3"

	if uci_get dhcp $cfg_dhcp >/dev/null ; then
		uci_remove dhcp $cfg_dhcp
	fi
	uci_add dhcp dhcp $cfg_dhcp
	uci_set dhcp $cfg_dhcp interface "$cfg_dhcp"
	uci_set dhcp $cfg_dhcp ignore "0"
	if [ -n "$ipaddr" ] ; then
		eval "$(ipcalc.sh "$ipaddr")"
		OCTET_4="${NETWORK##*.}"
		OCTET_1_3="${NETWORK%.*}"
		OCTET_4="$((OCTET_4 + 2))"
		#start_ipaddr="$OCTET_4"
		start_ipaddr=1
		uci_set dhcp $cfg_dhcp start "$start_ipaddr"
		limit=$(($((2**$((32-$PREFIX))))-2))
		uci_set dhcp $cfg_dhcp limit "$limit"
	fi
	uci_set dhcp $cfg_dhcp leasetime "15m"
	uci_add_list dhcp $cfg_dhcp dhcp_option "119,olsr,lan,p2p"
	uci_add_list dhcp $cfg_dhcp domain "olsr"
	uci_add_list dhcp $cfg_dhcp domain "lan"
	uci_add_list dhcp $cfg_dhcp domain "p2p"
	[ "$ipv6" -eq 1 ] && {
		uci_set dhcp $cfg_dhcp dhcpv6 "server"
		uci_set dhcp $cfg_dhcp ra "server"
		uci_set dhcp $cfg_dhcp ra_preference "low"
		uci_set dhcp $cfg_dhcp ra_default "1"
	}
}

setup_roaming_dhcp() {
	local cfg_dhcp="$1"
	local nodenumber="$2"
	local ipv6="$3"

	json_load "$nodedata"
	json_get_var offset roaming_dhcp_offset

	if uci_get dhcp $cfg_dhcp >/dev/null ; then
				uci_remove dhcp $cfg_dhcp
	fi
	uci_add dhcp dhcp $cfg_dhcp
	uci_set dhcp $cfg_dhcp interface "$cfg_dhcp"
	uci_set dhcp $cfg_dhcp ignore "0"
	uci_set dhcp $cfg_dhcp start "$offset"
	uci_set dhcp $cfg_dhcp limit "254"
	uci_set dhcp $cfg_dhcp leasetime "6h"
	uci_add_list dhcp $cfg_dhcp dhcp_option "119,olsr,lan,p2p"
	uci_add_list dhcp $cfg_dhcp domain "olsr"
	uci_add_list dhcp $cfg_dhcp domain "lan"
	uci_add_list dhcp $cfg_dhcp domain "p2p"
	if [ "$ipv6" -eq 1 ]; then
		uci_set dhcp $cfg_dhcp dhcpv6 "server"
		uci_set dhcp $cfg_dhcp ra "server"
		uci_set dhcp $cfg_dhcp ra_preference "low"
		uci_set dhcp $cfg_dhcp ra_default "1"
	fi
}

setup_ether() {
	local cfg="$1"
	local nodenumber="$2"

	config_get enabled $cfg enabled "0"
	[ "$enabled" -eq 0 ] && return
	json_init
	json_load "$nodedata"
	json_get_var ipaddr "$cfg"
	json_cleanup
	config_get ipv6 settings ipv6 "0"
	cfg_dhcp=$cfg""
	uci_remove dhcp $cfg_dhcp 2>/dev/null
	setup_dhcp $cfg_dhcp "$ipaddr" "$ipv6"
}

setup_wifi() {
	local cfg="$1"
	local nodenumber="$2"

	config_get enabled $cfg enabled "0"
	[ "$enabled" -eq 0 ] && return
	config_get ipv6 settings ipv6 "0"

	local nodedata=$(node2nets_json $nodenumber)
	json_init
	json_load "$nodedata"
	json_get_var dhcp_ip wifi
	cfg_dhcp="$br_name"
	uci_remove dhcp $cfg_dhcp 2>/dev/null
	if [ -n "$dhcp_ip" ] ; then
		log_dhcp "Setup $cfg with $dhcp_ip"
		setup_dhcp $cfg_dhcp "$dhcp_ip" "$ipv6"
	fi
	uci_remove dhcp roam 2>/dev/null
	setup_roaming_dhcp "roam" "$nodenumber"
	json_cleanup

}

setup_dhcpbase() {
	local cfg="$1"
	uci_set dhcp $cfg local "/olsr/"
	uci_set dhcp $cfg domain "olsr"
	uci_set dhcp $cfg allservers "1"
	uci_remove dhcp $cfg server
	uci_add_list dhcp $cfg server "5.1.66.255" #  https://ffmuc.net/wiki/doku.php?id=knb:dohdot
	uci_add_list dhcp $cfg server "46.182.19.48" # https://digitalcourage.de/support/zensurfreier-dns-server
	uci_add_list dhcp $cfg server "185.150.99.255" #  https://ffmuc.net/wiki/doku.php?id=knb:dohdot
	uci_add_list dhcp $cfg server "194.150.168.168" # as250.net - https://www.ccc.de/censorship/dns-howto/
	config_get ffwizard $cfg olsr_mesh "0"
	if [ "$olsr_mesh" -eq 1 ]; then
		uci_remove dhcp $cfg addnhosts
		uci_add_list dhcp $cfg addnhosts "/tmp/hosts/olsr.ipv4"
		uci_add_list dhcp $cfg addnhosts "/etc/hosts.ff"
	fi
}

setup_odhcpbase() {
	local cfg="$1"
	#uci_set dhcp $cfg maindhcp "1"
	uci_set dhcp $cfg maindhcp "0"
}

setup_hosts() {
		rm -f /etc/hosts.ff
		read -r hostname < /proc/sys/kernel/hostname 
		json_init
		json_load "$nodedata"
		json_get_vars wifi radio0_mesh radio1_mesh radio0_11s radio1_11s roaming_gw vpn_gw lan
		for h in internet kiste router mutti frei.funk
		do
			echo "${lan%/*} $h" >> /etc/hosts.ff
		done
		echo "${radio0_mesh%/*} mesh0.$hostname.olsr" >> /etc/hosts.ff
		echo "${radio1_mesh%/*} mesh1.$hostname.olsr" >> /etc/hosts.ff
		echo "${radio0_11s%/*} 11s.$hostname.olsr" >> /etc/hosts.ff
		echo "${radio1_11s%/*} 11s.$hostname.olsr" >> /etc/hosts.ff
		echo "${vpn_gw%/*} vpngw.$hostname.olsr" >> /etc/hosts.ff
		echo "${wifi%/*} vap.$hostname.olsr" >> /etc/hosts.ff
		echo "${roaming_gw%/*} roam.$hostname.olsr" >> /etc/hosts.ff
}

br_name="vap"
#lan_iface="lan"
wan_iface="wan"

#Load dhcp config
config_load dhcp
#Setup dnsmasq
config_foreach setup_dhcpbase dnsmasq

#Setup odhcpd
config_foreach setup_odhcpbase odhcpd

#Setup ether and wifi
config_load ffwizard
config_get nodenumber settings nodenumber
nodedata=$(node2nets_json $nodenumber)
config_foreach setup_ether ether "$nodenumber" 
config_foreach setup_wifi wifi "$nodenumber" 

#Setup DHCP Batman Bridge
#config_get br ffwizard br "0"
#if [ "$br" == "1" ] ; then
#	config_get dhcp_ip ffwizard dhcp_ip
#	log_dhcp "Setup iface $br_name with ip $dhcp_ip"
#	setup_dhcp $br_name $dhcp_ip
#else
#	if uci_get dhcp $br_name >/dev/null ; then
#		log_dhcp "Setup $br_name remove"
#		uci_remove dhcp $br_name 2>/dev/null
#	fi
#fi


#Enable dhcp on LAN
#if [ -n "$lan_iface" ] ; then
#	log_dhcp "Setup iface $lan_iface to default"
#	uci_set dhcp $cfg ignore "0"
#	uci_set dhcp $lan_iface start "1"
#	uci_set dhcp $lan_iface limit "13"
#	uci_set dhcp $lan_iface leasetime "12h"
#	uci_add_list dhcp $cfg_dhcp dhcp_option "119,olsr,lan,p2p"
#	uci_add_list dhcp $cfg_dhcp domain "olsr"
#	uci_add_list dhcp $cfg_dhcp domain "lan"
#	uci_add_list dhcp $cfg_dhcp domain "p2p"
#	uci_set dhcp $lan_iface dhcpv6 "server"
#	uci_set dhcp $lan_iface ra "server"
#fi

#Disable dhcp on WAN
if [ -n "$wan_iface" ] ; then
	log_dhcp "Setup iface $wan_iface to default"
	uci_set dhcp $wan_iface ignore "1"
	uci_set dhcp $wan_iface dhcpv6 "disabled"
	uci_set dhcp $wan_iface ra "disabled"
fi

setup_hosts

uci_commit dhcp

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
