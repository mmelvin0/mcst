#!/bin/sh

# config

[ -z "$MC_DIR"      ] && MC_DIR=/home/mike/minecraft/server
[ -z "$MC_JAR"      ] && MC_JAR=minecraft_server.jar
[ -z "$MC_JAVA"     ] && MC_JAVA=java
[ -z "$MC_JAVA_OPT" ] && MC_JAVA_OPT='-server -Xincgc -Xmx520M'
[ -z "$MC_NAME"     ] && MC_NAME=minecraft
[ -z "$MC_TIMEOUT"  ] && MC_TIMEOUT=10

# globals

MC_LOG="$MC_DIR/server.log"
MC_LOG_MARK=0
MC_PID=

# functions

mc_log_mark () {
	MC_LOG_MARK=$(cat "$MC_DIR/server.log" | wc -l)
	return $?
}

mc_log_seek () {
	local tries=0 lines=0
	while true; do
		lines=$(expr $(cat "$MC_LOG" | wc -l) - $MC_LOG_MARK)
		if tail -n$lines "$MC_LOG" | "$@" &> /dev/null; then
			return 0
		fi
		tries=$(expr $tries + 1)
		if [ $tries -gt $MC_TIMEOUT ]; then
			return 1
		else
			sleep 1
		fi
	done
}

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
