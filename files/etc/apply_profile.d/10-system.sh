
log_system() {
	logger -s -t apply_profile system $@
}

setup_system() {
	local cfg=$1
	
	if [ -z "$hostname" ] || [ "$hostname" == "LEDE" ] ; then
		config_get hostname $cfg hostname "$hostname"
		log_system "No custom Hostname! Get sys Hostname $hostname"
	fi
	if [ -z "$hostname" ] || [ "$hostname" == "LEDE" ] ; then
		rand="$(echo -n $(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1-4))"
		rand="$(printf "%d" "0x$rand")"
		hostname="$hostname-$rand"
		log_system "No valid Hostname! Set rand Hostname $hostname"
		uci_set system $cfg hostname "$hostname"
	else
		log_system "Set Hostname $hostname"
		uci_set system $cfg hostname "$hostname"
	fi

	# Set Timezone
	uci_set system $cfg zonename "Europe/Berlin"
	uci_set system $cfg timezone "CET-1CEST,M3.5.0,M10.5.0/3"

	# Set Location
	if [ -n "$location" ] ; then
		uci_set system $cfg location "$location"
	fi
	# Set Geo Location
	if [ -n "$latitude" ] ; then
		uci_set system $cfg latitude "$latitude"
	fi
	if [ -n "$longitude" ] ; then
		uci_set system $cfg longitude "$longitude"
	fi
}

#Load ffwizard config
config_load meshnode 

# Set Hostname
config_get hostname ffwizard hostname "LEDE"

# Set lat lon
config_get location ffwizard location
config_get latitude ffwizard latitude
config_get longitude ffwizard longitude


config_load system
#Setup system hostname,timezone,location,latlon
config_foreach setup_system system

#Save
uci_commit system
