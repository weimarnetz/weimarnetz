#!/bin/sh 

. /lib/functions.sh

uci_set freifunk community name "$(uci_get freifunk community name 'Weimar')"
uci_set freifunk community owm_api "http://mapapi.weimarnetz.de"
uci_set freifunk community mapserver "http://hopglass.weimarnetz.de"
uci_set freifunk community homepage "$(uci_get freifunk community homepage 'https://weimarnetz.de')"
uci_set freifunk community registrator "http://reg.weimarnetz.de"
