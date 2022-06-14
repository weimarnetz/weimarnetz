#!/bin/sh 

for FILE in /rom/etc/config/profile*; do
	NAME=$(echo "$FILE"|awk -F/ '{print $NF}')
	uci -f "$FILE" import "$NAME"
done

uci commit
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
