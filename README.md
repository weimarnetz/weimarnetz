kalua - build mesh-networks _without_ pain
==========================================

* community: http://wireless.subsignal.org | http://weimarnetz.de
* monitoring: http://weimarnetz.de/monitoring
* documentation: [API](http://wireless.subsignal.org/index.php?title=Firmware-Dokumentation_API)


Need support?
join the [club](http://www.weimarnetz.de) or ask for [consulting](http://bittorf-wireless.de)

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=weimarnetz&url=https://github.com/weimarnetz/weimarnetz&title=weimarnetz&language=&tags=github&category=software)

versions
--------

The `GebrannteMandeln` branch is the current stable version that is running on most routers at the moment (1/2017). The master `branch` is bleeding edge at the moment and should work with LEDE.


how to get a release for a specific hardware
--------------------------------------------

for building this firmware yourself please see our builder at https://github.com/weimarnetz/builder or use the new build code here: https://gitlab.bau-ha.us/weimarnetz/firmware

Bleeding Edge Images with LEDE and the current master branch can be found here: http://weimarnetz.segfault.gq/firmwares/ 


Cherry Picking Git commits from forked repositories
---------------------------------------------------

* git fetch [repository url]
* git cherry-pick -x [hash]
* resolve conflicts, if any
    * git commit -ac [hash]
* git push
