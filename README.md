weimarnetz
==========

* community: https://wireless.subsignal.org | https://weimarnetz.de
* monitoring: https://weimarnetz.de/monitoring
* documentation: [Wiki](https://github.com/weimarnetz/weimarnetz/wiki)


Need support?
join the [club](http://www.weimarnetz.de).

versions
--------

The `GebrannteMandeln` branch is the current stable version that is running on most routers (9/2017). The `master` branch is bleeding edge.


how to get a release for a specific hardware
--------------------------------------------

Use the firmware builder: 

https://github.com/weimarnetz/firmware


Cherry Picking Git commits from forked repositories
---------------------------------------------------

* git fetch [repository url]
* git cherry-pick -x [hash]
* resolve conflicts, if any
    * git commit -ac [hash]
* git push
