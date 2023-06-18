#!/bin/bash

MODID="NLSound"

MIRRORDIR="/data/local/tmp/NLSound"

OTHERTMPDIR="/dev/NLSound"

patch_xml() {
case "$2" in
*mixer_paths*.xml) sed -i "\$apatch_xml $1 \$MODPATH$(echo $2 | sed "s|$MODPATH||") '$3' \"$4\"" $MODPATH/.aml.sh;;
*) sed -i "\$apatch_xml $1 \$MODPATH$(echo $2 | sed "s|$MODPATH||") '$3' \"$4\"" $MODPATH/.aml.sh;;
esac
local NAME=$(echo "$3" | sed -r "s|^.*/.*\[@.*=\"(.*)\".*$|\1|")
local NAMEC=$(echo "$3" | sed -r "s|^.*/.*\[@(.*)=\".*\".*$|\1|")
local VAL=$(echo "$4" | sed "s|.*=||")
[ "$(echo $4 | grep '=')" ] && local VALC=$(echo "$4" | sed "s|=.*||") || local VALC="value"
case "$1" in
"-d") xmlstarlet ed -L -d "$3" $2;;
"-u") xmlstarlet ed -L -u "$3/@$VALC" -v "$VAL" $2;;
"-s") if [ "$(xmlstarlet sel -t -m "$3" -c . $2)" ]; then
xmlstarlet ed -L -u "$3/@$VALC" -v "$VAL" $2
else
local SNP=$(echo "$3" | sed "s|\[.*$||")
local NP=$(dirname "$SNP")
local SN=$(basename "$SNP")
xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" -i "$SNP-$MODID" -t attr -n "$NAMEC" -v "$NAME" -i "$SNP-$MODID" -t attr -n "$VALC" -v "$VAL" -r "$SNP-$MODID" -v "$SN" $2
fi;;
esac
}

#author - Lord_Of_The_Lost@Telegram
memes_confxml() {
case $FILE in
*.conf) sed -i "/$1 {/,/}/d" $FILE
sed -i "/$2 {/,/}/d" $FILE
sed -i "s/^effects {/effects {\n  $1 {\nlibrary $2\nuuid $5\n  }/g" $FILE
sed -i "s/^libraries {/libraries {\n  $2 {\npath $3\/$4\n  }/g" $FILE;;
*.xml) sed -i "/$1/d" $FILE
sed -i "/$2/d" $FILE
sed -i "/<libraries>/ a\<library name=\"$2\" path=\"$4\"\/>" $FILE
sed -i "/<effects>/ a\<effect name=\"$1\" library=\"$2\" uuid=\"$5\"\/>" $FILE;;
esac
}

altmemes_confxml() {
case $1 in
*.conf) local SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *music {/p}" $1 | sed -r "s/( *).*/\1/")
local EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\music {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
for EFFECT in $EFFECTS; do
local SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
[ "$EFFECT" != "atmos" ] && sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#/g}" $1
done;;
*.xml) local EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"music\">$/,/^ *<\/stream>$/ {/<stream type=\"music\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
for EFFECT in $EFFECTS; do
[ "$EFFECT" != "atmos" ] && sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--<apply effect=\"$EFFECT\"\/>-->/" $1
done;;
esac
}

#author - Lord_Of_The_Lost@Telegram
effects_patching() {
case $1 in
-pre) CONF=pre_processing; XML=preprocess;;
-post) CONF=output_session_processing; XML=postprocess;;
esac
case $2 in
*.conf) if [ ! "$(sed -n "/^$CONF {/,/^}/p" $2)" ]; then
echo -e "\n$CONF {\n$3 {\n$4 {\n}\n}\n}" >> $2
elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^}/p}" $2)" ]; then
sed -i "/^$CONF {/,/^}/ s/$CONF {/$CONF {\n$3 {\n$4 {\n}\n}/" $2
elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^}/ {/$4 {/,/}/p}}" $2)" ]; then
sed -i "/^$CONF {/,/^}/ {/$3 {/,/^}/ s/$3 {/$3 {\n$4 {\n}/}" $2
fi;;
*.xml) if [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/p" $2)" ]; then 
sed -i "/<\/audio_effects_conf>/i\<$XML>\n   <stream type=\"$3\">\n<apply effect=\"$4\"\/>\n<\/stream>\n<\/$XML>" $2
elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/p}" $2)" ]; then 
sed -i "/^ *<$XML>/,/^ *<\/$XML>/ s/<$XML>/<$XML>\n<stream type=\"$3\">\n<apply effect=\"$4\"\/>\n<\/stream>/" $2
elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ {/^ *<apply effect=\"$4\"\/>/p}}" $2)" ]; then
sed -i "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ s/<stream type=\"$3\">/<stream type=\"$3\">\n<apply effect=\"$4\"\/>/}" $2
fi;;
esac
}

libs_checker(){
ASDK="$(GREP_PROP "ro.build.version.sdk")"
DYNLIB=true
[ $ASDK -lt 26 ] && DYNLIB=false
[ -z $DYNLIB ] && DYNLIB=false
if $DYNLIB; then 
  DYNLIBPATCH="\/vendor"; 
else 
  DYNLIBPATCH="\/system"; 
fi
}

[ -f /system/vendor/build.prop ] && BUILDS="/system/build.prop /system/vendor/build.prop" || BUILDS="/system/build.prop"

TG2=$(grep "ro.board.platform=gs201" $BUILDS) #tensor g2
SD660=$(grep "ro.board.platform=sdm660" $BUILDS) #sdm 660
SD662=$(grep "ro.board.platform=bengal" $BUILDS) #sdm 662
SD665=$(grep "ro.board.platform=trinket" $BUILDS) #sdm 665
SD670=$(grep "ro.board.platform=sdm670" $BUILDS) #sdm 670
SD710=$(grep "ro.board.platform=sdm710" $BUILDS) #sdm 710
SD720G=$(grep "ro.board.platform=atoll" $BUILDS) #sdm 720g
SD730G=$(grep "ro.board.platform=sm6150" $BUILDS) #sdm 730g
SD765G=$(grep "ro.board.platform=lito" $BUILDS) #sdm 765g
SD820=$(grep "ro.board.platform=msm8996" $BUILDS) #sdm 820
SD835=$(grep "ro.board.platform=msm8998" $BUILDS) #sdm 835
SD845=$(grep "ro.board.platform=sdm845" $BUILDS) #sdm 845
SD855=$(grep "ro.board.platform=msmnile" $BUILDS) #sdm 855
SD865=$(grep "ro.board.platform=kona" $BUILDS) #sdm 865
SD888=$(grep "ro.board.platform=lahaina" $BUILDS) #sdm 888
SM6375=$(grep "ro.board.platform=holi" $BUILDS) #sdm 695
SM8450=$(grep "ro.board.platform=taro" $BUILDS) #sdm 8 gen 1
SM8550=$(grep "ro.board.platform=kalama" $BUILDS) #sdm 8+ gen 1 & sd 8 gen 2

if [ "$TG2" ] || [ "$SD662" ] || [ "$SD665" ] || [ "$SD670" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730G" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ] || [ "$SM6375" ] || [ "$SM8450" ] || [ "$SM8550" ]; then
HIFI=true
ui_print " "
ui_print "- Device with support Hi-Fi detected! -"
else
HIFI=false
ui_print " "
ui_print " - Device without support Hi-Fi detected! -"
fi

#kekw
A71=$(grep -E "ro.product.vendor.device=A71.*" $BUILDS)
S22U=$(grep -E "ro.product.vendor.device=b0q.*" $BUILDS)
RMEGTNEO3T=$(grep -E "ro.product.vendor.device=RE54E4L1.*" $BUILDS)

#reserved for pixels
PIXEL3a=$(grep -E "ro.product.vendor.device=bonito.*" $BUILDS)
PIXEL3=$(grep -E "ro.product.vendor.device=blueline.*" $BUILDS)
PIXEL4a=$(grep -E "ro.product.vendor.device=sunfish.*" $BUILDS)
PIXEL4a5G=$(grep -E "ro.product.vendor.device=bramble.*" $BUILDS) 
PIXEL4=$(grep -E "ro.product.vendor.device=flame.*" $BUILDS)
PIXEL4XL=$(grep -E "ro.product.vendor.device=coral.*" $BUILDS)
PIXEL5a5G=$(grep -E "ro.product.vendor.device=barbet.*" $BUILDS)
PIXEL5=$(grep -E "ro.product.vendor.device=redfin.*" $BUILDS)
PIXEL6a=$(grep -E "ro.product.vendor.device=bluejay.*" $BUILDS)
PIXEL6=$(grep -E "ro.product.vendor.device=oriel.*" $BUILDS)
PIXEL6Pro=$(grep -E "ro.product.vendor.device=raven.*" $BUILDS)
PIXEL7=$(grep -E "ro.product.vendor.device=cheetah.*" $BUILDS)
PIXEL7Pro=$(grep -E "ro.product.vendor.device=panther.*" $BUILDS)

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
RN124GNFC=$(grep -E "ro.product.vendor.device=topaz.*" $BUILDS)
RN124G=$(grep -E "ro.product.vendor.device=tapas.*" $BUILDS)

RK305G=$(grep -E "ro.product.vendor.device=picasso.*" $BUILDS)
RK304G=$(grep -E "ro.product.vendor.device=phoenix.*" $BUILDS)
RK30U=$(grep -E "ro.product.vendor.device=cezanne.*" $BUILDS)
RK30i5G=$(grep -E "ro.product.vendor.device=picasso48m.*" $BUILDS)

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
MI12x=$(grep -E "ro.product.vendor.device=psyche.*" $BUILDS)
MI13Lite=$(grep -E "ro.product.vendor.device=zuyi.*" $BUILDS)
MI13=$(grep -E "ro.product.vendor.device=fuxi.*" $BUILDS) #need check
MI13Pro=$(grep -E "ro.product.vendor.device=nuwa.*" $BUILDS) #need check
MI13U=$(grep -E "ro.product.vendor.device=mivendor.*" $BUILDS)
MIXFOLD2=$(grep -E "ro.product.vendor.device=zizhan.*" $BUILDS)

MIA2LITE=$(grep -E "ro.product.vendor.device=daisy.*" $BUILDS)
MIA2=$(grep -E "ro.product.vendor.device=jasmine.*" $BUILDS)
MIA3=$(grep -E "ro.product.vendor.device=laurel.*" $BUILDS)

POCOF1=$(grep -E "ro.product.vendor.device=beryllium.*" $BUILDS)
POCOF2P=$(grep -E "ro.product.vendor.device=lmi.*" $BUILDS)
POCOF3=$(grep -E "ro.product.vendor.device=alioth.*" $BUILDS)
POCOF4GT=$(grep -E "ro.product.vendor.device=ingres.*" $BUILDS)
POCOF4=$(grep -E "ro.product.vendor.device=munch.*" $BUILDS)
POCOF5=$(grep -E "ro.product.vendor.device=marble.*" $BUILDS)
POCOF5Pro=$(grep -E "ro.product.vendor.device=mondrian.*" $BUILDS)
POCOX5Pro=$(grep -E "ro.product.vendor.device=redwood.*" $BUILDS) 
POCOM2P=$(grep -E "ro.product.vendor.device=gram.*" $BUILDS)
POCOM3C=$(grep -E "ro.product.vendor.device=citrus.*" $BUILDS)
POCOM3J=$(grep -E "ro.product.vendor.device=juice.*" $BUILDS)
POCOX3=$(grep -E "ro.product.vendor.device=surya.*" $BUILDS)
POCOX3Pro=$(grep -E "ro.product.vendor.device=vayu.*" $BUILDS)

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

DEVICE=$(getprop ro.product.vendor.device)
ACONFS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "audio_configs*.xml")"
AECFGS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
MPATHS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "mixer_paths*.xml")"
APIXMLS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "audio_platform_info.xml")"
APIIXMLS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "audio_platform_info_intcodec*.xml")"
APIEXMLS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "audio_platform_info_extcodec*.xml")"
APIQRDXMLS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "audio_platform_info_qrd*.xml")"
DEVFEAS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "$DEVICE.xml")" 
AUDIOPOLICYS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "audio_policy_configuration.xml")"
SNDTRGS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "*sound_trigger_mixer_paths*.xml")"
MCODECS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "media_codecs_c2_audio.xml" -o -name "media_codecs_c2.xml" -o -name "media_codecs_google_audio.xml" -o -name "media_codecs_google_c2_audio.xml")"
IOPOLICYS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "audio_io_policy.conf")"
OUTPUTPOLICYS="$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f -name "audio_output_policy.conf")"

VNDK=$(find /system/lib /vendor/lib -type d -iname "*vndk*")
VNDK64=$(find /system/lib64 /vendor/lib64 -type d -iname "*vndk*")
VNDKQ=$(find /system/lib /vendor/lib -type d -iname "vndk*-Q")

SETTINGS=$MODPATH/settings.nls

STEP1=false
STEP2=false
STEP3=false
STEP4=false
STEP5=false
STEP6=false
STEP7=false
STEP8=false
STEP9=false
STEP10=false
STEP11=false
STEP12=false
STEP13=false
STEP14=false
STEP15=false
STEP16=false
STEP17=false
STEP18=false
STEP19=false
STEP20=false

VOLUMES=false
MICROPHONES=false
HIGHBIT=false
COMPANDERS=false
LOLMIXER=false
VOLSTEPSINT=Skip
VOLMEDIASINT=Skip
VOLMICINT=Skip
BITNESINT=Skip
SAMPLERATEINT=Skip

NEWdirac=$MODPATH/common/NLSound/newdirac
CUSTLIBS=$MODPATH/common/NLSound/custlibs
PROP=$MODPATH/system.prop

mkdir -p $MODPATH/tools
cp_ch $MODPATH/common/addon/External-Tools/tools/$ARCH32/\* $MODPATH/tools/.

ui_print " "
ui_print " - Configurate me, pls >.< - "
ui_print " "

ui_print "***************************************************"
ui_print "* [1/16]                                          *"
ui_print "*                                                 *"
ui_print "*            • SELECT VOLUME STEPS •              *"
ui_print "*       Lower value - faster volume control       *"
ui_print "*                                                 *"
ui_print "*      This step determines the total number      *"
ui_print "*  of volume steps for the music in your system.  *"
ui_print "*   For calls and other scenarios, the volume     *"
ui_print "*           steps will remain current.            *"
ui_print "*_________________________________________________*"
ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
ui_print "***************************************************"
sleep 1
ui_print " "
ui_print "   1. Skip (No changes will be made)"
ui_print "   2. 30 ( ~ 1.1 - 2.0 dB per step)"
ui_print "   3. 50 ( ~ 0.8 - 1.4 dB per step)"
ui_print "   4. 100 ( ~ 0.4 - 0.7 dB per step)"
ui_print " "
VOLSTEPS=1
while true; do
ui_print " - $VOLSTEPS"
"$VKSEL" && VOLSTEPS="$((VOLSTEPS + 1))" || break
[[ "$VOLSTEPS" -gt "4" ]] && VOLSTEPS=1
done

case "$VOLSTEPS" in
"1") VOLSTEPSINT="Skip";;
"2") VOLSTEPSINT="30";;
"3") VOLSTEPSINT="50";;
"4") VOLSTEPSINT="100";;
esac

ui_print " - [*] Selected: $VOLSTEPSINT"
ui_print ""

STEP1=true
sed -i 's/STEP1=false/STEP1=true/g' $SETTINGS
sed -i 's/VOLSTEPS=skip/VOLSTEPS='$VOLSTEPSINT'/g' $SETTINGS


ui_print " "
ui_print "***************************************************"
ui_print "* [2/16]                                          *"
ui_print "*                                                 *"
ui_print "*          • SELECT VOLUMES FOR MEDIA •           *"
ui_print "*      Lower numerical value - lower volume       *"
ui_print "*                                                 *"
ui_print "*        This item determines the overall         *"
ui_print "*    maximum volume threshold for the media.      *"
ui_print "*   The higher the numerical value you select,    *"
ui_print "*        the higher the maximum volume.           *"
ui_print "*                                                 *"
ui_print "*        NOTE: does not affect Bluetooth          *"
ui_print "*                                                 *"
ui_print "*_________________________________________________*"
ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
ui_print "***************************************************"
sleep 1
ui_print " "
ui_print "   1. Skip (No changes will be made)"
ui_print "   2. 84 "
ui_print "   3. 86"
ui_print "   4. 88"
ui_print "   5. 90"
ui_print "   6. 92"
ui_print "   7. 94"
ui_print " "
VOLMEDIA=1
while true; do
ui_print " - $VOLMEDIA"
"$VKSEL" && VOLMEDIA="$((VOLMEDIA + 1))" || break
[[ "$VOLMEDIA" -gt "7" ]] && VOLMEDIA=1
done

case "$VOLMEDIA" in
"1") VOLMEDIASINT="Skip";;
"2") VOLMEDIASINT="84";;
"3") VOLMEDIASINT="86";;
"4") VOLMEDIASINT="88";;
"5") VOLMEDIASINT="90";;
"6") VOLMEDIASINT="92";;
"7") VOLMEDIASINT="94";;
esac

ui_print " - [*] Selected: $VOLMEDIASINT"
ui_print ""

STEP2=true
sed -i 's/STEP2=false/STEP2=true/g' $SETTINGS
sed -i 's/VOLMEDIA=skip/VOLMEDIA='$VOLMEDIASINT'/g' $SETTINGS

ui_print "  "
ui_print "***************************************************"
ui_print "* [3/16]                                          *"
ui_print "*                                                 *"
ui_print "*        • SELECT MICROPHONE SENSITIVITY •        *"
ui_print "*       Lower numerical value - lower volume      *"
ui_print "*                                                 *"
ui_print "*    This item determines the overall maximum     *"
ui_print "*    volume threshold for the your microphones.   *"
ui_print "*    The higher the numerical value you select,   *"
ui_print "*       the louder your microphones will be.      *"
ui_print "*                                                 *"
ui_print "*        NOTE: does not affect Bluetooth          *"
ui_print "*                                                 *"
ui_print "*_________________________________________________*"
ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
ui_print "***************************************************"
sleep 1
VOLMIC=1
ui_print " "
ui_print "   1. Skip (No changes will be made)"
ui_print "   2. 84"
ui_print "   3. 86"
ui_print "   4. 88"
ui_print "   5. 90"
ui_print "   6. 92"
ui_print "   7. 94"
ui_print " "
VOLMIC=1
while true; do
ui_print " - $VOLMIC"
"$VKSEL" && VOLMIC="$((VOLMIC + 1))" || break
[[ "$VOLMIC" -gt "7" ]] && VOLMIC=1
done

case "$VOLMIC" in
"1") VOLMICINT="Skip";;
"2") VOLMICINT="84";;
"3") VOLMICINT="86";;
"4") VOLMICINT="88";;
"5") VOLMICINT="90";;
"6") VOLMICINT="92";;
"7") VOLMICINT="94";;
esac

ui_print " - [*] Selected: $VOLMICINT"
ui_print ""

STEP3=true
sed -i 's/STEP3=false/STEP3=true/g' $SETTINGS
sed -i 's/VOLMIC=skip/VOLMIC='$VOLMICINT'/g' $SETTINGS

ui_print " "
ui_print "***************************************************"
ui_print "* [4/16]                                          *"
ui_print "*                                                 *"
ui_print "*            • SELECT AUDIO FORMAT •              *"
ui_print "*                                                 *"
ui_print "*     This step configures your audio codec,      *"
ui_print "*     forcing it to process your audio more       *"
ui_print "*   thoroughly at the quality you select here.    *"
ui_print "*    You will not see *-bit in the logs after     *"
ui_print "*      setting this item, the module does         *"
ui_print "*     not mislead you with made-up numbers        *"
ui_print "*    Nevertheless, you will hear a positive       *"
ui_print "*              change in the sound.               *"
ui_print "*                                                 *"
ui_print "*         NOTE: does not affect Bluetooth         *"
ui_print "*                                                 *"
ui_print "*_________________________________________________*"
ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
ui_print "***************************************************"
sleep 1
BITNES=1
ui_print " "
ui_print "   1. Skip (No changes will be made)"
ui_print "   2. 24-bit"
ui_print "   3. 32-bit (only for SD870 and higher)"
ui_print "   4. Float"
ui_print " "
BITNES=1
while true; do
ui_print " - $BITNES"
"$VKSEL" && BITNES="$((BITNES + 1))" || break
[[ "$BITNES" -gt "4" ]] && BITNES=1
done

case "$BITNES" in
"1") BITNESINT="Skip";;
"2") BITNESINT="24";;
"3") BITNESINT="32";;
"4") BITNESINT="float";;
esac

ui_print " - [*] Selected: $BITNESINT"
ui_print ""

STEP4=true
sed -i 's/STEP4=false/STEP4=true/g' $SETTINGS
sed -i 's/BITNES=skip/BITNES='$BITNESINT'/g' $SETTINGS

ui_print " "
ui_print "***************************************************"
ui_print "* [5/16]                                          *"
ui_print "*                                                 *"
ui_print "*             • SELECT SAMPLING RATE •            *"
ui_print "*                                                 *"
ui_print "*     This step configures your audio codec,      *"
ui_print "*     forcing it to process your audio more       *"
ui_print "*   thoroughly at the quality you select here.    *"
ui_print "*    You will not see *-Hz in the logs after      *"
ui_print "*      setting this item, the module does         *"
ui_print "*     not mislead you with made-up numbers        *"
ui_print "*    Nevertheless, you will hear a positive       *"
ui_print "*              change in the sound.               *"
ui_print "*                                                 *"
ui_print "*         NOTE: does not affect Bluetooth         *"
ui_print "*                                                 *"
ui_print "*_________________________________________________*"
ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
ui_print "***************************************************"
sleep 1
ui_print " "
ui_print "   1. Skip (No changes will be made)"
ui_print "   2. 96000 Hz "
ui_print "   3. 192000 Hz "
ui_print "   4. 384000 Hz (only for SD870 and higher)"
ui_print " "
SAMPLERATE=1
while true; do
ui_print "  - $SAMPLERATE"
"$VKSEL" && SAMPLERATE="$((SAMPLERATE + 1))" || break
[[ "$SAMPLERATE" -gt "4" ]] && SAMPLERATE=1
done

case "$SAMPLERATE" in
"1") SAMPLERATEINT="Skip";;
"2") SAMPLERATEINT="96000";;
"3") SAMPLERATEINT="192000";;
"4") SAMPLERATEINT="384000";;
esac

ui_print " - [*] Selected: $SAMPLERATEINT"
ui_print ""

STEP5=true
sed -i 's/STEP5=false/STEP5=true/g' $SETTINGS
sed -i 's/SAMPLERATE=skip/SAMPLERATE='$SAMPLERATEINT'/g' $SETTINGS

ui_print " "
ui_print "***************************************************"
ui_print "* [6/16]                                          *"
ui_print "*                                                 *"
ui_print "*        • TURN OFF SOUND INTERFERENCE •          *"
ui_print "*                                                 *"
ui_print "*     This step will disable various system       *"
ui_print "*   optimizations of sound, such as compressors,  *"
ui_print "*    limiters and other unnecessary mechanisms    *"
ui_print "*         that interfere with the normal          *"
ui_print "*              perception of audio.               *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP6=true
sed -i 's/STEP6=false/STEP6=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [7/16]                                          *"
ui_print "*                                                 *"
ui_print "*        • CONFIGURE INTERNAL AUDIO CODEC •       *"
ui_print "*                                                 *"
ui_print "*           This option will configure            *"
ui_print "*       your device's internal audio codec.       *"
ui_print "*       For example, it will try to disable       *"
ui_print "*    the deep buffer a bit, allow the external    *"
ui_print "*       DSP chip to process audio and many        *"
ui_print "*           more useful little things.            *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP7=true
sed -i 's/STEP7=false/STEP7=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [8/16]                                          *"
ui_print "*                                                 *"
ui_print "*       • PATCHING DEVICE_FEATURES FILES •        *"
ui_print "*                                                 *"
ui_print "*        This step will do the following:         *"
ui_print "*        - Unlocks the sampling frequency         *"
ui_print "*          of the audio up to 192000 Hz;          *"
ui_print "*        - Enable HD record in camcorder;         *"
ui_print "*        - Increase VoIP record quality;          *"
ui_print "*        - Enable support for hd voice            *"
ui_print "*          recording quality;                     *"
ui_print "*        - Enable Hi-Fi support (on some devices) *"
ui_print "*                                                 *"
ui_print "*  And much more . . .                            *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP8=true
sed -i 's/STEP8=false/STEP8=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [9/16]                                          *"
ui_print "*                                                 *"
ui_print "*            • INSTALL CUSTOM DIRAC •             *"
ui_print "*                                                 *"
ui_print "*  Dirac is an audio library that superficially   *"
ui_print "*      processes sound. To put it bluntly,        *"
ui_print "*         some analogue of Dolby Atmos.           *"
ui_print "*    We reconfigured it and added the author's    *"
ui_print "*        equalizer preset with an emphasis        *"
ui_print "*         on low and mid-low frequencies.         *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP9=true
sed -i 's/STEP9=false/STEP9=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [10/16]                                         *"
ui_print "*                                                 *"
ui_print "*      • OTHER PATCHES IN MIXER_PATHS FILES •     *"
ui_print "*                                                 *"
ui_print "*         This option reroutes the audio,         *"
ui_print "*   removing anything superfluous and trying to   *"
ui_print "*     reconfigure the stream so that the audio    *"
ui_print "*         takes the shortest path from the        *"
ui_print "*        device's codec to your headphones.       *"
ui_print "*        Additionally, it disables various        *"
ui_print "*     low-frequency cutoffs that are supposedly   *"
ui_print "*            out of human hearing range.          *"
ui_print "*       Contains AUTHOR'S sound settings for      *"
ui_print "*          the speakers of some devices,          *"
ui_print "*        for example (list to be updated):        *"
ui_print "*                                                 *"
ui_print "*            - Poco X3 NFC (surya);               *"
ui_print "*            - Poco X3 Pro (vayu);                *"
ui_print "*            - Redmi Note 10 (mojito);            *"
ui_print "*            - Redmi Note 10 Pro (sweet);         *"
ui_print "*            - Redmi Note 10 Pro Max (sweetin);   *"
ui_print "*            - Mi 11 Ultra (star).                *"
ui_print "*                                                 *"
ui_print "*        These customizations significantly       *"
ui_print "*       improve stereo sound quality of these     *"
ui_print "*   devices, correct volume balance by channels   *"
ui_print "*           and improve the overall volume        *"
ui_print "*                 and sound scene.                *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP10=true
sed -i 's/STEP10=false/STEP10=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [11/16]                                         *"
ui_print "*                                                 *"
ui_print "*         • TWEAKS FOR BUILD.PROP FILES •         *"
ui_print "*                                                 *"
ui_print "*     A huge number of global settings that       *"
ui_print "*      greatly change the quality of audio        *"
ui_print "*   for the better. Don't hesitate and just go    *"
ui_print "*         along with the installation.            *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP11=true
sed -i 's/STEP11=false/STEP11=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [12/16]                                         *"
ui_print "*                                                 *"
ui_print "*             • IMPROVE BLUETOOTH •               *"
ui_print "*                                                 *"
ui_print "*   This option will improve the audio quality    *"
ui_print "*    in Bluetooth, as well as fix the problem     *"
ui_print "*      of disappearing the AAC codec switch       *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP12=true
sed -i 's/STEP12=false/STEP12=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [13/16]                                         *"
ui_print "*                                                 *"
ui_print "*            • SWITCH AUDIO OUTPUT •              *"
ui_print "*                                                 *"
ui_print "*  This option will switch DIRECT to DIRECT_PCM,  *"
ui_print "*      which will improve the sound detail.       *"
ui_print "*   Can cause no sound in applications such as    *"
ui_print "*       TikTok, YouTube, and many games           *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP13=true
sed -i's/STEP13=false/STEP13=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [14/16]                                         *"
ui_print "*                                                 *"
ui_print "*        • INSTALL CUSTOM PRESET FOR IIR •        *"
ui_print "*                                                 *"
ui_print "* IIR affects the final frequency response curve. *"
ui_print "*   headphones. The default setting is with an    *"
ui_print "* emphasis on the upper limit of low frequencies  *"
ui_print "* and the lower bound of the midrange frequencies *"
ui_print "*Once applied, these boundaries will be reinforced*"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP14=true
sed -i 's/STEP14=false/STEP14=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [15/16]                                         *"
ui_print "*                                                 *"
ui_print "*          • IGNORE ALL AUDIO EFFECTS •           *"
ui_print "*                                                 *"
ui_print "*      This item disables any audio effects       *"
ui_print "*   at the system level. It breaks XiaomiParts,   *"
ui_print "*      Dirac, Dolby, and other equalizers.        *"
ui_print "*   Significantly increases the sound quality     *"
ui_print "*            for quality headphones.              *"
ui_print "*                                                 *"
ui_print "*                     Note:                       *"
ui_print "*     If you agree, the sound becomes drier,      *"
ui_print "*                   "cleaner".                    *"
ui_print "*      However, many people are advised to        *"
ui_print "*               skip this point.                  *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP15=true
sed -i 's/STEP15=false/STEP15=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [16/16]                                         *"
ui_print "*                                                 *"
ui_print "*         • INSTALL EXPERIMENTAL TWEAKS •         *"
ui_print "*                                                 *"
ui_print "*   This option configures the audio codecs of    *"
ui_print "*     your device via the tinymix function.       *"
ui_print "*  WARNING These settings can lead to all sorts   *"
ui_print "*       of problems, up to and including          *"
ui_print "*   device malfunction (so called bootloop).      *"
ui_print "*                                                 *"
ui_print "*      These settings significantly improve       *"
ui_print "*      audio quality, but are not compatible      *"
ui_print "*  with most devices. Use only at your own risk!  *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP16=true
sed -i 's/STEP16=false/STEP16=true/g' $SETTINGS
fi

ui_print " - YOUR SETTINGS: "
ui_print " 1. Volume steps: $VOLSTEPSINT"
ui_print " 2. Volume levels: $VOLMEDIASINT"
ui_print " 3. Microphone levels: $VOLMICINT"
ui_print " 4. Audio format configuration: $BITNESINT"
ui_print " 5. Sample rate configuration: $SAMPLERATEINT"
ui_print " 6. Turn off sound interference: $STEP6"
ui_print " 7. Configurating interal audio codec: $STEP7"
ui_print " 8. Patching device_features files: $STEP8"
ui_print " 9. Install custom Dirac: $STEP9"
ui_print " 10. Other patches in mixer_paths files: $STEP10"
ui_print " 11. Tweaks for build.prop files: $STEP11"
ui_print " 12. Improve bluetooth: $STEP12"
ui_print " 13. Switch audio output: $STEP13"
ui_print " 14. Install custom preset for IIR: $STEP14"
ui_print " 15. Ignore all audio effects: $STEP15"
ui_print " 16. Install experimental tweaks: $STEP16"
ui_print " "

ui_print " "
ui_print " - Processing. . . -"
ui_print " "
ui_print " - You can minimize Magisk and use the device normally -"
ui_print " - and then come back here to reboot and apply the changes. -"
ui_print " "

if [ "$BITNESINT" != "Skip" ]; then
if [ "$SAMPLERATEINT" != "Skip" ]; then
for OAPIXML in ${APIXMLS}; do
APIXML="$MODPATH$(echo $OAPIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAPIXML $APIXML
sed -i 's/\t/  /g' $APIXML
patch_xml -s $APIXML '/audio_platform_info/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIXML '/audio_platform_info/config_params/param[@key="config_spk_protection"]' "false"
patch_xml -s $APIXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/app_types/app[@mode="default"]' "bit_width=$BITNESINT"
patch_xml -s $APIXML '/audio_platform_info/app_types/app[@mode="default"]' "max_rate=$SAMPLERATEINT"
if [ ! "$(grep '<app_types>' $APIXML)" ]; then
sed -i 's/<\/audio_platform_info>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69936\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69940\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n  <app_types> \n<\/audio_platform_info>/' $APIXML  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIXML)" ] || sed -i '/<audio_platform_info>/,/<\/audio_platform_info>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"$i\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n\1\2/}' $APIXML
done
fi
done
fi
fi

if [ "$BITNESINT" != "Skip" ]; then
if [ "$SAMPLERATEINT" != "Skip" ]; then
for OAPIIXML in ${APIIXMLS}; do
APIIXML="$MODPATH$(echo $OAPIIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAPIIXML $APIIXML
sed -i 's/\t/  /g' $APIIXML
patch_xml -s $APIIXML '/audio_platform_info_intcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIIXML '/audio_platform_info/config_params/param[@key="config_spk_protection"]' "false"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/app_types/app[@mode="default"]' "bit_width=$BITNESINT"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/app_types/app[@mode="default"]' "max_rate=$SAMPLERATEINT"
if [ ! "$(grep '<app_types>' $APIIXML)" ]; then
sed -i 's/<\/audio_platform_info_intcodec>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69936\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69940\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n  <app_types> \n<\/audio_platform_info_intcodec>/' $APIIXML  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info_intcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIIXML)" ] || sed -i '/<audio_platform_info_intcodec>/,/<\/audio_platform_info_intcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"$i\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n\1\2/}' $APIIXML
done
fi
done
fi
fi

if [ "$BITNESINT" != "Skip" ]; then
if [ "$SAMPLERATEINT" != "Skip" ]; then
for OAPIEXML in ${APIEXMLS}; do
APIEXML="$MODPATH$(echo $OAPIEXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAPIEXML $APIEXML
sed -i 's/\t/  /g' $APIEXML
patch_xml -s $APIEXML '/audio_platform_info_extcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIEXML '/audio_platform_info/config_params/param[@key="config_spk_protection"]' "false"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/app_types/app[@mode="default"]' "bit_width=$BITNESINT"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/app_types/app[@mode="default"]' "max_rate=$SAMPLERATEINT"
if [ ! "$(grep '<app_types>' $APIEXML)" ]; then
sed -i 's/<\/audio_platform_info_extcodec>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69936\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69940\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n  <app_types> \n<\/audio_platform_info_extcodec>/' $APIEXML  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIEXML)" ] || sed -i '/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"$i\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n\1\2/}' $APIEXML
done
fi
done
fi
fi

if [ "$BITNESINT" != "Skip" ]; then
if [ "$SAMPLERATEINT" != "Skip" ]; then
for OAPIQRDXML in ${APIQRDXMLS}; do
APIQRDXML="$MODPATH$(echo $OAPIQRDXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAPIQRDXML $APIQRDXML
sed -i 's/\t/  /g' $APIQRDXML
patch_xml -s $APIQRDXML '/audio_platform_info/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIQRDXML '/audio_platform_info/config_params/param[@key="config_spk_protection"]' "false"
patch_xml -s $APIQRDXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/app_types/app[@mode="default"]' "bit_width=$BITNESINT"
patch_xml -s $APIQRDXML '/audio_platform_info/app_types/app[@mode="default"]' "max_rate=$SAMPLERATEINT"
if [ ! "$(grep '<app_types>' $APIQRDXML)" ]; then
sed -i 's/<\/audio_platform_info>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69936\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69940\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n  <app_types> \n<\/audio_platform_info>/' $APIQRDXML  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIQRDXML)" ] || sed -i '/<audio_platform_info>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"$i\" max_rate=\"'$SAMPLERATEINT'\" \/\/> \n\1\2/}' $APIQRDXML
done
fi
done
#end step
fi 

sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIXML
sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIIXML
sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIEXML
sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIQRDXML

sed -i 's/name="SND_DEVICE_IN_UNPROCESSED_MIC" acdb_id=".*"/name="SND_DEVICE_IN_UNPROCESSED_MIC" acdb_id="41"/g' $APIXML
sed -i 's/name="SND_DEVICE_IN_VOICE_REC_TMIC" acdb_id=".*"/name="SND_DEVICE_IN_VOICE_REC_TMIC" acdb_id="41"/g' $APIXML
sed -i 's/name="SND_DEVICE_IN_VOICE_REC_MIC" acdb_id=".*"/name="SND_DEVICE_IN_VOICE_REC_MIC" acdb_id="41"/g' $APIXML

sed -i 's/name="SND_DEVICE_IN_UNPROCESSED_MIC" acdb_id=".*"/name="SND_DEVICE_IN_UNPROCESSED_MIC" acdb_id="41"/g' $APIIXML
sed -i 's/name="SND_DEVICE_IN_VOICE_REC_TMIC" acdb_id=".*"/name="SND_DEVICE_IN_VOICE_REC_TMIC" acdb_id="41"/g' $APIIXML
sed -i 's/name="SND_DEVICE_IN_VOICE_REC_MIC" acdb_id=".*"/name="SND_DEVICE_IN_VOICE_REC_MIC" acdb_id="41"/g' $APIIXML

sed -i 's/name="SND_DEVICE_IN_UNPROCESSED_MIC" acdb_id=".*"/name="SND_DEVICE_IN_UNPROCESSED_MIC" acdb_id="41"/g' $APIEXML
sed -i 's/name="SND_DEVICE_IN_VOICE_REC_TMIC" acdb_id=".*"/name="SND_DEVICE_IN_VOICE_REC_TMIC" acdb_id="41"/g' $APIEXML
sed -i 's/name="SND_DEVICE_IN_VOICE_REC_MIC" acdb_id=".*"/name="SND_DEVICE_IN_VOICE_REC_MIC" acdb_id="41"/g' $APIEXML

sed -i 's/name="SND_DEVICE_IN_UNPROCESSED_MIC" acdb_id=".*"/name="SND_DEVICE_IN_UNPROCESSED_MIC" acdb_id="41"/g' $APIQRDXML
sed -i 's/name="SND_DEVICE_IN_VOICE_REC_TMIC" acdb_id=".*"/name="SND_DEVICE_IN_VOICE_REC_TMIC" acdb_id="41"/g' $APIQRDXML
sed -i 's/name="SND_DEVICE_IN_VOICE_REC_MIC" acdb_id=".*"/name="SND_DEVICE_IN_VOICE_REC_MIC" acdb_id="41"/g' $APIQRDXML
fi

ui_print " "
ui_print "   ########================================ 20% done!"

#patch audio_configs.xml
if [ "$STEP7" == "true" ]; then
for OACONFS in ${ACONFS}; do
ACFG="$MODPATH$(echo $OACONFS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OACONFS $ACFG
sed -i 's/\t/  /g' $ACFG
sed -i 's/audio.deep_buffer.media" value="true"/audio.deep_buffer.media" value="false"/g' $ACFG
sed -i 's/audio.offload.disable" value="false"/audio.offload.disable" value="true"/g' $ACFG
sed -i 's/audio.offload.min.duration.secs" value="*."/audio.offload.min.duration.secs" value="30"/g' $ACFG
sed -i 's/audio.offload.video" value="true"/audio.offload.video" value="false"/g' $ACFG
sed -i 's/persist.vendor.audio.sva.conc.enabled" value="true"/persist.vendor.audio.sva.conc.enabled" value="false"/g' $ACFG
sed -i 's/persist.vendor.audio.va_concurrency_enabled" value="true"/persist.vendor.audio.va_concurrency_enabled" value="false"/g' $ACFG
sed -i 's/vendor.audio.av.streaming.offload.enable" value="true"/vendor.audio.av.streaming.offload.enable" value="false"/g' $ACFG
sed -i 's/vendor.audio.offload.track.enable" value="true"/vendor.audio.offload.track.enable" value="false"/g' $ACFG
sed -i 's/vendor.audio.offload.multiple.enabled" value="true"/vendor.audio.offload.multiple.enabled" value="false"/g' $ACFG
sed -i 's/vendor.audio.rec.playback.conc.disabled" value="true"/vendor.audio.rec.playback.conc.disabled" value="false"/g' $ACFG
sed -i 's/vendor.voice.conc.fallbackpath" value="*."/vendor.voice.conc.fallbackpath" value=""/g' $ACFG
sed -i 's/vendor.voice.dsd.playback.conc.disabled" value="true"/vendor.voice.dsd.playback.conc.disabled" value="false"/g' $ACFG
sed -i 's/vendor.voice.path.for.pcm.voip" value="true"/vendor.voice.path.for.pcm.voip" value="false"/g' $ACFG
sed -i 's/vendor.voice.playback.conc.disabled" value="true"/vendor.voice.playback.conc.disabled" value="false"/g' $ACFG
sed -i 's/vendor.voice.record.conc.disabled" value="true"/vendor.voice.record.conc.disabled" value="false"/g' $ACFG
sed -i 's/vendor.voice.voip.conc.disabled" value="true"/vendor.voice.voip.conc.disabled" value="false"/g' $ACFG
sed -i 's/audio_extn_formats_enabled" value="false"/audio_extn_formats_enabled" value="true"/g' $ACFG
sed -i 's/audio_extn_hdmi_spk_enabled" value="false"/audio_extn_hdmi_spk_enabled" value="true"/g' $ACFG
sed -i 's/use_xml_audio_policy_conf" value="false"/use_xml_audio_policy_conf" value="true"/g' $ACFG
sed -i 's/voice_concurrency" value="true"/voice_concurrency" value="false"/g' $ACFG
sed -i 's/afe_proxy_enabled" value="false"/afe_proxy_enabled" value="true"/g' $ACFG
sed -i 's/compress_voip_enabled" value="true"/compress_voip_enabled" value="false"/g' $ACFG
sed -i 's/fm_power_opt" value="false"/fm_power_opt" value="true"/g' $ACFG
sed -i 's/battery_listener_enabled" value="true"/battery_listener_enabled" value="false"/g' $ACFG
sed -i 's/compress_capture_enabled" value="true"/compress_capture_enabled" value="false"/g' $ACFG
sed -i 's/compress_metadata_needed" value="true"/compress_metadata_needed" value="false"/g' $ACFG
sed -i 's/dynamic_ecns_enabled" value="false"/dynamic_ecns_enabled" value="true"/g' $ACFG
sed -i 's/custom_stereo_enabled" value="false"/custom_stereo_enabled" value="true"/g' $ACFG
sed -i 's/ext_hw_plugin_enabled" value="false"/ext_hw_plugin_enabled" value="true"/g' $ACFG
sed -i 's/ext_qdsp_enabled" value="false"/ext_qdsp_enabled" value="true"/g' $ACFG
sed -i 's/ext_spkr_enabled" value="false"/ext_spkr_enabled" value="true"/g' $ACFG
sed -i 's/ext_spkr_tfa_enabled" value="false"/ext_spkr_tfa_enabled" value="true"/g' $ACFG
sed -i 's/keep_alive_enabled" value="false"/keep_alive_enabled" value="true"/g' $ACFG
sed -i 's/hifi_audio_enabled" value="false"/hifi_audio_enabled" value="true"/g' $ACFG
sed -i 's/extn_resampler" value="false"/extn_resampler" value="true"/g' $ACFG
sed -i 's/extn_flac_decoder" value="true"/extn_flac_decoder" value="false"/g' $ACFG
sed -i 's/extn_compress_format" value="false"/extn_compress_format" value="true"/g' $ACFG
sed -i 's/spkr_protection" value="true"/spkr_protection" value="false"/g' $ACFG
sed -i 's/usb_offload_sidetone_vol_enabled" value="true"/usb_offload_sidetone_vol_enabled" value="false"/g' $ACFG
sed -i 's/usb_offload_burst_mode" value="true"/usb_offload_burst_mode" value="false"/g' $ACFG
sed -i 's/pcm_offload_enabled_16" value="true"/pcm_offload_enabled_16" value="false"/g' $ACFG
sed -i 's/pcm_offload_enabled_24" value="true"/pcm_offload_enabled_24" value="false"/g' $ACFG
sed -i 's/pcm_offload_enabled_32" value="true"/pcm_offload_enabled_32" value="false"/g' $ACFG
sed -i 's/a2dp_offload_enabled" value="true"/a2dp_offload_enabled" value="false"/g' $ACFG
sed -i 's/vendor.audio.use.sw.alac.decoder" value="false"/vendor.audio.use.sw.alac.decoder" value="true"/g' $ACFG
sed -i 's/vendor.audio.use.sw.ape.decoder" value="false"/vendor.audio.use.sw.ape.decoder" value="true"/g' $ACFG
sed -i 's/vendor.audio.use.sw.mpegh.decoder" value="false"/vendor.audio.use.sw.mpegh.decoder" value="true"/g' $ACFG
sed -i 's/vendor.audio.flac.sw.decoder.24bit" value="false"/vendor.audio.flac.sw.decoder.24bit" value="true"/g' $ACFG
sed -i 's/vendor.audio.hw.aac.encoder" value="false"/vendor.audio.hw.aac.encoder" value="true"/g' $ACFG
sed -i 's/aac_adts_offload_enabled" value="true"/aac_adts_offload_enabled" value="false"/g' $ACFG
sed -i 's/alac_offload_enabled" value="true"/alac_offload_enabled" value="false"/g' $ACFG
sed -i 's/ape_offload_enabled" value="true"/ape_offload_enabled" value="false"/g' $ACFG
sed -i 's/flac_offload_enabled" value="true"/flac_offload_enabled" value="false"/g' $ACFG
sed -i 's/qti_flac_decoder" value="false"/qti_flac_decoder" value="true"/g' $ACFG
sed -i 's/vorbis_offload_enabled" value="true"/vorbis_offload_enabled" value="false"/g' $ACFG
sed -i 's/wma_offload_enabled" value="true"/wma_offload_enabled" value="false"/g' $ACFG
done
fi

if [ "$STEP8" == "true" ]; then
for ODEVFEA in ${DEVFEAS}; do 
DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$ODEVFEA $DEVFEA
sed -i 's/\t/  /g' $DEVFEA
sed -i 's/support_a2dp_latency" value="false"/support_a2dp_latency" value="true"/g' $DEVFEA
sed -i 's/support_samplerate_48000" value="false"/support_samplerate_48000" value="true"/g' $DEVFEA
sed -i 's/support_samplerate_96000" value="false"/support_samplerate_96000" value="true"/g' $DEVFEA
sed -i 's/support_samplerate_192000" value="false"/support_samplerate_192000" value="true"/g' $DEVFEA
sed -i 's/support_low_latency" value="false"/support_low_latency" value="true"/g' $DEVFEA
sed -i 's/support_mid_latency" value="true"/support_mid_latency" value="false"/g' $DEVFEA
sed -i 's/support_high_latency" value="true"/support_high_latency" value="false"/g' $DEVFEA
sed -i 's/support_interview_record_param" value="true"/support_interview_record_param" value="false"/g' $DEVFEA
sed -i 's/ext_qdsp_enabled" value="false"/ext_qdsp_enabled" value="true"/g' $DEVFEA
sed -i 's/ext_qdsp_enabled" value="false"/ext_qdsp_enabled" value="true"/g' $DEVFEA
sed -i 's/ext_qdsp_enabled" value="false"/ext_qdsp_enabled" value="true"/g' $DEVFEA
sed -i 's/ext_qdsp_enabled" value="false"/ext_qdsp_enabled" value="true"/g' $DEVFEA
done
fi


if [ "$STEP9" == "true" ]; then
for OFILE in ${AECFGS}; do
FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OFILE $FILE
sed -i 's/\t/  /g' $FILE
altmemes_confxml $FILE
memes_confxml "dirac_gef" "dirac_gef" "$DYNLIBPATCH\/lib\/soundfx" "libdiraceffect.so" "3799d6d1-22c5-43c3-b3ec-d664cf8d2f0d"
effects_patching -post "$FILE" "music" "dirac_gef"
done

mkdir -p $MODPATH/system/vendor/etc/dirac $MODPATH/system/vendor/lib/rfsa/adsp $MODPATH/system/vendor/lib/soundfx
cp_ch $NEWdirac/diracvdd.bin $MODPATH/system/vendor/etc/
cp_ch $NEWdirac/interfacedb $MODPATH/system/vendor/etc/dirac
cp_ch $NEWdirac/dirac_resource.dar $MODPATH/system/vendor/lib/rfsa/adsp
cp_ch $NEWdirac/dirac.so $MODPATH/system/vendor/lib/rfsa/adsp
cp_ch $NEWdirac/libdirac-capiv2.so $MODPATH/system/vendor/lib/rfsa/adsp
cp_ch $NEWdirac/libdiraceffect.so $MODPATH/system/vendor/lib/soundfx

echo -e '\n# Dirac configurations by NLSound Team
persist.dirac.acs.controller=gef
persist.dirac.gef.oppo.syss=true
persist.dirac.config=64
persist.dirac.gef.exs.did=50,50
persist.dirac.gef.ext.did=150,150,150,150
persist.dirac.gef.ins.did=50,50,50
persist.dirac.gef.int.did=150,150,150,150
persist.dirac.gef.ext.appt=0x00011130,0x00011134,0x00011136
persist.dirac.gef.exs.appt=0x00011130,0x00011131
persist.dirac.gef.int.appt=0x00011130,0x00011134,0x00011136
persist.dirac.gef.ins.appt=0x00011130,0x00011131
persist.dirac.gef.exs.mid=268512739
persist.dirac.gef.ext.mid=268512737
persist.dirac.gef.ins.mid=268512738
persist.dirac.gef.int.mid=268512736
persist.dirac.path=/vendor/etc/dirac
ro.dirac.acs.storeSettings=1
persist.dirac.acs.ignore_error=1
ro.audio.soundfx.dirac=true
ro.vendor.audio.soundfx.type=dirac
persist.audio.dirac.speaker=true
persist.audio.dirac.eq=0.0,0.0,0.0,0.0,0.0,0.0,0.0
persist.audio.dirac.headset=0
persist.audio.dirac.music.state=1' >> $PROP
fi

if [ "$STEP11" == "true" ]; then
echo -e "\n# Better parameters audio by NLSound Team
flac.sw.decoder.24bit.support=true
vendor.audio.flac.sw.decoder.24bit=true
vendor.audio.aac.sw.decoder.24bit=true
vendor.audio.mp3.sw.decoder.24bit=true
vendor.audio.ac3.sw.decoder.24bit=true
vendor.audio.eac3.sw.decoder.24bit=true
vendor.audio.eac3_joc.sw.decoder.24bit=true
vendor.audio.ac4.sw.decoder.24bit=true
vendor.audio.opus.sw.decoder.24bit=true
vendor.audio.qti.sw.decoder.24bit=true
vendor.audio.dsp.sw.decoder.24bit=true
vendor.audio.dsd.sw.decoder.24bit=true
vendor.audio.flac.sw.encoder.24bit=true
vendor.audio.aac.sw.encoder.24bit=true
vendor.audio.mp3.sw.encoder.24bit=true
vendor.audio.raw.sw.encoder.24bit=true
vendor.audio.ac3.sw.encoder.24bit=true
vendor.audio.eac3.sw.encoder.24bit=true
vendor.audio.eac3_joc.sw.encoder.24bit=true
vendor.audio.ac4.sw.encoder.24bit=true
vendor.audio.opus.sw.encoder.24bit=true
vendor.audio.qti.sw.encoder.24bit=true
vendor.audio.dsp.sw.encoder.24bit=true
vendor.audio.dsd.sw.encoder.24bit=true

vendor.audio.flac.complexity.default=10
vendor.audio.flac.quality=100
vendor.audio.aac.complexity.default=10
vendor.audio.aac.quality=100
vendor.audio.mp3.complexity.default=10
vendor.audio.mp3.quality=100
vendor.audio.qti.complexity.default=10
vendor.audio.qti.quality=100
vendor.audio.ac3.complexity.default=10
vendor.audio.ac3.quality=100
vendor.audio.eac3.complexity.default=10
vendor.audio.eac3.quality=100
vendor.audio.eac3_joc.complexity.default=10
vendor.audio.eac3_joc.quality=100
vendor.audio.ac4.complexity.default=10
vendor.audio.ac4.quality=100
vendor.audio.opus.complexity.default=10
vendor.audio.opus.quality=100
vendor.audio.dsp.complexity.default=10
vendor.audio.dsp.quality=100
vendor.audio.dsd.complexity.default=10
vendor.audio.dsd.quality=100

use.non-omx.flac.decoder=false
use.non-omx.aac.decoder=false
use.non-omx.mp3.decoder=false
use.non-omx.raw.decoder=false
use.non-omx.qti.decoder=false
use.non-omx.ac3.decoder=false
use.non-omx.ac4.decoder=false
use.non-omx.opus.decoder=false
use.non-omx.dsp.decoder=false
use.non-omx.dsd.decoder=false
use.non-omx.flac.encoder=false
use.non-omx.aac.encoder=false
use.non-omx.mp3.encoder=false
use.non-omx.raw.encoder=false
use.non-omx.qti.encoder=false
use.non-omx.ac3.encoder=false
use.non-omx.ac4.encoder=false
use.non-omx.opus.encoder=false
use.non-omx.dsp.encoder=false
use.non-omx.dsd.encoder=false

af.thread.throttle=0
af.fast_downmix=1
ro.vendor.af.raise_bt_thread_prio=true

audio.decoder_override_check=true
vendor.qc2audio.suspend.enabled=false
vendor.qc2audio.per_frame.flac.dec.enabled=true
ro.mediacodec.min_sample_rate=48000
ro.mediacodec.max_sample_rate=384000
media.stagefright.thumbnail.prefer_hw_codecs=true

vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
tunnel.audiovideo.decode=true
tunnel.decode=true
qc.tunnel.audio.encode=true

lpa.decode=false
lpa30.decode=false
lpa.use-stagefright=false
lpa.releaselock=false

audio.playback.mch.downsample=false
persist.vendor.audio.playback.mch.downsample=false

vendor.audio.feature.dsm_feedback.enable=true
vendor.audio.feature.dynamic_ecns.enable=true
vendor.audio.feature.external_dsp.enable=true
vendor.audio.feature.external_speaker.enable=true
vendor.audio.feature.external_speaker_tfa.enable=true
vendor.audio.feature.ext_hw_plugin.enable=true
vendor.audio.feature.keep_alive.enable=true
vendor.audio.feature.compress_meta_data.enable=false
vendor.audio.feature.compr_cap.enable=false
vendor.audio.feature.devicestate_listener.enable=false
vendor.audio.feature.thermal_listener.enable=false
vendor.audio.feature.power_mode.enable=true
vendor.audio.feature.hifi_audio.enable=true
vendor.audio.feature.keep_alive.enable=true
vendor.audio.feature.deepbuffer_as_primary.enable=false 
vendor.audio.feature.dmabuf.cma.memory.enable=true
vendor.audio.feature.battery_listener.enable=false
vendor.audio.feature.custom_stereo.enable=true
vendor.audio.feature.wsa.enable=true

vendor.audio.usb.super_hifi=true
ro.audio.hifi=true
ro.config.hifi_config_state=1
ro.config.hifi_enhance_support=1
ro.hardware.hifi.support=true
persist.audio.hifi=true
persist.audio.hifi.volume=90
persist.audio.hifi.int_codec=true
persist.audio.hifi_adv_support=1
persist.audio.hifi_dac=ON
persist.vendor.audio.hifi_enabled=true
persist.vendor.audio.hifi.int_codec=true

audio.spatializer.effect.util_clamp_min=300
effect.reverb.pcm=1
sys.vendor.atmos.passthrough=enable
vendor.audio.dolby.ds2.enabled=true
vendor.audio.keep_alive.disabled=false
vendor.audio.dolby.control.support=true
vendor.audio.dolby.control.tunning.by.volume.support=true
ro.vendor.audio.elus.enable=true
ro.audio.spatializer_enabled=true
ro.vendor.audio.soundfx.usb=false
ro.vendor.audio.sfx.speaker=false 
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false 
ro.vendor.audio.sfx.independentequalizer=false 
ro.vendor.audio.3d.audio.support=true
ro.vendor.audio.surround.support=true
ro.vendor.audio.dolby.eq.half=true
ro.vendor.audio.dolby.surround.enable=true
ro.vendor.audio.dolby.fade_switch=true
ro.vendor.media.video.meeting.support=true
persist.vendor.audio.ambisonic.capture=true
persist.vendor.audio.ambisonic.auto.profile=true

audio.record.delay=0
vendor.voice.dsd.playback.conc.disabled=false
vendor.audio.3daudio.record.enable=true
vendor.audio.hdr.spf.record.enable=true
vendor.audio.hdr.record.enable=true
vendor.audio.chk.cal.us=1
ro.vendor.audio.recording.hd=true
ro.vendor.audio.sdk.ssr=false 
ro.qc.sdk.audio.ssr=false 
persist.audio.lowlatency.rec=true
persist.vendor.audio.endcall.delay=0
persist.vendor.audio.record.ull.support=true

audio.offload.24bit.enable=1
vendor.usb.analog_audioacc_disabled=false
vendor.audio.enable.cirrus.speaker=true
vendor.audio.sys.init=true
vendor.audio.trace.enable=true
vendor.audio.powerop=true
vendor.audio.read.wsatz.type=true
vendor.audio.powerhal.power.ul=true
vendor.audio.powerhal.power.dl=true
vendor.audio.hal.boot.timeout.ms=5000
vendor.audio.gsl.shmem.dmaheap.uncached=true
vendor.audio.LL.coeff=100
vendor.audio.caretaker.at=true
vendor.audio.matrix.limiter.enable=0
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.hal.output.suspend.supported=false
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.camera.unsupport_low_latency=false 
vendor.audio.tfa9874.dsp.enabled=true
vendor.audio.lowpower=false
vendor.audio.compress_capture.enabled=false 
vendor.audio.compress_capture.aac=false
vendor.audio.spkr_prot.tx.sampling_rate=192000
vendor.audio.rt.mode=23
vendor.audio.rt.mode.onlyfast=false 
vendor.audio.cpu.sched=31
vendor.audio.cpu.sched.cpuset=248
vendor.audio.cpu.sched.cpuset.binder=255
vendor.audio.cpu.sched.cpuset.at=248
vendor.audio.cpu.sched.cpuset.af=248
vendor.audio.cpu.sched.cpuset.hb=248
vendor.audio.cpu.sched.cpuset.hso=248
vendor.audio.cpu.sched.cpuset.he=248
vendor.audio.cpu.sched.cpus=8
vendor.audio.cpu.sched.onlyfast=false 
vendor.media.amplayer.audiolimiter=false 
vendor.media.amplayer.videolimiter=false 
vendor.media.audio.ms12.downmixmode=on
ro.audio.resampler.psd.enable_at_samplerate=192000
ro.audio.resampler.psd.halflength=240
ro.audio.resampler.psd.stopband=20
ro.audio.resampler.psd.cutoff_percent=100
ro.audio.resampler.psd.tbwcheat=110
ro.audio.soundtrigger.lowpower=false
ro.vendor.audio_tunning.dual_spk=2
ro.vendor.audio_tunning.nr=1
ro.vendor.audio.frame_count_needed_constant=32768
ro.vendor.audio.soundtrigger.wakeupword=5
ro.vendor.audio.ce.compensation.need=true
ro.vendor.audio.ce.compensation.value=5
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
ro.vendor.audio.spk.clean=false
ro.vendor.audio.3d.audio.support=true
ro.vendor.audio.pastandby=true
ro.vendor.audio.dpaudio=true
ro.vendor.audio.spk.stereo=true
ro.vendor.audio.dualadc.support=true
ro.vendor.audio.meeting.mode=true
ro.vendor.media.support.omx2=true
ro.vendor.platform.disable.audiorawout=false
ro.vendor.platform.has.realoutputmode=true
ro.vendor.platform.support.dolby=true
ro.vendor.platform.support.dts=true
ro.vendor.usb.support_analog_audio=true
ro.mediaserver.64b.enable=true
persist.audio.hp=true
persist.config.speaker_protect_enabled=0
persist.sys.audio.source=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.cca.enabled=true
persist.vendor.audio.misoundasc=true
persist.vendor.audio.okg_hotword_ext_dsp=true
persist.vendor.audio.format.24bit=true
persist.vendor.audio.speaker.stereo=true
persist.vendor.audio_hal.dsp_bit_width_enforce_mode=24

persist.vendor.audio.ll_playback_bargein=true
persist.vendor.audio.delta.refresh=true" >> $PROP
#exit
fi

ui_print " "
ui_print "   ################======================== 40% done!"

if [ "$STEP12" == "true" ]; then
echo -e "\n# Bluetooth parameters by NLSound Team
config.disable_bluetooth=false
bluetooth.profile.a2dp.source.enabled=true
vendor.audio.effect.a2dp.enable=1
vendor.bluetooth.ldac.abr=false 
vendor.media.audiohal.btwbs=true
qcom.hw.aac.encoder=true
qcom.hw.aac.decoder=true
ro.vendor.audio.hw.aac.encoder=true
ro.vendor.audio.hw.aac.decoder=true
ro.vendor.bluetooth.csip_qti=true
persist.service.btui.use_aptx=1
persist.bt.a2dp.aac_disable=false
persist.bt.sbc_hd_enabled=1
persist.bt.power.down=false 
persist.vendor.audio.sys.a2h_delay_for_a2dp=50
persist.vendor.btstack.enable.lpa=false
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
persist.vendor.bt.splita2dp.44_1_war=true
persist.vendor.qcom.bluetooth.aidl_hal=true
persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true
persist.vendor.btstack.enable.twsplussho=true
persist.vendor.btstack.enable.twsplus=true
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
persist.vendor.qcom.bluetooth.scram.enabled=false 
persist.vendor.bluetooth.prefferedrole=master
persist.vendor.bluetooth.leaudio_mode=off
persist.vendor.bluetooth.connection_improve=yes
persist.bluetooth.a2dp_offload.aidl_flag=aidl
persist.bluetooth.dualconnection.supported=true
persist.bluetooth.a2dp_aac_abr.enable=false
persist.bluetooth.bluetooth_audio_hal.disabled=false
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true" >> $PROP
fi

#patching audio_io_policy file
for OIOPOLICY in ${IOPOLICYS}; do
IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OIOPOLICY $IOPOLICY
sed -i 's/\t/  /g' $IOPOLICY

if [ "$STEP13" == "true" ]; then
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
fi

if [ "$BITNESINT" == "24" ]; then
sed -i '/deep_buffer/,+6d' $IOPOLICY
sed -i '/^outputs/a\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates '$SAMPLERATEINT'\
    bit_width 24\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates '$SAMPLERATEINT'\
    bit_width 24\
    app_type 69940\
  }' $IOPOLICY
fi

if [ "$BITNESINT" == "32" ]; then
sed -i '/deep_buffer/,+6d' $IOPOLICY
sed -i '/^outputs/a\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates '$SAMPLERATEINT'\
    bit_width 32\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates '$SAMPLERATEINT'\
    bit_width 32\
    app_type 69940\
  }' $IOPOLICY
fi

if [ "$BITNESINT" == "float" ]; then
sed -i '/deep_buffer/,+6d' $IOPOLICY
sed -i '/^outputs/a\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates '$SAMPLERATEINT'\
    bit_width float\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates '$SAMPLERATEINT'\
    bit_width float\
    app_type 69940\
  }' $IOPOLICY
fi
done

#patching audio_output_policy file
for OOUTPUTPOLICY in ${OUTPUTPOLICYS}; do
OUTPUTPOLICY="$MODPATH$(echo $OUTPUTPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OOUTPUTPOLICY $OUTPUTPOLICY
sed -i 's/\t/  /g' $OUTPUTPOLICY

if [ "$STEP13" == "true" ]; then
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $OUTPUTPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $OUTPUTPOLICY
fi

if [ "$BITNESINT" == "24" ]; then
sed -i '/deep_buffer/,+6d' $OUTPUTPOLICY
sed -i '/^outputs/a\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates $SAMPLERATEINT\
    bit_width 24\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates $SAMPLERATEINT\
    bit_width 24\
    app_type 69937\
  }' $OUTPUTPOLICY
fi

if [ "$BITNESINT" == "32" ]; then
sed -i '/deep_buffer/,+6d' $OUTPUTPOLICY
sed -i '/^outputs/a\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates $SAMPLERATEINT\
    bit_width 32\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates $SAMPLERATEINT\
    bit_width 32\
    app_type 69937\
  }' $OUTPUTPOLICY
fi

if [ "$BITNESINT" == "float" ]; then
sed -i '/deep_buffer/,+6d' $OUTPUTPOLICY
sed -i '/^outputs/a\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates $SAMPLERATEINT\
    bit_width float\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates $SAMPLERATEINT\
    bit_width float\
    app_type 69937\
  }' $OUTPUTPOLICY
fi
done

#disable drc and use direct_pcm route
for OAUDIOPOLICY in ${AUDIOPOLICYS}; do
AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OAUDIOPOLICY $AUDIOPOLICY
sed -i 's/\t/  /g' $AUDIOPOLICY
sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
#exit
done

#patching media codecs files
for OMCODECS in ${MCODECS}; do
MEDIACODECS="$MODPATH$(echo $OMCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OMCODECS $MEDIACODECS
sed -i 's/\t/  /g' $MEDIACODECS
sed -i 's/<<!--.*-->>//; s/<!--.*-->>//; s/<<!--.*-->//; s/<!--.*-->//; /<!--/,/-->/d; /^ *#/d; /^ *$/d' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="8000,11025,12000,16000,22050,24000,32000,44100,48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="32000,44100,48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="7350,8000,11025,12000,16000,22050,24000,32000,44100,48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="8000-48000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="8000-96000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="sample-rate" ranges="8000-192000"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
sed -i 's/name="bitrate-modes" value="CBR"/name="bitrate-modes" value="CQ"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-10"  default="9"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-10"  default="8"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-10"  default="7"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-10"  default="6"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-8"  default="7"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-8"  default="6"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-8"  default="5"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="complexity" range="0-8"  default="4"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
sed -i 's/name="quality" range="0-80"  default="100"/name="quality" range="0-100"  default="100"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="8000-320000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="8000-960000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="32000-500000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="6000-510000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="1-10000000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="500-512000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="32000-640000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="32000-6144000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="16000-2688000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i 's/name="bitrate" range="64000"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
sed -i '/^ *#/d; /^ *$/d' $MEDIACODECS
done

ui_print " "                 
ui_print "   ########################================ 60% done!"

for OMIX in ${MPATHS}; do
MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
cp_ch -f $ORIGDIR$OMIX $MIX
sed -i 's/\t/  /g' $MIX
if [ "$VOLMEDIASINT" != "Skip" ]; then
patch_xml -u $MIX '/mixer/ctl[@name="RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX4 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX5 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX6 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX7 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -s $MIX '/mixer/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -s $MIX '/mixer/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX4 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX5 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX6 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX7 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX4 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX5 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX6 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX7 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX4 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX5 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX6 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX7 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_RX0 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_RX1 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_RX2 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIASINT"
patch_xml -u $MIX '/mixer/ctl[@name="LINEOUT1 Volume"]' "5"
patch_xml -u $MIX '/mixer/ctl[@name="LINEOUT2 Volume"]' "5"
fi

if [ "$STEP14" == "true" ]; then
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="0"]' "268833620"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="1"]' "537398060"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="2"]' "267510580"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="3"]' "537398060"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="4"]' "267908744"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="0"]' "266468108"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="1"]' "544862876"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="2"]' "262421829"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="3"]' "544862876"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="4"]' "260454481"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="0"]' "262913321"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="1"]' "559557058"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="2"]' "252311547"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="3"]' "559557058"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="4"]' "246789412"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="0"]' "294517138"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="1"]' "572289454"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="2"]' "210943778"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="3"]' "572289454"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="4"]' "237025461"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="0"]' "329006442"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="1"]' "711929387"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="2"]' "110068469"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="3"]' "711929387"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="4"]' "170639455"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band0"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band1"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band2"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band3"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band4"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band5"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP0 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP4 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP5 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "RX1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 MUX"]' "RX1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 MUX"]' "RX1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "RX2"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 MUX"]' "RX2"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 MUX"]' "RX2"
fi

if [ "$VOLMICINT" != "Skip" ]; then
patch_xml -u $MIX '/mixer/ctl[@name="ADC0 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="ADC1 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="ADC2 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="ADC3 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="ADC4 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="DEC0 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="DEC1 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="DEC2 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="DEC3 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="DEC4 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="DEC5 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="DEC6 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="DEC7 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="DEC8 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC0 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC1 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC2 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC3 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC4 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC5 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC6 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC7 Volume"]' "$VOLMICINT"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC8 Volume"]' "$VOLMICINT"
fi

if [ "$STEP6" == "true" ]; then
sed -i 's/COMP Switch" value="1"/COMP Switch" value="0"/g' $MIX
sed -i 's/COMP0 Switch" value="1"/COMP0 Switch" value="0"/g' $MIX
sed -i 's/COMP1 Switch" value="1"/COMP1 Switch" value="0"/g' $MIX
sed -i 's/COMP2 Switch" value="1"/COMP2 Switch" value="0"/g' $MIX
sed -i 's/COMP3 Switch" value="1"/COMP3 Switch" value="0"/g' $MIX
sed -i 's/COMP4 Switch" value="1"/COMP4 Switch" value="0"/g' $MIX
sed -i 's/COMP5 Switch" value="1"/COMP5 Switch" value="0"/g' $MIX
sed -i 's/COMP6 Switch" value="1"/COMP6 Switch" value="0"/g' $MIX
sed -i 's/COMP7 Switch" value="1"/COMP7 Switch" value="0"/g' $MIX
sed -i 's/COMP8 Switch" value="1"/COMP8 Switch" value="0"/g' $MIX
sed -i 's/WSA_COMP1 Switch" value="1"/WSA_COMP1 Switch" value="0"/g' $MIX
sed -i 's/WSA_COMP2 Switch" value="1"/WSA_COMP1 Switch" value="0"/g' $MIX
sed -i 's/WSA_COMP3 Switch" value="1"/WSA_COMP1 Switch" value="0"/g' $MIX
sed -i 's/WSA_COMP4 Switch" value="1"/WSA_COMP1 Switch" value="0"/g' $MIX
sed -i 's/WSA_COMP5 Switch" value="1"/WSA_COMP1 Switch" value="0"/g' $MIX
sed -i 's/WSA_COMP6 Switch" value="1"/WSA_COMP1 Switch" value="0"/g' $MIX
sed -i 's/WSA_COMP7 Switch" value="1"/WSA_COMP1 Switch" value="0"/g' $MIX
sed -i 's/WSA_COMP8 Switch" value="1"/WSA_COMP1 Switch" value="0"/g' $MIX
sed -i 's/RX_COMP1 Switch" value="1"/RX_COMP1 Switch" value="0"/g' $MIX
sed -i 's/RX_COMP2 Switch" value="1"/RX_COMP1 Switch" value="0"/g' $MIX
sed -i 's/RX_COMP3 Switch" value="1"/RX_COMP1 Switch" value="0"/g' $MIX
sed -i 's/RX_COMP4 Switch" value="1"/RX_COMP1 Switch" value="0"/g' $MIX
sed -i 's/RX_COMP5 Switch" value="1"/RX_COMP1 Switch" value="0"/g' $MIX
sed -i 's/RX_COMP6 Switch" value="1"/RX_COMP1 Switch" value="0"/g' $MIX
sed -i 's/RX_COMP7 Switch" value="1"/RX_COMP1 Switch" value="0"/g' $MIX
sed -i 's/RX_COMP8 Switch" value="1"/RX_COMP1 Switch" value="0"/g' $MIX
sed -i 's/HPHL_COMP Switch" value="1"/HPHL_COMP Switch" value="0"/g' $MIX
sed -i 's/HPHR_COMP Switch" value="1"/HPHR_COMP Switch" value="0"/g' $MIX
sed -i 's/Softclip0 Enable" value="0"/Softclip0 Enable" value="1"/g' $MIX
sed -i 's/Softclip1 Enable" value="0"/Softclip1 Enable" value="1"/g' $MIX
sed -i 's/Softclip2 Enable" value="0"/Softclip2 Enable" value="1"/g' $MIX
sed -i 's/Softclip3 Enable" value="0"/Softclip3 Enable" value="1"/g' $MIX
sed -i 's/Softclip4 Enable" value="0"/Softclip4 Enable" value="1"/g' $MIX
sed -i 's/Softclip5 Enable" value="0"/Softclip5 Enable" value="1"/g' $MIX
sed -i 's/Softclip6 Enable" value="0"/Softclip6 Enable" value="1"/g' $MIX
sed -i 's/Softclip7 Enable" value="0"/Softclip7 Enable" value="1"/g' $MIX
sed -i 's/Softclip8 Enable" value="0"/Softclip8 Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip Enable" value="0"/"RX_Softclip Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip0 Enable" value="0"/"RX_Softclip0 Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip1 Enable" value="0"/"RX_Softclip1 Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip2 Enable" value="0"/"RX_Softclip2 Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip3 Enable" value="0"/"RX_Softclip3 Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip4 Enable" value="0"/"RX_Softclip4 Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip5 Enable" value="0"/"RX_Softclip5 Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip6 Enable" value="0"/"RX_Softclip6 Enable" value="1"/g' $MIX
sed -i 's/"RX_Softclip7 Enable" value="0"/"RX_Softclip7 Enable" value="1"/g' $MIX
sed -i 's/"WSA_Softclip0 Enable" value="0"/"WSA_Softclip0 Enable" value="1"/g' $MIX
sed -i 's/"WSA_Softclip1 Enable" value="0"/"WSA_Softclip1 Enable" value="1"/g' $MIX
sed -i 's/"WSA_Softclip2 Enable" value="0"/"WSA_Softclip2 Enable" value="1"/g' $MIX
sed -i 's/"WSA_Softclip3 Enable" value="0"/"WSA_Softclip3 Enable" value="1"/g' $MIX
sed -i 's/"WSA_Softclip4 Enable" value="0"/"WSA_Softclip4 Enable" value="1"/g' $MIX
sed -i 's/"WSA_Softclip5 Enable" value="0"/"WSA_Softclip5 Enable" value="1"/g' $MIX
sed -i 's/"WSA_Softclip6 Enable" value="0"/"WSA_Softclip6 Enable" value="1"/g' $MIX
sed -i 's/"WSA_Softclip7 Enable" value="0"/"WSA_Softclip7 Enable" value="1"/g' $MIX
sed -i 's/SpkrLeft BOOST Switch" value="1"/SpkrLeft BOOST Switch" value="0"/g' $MIX
sed -i 's/SpkrRight BOOST Switch" value="1"/SpkrRight BOOST Switch" value="0"/g' $MIX
sed -i 's/SpkrLeft SWR DAC_Port Switch" value="1"/SpkrLeft SWR DAC_Port Switch" value="0"/g' $MIX
sed -i 's/SpkrRight SWR DAC_Port Switch" value="1"/SpkrRight SWR DAC_Port Switch" value="0"/g' $MIX
sed -i 's/HPHL_RDAC Switch" value="0"/HPHL_RDAC Switch" value="1"/g' $MIX
sed -i 's/HPHR_RDAC Switch" value="0"/HPHR_RDAC Switch" value="1"/g' $MIX
sed -i 's/Boost Class-H Tracking Enable" value="0"/Boost Class-H Tracking Enable" value="1"/g' $MIX
sed -i 's/DRE DRE Switch" value="0"/DRE DRE Switch" value="1"/g' $MIX
sed -i 's/"HFP_SLIM7_UL_HL Switch" value="1"/"HFP_SLIM7_UL_HL Switch" value="0"/g' $MIX
sed -i 's/"HFP_PRI_AUX_UL_HL Switch" value="1"/"HFP_PRI_AUX_UL_HL Switch" value="0"/g' $MIX
sed -i 's/"HFP_AUX_UL_HL Switch" value="1"/"HFP_AUX_UL_HL Switch" value="0"/g' $MIX
sed -i 's/"HFP_INT_UL_HL Switch" value="1"/"HFP_INT_UL_HL Switch" value="0"/g' $MIX
sed -i 's/"SCO_SLIM7_DL_HL Switch" value="1"/"SCO_SLIM7_DL_HL Switch" value="0"/g' $MIX
sed -i 's/"SLIMBUS7_DL_HL Switch" value="1"/"SLIMBUS7_DL_HL Switch" value="0"/g' $MIX
sed -i 's/"SLIM7_RX_DL_HL Switch" value="1"/"SLIM7_RX_DL_HL Switch" value="0"/g' $MIX
sed -i 's/"PCM_RX_DL_HL Switch" value="1"/"PCM_RX_DL_HL Switch" value="0"/g' $MIX
sed -i 's/"USB_DL_HL Switch" value="1"/"USB_DL_HL Switch" value="0"/g' $MIX
sed -i 's/"A2DP_SLIM7_UL_HL Switch" value="0"/"A2DP_SLIM7_UL_HL Switch" value="1"/g' $MIX
sed -i 's/"RX INT0 DEM MUX" value="NORMAL_DSM_OUT"/"RX INT0 DEM MUX" value="CLSH_DSM_OUT"/g' $MIX
sed -i 's/"RX INT1 DEM MUX" value="NORMAL_DSM_OUT"/"RX INT1 DEM MUX" value="CLSH_DSM_OUT"/g' $MIX
sed -i 's/"RX INT2 DEM MUX" value="NORMAL_DSM_OUT"/"RX INT2 DEM MUX" value="CLSH_DSM_OUT"/g' $MIX
sed -i 's/"RX INT3 DEM MUX" value="NORMAL_DSM_OUT"/"RX INT3 DEM MUX" value="CLSH_DSM_OUT"/g' $MIX
sed -i 's/"RX INT4 DEM MUX" value="NORMAL_DSM_OUT"/"RX INT4 DEM MUX" value="CLSH_DSM_OUT"/g' $MIX

patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-and-headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=speaker-mono-2]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-ce]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-no-ce]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-karaoke]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-44.1]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-dsd]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=headphones-generic]/ctl[@name=HPHR_COMP Switch]' "0"
fi

if [ "$STEP10" == "true" ]; then
if [ "$HIFI" == "true" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="RX1 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="RX2 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="RX3 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="RX4 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="RX5 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="TX1 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="TX2 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="TX3 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="TX4 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -s $MIX '/mixer/ctl[@name="TX5 HPF cut off"]' "CF_NEG_3DB_4HZ"
patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "CLS_H_LOHIFI"
patch_xml -u $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
else
patch_xml -s $MIX '/mixer/ctl[@name="RX1 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="RX2 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="RX3 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="RX4 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="RX5 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="TX1 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="TX2 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="TX3 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="TX4 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -s $MIX '/mixer/ctl[@name="TX5 HPF cut off"]' "MIN_3DB_4Hz"
patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "HD2"
patch_xml -u $MIX '/mixer/ctl[@name="RX HPH HD2 Mode"]' "On"
fi

if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 ClassD Edge"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 Volume"]' "30"
echo -e '\nro.sound.alsa=TAS2557' >> $PROP
fi

patch_xml -u $MIX '/mixer/ctl[@name="Tfa Enable"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="TFA Profile"]' "music"
patch_xml -s $MIX '/mixer/ctl[@name="DK Profile"]' "receiver"
patch_xml -s $MIX '/mixer/ctl[@name="TFA987X_ALGO_STATUS"]' "ENABLE"
patch_xml -s $MIX '/mixer/ctl[@name="TFA987X_TX_ENABLE"]' "ENABLE"
patch_xml -s $MIX '/mixer/ctl[@name="headphones]/ctl[@name="PowerCtrl"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="RX INT1 MIX3 DSD HPHL Switch"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="RX INT2 MIX3 DSD HPHR Switch"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="DSD_L Switch"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="DSD_R Switch"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="RCV AMP PCM Gain"]' "20"
patch_xml -s $MIX '/mixer/ctl[@name="AMP PCM Gain"]' "20"
patch_xml -s $MIX '/mixer/ctl[@name="Amp DSP Enable"]' "1" 
patch_xml -s $MIX '/mixer/ctl[@name="BDE AMP Enable"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="Amp Volume Location"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="Ext Spk Boost"]' "ENABLE"
patch_xml -s $MIX '/mixer/ctl[@name="PowerCtrl"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="Adsp Working Mode"]' "full"
patch_xml -s $MIX '/mixer/ctl[@name="Adsp Working Mode"]' "full"
patch_xml -s $MIX '/mixer/ctl[@name="RX_Native"]' "ON"
patch_xml -s $MIX '/mixer/ctl[@name="HPH Idle Detect"]' "ON"
patch_xml -s $MIX '/mixer/ctl[@name="Set Custom Stereo OnOff"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="HiFi Function"]' "On"
patch_xml -s $MIX '/mixer/ctl[@name="HiFi Filter"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="App Type Gain"]' "8192"
patch_xml -s $MIX '/mixer/ctl[@name="Audiosphere Enable"]' "On"
patch_xml -s $MIX '/mixer/ctl[@name="MSM ASphere Set Param"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="Load acoustic model"]' "1"
#end STEP7 patching
fi

if [ "$POCOX3" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME LEFT"]' "56"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE LEFT"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP LEFT"]' "3"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X RX MODE LEFT"]' "Speaker"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE LEFT"]' "12"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT LEFT"]' "56"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME RIGHT"]' "56"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE RIGHT"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP RIGHT"]' "3"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE RIGHT"]' "12"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT RIGHT"]' "56"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X VBAT LPF LEFT"]' "DISABLE"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X VBAT LPF RIGHT"]' "DISABLE"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256x Profile id"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="TAS25XX_SMARTPA_ENABLE"]' "ENABLE"
patch_xml -s $MIX '/mixer/ctl[@name="Amp Output Level"]' "22"
patch_xml -s $MIX '/mixer/ctl[@name="TAS25XX_ALGO_PROFILE"]' "MUSIC" 
fi

if [ "$POCOX3Pro" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME LEFT"]' "56"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE LEFT"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP LEFT"]' "3"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X RX MODE LEFT"]' "Speaker"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE LEFT"]' "15"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT LEFT"]' "59"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME RIGHT"]' "56"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE RIGHT"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP RIGHT"]' "3"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE RIGHT"]' "12"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT RIGHT"]' "55"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X VBAT LPF LEFT"]' "DISABLE"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X VBAT LPF RIGHT"]' "DISABLE"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256x Profile id"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="TAS25XX_SMARTPA_ENABLE"]' "ENABLE"
patch_xml -s $MIX '/mixer/ctl[@name="Amp Output Level"]' "22"
patch_xml -s $MIX '/mixer/ctl[@name="TAS25XX_ALGO_PROFILE"]' "MUSIC" 
fi

if [ "$RN10" ] || [ "$RN10PRO" ] || [ "$RN10PROMAX" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="aw882_xx_rx_switch"]' "Enable"
patch_xml -s $MIX '/mixer/ctl[@name="aw882_xx_tx_switch"]' "Enable"
patch_xml -s $MIX '/mixer/ctl[@name="aw882_copp_switch"]' "Enable"
patch_xml -s $MIX '/mixer/ctl[@name="aw_dev_0_prof"]' "Receiver"
patch_xml -s $MIX '/mixer/ctl[@name="aw_dev_0_switch"]' "Enable"
patch_xml -s $MIX '/mixer/ctl[@name="aw_dev_1_prof"]' "Receiver"
patch_xml -s $MIX '/mixer/ctl[@name="aw_dev_1_switch"]' "Enable"
fi

sed -i 's/"HDR12 MUX" value="NO_HDR12"/"HDR12 MUX" value="HDR12"/g' $MIX
sed -i 's/"HDR34 MUX" value="NO_HDR34"/"HDR34 MUX" value="HDR34"/g' $MIX

#end mixer patching function
done

if [ "$VOLSTEPSINT" != "Skip" ]; then
echo -e "\nro.config.media_vol_steps=$VOLSTEPSINT" >> $PROP
fi

ui_print " "                 
ui_print "   ################################======== 80% done!"

if [ "$STEP15" == "true" ]; then
echo -e "\n #Disable all effects by NLSound Team
ro.audio.ignore_effects=true
ro.vendor.audio.ignore_effects=true
vendor.audio.ignore_effects=true
persist.audio.ignore_effects=true
persis.vendor.audio.ignore_effects=true
persist.sys.phh.disable_audio_effects=1
ro.audio.disable_audio_effects=1
vendor.audio.disable_audio_effects=1
low.pass.filter=Off
midle.pass.filter=Off
high.pass.filter=Off
band.pass.filter=Off
LPF=Off
MPF=Off
HPF=Off
BPF=Off
persist.audio.uhqa=1
persist.vendor.audio.uhqa=1
ro.platform.disable.audiorawout=true
ro.vendor.platform.disable.audiorawout=true
ro.vendor.audio.sfx.speaker=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false
ro.vendor.audio.sfx.audiovisual=false
ro.vendor.audio.sfx.independentequalizer=false
vendor.audio.soundfx.usb=false
ro.vendor.audio.soundfx.usb=false
ro.vendor.soundfx.type=none
ro.vendor.audio.soundfx.type=none
persist.sys_phh.disable_audio_effects=1" >> $PROP
fi

ui_print " "
ui_print "   ######################################## 100% done!"

if [ "$STEP16" == "true" ]; then
echo -e '\n# Experimental tweaks' >> $MODPATH/service.sh

if [ "$POCOF3" ] || [ "$POCOX3Pro" ] || [ "$POCOF4GT" ] || [ "$ONEPLUS9R" ] || [ "$ONEPLUS9Pro" ] || [ "$S23U" ]; then
echo -e '\n

while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 32
tinymix "AFE Input Bit Format" S32_LE
tinymix "USB_AUDIO_RX Format" S32_LE
tinymix "USB_AUDIO_TX Format" S32_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_384
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S32_LE
tinymix "TERT_TDM_RX_1 Format" S32_LE
tinymix "TERT_MI2S_RX Format" S32_LE
tinymix "TERT_MI2S_TX Format" S32_LE
tinymix "TERT_MI2S_RX SampleRate" KHZ_192
tinymix "TERT_MI2S_TX SampleRate" KHZ_192
tinymix "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_0 Format" S32_LE
tinymix "WSA_CDC_DMA_RX_1 Format" S32_LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S32_LE
tinymix "SLIM_6_RX Format" S32_LE
tinymix "SLIM_0_RX Format" S32_LE
tinymix "SLIM_0_TX Format" S24_LE
tinymix "DEC0 MODE" ADC_HIGH_PERF
tinymix "DEC1 MODE" ADC_HIGH_PERF
tinymix "DEC2 MODE" ADC_HIGH_PERF
tinymix "DEC3 MODE" ADC_HIGH_PERF
tinymix "DEC4 MODE" ADC_HIGH_PERF
tinymix "DEC5 MODE" ADC_HIGH_PERF
tinymix "DEC6 MODE" ADC_HIGH_PERF
tinymix "DEC7 MODE" ADC_HIGH_PERF
tinymix "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix "TX0 MODE" ADC_LO_HIF
tinymix "TX1 MODE" ADC_LO_HIF
tinymix "TX2 MODE" ADC_LO_HIF
tinymix "TX3 MODE" ADC_LO_HIF
tinymix "Cirrus SP Load Config" Load
tinymix "Display Port RX Bit Format" S24_3LE
tinymix "Display Port1 RX Bit Format" S24_3LE
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "Playback 0 Compress" 0
tinymix "Playback 4 Compress" 0
tinymix "Playback 9 Compress" 0
tinymix "Compress Playback 11 Volume" 0
tinymix "Compress Playback 25 Volume" 0
tinymix "Compress Playback 26 Volume" 0
tinymix "Compress Playback 27 Volume" 0
tinymix "Compress Playback 28 Volume" 0
tinymix "Compress Playback 37 Volume" 0
tinymix "Compress Gapless Playback" 0
tinymix "RX_Softclip Enable" 1
tinymix "RCV Noise Gate" 16383
tinymix "Noise Gate" 16383
tinymix "RCV Digital PCM Volume" 830
tinymix "Digital PCM Volume" 830
tinymix "RCV Class-H Head Room" 127
tinymix "Class-H Head Room" 127
tinymix "RCV PCM Soft Ramp" 30ms
tinymix "PCM Soft Ramp" 30ms
tinymix "RCV DSP Set AMBIENT" 16777215
tinymix "DSP Set AMBIENT" 16777215
tinymix "DS2 OnOff" 1
tinymix "TERT_TDM_TX_0 LSM Function" AUDIO
tinymix "TERT_MI2S_TX LSM Function" AUDIO
tinymix "HPHL Volume" 24
tinymix "HPHR Volume" 24
sleep 4
done' >> $MODPATH/service.sh
fi

if [ "$MI11U" ] || [ "$ONEPLUS11GLOBAL" ] || [ "$MI13U" ]; then
echo -e '\n

while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 32
tinymix "AFE Input Bit Format" S32_LE
tinymix "USB_AUDIO_RX Format" S32_LE
tinymix "USB_AUDIO_TX Format" S32_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_384
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S32_LE
tinymix "TERT_TDM_RX_1 Format" S32_LE
tinymix "TERT_MI2S_RX Format" S32_LE
tinymix "TERT_MI2S_TX Format" S32_LE
tinymix "TERT_MI2S_RX SampleRate" KHZ_192
tinymix "TERT_MI2S_TX SampleRate" KHZ_192
tinymix "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix "TERT_TDM_RX_1 Header Type" Entertainment
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_0 Format" S32_LE
tinymix "WSA_CDC_DMA_RX_1 Format" S32_LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S32_LE
tinymix "SLIM_6_RX Format" S32_LE
tinymix "SLIM_0_RX Format" S32_LE
tinymix "SLIM_0_TX Format" S24_LE
tinymix "DEC0 MODE" ADC_HIGH_PERF
tinymix "DEC1 MODE" ADC_HIGH_PERF
tinymix "DEC2 MODE" ADC_HIGH_PERF
tinymix "DEC3 MODE" ADC_HIGH_PERF
tinymix "DEC4 MODE" ADC_HIGH_PERF
tinymix "DEC5 MODE" ADC_HIGH_PERF
tinymix "DEC6 MODE" ADC_HIGH_PERF
tinymix "DEC7 MODE" ADC_HIGH_PERF
tinymix "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix "Cirrus SP Load Config" Load
tinymix "Display Port RX Bit Format" S24_3LE
tinymix "Display Port1 RX Bit Format" S24_3LE
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96 
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "RX_Softclip Enable" 1
tinymix "RCV Noise Gate" 16383
tinymix "Noise Gate" 16383
tinymix "DS2 OnOff" 1
tinymix "HPHL Volume" 24
tinymix "HPHR Volume" 24
sleep 4
done' >> $MODPATH/service.sh
fi

if [ "$POCOM3C" ] || [ "$POCOM3J" ] || [ "$R9T" ]; then
echo -e '\n

while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S24_3LE
tinymix "USB_AUDIO_RX Format" S32_LE
tinymix "USB_AUDIO_TX Format" S32_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_384
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_3 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_3 Format" S24_3LE
tinymix "Playback 0 Compress" 0
tinymix "Playback 4 Compress" 0
tinymix "Playback 9 Compress" 0
tinymix "Compress Playback 25 Volume" 0
tinymix "Compress Playback 26 Volume" 0
tinymix "Compress Playback 27 Volume" 0
tinymix "Compress Playback 28 Volume" 0
tinymix "Compress Playback 36 Volume" 0
tinymix "Compress Gapless Playback" 0
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "RX_Softclip Enable" 1
tinymix "DS2 OnOff" 1
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
sleep 4
done' >> $MODPATH/service.sh
fi


if [ "$POCOX3" ]; then
echo -e '\n

while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S24_3LE
tinymix "USB_AUDIO_RX Format" S24_3LE
tinymix "USB_AUDIO_TX Format" S24_3LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_192
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "TERT_TDM_RX_0 Format" S24_3LE
tinymix "TERT_TDM_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_0 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_1 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "Playback 0 Compress" 0
tinymix "Playback 1 Compress" 0
tinymix "Playback 4 Compress" 0
tinymix "Playback 13 Compress" 0
tinymix "Playback 16 Compress" 0
tinymix "Playback 27 Compress" 0
tinymix "Compress Playback 15 Volume" 0
tinymix "Compress Playback 29 Volume" 0
tinymix "Compress Playback 30 Volume" 0
tinymix "Compress Playback 31 Volume" 0
tinymix "Compress Playback 32 Volume" 0
tinymix "Compress Playback 41 Volume" 0
tinymix "Compress Playback 42 Volume" 0
tinymix "Compress Playback 43 Volume" 0
tinymix "Compress Playback 44 Volume" 0
tinymix "Compress Playback 45 Volume" 0
tinymix "Display Port RX Bit Format" S24_3LE
tinymix "Display Port1 RX Bit Format" S24_3LE
tinymix "TERT_TDM_TX_0 Header Type" Entertainment 
tinymix "TERT_TDM_TX_1 Header Type" Entertainment 
tinymix "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "RX_Softclip Enable" 1
tinymix "DS2 OnOff" 1
tinymix "HPHL Volume" 24
tinymix "HPHR Volume" 24
sleep 4
done' >> $MODPATH/service.sh
fi

if [ "$RN10PRO" ] || [ "$RN10PROMAX" ] || [ "$RN8T" ] || [ "$A71" ] || [ "$RMEGTNEO3T" ] || [ "$ONEPLUS9RT" ]; then
echo -e '\n

while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S32_LE
tinymix "USB_AUDIO_RX Format" S32_LE
tinymix "USB_AUDIO_TX Format" S32_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_384
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S32_LE
tinymix "TERT_TDM_RX_1 Format" S32_LE
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_0 Format" S32_LE
tinymix "WSA_CDC_DMA_RX_1 Format" S32_LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S32_LE
tinymix "SLIM_6_RX Format" S32_LE
tinymix "SLIM_0_RX Format" S32_LE
tinymix "SLIM_0_TX Format" S24_LE
tinymix "DEC0 MODE" ADC_HIGH_PERF
tinymix "DEC1 MODE" ADC_HIGH_PERF
tinymix "DEC2 MODE" ADC_HIGH_PERF
tinymix "DEC3 MODE" ADC_HIGH_PERF
tinymix "DEC4 MODE" ADC_HIGH_PERF
tinymix "DEC5 MODE" ADC_HIGH_PERF
tinymix "DEC6 MODE" ADC_HIGH_PERF
tinymix "DEC7 MODE" ADC_HIGH_PERF
tinymix "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix "TX0 MODE" ADC_LO_HIF
tinymix "TX1 MODE" ADC_LO_HIF
tinymix "TX2 MODE" ADC_LO_HIF
tinymix "TX3 MODE" ADC_LO_HIF
tinymix "Playback 0 Compress" 0
tinymix "Playback 1 Compress" 0
tinymix "Playback 4 Compress" 0
tinymix "Playback 13 Compress" 0
tinymix "Playback 16 Compress" 0
tinymix "Playback 27 Compress" 0
tinymix "Compress Playback 15 Volume" 0
tinymix "Compress Playback 29 Volume" 0
tinymix "Compress Playback 30 Volume" 0
tinymix "Compress Playback 31 Volume" 0
tinymix "Compress Playback 32 Volume" 0
tinymix "Compress Playback 41 Volume" 0
tinymix "Compress Playback 42 Volume" 0
tinymix "Compress Playback 43 Volume" 0
tinymix "Compress Playback 44 Volume" 0
tinymix "Compress Playback 45 Volume" 0
tinymix "Cirrus SP Load Config" Load
tinymix "Display Port RX Bit Format" S24_3LE
tinymix "Display Port1 RX Bit Format" S24_3LE
tinymix "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "RX_Softclip Enable" 1
tinymix "RCV Noise Gate" 16383
tinymix "Noise Gate" 16383
tinymix "DS2 OnOff" 1
tinymix "HPHL Volume" 24
tinymix "HPHR Volume" 24
sleep 4
done' >> $MODPATH/service.sh
fi

if [ "$S22U" ]; then
echo -e '\n

while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 32
tinymix "AFE Input Bit Format" S32_LE
tinymix "USB_AUDIO_RX Format" S32_LE
tinymix "USB_AUDIO_TX Format" S32_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_384
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S32_LE
tinymix "TERT_TDM_RX_1 Format" S32_LE
tinymix "TERT_MI2S_RX Format" S32_LE
tinymix "TERT_MI2S_TX Format" S32_LE
tinymix "TERT_MI2S_RX SampleRate" KHZ_192
tinymix "TERT_MI2S_TX SampleRate" KHZ_192
tinymix "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_192
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_0 Format" S32_LE
tinymix "WSA_CDC_DMA_RX_1 Format" S32_LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S32_LE
tinymix "SLIM_6_RX Format" S32_LE
tinymix "SLIM_0_RX Format" S32_LE
tinymix "SLIM_0_TX Format" S24_LE
tinymix "DEC0 MODE" ADC_HIGH_PERF
tinymix "DEC1 MODE" ADC_HIGH_PERF
tinymix "DEC2 MODE" ADC_HIGH_PERF
tinymix "DEC3 MODE" ADC_HIGH_PERF
tinymix "DEC4 MODE" ADC_HIGH_PERF
tinymix "DEC5 MODE" ADC_HIGH_PERF
tinymix "DEC6 MODE" ADC_HIGH_PERF
tinymix "DEC7 MODE" ADC_HIGH_PERF
tinymix "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix "TX0 MODE" ADC_LO_HIF
tinymix "TX1 MODE" ADC_LO_HIF
tinymix "TX2 MODE" ADC_LO_HIF
tinymix "TX3 MODE" ADC_LO_HIF
tinymix "Cirrus SP Load Config" Load
tinymix "Display Port RX Bit Format" S24_3LE
tinymix "Display Port1 RX Bit Format" S24_3LE
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "Playback 0 Compress" 0
tinymix "Playback 4 Compress" 0
tinymix "Playback 9 Compress" 0
tinymix "Compress Playback 11 Volume" 0
tinymix "Compress Playback 25 Volume" 0
tinymix "Compress Playback 26 Volume" 0
tinymix "Compress Playback 27 Volume" 0
tinymix "Compress Playback 28 Volume" 0
tinymix "Compress Playback 37 Volume" 0
tinymix "Compress Gapless Playback" 0
tinymix "RX_Softclip Enable" 1
tinymix "RCV Noise Gate" 16383
tinymix "Noise Gate" 16383
tinymix "Haptics Source" A2H
tinymix "Static MCLK Mode" 24
tinymix "Force Frame32" 1
tinymix "A2H Tuning" 5
tinymix "LPI Enable" 0
tinymix "DMIC_RATE OVERRIDE" CLK_2P4MHZ
tinymix "DS2 OnOff" 1
tinymix "HPHL Volume" 24
tinymix "HPHR Volume" 24
sleep 4
done' >> $MODPATH/service.sh
fi

echo ' ' >> $MODPATH/service.sh

echo -e '\n resetprop -p --delete media.resolution.limit.16bit
resetprop -p --delete media.resolution.limit.24bit
resetprop -p --delete media.resolution.limit.32bit

resetprop -p --delete audio.resolution.limit.16bit
resetprop -p --delete audio.resolution.limit.24bit
resetprop -p --delete audio.resolution.limit.32bit ' >> $MODPATH/service.sh
fi


ui_print " "
ui_print " - All done! With love, NLSound Team. - "
ui_print " "
