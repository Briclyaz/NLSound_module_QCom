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
SM845075=$(grep "ro.board.platform=taro" $BUILDS)

if [ "$SD662" ] || [ "$SD665" ] || [ "$SD670" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730G" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ] || [ "$SM845075" ]; then
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
APIIXMLS="$(find /system /vendor /system_ext/product -type f -name "audio_platform_info_intcodec*.xml")"
APIEXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info_extcodec*.xml")"
APIQRDXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info_qrd*.xml")"
DEVFEAS="$(find /system /vendor /system_ext /product -type f -name "$DEVICE.xml")"; 
AUDIOPOLICYS="$(find /system /vendor /system_ext /product -type f -name "audio_policy_configuration.xml")"
SNDTRGS="$(find /system /vendor /system_ext /product -type f -name "*sound_trigger_mixer_paths*.xml")"
MCODECS="$(find /system /vendor /system_ext /product -type f -name "media_codecs_*_audio.xml")"

VNDK=$(find /system/lib /vendor/lib -type d -iname "*vndk*")
VNDK64=$(find /system/lib64 /vendor/lib64 -type d -iname "*vndk*")
VNDKQ=$(find /system/lib /vendor/lib -type d -iname "vndk*-Q")

SETTINGS=$MODPATH/settings.nls

RESTORE=false

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
VOLSTEPSINT=false
VOLMEDIAINT=false
VOLMICINT=false
BITNESINT=false
SAMPLERATEINT=false

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
	ui_print "* [1/18]                                          *"
	ui_print "*                                                 *"
	ui_print "*            • Select volumes steps •             *"
	ui_print "*       Lower value - faster volume control       *"
	ui_print "*_________________________________________________*"
	ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
	ui_print "***************************************************"
	sleep 1
	VOLSTEPS=1
	ui_print " "
	ui_print "   1. Skip (No changes will be made)"
	ui_print "   2. 30 ( ~ 1.1 - 2.0 dB per step)"
	ui_print "   3. 50 ( ~ 0.8 - 1.4 dB per step)"
	ui_print "   4. 100 ( ~ 0.4 - 0.7 dB per step)"
	ui_print " "
	ui_print "      Selected: "
	while true; do
	ui_print "      $VOLSTEPS"
	if $VKSEL; then
		VOLSTEPS=$((VOLSTEPS + 1))
	else
		break
	fi
		
	if [ $VOLSTEPS -gt 4 ]; then
		VOLSTEPS=1
	fi
	
      STEP1=true
	  sed -i 's/STEP1=false/STEP1=true/g' $SETTINGS
	  sed -i 's/VOLSTEPS=skip/VOLSTEPS='$VOLSTEPSINT'/g' $SETTINGS
	done

	case $VOLSTEPS in
	1) VOLSTEPSINT=0;;
	2) VOLSTEPSINT=30;;
	3) VOLSTEPSINT=50;;
	4) VOLSTEPSINT=100;
	esac

    ui_print " "
	ui_print "***************************************************"
	ui_print "* [2/18]                                          *"
	ui_print "*                                                 *"
	ui_print "*          • Select volumes for Media •           *"
	ui_print "*      Lower numerical value - lower volume       *"
	ui_print "*_________________________________________________*"
	ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
	ui_print "***************************************************"
	sleep 1
	VOLMEDIA=1
	ui_print " "
	ui_print "   1. Skip (No changes will be made)"
	ui_print "   2. 84 "
	ui_print "   3. 86"
	ui_print "   4. 88"
	ui_print "   5. 90"
	ui_print "   6. 92"
	ui_print "   7. 94"
	ui_print " "
	ui_print "      Selected: "
	while true; do
	ui_print "      $VOLMEDIA"
	if $VKSEL; then
		VOLMEDIA=$((VOLMEDIA + 1))
	else
		break
	fi
		
	if [ $VOLMEDIA -gt 7 ]; then
		VOLMEDIA=1
	fi

      STEP2=true
	  sed -i 's/STEP2=false/STEP2=true/g' $SETTINGS
	  sed -i 's/VOLMEDIA=skip/VOLMEDIA='$VOLMEDIAINT'/g' $SETTINGS
	done

	case $VOLMEDIA in
	1) VOLMEDIAINT=0;;
	2) VOLMEDIAINT=84;;
	3) VOLMEDIAINT=86;;
	4) VOLMEDIAINT=88;;
	5) VOLMEDIAINT=90;;
	6) VOLMEDIAINT=92;;
	7) VOLMEDIAINT=94;
	esac

    ui_print "  "
	ui_print "***************************************************"
	ui_print "* [3/18]                                          *"
	ui_print "*                                                 *"
	ui_print "*            • Microphone sensitivity •           *"
	ui_print "*       Lower numerical value - lower volume      *"
    ui_print "*_________________________________________________*"
    ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
	ui_print "***************************************************"
	sleep 1
	VOLMIC=1
	ui_print " "
	ui_print "   1. Skip (No changes will be made)"
	ui_print "   2. 84 "
	ui_print "   3. 86"
	ui_print "   4. 88"
	ui_print "   5. 90"
	ui_print "   6. 92"
	ui_print "   7. 94"
	ui_print " "
	ui_print "      Selected: "
	while true; do
	ui_print "      $VOLMIC"
	if $VKSEL; then
		VOLMIC=$((VOLMIC + 1))
	else
		break
	fi
		
	if [ $VOLMIC -gt 7 ]; then
		VOLMIC=1
	fi

      STEP3=true
	  sed -i 's/STEP3=false/STEP3=true/g' $SETTINGS
	  sed -i 's/VOLMIC=skip/VOLMIC='$VOLMICINT'/g' $SETTINGS
	done

	case $VOLMIC in
	1) VOLMICINT=0;;
	2) VOLMICINT=84;;
	3) VOLMICINT=86;;
	4) VOLMICINT=88;;
	5) VOLMICINT=90;;
	6) VOLMICINT=92;;
	7) VOLMICINT=94;
	esac

    sleep 1
    MICMOD=1
    ui_print " "
	ui_print "***************************************************"
	ui_print "* [4/18]                                          *"
    ui_print "*                                                 *"
    ui_print "*            • Fluence configuration •            *"
	ui_print "*                                                 *"
	ui_print "*   This option will change the aggressiveness    *"
	ui_print "*       and quality of the built-in noise         *"
	ui_print "*       cancellation for your microphones.        *"
	ui_print "*                                                 *"
	ui_print "*   1. Skip (No changes will be made)             *"
	ui_print "*   2. Fluence                                    *"
	ui_print "*   3. Fluencepro                                 *"
	ui_print "*   4. Disable                                    *"
	ui_print "*_________________________________________________*"
	ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
	ui_print "***************************************************"
	ui_print " "
	ui_print "      Selected: "
	while true; do
	ui_print "      $MICMOD"
	if $VKSEL; then
		MICMOD=$((MICMOD+ 1))
	else
		break
	fi
		
	if [ $MICMOD -gt 4 ]; then
		MICMOD=1
	fi

      STEP4=true
	  sed -i 's/STEP4=false/STEP4=true/g' $SETTINGS
	  sed -i 's/MICMOD=skip/MICMOD='$MICMODINT'/g' $SETTINGS
	done

	case $MICMOD in
	1) MICMODINT=0;;
	2) MICMODINT=fluence;;
	3) MICMODINT=fluencepro;;
	4) MICMODINT=none;
	esac

	ui_print " "
    ui_print "***************************************************"
	ui_print "* [5/18]                                          *"
	ui_print "*                                                 *"
	ui_print "*            • Select audio format •              *"
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
	ui_print "   3. 32-bit"
	ui_print "   4. float"
	ui_print " "
	ui_print "      Selected: "
	while true; do
	ui_print "      $BITNES"
	if $VKSEL; then
		BITNES=$((BITNES + 1))
	else
		break
	fi
		
	if [ $BITNES -gt 4 ]; then
		BITNES=1
	fi

      STEP5=true
	  sed -i 's/STEP5=false/STEP5=true/g' $SETTINGS
	  sed -i 's/BITNES=skip/BITNES='$BITNESINT'/g' $SETTINGS
	done

	case $BITNES in
	1) BITNESINT=0;;
	2) BITNESINT=24;;
	3) BITNESINT=32;;
	4) BITNESINT=float;
	esac
        
    ui_print " "
    ui_print "***************************************************"
	ui_print "* [6/18]                                          *"
	ui_print "*                                                 *"
	ui_print "*             • Select sampling rate •            *"
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
	SAMPLERATE=1
	ui_print " "
	ui_print "   1. Skip (No changes will be made)"
	ui_print "   2. 96000 kHz "
	ui_print "   3. 192000 kHz "
	ui_print "   4. 384000 kHz "
	ui_print " "
	ui_print "      Selected: "
	while true; do
	ui_print "      $SAMPLERATE"
	if $VKSEL; then
		SAMPLERATE=$((SAMPLERATE + 1))
	else
		break
	fi
		
	if [ $SAMPLERATE -gt 4 ]; then
		SAMPLERATE=1
	fi

      STEP6=true
	  sed -i 's/STEP6=false/STEP6=true/g' $SETTINGS
	  sed -i 's/SAMPLERATE=skip/SAMPLERATE='$SAMPLERATEINT'/g' $SETTINGS
	done



	case $SAMPLERATE in
	1) SAMPLERATEINT=0;;
	2) SAMPLERATEINT=96000;;
	3) SAMPLERATEINT=192000;;
	4) SAMPLERATEINT=384000;
	esac

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [7/18]                                          *"
    ui_print "*                                                 *"
	ui_print "*        • Patching audio platform files •        *"
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
	  STEP7=true
	  sed -i 's/STEP7=false/STEP7=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [8/18]                                          *"
    ui_print "*                                                 *"
	ui_print "*           • Disabling сompanders •              *"
	ui_print "*                                                 *"
	ui_print "*            When you click *Install*,            *"
	ui_print "*          you disable this mechanism.            *"
	ui_print "*                                                 *"
	ui_print "*    Companding-exists for audio compression.     *"
	ui_print "*    Because of this algorithm, you can hear      *"
	ui_print "*  the hiss in the path is even lossless audio.   *"
	ui_print "*     This algorithm does not work properly.      *"
	ui_print "*    Everything he does is pointlessly making     *"
	ui_print "* things worse the quality of your favorite audio *"
	ui_print "*        [Recommended for installation]           *"
	ui_print "*_________________________________________________*"
    ui_print "*        [VOL+] - install | [VOL-] - skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
	  STEP8=true
	  sed -i 's/STEP8=false/STEP8=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [9/18]                                          *"
    ui_print "*                                                 *"
	ui_print "*     • Configurating interal audio codec •       *"
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
	   STEP9=true
	   sed -i 's/STEP9=false/STEP9=true/g' $SETTINGS
	fi
	 
	ui_print " "
	ui_print "***************************************************"
	ui_print "* [10/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*       • Patching device_features files •        *"
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
		STEP10=true
		sed -i 's/STEP10=false/STEP10=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [11/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*                • New dirac •                    *"
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
		STEP11=true
		sed -i 's/STEP11=false/STEP11=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [12/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*       • Other patches in mixer_paths •          *"
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
	  STEP12=true
	  sed -i 's/STEP12=false/STEP12=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [13/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*            • Tweaks in prop file •              *"
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
	  STEP13=true
	  sed -i 's/STEP13=false/STEP13=true/g' $SETTINGS
	fi
	
	ui_print " "
	ui_print "***************************************************"
	ui_print "* [14/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*             • Improve Bluetooth •               *"
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
	  STEP14=true
	  sed -i 's/STEP14=false/STEP14=true/g' $SETTINGS
	fi
	
	ui_print " "
	ui_print "***************************************************"
	ui_print "* [15/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*            • Switch audio output •              *"
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
	  STEP15=true
	  sed -i's/STEP15=false/STEP15=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [16/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*                 • IIR patches •                 *"
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
	  STEP16=true
	  sed -i 's/STEP16=false/STEP16=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [17/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*          • Ignore all audio effects •           *"
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
	  STEP17=true
	  sed -i 's/STEP17=false/STEP17=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [18/18]                                         *"
    ui_print "*                                                 *"
	ui_print "*      • Experimental tweaks for tinymix •        *"
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
	  STEP18=true
	  sed -i 's/STEP18=false/STEP18=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print " - Processing. . . -"
	ui_print " "
	ui_print " - You can minimize Magisk and use the device normally -"
	ui_print " - and then come back here to reboot and apply the changes. -"
	ui_print " "

if [ "$STEP7" == "true" ]; then
if [ "$BITNESINT" != "0" ]; then
if [ "$SAMPLERATEINT" != "0" ]; then
for OAPIXML in ${APIXMLS}; do
APIXML="$MODPATH$(echo $OAPIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OAPIXML $APIXML
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

if [ "$BITNESINT" != "0" ]; then
if [ "$SAMPLERATEINT" != "0" ]; then
for OAPIIXML in ${APIIXMLS}; do
APIIXML="$MODPATH$(echo $OAPIIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OAPIIXML $APIIXML
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

if [ "$BITNESINT" != "0" ]; then
if [ "$SAMPLERATEINT" != "0" ]; then
for OAPIEXML in ${APIEXMLS}; do
APIEXML="$MODPATH$(echo $OAPIEXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OAPIEXML $APIEXML
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

if [ "$BITNESINT" != "0" ]; then
if [ "$SAMPLERATEINT" != "0" ]; then
for OAPIQRDXML in ${APIQRDXMLS}; do
APIQRDXML="$MODPATH$(echo $OAPIQRDXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OAPIQRDXML $APIQRDXML
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

bitaddonprop=true
fi

if [ "$bitaddonprop" == "true" ]; then
echo -e '#Bit fixation by NLSound Team 
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
vendor.audio.dsd.sw.encoder.24bit=true' >> $MODPATH/system.prop
fi


ui_print " "
ui_print "   ################======================== 40% done!"

if [ "$STEP9" == "true" ]; then
for OACONF in ${ACONFS}; do
ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OACONF $ACONF
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

if [ "$STEP10" == "true" ]; then
for ODEVFEA in ${DEVFEAS}; do 
DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$ODEVFEA $DEVFEA
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

if [ "$STEP11" == "true" ]; then
for OFILE in ${AECFGS}; do
FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OFILE $FILE
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
persist.dirac.gef.ext.did=750,750,750,750
persist.dirac.gef.ins.did=50,50,50
persist.dirac.gef.int.did=750,750,750,750
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
persist.audio.dirac.eq=5.0,4.0,3.0,3.0,4.0,1.0,0.0
persist.audio.dirac.headset=1
persist.audio.dirac.music.state=1' >> $MODPATH/system.prop
fi

if [ "$STEP13" == "true" ]; then
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
vendor.audio.truehd.buffer.size.kb=256" >> $MODPATH/system.prop
fi


ui_print " "                 
ui_print "   ########################================ 60% done!"

if [ "$STEP14" == "true" ]; then
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

if [ "$STEP15" == "true" ]; then
for OIOPOLICY in ${IOPOLICYS}; do
IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OIOPOLICY $IOPOLICY
sed -i 's/\t/  /g' $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
done
fi

if [ "$STEP15" == "true" ]; then
for OUTPUTPOLICY in ${OUTPUTPOLICYS}; do
OUTPUTPOLICY="$MODPATH$(echo $OUTPUTPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OUTPUTPOLICY $OUTPUTPOLICY
sed -i 's/\t/  /g' $OUTPUTPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $OUTPUTPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $OUTPUTPOLICY
done
fi

uselessdrc=true
if [ "$uselessdrc" == "true" ]; then
for OAUDIOPOLICY in ${AUDIOPOLICYS}; do
AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OAUDIOPOLICY $AUDIOPOLICY
sed -i 's/\t/  /g' $AUDIOPOLICY
sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
done
fi

mediacodecspatching=true
if [ "$mediacodecspatching" == "true" ]; then
for OMCODECS in ${MCODECS}; do
MEDIACODECS="$MODPATH$(echo $OMCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OMCODECS $MEDIACODECS
sed -i 's/\t/  /g' $MEDIACODECS
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
done
fi

for OMIX in ${MPATHS}; do
MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OMIX $MIX
sed -i 's/\t/  /g' $MIX

STEP2=true
if [ "$STEP2" == "true" ]; then
if [ "$VOLMEDIAINT" != "0" ]; then
patch_xml -u $MIX '/mixer/ctl[@name="RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX4 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX5 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX6 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX7 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -s $MIX '/mixer/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -s $MIX '/mixer/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX4 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX5 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX6 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX7 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX4 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX5 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX6 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX7 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX4 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX5 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX6 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX7 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX8 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_RX0 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_RX1 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_RX2 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_RX3 Digital Volume"]' "$VOLMEDIAINT"
patch_xml -u $MIX '/mixer/ctl[@name="LINEOUT1 Volume"]' "5"
patch_xml -u $MIX '/mixer/ctl[@name="LINEOUT2 Volume"]' "5"
fi
if [ "$VOLSTEPSINT" != "0" ]; then
echo -e "\nro.config.media_vol_steps=$VOLSTEPSINT" >> $MODPATH/system.prop
fi
fi

if [ "$STEP16" == "true" ]; then
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="0"]' "238395206"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="1"]' "689443228"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="2"]' "205354587"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="3"]' "689443228"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="4"]' "175314338"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="0"]' "262009200"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="1"]' "568438374"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="2"]' "243939794"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="3"]' "569025299"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="4"]' "238100463"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="0"]' "253440447"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="1"]' "842391711"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="2"]' "209259777"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="3"]' "842391711"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="4"]' "194264768"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="0"]' "268435456"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="1"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="2"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="3"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="4"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="0"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="1"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="2"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="3"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="4"]' "0"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band0"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band1"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band2"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band3"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band4"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band5"]' "1"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP0 Volume"]' "82"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 Volume"]' "82"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 Volume"]' "82"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 Volume"]' "82"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP4 Volume"]' "82"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP5 Volume"]' "82"
fi

if [ "$STEP3" == "true" ]; then
if [ "$VOLMICINT" != "0" ]; then
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
patch_xml -u $MIX '/mixer/ctl[@name="ADC0 Volume"]' "20"
patch_xml -u $MIX '/mixer/ctl[@name="ADC1 Volume"]' "20"
patch_xml -u $MIX '/mixer/ctl[@name="ADC2 Volume"]' "20"
patch_xml -u $MIX '/mixer/ctl[@name="ADC3 Volume"]' "20"
patch_xml -u $MIX '/mixer/ctl[@name="ADC4 Volume"]' "20"
fi
fi
if [ "$STEP4" == "true" ]; then
if [ "$MICMODINT" != "0" ]; then
echo -e "\n #Fluence configuration
ro.vendor.audio.sdk.fluencetype=$MICMODINT
ro.qc.sdk.audio.fluencetype=$MICMODINT
persist.vendor.audio.fluence.voicecall=false
persist.vendor.audio.fluence.voicerec=true
persist.vendor.audio.fluence.speaker=true
persist.vendor.audio.fluence.tmic.enabled=true" >> $MODPATH/system.prop
fi
fi

if [ "$STEP8" == "true" ]; then
patch_xml -u $MIX '/mixer/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=HPHR_COMP Switch]' "0"
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
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=aac-initial]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=ADSP testfwk]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=bt-a2dp]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=deep-buffer-playback headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=low-latency-playback headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 16 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 15 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 29 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 30 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 31 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 32 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 41 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 42 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 43 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 44 Volume]' "0"
patch_xml -u $MIX '/mixer/ctl[@name=Compress Playback 45 Volume]' "0"
fi

if [ "$STEP12" == "true" ]; then
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
patch_xml -u $MIX '/mixer/ctl[@name="RX INT0 DEM MUX"]' "CLSH_DSM_OUT"
patch_xml -u $MIX '/mixer/ctl[@name="RX INT1 DEM MUX"]' "CLSH_DSM_OUT"
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
patch_xml -s $MIX '/mixer/ctl[@name="A2DP_SLIM7_UL_HL Switch"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="SLIM7_RX_DL_HL Switch"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="App Type Gain"]' "8192"
patch_xml -s $MIX '/mixer/ctl[@name="Audiosphere Enable"]' "On"
patch_xml -s $MIX '/mixer/ctl[@name="MSM ASphere Set Param"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="RX_Softclip Enable"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_Softclip0 Enable"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_Softclip1 Enable"]' "1"
patch_xml -s $MIX '/mixer/ctl[@name="Load acoustic model"]' "1"
patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="TWS Channel Mode"]' "Two"
patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="TWS Channel Mode"]' "Two"
patch_xml -u $MIX '/mixer/ctl[@name="TWS Channel Mode"]' "Two"
patch_xml -s $MIX '/mixer/ctl[@name="TWS Channel Mode"]' "Two"
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


if [ "$STEP17" == "true" ]; then
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

cp_ch $MODPATH/common/NLSound/audio_io_policy.conf $MODPATH/system/vendor/etc
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

cp_ch $MODPATH/common/NLSound/audio_output_policy.conf $MODPATH/system/vendor/etc
#end function
fi

if [ "$STEP18" == "true" ]; then
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
fi
done' >> $MODPATH/service.sh
fi

ui_print " "
ui_print "   ######################################## 100% done!"

ui_print " "
ui_print " - All done! With love, NLSound Team. - "
ui_print " "
