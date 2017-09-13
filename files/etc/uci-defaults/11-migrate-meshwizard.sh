#!/bin/sh 

. /lib/functions.sh 

config_cb() {
    local type="$1"
    local name="$2"
    case "$type" in
	system)
		option_cb() {
			local option="$1"
			local value="$2"
			uci_set ffwizard settings "$option" "$value"
		}
	;;
	public)
		case "$name" in 
			community)
				option_cb() {
					local option="$1"
					local value="$2"
					uci_set ffwizard node "$option" "$value"
				}
			;;
			*)
				option_cb() { return; }
			;;
		esac
	;;
	*)
		option_cb() { return; }
	;;
	esac
}

config_load meshwizard || return 0
uci commit
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
