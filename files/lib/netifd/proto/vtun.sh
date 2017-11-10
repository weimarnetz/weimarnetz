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
        config_get ipaddr     "${config}" "ipaddr"
	config_get netmask    "${config}" "netmask"
        config_get mtu        "${config}" "mtu"
        # config_get fwmark   "${config}" "fwmark"
        config_get gateway    "${config}" "gateway"
	config_get server     "${config}" "server"
	config_get port       "${config}" "port"

	[ -n "$server" ] || {                                                  
                proto_notify_error "$config" "server missing"                        
                proto_block_restart "$config"                                            
        }
         
	port=${port:-5001}
	mtu=${mtu:-1280}

	for ip in $(resolveip -4 -t 10 "$server"); do
		logger -t "vtun-${config}" "adding host dependency for $ip at $config"
		proto_add_host_dependency "$config" "$ip"
	done

	nodenumber=$(uci_get ffwizard settings nodenumber -1)
	[ "$nodenumber" -lt 0 ] || {
		proto_notify_error "$config" "NODENUMBER_MISSING"
		proto_block_restart "$config"
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
	local config="$1"
	local rand
	local count 
	rand=$(tr -dc '1-65000' </dev/urandom | head -c 1)
	rand=$(expr $rand % $count + 1)

}

generate_vtun_conf() {
	local config="$1"
	local nodenumber="$3"

cat <<- EOF > /var/run/vtun-${config}.conf
	Node${nodenumber} {
		passwd ff;
		type ether;	
		persist no;
		timeout 5;
		up { program "/lib/netifd/vtun-up config=${config} dev=%% address=${ipaddr} netmask=${netmask} gw=${gateway} mtu=${mtu}" ; };
		down { program "/lib/netifd/vtund-down config=${config} dev=%% " ; };
	}
	EOF
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol vtun 
}
