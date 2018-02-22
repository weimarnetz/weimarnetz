#!/bin/sh 

uci -m import ffwizard <<EOF
config node 'settings'
	option ipschema 'ffweimar'
	option roaming '1'
	option ipv6 '0'
	option ip6prefix 'fd42:7ceb:f2ff::/48'

EOF
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
