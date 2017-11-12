#!/bin/sh

log() {
        logger -s -t network.sh: "$@"
}

net_http_get()
{
	local funcname='net_http_get'
	local url="$1"
	local max="${2:-15}"	# maximal running time [sec]

	# log $funcname "max ${max}s, ${#url} bytes, wget -qO - '$url'"
	timeout $max wget -qO - "$url" 
}

net_dns2ip4()
{
	local dns="$1"
	local go

	# set -- $( nslookup host86-139-31-49.range86-139.btcentralplus.com )
	# Server: 127.0.0.1 Address 1: 127.0.0.1 localhost Name: host86-139-31-49.range86-139.btcentralplus.com Address 1: 86.139.31.49 host86-139-31-49.range86-139.btcentralplus.com
	set -- $( nslookup "$dns" || echo 'ERROR ERROR' )

	while shift; do {
		case "$1" in
			'ERROR'|'')
				return 1
			;;
			'Name:')
				go='true'
			;;
			'Address:'|'Address')
				[ "$go" = 'true' ] || continue

				# 'Address 1: 84.38.67.43'
				# 'Address 1: 2a02:2e0:3fe:100::8 redirector.heise.de'
				# 'Address 2: 193.99.144.80 redirector.heise.de'
				# 'Address:    193.99.144.80'	// spaces on kernel 2.4
				[ "$1" = 'Address' ] && shift
				shift

				case "$1" in
					*':'*)
						# ignore IPv6
					;;
					*)
						echo "$1"
						return 0
					;;
				esac
			;;
		esac
	} done
}


net_get_rxtx()
{
	local dev="$1"
	local line

	while read -r line; do {
		set -- $line

		case "$1" in
			"$dev:")
				echo "bytes_rx=$2;bytes_tx=${10};"
				return
			;;
		esac
	} done <'/proc/net/dev'
}

net_tcp_port_reachable()
{					
	local funcname='net_tcp_port_reachable'
	local server="$1"		# e.g. 127.0.0.1
	local port="$2"			# e.g. 80

	# we can't rely on '-w3' or '-z' because of lobotomized busybox netcat
	timeout 5 echo "foo" | nc "$server" "$port" 1>/dev/null 2>/dev/null || return 1 
}

net_ping_getlatency()
{
	local server="$1"	# e.g. <ip> or <host>
	local pings="${2:-3}"

	# round-trip min/avg/max = 24.638/24.638/24.638 ms	// busybox
	# or:					   ^^^^^^^^^^^^^^^^^^^^
	# 3 packets transmitted, 0 packets received, 100% packet loss
	#						^^^
	# rtt min/avg/max/mdev = 33.415/33.415/33.415/0.000 ms	// debian
	# or: <empty>
	set -- $( ping -q -c${pings} -W1 "$server" 2>/dev/null | tail -n1 )

	# bad return on error
	test -n "$4" -a "$4" != '0' &&	{
		# round-trip min/avg/max = 15.887/24.931/42.406 ms
		# -> 15.887/24.931/42.406 -> 15 887 24 931 42 406
		local oldIFS="$IFS"; IFS='[/.]'; set -- $4; IFS="$oldIFS"

		# output 'average' round trip time: 24.931 -> 24
		echo "$3"
	}
}

net_local_inet_offer()			
{	
	local funcname='net_local_inet_offer'
	local gw=''

	. /lib/functions/network.sh
	network_flush_cache
	network_get_gateway gw 'wan' 0
	test -z "$gw" 
}

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
