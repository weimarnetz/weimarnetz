#!/bin/sh
# shellcheck disable=SC2039

log_system() {
	logger -s -t ffwizard_system "$@"
}

setup_boot() {
	/etc/init.d/cron enable
	/etc/init.d/cron start
}

setup_sysctl()
{
  
	mem=$(awk '/MemTotal/ { print $2}' < /proc/meminfo)
	min_free=$(sysctl -n vm.min_free_kbytes)
	[ "$mem" -lt 32768 ] && min_free=128

	# http://www.kernel.org/doc/Documentation/sysctl/kernel.txt
	# http://www.kernel.org/doc/Documentation/sysctl/vm.txt
	# /proc/sys/vm/panic_on_oom = 2
	# /proc/sys/kernel/panic_on_oops = 1
	# /proc/sys/kernel/panic = 10
	
	for entry in 'vm.panic_on_oom=1' \
			'kernel.panic_on_oops=1' \
			'kernel.panic_on_warn=1' \
			'kernel.panic_on_rcu_stall=1' \
			'kernel.panic=10' \
			"vm.min_free_kbytes=$min_free"; do {
		sysctl -w "$entry" >/dev/null
		grep -q ^"$entry"$ '/etc/sysctl.conf' || {
			echo "$entry" >>'/etc/sysctl.conf'
		}
	} done
	sysctl -qp 2> /dev/null
	
}

setup_system() {
	local cfg="$1"
	
	if [ -z "$hostname" ] || [ "$hostname" = "LEDE" -o "$hostname" = "OpenWrt" ] ; then
		config_get hostname "$cfg" hostname "$hostname"
		log_system "No custom hostname! Using $hostname"
	fi
	random_hostname=$(echo $hostname | grep -E '^ff.*-[0-9]{4}-random-[a-zA-Z]{4}') # contains the hostname if it is build with a random node number, else it is empty
	if [ -z "$hostname" ] || [ "$hostname" = "LEDE" -o "$hostname" = "OpenWrt"  -o "$hostname" = "$random_hostname" ] ; then
		if [ "$nodenumber" -gt 1001 ] ; then
			random_string=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4)
			hostname=$(echo "ff${community}" | tr '[:upper:]' '[:lower:]')-$nodenumber-random-$random_string
		else
			hostname=$(echo "ff${community}" | tr '[:upper:]' '[:lower:]')-$nodenumber 
		fi
		uci_set system "$cfg" hostname "$hostname"
	else
		log_system "Using $hostname"
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

config_load ffwizard 
config_get hostname settings hostname "OpenWrt"
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

# sysctl settings
setup_sysctl
setup_boot

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
