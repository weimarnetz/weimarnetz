#!/bin/sh 
# shellcheck disable=SC2039
test -f /etc/crontabs/root || touch /etc/crontabs/root
SEEDMIN="$( dd if=/dev/urandom bs=2 count=1 2>&- | hexdump | if read line; then echo 0x${line#* }; fi )"
SEEDDAY="$( dd if=/dev/urandom bs=2 count=1 2>&- | hexdump | if read line; then echo 0x${line#* }; fi )"
MIN="$(( $SEEDMIN % 59 ))"
DAY="$(( $SEEDDAY % 59 ))"
crontab -l | grep -q "/sbin/reboot" || crontab -l | { cat; echo "$MIN 3 $DAY * *	/sbin/reboot"; } | crontab -
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
