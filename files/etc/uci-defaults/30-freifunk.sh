#!/bin/sh 

. /lib/functions.sh

uci_set freifunk community name "Weimar"
uci_set freifunk community owm_api "http://mapapi.weimarnetz.de"
uci_set freifunk community mapserver "http://map.weimarnetz.de"
uci_set freifunk community homepage "http://weimarnetz.de"
uci_set freifunk community registrator "http://reg.weimarnetz.de"
