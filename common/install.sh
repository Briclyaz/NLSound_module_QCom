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


[ -f /system/vendor/build.prop ] && BUILDS="/system/build.prop /system/vendor/build.prop" || BUILDS="/system/build.prop"

SD617=$(grep "ro.board.platform=msm8952" $BUILDS)
SD625=$(grep "ro.board.platform=msm8953" $BUILDS)
SD660=$(grep "ro.board.platform=sdm660" $BUILDS)
SD662=$(grep "ro.board.platform=bengal" $BUILDS)
SD665=$(grep "ro.board.platform=trinket" $BUILDS)
SD670=$(grep "ro.board.platform=sdm670" $BUILDS)
SD710=$(grep "ro.board.platform=sdm710" $BUILDS)
SD720G=$(grep "ro.board.platform=atoll" $BUILDS)
SD730G=$(grep "ro.board.platform=sm6150" $BUILDS)
SD765G=$(grep "ro.board.platform=lito" $BUILDS)
SD820=$(grep "ro.board.platform=msm8996" $BUILDS)
SD835=$(grep "ro.board.platform=msm8998" $BUILDS)
SD845=$(grep "ro.board.platform=sdm845" $BUILDS)
SD855=$(grep "ro.board.platform=msmnile" $BUILDS)
SD865=$(grep "ro.board.platform=kona" $BUILDS)
SD888=$(grep "ro.board.platform=lahaina" $BUILDS)
SM6375=$(grep "ro.board.platform=holi" $BUILDS)
SM8450=$(grep "ro.board.platform=taro" $BUILDS)
SM8550=$(grep "ro.board.platform=kalama" $BUILDS)

if [ "$SD662" ] || [ "$SD665" ] || [ "$SD670" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730G" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ] || [ "$SM6375" ] || [ "$SM8450" ] || [ "$SM8550" ]; then
HIFI=true
ui_print " "
ui_print "- Device with support Hi-Fi detected! -"
else
HIFI=false
ui_print " "
ui_print " - Device without support Hi-Fi detected! -"
fi

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

RN10PROMAX=$(grep -E "ro.product.vendor.device=sweetin.*" $BUILDS)
RN10PRO=$(grep -E "ro.product.vendor.device=sweet.*" $BUILDS)
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
MI10Ultra=$(grep -E "ro.product.vendor.device=cas.*" $BUILDS)
MI10i5GRN95G=$(grep -E "ro.product.vendor.device=gauguin.*" $BUILDS)
MI10LITE=$(grep -E "ro.product.vendor.device=vangogh.*" $BUILDS)
MI10T=$(grep -E "ro.product.vendor.device=apollo.*" $BUILDS)
MI10PRO=$(grep -E "ro.product.vendor.device=cmi.*" $BUILDS)
MI11=$(grep -E "ro.product.vendor.device=venus.*" $BUILDS)
MI11Lite5G=$(grep -E "ro.product.vendor.device=renoir.*" $BUILDS)
MI11Lite4G=$(grep -E "ro.product.vendor.device=courbet.*" $BUILDS)
K20P=$(grep -E "ro.product.vendor.device=raphael.*|ro.product.vendor.device=raphaelin.*|ro.product.vendor.device=raphaels.*" $BUILDS)
MI8=$(grep -E "ro.product.vendor.device=dipper.*" $BUILDS)
MI8P=$(grep -E "ro.product.vendor.device=equuleus.*" $BUILDS)
MI9P=$(grep -E "ro.product.vendor.device=crux.*" $BUILDS)

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

ONEPLUS7=$(grep -E "ro.product.vendor.device=guacamoleb.*" $BUILDS)
ONEPLUS7PRO=$(grep -E "ro.product.vendor.device=guacamole.*" $BUILDS)
ONEPLUS7TPRO=$(grep -E "ro.product.vendor.device=hotdog.*" $BUILDS)
ONEPLUS7T=$(grep -E "ro.product.vendor.device=hotdogb.*" $BUILDS)
ONEPLUS8=$(grep -E "ro.product.vendor.device=instantnoodle.*" $BUILDS)
ONEPLUS8PRO=$(grep -E "ro.product.vendor.device=instantnoodlep.*" $BUILDS)
ONEPLUS8T=$(grep -E "ro.product.vendor.device=kebab.*" $BUILDS)
ONEPLUSNORD=$(grep -E "ro.product.vendor.device=avicii.*" $BUILDS)
ONEPLUS99PRO9R=$(grep -E "ro.product.vendor.device=lemonade.*" $BUILDS)

DEVICE=$(getprop ro.product.vendor.device)
ACONFS="$(find /system /vendor /system_ext /product -type f -name "audio_configs*.xml")"
AECFGS="$(find /system /vendor /system_ext /product -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
AECFGVENDORS="$(find /vendor -type f -name "*audio_effects*.conf")"
AECFGVSYSTEMS="$(find /system /system_ext -type f -name "*audio_effects*.conf")"
MPATHS="$(find /system /vendor /system_ext /product -type f -name "mixer_paths*.xml")"
APIXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info.xml")"
APIIXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info_intcodec*.xml")"
APIEXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info_extcodec*.xml")"
APIQRDXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info_qrd*.xml")"
DEVFEAS="$(find /system /vendor /system_ext /product -type f -name "$DEVICE.xml")" 
AUDIOPOLICYS="$(find /system /vendor /system_ext /product -type f -name "audio_policy_configuration.xml")"
SNDTRGS="$(find /system /vendor /system_ext /product -type f -name "*sound_trigger_mixer_paths*.xml")"
MCODECS="$(find /system /vendor /system_ext /product -type f -name "media_codecs_*_audio.xml")"

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
IOPOLICYS=$MODPATH/common/NLSound/audio_io_policy.conf
OUTPUTPOLICYS=$MODPATH/common/NLSound/audio_output_policy.conf

mkdir -p $MODPATH/tools
cp_ch $MODPATH/common/addon/External-Tools/tools/$ARCH32/* $MODPATH/tools/

ui_print " "
ui_print " - Configurate me, pls >.< - "
ui_print " "

ui_print "***************************************************"
ui_print "* [1/17]                                          *"
ui_print "*                                                 *"
ui_print "*            • SELECT VOLUME STEPS •              *"
ui_print "*       Lower value - faster volume control       *"
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
ui_print "* [2/17]                                          *"
ui_print "*                                                 *"
ui_print "*          • SELECT VOLUMES FOR MEDIA •           *"
ui_print "*      Lower numerical value - lower volume       *"
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
ui_print "* [3/17]                                          *"
ui_print "*                                                 *"
ui_print "*        • SELECT MICROPHONE SENSITIVITY •        *"
ui_print "*       Lower numerical value - lower volume      *"
ui_print "*  NOTE: If you specify a new microphone volume   *"
ui_print "*   some settings will automatically be applied   *"
ui_print "*             to improve their sound.             *"
ui_print "*     If you skip this option,these settings      *"
ui_print "*               will not be applied.              *"
ui_print "*                                                 *"
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
ui_print "* [4/17]                                          *"
ui_print "*                                                 *"
ui_print "*            • SELECT AUDIO FORMAT •              *"
ui_print "*                  ATTENTION!                     *"
ui_print "*     If your device does not support Hi-Fi,      *"
ui_print "*       we strongly recommend that you do         *"
ui_print "*         not set it higher than 24-bit.          *"
ui_print "*_________________________________________________*"
ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
ui_print "***************************************************"
sleep 1
BITNES=1
ui_print " "
ui_print "   1. Skip (No changes will be made)"
ui_print "   2. 24-bit"
ui_print "   3. 32-bit (only for SD870 and higher)"
ui_print "   4. float"
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
ui_print "* [5/17]                                          *"
ui_print "*                                                 *"
ui_print "*             • SELECT SAMPLING RATE •            *"
ui_print "*                    ATTENTION!                   *"
ui_print "*      If your device does not support Hi-Fi,     *"
ui_print "*        we strongly recommend that you do        *"
ui_print "*         not set it higher than 192 kHz.         *"
ui_print "*                    Recommended:                 *"
ui_print "*                  16-bit 48000 kHz,              *"
ui_print "*              24-bit 96000-192000 kHz,           *"
ui_print "*                  32-bit 384000 kHz              *"
ui_print "*      You don't need to fix 48000 kHz or do      *"
ui_print "*     other absurdities after selecting 32-bit    *"
ui_print "*_________________________________________________*"
ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
ui_print "***************************************************"
sleep 1
ui_print " "
ui_print "   1. Skip (No changes will be made)"
ui_print "   2. 96000 kHz "
ui_print "   3. 192000 kHz "
ui_print "   4. 384000 kHz (only for SD870 and higher)"
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
ui_print "* [6/17]                                          *"
ui_print "*                                                 *"
ui_print "*        • PATCHING AUDIO PLATFORM FILES •        *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*          you activate this mechanism.           *"
ui_print "*                                                 *"
ui_print "* Confirming this option will allow the module to *"
ui_print "*      use a different audio codec algorithm      *"
ui_print "* for your favorite songs, and will also improve  *"
ui_print "*    the sound quality during video recording     *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP6=true
sed -i 's/STEP6=false/STEP6=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [7/17]                                          *"
ui_print "*                                                 *"
ui_print "*        • TURN OFF SOUND INTERFERENCE •          *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*             you disable all shit.               *"
ui_print "*                                                 *"
ui_print "*    Compounders, low-quality speaker boosts,     *"
ui_print "*           and a bunch of other stuff.           *"
ui_print "*          [Recommended for installation]         *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP7=true
sed -i 's/STEP7=false/STEP7=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [8/17]                                          *"
ui_print "*                                                 *"
ui_print "*        • CONFIGURE INTERNAL AUDIO CODEC •       *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*           you will apply the changes.           *"
ui_print "*                                                 *"
ui_print "*           This option will configure            *"
ui_print "*       your device's internal audio codec.       *"
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
ui_print "* [9/17]                                          *"
ui_print "*                                                 *"
ui_print "*       • PATCHING DEVICE_FEATURES FILES •        *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*           you will apply the changes.           *"
ui_print "*                                                 *"
ui_print "*        This step will do the following:         *"
ui_print "*        - Unlocks the sampling frequency         *"
ui_print "*          of the audio up to 192000 kHz;         *"
ui_print "*        - Enable HD record in camcorder;         *"
ui_print "*        - Increase VoIP recor quality;           *"
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
STEP9=true
sed -i 's/STEP9=false/STEP9=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [10/17]                                         *"
ui_print "*                                                 *"
ui_print "*            • INSTALL CUSTOM DIRAC •             *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*           you will apply the changes.           *"
ui_print "*                                                 *"
ui_print "* This option will add a new dirac to the system  *"
ui_print "*   If you encounter wheezing from the outside    *"
ui_print "*    speaker, first of all when reinstalling      *"
ui_print "*               skip this step.                   *"
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
ui_print "* [11/17]                                         *"
ui_print "*                                                 *"
ui_print "*      • OTHER PATCHES IN MIXER_PATHS FILES •     *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*           you will apply the changes.           *"
ui_print "*                                                 *"
ui_print "*     Global sound changes by adjusting the       *"
ui_print "*        internal codec of the device.            *"
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
ui_print "* [12/17]                                         *"
ui_print "*                                                 *"
ui_print "*         • TWEAKS FOR BUILD.PROP FILES •         *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*           you will apply the changes.           *"
ui_print "*                                                 *"
ui_print "*    This option will change the sound quality    *"
ui_print "*                  the most.                      *"
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
ui_print "* [13/17]                                         *"
ui_print "*                                                 *"
ui_print "*             • IMPROVE BLUETOOTH •               *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*           you will apply the changes.           *"
ui_print "*                                                 *"
ui_print "*   This option will improve the audio quality    *"
ui_print "*    in Bluetooth, as well as fix the problem     *"
ui_print "*      of disappearing the AAC codec switch       *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP13=true
sed -i 's/STEP13=false/STEP13=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [14/17]                                         *"
ui_print "*                                                 *"
ui_print "*            • SWITCH AUDIO OUTPUT •              *"
ui_print "*                                                 *"
ui_print "*            When you click *Install*,            *"
ui_print "*           you will apply the changes.           *"
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
STEP14=true
sed -i's/STEP14=false/STEP14=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [15/17]                                         *"
ui_print "*                                                 *"
ui_print "*        • INSTALL CUSTOM PRESET FOR IIR •        *"
ui_print "*                                                 *"
ui_print "* IIR affects the final frequency response curve. *"
ui_print "*   headphones. The default setting is with an    *"
ui_print "* emphasis on the upper limit of low frequencies  *"
ui_print "* and the lower bound of the midrange frequencies *"
ui_print "*Once applied, these boundaries will be reinforced*"
ui_print "*        [Recommended for installation]           *"
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
ui_print "* [16/17]                                         *"
ui_print "*                                                 *"
ui_print "*          • IGNORE ALL AUDIO EFFECTS •           *"
ui_print "*                                                 *"
ui_print "*      This item disables any audio effects       *"
ui_print "*   at the system level. It breaks XiaomiParts,   *"
ui_print "*      Dirac, Dolby, and other equalizers.        *"
ui_print "*   Significantly increases the sound quality     *"
ui_print "*            for quality headphones.              *"
ui_print "*                                                 *"
ui_print "*   Note: if you click Install, this item will    *"
ui_print "*  also disable the Dirac that the module offers, *"
ui_print "*    as well as the influence of third-party      *"
ui_print "*    audio libraries contained in the module.     *"
ui_print "*_________________________________________________*"
ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
ui_print "***************************************************"
ui_print " "
if chooseport 60; then
STEP16=true
sed -i 's/STEP16=false/STEP16=true/g' $SETTINGS
fi

ui_print " "
ui_print "***************************************************"
ui_print "* [17/17]                                         *"
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
STEP17=true
sed -i 's/STEP17=false/STEP17=true/g' $SETTINGS
fi

ui_print " - YOUR SETTINGS: "
ui_print " 1. Volume steps: $VOLSTEPSINT"
ui_print " 2. Volume levels: $VOLMEDIASINT"
ui_print " 3. Microphone levels: $VOLMICINT"
ui_print " 4. Audio format configuration: $BITNESINT"
ui_print " 5. Sample rate configutation: $SAMPLERATEINT"
ui_print " 6. Patching audio_platform files: $STEP6"
ui_print " 7. Turn off sound interference: $STEP7"
ui_print " 8. Configurating interal audio codec: $STEP8"
ui_print " 9. Patching device_features files: $STEP9"
ui_print " 10. Install custom Dirac: $STEP10"
ui_print " 11. Other patches in mixer_paths files: $STEP11"
ui_print " 12. Tweaks for build.prop files: $STEP12"
ui_print " 13. Improve bluetooth: $STEP13"
ui_print " 14. Switch audio output: $STEP14"
ui_print " 15. Install custom preset for IIR: $STEP15"
ui_print " 16. Ignore all audio effects: $STEP16"
ui_print " 17. Install experimental tweaks: $STEP17"
ui_print " "

ui_print " "
ui_print " - Processing. . . -"
ui_print " "
ui_print " - You can minimize Magisk and use the device normally -"
ui_print " - and then come back here to reboot and apply the changes. -"
ui_print " "

if [ "$STEP6" == "true" ]; then
if [ "$BITNESINT" != "Skip" ]; then
if [ "$SAMPLERATEINT" != "Skip" ]; then
for OAPIXML in ${APIXMLS}; do
APIXML="$MODPATH$(echo $OAPIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAPIXML $APIXML
sed -i 's/\t/  /g' $APIXML
patch_xml -s $APIXML '/audio_platform_info/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIXML '/audio_platform_info/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIXML '/audio_platform_info/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
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
APIIXML="$MODPATH$(echo $OAPIIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAPIIXML $APIIXML
sed -i 's/\t/  /g' $APIIXML
patch_xml -s $APIIXML '/audio_platform_info_intcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
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
APIEXML="$MODPATH$(echo $OAPIEXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAPIEXML $APIEXML
sed -i 's/\t/  /g' $APIEXML
patch_xml -s $APIEXML '/audio_platform_info_extcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIEXML '/audio_platform_info_extcodec/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
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
APIQRDXML="$MODPATH$(echo $OAPIQRDXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAPIQRDXML $APIQRDXML
sed -i 's/\t/  /g' $APIQRDXML
patch_xml -s $APIQRDXML '/audio_platform_info/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIQRDXML '/audio_platform_info/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIQRDXML '/audio_platform_info/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
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

if [ "$STEP9" == "true" ]; then
for OACONF in ${ACONFS}; do
ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OACONF $ACONF
sed -i 's/\t/  /g' $ACONF
patch_xml -u $ACONF '/configs/property[@name="audio.deep_buffer.media"]' "false"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.flac.sw.decoder.24bit"]' "true"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.hw.aac.encoder"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="qti_flac_decoder"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="audiosphere_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="custom_stereo_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="battery_listener_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="ext_hw_plugin_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="ext_qdsp_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="ext_spkr_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="ext_spkr_tfa_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="hifi_audio_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="keep_alive_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="receiver_aided_stereo"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="use_deep_buffer_as_primary_output"]' "false"
done
fi

if [ "$STEP9" == "true" ]; then
for ODEVFEA in ${DEVFEAS}; do 
DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$ODEVFEA $DEVFEA
sed -i 's/\t/  /g' $DEVFEA
patch_xml -s $DEVFEA '/features/bool[@name="support_a2dp_latency"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_48000"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_96000"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_192000"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_low_latency"]' "true"
patch_xml -s $DEVFEA '/features/bool[@name="support_mid_latency"]' "false"
patch_xml -s $DEVFEA '/features/bool[@name="support_high_latency"]' "false"
patch_xml -s $DEVFEA '/features/bool[@name="support_interview_record_param"]' "false"
done
fi

if [ "$STEP10" == "true" ]; then
for OFILE in ${AECFGS}; do
FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
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

echo -e '\n# Patch dirac
persist.dirac.acs.controller=gef
persist.dirac.gef.oppo.syss=true
persist.dirac.config=64
persist.dirac.gef.exs.did=50,50
persist.dirac.gef.ext.did=850,850,850,850
persist.dirac.gef.ins.did=50,50,50
persist.dirac.gef.int.did=850,850,850,850
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
persist.audio.dirac.eq=7.0,6.0,4.0,4.0,3.0,2.0,0.0
persist.audio.dirac.headset=1
persist.audio.dirac.music.state=1' >> $MODPATH/system.prop
fi

if [ "$STEP12" == "true" ]; then
echo -e "\n#
ro.mediacodec.min_sample_rate=7350
ro.mediacodec.max_sample_rate=2822400
vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
qc.tunnel.audio.encode=true
mpq.audio.decode=true
audio.nat.codec.enabled=1
audio.decoder_override_check=true

vendor.audio.aac.complexity.default=10
vendor.audio.aac.quality=100
vendor.audio.vorbis.complexity.default=10
vendor.audio.vorbis.quality=100
vendor.audio.mp3.complexity.default=10
vendor.audio.mp3.quality=100
vendor.audio.mpegh.complexity.default=10
vendor.audio.mpegh.quality=100
vendor.audio.amrnb.complexity.default=10
vendor.audio.amrnb.quality=100
vendor.audio.amrwb.complexity.default=10
vendor.audio.amrwb.quality=100
vendor.audio.g711.alaw.complexity.default=10
vendor.audio.g711.alaw.quality=100
vendor.audio.g711.mlaw.complexity.default=10
vendor.audio.g711.mlaw.quality=100
vendor.audio.opus.complexity.default=10
vendor.audio.opus.quality=100
vendor.audio.raw.complexity.default=10
vendor.audio.raw.quality=100
vendor.audio.flac.complexity.default=10
vendor.audio.flac.quality=100
vendor.audio.dsp.complexity.default=10
vendor.audio.dsp.quality=100
vendor.audio.dsd.complexity.default=10
vendor.audio.dsd.quality=100
vendor.audio.alac.complexity.default=10
vendor.audio.alac.quality=100

use.non-omx.alac.decoder=false
use.non-omx.mpegh.decoder=false
use.non-omx.vorbis.decoder=false
use.non-omx.wma.decoder=false
use.non-omx.amrnb.decoder=false
use.non-omx.amrwb.decoder=false
use.non-omx.mhas.decoder=false
use.non-omx.g711.alaw.decoder=false
use.non-omx.g711.mlaw.sw.decoder=false
use.non-omx.opus.decoder=false
use.non-omx.raw.decoder=false
use.non-omx.qti.decoder=false
use.non-omx.dsp.decoder=false
use.non-omx.dsd.decoder=false
use.non-omx.alac.encoder=false
use.non-omx.mpegh.encoder=false
use.non-omx.flac.encoder=false
use.non-omx.aac.encoder=false
use.non-omx.vorbis.encoder=false
use.non-omx.wma.encoder=false
use.non-omx.mp3.encoder=false
use.non-omx.amrnb.encoder=false
use.non-omx.amrwb.encoder=false
use.non-omx.mhas.encoder=false
use.non-omx.g711.alaw.encoder=false
use.non-omx.g711.mlaw.sw.encoder=false
use.non-omx.opus.encoder=false
use.non-omx.raw.encoder=false
use.non-omx.qti.encoder=false
use.non-omx.dsp.encoder=false
use.non-omx.dsd.encoder=false

media.aac_51_output_enabled=true
mm.enable.smoothstreaming=true
mmp.enable.3g2=true
mm.enable.qcom_parser=63963135
vendor.mm.enable.qcom_parser=63963135

lpa.decode=false
lpa30.decode=false
lpa.use-stagefright=false
lpa.releaselock=false

af.thread.throttle=0

audio.playback.mch.downsample=false
vendor.audio.playback.mch.downsample=false
persist.vendor.audio.playback.mch.downsample=false

vendor.audio.feature.dynamic_ecns.enable=true
vendor.audio.feature.external_dsp.enable=true
vendor.audio.feature.external_qdsp.enable=true
vendor.audio.feature.external_speaker.enable=true
vendor.audio.feature.external_speaker_tfa.enable=true
vendor.audio.feature.receiver_aided_stereo.enable=true
vendor.audio.feature.ext_hw_plugin=true
vendor.audio.feature.source_track_enabled=true
vendor.audio.feature.keep_alive.enable=true
vendor.audio.feature.devicestate_listener.enable=false
vendor.audio.feature.thermal_listener.enable=false
vendor.audio.feature.power_mode.enable=true
vendor.audio.feature.hifi_audio.enable=true

vendor.audio.feature.keep_alive.enable=true
vendor.audio.feature.deepbuffer_as_primary.enable=false
vendor.audio.feature.dmabuf.cma.memory.enable=true

ro.hardware.hifi.support=true
ro.audio.hifi=true
ro.vendor.audio.hifi=true
persist.audio.hifi=true
persist.vendor.audio.hifi=true
persist.audio.hifi.volume=92
persist.audio.hifi.int_codec=true
persist.vendor.audio.hifi.int_codec=true

effect.reverb.pcm=1
vendor.audio.safx.pbe.enabled=true
vendor.audio.soundfx.usb=false
vendor.audio.keep_alive.disabled=false
ro.vendor.audio.soundfx.usb=false
ro.vendor.audio.sfx.speaker=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false
ro.vendor.audio.sfx.audiovisual=false
ro.vendor.audio.sfx.independentequalizer=false
ro.vendor.audio.3d.audio.support=true
persist.vendor.audio.ambisonic.capture=true
persist.vendor.audio.ambisonic.auto.profile=true

vendor.voice.dsd.playback.conc.disabled=false
vendor.audio.hdr.record.enable=true
vendor.audio.3daudio.record.enable=true
ro.vendor.audio.recording.hd=true
ro.ril.enable.amr.wideband=1
persist.audio.lowlatency.rec=true

vendor.audio.matrix.limiter.enable=0
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.hal.output.suspend.supported=true
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.tfa9874.dsp.enabled=true
ro.audio.soundtrigger.lowpower=false
ro.vendor.audio.soundtrigger.adjconf=true
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
persist.vendor.audio.ll_playback_bargein=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.delta.refresh=true

ro.audio.resampler.psd.enable_at_samplerate=192000
ro.audio.resampler.psd.stopband=179
ro.audio.resampler.psd.halflength=408
ro.audio.resampler.psd.cutoff_percent=99
ro.audio.resampler.psd.tbwcheat=100

vendor.qc2audio.suspend.enabled=true
vendor.qc2audio.per_frame.flac.dec.enabled=true
vendor.audio.lowpower=false

ro.vendor.audio.misound.bluetooth.enable=true
ro.vendor.audio.dolby.eq.half=true
ro.vendor.audio.dolby.dax.support=true
ro.vendor.audio.dolby.surround.enable=true

vendor.audio.c2.preferred=true
debug.c2.use_dmabufheaps=1
ro.vendor.audio.sfx.harmankardon=true

ro.vendor.audio.bass.enhancer.enable=true
audio.safemedia.bypass=true
ro.audio.usb.period_us=2625

#change usb period
ro.audio.usb.period_us=50000
vendor.audio.usb.perio=50000
vendor.audio.usb.out.period_us=50000
vendor.audio.usb.out.period_count=2

#alsa
AUDIODRIVER=alsa
ro.sound.driver=alsa
ro.sound.alsa=snd_pcm
ro.config.hifi_config_state=1
alsa.mixer.playback.master=Speaker 
alsa.mixer.capture.master=Mic
alsa.mixer.playback.earpiece=Earpiece
alsa.mixer.capture.earpiece=Mic
alsa.mixer.playback.headset=Headset
alsa.mixer.capture.headset=Mic
alsa.mixer.playback.headphones=Headphones
alsa.mixer.capture.headset=Mic
alsa.mixer.playback.speaker=Speaker
alsa.mixer.capture.speaker=Mic
alsa.mixer.playback.bt.sco=BTHeadset
alsa.mixer.capture.bt.sco=BTHeadset

#new11102022
persist.vendor.audio.spv4.enable=true
ro.vendor.audio.ns.support=true
ro.vendor.audio.enhance.support=true
ro.vendor.audio.karaok.support=true
ro.audio.monitorRotation=true
ro.audio.recording.hd=true
ro.vendor.audio.spk.clean=true
persist.vendor.vcb.enable=true
persist.vendor.vcb.ability=true
defaults.pcm.rate_converter=samplerate_best
ro.vendor.audio.sdk.ssr=true
ro.vendor.audio.dump.mixer=false
ro.audio.playbackScene=false
ro.vendor.audio.playbackScene=false
ro.vendor.audio.recording.hd=true
ro.vendor.audio.multiroute=true
ro.vendor.audio.sos=true
ro.vendor.audio.voice.change.support=true
ro.vendor.audio.voice.change.youme.support=true
ro.vendor.audio.spk.stereo=true
ro.vendor.audio.spk.clean=true
ro.vendor.audio.vocal.support=true
ro.vendor.audio.sfx.independentequalizer=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.speaker=true
ro.vendor.audio.sfx.spk.movie=true
ro.vendor.audio.gain.support=true
ro.vendor.audio.karaok.support=true
ro.vendor.camera.karaok.support=true
ro.vendor.audio.ns.support=true
ro.vendor.audio.enhance.support=true
ro.audio.monitorRotation=true
ro.vendor.audio.monitorRotation=true
ro.vendor.audio.game.mode=true
ro.vendor.audio.game.vibrate=true
ro.vendor.audio.aiasst.support=true
ro.vendor.audio.soundtrigger.lowpower=false
ro.vendor.audio.soundtrigger.adjconf=false
ro.vendor.audio.soundtrigger.pangaea=0
ro.vendor.audio.soundtrigger.sva-5.0=1
ro.vendor.audio.soundtrigger.sva-6.0=1
ro.vendor.audio.soundfx.usb=true
ro.vendor.audio.ring.filter=true
ro.vendor.audio.feature.fade=true
ro.vendor.audio.us.proximity=false
ro.vendor.audio.camera.loopback.support=true
ro.vendor.audio.support.sound.id=true
ro.vendor.standard.video.enable=true
ro.vendor.audio.videobox.switch=true
ro.vendor.video_box.version=2
ro.vendor.audio.feature.spatial=7
ro.vendor.audio.multichannel.5point1.headset=true
ro.vendor.audio.multichannel.5point1=true
ro.vendor.audio.notify5Point1InUse=true
ro.vendor.audio.multi.channel=true
ro.vendor.audio.dolby.eq.half=false
ro.vendor.audio.dolby.vision.support=false
ro.vendor.audio.dolby.vision.capture.support=false
ro.vendor.audio.dolby.surround.enable=false
ro.vendor.audio.surround.support=false
ro.vendor.audio.surround.headphone.only=false
ro.vendor.audio.elus.enable=true
ro.vendor.audio.sfx.scenario=true

audio.high.resolution.enable=true
vendor.audio.high.resolution.enable=true
vendor.audio.offload.buffer.size.kb=384
audio.native.dsd.buffer.size.kb=1024
vendor.audio.native.dsd.buffer.size.kb=1024
audio.truehd.buffer.size.kb=256
vendor.audio.truehd.buffer.size.kb=256

#Bit fixation by NLSound Team 
flac.sw.decoder.24bit.support=true
vendor.audio.flac.sw.decoder.24bit=true
vendor.audio.aac.sw.decoder.24bit=true
vendor.audio.use.sw.alac.decoder=true
vendor.audio.flac.sw.encoder.24bit=true
vendor.audio.aac.sw.encoder.24bit=true
persist.vendor.audio.format.24bit=true
vendor.audio.alac.sw.decoder.24bit=true
vendor.audio.ape.sw.decoder.24bit=true
vendor.audio.mpegh.sw.decoder.24bit=true
vendor.audio.flac.sw.decoder.24bit=true
vendor.audio.aac.sw.decoder.24bit=true
vendor.audio.vorbis.sw.decoder.24bit=true
vendor.audio.wma.sw.decoder.24bit=true
vendor.audio.mp3.sw.decoder.24bit=true
vendor.audio.amrnb.sw.decoder.24bit=true
vendor.audio.amrwb.sw.decoder.24bit=true
vendor.audio.mhas.sw.decoder.24bit=true
vendor.audio.g711.alaw.sw.decoder.24bit=true
vendor.audio.g711.mlaw.sw.decoder.24bit=true
vendor.audio.opus.sw.decoder.24bit=true
vendor.audio.raw.sw.decoder.24bit=true
vendor.audio.ac3.sw.decoder.24bit=true
vendor.audio.eac3.sw.decoder.24bit=true
vendor.audio.eac3_joc.sw.decoder.24bit=true
vendor.audio.ac4.sw.decoder.24bit=true
vendor.audio.qti.sw.decoder.24bit=true
vendor.audio.dsp.sw.decoder.24bit=true
vendor.audio.dsd.sw.decoder.24bit=true
vendor.audio.alac.sw.encoder.24bit=true
vendor.audio.ape.sw.encoder.24bit=true
vendor.audio.mpegh.sw.encoder.24bit=true
vendor.audio.flac.sw.encoder.24bit=true
vendor.audio.aac.sw.encoder.24bit=true
vendor.audio.vorbis.sw.encoder.24bit=true
vendor.audio.wma.sw.encoder.24bit=true
vendor.audio.mp3.sw.encoder.24bit=true
vendor.audio.amrnb.sw.encoder.24bit=true
vendor.audio.amrwb.sw.encoder.24bit=true
vendor.audio.mhas.sw.encoder.24bit=true
vendor.audio.g711.alaw.sw.encoder.24bit=true
vendor.audio.g711.mlaw.sw.encoder.24bit=true
vendor.audio.opus.sw.encoder.24bit=true
vendor.audio.raw.sw.encoder.24bit=true
vendor.audio.ac3.sw.encoder.24bit=true
vendor.audio.eac3.sw.encoder.24bit=true
vendor.audio.eac3_joc.sw.encoder.24bit=true
vendor.audio.ac4.sw.encoder.24bit=true
vendor.audio.qti.sw.encoder.24bit=true
vendor.audio.dsp.sw.encoder.24bit=true
vendor.audio.dsd.sw.encoder.24bit=true" >> $MODPATH/system.prop
fi

ui_print " "
ui_print "   ################======================== 40% done!"

if [ "$STEP13" == "true" ]; then
echo -e "\n# Bluetooth

audio.effect.a2dp.enable=1
vendor.audio.effect.a2dp.enable=1
qcom.hw.aac.encoder=true
qcom.hw.aac.decoder=true
persist.service.btui.use_aptx=1
persist.bt.enableAptXHD=true
persist.bt.a2dp.aptx_disable=false
persist.bt.a2dp.aptx_hd_disable=false
persist.bt.a2dp.aac_disable=false
persist.bt.sbc_hd_enabled=1
persist.vendor.btstack.enable.lpa=false
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true
persist.vendor.btstack.enable.twsplussho=true
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true
persist.vendor.qcom.bluetooth.aptxadaptiver2_2_support=true
#new11102022
persist.rcs.supported=1
persist.vendor.btstack.enable.swb=true
persist.vendor.btstack.enable.swbpm=true
persist.vendor.qcom.bluetooth.enable.swb=true" >> $MODPATH/system.prop
fi

if [ "$STEP14" == "true" ]; then
for OIOPOLICY in ${IOPOLICYS}; do
IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OIOPOLICY $IOPOLICY
sed -i 's/\t/  /g' $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
done
fi

if [ "$STEP14" == "true" ]; then
for OUTPUTPOLICY in ${OUTPUTPOLICYS}; do
OUTPUTPOLICY="$MODPATH$(echo $OUTPUTPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OUTPUTPOLICY $OUTPUTPOLICY
sed -i 's/\t/  /g' $OUTPUTPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $OUTPUTPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $OUTPUTPOLICY
done
fi

for OAUDIOPOLICY in ${AUDIOPOLICYS}; do
AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OAUDIOPOLICY $AUDIOPOLICY
sed -i 's/\t/  /g' $AUDIOPOLICY
sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
done

for OMCODECS in ${MCODECS}; do
MEDIACODECS="$MODPATH$(echo $OMCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
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
MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch -f $ORIGDIR$OMIX $MIX
sed -i 's/\t/  /g' $MIX

STEP2=true
if [ "$STEP2" == "true" ]; then
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
if [ "$VOLSTEPSINT" != "Skip" ]; then
echo -e "\nro.config.media_vol_steps=$VOLSTEPSINT" >> $MODPATH/system.prop
fi
fi

if [ "$STEP15" == "true" ]; then
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

if [ "$STEP3" == "true" ]; then
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
fi

if [ "$STEP7" == "true" ]; then
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
sed -i 's/Softclip0 Enable" value="1"/Softclip0 Enable" value="0"/g' $MIX
sed -i 's/Softclip1 Enable" value="1"/Softclip1 Enable" value="0"/g' $MIX
sed -i 's/Softclip2 Enable" value="1"/Softclip2 Enable" value="0"/g' $MIX
sed -i 's/Softclip3 Enable" value="1"/Softclip3 Enable" value="0"/g' $MIX
sed -i 's/Softclip4 Enable" value="1"/Softclip4 Enable" value="0"/g' $MIX
sed -i 's/Softclip5 Enable" value="1"/Softclip5 Enable" value="0"/g' $MIX
sed -i 's/Softclip6 Enable" value="1"/Softclip6 Enable" value="0"/g' $MIX
sed -i 's/Softclip7 Enable" value="1"/Softclip7 Enable" value="0"/g' $MIX
sed -i 's/Softclip8 Enable" value="1"/Softclip8 Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip Enable" value="1"/"RX_Softclip Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip0 Enable" value="1"/"RX_Softclip0 Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip1 Enable" value="1"/"RX_Softclip1 Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip2 Enable" value="1"/"RX_Softclip2 Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip3 Enable" value="1"/"RX_Softclip3 Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip4 Enable" value="1"/"RX_Softclip4 Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip5 Enable" value="1"/"RX_Softclip5 Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip6 Enable" value="1"/"RX_Softclip6 Enable" value="0"/g' $MIX
sed -i 's/"RX_Softclip7 Enable" value="1"/"RX_Softclip7 Enable" value="0"/g' $MIX
sed -i 's/"WSA_Softclip0 Enable" value="1"/"WSA_Softclip0 Enable" value="0"/g' $MIX
sed -i 's/"WSA_Softclip1 Enable" value="1"/"WSA_Softclip1 Enable" value="0"/g' $MIX
sed -i 's/"WSA_Softclip2 Enable" value="1"/"WSA_Softclip2 Enable" value="0"/g' $MIX
sed -i 's/"WSA_Softclip3 Enable" value="1"/"WSA_Softclip3 Enable" value="0"/g' $MIX
sed -i 's/"WSA_Softclip4 Enable" value="1"/"WSA_Softclip4 Enable" value="0"/g' $MIX
sed -i 's/"WSA_Softclip5 Enable" value="1"/"WSA_Softclip5 Enable" value="0"/g' $MIX
sed -i 's/"WSA_Softclip6 Enable" value="1"/"WSA_Softclip6 Enable" value="0"/g' $MIX
sed -i 's/"WSA_Softclip7 Enable" value="1"/"WSA_Softclip7 Enable" value="0"/g' $MIX
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

sed -i 's/"Compress Playback 1 Volume" value="1"/"Compress Playback 1 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 2 Volume" value="1"/"Compress Playback 2 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 3 Volume" value="1"/"Compress Playback 3 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 4 Volume" value="1"/"Compress Playback 4 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 5 Volume" value="1"/"Compress Playback 5 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 6 Volume" value="1"/"Compress Playback 6 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 7 Volume" value="1"/"Compress Playback 7 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 8 Volume" value="1"/"Compress Playback 8 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 9 Volume" value="1"/"Compress Playback 9 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 10 Volume" value="1"/"Compress Playback 10 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 12 Volume" value="1"/"Compress Playback 11 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 13 Volume" value="1"/"Compress Playback 12 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 14 Volume" value="1"/"Compress Playback 13 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 15 Volume" value="1"/"Compress Playback 14 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 16 Volume" value="1"/"Compress Playback 15 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 16 Volume" value="1"/"Compress Playback 16 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 17 Volume" value="1"/"Compress Playback 17 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 18 Volume" value="1"/"Compress Playback 18 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 19 Volume" value="1"/"Compress Playback 19 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 20 Volume" value="1"/"Compress Playback 20 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 21 Volume" value="1"/"Compress Playback 21 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 22 Volume" value="1"/"Compress Playback 22 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 23 Volume" value="1"/"Compress Playback 23 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 24 Volume" value="1"/"Compress Playback 24 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 25 Volume" value="1"/"Compress Playback 25 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 26 Volume" value="1"/"Compress Playback 26 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 27 Volume" value="1"/"Compress Playback 27 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 28 Volume" value="1"/"Compress Playback 28 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 29 Volume" value="1"/"Compress Playback 29 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 30 Volume" value="1"/"Compress Playback 30 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 31 Volume" value="1"/"Compress Playback 31 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 32 Volume" value="1"/"Compress Playback 32 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 33 Volume" value="1"/"Compress Playback 33 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 34 Volume" value="1"/"Compress Playback 34 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 35 Volume" value="1"/"Compress Playback 35 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 36 Volume" value="1"/"Compress Playback 36 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 37 Volume" value="1"/"Compress Playback 37 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 38 Volume" value="1"/"Compress Playback 38 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 39 Volume" value="1"/"Compress Playback 39 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 40 Volume" value="1"/"Compress Playback 40 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 41 Volume" value="1"/"Compress Playback 41 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 42 Volume" value="1"/"Compress Playback 42 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 43 Volume" value="1"/"Compress Playback 43 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 44 Volume" value="1"/"Compress Playback 44 Volume" value="0"/g' $MIX
sed -i 's/"Compress Playback 45 Volume" value="1"/"Compress Playback 45 Volume" value="0"/g' $MIX

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

if [ "$STEP11" == "true" ]; then
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

if [ "$SD865" ] || [ "$SD888" ] || [ "$SM8450" ] || [ "$SM8550" ]; then
patch_xml -u $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="top-speaker"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="bottom-speaker"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="voice-headset"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="RX HPH Mode"]' "CLS_AB_LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="top-speaker"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="bottom-speaker"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="voice-headset"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
fi

if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 ClassD Edge"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 Volume"]' "30"
echo -e '\nro.sound.alsa=TAS2557' >> $MODPATH/system.prop
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
patch_xml -s $MIX '/mixer/ctl[@name="RCV Boost Target Voltage"]' "170"
patch_xml -s $MIX '/mixer/ctl[@name="Boost Target Voltage"]' "170"
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
if [ "$STEP6" == "true" ]; then
patch_xml -u $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "192000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference earpiece"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference earpiece"]/ctl[@name="EC Reference SampleRate"]' "16000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference headphones"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference headphones"]/ctl[@name="EC Reference SampleRate"]' "192000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference headset"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference headset"]/ctl[@name="EC Reference SampleRate"]' "16000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference headphones-44.1"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference headphones-44.1"]/ctl[@name="EC Reference SampleRate"]' "96000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference speaker"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference speaker"]/ctl[@name="EC Reference SampleRate"]' "96000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference bt-sco"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference bt-sco"]/ctl[@name="EC Reference SampleRate"]' "16000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference bt-sco-wb"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference bt-sco-wb"]/ctl[@name="EC Reference SampleRate"]' "16000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference bt-sco-swb"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference bt-sco-swb"]/ctl[@name="EC Reference SampleRate"]' "48000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference-voip"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference-voip"]/ctl[@name="EC Reference SampleRate"]' "96000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference bt-sco-headset"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference bt-sco-headset"]/ctl[@name="EC Reference SampleRate"]' "16000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference usb-headphones"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference usb-headphones"]/ctl[@name="EC Reference SampleRate"]' "192000"
patch_xml -u $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -u $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "384000"
#end if step6=true 
fi
#end STEP7 patching
fi

if [ "$POCOX3" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME LEFT"]' "80"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE LEFT"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP LEFT"]' "3"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X RX MODE LEFT"]' "Speaker"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE LEFT"]' "15"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT LEFT"]' "70"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME RIGHT"]' "80"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE RIGHT"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP RIGHT"]' "3"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE RIGHT"]' "15"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT RIGHT"]' "68"
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
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT LEFT"]' "57"
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

if [ "$RN10PRO" ] || [ "$RN10PROMAX" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="aw882_xx_rx_switch"]' "Enable"
patch_xml -s $MIX '/mixer/ctl[@name="aw882_xx_tx_switch"]' "Enable"
patch_xml -s $MIX '/mixer/ctl[@name="aw882_copp_switch"]' "Enable"
patch_xml -s $MIX '/mixer/ctl[@name="aw_dev_0_prof"]' "Receiver"
patch_xml -s $MIX '/mixer/ctl[@name="aw_dev_0_switch"]' "Enable"
patch_xml -s $MIX '/mixer/ctl[@name="aw_dev_1_prof"]' "Receiver"
patch_xml -s $MIX '/mixer/ctl[@name="aw_dev_1_switch"]' "Enable"
fi

#end mixer patching function
done

ui_print " "                 
ui_print "   ################################======== 80% done!"

if [ "$STEP16" == "true" ]; then
echo -e "\n #Disable all effects
ro.audio.ignore_effects=true
ro.vendor.audio.ignore_effects=true
vendor.audio.ignore_effects=true
persist.audio.ignore_effects=true
persis.vendor.audio.ignore_effects=true
persist.sys.phh.disable_audio_effects=1
ro.audio.disable_audio_effects=1
vendor.audio.disable_audio_effects=1
low.pass.filter=Off
high.pass.filter=Off
LPF=Off
HPF=Off" >> $MODPATH/system.prop
fi

#patching io policy
if find $SYSTEM $VENDOR -type f -name "audio_io_policy.xml" >/dev/null; then
if [ "$BITNESINT" == "24" ]; then
#format
sed -i 's/%OUT_FORMAT_DEFAULT%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DEFAULT24%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PROAUDIO%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_VOIP%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DB%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DB24%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM16%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM24%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM32%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP16%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP24%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP32%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $IOPOLICYS
#bitwidth
sed -i 's/%OUT_BIT_DEFAULT%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DEFAULT_24%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PROAUDIO%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_VOIP%/16/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DB%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DB24%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM16%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM24%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM32%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP16%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP24%/24/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP32%/24/g' $IOPOLICYS
fi

if [ "$BITNESINT" == "32" ]; then
#format
sed -i 's/%OUT_FORMAT_DEFAULT%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DEFAULT24%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PROAUDIO%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_VOIP%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DB%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DB24%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM16%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM24%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM32%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP16%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP24%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP32%/AUDIO_FORMAT_PCM_32_BIT/g' $IOPOLICYS
#bitwidth
sed -i 's/%OUT_BIT_DEFAULT%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DEFAULT_24%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PROAUDIO%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_VOIP%/16/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DB%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DB24%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM16%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM24%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM32%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP16%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP24%/32/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP32%/32/g' $IOPOLICYS
fi

if [ "$BITNESINT" == "float" ]; then
#format
sed -i 's/%OUT_FORMAT_DEFAULT%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DEFAULT24%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PROAUDIO%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_VOIP%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DB%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_DB24%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM16%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM24%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_PCM32%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP16%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP24%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%OUT_FORMAT_COMP32%/AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
#bitwidth
sed -i 's/%OUT_BIT_DEFAULT%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DEFAULT_24%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PROAUDIO%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_VOIP%/16/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DB%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_DB24%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM16%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM24%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_PCM32%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP16%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP24%/float/g' $IOPOLICYS
sed -i 's/%OUT_BIT_COMP32%/float/g' $IOPOLICYS
fi

#samplerate
if [ "$SAMPLERATEINT" == "96000" ]; then
sed -i 's/%OUT_SMPL_DEFAULT%/96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DEFAULT_24%/96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PROAUDIO%/96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_VOIP%/8000|16000|32000|48000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DB%/96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DB24%/96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM16%/44100|48000|96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM24%/44100|48000|96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM32%/44100|48000|96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP16%/44100|48000|96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP24%/44100|48000|96000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP32%/44100|48000|96000/g' $IOPOLICYS
fi

if [ "$SAMPLERATEINT" == "192000" ]; then
sed -i 's/%OUT_SMPL_DEFAULT%/192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DEFAULT_24%/192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PROAUDIO%/192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_VOIP%/8000|16000|32000|48000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DB%/192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DB24%/192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM16%/44100|48000|96000|192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM24%/44100|48000|96000|192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM32%/44100|48000|96000|192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP16%/44100|48000|96000|192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP24%/44100|48000|96000|192000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP32%/44100|48000|96000|192000/g' $IOPOLICYS
fi

if [ "$SAMPLERATEINT" == "384000" ]; then
sed -i 's/%OUT_SMPL_DEFAULT%/384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DEFAULT_24%/384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PROAUDIO%/384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_VOIP%/8000|16000|32000|48000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DB%/384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_DB24%/384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM16%/44100|48000|96000|192000|384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM24%/44100|48000|96000|192000|384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_PCM32%/44100|48000|96000|192000|384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP16%/44100|48000|96000|192000|384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP24%/44100|48000|96000|192000|384000/g' $IOPOLICYS
sed -i 's/%OUT_SMPL_COMP32%/44100|48000|96000|192000|384000/g' $IOPOLICYS
fi

#input
sed -i 's/%IN_FORMAT_REC16%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_REC24%/AUDIO_FORMAT_PCM_24_BIT_PACKED|AUDIO_FORMAT_PCM_24_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_REC32%/AUDIO_FORMAT_PCM_32_BIT|AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_COMP16%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_COMP24%/AUDIO_FORMAT_PCM_24_BIT_PACKED|AUDIO_FORMAT_PCM_24_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_COMP32%/AUDIO_FORMAT_PCM_32_BIT|AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_VOIP%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_LLVOIP%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS

sed -i 's/%IN_SMPL_REC16%/8000|16000|32000|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_REC24%/44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_REC32%/44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_COMP16%/8000|16000|32000|44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_COMP24%/44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_COMP32%/44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_VOIP%/8000|16000|32000|48000/g' $IOPOLICYS
sed -i 's/%IN_BIT_VOIP%/48000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_LLVOIP%/48000/g' $IOPOLICYS

sed -i 's/%IN_BIT_REC16%/16/g' $IOPOLICYS
sed -i 's/%IN_BIT_REC24%/24/g' $IOPOLICYS
sed -i 's/%IN_BIT_REC32%/32/g' $IOPOLICYS
sed -i 's/%IN_BIT_COMP16%/16/g' $IOPOLICYS
sed -i 's/%IN_BIT_COMP24%/24/g' $IOPOLICYS
sed -i 's/%IN_BIT_COMP32%/32/g' $IOPOLICYS
sed -i 's/%IN_BIT_VOIP%/16/g' $IOPOLICYS
sed -i 's/%IN_BIT_LLVOIP%/16/g' $IOPOLICYS


if [ "$BITNESINT" != "Skip" ] || [ "$SAMPLERATEINT" != "Skip" ]; then
cp_ch $MODPATH/common/NLSound/audio_io_policy.conf $MODPATH/system/vendor/etc
fi
#end function
fi

#patching output_policy
if find $SYSTEM $VENDOR -type f -name "audio_output_policy.xml" >/dev/null; then
if [ "$BITNESINT" == "24" ]; then
#format
sed -i 's/%OUT_FORMAT_DEFAULT%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DEFAULT24%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PROAUDIO%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_VOIP%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DB%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DB24%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM16%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM24%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM32%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP16%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP24%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP32%/AUDIO_FORMAT_PCM_24_BIT_PACKED/g' $OUTPUTPOLICYS
#bitwidth
sed -i 's/%OUT_BIT_DEFAULT%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DEFAULT_24%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PROAUDIO%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_VOIP%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DB%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DB24%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM16%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM24%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM32%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP16%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP24%/24/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP32%/24/g' $OUTPUTPOLICYS
fi

if [ "$BITNESINT" == "32" ]; then
#format
sed -i 's/%OUT_FORMAT_DEFAULT%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DEFAULT24%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PROAUDIO%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_VOIP%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DB%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DB24%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM16%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM24%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM32%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP16%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP24%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP32%/AUDIO_FORMAT_PCM_32_BIT/g' $OUTPUTPOLICYS
#bitwidth
sed -i 's/%OUT_BIT_DEFAULT%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DEFAULT_24%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PROAUDIO%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_VOIP%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DB%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DB24%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM16%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM24%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM32%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP16%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP24%/32/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP32%/32/g' $OUTPUTPOLICYS
fi

if [ "$BITNESINT" == "float" ]; then
#format
sed -i 's/%OUT_FORMAT_DEFAULT%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DEFAULT24%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PROAUDIO%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_VOIP%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DB%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_DB24%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM16%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM24%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_PCM32%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP16%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP24%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
sed -i 's/%OUT_FORMAT_COMP32%/AUDIO_FORMAT_PCM_FLOAT/g' $OUTPUTPOLICYS
#bitwidth
sed -i 's/%OUT_BIT_DEFAULT%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DEFAULT_24%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PROAUDIO%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_VOIP%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DB%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_DB24%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM16%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM24%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_PCM32%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP16%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP24%/float/g' $OUTPUTPOLICYS
sed -i 's/%OUT_BIT_COMP32%/float/g' $OUTPUTPOLICYS
fi

#samplerate
if [ "$SAMPLERATEINT" == "96000" ]; then
sed -i 's/%OUT_SMPL_DEFAULT%/96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DEFAULT_24%/96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PROAUDIO%/96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_VOIP%/96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DB%/96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DB24%/96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM16%/44100|48000|96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM24%/44100|48000|96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM32%/44100|48000|96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP16%/44100|48000|96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP24%/44100|48000|96000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP32%/44100|48000|96000/g' $OUTPUTPOLICYS
fi

if [ "$SAMPLERATEINT" == "192000" ]; then
sed -i 's/%OUT_SMPL_DEFAULT%/192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DEFAULT_24%/192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PROAUDIO%/192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_VOIP%/192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DB%/192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DB24%/192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM16%/44100|48000|96000|192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM24%/44100|48000|96000|192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM32%/44100|48000|96000|192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP16%/44100|48000|96000|192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP24%/44100|48000|96000|192000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP32%/44100|48000|96000|192000/g' $OUTPUTPOLICYS
fi

if [ "$SAMPLERATEINT" == "384000" ]; then
sed -i 's/%OUT_SMPL_DEFAULT%/384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DEFAULT_24%/384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PROAUDIO%/384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_VOIP%/384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DB%/384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_DB24%/384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM16%/44100|48000|96000|192000|384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM24%/44100|48000|96000|192000|384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_PCM32%/44100|48000|96000|192000|384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP16%/44100|48000|96000|192000|384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP24%/44100|48000|96000|192000|384000/g' $OUTPUTPOLICYS
sed -i 's/%OUT_SMPL_COMP32%/44100|48000|96000|192000|384000/g' $OUTPUTPOLICYS
fi

#input
sed -i 's/%IN_FORMAT_REC16%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_REC24%/AUDIO_FORMAT_PCM_24_BIT_PACKED|AUDIO_FORMAT_PCM_24_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_REC32%/AUDIO_FORMAT_PCM_32_BIT|AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_COMP16%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_COMP24%/AUDIO_FORMAT_PCM_24_BIT_PACKED|AUDIO_FORMAT_PCM_24_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_COMP32%/AUDIO_FORMAT_PCM_32_BIT|AUDIO_FORMAT_PCM_FLOAT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_VOIP%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS
sed -i 's/%IN_FORMAT_LLVOIP%/AUDIO_FORMAT_PCM_16_BIT/g' $IOPOLICYS

sed -i 's/%IN_SMPL_REC16%/8000|16000|32000|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_REC24%/44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_REC32%/44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_COMP16%/8000|16000|32000|44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_COMP24%/44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_COMP32%/44100|48000|88200|96000|176400|192000/g' $IOPOLICYS
sed -i 's/%IN_SMPL_VOIP%/8000|16000|32000|48000/g' $IOPOLICYS
sed -i 's/%IN_BIT_VOIP%/48000/g' $IOPOLICYS

sed -i 's/%IN_BIT_REC16%/16/g' $IOPOLICYS
sed -i 's/%IN_BIT_REC24%/24/g' $IOPOLICYS
sed -i 's/%IN_BIT_REC32%/32/g' $IOPOLICYS
sed -i 's/%IN_BIT_COMP16%/16/g' $IOPOLICYS
sed -i 's/%IN_BIT_COMP24%/24/g' $IOPOLICYS
sed -i 's/%IN_BIT_COMP32%/32/g' $IOPOLICYS
sed -i 's/%IN_BIT_VOIP%/16/g' $IOPOLICYS
sed -i 's/%IN_BIT_LLVOIP%/16/g' $IOPOLICYS

if [ "$BITNESINT" != "Skip" ] || [ "$SAMPLERATEINT" != "Skip" ]; then
cp_ch $MODPATH/common/NLSound/audio_output_policy.conf $MODPATH/system/vendor/etc
fi
#end function
fi

ui_print " "
ui_print "   ######################################## 100% done!"

if [ "$STEP17" == "true" ]; then
echo -e '\n# Experimental tweaks

if [ "$POCOF3" ]; then
while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 32
tinymix "AFE Input Bit Format" S32_LE
tinymix "USB_AUDIO_RX Format" S32_LE
tinymix "USB_AUDIO_TX Format" S32_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_384
tinymix "USB_AUDIO_TX SampleRate" KHZ_384
tinymix "RCV Digital PCM Volume" 830
tinymix "Digital PCM Volume" 830
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "RCV PCM Soft Ramp" Off
tinymix "PCM Soft Ramp" Off
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S32_LE
tinymix "TERT_TDM_RX_1 Format" S32_LE
tinymix "TERT_MI2S_RX Format" S32_LE
tinymix "TERT_MI2S_TX Format" S32_LE
tinymix "TERT_MI2S_RX SampleRate" KHZ_384
tinymix "TERT_MI2S_TX SampleRate" KHZ_384
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
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_384
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_384
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_0_RX Format" S32_LE
tinymix "SLIM_0_TX Format" S32_LE
tinymix "SLIM_5_RX Format" S32_LE
tinymix "SLIM_6_RX Format" S32_LE
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
tinymix "RCV Noise Gate" 0
tinymix "Noise Gate" 0
tinymix "Display Port1 RX Bit Format" S24_3LE
sleep 4
done
fi

if [ "$POCOX3" ] || [ "$RN10PRO" ] || [ "$RN10PROMAX" ]; then
while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S24_3LE
tinymix "USB_AUDIO_RX Format" S24_3LE
tinymix "USB_AUDIO_TX Format" S24_3LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_192
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "RCV Digital PCM Volume" 830
tinymix "Digital PCM Volume" 830
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "RCV PCM Soft Ramp" Off
tinymix "PCM Soft Ramp" Off
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S24_3LE
tinymix "TERT_TDM_RX_1 Format" S24_3LE
tinymix "TERT_MI2S_RX Format" S24_3LE
tinymix "TERT_MI2S_TX Format" S24_3LE
tinymix "TERT_MI2S_RX SampleRate" KHZ_192
tinymix "TERT_MI2S_TX SampleRate" KHZ_192
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
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_0_RX Format" S24_3LE
tinymix "SLIM_0_TX Format" S24_3LE
tinymix "SLIM_5_RX Format" S24_3LE
tinymix "SLIM_6_RX Format" S24_3LE
tinymix "Cirrus SP Load Config" Load
tinymix "RCV Noise Gate" 0
tinymix "Noise Gate" 0
tinymix "Display Port1 RX Bit Format" S24_3LE
sleep 4
done
fi' >> $MODPATH/service.sh
fi

ui_print " "
ui_print " - All done! With love, NLSound Team. - "
ui_print " "
