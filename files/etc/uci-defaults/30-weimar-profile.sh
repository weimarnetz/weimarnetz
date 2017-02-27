#!/bin/sh 

uci -m import profile_weimar <<EOF
config community 'profile'
	option 'name' 'Weimarnetz e.V.'
	option 'homepage' 'http://www.weimarnetz.de'
	option 'ssid' 'weimar.freifunk.net'
	option 'mesh_network' '10.63.0.0/16'
	option 'latitude' '50.989530'
	option 'longitude' '11.338675'
EOF
