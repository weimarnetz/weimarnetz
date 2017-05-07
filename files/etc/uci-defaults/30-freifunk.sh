#!/bin/sh 

. /lib/functions.sh

uci -m import profile_Weimar <<EOF
config community 'profile'
	option 'name' 'Weimarnetz e.V.'
	option 'homepage' 'http://www.weimarnetz.de'
	option 'ssid' 'weimar.freifunk.net'
	option 'mesh_network' '10.63.0.0/16'
	option 'latitude' '50.989530'
	option 'longitude' '11.338675'
EOF


uci_set freifunk community "public"
uci_set freifunk community name "Weimar"
uci_set freifunk community owm_api "http://mapapi.weimarnetz.de"
uci_set freifunk community mapserver "http://map.weimarnetz.de"
uci_set freifunk community homepage "http://weimarnetz.de"
uci_set freifunk community registrator "http://reg.weimarnetz.de"
