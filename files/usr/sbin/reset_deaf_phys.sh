#!/bin/sh
# checks for deaf interfaces and brings them up, only if there are associated stations

[ $(cut -d '.' -f1 /proc/uptime) -gt 600 ] || return 

for num in 0 1; do
    if [ -d /sys/kernel/debug/ieee80211/phy$num/netdev\:wlan$num ]; then
        logger "deaf_phys: checking wlan$num status..."
        neighs=$(ls -ld /sys/kernel/debug/ieee80211/phy$num/netdev\:wlan$num/stations/* 2>/dev/null | wc -l)
        if [ $neighs == 0 ]; then
            logger "deaf_phys: triggering wlan$num scan..."
            iw wlan$num scan
        else
            logger "deaf_phys: wlan$num has $neighs neighbors."
        fi
    fi
done

