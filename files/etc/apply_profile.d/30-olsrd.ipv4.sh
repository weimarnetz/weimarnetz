
log_olsr4() {
	logger -s -t ffwizard_olsrd $@
}

setup_olsrbase() {
	local cfg="$1"
	uci_set olsrd $cfg IpVersion "4"
	uci_set olsrd $cfg AllowNoInt "yes"
	uci_set olsrd $cfg NatThreshold "0.75"
	uci_set olsrd $cfg LinkQualityAlgorithm "etx_ff"
	uci_set olsrd $cfg FIBMetric "flat"
	uci_set olsrd $cfg TcRedundancy "2"
	uci_set olsrd $cfg Pollrate "0.025"
}

setup_InterfaceDefaults() {
	uci_add olsrd InterfaceDefaults ; cfg="$CONFIG_SECTION"
	uci_set olsrd $cfg MidValidityTime "500.0"
	uci_set olsrd $cfg TcInterval "2.0"
	uci_set olsrd $cfg HnaValidityTime "125.0"
	uci_set olsrd $cfg HelloValidityTime "125.0"
	uci_set olsrd $cfg TcValidityTime "500.0"
	uci_set olsrd $cfg Ip4Broadcast "255.255.255.255"
	uci_set olsrd $cfg MidInterval "25.0"
	uci_set olsrd $cfg HelloInterval "3.0"
	uci_set olsrd $cfg HnaInterval "10.0"
}

setup_Plugin_json() {
	local cfg="$1"
	uci_set olsrd $cfg accept "127.0.0.1"
	uci_set olsrd $cfg ignore "0"
}

setup_Plugin_watchdog() {
	local cfg="$1"
	uci_set olsrd $cfg file "/var/run/olsrd.watchdog.ipv4"
	uci_set olsrd $cfg interval "30"
	uci_set olsrd $cfg ignore "1"
}
setup_Plugin_nameservice() {
	local cfg="$1"
	uci_set olsrd $cfg services_file "/var/etc/services.olsr.ipv4"
	uci_set olsrd $cfg latlon_file "/var/run/latlon.js.ipv4"
	uci_set olsrd $cfg hosts_file "/tmp/hosts/olsr.ipv4"
	uci_set olsrd $cfg suffix ".olsr"
	uci_set olsrd $cfg ignore "0"
}

setup_Plugins() {
	local cfg="$1"
	config_get library $cfg library
	case $library in
		*json* )
			setup_Plugin_json $cfg
			olsr_json=1
		;;
		*watchdog*)
			setup_Plugin_watchdog $cfg
			olsr_watchdog=1
		;;
		*nameservice*)
			setup_Plugin_nameservice $cfg
			olsr_nameservice=1
		;;
		*)
			uci_set olsrd $cfg ignore "1"
		;;
	esac
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_br $cfg dhcp_br "0"
	[ "$dhcp_br" == "0" ] || return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get mesh_ip $cfg mesh_ip "0"
	[ "$mesh_ip" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	log_olsr4 "Setup ether $cfg"
	uci_add olsrd Interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd "$iface_sec" interface "$device"
	uci_set olsrd "$iface_sec" ignore "0"
	# only with LinkQualityAlgorithm=etx_ffeth
	#uci_set olsrd "$iface_sec" Mode "ether"
	# only with LinkQualityAlgorithm=etx_ff
	uci_set olsrd "$iface_sec" Mode "mesh"
	olsr_enabled=1
	config_get ipaddr $cfg dhcp_ip 0
	if [ "$ipaddr" != 0 ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		uci_add olsrd Hna4 ; hna_sec="$CONFIG_SECTION"
		uci_set olsrd "$hna_sec" netmask "$NETMASK"
		uci_set olsrd "$hna_sec" netaddr "$NETWORK"
	fi
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get mesh_ip $cfg mesh_ip "0"
	[ "$mesh_ip" == "0" ] && return
	config_get idx $cfg phy_idx "-1"
	[ "$idx" == "-1" ] && return
	local device="radio"$idx"_mesh"
	log_olsr4 "Setup wifi $cfg"
	uci_add olsrd Interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd "$iface_sec" interface "$device"
	uci_set olsrd "$iface_sec" ignore "0"
	#Shoud be mesh with LinkQualityAlgorithm=etx_ffeth
	#and LinkQualityAlgorithm=etx_ff
	uci_set olsrd "$iface_sec" Mode "mesh"
	olsr_enabled=1
	config_get ipaddr $cfg dhcp_ip 0
	if [ "$ipaddr" != 0 ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		uci_add olsrd Hna4 ; hna_sec="$CONFIG_SECTION"
		uci_set olsrd "$hna_sec" netmask "$NETMASK"
		uci_set olsrd "$hna_sec" netaddr "$NETWORK"
	fi
}

remove_section() {
	local cfg="$1"
	uci_remove olsrd $cfg
}

#Load olsrd6 config
config_load olsrd
#Remove InterfaceDefaults
config_foreach remove_section InterfaceDefaults
#Remove Interface
config_foreach remove_section Interface
#Remove Hna's
config_foreach remove_section Hna4

local olsr_enabled=0
local olsr_json=0
local olsr_watchdog=0
local olsr_nameservice=0

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	config_get ipaddr ffwizard dhcp_ip "0"
	if [ "$ipaddr" != 0 ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		uci_add olsrd Hna4 ; hna_sec="$CONFIG_SECTION"
		uci_set olsrd "$hna_sec" netmask "$NETMASK"
		uci_set olsrd "$hna_sec" netaddr "$NETWORK"
	fi
fi

if [ "$olsr_enabled" == "1" ] ; then
	#If olsrd is disabled then start olsrd before write config
	#read new olsrd config via ubus call uci "reload_config" in ffwizard
	if ! [ -s /etc/rc.d/S*olsrd ] ; then
		/etc/init.d/olsrd enable
		/etc/init.d/olsrd restart
	fi
	#Setup olsrd
	config_load olsrd
	config_foreach setup_olsrbase olsrd
	#Setup InterfaceDefaults
	setup_InterfaceDefaults
	#Setup Plugin or disable
	config_foreach setup_Plugins LoadPlugin
	if [ "$olsr_json" == 0 -a -n "$(opkg status olsrd-mod-jsoninfo)" ] ; then
		library="$(find /usr/lib/olsrd_jsoninfo.so* | cut -d '/' -f 4)"
		uci_add olsrd LoadPlugin ; sec="$CONFIG_SECTION"
		uci_set olsrd "$sec" library "$library"
		setup_Plugin_json $sec
	fi
	if [ "$olsr_watchdog" == 0 -a -n "$(opkg status olsrd-mod-watchdog)" ] ; then
		library="$(find /usr/lib/olsrd_watchdog.so* | cut -d '/' -f 4)"
		uci_add olsrd LoadPlugin ; sec="$CONFIG_SECTION"
		uci_set olsrd "$sec" library "$library"
		setup_Plugin_watchdog $sec
	fi
	if [ "$olsr_nameservice" == 0 -a -n "$(opkg status olsrd-mod-nameservice)" ] ; then
		library="$(find /usr/lib/olsrd_nameservice.so* | cut -d '/' -f 4)"
		uci_add olsrd LoadPlugin ; sec="$CONFIG_SECTION"
		uci_set olsrd "$sec" library "$library"
		setup_Plugin_nameservice $sec
		crontab -l | grep -q 'dnsmasq' || crontab -l | { cat; echo '* * * * * killall -HUP dnsmasq'; } | crontab -
	fi
	#TODO remove it from freifunk-common luci package
	crontab -l | grep -q 'ff_olsr_watchdog' && crontab -l | sed -e '/.*ff_olsr_watchdog.*/d' | crontab -
	uci_commit olsrd
else
	/sbin/uci revert olsrd
	if [ -s /etc/rc.d/S*olsrd ] ; then
		/etc/init.d/olsrd stop
		/etc/init.d/olsrd disable
	fi
fi
