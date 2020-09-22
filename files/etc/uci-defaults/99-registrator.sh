#!/bin/sh 
# shellcheck disable=SC2039
test -f /etc/crontabs/root || touch /etc/crontabs/root
SEED="$( dd if=/dev/urandom bs=2 count=1 2>&- | hexdump | if read line; then echo 0x${line#* }; fi )"
MIN="$(( $SEED % 59 ))"
crontab -l | grep -q "/usr/sbin/registrator heartbeat" || crontab -l | { cat; echo "$MIN * * * *	/usr/sbin/registrator heartbeat"; } | crontab -
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
