weimarnetz
==========

* community: https://wireless.subsignal.org | https://weimarnetz.de
* monitoring: https://weimarnetz.de/uebersicht-weimarnetz/status
* documentation: [Wiki](https://wireless.subsignal.org)


Need support?
join the [club](https://weimarnetz.de).


about
-----

Weimarnetz specific OpenWrt package `weimarnetz-ffwizard`.


versions
--------

The `brauhaus` branch is the current stable version that is running on most routers (6/2022). The `master` branch is bleeding edge.


how to get a release for a specific hardware
--------------------------------------------

Use the packages repository:

https://github.com/weimarnetz/packages


how to get a release with a modified weimarnetz configuration
-------------------------------------------------------------

Modify the `Makefile` of the package:

https://github.com/weimarnetz/packages/blob/brauhaus-19.07/utils/weimarnetz-ffwizard/Makefile


Cherry Picking Git commits from forked repositories
---------------------------------------------------

* git fetch [repository url]
* git cherry-pick -x [hash]
* resolve conflicts, if any
    * git commit -ac [hash]
* git push
