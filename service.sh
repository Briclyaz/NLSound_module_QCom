#!/system/bin/sh
resetprop -p --delete persist.vendor.audio_hal.dsp_bit_width_enforce_mode
resetprop -n persist.vendor.audio_hal.dsp_bit_width_enforce_mode 24
# restart
if [ "$API" -ge 24 ]; then
  killall audioserver 2>/dev/null
else
  killall mediaserver 2>/dev/null
fi

#AML FIX by reiryuki@GitHub
DIR=$AML/system/vendor/odm/etc
if [ -d $DIR ] && [ ! -f $AML/disable ]; then
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi

# notification
sleep 10
su -lp 2000 -c "cmd notification post -S bigtext -t 'NLSound Notification' 'Tag' 'NLSound modification works, enjoy listening'"

[ -f /system/vendor/build.prop ] && BUILDS="/system/build.prop /system/vendor/build.prop" || BUILDS="/system/build.prop"

#kekw
A71=$(grep -E "ro.product.vendor.device=A71.*" $BUILDS)
RMEGTNEO3T=$(grep -E "ro.product.vendor.device=RE54E4L1.*" $BUILDS)

RN5PRO=$(grep -E "ro.product.vendor.device=whyred.*" $BUILDS)
RN6PRO=$(grep -E "ro.product.vendor.device=tulip.*" $BUILDS)
R7Y3=$(grep -E "ro.product.vendor.device=onclite.*" $BUILDS)
RN7=$(grep -E "ro.product.vendor.device=lavender.*" $BUILDS)
RN7PRO=$(grep -E "ro.product.vendor.device=violet.*" $BUILDS)
RN8=$(grep -E "ro.product.vendor.device=ginkgo.*" $BUILDS)
RN8T=$(grep -E "ro.product.vendor.device=willow.*" $BUILDS)
RN9S=$(grep -E "ro.product.vendor.device=curtana.*" $BUILDS)
RN9PRO=$(grep -E "ro.product.vendor.device=joyeuse.*" $BUILDS)
RN95G=$(grep -E "ro.product.vendor.device=cannon.*" $BUILDS)
RN9T=$(grep -E "ro.product.vendor.device=cannong.*" $BUILDS)
R9T=$(grep -E "ro.product.vendor.device=lime.*" $BUILDS)
RN10=$(grep -E "ro.product.vendor.device=mojito.*" $BUILDS)
RN10PRO=$(grep -E "ro.product.vendor.device=sweet.*" $BUILDS)
RN10PROMAX=$(grep -E "ro.product.vendor.device=sweetin.*" $BUILDS)
RN11=$(grep -E "ro.product.vendor.device=spes.*" $BUILDS)

RK305G=$(grep -E "ro.product.vendor.device=picasso.*" $BUILDS)
RK304G=$(grep -E "ro.product.vendor.device=phoenix.*" $BUILDS)
RK30U=$(grep -E "ro.product.vendor.device=cezanne.*" $BUILDS)
RK30i5G=$(grep -E "ro.product.vendor.device=picasso48m.*" $BUILDS)
RK40=$(grep -E "ro.product.vendor.device=alioth.*" $BUILDS)

MI9SE=$(grep -E "ro.product.vendor.device=grus.*" $BUILDS)
MICC9E=$(grep -E "ro.product.vendor.device=laurus.*" $BUILDS)
MICC9=$(grep -E "ro.product.vendor.device=pyxis.*" $BUILDS)
MINOTECC9PRO=$(grep -E "ro.product.vendor.device=tucana.*" $BUILDS)
MINOTE10LITE=$(grep -E "ro.product.vendor.device=toco.*" $BUILDS)
MINOTE10LITEZOOM=$(grep -E "ro.product.vendor.device=vangogh.*" $BUILDS)
MI9=$(grep -E "ro.product.vendor.device=cepheus.*" $BUILDS)
MI9T=$(grep -E "ro.product.vendor.device=davinci.*" $BUILDS)
MI10=$(grep -E "ro.product.vendor.device=umi.*" $BUILDS)
MI10s=$(grep -E "ro.product.vendor.device=thyme.*" $BUILDS)
MI10Ultra=$(grep -E "ro.product.vendor.device=cas.*" $BUILDS)
MI10i5GRN95G=$(grep -E "ro.product.vendor.device=gauguin.*" $BUILDS)
MI10LITE=$(grep -E "ro.product.vendor.device=vangogh.*" $BUILDS)
MI10T=$(grep -E "ro.product.vendor.device=apollo.*" $BUILDS)
MI10PRO=$(grep -E "ro.product.vendor.device=cmi.*" $BUILDS)
MI11=$(grep -E "ro.product.vendor.device=venus.*" $BUILDS)
MI11Lite5G=$(grep -E "ro.product.vendor.device=renoir.*" $BUILDS)
MI11Lite4G=$(grep -E "ro.product.vendor.device=courbet.*" $BUILDS)
MI11U=$(grep -E "ro.product.vendor.device=star.*" $BUILDS)
K20P=$(grep -E "ro.product.vendor.device=raphael.*|ro.product.vendor.device=raphaelin.*|ro.product.vendor.device=raphaels.*" $BUILDS)
MI8=$(grep -E "ro.product.vendor.device=dipper.*" $BUILDS)
MI8P=$(grep -E "ro.product.vendor.device=equuleus.*" $BUILDS)
MI9P=$(grep -E "ro.product.vendor.device=crux.*" $BUILDS)

MI12Pro=$(grep -E "ro.product.vendor.device=zeus.*" $BUILDS)
MI12SPro=$(grep -E "ro.product.vendor.device=unicorn.*" $BUILDS)
MI12SU=$(grep -E "ro.product.vendor.device=thor.*" $BUILDS)
MIXFOLD2=$(grep -E "ro.product.vendor.device=zizhan.*" $BUILDS)

MIA2LITE=$(grep -E "ro.product.vendor.device=daisy.*" $BUILDS)
MIA2=$(grep -E "ro.product.vendor.device=jasmine.*" $BUILDS)
MIA3=$(grep -E "ro.product.vendor.device=laurel.*" $BUILDS)

POCOF1=$(grep -E "ro.product.vendor.device=beryllium.*" $BUILDS)
POCOF2P=$(grep -E "ro.product.vendor.device=lmi.*" $BUILDS)
POCOF3=$(grep -E "ro.product.vendor.device=alioth.*" $BUILDS)
POCOF3P=$(grep -E "ro.product.vendor.device=vayu.*" $BUILDS)
POCOM2P=$(grep -E "ro.product.vendor.device=gram.*" $BUILDS)
POCOM3=$(grep -E "ro.product.vendor.device=citrus.*" $BUILDS)
POCOX3=$(grep -E "ro.product.vendor.device=surya.*" $BUILDS)
POCOX3Pro=$(grep -E "ro.product.vendor.device=vayu.*" $BUILDS)
POCOF4GT=$(grep -E "ro.product.vendor.device=ingres.*" $BUILDS)

ONEPLUS7F=$(grep -E "ro.product.vendor.device=msmnile.*" $BUILDS)
ONEPLUS8F=$(grep -E "ro.product.vendor.device=kona.*" $BUILDS)
ONEPLUSNORD=$(grep -E "ro.product.vendor.device=lito.*" $BUILDS)
ONEPLUS9ANDPRO=$(grep -E "ro.product.vendor.device=lahaina.*" $BUILDS)
ONEPLUS9R=$(grep -E "ro.product.vendor.device=OnePlus9R.*" $BUILDS)
ONEPLUS9RT=$(grep -E "ro.product.vendor.device=OnePlus9RT.*" $BUILDS)
ONEPLUS9Pro=$(grep -E "ro.product.vendor.device=OnePlus9Pro.*" $BUILDS)
ONEPLUS10=$(grep -E "ro.product.vendor.device=OnePlusN10.*" $BUILDS)
ONEPLUSNORDCE=$(grep -E "ro.product.vendor.device=lito.*" $BUILDS)
ONEPLUS11GLOBAL=$(grep -E "ro.product.vendor.device=OP594DL1.*" $BUILDS)