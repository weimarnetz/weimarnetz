
uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

log_dhcp() {
	logger -s -t ffwizard_dhcp $@
}

setup_dhcp() {
		local cfg_dhcp="$1"
		local ipaddr="$2"
		if uci_get dhcp $cfg_dhcp >/dev/null ; then
			uci_remove dhcp $cfg_dhcp
		fi
		uci_add dhcp dhcp $cfg_dhcp
		uci_set dhcp $cfg_dhcp interface "$cfg_dhcp"
		uci_set dhcp $cfg_dhcp ignore "0"
		if [ -n "$ipaddr" ] ; then
			eval "$(ipcalc.sh $ipaddr)"
			OCTET_4="${NETWORK##*.}"
			OCTET_1_3="${NETWORK%.*}"
			OCTET_4="$((OCTET_4 + 2))"
			start_ipaddr="$OCTET_4"
			uci_set dhcp $cfg_dhcp start "$start_ipaddr"
			limit=$(($((2**$((32-$PREFIX))))-2))
			uci_set dhcp $cfg_dhcp limit "$limit"
		fi
		uci_set dhcp $cfg_dhcp leasetime "15m"
		uci_add_list dhcp $cfg_dhcp dhcp_option "119,olsr,lan,p2p"
		uci_add_list dhcp $cfg_dhcp domain "olsr"
		uci_add_list dhcp $cfg_dhcp domain "lan"
		uci_add_list dhcp $cfg_dhcp domain "p2p"
		uci_set dhcp $cfg_dhcp dhcpv6 "server"
		uci_set dhcp $cfg_dhcp ra "server"
		uci_set dhcp $cfg_dhcp ra_preference "low"
		uci_set dhcp $cfg_dhcp ra_default "1"
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_ip $cfg dhcp_ip "0"
	cfg_dhcp=$cfg"_dhcp"
	uci_remove dhcp $cfg_dhcp 2>/dev/null
	if [ "$dhcp_ip" != "0" ] ; then
		log_dhcp "Setup $cfg"
		setup_dhcp $cfg_dhcp "$dhcp_ip"
	else
		config_get dhcp_br $cfg dhcp_br "0"
		config_get mesh_ip $cfg mesh_ip "0"
		if [ "$cfg" == "lan" ] && [ "$mesh_ip" == "0" ] && [ "$dhcp_br" == "0" ] ; then
			log_dhcp "Setup iface $cfg to default"
			uci_set dhcp $cfg ignore "0"
			uci_add_list dhcp $cfg dhcp_option "119,olsr,lan,p2p"
			uci_add_list dhcp $cfg domain "olsr"
			uci_add_list dhcp $cfg domain "lan"
			uci_add_list dhcp $cfg domain "p2p"
			uci_set dhcp $cfg dhcpv6 "server"
			uci_set dhcp $cfg ra "server"
			uci_set dhcp $cfg ra_preference "low"
			uci_set dhcp $cfg ra_default "1"
		else
			uci_set dhcp $cfg ignore "1"
			uci_set dhcp $cfg dhcpv6 "disabled"
			uci_set dhcp $cfg ra "disabled"
		fi
	fi
	case $cfg in
		lan) lan_iface="";;
		wan) wan_iface="";;
	esac
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_ip $cfg dhcp_ip "0"
	cfg_dhcp=$cfg"_vap"
	uci_remove dhcp $cfg_dhcp 2>/dev/null
	if [ "$dhcp_ip" != "0" ] ; then
		log_dhcp "Setup $cfg with $dhcp_ip"
		setup_dhcp $cfg_dhcp "$dhcp_ip"
	fi
}

setup_dhcpbase() {
	local cfg="$1"
	uci_set dhcp $cfg local "/olsr/"
	uci_set dhcp $cfg domain "olsr"
}

setup_odhcpbase() {
	local cfg="$1"
	#uci_set dhcp $cfg maindhcp "1"
	uci_set dhcp $cfg maindhcp "0"
}

local br_name="fflandhcp"
local lan_iface="lan"
local wan_iface="wan"
#Load dhcp config
config_load dhcp
#Setup dnsmasq
config_foreach setup_dhcpbase dnsmasq

#Setup odhcpd
config_foreach setup_odhcpbase odhcpd

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

#Setup DHCP Batman Bridge
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	config_get dhcp_ip ffwizard dhcp_ip
	log_dhcp "Setup iface $br_name with ip $dhcp_ip"
	setup_dhcp $br_name $dhcp_ip
else
	if uci_get dhcp $br_name >/dev/null ; then
		log_dhcp "Setup $br_name remove"
		uci_remove dhcp $br_name 2>/dev/null
	fi
fi


#Enable dhcp on LAN
if [ -n "$lan_iface" ] ; then
	log_dhcp "Setup iface $lan_iface to default"
	uci_set dhcp $cfg ignore "0"
	uci_set dhcp $lan_iface start "100"
	uci_set dhcp $lan_iface limit "150"
	uci_set dhcp $lan_iface leasetime "12h"
	uci_add_list dhcp $cfg_dhcp dhcp_option "119,olsr,lan,p2p"
	uci_add_list dhcp $cfg_dhcp domain "olsr"
	uci_add_list dhcp $cfg_dhcp domain "lan"
	uci_add_list dhcp $cfg_dhcp domain "p2p"
	uci_set dhcp $lan_iface dhcpv6 "server"
	uci_set dhcp $lan_iface ra "server"
fi

#Disable dhcp on WAN
if [ -n "$wan_iface" ] ; then
	log_dhcp "Setup iface $wan_iface to default"
	uci_set dhcp $wan_iface ignore "1"
	uci_set dhcp $wan_iface dhcpv6 "disabled"
	uci_set dhcp $wan_iface ra "disabled"
fi

uci_commit dhcp
