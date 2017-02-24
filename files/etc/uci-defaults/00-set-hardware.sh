#!/bin/sh

HARDWARE=""

if [ ! -s /etc/HARDWARE ]; then
	read HARDWARE < /tmp/sysinfo/model
	[ -z "$HARDWARE" ] && { 
		HARDWARE=$(grep ^machine /proc/cpuinfo | sed 's/.*: \(.*\)/\1/')
	}
	[ -z "$HARDWARE" ] && {
		if $(grep -qc ^"model name" /proc/cpuinfo); then 
			HARDWARE=$(uname -m)-$(grep ^"model name" /proc/cpuinfo | sed 's/.*: \(.*\)/\1/')
		else 
		HARDWARE=$(uname -m)-unknown
		fi
	}
	echo "$HARDWARE" > /etc/HARDWARE
fi

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
