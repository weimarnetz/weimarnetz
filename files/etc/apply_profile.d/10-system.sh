#!/bin/sh -x
# shellcheck disable=SC2039

log() {
	logger -s -t apply_profile system "$@"
}

setup_system() {
	local cfg="$1"
	
	if [ -z "$hostname" ] || [ "$hostname" = "LEDE" ] ; then
		config_get hostname "$cfg" hostname "$hostname"
		log "No custom Hostname! Get sys Hostname $hostname"
	fi
	if [ -z "$hostname" ] || [ "$hostname" = "LEDE" ] ; then
		hostname="weimarnetz-$nodenumber"
		uci_set system "$cfg" hostname "$hostname"
	else
		log "Set Hostname $hostname"
		uci_set system "$cfg" hostname "$hostname"
	fi

	# Set Timezone
	uci_set system "$cfg" zonename "Europe/Berlin"
	uci_set system "$cfg" timezone "CET-1CEST,M3.5.0,M10.5.0/3"

	# Set Location
	if [ -n "$location" ] ; then
		uci_set system "$cfg" location "$location"
	fi
	# Set Geo Location
	if [ -n "$latitude" ] ; then
		uci_set system "$cfg" latitude "$latitude"
	fi
	if [ -n "$longitude" ] ; then
		uci_set system "$cfg" longitude "$longitude"
	fi
}

config_load meshnode 
config_get hostname settings hostname "LEDE"
config_get nodenumber settings nodenumber

# Set lat lon
config_get location settings location
config_get latitude settings latitude
config_get longitude settings longitude


config_load system
#Setup system hostname,timezone,location,latlon
config_foreach setup_system system

#Save
uci_commit system

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
