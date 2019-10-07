#!/bin/sh -x 
# shellcheck disable=SC2039

log_net() {
	logger -s -t ffwizard_net "$@"
}

log_wifi() {
	logger -s -t ffwizard_wifi "$@"
}

is_ac_radio() {
        local radio="$1"
        local info

        info=$(ubus call iwinfo info "{ \"device\":\"$radio\"}")
        json_load "$info"
        json_select "hwmodes"
        local idx=1
        while json_get_type status "$idx" && [ "$status" = "string" ]; do
                json_get_var ac "$((idx++))"
                [ "$ac" = "ac" ] && { 
					json_cleanup 
					return 0
				}
        done
        json_cleanup
        return 1 
}


setup_ip() {
	local cfg="$1"
	local ipaddr="$2"
	local gateway="$3"

	if ! uci_get network "$cfg" >/dev/null ; then
		uci_add network interface "$cfg"
	fi
	if [ -n "$ipaddr" ] ; then
		eval "$(ipcalc.sh "$ipaddr")"
		uci_set network "$cfg" ipaddr "$IP"
		uci_set network "$cfg" netmask "$NETMASK"
	fi
	if [ -n "$gateway" ] ; then
		eval "$(ipcalc.sh "$gateway")"
		uci_set network "$cfg" gateway "$IP"
	fi 
	if uci_get network "$cfg" type bridge >/dev/null; then 
		uci_remove network "$cfg" type
	fi
	if [ "$cfg" = "vpn" ] ; then
		uci_set network "$cfg" proto 'vtun'
	else
		uci_set network "$cfg" proto 'static'
	fi
	# uci_set network "$cfg" ip6assign '64'
	log_net ${cfg}: $ipaddr $gateway
}

setup_bridge() {
	local cfg="$1"
	local ipaddr="$2"
	local roaming="$3"
	setup_ip "$cfg" "$ipaddr"
	if [ "$cfg" = "roam" ]; then 
		uci_set network "$cfg" macaddr '02:ff:ff:ff:23:42'
		true
	fi
	uci_set network "$cfg" type 'bridge'
}

setup_vpn() {
	local cfg="$1"
	if uci_get network "$cfg" >/dev/null; then 
		uci_remove network "$cfg"
	fi
	# remove old settings
	if uci_get network "tap0" >/dev/null; then 
		uci_remove network "tap0"
	fi
	uci_add network interface "$cfg"
	config_get type "$cfg" type "vtun"
	if [ "$type" = "vtun" ]; then
		uci_set network "$cfg" proto "vtun"
		uci_set network "$cfg" auto "0"
		json_init
		json_load "$nodedata"
		json_get_var ipaddr vpn
		json_get_var gw vpn_gw
		[ -n "$ipaddr" ] || {
			log_net "ERR $cfg - missing ip" 
			return 1
		}
		setup_ip "$cfg" "$ipaddr" "$gw"
		json_cleanup
	fi
}

setup_ether() {
	local cfg="$1"
	local nodenumber="$2"

	config_get enabled "$cfg" enabled "0"					  
	[ "$enabled" -eq 1 ] || return 
	config_get device "$cfg" device "none"
	[ "$device" = "none" ] && return
	json_init
	json_load "$nodedata"
	json_get_var ipaddr "$device"
	[ -n "$ipaddr" ] || {
		log_net "ERR $cfg - missing ip" 
		return 1
	}
	setup_ip "$cfg" "$ipaddr"
	json_cleanup
}

preserve_ssid() {
	local cfg="$1"
	config_get device "$cfg" device
	local storedSsid
	storedSsid=$(uci_get ffwizard "$device" ap_ssid)
	[ -n "$storedSsid" ] && return
	config_get mode "$cfg" mode
	config_get network "$cfg" network
	if [ "$mode" = "ap" ] && [ "$network" != "roam" ]; then
		local ffwizardDevice
		ffWizardDevice=$(uci_get ffwizard "$device")
		if [ -z "$ffwizardDevice" ]; then
			uci_add ffwizard wifi "$device"
		fi
		config_get ssid "$cfg" ssid
		if [ -n "$ssid" ] && [ "$ssid" != "OpenWrt" ]; then
			uci_set ffwizard "$device" ap_ssid "$ssid"
		fi
	fi
}

setup_wifi() {
	local cfg="$1"
	local nodenumber="$2"
	local vap_name="$3"
	local roam_name="$4"
	local roam="$5"

	config_get enabled "$cfg" enabled "0"
	[ "$enabled" -eq 0 ] && return
	config_get idx "$cfg" idx "-1"
	[ "$idx" -ge 0 ] || return
	
	local device="radio$idx"

	local channel 
	local hwmode 
    local htmode

	hwmode=$(uci_get wireless "$device" hwmode)
	
	case $hwmode in 
		11a*)
			channel=104
		    is_ac_radio "$device" && htmode="VHT20" || htmode="HT20"
			;;
		11g)
			channel=5
			htmode="HT20"
			;;
		*)	log_wifi "ERR unknown hwmode: $hwmode"
			;;
	esac
			
    uci_set wireless "$device" htmode "$htmode" 
	uci_set wireless "$device" channel "$channel"
	uci_set wireless "$device" disabled "0"
	uci_set wireless "$device" country "DE"
	uci_add_list wireless "$device" supported_rates '12000 18000 24000 36000 48000 54000'
    uci_add_list wireless "$device" basic_rate '12000 18000 24000 36000 48000 54000'
	#uci_set wireless $device distance "1000"
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
	

	if [ "$olsr_mesh" -eq 1 ] || [ "$bat_mesh" -eq 1 ]; then
		case $hwmode in 
	    	# ibss only for 2.4ghz 
			11g)
				[ $(uci_get ffwizard settings legacy) -eq 1 ] && {
					local bssid mesh_ssid
					log_wifi "${cfg}: mesh"
					local network="${cfg}_mesh"
					uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
					uci_set wireless "$sec" device "$device"
					uci_set wireless "$sec" encryption "none"
					uci_set wireless "$sec" mode "adhoc"
					mesh_ssid=$(uci_get profile_${community} profile mesh_ssid)
					mesh_ssid=$(printf "$mesh_ssid" "$nodenumber" "$channel" | cut -c0-32)
					uci_set wireless "$sec" ssid "$mesh_ssid"
					uci_set wireless "$sec" bssid "02:CA:FF:EE:BA:BE"
					uci_set wireless "$sec" network "$network"
					uci_set wireless "$sec" mcast_rate "12000"
					json_get_var ipaddr "${device}_mesh"
					setup_ip "$network" "$ipaddr"
				}
			;;
			*)
			;;
		esac

		# 11s
		local mesh_ssid
		log_wifi "${cfg}: 11s"
		local network="${cfg}_11s"
		uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
		uci_set wireless "$sec" device "$device"
		uci_set wireless "$sec" encryption "none"
		uci_set wireless "$sec" mode "mesh"
		mesh_ssid=$(uci_get profile_${community} profile mesh_ssid)
		mesh_ssid=$(printf "$mesh_ssid" "$nodenumber" "$channel" | sed 's!mesh!11s!g' | cut -c0-32)
		uci_set wireless "$sec" ssid "$mesh_ssid"
		uci_set wireless "$sec" mesh_id 'freifunk'
		uci_set wireless "$sec" mesh_fwding '0'
		uci_set wireless "$sec" network "$network"
		uci_set wireless "$sec" mcast_rate "12000"

		json_get_var ipaddr "${device}_11s"
		setup_ip "$network" "$ipaddr"
	fi
	config_get vap "$cfg" vap "0"
	#TODO check valid interface combinations
	#iw phy$idx info | grep -A6 "valid interface combinations"
	#iw phy$idx info | grep "interface combinations are not supported"
	if [ "$vap" -eq 1 ] && \
		[ -n "$(iw phy$idx info | grep 'interface combinations are not supported')" ]  ; then
		vap="0"
		log_wifi "{cfg}: virtual ap not supported"
		#uci_set ffwizard $cfg vap "0"
	fi
	if [ "$vap" -eq 1 ] ; then
		log_wifi "${cfg}: virtual ap supported"
		uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
		uci_set wireless "$sec" device "$device"
		uci_set wireless "$sec" mode "ap"
		#uci_set wireless "$sec" mcast_rate "6000"
		#uci_set wireless "$sec" isolate 1
		uci_set wireless "$sec" network "$vap_name"
		json_get_var ipaddr wifi
		ap_ssid=$(uci_get ffwizard "$device" ap_ssid "")
		if [ -z "$ap_ssid" ]; then
			ap_ssid=$(uci_get profile_${community} profile ap_ssid)
			# fixme - hostname support
			ap_ssid=$(printf "$ap_ssid" "$nodenumber" | cut -c0-32)
		fi
		uci_set wireless "$sec" ssid "$ap_ssid"
		setup_bridge "$vap_name" "$ipaddr" "0"
	fi

    if [ "$roam" -eq 1 ]; then
        log_wifi "${cfg}: roaming ap enabled"                                                                  
        uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"                                                      
        uci_set wireless "$sec" device "$device"                                                                 
        uci_set wireless "$sec" mode "ap"                                                                        
        #uci_set wireless "$sec" mcast_rate "6000"                                                               
        uci_set wireless "$sec" isolate 1                                                                       
        uci_set wireless "$sec" network "$roam_name"                                                              
        json_get_var ipaddr roaming_block                                                                
        ssid=$(uci_get profile_${community} profile ssid)                                                
        uci_set wireless "$sec" ssid "$ssid"
		uci_set wireless "$sec" max_inactivity '5'
        uci_set wireless "$sec" max_listen_interval '128'                                                  
		setup_bridge "$roam_name" "$ipaddr" "1"   
		
	fi  
	json_cleanup
}

remove_wifi() {
	local cfg="$1"
	uci_remove wireless "$cfg" 2>/dev/null
}

remove_network() {
# delete stuff we don't need
	local cfg="$1"
	case "$cfg" in
		intercity*|wlan|wlanadhoc|wlanRADIO*)
			uci_remove network "$cfg" 2>/dev/null
		;;
	esac
}


#Remove wireless config
config_load wireless
config_foreach preserve_ssid wifi-iface
uci_commit ffwizard
config_foreach remove_wifi wifi-device
uci_commit wireless 
wifi config
uci_commit wireless
#Remove wifi ifaces	
# FIXME leave disabled iface alone	
config_load wireless	
config_foreach remove_wifi wifi-iface	
uci_commit wireless

config_load network
config_foreach remove_network interface
uci_commit network
#Setup ether and wifi
config_load ffwizard
config_get roaming settings roaming 0
config_foreach setup_ether ether "$nodenumber"
config_foreach setup_wifi wifi "$nodenumber" "vap" "roam" "$roaming" 
config_foreach setup_vpn vpn 

config_get ip6prefix ffwizard ip6prefix
if [ -n "$ip6prefix" ] ; then
	uci_set network globals ula_prefix "$ip6prefix"
fi

uci_commit network
uci_commit wireless

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
