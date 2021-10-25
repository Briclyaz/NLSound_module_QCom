nlsound() {
case $1 in
	-pre) CONF=pre_processing; XML=preprocess;;
	-post) CONF=output_session_processing; XML=postprocess;;
esac
case $2 in
	*.conf) if [ ! "$(sed -n "/^$CONF {/,/^}/p" $2)" ]; then
		echo -e "\n$CONF {\n    $3 {\n        $4 {\n        }\n    }\n}" >> $2
	elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^    }/p}" $2)" ]; then
		sed -i "/^$CONF {/,/^}/ s/$CONF {/$CONF {\n    $3 {\n        $4 {\n        }\n    }/" $2
	elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^    }/ {/$4 {/,/}/p}}" $2)" ]; then
		sed -i "/^$CONF {/,/^}/ {/$3 {/,/^    }/ s/$3 {/$3 {\n        $4 {\n        }/}" $2
	fi;;
	*.xml) if [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/p" $2)" ]; then     
		sed -i "/<\/audio_effects_conf>/i\    <$XML>\n       <stream type=\"$3\">\n            <apply effect=\"$4\"\/>\n        <\/stream>\n    <\/$XML>" $2
	elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/p}" $2)" ]; then     
		sed -i "/^ *<$XML>/,/^ *<\/$XML>/ s/    <$XML>/    <$XML>\n        <stream type=\"$3\">\n            <apply effect=\"$4\"\/>\n        <\/stream>/" $2
	elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ {/^ *<apply effect=\"$4\"\/>/p}}" $2)" ]; then
		sed -i "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ s/<stream type=\"$3\">/<stream type=\"$3\">\n            <apply effect=\"$4\"\/>/}" $2
	fi;;
esac
}

patch_xml() {
  local Name0=$(echo "$3" | sed -r "s|^.*/.*\[@(.*)=\".*\".*$|\1|")
  local Value0=$(echo "$3" | sed -r "s|^.*/.*\[@.*=\"(.*)\".*$|\1|")
  [ "$(echo "$4" | grep '=')" ] && Name1=$(echo "$4" | sed "s|=.*||") || local Name1="value"
  local Value1=$(echo "$4" | sed "s|.*=||")
  case $1 in
  "-s"|"-u"|"-i")
    local SNP=$(echo "$3" | sed -r "s|(^.*/.*)\[@.*=\".*\".*$|\1|")
    local NP=$(dirname "$SNP")
    local SN=$(basename "$SNP")
    if [ "$5" ]; then
      [ "$(echo "$5" | grep '=')" ] && local Name2=$(echo "$5" | sed "s|=.*||") || local Name2="value"
      local Value2=$(echo "$5" | sed "s|.*=||")
    fi
    if [ "$6" ]; then
      [ "$(echo "$6" | grep '=')" ] && local Name3=$(echo "$6" | sed "s|=.*||") || local Name3="value"
      local Value3=$(echo "$6" | sed "s|.*=||")
    fi
    if [ "$7" ]; then
      [ "$(echo "$7" | grep '=')" ] && local Name4=$(echo "$7" | sed "s|=.*||") || local Name4="value"
      local Value4=$(echo "$7" | sed "s|.*=||")
    fi
  ;;
  esac
  case "$1" in
    "-d") xmlstarlet ed -L -d "$3" "$2";;
    "-u") xmlstarlet ed -L -u "$3/@$Name1" -v "$Value1" "$2";;
    "-s")
      if [ "$(xmlstarlet sel -t -m "$3" -c . "$2")" ]; then
        xmlstarlet ed -L -u "$3/@$Name1" -v "$Value1" "$2"
      else
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      fi;;
    "-i")
      if [ "$(xmlstarlet sel -t -m "$3[@$Name1=\"$Value1\"]" -c . "$2")" ]; then
        xmlstarlet ed -L -d "$3[@$Name1=\"$Value1\"]" "$2"
      fi
      if [ -z "$Value3" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      elif [ "$Value4" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -i "$SNP-$MODID" -t attr -n "$Name3" -v "$Value3" \
        -i "$SNP-$MODID" -t attr -n "$Name4" -v "$Value4" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      elif [ "$Value3" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -i "$SNP-$MODID" -t attr -n "$Name3" -v "$Value3" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      fi
      ;;
  esac
}

#author - Lord_Of_The_Lost@Telegram
meme_effects() {
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
memes_confxml() {
case $FILE in
	*.conf) sed -i "/$1 {/,/}/d" $FILE
		sed -i "/$2 {/,/}/d" $FILE
		sed -i "s/^effects {/effects {\n  $1 {\n    library $2\n    uuid $5\n  }/g" $FILE
		sed -i "s/^libraries {/libraries {\n  $2 {\n    path $3\/$4\n  }/g" $FILE;;
	*.xml) sed -i "/$1/d" $FILE
		sed -i "/$2/d" $FILE
		sed -i "/<libraries>/ a\        <library name=\"$2\" path=\"$4\"\/>" $FILE
	sed -i "/<effects>/ a\        <effect name=\"$1\" library=\"$2\" uuid=\"$5\"\/>" $FILE;;
esac
}

#author - Lord_Of_The_Lost@Telegram
SET_PERM_RM() {
	SET_PERM_R $MODPATH/$MODID 0 0 0755 0644; [ -d $MODPATH$MIPSB ] && chmod -R 777 $MODPATH$MIPSB; [ -d $MODPATH$MIPSXB ] && chmod -R 777 $MODPATH$MIPSXB; case $1 in -msgdi) UIP "$MSGDI";; esac
}

#author - Lord_Of_The_Lost@Telegram
MOVERPATH() {
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system_root/system ]; then
		mkdir -p $MODPATH/$MODID/system; cp -rf $MODPATH/$MODID/system_root/system/* $MODPATH/$MODID/system; rm -rf $MODPATH/$MODID/system_root
	fi
if [ -d $MODPATH/$MODID/vendor ]; then
		mkdir -p $MODPATH$MIPSV; cp -rf $MODPATH/$MODID/vendor/* $MODPATH$MIPSV; rm -rf $MODPATH/$MODID/vendor
	fi
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system/system ]; then
		mkdir -p $MODPATH/$MODID/system; cp -rf $MODPATH/$MODID/system/system/* $MODPATH/$MODID/system; rm -rf $MODPATH/$MODID/system/system
	fi
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system_root/system/system_ext ]; then
		mkdir -p $MODPATH/$MODID/system/system_ext; cp -rf $MODPATH/$MODID/system_root/system/system_ext/* $MODPATH/$MODID/system/system_ext; rm -rf $MODPATH/$MODID/system_root
	fi
}

[ -f /system/vendor/build.prop ] && BUILDS="/system/build.prop /system/vendor/build.prop" || BUILDS="/system/build.prop"
SD625=$(grep "ro.board.platform=msm8953" $BUILDS)
SD660=$(grep "ro.board.platform=sdm660" $BUILDS)
SD662=$(grep "ro.board.platform=bengal" $BUILDS)
SD665=$(grep "ro.board.platform=trinket" $BUILDS)
SD690=$(grep "ro.board.platform=lito" $BUILDS)
SD710=$(grep "ro.board.platform=sdm710" $BUILDS)
SD720G=$(grep "ro.board.platform=atoll" $BUILDS)
SD730=$(grep "ro.board.platform=sm6150" $BUILDS)
SD765G=$(grep "ro.board.platform=lito" $BUILDS)
SD820=$(grep "ro.board.platform=msm8996" $BUILDS)
SD835=$(grep "ro.board.platform=msm8998" $BUILDS)
SD845=$(grep "ro.board.platform=sdm845" $BUILDS)
SD855=$(grep "ro.board.platform=msmnile" $BUILDS)
SD865=$(grep "ro.board.platform=kona" $BUILDS)
SD888=$(grep "ro.board.platform=lahaina" $BUILDS)

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

DEVICE=$(getprop ro.product.system.model)

ACONFS="$(find /system /vendor -type f -name "audio_configs*.xml")"
APINF="$(find /system /vendor -type f -name "audio_platform_info*.xml")"
CFGS="$(find /system /vendor -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
MPATHS="$(find /system /vendor -type f -name "mixer_paths*.xml")"
#MCGAX="$(find /system /vendor -type f -name "*media_codecs_google_c2_audio*.xml" -o -name "*media_codecs_google_audio*.xml" -o -name "*media_codecs_vendor_audio*.xml")"
APIXML="/vendor/etc/audio_platform_info.xml"
APIIXML="/vendor/etc/audio_platform_info_intcodec.xml"
APIEXML="/vendor/etc/audio_platform_info_extcodec.xml"
DEVFEA="/vendor/etc/device_features/*.xml"; DEVFEAA="/system/etc/device_features/*.xml"
IOPOLICY="$(find /system /vendor -type f -name "audio_io_policy.conf")"
AUDIOPOLICY="$(find /system /vendor -type f -name "audio_policy_configuration.xml")"

NEWdirac=$MODPATH/common/NLSound/newdirac

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

ALL=false

for OMIX in $MPATHS; do
	MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $MIX`
	cp -f $MAGISKMIRROR$OMIX $MIX
	sed -i 's/\t/  /g' $MIX
done

for OACONF in $ACONFS; do
	ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $ACONF`
	cp -f $MAGISKMIRROR$OACONF $ACONF
	sed -i 's/\t/  /g' $ACONF
done

deep_buffer() {
	echo -e '\naudio.deep_buffer.media=false\nvendor.audio.deep_buffer.media=false\nqc.audio.deep_buffer.media=false\nro.qc.audio.deep_buffer.media=false\npersist.vendor.audio.deep_buffer.media=false' >> $MODPATH/system.prop
		for OACONF in $ACONFS; do
		ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g")"
			patch_xml -u $ACONF '/configs/property[@name="audio.deep_buffer.media"]' "false"
		done
}
	
patch_volumes() {
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -u $MIX '/mixer/ctl[@name="RX0 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX1 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX2 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX3 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX4 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX5 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX6 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX7 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX8 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX0 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX1 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX2 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX3 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX4 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX5 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX6 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX7 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX8 Mix Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX0 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX1 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX2 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX3 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX4 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX5 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX6 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX7 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX8 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX0 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX1 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX2 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX3 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX4 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX5 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX6 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX7 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX8 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX0 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_RX1 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX0 Digital Volume"]' "92"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_RX1 Digital Volume"]' "92"
		echo -e '\nro.config.media_vol_steps=30' >> $MODPATH/system.prop
	done
}

patch_microphone() {
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC1 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC2 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC3 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC4 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC0 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC1 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC2 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC3 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC4 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC5 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC6 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC7 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC8 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC0 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC1 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC2 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC3 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC4 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC5 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC6 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC7 Volume"]' "94"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC8 Volume"]' "94"
		patch_xml -s $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S16_LE"
		patch_xml -s $MIX '/mixer/ctl[@name="EC Reference SampleRate"]' "48000"
		patch_xml -u $MIX '/mixer/ctl[@name="adc1"]/ctl[@name="ADC1 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="adc2"]/ctl[@name="ADC2 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="adc3"]/ctl[@name="ADC3 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="asr-mic"]/ctl[@name="ADC1 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="asr-mic"]/ctl[@name="ADC3 Volume"]' "12"
		patch_xml -u $MIX '/mixer/speaker-mic/adc1/ctl[@name="IIR1 INP1 MUX"]' "ZERO"
		patch_xml -u $MIX '/mixer/handset-mic/adc1/ctl[@name="IIR1 INP1 MUX"]' "ZERO"
		patch_xml -u $MIX '/mixer/secondary-mic/adc3/ctl[@name="IIR1 INP1 MUX"]' "ZERO"
		patch_xml -u $MIX '/mixer/headset-mic/adc2/ctl[@name="IIR1 INP1 MUX"]' "ZERO"
		patch_xml -u $MIX '/mixer/dmic-endfire/handset-dmic-endfire/ctl[@name="IIR1 INP1 MUX"]' "ZERO"
		patch_xml -u $MIX '/mixer/dmic-endfire-liquid/handset-dmic-endfire/ctl[@name="IIR1 INP1 MUX"]' "ZERO"
		patch_xml -u $MIX '/mixer/dmic-broadside/speaker-dmic-broadside/ctl[@name="IIR1 INP1 MUX"]' "ZERO"
	done
}

iir_patches() {
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
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
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "headphones"
		patch_xml -u $MIX '/mixer/ctl[@name="RX1 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer/ctl[@name="RX2 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer/ctl[@name="RX3 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer/ctl[@name="TX1 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer/ctl[@name="TX2 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer/ctl[@name="TX3 HPF Switch"]' "On"
	done
}

audio_platform_info_int() {
	for OAPLI in $APINF; do
	APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $APLI`
	cp -f $MAGISKMIRROR$OAPLI $APLI
	sed -i 's/\t/  /g' $APLI
		patch_xml -s $APLI '/audio_platform_info_intcodec/config_params/param[@key="native_audio_mode"]' 'src'
		patch_xml -s $APLI '/audio_platform_info_intcodec/config_params/param[@key="hifi_filter"]' 'true'
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "24"	 
		patch_xml -u $APLI '/audio_platform_info_intcodec/app_types/app[@mode="default"]' 'bit_width=24'
		patch_xml -u $APLI '/audio_platform_info_intcodec/app_types/app[@mode="default"]' 'max_rate=192000'
	if [ ! "$(grep '<app_types>' $APLI)" ]; then
		sed -i "s/<\/audio_platform_info_intcodec>/  <app_types> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info_intcodec>/" $APLI		  
	else
	for i in 69936 69940; do
		[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APLI)" ] || sed -i "/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}" $APLI			
    done
	fi
done
}

audio_platform_info_ext() {
	for OAPLI in $APINF; do
	APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $APLI`
	cp -f $MAGISKMIRROR$OAPLI $APLI
	sed -i 's/\t/  /g' $APLI
		patch_xml -s $APLI '/audio_platform_info_extcodec/config_params/param[@key="native_audio_mode"]' 'src'
		patch_xml -s $APLI '/audio_platform_info_extcodec/config_params/param[@key="hifi_filter"]' 'true'
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "24"	 
		patch_xml -u $APLI '/audio_platform_info_extcodec/app_types/app[@mode="default"]' 'bit_width=24'
		patch_xml -u $APLI '/audio_platform_info_extcodec/app_types/app[@mode="default"]' 'max_rate=192000'
	if [ ! "$(grep '<app_types>' $APLI)" ]; then
		sed -i "s/<\/audio_platform_info_extcodec>/  <app_types> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info_extcodec>/" $APLI		  
	else
	for i in 69936 69940; do
		[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APLI)" ] || sed -i "/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}" $APLI			
    done
	fi
done
}

audio_platform_info() {
	for OAPLI in $APINF; do
	APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $APLI`
	cp -f $MAGISKMIRROR$OAPLI $APLI
	sed -i 's/\t/  /g' $APLI
		patch_xml -s $APLI '/audio_platform_info/config_params/param[@key="native_audio_mode"]' 'src'
		patch_xml -s $APLI '/audio_platform_info/config_params/param[@key="hifi_filter"]' 'true'
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "24"	 
		patch_xml -u $APLI '/audio_platform_info/app_types/app[@mode="default"]' 'bit_width=24'
		patch_xml -u $APLI '/audio_platform_info/app_types/app[@mode="default"]' 'max_rate=192000'
	if [ ! "$(grep '<app_types>' $APLI)" ]; then
		sed -i "s/<\/audio_platform_info>/  <app_types> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info>/" $APLI		  
	else
	for i in 69936 69940; do
		[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APLI)" ] || sed -i "/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}" $APLI			
    done
	fi
done
}

companders() {
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="SpkrRight COMP Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="RX_COMP2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX2 Switch"]' 0	
		
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0	
		
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 16 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 15 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 29 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 30 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 31 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 32 Volume"]' 0
	done
}

audio_codec() {
if find $SYSTEM $VENDOR -type f -name "audio_configs*.xml" >/dev/null; then
	for OACONF in $ACONFS; do
	ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -u $ACONF '/configs/property[@name="audio.offload.disable"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="audio.offload.min.duration.secs"]' "30"
		patch_xml -u $ACONF '/configs/property[@name="persist.vendor.audio.sva.conc.enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="persist.vendor.audio.va_concurrency_enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.av.streaming.offload.enable"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.offload.track.enable"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.offload.multiple.enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.rec.playback.conc.disabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.conc.fallbackpath"]' ""
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.dsd.playback.conc.disabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.path.for.pcm.voip"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.playback.conc.disabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.record.conc.disabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.voip.conc.disabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="audio_extn_formats_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="audio_extn_hdmi_spk_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="use_xml_audio_policy_conf"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="voice_concurrency"]' "false "
		patch_xml -u $ACONF '/configs/property[@name="afe_proxy_enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="compress_voip_enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="fm_power_opt"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="record_play_concurrency"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.alac.decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.ape.decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.mpegh.decoder"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.flac.sw.decoder.24bit"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.hw.aac.encoder"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="aac_adts_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="alac_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="ape_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="flac_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="pcm_offload_enabled_16"]' "false "
		patch_xml -u $ACONF '/configs/property[@name="pcm_offload_enabled_24"]' "false "
		patch_xml -u $ACONF '/configs/property[@name="qti_flac_decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vorbis_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="wma_offload_enabled"]' "true"
	done
fi
}

device_features_system() {
	for ODEVFEA in $DEVFEA; do 
	DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $DEVFEA`
	cp -f $MAGISKMIRROR$ODEVFEA $DEVFEA
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
}

device_features_vendor() {
	for ODEVFEAA in $DEVFEAA; do 
	DEVFEAA="$MODPATH$(echo $ODEVFEAA | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $DEVFEAA`
	cp -f $MAGISKMIRROR$ODEVFEAA $DEVFEAA
	sed -i 's/\t/  /g' $DEVFEAA
		patch_xml -s $DEVFEAA '/features/bool[@name="support_a2dp_latency"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_48000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_96000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_192000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_low_latency"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_mid_latency"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_high_latency"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_interview_record_param"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_voip_record"]' "true"
		patch_xml -s $DEVFEAA '/features/integer[@name="support_inner_record"]' "1"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_hifi"]' "true"
	done
}

dirac() {
	for OFILE in $CFGS; do
	FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $FILE`
	cp -f $MAGISKMIRROR$OFILE $FILE
		meme_effects $FILE
		memes_confxml "dirac_gef" "$MODID" "\/system\/lib\/soundfx" "libdiraceffect.so" "3799d6d1-22c5-43c3-b3ec-d664cf8d2f0d"
		nlsound -post "$FILE" "music" "dirac_gef"
	done
	mkdir -p $MODPATH/system/vendor/etc/dirac $MODPATH/system/vendor/lib/rfsa/adsp $MODPATH/system/vendor/lib/soundfx
	cp -f $NEWdirac/diracvdd.bin $MODPATH/system/vendor/etc/
	cp -f $NEWdirac/interfacedb $MODPATH/system/vendor/etc/dirac
	cp -f $NEWdirac/dirac_resource.dar $MODPATH/system/vendor/lib/rfsa/adsp
	cp -f $NEWdirac/dirac.so $MODPATH/system/vendor/lib/rfsa/adsp
	cp -f $NEWdirac/libdirac-capiv2.so $MODPATH/system/vendor/lib/rfsa/adsp
	cp -f $NEWdirac/libdiraceffect.so $MODPATH/system/vendor/lib/soundfx
echo -e "\n# Patch dirac
persist.dirac.acs.controller=gef
persist.dirac.gef.oppo.syss=true
persist.dirac.config=64
persist.dirac.gef.exs.did=50,50
persist.dirac.gef.ext.did=450,450,450,450
persist.dirac.gef.ins.did=0,0,0
persist.dirac.gef.int.did=0,0,0,0
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
persist.dirac.acs.ignore_error=1" >> $MODPATH/system.prop
} 

mixer() {
	for OMIX in $MPATHS; do
	MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		if $HIFI; then
			patch_xml -u $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="headphones"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
			patch_xml -u $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_3LE"
		else
            patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "HD2"
			patch_xml -u $MIX '/mixer/ctl[@name="RX HPH HD2 Mode"]' "On"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX Format"]' "S24_LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX Format"]' "S24_LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="headphones"]/ctl[@name="SLIM_5_RX Format"]' "S24_LE"
			patch_xml -u $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		fi
		if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
			patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 ClassD Edge"]' "7"
			patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 Volume"]' "30"
			echo -e '\nro.sound.alsa=TAS2557' >> $MODPATH/system.prop
		fi
			patch_xml -s $MIX '/mixer/ctl[@name="headphones]/ctl[@name="PowerCtrl"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="TFA Profile"]' "speaker"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT1 MIX3 DSD HPHL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT2 MIX3 DSD HPHR Switch"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="HiFi Function"]' "On"
			patch_xml -s $MIX '/mixer/ctl[@name="HiFi Filter"]' "6"
			patch_xml -u $MIX '/mixer/ctl[@name="HPHL"]' "Switch"
			patch_xml -u $MIX '/mixer/ctl[@name="HPHR"]' "Switch"
			patch_xml -s $MIX '/mixer/ctl[@name="RX1 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="RX2 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="RX3 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="TX1 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="TX2 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="TX3 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -u $MIX '/mixer/ctl[@name="Voice Sidetone Enable"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="Set Custom Stereo OnOff"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="MSM ASphere Set Param"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="HPH Idle Detect"]' "ON"
			patch_xml -s $MIX '/mixer/ctl[@name="ASM Bit Width"]' "24"
			patch_xml -s $MIX '/mixer/ctl[@name="HPHL_RDAC Switch"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="HPHR_RDAC Switch"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="AUX_RDAC Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="Adsp Working Mode"]' "full"
			patch_xml -s $MIX '/mixer/ctl[@name="Adsp Working Mode"]' "full"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT1 SEC MIX HPHL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT2 SEC MIX HPHR Switch"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="RX INT3 SEC MIX LO1 Switch"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="RX INT4 SEC MIX LO2 Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT0 DEM MUX"]' "CLSH_DSM_OUT"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT1 DEM MUX"]' "CLSH_DSM_OUT"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT2 DEM MUX"]' "CLSH_DSM_OUT"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT3 DEM MUX"]' "CLSH_DSM_OUT"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT4 DEM MUX"]' "CLSH_DSM_OUT"
			patch_xml -u $MIX '/mixer/ctl[@name="HPHL"]' "Switch"
			patch_xml -u $MIX '/mixer/ctl[@name="HPHR"]' "Switch"
			patch_xml -s $MIX '/mixer/ctl[@name="TFA987X_ALGO_STATUS"]' "ENABLE"
			patch_xml -s $MIX '/mixer/ctl[@name="TFA987X_TX_ENABLE"]' "ENABLE"
			patch_xml -s $MIX '/mixer/ctl[@name="Amp DSP Enable"]' "1" 
			patch_xml -s $MIX '/mixer/ctl[@name="BDE AMP Enable"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="Amp Volume Location"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="A2DP_SLIM7_UL_HL Switch"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM7_RX_DL_HL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="HFP_SLIM7_UL_HL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="HFP_PRI_AUX_UL_HL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="HFP_AUX_UL_HL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="HFP_INT_UL_HL Switch"]' "1"
			patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SLIM_2_RX Format"]' "DSD_DOP"
			patch_xml -s $MIX '/mixer/ctl[@name="Ext Spk Boost"]' "ENABLE"
			patch_xml -s $MIX '/mixer/ctl[@name="Boost Option"]' "BOOST_ALWAYS"
			patch_xml -s $MIX '/mixer/ctl[@name="PowerCtrl"]' "0"
	done
	
	#for MCP in $MC; do
	#MC="$MODPATH$(echo $MCP | sed "s|^/vendor|/system/vendor|g")"
	#mkdir -p `dirname $MC`
	#cp -f $MAGISKMIRROR$MCP $MC
	#case $MC in
	#	*media_codecs_google_audio*.xml) sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/aac.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC;;
	#	*media_codecs_google_c2_audio*.xml) sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC;;
	#	*media_codecs_vendor_audio*.xml) sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC;;
	#esac
#done
}

mixer_lite() {
	for OMIX in $MPATHS; do
	MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		if $HIFI; then
			patch_xml -u $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -u $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="headphones"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
			patch_xml -u $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_3LE"
		else
			patch_xml -u $MIX '/mixer/ctl[@name="RX HPH HD2 Mode"]' "On"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX Format"]' "S24_LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX Format"]' "S24_LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="headphones"]/ctl[@name="SLIM_5_RX Format"]' "S24_LE"
			patch_xml -u $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		fi
		if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
			patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 ClassD Edge"]' "7"
			patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 Volume"]' "30"
			echo -e '\nro.sound.alsa=TAS2557' >> $MODPATH/system.prop
		fi
			patch_xml -s $MIX '/mixer/ctl[@name="headphones]/ctl[@name="PowerCtrl"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="TFA Profile"]' "speaker"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT1 MIX3 DSD HPHL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="RX INT2 MIX3 DSD HPHR Switch"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="HiFi Function"]' "On"
			patch_xml -s $MIX '/mixer/ctl[@name="HiFi Filter"]' "6"
			patch_xml -u $MIX '/mixer/ctl[@name="HPHL"]' "Switch"
			patch_xml -u $MIX '/mixer/ctl[@name="HPHR"]' "Switch"
			#ADDED 12.04.2021 by NLSound Team
			patch_xml -s $MIX '/mixer/ctl[@name="RX1 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="RX2 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="RX3 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="TX1 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="TX2 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -s $MIX '/mixer/ctl[@name="TX3 HPF cut off"]' "MIN_3DB_4Hz"
			patch_xml -u $MIX '/mixer/ctl[@name="TFA987X_ALGO_STATUS"]' "ENABLE"
			patch_xml -u $MIX '/mixer/ctl[@name="TFA987X_TX_ENABLE"]' "ENABLE"
			patch_xml -s $MIX '/mixer/ctl[@name="Amp DSP Enable"]' "1" 
			patch_xml -s $MIX '/mixer/ctl[@name="Amp Volume Location"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="BDE AMP Enable"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="A2DP_SLIM7_UL_HL Switch"]' "1"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX Channels"]' "Two"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM7_RX_DL_HL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="HFP_SLIM7_UL_HL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="HFP_PRI_AUX_UL_HL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="HFP_AUX_UL_HL Switch"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="HFP_INT_UL_HL Switch"]' "1"
	done

	#for MCP in $MC; do
	#MC="$MODPATH$(echo $MCP | sed "s|^/vendor|/system/vendor|g")"
	#mkdir -p `dirname $MC`
	#cp -f $MAGISKMIRROR$MCP $MC
	#case $MC in
	#	*media_codecs_google_audio*.xml) sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/aac.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC;;
	#	*media_codecs_google_c2_audio*.xml) sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC;;
	#	*media_codecs_vendor_audio*.xml) sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC
	#		sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $MC;;
	#esac
#done
}

io_policy(){
	for OIOPOLICY in $IOPOLICY; do
	IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $IOPOLICY`
	cp -f $MAGISKMIRROR$OIOPOLICY $IOPOLICY
	sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
	sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
	done
	}

audio_policy() {
	for OAUDIOPOLICY in $AUDIOPOLICY; do
	AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $AUDIOPOLICY`
	cp -f $MAGISKMIRROR$OAUDIOPOLICY $AUDIOPOLICY
	#sed -i 's/\t/  /g' $AUDIOPOLICY
	sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
	done
}

clear_screen() {
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
}

prop() {
echo -e "\n#
persist.vendor.audio.spv4.enable=true
persist.vendor.audio.avs.afe_api_version=9

ro.mediacodec.min_sample_rate=7350
ro.mediacodec.max_sample_rate=2822400
vendor.audio.flac.sw.decoder.24bit=true
vendor.audio.aac.sw.decoder.24bit=true
vendor.audio.use.sw.alac.decoder=true
vendor.audio.flac.sw.encoder.24bit=true
vendor.audio.aac.sw.encoder.24bit=true
vendor.audio.use.sw.ape.decoder=true
vendor.audio.vorbis.complexity.default=8
vendor.audio.vorbis.quality=100
vendor.audio.aac.complexity.default=8
vendor.audio.aac.quality=100
vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
qc.tunnel.audio.encode=true
audio.decoder_override_check=true
mpq.audio.decode=true
audio.nat.codec.enabled=1
use.non-omx.mp3.decoder=false
use.non-omx.aac.decoder=false
use.non-omx.flac.decoder=false

media.stagefright.enable-player=true
media.stagefright.enable-http=true
media.stagefright.enable-aac=true
media.stagefright.enable-qcp=true
media.stagefright.enable-fma2dp=true
media.stagefright.enable-scan=true
media.stagefright.audio.sink=128
media.stagefright.thumbnail.prefer_hw_codecs=true
mmp.enable.3g2=true
media.aac_51_output_enabled=true
mm.enable.smoothstreaming=true
vendor.audio.parser.ip.buffer.size=262144
vendor.mm.enable.qcom_parser=63963135
persist.mm.enable.prefetch=true

av.offload.enable=true
vendor.av.offload.enable=true
qc.av.offload.enable=true
audio.offload.buffer.size.kb=32
vendor.audio.offload.buffer.size.kb=32

lpa.decode=false
lpa30.decode=false
lpa.use-stagefright=false
lpa.releaselock=false

af.thread.throttle=0
af.fast.track.multiplier=2
ro.af.client_heap_size_kbyte=7168

vendor.audio_hal.in_period_size=144
vendor.audio_hal.period_multiplier=3 
vendor.audio.hal.output.suspend.supported=true

audio.playback.mch.downsample=false
ro.vendor.audio.playbackScene=true
vendor.audio.playback.dsp.pathdelay=0
vendor.audio.playback.mch.downsample=false
persist.vendor.audio.playback.mch.downsample=false

vendor.audio.feature.external_dsp.enable=true
vendor.audio.feature.external_speaker.enable=true
vendor.audio.feature.external_speaker_tfa.enable=true
vendor.audio.feature.ext_hw_plugin=true
vendor.audio.feature.ras.enable=true
vendor.audio.feature.afe_proxy.enable=true
vendor.audio.feature.src_trkn.enable=true
vendor.audio.feature.spkr_prot.enable=true
vendor.audio.feature.kpi_optimize.enable=true
vendor.audio.feature.power_mode.enable=true 
vendor.audio.feature.compress_meta_data.enable=false
vendor.audio.feature.compr_cap.enable=false
vendor.audio.feature.ssrec.enable=true
vendor.audio.feature.dynamic_ecns.enable=true
vendor.audio.feature.concurrent_capture.enable=true
vendor.audio.feature.devicestate_listener.enable=false
vendor.audio.feature.thermal_listener.enable=false
vendor.audio.feature.hifi_audio.enable=true

ro.hardware.hifi.support=true
ro.audio.hifi=true
ro.vendor.audio.hifi=true
persist.audio.hifi=true
persist.audio.hifi.volume=72
persist.audio.hifi.int_codec=true
persist.vendor.audio.hifi=true
persist.vendor.audio.hifi.int_codec=true

effect.reverb.pcm=1
vendor.audio.safx.pbe.enabled=true
vendor.audio.soundfx.usb=false
vendor.audio.keep_alive.disabled=false
vendor.audio.pp.asphere.enabled=true
ro.vendor.audio.3d.audio.support=true
ro.vendor.audio.sfx.speaker=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.audiovisual=false
ro.vendor.audio.sfx.independentequalizer=false
ro.vendor.audio.surround.support=true
ro.vendor.audio.scenario.support=true
ro.vendor.audio.vocal.support=true
ro.vendor.audio.voice.change.support=true
ro.vendor.audio.voice.change.youme.support=true
persist.vendor.audio.ambisonic.capture=true
persist.vendor.audio.ambisonic.auto.profile=true
persist.vendor.audio.misound.disable=true

vendor.audio.hdr.record.enable=true
vendor.audio.3daudio.record.enable=true
ro.vendor.audio.sdk.ssr=false
ro.vendor.audio.recording.hd=true
ro.ril.enable.amr.wideband=1
persist.audio.lowlatency.rec=true

ro.vendor.audio.game.mode=true
ro.vendor.audio.game.vibrate=true
ro.audio.soundtrigger.lowpower=false
vendor.power.pasr.enabled=true
vendor.audio.matrix.limiter.enable=0
vendor.audio.enable.mirrorlink=false
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.spkr_prot.tx.sampling_rate=48000
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.tfa9874.dsp.enabled=true
ro.vendor.audio.multiroute=true
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
persist.vendor.audio.ha_proxy.enabled=true
persist.vendor.audio.ll_playback_bargein=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.hw.binder.size_kbyte=1024
persist.vendor.audio.format.24bit=true
persist.vendor.audio.delta.refresh=true" >> $MODPATH/system.prop
}

improve_bluetooth() {
echo -e "\n# Bluetooth

audio.effect.a2dp.enable=1
vendor.audio.effect.a2dp.enable=1
vendor.bt.pts.pbap=true
ro.bluetooth.emb_wp_mode=false
ro.bluetooth.wipower=false 
ro.vendor.bluetooth.wipower=false
persist.service.btui.use_aptx=1
persist.bt.enableAptXHD=true
persist.bt.a2dp.aptx_disable=false
persist.bt.a2dp.aptx_hd_disable=false
persist.bt.a2dp.aac_disable=false
persist.bt.sbc_hd_enabled=1
persist.vendor.btstack.enable.splita2dp=true
persist.vendor.btstack.connect.peer_earbud=true
persist.vendor.btstack.enable.twsplussho=true
persist.vendor.btstack.enable.swb=true
persist.vendor.btstack.enable.swbpm=true
persist.vendor.btstack.enable.lpa=false
persist.vendor.btstack.avrcp.pos_time=1000
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.a2dp.addr_check_enabled_for_aac=true
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
persist.vendor.qcom.bluetooth.scram.enabled=false
persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true
persist.vendor.qcom.bluetooth.enable.splita2dp=true 
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
persist.vendor.qcom.bluetooth.a2dp_mcast_test.enabled=false
persist.vendor.qcom.bluetooth.aptxadaptiver2_1_support=true
persist.vendor.qcom.bluetooth.enable.swb=true
persist.bluetooth.enabledelayreports=true
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true" >> $MODPATH/system.prop
}

AUTO_EN() {
	ui_print " "
    ui_print " - You selected AUTO installation mode - "
    AUTO_In=true
	
	clear_screen
	ui_print " "
	ui_print " - The installation has started! - "
	
	ui_print " "
	ui_print "     Please wait until it is completed. "
	ui_print "     The installation time can vary from "
	ui_print "     one minute to ten minutes depending "
	ui_print "     on your device and the ROM used "
   
    if [ $AUTO_In = true ]; then
		deep_buffer
	fi
	
	if [ $AUTO_In = true ]; then
		iir_patches
	fi
 
    ui_print " "
    ui_print "   ########================================= 20% done!"
	
	if [ -f $sys_tem/vendor/etc/audio_platform_info.xml ]; then
		audio_platform_info
	 elif [ -f $sys_tem/vendor/etc/audio_platform_info_extcodec.xml ]; then
        audio_platform__info_ext
      elif [ -f $sys_tem/vendor/etc/audio_platform_info_intcodec.xml ]; then
         audio_platform_info_int
     fi
	
	if [ $AUTO_In = true ]; then
		companders
	fi
	
	ui_print " "
    ui_print "   ##################====================== 45% done!"
	
	if [ $AUTO_In = true ]; then
		audio_codec
	fi
	
	ui_print " "
    ui_print "   ########################================ 60% done!"
	
	if [ $AUTO_In = true ]; then
      if [ -f $sys_tem/etc/device_features/$DEVICE.xml ]; then
		device_features_system
      elif [ -f $sys_tem/vendor/etc/device_features/$DEVICE.xml ]; then
        device_features_vendor
      fi
	fi
	
	if [ $AUTO_In = true ]; then
		mixer_lite
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
    ui_print "   ######################################## 100% done!"
	
	ui_print " "
	ui_print " - All done! "
}

AUTO_RU() {
	ui_print " "
	ui_print " - Вы выбрали режим установки АВТО - "
    AUTO_In=true
	
	clear_screen
	ui_print " "
	ui_print " - Установка началась! - "
	
	ui_print " "
	ui_print "     Пожалуйста дождитесь завершения. "
	ui_print "     Время установки может варьироваться "
	ui_print "     от одной до пяти минут в зависимости от "
	ui_print "     вашего устройства и используемой прошивки. "
   
	if [ $AUTO_In = true ]; then
		deep_buffer
	fi
	
	if [ $AUTO_In = true ]; then
		iir_patches
	fi
 
    ui_print " "
    ui_print "   ########================================= 20% готово!"
	
	if [ -f $sys_tem/vendor/etc/audio_platform_info.xml ]; then
		audio_platform_info
	 elif [ -f $sys_tem/vendor/etc/audio_platform_info_extcodec.xml ]; then
        audio_platform__info_ext
      elif [ -f $sys_tem/vendor/etc/audio_platform_info_intcodec.xml ]; then
         audio_platform_info_int
     fi
	
	if [ $AUTO_In = true ]; then
		companders
	fi
	
	ui_print " "
    ui_print "   ##################====================== 45% готово!"
	
	if [ $AUTO_In = true ]; then
		audio_codec
	fi
	
	ui_print " "
    ui_print "   ########################================ 60% готово!"
	
	if [ $AUTO_In = true ]; then
      if [ -f $sys_tem/etc/device_features/$DEVICE.xml ]; then
		device_features_system
      elif [ -f $sys_tem/vendor/etc/device_features/$DEVICE.xml ]; then
        device_features_vendor
      fi
	fi
	
	if [ $AUTO_In = true ]; then
		mixer_lite
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
    ui_print "   ######################################## 100% готово!"
	
	ui_print " "
	ui_print " - Всё готово! "
}

English() {
	  clear_screen
	  if [ "$SD662" ] || [ "$SD665" ] || [ "$SD690" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ]; then
		HIFI=true
	  ui_print " "
	  ui_print " - Device with support Hi-Fi detected! -"
	  else
		NOHIFI=false
	  ui_print " "
	  ui_print " - Device without support Hi-Fi detected! -"
	  fi
	  
	  ENG_CHK=1
	  ui_print " "
	  ui_print " - You selected English language! -"
	  ui_print " "
	  ui_print " - Select installation mode: "
	  ui_print " "
	  ui_print " - NOTE: [VOL+] - select, [VOL-] - confirm "
	  ui_print " "
	  ui_print " 1. Auto (Only the most necessary things"
	  ui_print "    for your device will be installed)"
	  ui_print " "
	  ui_print " 2. Manual (You configure the module yourself)"
	  ui_print " "
	  ui_print " "
	  ui_print " 3. Install all (For experienced users, may cause problems)"
	  ui_print " "
	  ui_print "        Selected: "
	  ui_print " "
	  
	  while true; do
	  ui_print "------>    $ENG_CHK    step"
	  ui_print " "
	  if $VKSEL; then
		ENG_CHK=$((ENG_CHK + 1))
		ALL=true
	  else
		break
	  fi
		
	  if [ $ENG_CHK -gt 3 ]; then
		ENG_CHK=1
	  fi
done

case $ENG_CHK in
	1) AUTO_EN;;
	2) ENG_Manual;;
	3) All_En;;
esac
}

Russian() {
	  clear_screen
	  if [ "$SD662" ] || [ "$SD665" ] || [ "$SD690" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ]; then
		HIFI=true
	  ui_print " "
	  ui_print " - Обнаружено устройство с поддержкой Hi-Fi! -"
	  else
		NOHIFI=false
	  ui_print " "
	  ui_print " - Обнаружено устройство без поддержки Hi-Fi! -"
	  fi
	  
	  RU_CHK=1
	  ui_print " "
	  ui_print " - Вы выбрали Русский язык! -"
	  ui_print " "
	  ui_print " - Выберите режим установки: "
	  ui_print " "
	  ui_print " - Заметка: [VOL+] - выбор, [VOL-] - подтверждение "
	  ui_print " "
	  ui_print " 1. Авто (Только самое необходимое для"
	  ui_print "    вашего устройства будет установлено)"
	  ui_print " "
	  ui_print " 2. Ручной (Вы самостоятельно настраиваете модуль)"
	  ui_print " "
	  ui_print " "
	  ui_print " 3. Установить всё (Для опытных пользователей, может вызвать проблемы)"
	  ui_print " "
	  ui_print "        Выбран: "
	  ui_print " "
	  while true; do
	  ui_print "------>    $RU_CHK    пункт"
	  ui_print " "
	  if $VKSEL; then
		RU_CHK=$((RU_CHK + 1))
		ALL=true
	  else
		break
	  fi
		
	  if [ $RU_CHK -gt 3 ]; then
		RU_CHK=1
	  fi
done

case $RU_CHK in
	1) AUTO_RU;;
	2) RU_Manual;;
	3) All_Ru;;
esac
}
	
ENG_Manual() {
	  clear_screen
	  ui_print " "
	  ui_print " - You selected Manual mode - "
	  ui_print " "
	  ui_print " - Configurate me, pls >.< - "
	  ui_print " "
	  
	  sleep 1
	  ui_print " - Disable Deep Buffer -"
	  ui_print "***************************************************"
	  ui_print "* [1/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*               This option disable               *"
	  ui_print "*            deep buffer in your device.          *"
	  ui_print "*         If you want more low frequencies,       *"
	  ui_print "*                skip this option.                *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Disable deep buffer?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
		STEP1=true
	fi

	ui_print " "
	ui_print " - Improve volume levels and change media volume steps -"
	  ui_print "***************************************************"
	  ui_print "* [2/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*               A T T E N T I O N!                *"
	  ui_print "*   Confirming this option may harm your device!  *"
	  ui_print "*NLSound Team is not responsible for your devices!*"
	  ui_print "*              Choose at your own risk!           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Improve volume levels and media volume steps?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP2=true
		
	fi

	ui_print " "
	ui_print " - Improve microphones levels -"
	  ui_print "***************************************************"
	  ui_print "* [3/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*             This option improving               *"
	  ui_print "*     microphone volume levels and quality in     *"
	  ui_print "*                 your device.                    *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Improve microphone levels?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP3=true
	fi

	ui_print " "
	ui_print " - IIR patches -"
	  ui_print "***************************************************"
	  ui_print "* [4/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "* IIR affects the final frequency response curve. *"
	  ui_print "*   headphones. The default setting is with an    *"
	  ui_print "* emphasis on the upper limit of low frequencies  *"
	  ui_print "* and the lower bound of the midrange frequencies *"
	  ui_print "*Once applied, these boundaries will be reinforced*"
	  ui_print "*        [Recommended for installation]           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install IIR patches?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP4=true
	fi

	ui_print " "
	ui_print " - Patching audio platform files -"
	  ui_print "***************************************************"
	  ui_print "* [5/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "* Confirming this option will allow the module to *"
	  ui_print "*      use a different audio codec algorithm      *"
	  ui_print "* for your favorite songs, and will also improve  *"
	  ui_print "*    the sound quality during video recording     *"
	  ui_print "*        [Recommended for installation]           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Patching audio platform files?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP5=true
	fi

	ui_print " "
	ui_print " - Disable сompanders -"
	  ui_print "***************************************************"
	  ui_print "* [6/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*    Companding-exists for audio compression.     *"
	  ui_print "*    Because of this algorithm, you can hear      *"
	  ui_print "*  the hiss in the path is even lossless audio.   *"
	  ui_print "*     This algorithm does not work properly.      *"
	  ui_print "*    Everything he does is pointlessly making     *"
	  ui_print "* things worse the quality of your favorite audio *"
	  ui_print "*        [Recommended for installation]           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "    Disable companders?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP6=true
	fi

	ui_print " "
	ui_print " - Configurating interal audio codec -"
	  ui_print "***************************************************"
	  ui_print "* [7/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*            This option configuring              *"
	  ui_print "*       your device's internal audio codec.       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Configurate?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	   STEP7=true
	fi
	 
	ui_print " "
	ui_print " - Patch device_features files -"
	  ui_print "***************************************************"
	  ui_print "* [8/14]                                          *"
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
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "    Install this step?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = YES, Vol Down = NO"
	if chooseport; then
		STEP8=true
	fi

	ui_print " "
	ui_print " - Added new dirac -"
	  ui_print "***************************************************"
	  ui_print "* [9/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "* This option will add a new dirac to the system  *"
	  ui_print "*   If you encounter wheezing from the outside    *"
	  ui_print "*    speaker, first of all when reinstalling      *"
	  ui_print "*               skip this step.                   *"
	  ui_print "***************************************************"
	ui_print "   Added new dirac?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
		STEP9=true
	fi

	ui_print " "
	ui_print " - Install other patches in mixer_paths - "
	  ui_print "***************************************************"
	  ui_print "* [10/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*        Contains experimental settings           *"
	  ui_print "*          If you encounter problems              *"
	  ui_print "*     after installation - skip this step.        *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install patches in mixer_paths files?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP10=true
	fi
	  
	ui_print " "
	ui_print " - Install tweaks in prop file - "
	  ui_print "***************************************************"
	  ui_print "* [11/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*    This option will change the sound quality    *"
	  ui_print "*                  the most.                      *"
	  ui_print "*             May cause problems.                 *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP11=true
	fi
	
	ui_print " "
	ui_print " - Improve Bluetooth - "
	  ui_print "***************************************************"
	  ui_print "* [12/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*   This option will improve the audio quality    *"
	  ui_print "*    in Bluetooth, as well as fix the problem     *"
	  ui_print "*      of disappearing the AAC codec switch       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP12=true
	fi
	
	ui_print " "
	ui_print " - Switch audio output from DIRECT to DIRECT_PCM - "
	  ui_print "***************************************************"
	  ui_print "* [13/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*  This option will switch DIRECT to DIRECT_PCM,  *"
	  ui_print "*      which will improve the sound detail.       *"
	  ui_print "*         [Recommended for installation]          *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP13=true
	fi
	
	ui_print " "
	ui_print " - Turn off useless DRC - "
	  ui_print "***************************************************"
	  ui_print "* [14/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*    Limit the dynamic range of the soundtrack    *"
	  ui_print "*       (the difference between the loudest       *"
	  ui_print "*             and the quietest sounds)            *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP14=true
	fi
	
	ui_print " "
	ui_print " - Processing. . . . -"
	ui_print " "
	ui_print " - You can minimize Magisk and use the device -"
	ui_print " - and then come back here to reboot and apply the changes. -"
	
	if [ $STEP1 = true ]; then
		deep_buffer
	fi
	
	if [ $STEP2 = true ]; then
		patch_volumes
	fi

    ui_print " "
    ui_print "   ########================================ 20% done!"
	
	if [ $STEP3 = true ]; then
		patch_microphone
	fi
	
	if [ $STEP4 = true ]; then
		iir_patches
	fi
 
    ui_print " "
    ui_print "   ################======================== 40% done!"
	
	if [ $STEP5 = true ]; then
     if [ -f $APII ]; then
		audio_platform_info_int
	 elif [ -f $APIE ]; then
        audio_platform__info_ext
     elif [ -f $API ]; then
        audio_platform_info
     fi
	fi
	
	if [ $STEP6 = true ]; then
		companders
	fi
  
    ui_print " "
    ui_print "   ########################================ 60% done!"
	
	if [ $STEP7 = true ]; then
		audio_codec
	fi
	
	if [ $STEP8 = true ]; then
      if [ -f $DEVFEA ]; then
		device_features_system
      elif [ -f $DEVFEAA ]; then
        device_features_vendor
      fi
	fi

    ui_print " "
    ui_print "   ################################======== 80% done!"
	
	if [ $STEP9 = true ]; then
		dirac
	fi
	
	if [ $STEP10 = true ]; then
		mixer
	fi
	
	if [ $STEP11 = true ]; then
		prop
	fi
	
	if [ $STEP12 = true ]; then
		improve_bluetooth
	fi
	
	if [ $STEP13 = true ]; then
		io_policy
	fi
	
	if [ $STEP14 = true ]; then
		audio_policy
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
    ui_print "   ######################################## 100% done!"
	
    ui_print " "
    ui_print " - All done! With love, NLSound Team. - "
    ui_print " "
}

RU_Manual() {
	clear_screen
	ui_print " "
	ui_print " - Вы выбрали РУЧНОЙ режим установки - "
	ui_print " "
	ui_print " - Настрой меня, пожалуйста >.< -"
	ui_print " "

	sleep 1
	ui_print " - Отключение глубокого буффера -"
	  ui_print "**************************************************"
	  ui_print "* [1/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*             Эта опция отключит                 *"
	  ui_print "*     глубокий буффер в вашем устройстве.        *"
	  ui_print "*     Если вам недостаточно низких частот,       *"
	  ui_print "*            пропустите этот пункт.              *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Отключить глубокий буффер?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP1=true
	fi

	ui_print " "
	ui_print " - Увеличить уровни и шаги громкости медиа -"
	  ui_print "**************************************************"
	  ui_print "* [2/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*                О С Т О Р О Ж Н О!              *"
	  ui_print "*          Подтверждение этой опции может        *"
	  ui_print "*          нанести вред вашему устройству!       *"
	  ui_print "*      NLSound Team не несёт ответственности     *"
	  ui_print "*               за ваше устройство!              *"
	  ui_print "*          Выбирать на свой страх и риск!        *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Увеличить уровни и шаги громкости медиа?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP2=true
	fi

	ui_print " "
	ui_print " - Увеличить громкости микрофонов -"
	  ui_print "**************************************************"
	  ui_print "* [3/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*                 Эта опция увеличит             *"
	  ui_print "*           уровни громкостей микрофонов в       *"
	  ui_print "*                  вашем устройстве.             *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Увеличить громкости микрофонов?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP3=true
	fi

	ui_print " "
	ui_print " - IIR патчи -"
	  ui_print "**************************************************"
	  ui_print "* [4/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*    IIR влияет на итоговую кривую АЧХ ваших     *"
	  ui_print "* наушников. По-умолчанию используется настройка *"
	  ui_print "*  с акцентом на верхнюю границу низких частот   *"
	  ui_print "*       и нижнюю границу средних частот.         *"
	  ui_print "*  После применения эти границы будут усилены.   *"
	  ui_print "*        [Рекомендуется для установки]           *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Установить IIR патчи?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP4=true
	fi

	ui_print " "
	ui_print " - Патчинг audio_platform файлов -"
	  ui_print "**************************************************"
	  ui_print "* [5/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*    Подтверждение этой опции позволит модулю    *"
	  ui_print "* использовать иной алгоритм работы аудио кодека *"
	  ui_print "* для ваших любимых композиций, а также улучшит  *"
	  ui_print "*       качество звука при видеосъёмке.          *"
	  ui_print "*        [Рекомендуется для установки]           *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Патчить audio platform файлы?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP5=true
	fi

	ui_print " "
	ui_print " - Отключение компандеров -"
	  ui_print "**************************************************"
	  ui_print "* [6/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "* Компандирование - существует для сжатия аудио. *"
	  ui_print "*     Из-за этого алгоритма вы можете слышать    *"
	  ui_print "*      шипение в тракте даже lossless аудио.     *"
	  ui_print "*   Этот алгоритм не работает должным образом.   *"
	  ui_print "*   Всё, что он делает - бессмысленно ухудшает   *"
	  ui_print "*        качество вашего любимого аудио.         *"
	  ui_print "*         [Рекомендуется для установки]          *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "    Отключить компандеры?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP6=true
	fi

	ui_print " "
	ui_print " - Настройка внутреннего аудио кодека -"
	  ui_print "**************************************************"
	  ui_print "* [7/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*               Эта опция настроит               *"
	  ui_print "*   внутреннний аудио кодек вашего устройства.   *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Настроить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	   STEP7=true
	fi
	 
	ui_print " "
	ui_print " - Патчинг device_features файлов -"
	  ui_print "**************************************************"
	  ui_print "* [8/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*  Этот шаг сделает следующее:                   *"
	  ui_print "*   - Разблокирует частоты дискретизации         *"
	  ui_print "*     вплоть до 192000 kHz;                      *"
	  ui_print "*   - Активирует режим чувствительности для      *"
	  ui_print "*     Bluetooth наушников;                       *"
	  ui_print "*   - Включит HD запись аудио;                   *"
	  ui_print "*   - Улучшит качество Voip записи;              *"
	  ui_print "*   - Включит поддержку Hi-Fi (для под. ус-тв);  *"
	  ui_print "*                                                *"
	  ui_print "*  И многое другое . . .                         *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "    Установить этот пункт?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP8=true
	fi

	ui_print " "
	ui_print " - Добавление нового dirac -"
	  ui_print "**************************************************"
	  ui_print "* [9/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*     Эта опция добавит новый dirac в систему    *"
	  ui_print "*    Если вы столкнётесь с хрипами из внешнего   *"
	  ui_print "*  динамика, в первую очередь при переустановке  *"
	  ui_print "*             пропустите данный пункт.           *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Добавить новый dirac?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP9=true
	fi

	ui_print " "
	ui_print " - Установить другие патчи в mixer_paths файлы - "
	  ui_print "**************************************************"
	  ui_print "* [10/14]                                        *"
	  ui_print "*                                                *"
	  ui_print "*       Содержит экспериментальные настройки     *"
	  ui_print "*        Если вы столкнулись с проблемами        *"
	  ui_print "*   после установки - пропустите данный пункт.   *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Установить патчи в mixer_paths файлы?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP10=true
	fi
	
	ui_print " "
	ui_print " - Установить твики в prop файл - "
	  ui_print "***************************************************"
	  ui_print "* [11/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*  Эта опция сильнее всех изменит качество звука  *"
	  ui_print "*          Может вызвать проблемы.                *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP11=true
	fi
	
	ui_print " "
	ui_print " - Улучшить Bluetooth - "
	  ui_print "***************************************************"
	  ui_print "* [12/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*        Эта опция улучшит качество аудио         *"
	  ui_print "*     в Bluetooth, а также исправит проблему с    *"
	  ui_print "*      исчезновением переключателя ААС кодека.    *"
	  ui_print "*            Может вызвать проблемы.              *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP12=true
	fi
	
	ui_print " "
	ui_print " - Переключает роут звука с DIRECT на DIRECT_PCM - "
	  ui_print "***************************************************"
	  ui_print "* [13/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*    Эта опция переключит DIRECT на DIRECT_PCM,   *"
	  ui_print "*       и улучшит качество итогового звука.       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP13=true
	fi
	
	ui_print " "
	ui_print " - Отключить бесполезную DRC функцию - "
	  ui_print "***************************************************"
	  ui_print "* [14/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "* Ограничивает динамический диапазон аудио треков *"
	  ui_print "*      если разница между низкими и высокими      *"
	  ui_print "*           частотами слишком большая.            *"
	  ui_print "*          [Рекомендуется к установке]            *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP14=true
	fi
	
	ui_print " "
	ui_print " - Обработка. . . . -"
	ui_print " "
	ui_print " - Вы можете свернуть Magisk и пользоваться устройством -"
	ui_print " - а затем вернуться сюда для перезагрузки и применения изменений. -"
    
	if [ $STEP1 = true ]; then
		deep_buffer
	fi
	
	if [ $STEP2 = true ]; then
		patch_volumes
	fi

    ui_print " "
    ui_print "   ########================================ 20% done!"
	
	if [ $STEP3 = true ]; then
		patch_microphone
	fi
	
	if [ $STEP4 = true ]; then
		iir_patches
	fi
 
    ui_print " "
    ui_print "   ################======================== 40% done!"
	
	if [ $STEP5 = true ]; then
     if [ -f $APII ]; then
		audio_platform_info_int
	 elif [ -f $APIE ]; then
        audio_platform__info_ext
     elif [ -f $API ]; then
        audio_platform_info
     fi
	fi
	
	if [ $STEP6 = true ]; then
		companders
	fi
  
    ui_print " "
    ui_print "   ########################================ 60% done!"
	
	if [ $STEP7 = true ]; then
		audio_codec
	fi
	
	if [ $STEP8 = true ]; then
      if [ -f $DEVFEA ]; then
		device_features_system
      elif [ -f $DEVFEAA ]; then
        device_features_vendor
      fi
	fi

    ui_print " "
    ui_print "   ################################======== 80% done!"
	
	if [ $STEP9 = true ]; then
		dirac
	fi
	
	if [ $STEP10 = true ]; then
		mixer
	fi
	
	if [ $STEP11 = true ]; then
		prop
	fi
	
	if [ $STEP12 = true ]; then
		improve_bluetooth
	fi
	
	if [ $STEP13 = true ]; then
		io_policy
	fi
	
	if [ $STEP14 = true ]; then
		audio_policy
	fi

	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
    ui_print "   ######################################## 100% готово!"
	
    ui_print " "
    ui_print " - Всё готово! С любовью, NLSound Team. - "
    ui_print " "
}

All_En() {
	clear_screen
	ui_print " "
	ui_print " - You selected INSTALL ALL "
	ui_print " "
	ui_print " - Installation started! Please, wait..."
	
	if [ $ALL = true ]; then
		deep_buffer
		patch_microphone
		patch_volumes
		iir_patches
		
		if [ -f $APII ]; then
			audio_platform_info_int
		elif [ -f $APIE ]; then
			audio_platform_info_ext
		elif [ -f $API ]; then
			audio_platform_info
		fi
		
		companders
		audio_codec
		device_features_system
		device_features_vendor
		dirac
		mixer
		prop
		improve_bluetooth
		io_policy
		audio_policy
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
	ui_print " - All done!"
	ui_print " "
}

All_Ru() {
	clear_screen
	ui_print " "
	ui_print " - Вы выбрали УСТАНОВИТЬ ВСЁ "
	ui_print " "
	ui_print " - Установка начата! Пожалуйста, подождите..."
	
	if [ $ALL = true ]; then
		deep_buffer
		patch_microphone
		patch_volumes
		iir_patches
		
		if [ -f $APII ]; then
			audio_platform_info_int
		elif [ -f $APIE ]; then
			audio_platform_info_ext
		elif [ -f $API ]; then
			audio_platform_info
		fi
		
		companders
		audio_codec
		device_features_system
		device_features_vendor
		dirac
		mixer
		prop
		improve_bluetooth
		io_policy
		audio_policy
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
	ui_print " - Всё готово!"
	ui_print " "
}

ui_print " "
ui_print " - Select language -"
ui_print " "
ui_print " - NOTE: [VOL+] - select, [VOL-] - confirm "
sleep 1
LANG=1
ui_print " "
ui_print "   1. English "
ui_print "   2. Русский "
ui_print " "
ui_print "      Selected: "
while true; do
	ui_print "      $LANG"
	if $VKSEL; then
		LANG=$((LANG + 1))
	else
		break
	fi
		
	if [ $LANG -gt 2 ]; then
		LANG=1
	fi
done

case $LANG in
	1) English;;
	2) Russian;;
esac

