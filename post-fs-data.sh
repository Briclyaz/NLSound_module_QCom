(

mount /data
mount -o rw,remount /data
MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml

# debug
magiskpolicy --live "dontaudit system_server system_file file write"
magiskpolicy --live "allow     system_server system_file file write"
exec 2>$MODPATH/debug-pfsd.log
set -x

# run
FILE=$MODPATH/sepolicy.sh
if [ -f $FILE ]; then
  sh $FILE
fi

# etc
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi
ETC="/my_product/etc $MAGISKTMP/mirror/system/etc"
VETC=$MAGISKTMP/mirror/system/vendor/etc
VOETC="/odm/etc $MAGISKTMP/mirror/system/vendor/odm/etc"
MODETC=$MODPATH/system/etc
MODVETC=$MODPATH/system/vendor/etc
MODVOETC=$MODPATH/system/vendor/odm/etc

# directory
SKU=`ls $VETC/audio | grep sku_`
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    mkdir -p $MODVETC/audio/$SKUS
  done
fi
PROP=`getprop ro.build.product`
if [ -d $VETC/audio/"$PROP" ]; then
  mkdir -p $MODVETC/audio/"$PROP"
fi

# audio files
NAME="*policy*.conf -o -name *policy*.xml -o -name *audio*platform*info*.xml"
rm -f `find $MODPATH/system -type f -name $NAME`
A=`find $ETC -maxdepth 1 -type f -name $NAME`
VA=`find $VETC -maxdepth 1 -type f -name $NAME`
VOA=`find $OETC -maxdepth 1 -type f -name $NAME`
VAA=`find $VETC/audio -maxdepth 1 -type f -name $NAME`
VBA=`find $VETC/audio/"$PROP" -maxdepth 1 -type f -name $NAME`
if [ "$A" ]; then
  cp -f $A $MODETC
fi
if [ "$VA" ]; then
  cp -f $VA $MODVETC
fi
if [ "$VOA" ]; then
  cp -f $VOA $MODOETC
fi
if [ "$VAA" ]; then
  cp -f $VAA $MODOETC/audio
fi
if [ "$VBA" ]; then
  cp -f $VBA $MODVETC/audio/"$PROP"
fi
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    VSA=`find $VETC/audio/$SKUS -maxdepth 1 -type f -name $NAME`
    if [ "$VSA" ]; then
      cp -f $VSA $MODVETC/audio/$SKUS
    fi
  done
fi

# aml fix
DIR=$AML/system/vendor/odm/etc
if [ "$VOA" ] && [ -d $AML ] && [ ! -f $AML/disable ] && [ ! -d $DIR ]; then
  mkdir -p $DIR
  cp -f $VOA $DIR
fi
if [ "$API" -ge 26 ]; then
  magiskpolicy --live "dontaudit vendor_configs_file labeledfs filesystem associate"
  magiskpolicy --live "allow     vendor_configs_file labeledfs filesystem associate"
  magiskpolicy --live "dontaudit init vendor_configs_file dir relabelfrom"
  magiskpolicy --live "allow     init vendor_configs_file dir relabelfrom"
  magiskpolicy --live "dontaudit init vendor_configs_file file relabelfrom"
  magiskpolicy --live "allow     init vendor_configs_file file relabelfrom"
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi

# run
sh $MODPATH/.aml.sh

) 2>/dev/null