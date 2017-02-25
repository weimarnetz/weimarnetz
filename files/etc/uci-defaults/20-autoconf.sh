#!/bin/sh 

uci set meshnode.settings.firstboot=1
uci set meshnode.settings.enabled=1
uci commit
