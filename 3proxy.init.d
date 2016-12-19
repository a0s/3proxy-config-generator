#!/bin/sh
#
### BEGIN INIT INFO
# Provides:     3Proxy
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Initialize 3proxy server
# Description: starts 3proxy
### END INIT INFO

case "$1" in
   start)
       echo Starting 3Proxy

       /root/3proxy/src/3proxy /root/3proxy-config-generator/3proxy.cfg
       ;;

   stop)
       echo Stopping 3Proxy
       /usr/bin/killall 3proxy
       ;;

   restart|reload)
       echo Reloading 3Proxy
       /usr/bin/killall -s USR1 3proxy
       ;;
   *)
       echo Usage: \$0 "{start|stop|restart}"
       exit 1
esac
exit 0

# update-rc.d 3proxyinit defaults
# service 3proxyinit start/stop/status
