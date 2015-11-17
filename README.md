kalua - build mesh-networks _without_ pain
==========================================

* community: http://wireless.subsignal.org
* monitoring: http://intercity-vpn.de/networks/dhfleesensee/
* documentation: [API](http://wireless.subsignal.org/index.php?title=Firmware-Dokumentation_API)


Need support?
join the [club](http://www.weimarnetz.de) or ask for [consulting](http://bittorf-wireless.de)

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=weimarnetz&url=https://github.com/weimarnetz/weimarnetz&title=weimarnetz&language=&tags=github&category=software)

Important!
----------

> Don't forget to set the variables $REPONAME and $REPOURL as global variables (export VARIABLE=VALUE) before you start playing here. REPONAME is the directory where you checked out REPOURL.
> E.g. REPONAME could be set to weimarnetz and REPOURL to git://github.com/weimarnetz/weimarnetz.git

how to get a release for a specific hardware
--------------------------------------------

for building this firmware yourself please see our builder at https://github.com/weimarnetz/builder


Cherry Picking Git commits from forked repositories
---------------------------------------------------

* git fetch [repository url]
* git cherry-pick -x [hash]
* resolve conflicts, if any
    * git commit -ac [hash]
* git push
