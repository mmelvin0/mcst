#!/bin/sh


# config

[ -f /etc/default/minecraft ] && . /etc/default/minecraft

[ -z "$MC_DIR"      ] && MC_DIR=
[ -z "$MC_JAR"      ] && MC_JAR=minecraft_server.jar
[ -z "$MC_JAVA"     ] && MC_JAVA=java
[ -z "$MC_JAVA_OPT" ] && MC_JAVA_OPT='-Xms1024M -Xmx1024M'
[ -z "$MC_NAME"     ] && MC_NAME=minecraft
[ -z "$MC_TIMEOUT"  ] && MC_TIMEOUT=10
[ -z "$MC_USER"     ] && MC_USER=


# globals

MC_LOG="$MC_DIR/server.log"
MC_LOG_MARK=0
MC_PID=


# functions

##
# mark the current line in the server log
mc_log_mark () {
	MC_LOG_MARK=$(cat "$MC_DIR/server.log" | wc -l)
	return $?
}

##
# wait until the server log (since the last mark) matches a filter program
# @param filter program to apply to the log lines (eg. grep)
# @return 0 when the log matches, 1 if it doesn't or the process dies
mc_log_seek () {
	local tries=0 lines=0
	while true; do
		lines=$(expr $(cat "$MC_LOG" | wc -l) - $MC_LOG_MARK)
		tail -n$lines "$MC_LOG" | "$@" > /dev/null 2>&1
		[ $? -eq 0 ] && return  0
		mc_pid || return 1
		tries=$(expr $tries + 1)
		[ $tries -gt $MC_TIMEOUT ] && return 1
		sleep 1
	done
}

##
# fetch the pid of the screen process that owns the minecraft server process
# @return 0 if $MC_PID is valid, 1 otherwise
mc_pid () {
	local temp
	temp=$(screen -ls | egrep '^[[:space:]]+[[:digit:]]+\.' | fgrep "$MC_NAME")
	if [ $? -eq 0 ]; then
		MC_PID=$(echo $temp | head -n1 | awk 'BEGIN { FS = "." } { print $1 }')
		return 0
	else
		MC_PID=
		return 1
	fi
}

##
# wait until the pid goes away, according to mc_pid
# @return 0 when pid goes away, 1 on timeout
mc_pid_wait () {
	local tries=0
	while true; do
		if mc_pid; then
			tries=$(expr $tries + 1)
			if [ $tries -gt $MC_TIMEOUT ]; then
				return 1
			else
				sleep 1
			fi
		else
			return 0
		fi
	done
}


# main

# check if we are supposed to run the server as another user than ourselves
# to do this, you must run this script as root, or as that user
# if you don't want to do this, set MC_USER to an empty string
if [ -n "$MC_USER" -a "$(id -un)" != "$MC_USER" ]; then
	if [ "$(id -u)" = 0 ]; then
		dir="$(cd $(dirname $0) && pwd)"
		exec su "$MC_USER" -c "$0 $@"
	else
		echo "$MC_NAME: you are not authorized"
		exit 1
	fi
fi

# simply do not proceed beyond this point if we are still root
if [ "$(id -u)" = 0 ]; then
	echo "$MC_NAME: cowardly refusing to run as root"
	exit 1
fi

# unless the user is looking for help, we need MC_DIR defined now
if [ -n "$1" ] && [ -z "$MC_DIR" -o ! -d "$MC_DIR" ]; then
	echo "$MC_NAME: MC_DIR not configured correctly"
	exit 1
fi

# action handlers
case "$1" in

start)
	cd "$MC_DIR"
	if mc_pid; then
		echo "$MC_NAME: already running"
		exit 0
	else
		printf "$MC_NAME: starting... "
		mc_log_mark
		screen -dmS "$MC_NAME" "$MC_JAVA" $MC_JAVA_OPT -jar "$MC_JAR"
		if mc_log_seek egrep 'Done \([[:digit:]]+ns\)!'; then
			echo ok
			exit 0
		else
			echo 'fail!'
			exit 1
		fi
	fi
;;

stop)
	if mc_pid; then
		printf "$MC_NAME: stopping... "
		screen -S "$MC_NAME" -p 0 -X stuff "$(printf 'stop\r')"
		if mc_pid_wait; then
			echo ok
			exit 0
		else
			echo 'fail!'
			exit 1
		fi
	else
		echo "$MC_NAME: not running"
		exit 0
	fi
;;

restart)
	mc_pid && "$0" stop
	"$0" start
	exit $?
;;

status)
	if mc_pid; then
		echo "$MC_NAME: pid $MC_PID"
		exit 0
	else
		echo "$MC_NAME: not running"
		exit 1
	fi
;;

*)
	echo usage: $(basename "$0") 'start|stop|restart|status'
	exit 1
;;

esac
