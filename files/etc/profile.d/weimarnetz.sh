#!/bin/sh
# shellcheck disable=SC2039

[ -e '/etc/variables_fff+' ] && . '/etc/variables_fff+'
[ -n "$FFF_VERSION" ] && { 
	echo ".oo/ weimarnetz $FFF_VERSION (${FFF_SOURCE_URL#*://})"
	echo '/[]. Welcome!'
	echo ''
}

nmeter_cmd() {
 . /lib/functions/network.sh 
 local cmd='%t %20c '
 for dev in vap radio0_mesh radio1_mesh lan wan; do
	network_get_physdev physdev "$dev"
	[ -n "$physdev" ] && cmd="$cmd ${physdev}: %[n$physdev]"
 done
 cmd="$cmd ctx: %x mem: %m"
 echo $cmd
}

check_weak_passwd() 
{

	command -V mkpasswd > /dev/null || return 

	salt=$(awk -F"$" '/^root/ { print $3}' < /etc/shadow)
	pass=admin
	weakhash=$(mkpasswd -S "$salt" "$pass") 
	hash=$(awk -F":" '/^root/ { print $2}' < /etc/shadow)
	[ "$weakhash" = "$hash" ] && { 
		echo "!!!! Weak default password! Please change the password with 'passwd' now!"
	}
}

prompt_set()
{
	face()
	{
		local rc=$?

		case "$rc" in
			0) printf '%s' "$1" ;;
			*) printf '%s' "$2" ; return $rc ;;
		esac
	}

	local e='\[\e'			# start escape-sequence
	local c='\]'			# close escape-sequence

	local user='\u'
	local wdir='\w'			# workdir
	local host='\h'			# short form

	local reset="${e}[0m${c}"	# all attributes
	local white="${e}[37m${c}"
	local cyan="${e}[36m${c}"
	local yellow="${e}[33;1m${c}"	# bold
	local green="${e}[32m${c}"
	local red="${e}[31m${c}"

	local ok="${green}:)"
	local bad="${red}8("

	# e.g. user@hostname:~ :)
	export PS1="${cyan}${user}$white@${green}$host:${yellow}$wdir \$( face '$ok' '$bad' ) $reset"
}

prompt_set

if command -V neigh.sh >/dev/null; then
	alias n='neigh.sh 2>/dev/null'

	if command -V nmeter >/dev/null; then
	echo '.... type nm for live cpu/memory/traffic stats'
	alias nm="nmeter \"$(nmeter_cmd)\""
fi
alias n2='echo /nhdpinfo link | nc 127.0.0.1 2009'
alias ll='ls -la'
alias lr='logread'
alias myssh='ssh -i $( _ssh key_public_fingerprint_get keyfilename )'
alias dropshell='echo >>$SCHEDULER_IMPORTANT "/etc/init.d/dropbear stop"; killall dropbear'

read -r LOAD <'/proc/loadavg'
case "$LOAD" in
	'0'*)
	;;
	*)
		echo "!!!! high load: $(uptime)"
	;;
esac
unset LOAD

read -r UP REST <'/proc/uptime'
UP="${UP%.*}"
case "${#UP}" in 1|2|3) echo "!!!! low uptime: $UP sec";; esac
unset UP REST

case "$USER" in
	'root'|'')
		check_weak_passwd

		grep -qs ^'root:\$' '/etc/shadow' || {
			echo "ERR! unset password, use 'passwd'"
		}
	;;
esac

echo
echo ".... hardware: $HARDWARE"
echo ".... type _ for an overview of available commands"

if [ -e '/tmp/REBOOT_REASON' ]; then
	# see system_crashreboot()
	read -r CRASH <'/tmp/REBOOT_REASON'
	[ -e '/tmp/loader' ] && . /tmp/loader
	_system include

	case "$CRASH" in
		'nocrash'|'nightly_reboot'|'apply_profile'|'wifimac_safed')
			CRASH="$( _system reboots )"

			test ${CRASH:-0} -gt 50 && {
				echo "!!!! detected $CRASH reboots since last update - please check"
			}
		;;
		*)
			UNIXTIME=$( date +%s )
			UPTIME=$( _system uptime sec )
			printf '\n%s' "!!!! last reboot unusual @ $( date -d @$(( UNIXTIME - UPTIME )) ) - "

			if [ -e '/sys/kernel/debug/crashlog' ]; then
				printf '%s\n\n' "was: $CRASH, see with: cat /sys/kernel/debug/crashlog"
			else
				printf '%s\n\n' "was: $CRASH"
			fi
		;;
	esac

	unset CRASH UNIXTIME UPTIME
fi
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
