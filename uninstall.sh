(

mount /data
mount -o rw,remount /data
MODDIR=${0%/*}
MODID=`echo "$MODDIR" | sed -n -e 's/\/data\/adb\/modules\///p'`

rm -rf /metadata/magisk/"$MODID"
rm -rf /mnt/vendor/persist/magisk/"$MODID"
rm -rf /persist/magisk/"$MODID"
rm -rf /data/unencrypted/magisk/"$MODID"
rm -rf /cache/magisk/"$MODID"

) 2>/dev/null


