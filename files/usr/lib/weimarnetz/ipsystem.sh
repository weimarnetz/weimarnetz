#!/bin/sh

. /usr/share/libubox/jshn.sh

# return the interface ip + range
# use with ipcalc.sh to get broadcast / net
node2nets_json()
{
	local nodenumber="$1"
	local city="${2:-63}"
	local network="${3:-10}"
	local range_start="${4:-2}"
	local range_end="${5:-1020}"

	local oct1 oct2 oct3 oct4

	json_init
	# a typical node 16:
	# all:	10.63.16.0	/26  (=  0...64)

	if [ "$nodenumber" -ge "$range_start" -a "$nodenumber" -le "$range_end" ]; then
		s="0" # subnetstart   e.g. network.city.100.${S}
		n="$nodenumber" # nodenumber_id e.g. network.city.${N}.0
		if [ "$nodenumber" -gt 765 ]; then
			n=$(( nodenumber - 765 ))
			s=192
		elif [ "$nodenumber" -gt 510 ]; then
			n=$(( nodenumber - 510 ))
			s=128
		elif [ "$nodenumber" -gt 255 ]; then
			n=$(( nodenumber - 255 ))
			s=64
		fi
		json_add_string "node_net" "$network.$city.$n.$((s+1))/26"
		json_add_string "wifi" "$network.$city.$n.$((s+1))/27"
		json_add_string "lan" "$network.$city.$n.$((s+32+1))/28"
		json_add_string "radio0_mesh" "$network.$city.$n.$((s+48))/32"
		json_add_string "radio1_mesh" "$network.$city.$n.$((s+49))/32"
		json_add_string "radio0_11s" "$network.$city.$n.$((s+50))/32"
		json_add_string "radio1_11s" "$network.$city.$n.$((s+51))/32"
		json_add_string "vpn" "$network.$city.$n.$((s+58))/30"
		json_add_string "vpn_gw" "$network.$city.$n.$((s+57))"
		json_add_string "vpn_ip" "$network.$city.$n.$((s+62))/16"
		local roamingnet="$(__calc_roaming_net $nodenumber)"
		json_add_string "roaming_block" "100.64.0.1/10"
		json_add_string "roaming_net" "$roamingnet"
		json_add_string "roaming_gw" "100.64.0.1"
		json_add_string "roaming_dhcp_offset" "$(__dhcp_offset $roamingnet)"
		json_dump
	else
		return 1
	fi
}

__calc_roaming_net() {
	local nodenumber="$1"
	local i=2
	local o2=64
	local o3=""

	while [ $i -lt 1024 ]; do		# each node has it's own uniq /24 DHCP-range
		o2=$(( o2 + 1 ))		# which must be valid across the whole network
		for o3 in $(seq 0 255);do
			test "$nodenumber" = "$i" && break 2
			i=$(( i + 1 ))
		done
	done
	echo "100.$o2.$o3.0/24"
}

__dhcp_offset() {

awk -f - "$*" <<EOF

function ip2int(ip) {
	for (ret=0,n=split(ip,a,"\."),x=1;x<=n;x++) ret=or(lshift(ret,8),a[x])
	return ret
}

BEGIN {
	print ip2int(ARGV[1])-ip2int("100.64.0.1")
}
EOF
}
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
