#!/system/bin/sh

POST=$MODPATH/post-fs-data

FORCING=$(find /sys/module -name high_perf_mode)

chmod 0777 $POST

busybox echo "1" > $FORCING

