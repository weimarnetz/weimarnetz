#!/bin/sh
# shellcheck disable=SC2039

[ -e '/etc/variables_fff+' ] && . '/etc/variables_fff+'
[ -n "$FFF_VERSION" ] && { 
echo "::: weimarnetz $FFF_VERSION (${FFF_SOURCE_URL#*://})"
echo '::: Welcome \o/'

check_weak_passwd() 
{

	command -V mkpasswd > /dev/null || return 

	salt=$(awk -F"$" '/^root/ { print $3}' < /etc/shadow)
	pass=admin
	weakhash=$(mkpasswd -S "$salt" "$pass") 
	hash=$(awk -F":" '/^root/ { print $2}' < /etc/shadow)
	[ "$weakhash" = "$hash" ] && { 
		echo "ATT Weak default password! Please change the password with 'passwd' now!"
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

case "$PS1" in
	*' face '*)
		return 0
	;;
esac

prompt_set

alias n='_olsr txtinfo'
alias n2='echo /nhdpinfo link | nc 127.0.0.1 2009'
alias ll='ls -la'
alias lr='logread'
alias flush='_system ram_free flush'
alias myssh='ssh -i $( _ssh key_public_fingerprint_get keyfilename )'
alias regen='_ rebuild; _(){ false;}; . /tmp/loader'
alias dropshell='echo >>$SCHEDULER_IMPORTANT "/etc/init.d/dropbear stop"; killall dropbear'

read -r LOAD <'/proc/loadavg'
case "$LOAD" in
	'0'*)
	;;
	*)
		echo 'ATT high load:'
		uptime
	;;
esac
unset LOAD

read -r UP REST <'/proc/uptime'
UP="${UP%.*}"
case "${#UP}" in 1|2|3) echo "[ATT] low uptime: $UP sec";; esac
unset UP REST

case "$USER" in
	'root'|'')
		check_weak_passwd

		grep -qs ^'root:\$' '/etc/shadow' || {
			echo "ERR unset password, use 'passwd'"
		}
	;;
esac

_ t 2>/dev/null || {
	[ -e '/tmp/loader' ] && {
		# http://unix.stackexchange.com/questions/82347/how-to-check-if-a-user-can-access-a-given-file
		. '/tmp/loader'		# TODO: avoid "no permission" on debian user-X-session

		echo
		echo "::: hardware: $HARDWARE" 
		echo "::: type _ for an overview of available commands"
	}
}

if [ -e '/tmp/REBOOT_REASON' ]; then
	# see system_crashreboot()
	read -r CRASH <'/tmp/REBOOT_REASON'
	[ -e '/tmp/loader' ] && . /tmp/loader
	_system include

	case "$CRASH" in
		'nocrash'|'nightly_reboot'|'apply_profile'|'wifimac_safed')
			CRASH="$( _system reboots )"

			test ${CRASH:-0} -gt 50 && {
				echo "ATT detected $CRASH reboots since last update - please check"
			}
		;;
		*)
			UNIXTIME=$( date +%s )
			UPTIME=$( _system uptime sec )
			printf '\n%s' "ATT last reboot unusual @ $( date -d @$(( UNIXTIME - UPTIME )) ) - "

			if [ -e '/sys/kernel/debug/crashlog' ]; then
				printf '%s\n\n' "ATT was: $CRASH, see with: cat /sys/kernel/debug/crashlog"
			else
				printf '%s\n\n' "ATT was: $CRASH"
			fi
		;;
	esac

	unset CRASH UNIXTIME UPTIME
fi
# vim: set filetype=sh ai noet ts=4 sw=4 sts=4 :
