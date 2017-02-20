
. /lib/functions/weimarnetz/ipsystem.sh

log_net() {
	logger -s -t apply_profile_net $@
}

log_wifi() {
	logger -s -t apply_profile_wifi $@
}

setup_ip() {
	local cfg="$1"
	local ipaddr="$2"
	if ! uci_get network $cfg >/dev/null ; then
		uci_add network interface "$cfg"
	fi
	if [ -n "$ipaddr" ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		uci_set network $cfg ipaddr "$IP"
		uci_set network $cfg netmask "$NETMASK"
	fi
	if uci_get network $cfg type bridge; then 
		uci_remove network $cfg type
	fi
	uci_set network $cfg proto "static"
	uci_set network $cfg ip6assign "64"
}

setup_bridge() {
	local cfg="$1"
	local ipaddr="$2"
	local ifc="$3"
	setup_ip $cfg "$ipaddr"
	uci_set network $cfg macaddr '02:ff:ff:ff:00:00'
	uci_set network $cfg type "bridge"
	#uci_set network $cfg ifname "$ifc"
}

setup_ether() {
	local cfg="$1"
	local nodenumber="$2"

        config_get enabled $cfg enabled "0"                     
        [ "$enabled" == "0" ] && return 
	
	nodeconfig=$(node2nets_json $nodenumber)

	json_load "$nodeconfig"
	json_get_var ipaddr lan
 
	log_net "Setup $cfg IP"
	setup_ip "$cfg" "$ipaddr"
}

setup_wifi() {
	local cfg="$1"
	local nodenumber="$2"
	local br_name="$3"

	config_get enabled $cfg enabled "0"
	log_wifi "$cfg" "$enabled"

	[ "$enabled" == "0" ] && return
	config_get idx $cfg idx "-1"
	[ "$idx" == "-1" ] return
	local device="radio$idx"
	log_wifi "Setup $cfg"
	#get valid hwmods
	local hw_ac=0
	local hw_a=0
	local hw_b=0
	local hw_g=0
	local hw_n=0
	local info_data
	info_data=$(ubus call iwinfo info '{ "device": "wlan'$idx'" }' 2>/dev/null)
	[ -z "$info_data" ] && {
		log_wifi "ERR No iwinfo data for wlan$idx"
		return 1
	}
	json_load "$info_data"
	json_select hwmodes
	json_get_values hw_res
	[ -z "$hw_res" ] && {
		log_wifi "ERR No iwinfo hwmodes for wlan$idx"
		return 1
	}
	for i in $hw_res ; do
		case $i in
			a)  hw_a=1 ;;
			ac) hw_ac=1 ;;
			b)  hw_b=1 ;;
			g)  hw_g=1 ;;
			n)  hw_n=1 ;;
		esac
	done
	[ "$hw_a" == 1 ] && log_wifi "HWmode a"
	[ "$hw_b" == 1 ] && log_wifi "HWmode b"
	[ "$hw_g" == 1 ] && log_wifi "HWmode g"
	[ "$hw_n" == 1 ] && log_wifi "HWmode n"
	[ "$hw_ac" == 1 ] && log_wifi "HWmode ac"
	#get valid channel list
	local channels
	local valid_channel
	local chan_data
	chan_data=$(ubus call iwinfo freqlist '{ "device": "wlan'$idx'" }' 2>/dev/null)
	[ -z "$chan_data" ] && {
		log_wifi "ERR No iwinfo freqlist for wlan$idx"
		return 1
	}
	json_load "$chan_data"
	json_select results
	json_get_keys chan_res
	for i in $chan_res ; do
		json_select "$i"
		#check what channels are available
		json_get_var restricted restricted
		if [ "$restricted" == 0 ] ; then
			json_get_var channel channel
			channels="$channels $channel"
		fi
		json_select ".."
	done
	#get default channel depending on hw_mod
	[ "$hw_a" == 1 ] && def_channel=36
	[ "$hw_b" == 1 ] && def_channel=5
	[ "$hw_g" == 1 ] && def_channel=5
	config_get channel $cfg channel "$def_channel"
	local valid_channel
	for i in $channels ; do
		[ -z "$valid_channel" ] && valid_channel="$i"
		if [ "$channel" == "$i" ] ; then
			valid_channel="$i"
		fi
	done
	log_wifi "Channel $valid_channel"
	uci_set wireless $device channel "$valid_channel"
	uci_set wireless $device disabled "0"
	[ $hw_g == 1 ] && [ $hw_n == 1 ] && uci_set wireless $device noscan "1"
	[ $hw_n == 1 ] && [ $valid_channel -gt 165 ] && uci_set wireless $device htmode "HT40+"
	# Channel 165 HT40-
	[ $hw_n == 1 ] && [ $valid_channel -le 165 ] && uci_set wireless $device htmode "HT40-"
	# Channel 153,157,161 HT40+
	[ $hw_n == 1 ] && [ $valid_channel -le 161 ] && uci_set wireless $device htmode "HT40+"
	# Channel 104 - 140 HT40-
	[ $hw_n == 1 ] && [ $valid_channel -le 140 ] && uci_set wireless $device htmode "HT40-"
	# Channel 100 HT40+
	[ $hw_n == 1 ] && [ $valid_channel -le 100 ] && uci_set wireless $device htmode "HT40+"
	# Channel 40 - 64 HT40-
	[ $hw_n == 1 ] && [ $valid_channel -le 64 ] && uci_set wireless $device htmode "HT40-"
	# Channel 36 HT40+
	[ $hw_n == 1 ] && [ $valid_channel -le 36 ] && uci_set wireless $device htmode "HT40+"
	# Channel 10 - 14 HT40-
	[ $hw_n == 1 ] && [ $valid_channel -le 14 ] && uci_set wireless $device htmode "HT40-"
	# Channel 5 - 9 HT40+/-
	[ $hw_n == 1 ] && [ $valid_channel -le 7 ] && uci_set wireless $device htmode "HT40+"
	# Channel 1 - 4 HT40+
	[ $hw_n == 1 ] && [ $valid_channel -le 4 ] && uci_set wireless $device htmode "HT40+"
	uci_set wireless $device country "DE"
	[ $hw_a == 1 ] && uci_set wireless $device doth "0"
	#uci_set wireless $device distance "1000"
	#Reduce the Broadcast distance and save Airtime
	#Not working on wdr4300 with AP and ad-hoc
	#[ $hw_n == 1 ] && uci_set wireless $device basic_rate "5500 6000 9000 11000 12000 18000 24000 36000 48000 54000"
	#Set Man or Auto?
	#uci_set wireless $device txpower 15
	#Save Airtime max 1000
	#uci_set wireless $device beacon_int "250"
	#wifi-iface
	config_get olsr_mesh $cfg olsr_mesh "0"
	config_get bat_mesh $cfg bat_mesh "0"
	config_get nodenumber settings nodenumber

        nodeconfig=$(node2nets_json $nodenumber)                                                      
                                                                                                      
        json_load "$nodeconfig"                                                                       
        json_get_var ipaddr ${cfg}_mesh	
	log_net $cfg $ipaddr	
	if [ "$olsr_mesh" == "1" -o "$bat_mesh" == "1" ]; then
		local bssid
		log_wifi "mesh"
		cfg_mesh=$cfg"_mesh"
		uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
		uci_set wireless $sec device "$device"
		uci_set wireless $sec encryption "none"
		# Depricated Ad-Hoc config
		uci_set wireless $sec mode "adhoc"
		uci_set wireless $sec ssid "intern."$nodenumber".ch"$valid_channel".weimarnetz.de"
		bssid="02:CA:FF:EE:BA:BE"
		#elif [ $valid_channel -gt 99 -a $valid_channel -lt 199 ] ; then
		#	bssid="12:"$(printf "%02d" "$(expr $valid_channel - 100)")":CA:FF:EE:EE"
		#fi
		uci_set wireless $sec bssid "$bssid"
		#uci_set wireless $sec mode "mesh"
		#uci_set wireless $sec mesh_id 'freifunk'
		#uci_set wireless $sec mesh_fwding '0'
		#uci_set wireless $sec "doth"
		uci_set wireless $sec network "$cfg_mesh"
		uci_set wireless $sec mcast_rate "6000"
		setup_ip "$cfg_mesh" "$ipaddr"
	fi
	config_get vap $cfg vap "0"
	#TODO check valid interface combinations
	#iw phy$idx info | grep -A6 "valid interface combinations"
	#iw phy$idx info | grep "interface combinations are not supported"
	if [ "$vap" == "1" ] && \
		[ -n "$(iw phy$idx info | grep 'interface combinations are not supported')" ]  ; then
		vap="0"
		log_wifi "Virtual AP Not Supported"
		#uci_set meshnode $cfg vap "0"
	fi
	if [ "$vap" == "1" ] ; then
		log_wifi "Virtual AP"
		cfg_vap=$cfg"_vap"
		uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
		uci_set wireless $sec device "$device"
		uci_set wireless $sec mode "ap"
		uci_set wireless $sec mcast_rate "6000"
		#uci_set wireless $sec isolate 1
		uci_set wireless $sec ssid "weimar.freifunk.net"
		uci_set wireless $sec network "$br_name"

		config_get roaming "$cfg" "roaming"
		if [ "$roaming" == "1" ]; then
			json_get_var ipaddr roaming_block
		else 
			json_get_var ipaddr wifi
		fi
		log_wifi "$ipaddr"
		setup_bridge "$br_name" "$ipaddr"
	fi
}

remove_wifi() {
	local cfg="$1"
	uci_remove wireless "$cfg" 2>/dev/null
}

br_ifaces=""
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
config_foreach setup_ether ether "$nodenumber"
config_foreach setup_wifi wifi "$nodenumber" "$br_name"

#Setup IP6 Prefix
#config_get ip6prefix meshnode ip6prefix
#if [ -n "$ip6prefix" ] ; then
#	uci_set network loopback ip6prefix "$ip6prefix"
#fi

uci_commit network
uci_commit wireless
