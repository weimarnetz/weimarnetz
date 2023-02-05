#!/bin/sh 
# shellcheck disable=SC2039

. /lib/functions/network.sh

log_olsr4() {
	logger -s -t ffwizard_olsrd "$@"
}

setup_olsrbase() {
	local cfg="$1"
	uci_set olsrd "$cfg" IpVersion "4"
	uci_set olsrd "$cfg" AllowNoInt "yes"
	uci_set olsrd "$cfg" NatThreshold "0.75"
	uci_set olsrd "$cfg" LinkQualityAlgorithm "etx_ffeth"
	uci_set olsrd "$cfg" LinkQualityLevel "2"
	uci_set olsrd "$cfg" LinkQualityFishEye "1"
	uci_set olsrd "$cfg" Willingness "7"
	uci_set olsrd "$cfg" MprCoverage "7"
	uci_set olsrd "$cfg" FIBMetric "flat"
	uci_set olsrd "$cfg" TcRedundancy "2"
	uci_remove olsrd "$cfg" MainIp
}

setup_InterfaceDefaults() {
	uci_add olsrd InterfaceDefaults ; cfg="$CONFIG_SECTION"
	uci_set olsrd "$cfg" MidValidityTime "500.0"
	uci_set olsrd "$cfg" TcInterval "2.0"
	uci_set olsrd "$cfg" HnaValidityTime "125.0"
	uci_set olsrd "$cfg" HelloValidityTime "125.0"
	uci_set olsrd "$cfg" TcValidityTime "500.0"
	uci_set olsrd "$cfg" Ip4Broadcast "255.255.255.255"
	uci_set olsrd "$cfg" MidInterval "25.0"
	uci_set olsrd "$cfg" HelloInterval "3.0"
	uci_set olsrd "$cfg" HnaInterval "10.0"
}

setup_Plugin_json() {
	local cfg="$1"
	uci_set olsrd "$cfg" accept "127.0.0.1"
	uci_set olsrd "$cfg" port '9090'
	uci_set olsrd "$cfg" ignore "0"
}

setup_Plugin_txtinfo() {
	local cfg="$1"
	uci_set olsrd "$cfg" accept "127.0.0.1"
	uci_set olsrd "$cfg" port '2006'
	uci_set olsrd "$cfg" ignore "0"
}

setup_Plugin_dyn_gw() {
	local cfg="$1"
	uci_set olsrd "$cfg" CheckInterval '1000'
	uci_set olsrd "$cfg" PingInterval '5'
	#uci_set olsrd "$cfg" PingCmd "ping -c 1 -q -I wlan0 %s"
	uci_remove olsrd "$cfg" 'Ping'
	uci_add_list olsrd "$cfg" 'Ping' '1.1.1.1'
	uci_add_list olsrd "$cfg" 'Ping' '8.8.8.8'
	uci_add_list olsrd "$cfg" 'Ping' '8.8.4.4'
}

setup_Plugin_nameservice() {
	local cfg="$1"
	uci_set olsrd "$cfg" services_file "/var/etc/services.olsr.ipv4"
	uci_set olsrd "$cfg" latlon_file "/var/run/latlon.ipv4"
	uci_set olsrd "$cfg" hosts_file "/tmp/hosts/olsr.ipv4"
	uci_set olsrd "$cfg" suffix ".olsr"
	uci_set olsrd "$cfg" ignore "0"
	config_load ffwizard
	config_list_foreach "olsr" service setup_olsr_services $cfg
}

setup_olsr_services() {
	local value="$1"
	local cfg="$2"

	log_olsr4 "add olsrd service $1"
	uci_add_list olsrd "$cfg" 'service' "$value"
}

setup_Plugin_watchdog() {
	local cfg="$1"
	uci_set olsrd $cfg file "/var/run/olsrd.watchdog.ipv4"
	uci_set olsrd $cfg interval "5"
	uci_set olsrd $cfg ignore "0"
}


setup_Plugins() {
	local cfg="$1"
	config_get library "$cfg" library
	case "$library" in
		*json* )
			setup_Plugin_json "$cfg"
		;;
		*dyn_gw*)
			setup_Plugin_dyn_gw "$cfg"
		;;
		*arprefresh*)
			:
		;;
		*txtinfo*)
			setup_Plugin_txtinfo "$cfg"
		;;
		*watchdog*)
			setup_Plugin_watchdog "$cfg"
		;;
		*nameservice*)
			setup_Plugin_nameservice "$cfg"
		;;
		*)
			uci_set olsrd "$cfg" ignore "1"
		;;
	esac
}

setup_ether() {
	local cfg="$1"
	local nodenumber="$2"

	config_get enabled "$cfg" enabled "0"
	[ "$enabled" -eq 0 ] && return
	config_get olsr_mesh "$cfg" olsr_mesh "0"
	log_olsr4 "$cfg $enabled"
	[ "$olsr_mesh" -eq 0 ] && return
	
	log_olsr4 "setup_ether: $cfg $device"
	[ -z "$device" ] && return
	log_olsr4 "Setup ether $cfg"
	uci_add olsrd Interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd "$iface_sec" interface "$cfg"
	uci_set olsrd "$iface_sec" ignore "0"
	# only with LinkQualityAlgorithm=etx_ffeth
	uci_set olsrd "$iface_sec" Mode "ether"
	# only with LinkQualityAlgorithm=etx_ff
	#uci_set olsrd "$iface_sec" Mode "mesh"
	olsr_enabled=1
}

setup_wifi() {
	local cfg="$1"
	local nodenumber="$2"

	config_get enabled "$cfg" enabled "0"
	[ "$enabled" -eq 0 ] && return
	config_get olsr_mesh "$cfg" olsr_mesh "0"
	log_olsr4 "$cfg $enabled"
	[ "$olsr_mesh" -eq 0 ] && return
	config_get idx "$cfg" idx "-1"
	[ "$idx" -eq "-1" ] && return

	log_olsr4 "Setup wifi $cfg"
	uci_add olsrd Interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd "$iface_sec" interface "radio${idx}_11s"
	uci_set olsrd "$iface_sec" ignore "0"
	uci_set olsrd "$iface_sec" Mode "mesh"
	olsr_enabled=1
}

setup_hna4() {
	local ipaddr="$1"

	[ -n "$ipaddr" ] || return

	eval "$(ipcalc.sh "$ipaddr")"
	uci_add olsrd Hna4 ; hna_sec="$CONFIG_SECTION"
	uci_set olsrd "$hna_sec" netmask "$NETMASK"
	uci_set olsrd "$hna_sec" netaddr "$NETWORK"
}

setup_custom_hna4() {
	local config="$1"
	config_get custom_netaddr "$config" netaddr "empty"
	config_get custom_netmask "$config" netmask "empty"
	if [ "$custom_netaddr" = "empty" ] || [ "$custom_netmask" = "empty" ]; then
		return
	fi
	log_olsr4 "custom hna config for $custom_netaddr/$custom_netmask"
	uci_add olsrd Hna4
	section="$CONFIG_SECTION"
	uci_set olsrd "$section" netaddr "$custom_netaddr"
	uci_set olsrd "$section" netmask "$custom_netmask"
}

remove_section() {
	local cfg="$1"
	uci_remove olsrd "$cfg"
}

#Load olsrd config
config_load olsrd
#Remove InterfaceDefaults
config_foreach remove_section InterfaceDefaults
#Remove Interface
config_foreach remove_section Interface
#Remove Hna's
config_foreach remove_section Hna4
#Remove Plugin Config
config_foreach remove_section LoadPlugin 

olsr_enabled=0

#Setup ether and wifi
config_load ffwizard
config_get nodenumber settings nodenumber
config_foreach setup_ether ether "$nodenumber"
config_foreach setup_wifi wifi "$nodenumber"

# setup hna4 
json_init
json_load "$nodedata"
json_get_var node_net node_net

setup_hna4 "$node_net"

json_cleanup

config_foreach setup_custom_hna4 hna4

if [ "$olsr_enabled" -eq 1 ] ; then
	#If olsrd is disabled then start olsrd before write config
	#read new olsrd config via ubus call uci "reload_config" in ffwizard
	if ! [ "$(find /etc/rc.d/S*olsrd)" ]; then
		/etc/init.d/olsrd enable
		/etc/init.d/olsrd restart
	fi
	#Setup olsrd
	config_load olsrd
	config_foreach setup_olsrbase olsrd
	#Setup InterfaceDefaults
	setup_InterfaceDefaults
	
	#Setup Plugin or disable
	plugins=$(find /usr/lib -name "olsrd_*so*" -exec basename {} \;) 

	for p in $plugins; do
		uci_add olsrd LoadPlugin ; sec="$CONFIG_SECTION"
		uci_set olsrd "$sec" library "${p%%.*}"
	done
	# fixme - looks wrong
	uci_commit olsrd
	config_load olsrd
	config_foreach setup_Plugins LoadPlugin
	uci_commit olsrd
else
	uci revert olsrd
	if [ "$(find /etc/rc.d/S*olsrd)" ]; then
		/etc/init.d/olsrd stop
		/etc/init.d/olsrd disable
	fi
fi

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
