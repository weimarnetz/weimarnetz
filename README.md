weimarnetz
==========

* community: https://wireless.subsignal.org | https://weimarnetz.de
* monitoring: https://weimarnetz.de/uebersicht-weimarnetz/status
* documentation: [Wiki](https://wireless.subsignal.org)


Need support?
join the [club](https://www.weimarnetz.de).


buildbot
--------

current builds can be found here: 

http://buildbot.weimarnetz.de/builds/



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
