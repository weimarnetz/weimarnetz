#!/bin/sh

[ -x /usr/sbin/vtund ] || exit 1

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/network.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

proto_vtun-ffwe_init_config() {
	available=1
	no_device=1
	proto_config_add_string "ifname"
	proto_config_add_defaults
}

proto_vtun-ffwe_setup() {
	local config="$1"

	json_get_vars server port random probe mtu

	logger -t "vpn-ffwe" "initializing..."
	logger -t "vpn-ffwe" "adding host dependency for $server at $config"

	for ip in $(resolveip -t 10 "$server"); do
		logger -t "vpn-ffwe" "adding host dependency for $ip at $config"
		proto_add_host_dependency "$config" "$ip"
	done

	logger -t "vpn-ffwe" "executing vtun"

	proto_run_command "$cfg" /usr/sbin/vtund -n \ 
		-f "/var/run/vtund-${cfg}" \
		"$nodeconfig" \
		"$server" 

proto_vtun-ffwe_teardown() {
	local cfg="$1"
	proto_kill_command "$cfg"
}

probe_vtun-ffwe_serverlist() {
	# todo
	local cfg="$1"
	local rand
	local count 
	rand=$(tr -dc '1-65000' </dev/urandom | head -c 1)
	rand=$(expr $rand % $count + 1)

}

generate_vtun-ffwe_conf() {
	local cfg="$1"
	local nodenumber="$2"

cat <<- EOF > /var/run/vtun-${cfg}.conf
	Node${nodenumber} {
		passwd ff;
		type ether;	
		persist yes;
		}
	EOF
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol vtun-ffwe 
}
