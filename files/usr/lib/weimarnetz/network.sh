#!/bin/sh
# shellcheck disable=SC2039

net_http_get()
{
	local url="$1"
	local max="${2:-15}"	# maximal running time [sec]

	# log $funcname "max ${max}s, ${#url} bytes, wget -qO - '$url'"
	timeout "$max" wget -qO - "$url" 
}

net_tcp_port_reachable()
{					
	local server="$1"		# e.g. 127.0.0.1
	local port="$2"			# e.g. 80

	# we can't rely on '-w3' or '-z' because of lobotomized busybox netcat
	timeout 5 echo "foo" | nc "$server" "$port" 1>/dev/null 2>/dev/null || return 1 
}

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
