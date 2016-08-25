#!/bin/sh 
# make opkg work on system with 32mb 
# see: https://github.com/lede-project/source/issues/237#issuecomment-242476551
#      http://cgit.openembedded.org/openembedded/plain/recipes/opkg/files/opkg_use_vfork_gunzip.patch
export OPKG_USE_VFORK=1 


