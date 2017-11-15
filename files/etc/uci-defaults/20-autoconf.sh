#!/bin/sh 

uci set ffwizard.settings.firstboot=1
uci set ffwizard.settings.enabled=1
uci commit
