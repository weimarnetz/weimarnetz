#!/bin/sh 

. /lib/functions.sh

community_name="$(uci_get freifunk community name 'Weimar')"
website="$(uci_get freifunk community homepage 'https://weimarnetz.de')"
if [ "$community_name" = "Freifunk" ]; then
  community_name="Weimar"
  website="https://weimarnetz.de"
fi

uci_set freifunk community name "$community_name"
uci_set freifunk community owm_api "http://mapapi.weimarnetz.de"
uci_set freifunk community mapserver "http://hopglass.weimarnetz.de"
uci_set freifunk community homepage "$website"
uci_set freifunk community registrator "http://reg.weimarnetz.de"
