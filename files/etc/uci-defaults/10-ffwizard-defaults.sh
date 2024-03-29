#!/bin/sh 

. /lib/functions.sh 

uci -m import ffwizard < /dev/null
uci_add ffwizard node "settings"

uci_set ffwizard settings ipschema "$(uci_get ffwizard settings ipschema 'ffweimar')"
uci_set ffwizard settings restrict "$(uci_get ffwizard settings restrict '1')"
uci_set ffwizard settings blockWanPort "$(uci_get ffwizard settings block_wan_port '0')"
uci_set ffwizard settings ipv6 "$(uci_get ffwizard settings ipv6 '0')"
uci_set ffwizard settings ipv6prefix "$(uci_get ffwizard settings ipv6prefix 'fd42:7ceb:f2ff::/48')"
uci_remove ffwizard settings roaming
uci_remove ffwizard settings legacy
uci_commit ffwizard

# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
