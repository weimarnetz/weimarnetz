#!/bin/sh
# shellcheck disable=SC2154 disable=SC2039 disable=SC2034
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
	autostart=0
	proto_config_add_defaults
}

proto_vtun_setup() {
	local config="$1"
	json_get_vars $PROTO_DEFAULT_OPTIONS

	# load configuration
	config_load network
	config_get ipaddr	  "$config" "ipaddr"
	config_get netmask	  "$config" "netmask"
	config_get gateway	  "$config" "gateway"
	
	nodenumber=$(uci -q get ffwizard.settings.nodenumber)						  
	[ -n "$nodenumber" ] || {													  
		proto_notify_error "$config" "nodenumber is missing!"				  
		proto_block_restart "$config"
		return 1										 
	}			  
	
	json=$(config_foreach probe_vtun_endpoints "vtun_${config}")
	[ -n "$json" ] || {
		proto_notify_error "$config" "could not get server json data"
	}
																								
	json_load "$json" 2>/dev/null													  
	json_get_var server server															
	json_get_var port port_vtun_nossl_nolzo																 
	json_get_var mtu maxmtu																
	for ip in $(resolveip -4 -t 10 "$server"); do
		proto_add_host_dependency "$config" "$ip"
	done

	nodeconfig="Node${nodenumber}"
	generate_vtun_conf "$config" "$nodeconfig"

	proto_run_command "$config" /usr/sbin/vtund -n \
		-f "/var/run/vtun-${config}.conf" \
		-P "$port" "$nodeconfig" "$ip"
}

proto_vtun_teardown() {
	local config="$1"
	proto_kill_command "$config"
	return
}

probe_vtun_endpoints() {
	section="$1"
	config_get endpoints "$section" endpoint
	[ -n "$endpoints" ] || { 
		proto_notify_error "$config" "no valid endpoint found!"
		proto_block_restart "$config" 
		return 1
	}

	. /usr/lib/weimarnetz/network.sh

	count=0
	for e in $endpoints
	do
		json="$(net_http_get "http://$e/freifunk/vpn")"
		json_load "$json" 2>/dev/null
		json_get_var server server
		json_get_var port port_vtun_nossl_nolzo
		json_cleanup
		if net_tcp_port_reachable "$server" "$port"; then
			c="$c $e"
			count=$((count+1))
		fi
	done 

	if [ "$count" -gt 0 ]; then
		rand=$(tr -dc 1-"$count" </dev/urandom 2>/dev/null| head -c1)
		final=$(echo "$c" | awk '{$1=$1};1' | cut -d" " -f"$rand")
		json="$(net_http_get "http://$final/freifunk/vpn")"
		json_load "$json" 2>/dev/null
		json_dump
	fi
}

generate_vtun_conf() {
	local config="$1"
	local nodenumber="$2"

cat <<- EOF > "/var/run/vtun-${config}.conf"
	$nodeconfig {
		passwd ff;
		type ether;	
		persist no;
		timeout 5;
		keepalive 15:2;
		up { program "/lib/netifd/vtun-up config=${config} dev=%% address=${ipaddr} netmask=${netmask} gw=${gateway} mtu=${mtu} server=${server} port=${port}" wait; };
		down { program "/lib/netifd/vtun-down config=${config} dev=%% " wait; };
	}
	EOF
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol vtun 
}

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :