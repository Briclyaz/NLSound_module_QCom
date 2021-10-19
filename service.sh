#!/system/bin/sh
#author: akirasuper@github
MOUNT=/data
MODDIR=${0%/*}
# Check if file exist
FILE1=$(find /sys/module -name high_perf_mode)
FILE2=$(find /sys/module -name cpe_debug_mode)
FILE3=$(find /sys/module -name impedance_detect_en)
# High Perf Mode
echo 1 > $FILE1
# CPE Debug Mode
echo 1 > $FILE2
# Impedance Detect EN
echo 1 > $FILE3
fi