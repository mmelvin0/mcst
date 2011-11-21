#!/bin/sh

### BEGIN INIT INFO
# Provides:          minecraft
# Required-Start:    $local_fs $network $named
# Required-Stop:     $local_fs $network $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop Minecraft server
### END INIT INFO

MC_INIT=mc-init.sh # assumes it's on the PATH
RUN=yes

[ -f /etc/default/minecraft ] && . /etc/default/minecraft

##
# example /etc/default/minecraft:
# MC_DIR=/opy/minecraft/server
# MC_INIT=/opt/minecraft/bin/mc-init.sh
# MC_JAVA_OPT='-server -Xincgc -Xmx2048M'
# MC_USER=user
# RUN=yes

case "$1" in
	start)
		[ "$RUN" = yes ] && "$MC_INIT" start
		exit $?
		;;
	*)
		"$MC_INIT" "$1"
		exit $?
		;;
esac
