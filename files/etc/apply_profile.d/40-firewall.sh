
uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

log_fw() {
	logger -s -t ffwizard_fw $@
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_br $cfg dhcp_br "0"
	[ "$dhcp_br" == "0" ] || return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	log_fw "Setup ether $cfg"
	ff_ifaces="$device $ff_ifaces"
	case $cfg in
		lan) lan_iface="";;
		wan) wan_iface="";;
	esac
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get idx $cfg phy_idx "-1"
	[ "$idx" == "-1" ] && return
	local device="radio"$idx"_mesh"
	log_fw "Setup wifi $cfg"
	ff_ifaces="$device $ff_ifaces"
}

zone_iface_add() {
	local cfg="$1"
	local zone="$2"
	local networks="$3"
	config_get name $cfg name

	if [ "$name" == "$zone" ] ; then
		for network in $networks ; do
			uci_add_list firewall "$cfg" network $network
		done
	fi
}

zone_iface_del() {
	local cfg="$1"
	local zone="$2"
	config_get name $cfg name

	if [ "$name" == "$zone" ] ; then
		uci_remove firewall "$cfg" network 2>/dev/null
	fi
}

local br_name="fflandhcp"
local ff_ifaces=""
local lan_iface="lan"
local wan_iface="wan wan6"

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

#Add Bridge interface to Zone freifunk
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	ff_ifaces="$br_name $ff_ifaces"
fi

#Add interfaces to Zone freifunk
config_load firewall
config_foreach zone_iface_del zone "freifunk"
config_foreach zone_iface_add zone "freifunk" "$ff_ifaces"
#Add interface lan to Zone lan if not an freifunk interface
config_foreach zone_iface_del zone "lan"
if [ -n "$lan_iface" ] ; then
	config_foreach zone_iface_add zone "lan" "$lan_iface"
fi

#Add interface wan to Zone wan if not an freifunk interface
config_foreach zone_iface_del zone "wan"
if [ -n "$wan_iface" ] ; then
	config_foreach zone_iface_add zone "wan" "$wan_iface"
fi

uci_commit firewall
