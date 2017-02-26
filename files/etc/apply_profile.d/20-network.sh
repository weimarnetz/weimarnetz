#!/bin/sh -x 
# shellcheck disable=SC2039

. /lib/functions/weimarnetz/ipsystem.sh

log_net() {
	logger -s -t apply_profile_net "$@"
}

log_wifi() {
	logger -s -t apply_profile_wifi "$@"
}

setup_ip() {
	local cfg="$1"
	local ipaddr="$2"
	if ! uci_get network "$cfg" >/dev/null ; then
		uci_add network interface "$cfg"
	fi
	if [ -n "$ipaddr" ] ; then
		eval "$(ipcalc.sh "$ipaddr")"
		uci_set network "$cfg" ipaddr "$IP"
		uci_set network "$cfg" netmask "$NETMASK"
	fi
	if uci_get network "$cfg" type bridge >/dev/null; then 
		uci_remove network "$cfg" type
	fi
	uci_set network "$cfg" proto 'static'
	uci_set network "$cfg" ip6assign '64'
}

setup_bridge() {
	local cfg="$1"
	local ipaddr="$2"
	local roaming="$3"
	setup_ip "$cfg" "$ipaddr"
	if [ "$roaming" -eq "1" ]; then 
		uci_set network "$cfg" macaddr '02:ff:ff:ff:00:00'
	fi
	uci_set network "$cfg" type 'bridge'
}

setup_vpn() {
	local cfg="$1"
	if uci_get network "$cfg"; then 
		uci_remove network "$cfg"
	fi 
	if uci_get network "tap0"; then 
		uci_remove network "tap0"
	fi
	uci_add network interface "$cfg"
	config_get type "$cfg" type "vtun"
	if [ "$type" = "vtun" ]; then
		uci_set network "$cfg" ifname "tap0"
	fi
}

setup_ether() {
	local cfg="$1"
	local nodenumber="$2"

	config_get enabled "$cfg" enabled "0"					  
	[ "$enabled" -eq "1" ] || return 
	config_get device "$cfg" device "none"
	[ "$device" = "none" ] && return
	json_init
	json_load "$nodedata"
	json_get_var ipaddr "$device"
	[ -z "$ipaddr" ] && log_net "ERR $cfg - missing IP" 
	log_net "Setup $cfg | IP $ipaddr"
	setup_ip "$cfg" "$ipaddr"
	json_cleanup
}

setup_wifi() {
	local cfg="$1"
	local nodenumber="$2"
	local br_name="$3"

	config_get enabled "$cfg" enabled "0"
	[ -z "$enabled" ] && return
	config_get idx "$cfg" idx "-1"
	[ "$idx" -eq "-1" ] return
	
	local device="radio$idx"
	log_wifi "Setup $cfg"

	#get valid hwmods
	local hw_ac=0
	local hw_a=0
	local hw_b=0
	local hw_g=0
	local hw_n=0
	local info_data
	info_data=$(ubus call iwinfo info '{ "device": "wlan'"$idx"'" }' 2>/dev/null)
	[ -z "$info_data" ] && {
		log_wifi "ERR No iwinfo data for wlan$idx"
		return 1
	}
	json_init
	json_load "$info_data"
	json_select hwmodes
	json_get_values hw_res
	json_cleanup
	[ -z "$hw_res" ] && {
		log_wifi "ERR No iwinfo hwmodes for wlan$idx"
		return 1
	}
	for i in $hw_res; do
		case $i in
			a)	hw_a=1	;;
			ac) hw_ac=1 ;;
			b)	hw_b=1	;;
			g)	hw_g=1	;;
			n)	hw_n=1	;;
		esac
	done

	[  "$hw_a"	-eq "1" ] && log_wifi "$cfg: HWmode a"
	[  "$hw_b"	-eq "1" ] && log_wifi "$cfg: HWmode b"
	[  "$hw_g"	-eq "1" ] && log_wifi "$cfg: HWmode g"
	[  "$hw_n"	-eq "1" ] && log_wifi "$cfg: HWmode n"
	[  "$hw_ac" -eq "1" ] && log_wifi "$cfg: HWmode ac"

	#get default channel depending on hw_mod
	[ "$hw_ac" -eq "1" ] && channel=40
	[ "$hw_a" -eq "1"  ] && channel=40
	[ "$hw_b" -eq "1"  ] && channel=5
	[ "$hw_g" -eq "1"  ] && channel=5
	uci_set wireless "$device" channel "$channel"
	uci_set wireless "$device" disabled "0"
	[  "$hw_g" -eq "1" ] || [ "$hw_n" -eq "1"  ] && uci_set wireless "$device" noscan "1"
	[  "$hw_n" ]					 && uci_set wireless "$device" htmode "HT20"
	[  "$hw_a" -eq "1" ] && [ "$hw_ac" -eq "1" ] && uci_set wireless "$device" htmode "VHT80"
	[  "$hw_a" -eq "1" ] && [ "$hw_ac" -eq "0" ] && uci_set wireless "$device" htmode "HT40"

	uci_set wireless "$device" country "DE"

	uci_set wireless $device distance "1000"
	#Reduce the Broadcast distance and save Airtime
	#Not working on wdr4300 with AP and ad-hoc
	#[ $hw_n == 1 ] && uci_set wireless $device basic_rate "5500 6000 9000 11000 12000 18000 24000 36000 48000 54000"
	#Set Man or Auto?
	#uci_set wireless $device txpower 15
	#Save Airtime max 1000
	#uci_set wireless $device beacon_int "250"
	#wifi-iface

	config_get olsr_mesh "$cfg" olsr_mesh "0"

	json_init	
	json_load "$nodedata"  
	json_get_var ipaddr "${device}_mesh"

	if [ "$olsr_mesh" -eq "1" ] || [ "$bat_mesh" -eq "1" ]; then
		local bssid
		log_wifi "${cfg}: mesh"
		local network="${cfg}_mesh"
		uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
		uci_set wireless "$sec" device "$device"
		uci_set wireless "$sec" encryption "none"
		uci_set wireless "$sec" mode "adhoc"
		uci_set wireless "$sec" ssid "intern.$nodenumber.ch$channel.weimarnetz.de"
		bssid="02:CA:FF:EE:BA:BE"
		#elif [ $valid_channel -gt 99 -a $valid_channel -lt 199 ] ; then
		#	bssid="12:"$(printf "%02d" "$(expr $valid_channel - 100)")":CA:FF:EE:EE"
		#fi
		uci_set wireless "$sec" bssid "$bssid"
		#uci_set wireless "$sec" mode "mesh"
		#uci_set wireless "$sec" mesh_id 'freifunk'
		#uci_set wireless "$sec mesh_fwding '0'
		#uci_set wireless "$sec "doth"
		uci_set wireless "$sec" network "$network"
		uci_set wireless "$sec" mcast_rate "6000"
		setup_ip "$network" "$ipaddr"
	fi
	config_get vap "$cfg" vap "0"
	#TODO check valid interface combinations
	#iw phy$idx info | grep -A6 "valid interface combinations"
	#iw phy$idx info | grep "interface combinations are not supported"
	if [ "$vap" -eq "1" ] && \
		[ -n "$(iw phy$idx info | grep 'interface combinations are not supported')" ]  ; then
		vap="0"
		log_wifi "Virtual AP Not Supported"
		#uci_set meshnode $cfg vap "0"
	fi
	if [ "$vap" -eq "1" ] ; then
		log_wifi "${cfg}: Virtual AP"
		cfg_vap="${cfg}_vap"
		uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
		uci_set wireless "$sec" device "$device"
		uci_set wireless "$sec" mode "ap"
		#uci_set wireless "$sec" mcast_rate "6000"
		#uci_set wireless "$sec" isolate 1
		uci_set wireless "$sec" ssid "weimar.freifunk.net"
		uci_set wireless "$sec" network "$br_name"

		config_get roaming settings roaming
		if [ "$roaming" -eq "1" ]; then
			json_get_var ipaddr roaming_block
		else 
			json_get_var ipaddr wifi
		fi
		log_wifi "${cfg}: $ipaddr"
		setup_bridge "$br_name" "$ipaddr" "$roaming"
	fi
	json_cleanup
}

remove_wifi() {
	local cfg="$1"
	uci_remove wireless "$cfg" 2>/dev/null
}

br_name="vap"

#Remove wireless config
rm /etc/config/wireless
/sbin/wifi config 
uci commit wireless 

#Remove wifi ifaces
# FIXME leave disabled iface alone
config_load wireless
config_foreach remove_wifi wifi-iface
uci_commit wireless

#Setup ether and wifi
config_load meshnode
config_get nodenumber settings nodenumber
nodedata=$(node2nets_json "$nodenumber")
config_foreach setup_ether ether "$nodenumber"
config_foreach setup_wifi wifi "$nodenumber" "$br_name"
config_foreach setup_vpn vpn 

config_get ip6prefix meshnode ip6prefix
if [ -n "$ip6prefix" ] ; then
	uci_set network globals ula_prefix "$ip6prefix"
fi

uci_commit network
uci_commit wireless
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
