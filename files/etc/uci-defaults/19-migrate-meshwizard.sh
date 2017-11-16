#!/bin/sh 
# shellcheck disable=SC2039

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
			uci_set system system "$option" "$value"
		}
	;;
	public)
		case "$name" in 
			community)
				option_cb() {
					local option="$1"
					local value="$2"
					uci_set ffwizard node "$option" "$value"
					uci_set freifunk community "$option" "$value"
				}
			;;
			contact)
				option_cb() {
					local option="$1"
					local value="$2"
					uci_set freifunk contact "$option" "$value"
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

uci_remove meshwizard
uci commit

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
