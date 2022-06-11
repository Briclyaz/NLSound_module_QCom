ui_print " "

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi

# sepolicy.rule
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi
FILE=$MODPATH/sepolicy.sh
DES=$MODPATH/sepolicy.rule
if [ -f $FILE ] && ! getprop | grep -Eq "sepolicy.sh\]: \[1"; then
  mv -f $FILE $DES
  sed -i 's/magiskpolicy --live "//g' $DES
  sed -i 's/"//g' $DES
fi

# .aml.sh
mv -f $MODPATH/aml.sh $MODPATH/.aml.sh

# cleaning
ui_print "- Cleaning..."
rm -f $MODPATH/LICENSE
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
ui_print " "

# primary
if getprop | grep -Eq "hires.primary\]: \[1"; then
  ui_print "- Enable Hi-Res to low latency playback (primary) output..."
  sed -i 's/#p//g' $MODPATH/.aml.sh
  ui_print " "
fi

# force 32
if getprop | grep -Eq "hires.32\]: \[1"; then
  ui_print "- Forcing audio format PCM to 32 bit instead of 24 bit..."
  sed -i 's/#32//g' $MODPATH/.aml.sh
  sed -i 's/#32//g' $MODPATH/service.sh
  sed -i 's/enforce_mode 24/enforce_mode 32/g' $MODPATH/service.sh
  ui_print " "
fi

# force float
if getprop | grep -Eq "hires.float\]: \[1"; then
  ui_print "- Enable audio format PCM float..."
  sed -i 's/#f//g' $MODPATH/.aml.sh
  ui_print " "
fi

# speaker
if getprop | grep -Eq "speaker.bit\]: \[16"; then
  ui_print "- Forcing audio format PCM 16 bit to internal speaker..."
  sed -i 's/#s16//g' $MODPATH/.aml.sh
  ui_print " "
elif getprop | grep -Eq "hires.32\]: \[1" && getprop | grep -Eq "speaker.bit\]: \[24"; then
  ui_print "- Forcing audio format PCM 24 bit to internal speaker..."
  sed -i 's/#s24//g' $MODPATH/.aml.sh
  ui_print " "
fi

# sampling rates
if getprop | grep -Eq "sample.rate\]: \[88"; then
  ui_print "- Forcing sample rate to 88200..."
  sed -i 's/|48000/|48000|88200/g' $MODPATH/.aml.sh
  sed -i 's/,48000/,48000,88200/g' $MODPATH/.aml.sh
  ui_print " "
elif getprop | grep -Eq "sample.rate\]: \[96"; then
  ui_print "- Forcing sample rate to 96000..."
  sed -i 's/|48000/|48000|88200|96000/g' $MODPATH/.aml.sh
  sed -i 's/,48000/,48000,88200,96000/g' $MODPATH/.aml.sh
  ui_print " "
elif getprop | grep -Eq "sample.rate\]: \[128"; then
  ui_print "- Forcing sample rate to 128000..."
  sed -i 's/|48000/|48000|88200|96000|128000/g' $MODPATH/.aml.sh
  sed -i 's/,48000/,48000,88200,96000,128000/g' $MODPATH/.aml.sh
  ui_print " "
elif getprop | grep -Eq "sample.rate\]: \[176"; then
  ui_print "- Forcing sample rate to 176400..."
  sed -i 's/|48000/|48000|88200|96000|128000|176400/g' $MODPATH/.aml.sh
  sed -i 's/,48000/,48000,88200,96000,128000,176400/g' $MODPATH/.aml.sh
  ui_print " "
elif getprop | grep -Eq "sample.rate\]: \[192"; then
  ui_print "- Forcing sample rate to 192000..."
  sed -i 's/|48000/|48000|88200|96000|128000|176400|192000/g' $MODPATH/.aml.sh
  sed -i 's/,48000/,48000,88200,96000,128000,176400,192000/g' $MODPATH/.aml.sh
  ui_print " "
elif getprop | grep -Eq "sample.rate\]: \[352"; then
  ui_print "- Forcing sample rate to 352800..."
  sed -i 's/|48000/|48000|88200|96000|128000|176400|192000|352800/g' $MODPATH/.aml.sh
  sed -i 's/,48000/,48000,88200,96000,128000,176400,192000,352800/g' $MODPATH/.aml.sh
  ui_print " "
elif getprop | grep -Eq "sample.rate\]: \[384"; then
  ui_print "- Forcing sample rate to 384000..."
  sed -i 's/|48000/|48000|88200|96000|128000|176400|192000|352800|384000/g' $MODPATH/.aml.sh
  sed -i 's/,48000/,48000,88200,96000,128000,176400,192000,352800,384000/g' $MODPATH/.aml.sh
  ui_print " "
fi

# other
FILE=$MODPATH/service.sh
if getprop | grep -Eq "other.etc\]: \[1"; then
  ui_print "- Activating other etc files bind mount..."
  sed -i 's/#p//g' $FILE
  ui_print " "
fi

# permission
ui_print "- Setting permission..."
DIR=`find $MODPATH/system/vendor -type d`
for DIRS in $DIR; do
  chown 0.2000 $DIRS
done
if [ "$API" -ge 26 ]; then
  magiskpolicy --live "type vendor_file"
  magiskpolicy --live "type vendor_configs_file"
  magiskpolicy --live "dontaudit { vendor_file vendor_configs_file } labeledfs filesystem associate"
  magiskpolicy --live "allow     { vendor_file vendor_configs_file } labeledfs filesystem associate"
  magiskpolicy --live "dontaudit init { vendor_file vendor_configs_file } dir relabelfrom"
  magiskpolicy --live "allow     init { vendor_file vendor_configs_file } dir relabelfrom"
  magiskpolicy --live "dontaudit init { vendor_file vendor_configs_file } file relabelfrom"
  magiskpolicy --live "allow     init { vendor_file vendor_configs_file } file relabelfrom"
  chcon -R u:object_r:vendor_file:s0 $MODPATH/system/vendor
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/odm/etc
fi
ui_print " "