#!/bin/sh

[ -x /usr/sbin/vtund ] || exit 1

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/network.sh
	. /lib/netifd/netifd-proto.sh
	init_proto "$@"
}

proto_vtun_init_config() {
	no_device=1
	available=1	
	proto_config_add_defaults
}

proto_vtun_setup() {
	local config="$1"

	# load configuration
	config_load network
        config_get addresses     "${config}" "ipaddr"
        config_get mtu           "${config}" "mtu"
        config_get fwmark        "${config}" "fwmark"
        config_get gateway 	    "${config}" "gateway"

	server=3.v.weimarnetz.de
	port=5001
	ifname=tap0
	mtu=1280	

	logger -t "vtun-${config}" "initializing... vtun-${config} $iface"

	for ip in $(resolveip -4 -t 10 "$server"); do
		logger -t "vtun-${config}" "adding host dependency for $ip at $config"
		proto_add_host_dependency "$config" "$ip"
	done

	nodenumber=$(uci_get ffwizard settings nodenumber -1)
	[ "$nodenumber" -lt 0 ] || {
		proto_notify_error "$cfg" "NODENUMBER_MISSING"
		proto_block_restart "$cfg"
	}
	nodeconfig="Node${nodenumber}"

	generate_vtun_conf "$config" "$ifname" "$nodenumber"
	logger -t "vtun-${config}" "executing vtun"

	proto_run_command "$config" /usr/sbin/vtund -n \
		-f /var/run/vtun-${config}.conf \
		-P "$port" "$nodeconfig" "$ip"
}

proto_vtun_teardown() {
	proto_kill_command "$interface"
	return
}

probe_vtun_serverlist() {
	# todo
	local cfg="$1"
	local rand
	local count 
	rand=$(tr -dc '1-65000' </dev/urandom | head -c 1)
	rand=$(expr $rand % $count + 1)

}

generate_vtun_conf() {
	local cfg="$1"
	local nodenumber="$3"

cat <<- EOF > /var/run/vtun-${cfg}.conf
	Node${nodenumber} {
		passwd ff;
		type ether;	
		persist no;
		up { program "/lib/netifd/vtun-up config=${cfg} dev=%% addresses=${addresses} gw=${gateway} mtu=${mtu}" ; };
		down { program "/lib/netifd/vtund-down config=${cfg} dev=%% addresses=${addresses} gw=${gateway} mtu=${mtu}" ; };
	}
	EOF
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol vtun 
}
