#!/bin/sh 

uci -m import meshnode <<EOF
config node 'settings'
	option hostname ''
	option nodenumber ''
	option ipschema 'ffweimar'
	option wifimode 'hybrid'
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

config ether 'lan' 
	option enabled '1'
	option olsr_mesh '1' 

config ether 'wan'
	option restrict '1'

config wifi 'radio0'
	option idx '0'
	option enabled '1'
	option vap '1'
	option roaming '1'
	option olsr_mesh '1'

config wifi 'radio1'
        option idx '1'
	option enabled '1'
	option vap '1'
	option roaming '1'
	option olsr_mesh '1' 
EOF
