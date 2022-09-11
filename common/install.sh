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
SM8450=$(grep "ro.board.platform=taro" $BUILDS)

if [ "$SD662" ] || [ "$SD665" ] || [ "$SD670" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730G" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ] || [ "$SM8450" ]; then
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
APIXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info*.xml")"
APIIXMLS="$(find /system /vendor /system_ext/product -type f -name "audio_platform_info_intcodec*.xml")"
APIEXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info_extcodec*.xml")"
APIQRDXMLS="$(find /system /vendor /system_ext /product -type f -name "audio_platform_info_qrd*.xml")"
DEVFEAS="$(find /system /vendor /system_ext /product -type f -name "$DEVICE.xml")"; 
IOPOLICYS="$(find /system /vendor /system_ext /product -type f -name "audio_io_policy.conf")"
OUTPUTPOLICYS="$(find /system /vendor /system_ext /product -type f -name "audio_output_policy.conf")"
AUDIOPOLICYS="$(find /system /vendor /system_ext /product -type f -name "audio_policy_configuration.xml")"
SNDTRGS="$(find /system /vendor /system_ext /product -type f -name "*sound_trigger_mixer_paths*.xml")"
MCODECS="$(find /system /vendor /system_ext /product -type f -name "media_codecs_google_audio.xml" -o -name "media_codecs_vendor_audio.xml" -o -name "media_codecs_c2_audio.xml")"

VNDK=$(find /system/lib /vendor/lib -type d -iname "*vndk*")
VNDK64=$(find /system/lib64 /vendor/lib64 -type d -iname "*vndk*")
VNDKQ=$(find /system/lib /vendor/lib -type d -iname "vndk*-Q")

SETTINGS=$MODPATH/settings.nls
bitaddon=false

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

mkdir -p $MODPATH/tools
cp_ch $MODPATH/common/addon/External-Tools/tools/$ARCH32/* $MODPATH/tools/


    ui_print " "
	ui_print " - Configurate me, pls >.< - "
	ui_print " "

	ui_print "***************************************************"
	ui_print "* [1/15]                                          *"
	ui_print "*                                                 *"
	ui_print "*            • Select volumes steps •             *"
	ui_print "*       Lower value - faster volume control       *"
	ui_print "*_________________________________________________*"
	ui_print "*     NOTE: [VOL+] - select, [VOL-] - confirm     *"
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

	done

	case $VOLSTEPS in
	1) VOLSTEPSINT=0;;
	2) VOLSTEPSINT=30;;
	3) VOLSTEPSINT=50;;
	4) VOLSTEPSINT=100;
	esac

        ui_print " "
	ui_print "***************************************************"
	ui_print "* [2/15]                                          *"
	ui_print "*                                                 *"
	ui_print "*          • Select volumes for Media •           *"
	ui_print "*      Lower numerical value - lower volume       *"
	ui_print "*_________________________________________________*"
	ui_print "*   NOTE: [VOL+] - select, [VOL-] - confirm       *"
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
	ui_print "* [3/15]                                          *"
	ui_print "*                                                 *"
	ui_print "*        • Select volumes for microphones •       *"
	ui_print "*       Lower numerical value - lower volume      *"
    ui_print "*_________________________________________________*"
	ui_print "*      NOTE: [VOL+] - select, [VOL-] - confirm    *"
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

	ui_print " "
    ui_print "***************************************************"
	ui_print "* [4/15]                                          *"
	ui_print "*                                                 *"
	ui_print "*            • Select audio format •              *"
	ui_print "*                  ATTENTION!                     *"
	ui_print "*     If your device does not support Hi-Fi,      *"
	ui_print "*       we strongly recommend that you do         *"
	ui_print "*         not set it higher than 24-bit.          *"
	ui_print "*_________________________________________________*"
	ui_print "*     NOTE: [VOL+] - select, [VOL-] - confirm     *"
	ui_print "***************************************************"
	sleep 1
	BITNES=1
	ui_print " "
	ui_print "   1. Skip (No changes will be made)"
	ui_print "   2. 16-bit"
	ui_print "   3. 24-bit"
	ui_print "   4. 32-bit"
	ui_print "   5. float"
	ui_print " "
	ui_print "      Selected: "
	while true; do
	ui_print "      $BITNES"
	if $VKSEL; then
		BITNES=$((BITNES + 1))
	else
		break
	fi
		
	if [ $BITNES -gt 5 ]; then
		BITNES=1
	fi

      STEP4=true
	  sed -i 's/STEP4=false/STEP4=true/g' $SETTINGS

	done

	case $BITNES in
	1) BITNESINT=0;;
	2) BITNESINT=16;;
	3) BITNESINT=24;;
	4) BITNESINT=32;;
	5) BITNESINT=float;
	esac
        
    ui_print " "
    ui_print "***************************************************"
	ui_print "* [5/15]                                          *"
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
	ui_print "*    NOTE: [VOL+] - select, [VOL-] - confirm      *"
	ui_print "***************************************************"
	sleep 1
	SAMPLERATE=1
	ui_print " "
	ui_print "   1. Skip (No changes will be made)"
	ui_print "   2. 48000 kHz "
	ui_print "   3. 96000 kHz "
	ui_print "   4. 192000 kHz "
	ui_print "   5. 384000 kHz "
	ui_print " "
	ui_print "      Selected: "
	while true; do
	ui_print "      $SAMPLERATE"
	if $VKSEL; then
		SAMPLERATE=$((SAMPLERATE + 1))
	else
		break
	fi
		
	if [ $SAMPLERATE -gt 5 ]; then
		SAMPLERATE=1
	fi

      STEP5=true
	  sed -i 's/STEP5=false/STEP5=true/g' $SETTINGS
	  
	done

	case $SAMPLERATE in
	1) SAMPLERATEINT=0;;
	2) SAMPLERATEINT=48000;;
	3) SAMPLERATEINT=96000;;
	4) SAMPLERATEINT=192000;;
	5) SAMPLERATEINT=384000;
	esac

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [6/15]                                          *"
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
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
	  STEP6=true
	  HIGHBIT=true
	  sed -i 's/STEP6=false/STEP6=true/g' $SETTINGS
	  sed -i 's/HIGHBIT=false/HIGHBIT=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [7/15]                                          *"
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
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
	  STEP7=true
      COMPANDERS=true
	  sed -i 's/STEP7=false/STEP7=true/g' $SETTINGS
	  sed -i 's/COMPANDERS=false/COMPANDERS=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [8/15]                                          *"
    ui_print "*                                                 *"
	ui_print "*     • Configurating interal audio codec •       *"
	ui_print "*                                                 *"
	ui_print "*            When you click *Install*,            *"
	ui_print "*           you will apply the changes.           *"
	ui_print "*                                                 *"
	ui_print "*           This option will configure            *"
	ui_print "*       your device's internal audio codec.       *"
	ui_print "*_________________________________________________*"
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
	ui_print " "
	if chooseport 60; then
	   STEP8=true
	   COMPANDERS=true
	   sed -i 's/STEP8=false/STEP8=true/g' $SETTINGS
	   sed -i 's/COMPANDERS=false/COMPANDERS=true/g' $SETTINGS
	fi
	 
	ui_print " "
	ui_print "***************************************************"
	ui_print "* [9/15]                                          *"
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
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
		STEP9=true
		sed -i 's/STEP9=false/STEP9=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [10/15]                                         *"
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
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
		STEP10=true
		sed -i 's/STEP10=false/STEP10=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [11/15]                                         *"
    ui_print "*                                                 *"
	ui_print "*       • Other patches in mixer_paths •          *"
	ui_print "*                                                 *"
	ui_print "*            When you click *Install*,            *"
	ui_print "*           you will apply the changes.           *"
	ui_print "*                                                 *"
	ui_print "*     Global sound changes by adjusting the       *"
	ui_print "*        internal codec of the device.            *"
	ui_print "*_________________________________________________*"
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
	  STEP11=true
	  LOLMIXER=true
	  sed -i 's/LOLMIXER=false/LOLMIXER=true/g' $SETTINGS
	  sed -i 's/STEP11=false/STEP11=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [12/15]                                         *"
    ui_print "*                                                 *"
	ui_print "*            • Tweaks in prop file •              *"
	ui_print "*                                                 *"
	ui_print "*            When you click *Install*,            *"
	ui_print "*           you will apply the changes.           *"
	ui_print "*                                                 *"
	ui_print "*    This option will change the sound quality    *"
	ui_print "*                  the most.                      *"
	ui_print "*_________________________________________________*"
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
	  STEP12=true
	  sed -i 's/STEP12=false/STEP12=true/g' $SETTINGS
	fi
	
	ui_print " "
	ui_print "***************************************************"
	ui_print "* [13/15]                                         *"
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
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
	  STEP13=true
	  sed -i 's/STEP13=false/STEP13=true/g' $SETTINGS
	fi
	
	ui_print " "
	ui_print "***************************************************"
	ui_print "* [14/15]                                         *"
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
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
	  STEP14=true
	  sed -i's/STEP14=false/STEP14=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print "***************************************************"
	ui_print "* [15/15]                                         *"
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
	ui_print "*       Vol Up = Install, Vol Down = Skip         *"
	ui_print "***************************************************"
    ui_print " "
	if chooseport 60; then
	  STEP15=true
	  sed -i 's/STEP15=false/STEP15=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print " - Processing. . . -"
	ui_print " "
	ui_print " - You can minimize Magisk and use the device normally -"
	ui_print " - and then come back here to reboot and apply the changes. -"
	ui_print " "

if [ "$STEP6" == "true" ]; then
if [ "$BITNESINT" != "0" ]; then
if [ "$SAMPLERATEINT" != "0" ]; then
for OAPIXML in ${APIXMLS}; do
APIXML="$MODPATH$(echo $OAPIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OAPIXML $APIXML
sed -i 's/\t/  /g' $APIXML

patch_xml -s $APIXML '/audio_platform_info/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIXML '/audio_platform_info/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIXML '/audio_platform_info/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
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
sed -i 's/<\/audio_platform_info>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69936\" max_rate=\"'$SAMPLERATEINT'\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69940\" max_rate=\"'$SAMPLERATEINT'\" \/> \n  <app_types> \n<\/audio_platform_info>/' $APIXML  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIXML)" ] || sed -i '/<audio_platform_info>/,/<\/audio_platform_info>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"$i\" max_rate=\"'$SAMPLERATEINT'\" \/> \n\1\2/}' $APIXML
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
sed -i 's/\t/  /g' $APIXML
patch_xml -s $APIIXML '/audio_platform_info_intcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIIXML '/audio_platform_info_intcodec/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
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
sed -i 's/<\/audio_platform_info_intcodec>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69936\" max_rate=\"'$SAMPLERATEINT'\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69940\" max_rate=\"'$SAMPLERATEINT'\" \/> \n  <app_types> \n<\/audio_platform_info_intcodec>/' $APIIXML  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info_intcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIIXML)" ] || sed -i '/<audio_platform_info_intcodec>/,/<\/audio_platform_info_intcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"$i\" max_rate=\"'$SAMPLERATEINT'\" \/> \n\1\2/}' $APIIXML
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
sed -i 's/<\/audio_platform_info_extcodec>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69936\" max_rate=\"'$SAMPLERATEINT'\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69940\" max_rate=\"'$SAMPLERATEINT'\" \/> \n  <app_types> \n<\/audio_platform_info_extcodec>/' $APIEXML  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIEXML)" ] || sed -i '/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"$i\" max_rate=\"'$SAMPLERATEINT'\" \/> \n\1\2/}' $APIEXML
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
sed -i 's/<\/audio_platform_info>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69936\" max_rate=\"'$SAMPLERATEINT'\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"69940\" max_rate=\"'$SAMPLERATEINT'\" \/> \n  <app_types> \n<\/audio_platform_info>/' $APIQRDXML  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIQRDXML)" ] || sed -i '/<audio_platform_info>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"'$BITNESINT'\" id=\"$i\" max_rate=\"'$SAMPLERATEINT'\" \/> \n\1\2/}' $APIQRDXML
done
fi
done

for OIOPOLICY in ${IOPOLICYS}; do
IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OIOPOLICY $IOPOLICY
sed -i 's/\t/  /g' $IOPOLICY

if [ "$BITNESINT" == "24" ]; then
sed -i '/^outputs/a\
  default {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 24\
    app_type 69937\
  }\
  default_24bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width 24\
    app_type 69937\
  }\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width 24\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width 24\
    app_type 69940\
  }' $IOPOLICY
fi

if [ "$BITNESINT" == "32" ]; then
sed -i '/^outputs/a\
  default {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width 32\ 
    app_type 69937\
  }\
  default_24bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69937\
  }\
  default_32bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69937\
  }\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69940\
  }\
  deep_buffer_32 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69940\
  }' $IOPOLICY
fi

if [ "$BITNESINT" == "float" ]; then
sed -i '/^outputs/a\
  default {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69937\
  }\
  default_24bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69937\
  }\
  default_float {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69937\
  }\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|96000|192000|356000|384000\ 
    bit_width float\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69940\
  }\
  deep_buffer_float {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69940\
  }' $IOPOLICY
fi
#end function
done

for OOUTPUTPOLICY in ${OUTPUTPOLICYS}; do
OUTPUTPOLICY="$MODPATH$(echo $OOUTPUTPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OOUTPUTPOLICY $OUTPUTPOLICY
sed -i 's/\t/  /g' $OUTPUTPOLICY

if [ "$BITNESINT" == "24" ]; then
sed -i '/^outputs/a\
  default {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 24\
    app_type 69937\
  }\
  default_24bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width 24\
    app_type 69937\
  }\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width 24\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width 24\
    app_type 69940\
  }' $OUTPUTPOLICY
fi

if [ "$BITNESINT" == "32" ]; then
sed -i '/^outputs/a\
  default {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width 32\ 
    app_type 69937\
  }\
  default_24bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69937\
  }\
  default_32bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69937\
  }\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69940\
  }\
  deep_buffer_32 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_32_BIT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width 32\
    app_type 69940\
  }' $OUTPUTPOLICY
fi

if [ "$BITNESINT" == "float" ]; then
sed -i '/^outputs/a\
  default {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69937\
  }\
  default_24bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69937\
  }\
  default_float {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69937\
  }\
  deep_buffer {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|96000|192000|356000|384000\ 
    bit_width float\
    app_type 69936\
  }\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69940\
  }\
  deep_buffer_float {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_FLOAT\
    sampling_rates 44100|48000|96000|192000|356000|384000\
    bit_width float\
    app_type 69940\
  }' $OUTPUTPOLICY
fi
#end function
done
#end step
fi 
fi

sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIXML
sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIIXML
sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIEXML
sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIQRDXML

bitaddonprop=true
fi

if [ "$bitaddonprop" == "true" ]; then
echo -e '#Bit fixation by NLSound Team' >> $MODPATH/system.prop
sed -i 'persist.vendor.audio_hal.dsp_bit_width_enforce_mode='$BITNESINT $PROP
sed -i 'persist.audio_hal.dsp_bit_width_enforce_mode='$BITNESINT $PROP
sed -i 'vendor.audio_hal.dsp_bit_width_enforce_mode='$BITNESINT $PROP
sed -i 'audio_hal.dsp_bit_width_enforce_mode='$BITNESINT $PROP
sed -i 'ro.vendor.audio_hal.dsp_bit_width_enforce_mode='$BITNESINT $PROP
sed -i 'ro.audio_hal.dsp_bit_width_enforce_mode='$BITNESINT >> $PROP
sed -i 'qcom.vendor.audio_hal.dsp_bit_width_enforce_mode='$BITNESINT $PROP
sed -i 'qcom.audio_hal.dsp_bit_width_enforce_mode='$BITNESINT $PROP
echo -e 'flac.sw.decoder.24bit.support=true
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
vendor.audio.dsd.sw.encoder.24bit=true'  >> $MODPATH/system.prop
fi


ui_print " "
ui_print "   ################======================== 40% done!"

if [ "$STEP8" == "true" ]; then
for OACONF in ${ACONFS}; do
ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OACONF $ACONF
sed -i 's/\t/  /g' $ACONF
patch_xml -u $ACONF '/configs/property[@name="audio.deep_buffer.media"]' "true"
patch_xml -u $ACONF '/configs/property[@name="audio.offload.video"]' "true"
patch_xml -u $ACONF '/configs/property[@name="audio.offload.disable"]' "false"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.av.streaming.offload.enable"]' "false"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.offload.track.enable"]' "true"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.offload.multiple.enabled"]' "false"
patch_xml -u $ACONF '/configs/property[@name="vendor.voice.path.for.pcm.voip"]' "true"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.alac.decoder"]' "true"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.ape.decoder"]' "true"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.mpegh.decoder"]' "true"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.flac.sw.decoder.24bit"]' "true"
patch_xml -u $ACONF '/configs/property[@name="vendor.audio.hw.aac.encoder"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="fm_power_opt"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="aac_adts_offload_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="alac_offload_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="ape_offload_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="flac_offload_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="pcm_offload_enabled_16"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="pcm_offload_enabled_24"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="qti_flac_decoder"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="vorbis_offload_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="wma_offload_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="a2dp_offload_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="anc_headset_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="audio_zoom_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="audiosphere_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="custom_stereo_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="battery_listener_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="dsm_feedback_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="ext_hw_plugin_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="ext_qdsp_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="ext_spkr_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="ext_spkr_tfa_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="hfp_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="hifi_audio_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="hwdep_cal_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="incall_music_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="keep_alive_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="kpi_optimize_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="maxx_audio_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="multi_voice_session"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="receiver_aided_stereo"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="spkr_prot_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="usb_offload_burst_mode"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="usb_offload_enabled"]' "true"
patch_xml -u $ACONF '/configs/flag[@name="usb_offload_sidetone_vol_enabled"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="use_deep_buffer_as_primary_output"]' "false"
patch_xml -u $ACONF '/configs/flag[@name="vbat_enabled"]' "false"
done
fi

if [ "$STEP9" == "true" ]; then
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

if [ "$STEP10" == "true" ]; then
for OFILE in ${AECFGS}; do
FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OFILE $FILE
sed -i 's/\t/  /g' $FILE
altmemes_confxml $FILE
memes_confxml "dirac_gef" "$MODID" "$DYNLIBPATCH\/lib\/soundfx" "libdiraceffect.so" "3799D6D1-22C5-43C3-B3EC-D664CF8D2F0D"
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

vendor.audio.use.sw.alac.decoder=true
vendor.audio.use.sw.mpegh.decoder=true
vendor.audio.use.sw.flac.decoder=true
vendor.audio.use.sw.aac.decoder=true
vendor.audio.use.sw.vorbis.decoder=true
vendor.audio.use.sw.wma.decoder=true
vendor.audio.use.sw.mp3.decoder=true
vendor.audio.use.sw.amrnb.decoder=true
vendor.audio.use.sw.amrwb.decoder=true
vendor.audio.use.sw.mhas.decoder=true
vendor.audio.use.sw.g711.alaw.decoder=true
vendor.audio.use.sw.g711.mlaw.decoder=true
vendor.audio.use.sw.opus.decoder=true
vendor.audio.use.sw.raw.decoder=true
vendor.audio.use.sw.qti.audio.decoder=true
vendor.audio.use.sw.dsp.decoder=true
vendor.audio.use.sw.dsd.decoder=true
vendor.audio.use.sw.alac.encoder=true
vendor.audio.use.sw.mpegh.encoder=true
vendor.audio.use.sw.flac.encoder=true
vendor.audio.use.sw.aac.encoder=true
vendor.audio.use.sw.vorbis.encoder=true
vendor.audio.use.sw.wma.encoder=true
vendor.audio.use.sw.mp3.encoder=true
vendor.audio.use.sw.amrnb.encoder=true
vendor.audio.use.sw.amrwb.encoder=true
vendor.audio.use.sw.mhas.encoder=true
vendor.audio.use.sw.g711.alaw.encoder=true
vendor.audio.use.sw.g711.mlaw.encoder=true
vendor.audio.use.sw.opus.encoder=true
vendor.audio.use.sw.raw.encoder=true
vendor.audio.use.sw.qti.audio.encoder=true
vendor.audio.use.sw.dsp.encoder=true
vendor.audio.use.sw.dsd.encoder=true

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
vendor.audio.feature.compress_meta_data.enable=false
vendor.audio.feature.compr_cap.enable=false
vendor.audio.feature.devicestate_listener.enable=false
vendor.audio.feature.thermal_listener.enable=false
vendor.audio.feature.power_mode.enable=true
vendor.audio.feature.hifi_audio.enable=true

ro.hardware.hifi.support=true
ro.audio.hifi=true
ro.vendor.audio.hifi=true
persist.audio.hifi=true
persist.audio.hifi.volume=90
persist.audio.hifi.int_codec=true
persist.vendor.audio.hifi.int_codec=true

audio.offload.pcm.float.enable=true
audio.offload.track.enable=true
vendor.audio.offload.track.enable=true
vendor.audio.offload.multiaac.enable=true
vendor.audio.offload.multiple.enabled=true
vendor.audio.offload.passthrough=true
vendor.audio.offload.gapless.enabled=true
vendor.audio.offload.pcm.float.enable=true

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
ro.qc.sdk.audio.ssr=true
ro.vendor.audio.sdk.ssr=true
ro.vendor.audio.recording.hd=true
ro.ril.enable.amr.wideband=1
persist.audio.lowlatency.rec=true

ro.vendor.audio.surround.headphone.only=true
ro.vendor.audio.support.sound.id=true

vendor.audio.matrix.limiter.enable=0
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.hal.output.suspend.supported=true
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.tfa9874.dsp.enabled=true
ro.audio.soundtrigger.lowpower=false
ro.vendor.audio.soundtrigger.adjconf=true
ro.vendor.audio.ns.support=true
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
persist.vendor.audio.ll_playback_bargein=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.delta.refresh=true

audio.safemedia.bypass=true
ro.audio.ignore_effects=true
ro.audio.resampler.psd.enable_at_samplerate=192000
ro.audio.resampler.psd.stopband=140
ro.audio.resampler.psd.halflength=320
ro.audio.resampler.psd.cutoff_percent=91" >> $MODPATH/system.prop
fi


ui_print " "                 
ui_print "   ########################================ 60% done!"

if [ "$STEP13" == "true" ]; then
echo -e "\n# Bluetooth

audio.effect.a2dp.enable=1
audio.hw.aac.encoder=true
audio.hw.aac.decoder=true
vendor.audio.effect.a2dp.enable=1
vendor.audio.hw.aac.encoder=true
vendor.audio.hw.aac.decoder=true
ro.vendor.audio.hw.aac.encoder=true
ro.vendor.audio.hw.aac.decoder=true
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
persist.bluetooth.disableabsvol=true
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true" >> $MODPATH/system.prop
fi

if [ "$STEP14" == "true" ]; then
for OIOPOLICY in ${IOPOLICYS}; do
IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OIOPOLICY $IOPOLICY
sed -i 's/\t/  /g' $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
done

for OUTPUTPOLICY in ${OUTPUTPOLICYS}; do
OUTPUTPOLICY="$MODPATH$(echo $OUTPUTPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OUTPUTPOLICY $OUTPUTPOLICY
sed -i 's/\t/  /g' $OUTPUTPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $OUTPUTPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $OUTPUTPOLICY
done
fi

STEP13=true
if [ "$STEP13" == "true" ]; then
for OAUDIOPOLICY in ${AUDIOPOLICYS}; do
AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OAUDIOPOLICY $AUDIOPOLICY
sed -i 's/\t/  /g' $AUDIOPOLICY
sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
done
fi

STEP14=true
if [ "$STEP14" == "true" ]; then
for OMCODECS in ${MCODECS}; do
MEDIACODECS="$MODPATH$(echo $OMCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g")"
cp_ch $ORIGDIR$OMEDCODECS $MEDIACODECS
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

if [ "$STEP15" == "true" ]; then
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="0"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="1"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="2"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="3"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="4"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="0"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="1"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="2"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="3"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="4"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="0"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="1"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="2"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="3"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="4"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="0"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="1"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="2"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="3"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="4"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="0"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="1"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="2"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="3"]' "000000000"
patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="4"]' "000000000"
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

if [ "$STEP7" == "true" ]; then
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
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=asr-mic]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc1]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc2]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=adc3]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=va-enroll-mic]/ctl[@name=HPHR_COMP Switch]' "0"
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
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=handset]/ctl[@name=HPHR_COMP Switch]' "0"
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
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=tty-headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=true-native-mode]/ctl[@name=HPHR_COMP Switch]' "0"
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
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voice-anc-fb-headphones]/ctl[@name=HPHR_COMP Switch]' "0"
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
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-on]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc2-on]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphones]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=anc-off-headphone-combo]/ctl[@name=HPHR_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP3 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP4 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP5 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP6 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP7 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP8 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP0 RX1]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP0 RX2]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP1]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP2]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=SpkrLeft COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=SpkrRight COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=WSA_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=WSA_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=RX_COMP1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=RX_COMP2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP0 RX1 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=COMP0 RX2 Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=HPHL_COMP Switch]' "0"
patch_xml -u $MIX '/mixer/path[@name=voiceanc-headphone]/ctl[@name=HPHR_COMP Switch]' "0"
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

if [ "$STEP7" == "true" ]; then
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
patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
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
ui_print "   ######################################## 100% done!"

ui_print " "
ui_print " - All done! With love, NLSound Team. - "
ui_print " "
