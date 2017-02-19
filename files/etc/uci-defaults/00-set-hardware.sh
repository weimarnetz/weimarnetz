#!/bin/sh

if [ ! -s /etc/HARDWARE ]; then
    read HARDWARE < /tmp/sysinfo/model
    [ -z "$HARDWARE" ] && { 
        HARDWARE=$(grep ^machine /proc/cpuinfo | sed 's/.*: \(.*\)/\1/')
    }
    [ -z "$HARDWARE" ] && { 
         HARDWARE="unknown-$( uname -m )" 
    }
    echo "$HARDWARE" > /etc/HARDWARE
fi
