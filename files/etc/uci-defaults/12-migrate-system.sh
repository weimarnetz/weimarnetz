#!/bin/sh

. /lib/functions.sh 

config_cb() {
    local type="$1"
    local name="$2"
    case "$type" in
	profile) 
        	option_cb() {                                            
            		local option="$1" 
            		local value="$2" 
			uci_set meshnode settings "$option" "$value"
        	}
		uci_remove system profile
	;;
	system)
		option_cb() {
			local option="$1"
			local value="$2"
			[ "$option" = "hostname" ] && {
				uci_set meshnode settings hostname "$value"
			}
		}
		uci_remove system noswinstall 
	;;
        weblogin|monitoring|fwupdate|admin|vpn)  
                uci_remove system "$type"
        ;;
    	*) 
        	option_cb() { return; }
	;;
	esac
}

config_load system

uci_commit

