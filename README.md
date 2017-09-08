weimarnetz
==========

* community: http://wireless.subsignal.org | https://weimarnetz.de
* monitoring: http://weimarnetz.de/monitoring
* documentation: [Wiki](https://github.com/weimarnetz/weimarnetz/wiki)


Need support?
join the [club](http://www.weimarnetz.de) or ask for [consulting](http://bittorf-wireless.de)

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=weimarnetz&url=https://github.com/weimarnetz/weimarnetz&title=weimarnetz&language=&tags=github&category=software)

versions
--------

The `GebrannteMandeln` branch is the current stable version that is running on most routers (1/2017). The `master` branch is bleeding edge at the moment and should work with LEDE.


how to get a release for a specific hardware
--------------------------------------------

https://gitlab.bau-ha.us/weimarnetz/firmware

Bleeding Edge Images with LEDE and the current master branch can be found here: http://weimarnetz.segfault.gq/firmwares/ 


Cherry Picking Git commits from forked repositories
---------------------------------------------------

* git fetch [repository url]
* git cherry-pick -x [hash]
* resolve conflicts, if any
    * git commit -ac [hash]
* git push
