#!/bin/sh 

uci -m import ffwizard <<EOF
config node 'settings'
	option hostname ''
	option nodenumber '-1'
	option ipschema 'ffweimar'
	option roaming '0'
	option ipv6 '0'
	option ip6prefix 'fd42:7ceb:f2ff::/48'
	option location ''
	option latitude ''
	option longitutde ''

EOF
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
