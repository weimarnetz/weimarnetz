#!/bin/sh
# shellcheck disable=SC2039

grep -q "weimarnetz_anonym" /etc/iproute2/rt_tables || echo "50 weimarnetz_anonym" >> /etc/iproute2/rt_tables
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
