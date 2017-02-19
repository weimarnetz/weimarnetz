#!/bin/sh 

uci -m import meshnode << -EOF
config public 'community'
	option name 'weimar'
	option nodenumber ''
	option ipschema 'ffweimar'
	option wifimode 'hybrid'

config public 'contact'
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
	option mesh 'olsr'

config wifi 'radio0' 
	option enabled '1'
	option mesh  'olsr'

config wifi 'radio1' 
	option enabled '1'
	option mesh  'olsr' 

config wifi 'roaming'
	option enabled '1' 


config monitoring 'monitoring'
        option url 'http://intercity-vpn.de/networks/ffweimar'

EOF
