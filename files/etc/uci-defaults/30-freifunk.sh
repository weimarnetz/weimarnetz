#!/bin/sh 

. /lib/functions.sh

uci -m import profile_Weimar <<EOF
config community 'profile'
	option 'name' 'Weimar'
	option 'homepage' 'http://www.weimarnetz.de'
	option 'ssid' 'Weimarnetz.Freifunk'
	option 'mesh_ssid' 'mesh.%d.ch%d.weimarnetz.de'
	option 'ap_ssid' 'weimarnetz.de | %s' 
	option 'mesh_network' '10.63.0.0/16'
	option 'latitude' '50.989530'
	option 'longitude' '11.338675'
EOF

uci -m import profile_Camburg <<EOF
config community 'profile'
        option 'name' 'Camburg'
        option 'homepage' 'http://camburg.freifunk.net'
        option 'ssid' 'Camburg.Freifunk'
        option 'mesh_ssid' 'mesh.%d.ch%d.camburg.ff'
        option 'ap_ssid 'Freifunk Camburg | %s'
        option 'mesh_network' '10.63.0.0/16'
        option 'latitude' '51.053889'
        option 'longitude' '11.7075'
EOF


uci_set freifunk community name "Weimar"
uci_set freifunk community owm_api "http://mapapi.weimarnetz.de"
uci_set freifunk community mapserver "http://map.weimarnetz.de"
uci_set freifunk community homepage "http://weimarnetz.de"
uci_set freifunk community registrator "http://reg.weimarnetz.de"
