
#remove https certs
#set new common name
#generate new certs with uhttpd restart


get_hostname() {
	local cfg="$1"
	config_get sys_hostname $cfg hostname "$sys_hostname"
}


local sys_hostname

#Load system config
config_load system
#Setup dnsmasq
config_foreach get_hostname system

#Load uhttpd config
config_load uhttpd
config_get cn_hostname px5g commonname
if [ "$cn_hostname" != "$sys_hostname" ] ; then
	config_get crtfile main cert
	config_get keyfile main key
	[ -f "$crtfile" ] && rm -f "$crtfile"
	[ -f "$keyfile" ] && rm -f "$keyfile"
	uci_set uhttpd px5g commonname "$hostname"
	uci_commit uhttpd
fi

[ -s /www/index.html ] || ln -s /www/luci2.html /www/index.html
