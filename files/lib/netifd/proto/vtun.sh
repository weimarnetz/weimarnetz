#!/bin/sh

[ -x /usr/sbin/vtund ] || exit 1

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/network.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

proto_vtun_init_config() {
	available=1
	no_device=1
	proto_config_add_string "ifname"
	proto_config_add_defaults
}

proto_vtun_setup() {
	local config="$1"
	local iface="$2"

	local ifname $PROTO_DEFAULT_OPTIONS
	json_get_vars ifname server port random probe mtu $PROTO_DEFAULT_OPTIONS

	server=3.v.weimarnetz.de
	port=5001
	ifname=tap0	

	logger -t "vtun-${config}" "initializing..."

	for ip in $(resolveip -4 -t 10 "$server"); do
		logger -t "vtun-${config}" "adding host dependency for $ip at $config"
		proto_add_host_dependency "$config" "$ip"
	done

	logger -t "vtun-${config}"
	nodenumber=$(uci_get ffwizard settings nodenumber -1)
	[ "$nodenumber" -gt 0 ] || {
		proto_notify_error "$cfg" "NODENUMBER_MISSING"
		proto_block_restart "$cfg"
	}
	nodeconfig="Node${nodenumber}"

	generate_vtun_conf "$config" "$ifname" "$nodenumber"
	logger -t "vtun-${config}" "executing vtun"

	proto_run_command "$config" /usr/sbin/vtund \
		-f /var/run/vtun-${config}.conf \
		-P "$port" "$nodeconfig" "$ip"
}

proto_vtun_teardown() {
	local cfg="$1"
	proto_kill_command "$cfg"
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
	local ifname="$2"
	local nodenumber="$3"

cat <<- EOF > /var/run/vtun-${cfg}.conf
	Node${nodenumber} {
		passwd ff;
		type ether;	
		persist yes;
		device ${ifname};
		up { program "/lib/netifd/vtun-up %d" ; };
		down { program "/lib/netifd/vtund-down %d" ; };
		}
	EOF
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol vtun 
}
