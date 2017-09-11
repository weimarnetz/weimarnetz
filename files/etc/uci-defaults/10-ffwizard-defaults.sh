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

config node 'contact'
	option nickname ''
	option name ''
	list homepage ''
	option mail ''
	option phone ''
	option note ''

config vpn 'vpn'
	option type 'vtun'
	option domain 'weimarnetz.de'
	option prefix 'v'
	option jsonpath '/freifunk/vpn/'
	option proto 'olsr'
	option disabled '0'
	option lan_vpn '1'
EOF
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
