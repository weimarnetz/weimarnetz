#!/bin/sh 
# shellcheck disable=SC2039
test -f /etc/crontabs/root || touch /etc/crontabs/root
crontab -l | grep -q "/usr/sbin/vpnwatchdog" || crontab -l | { cat; echo "*/5 * * * *	/usr/sbin/vpnwatchdog"; } | crontab -
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
