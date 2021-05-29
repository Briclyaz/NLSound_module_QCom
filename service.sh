#!/system/bin/sh

SERVICE=$MODPATH/service

FORCING=$(find /sys/module -name high_perf_mode)

chmod 0777 $SERVICE

busybox echo "1" > $FORCING

setprop mic.volume 7
