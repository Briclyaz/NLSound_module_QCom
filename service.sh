(

MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml

# debug
exec 2>$MODPATH/debug.log
set -x

# property
#32resetprop vendor.audio.flac.sw.decoder.32bit true
resetprop vendor.audio.flac.sw.decoder.24bit true
#32resetprop audio.offload.pcm.32bit.enabled true
resetprop audio.offload.pcm.24bit.enabled true
resetprop audio.offload.pcm.16bit.enabled true
resetprop -p --delete persist.vendor.audio_hal.dsp_bit_width_enforce_mode
resetprop -n persist.vendor.audio_hal.dsp_bit_width_enforce_mode 24

# function
restart_audioserver() {
if [ "$API" -ge 24 ]; then
  killall audioserver
else
  killall mediaserver
fi
}

# restart
restart_audioserver

# wait
sleep 20

# mount
NAME="*policy*.conf -o -name *policy*.xml -o -name *audio*platform*info*.xml"
if [ ! -d $AML ] || [ -f $AML/disable ]; then
  DIR=$MODPATH/system/vendor
else
  DIR=$AML/system/vendor
fi
FILE=`find $DIR/odm/etc -maxdepth 1 -type f -name $NAME`
if [ "`realpath /odm/etc`" != /vendor/odm/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="$(echo $i | sed "s|$DIR||")"
    umount $j
    mount -o bind $i $j
  done
  restart_audioserver
fi
if [ ! -d $AML ] || [ -f $AML/disable ]; then
  DIR=$MODPATH/system
else
  DIR=$AML/system
fi
FILE=`find $DIR/etc -maxdepth 1 -type f -name $NAME`
if [ -d /my_product/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="$(echo $i | sed "s|$DIR||")"
    umount /my_product$j
    mount -o bind $i /my_product$j
  done
  restart_audioserver
fi

) 2>/dev/null

