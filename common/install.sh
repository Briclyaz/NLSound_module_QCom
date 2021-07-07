set_perm() {
	chown $1:$2 $4
	chmod $3 $4
	case $4 in
		*/vendor/etc/*)
			chcon 'u:object_r:vendor_configs_file:s0' $4
		;;
		*/vendor/*)
			chcon 'u:object_r:vendor_file:s0' $4
		;;
		*/data/adb/*.d/*)
			chcon 'u:object_r:adb_data_file:s0' $4
		;;
		*)
			chcon 'u:object_r:system_file:s0' $4
		;;
	esac
}

cp_perm() {
  if [ -f "$4" ]; then
    rm -f $5
    cat $4 > $5
    set_perm $1 $2 $3 $5
  fi
}

set_perm_recursive() {
	find $5 -type d | while read dir; do
		set_perm $1 $2 $3 $dir
	done
	find $5 -type f -o -type l | while read file; do
		set_perm $1 $2 $4 $file
	done
}

nlsound() {
  case $1 in
    *.conf) SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *music {/p}" $1 | sed -r "s/( *).*/\1/")
            EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\music {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
            for EFFECT in ${EFFECTS}; do
              SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
              [ "$EFFECT" != "atmos" ] && sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#/g}" $1
            done;;
     *.xml) EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"music\">$/,/^ *<\/stream>$/ {/<stream type=\"music\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
            for EFFECT in ${EFFECTS}; do
              [ "$EFFECT" != "atmos" ] && sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--<apply effect=\"$EFFECT\"\/>-->/" $1
            done;;
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

if [ "$SD662" ] || [ "$SD665" ] || [ "$SD690" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ]; then
  HIFI=true
ui_print " "
ui_print "- Device with support Hi-Fi detected! -"
else
  NOHIFI=false
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
RK40=$(grep -E "ro.product.vendor.device=alioth.*" $BUILDS)

MI9SE=$(grep -E "ro.product.vendor.device=grus.*" $BUILDS)
MICC9E=$(grep -E "ro.product.vendor.device=laurus.*" $BUILDS)
MICC9=$(grep -E "ro.product.vendor.device=pyxis.*" $BUILDS)
MICC9PRO=$(grep -E "ro.product.vendor.device=tucana.*" $BUILDS)
MI9=$(grep -E "ro.product.vendor.device=cepheus.*" $BUILDS)
MI9T=$(grep -E "ro.product.vendor.device=davinci.*" $BUILDS)
MI10=$(grep -E "ro.product.vendor.device=umi.*" $BUILDS)
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

MPATHS="$(find /system /vendor -type f -name "mixer_paths*.xml")"
APINF="$(find /system /vendor -type f -name "audio_platform_info*.xml")"
ACONFS="$(find /system /vendor -type f -name "audio_configs*.xml")"
CFGS="$(find /system /vendor -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
VNDK=$(find /system/lib /vendor/lib -type d -iname "*vndk*")
VNDK64=$(find /system/lib64 /vendor/lib64 -type d -iname "*vndk*")
#STPI="$(find /system /vendor -type f -name "sound_trigger_platform_info*.xml")"

DEVFEA=/system/etc/device_features/*.xml
DEVFEAA=/vendor/etc/device_features/*.xml

API=/vendor/etc/audio_platform_info.xml
APII=/vendor/etc/audio_platform_info_intcodec.xml
APIE=/vendor/etc/audio_platform_info_extcodec.xml

NLS=$MODPATH/common/NLSound
FIRMRN7PRO=$MODPATH/common/NLSound/firmrn7pro
FEATURES=$MODPATH/common/NLSound/features
WHYDED=$MODPATH/common/NLSound/whyded
FIRMWARE=$MODPATH/common/NLSound/firmware
NEWDIRAC=$MODPATH/common/NLSound/newdirac

SETC=/system/SETC
SVSETC=/system/vendor/SETC

mkdir -p $MODPATH/tools
cp -f $MODPATH/common/addon/External-Tools/tools/$ARCH32/* $MODPATH/tools/



for OMIX in ${MPATHS}; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OMIX $MIX
    sed -i 's/\t/  /g' $MIX
    done

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

deep_buffer() {
	echo -e '\naudio.deep_buffer.media=false\nvendor.audio.deep_buffer.media=false\nqc.audio.deep_buffer.media=false\nro.qc.audio.deep_buffer.media=false\npersist.vendor.audio.deep_buffer.media=false' >> $MODPATH/system.prop
		for OACONF in ${ACONFS}; do
		ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g")"
			patch_xml -u $ACONF '/configs/property[@name="audio.deep_buffer.media"]' "false"
		done
}
	
patch_headphones() {
	for OMIX in ${MPATHS}; do
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
		if [ "$RN9S" ] || [ "$RN9PRO" ] || [ "$POCOM2P" ] || [ "$RN9PROMAX" ]; then
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX0 Digital Volume"]' "60"
		fi
		if [ "$POCOX3" ] || [ "$RN10" ]; then
		patch_xml -u $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME LEFT"]' "40"
		fi
		if [ "$RN7" ]; then
		patch_xml -u $MIX '/mixer/ctl[@name="RX1 Digital Volume"]' "60"
		fi
		done	
		echo -e '\nro.config.media_vol_steps=30' >> $MODPATH/system.prop
}

patch_microphone() {
	for OMIX in ${MPATHS}; do
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
	  
	  #for OSTPI in ${STPI}; do 
		#STPI="$MODPATH$(echo $OSTPI | sed "s|^/vendor|/system/vendor|g")"
		#cp_ch $ORIGDIR$OSTPI $STPI
		#sed -i 's/\t/  /g' $STPI
		#patch_xml -u $STPI '/sound_trigger_platform_info/sound_model_config/param[@name="execution_type"]' "ADSP"
		#patch_xml -u $STPI '/sound_trigger_platform_info/sound_model_config/param[@name="fluence_type"]' "NONE"
		#patch_xml -u $STPI '/sound_trigger_platform_info/sound_model_config/param[@name="execution_mode"]' "ADSP"
		#patch_xml -u $STPI '/sound_trigger_platform_info/sound_model_config/param[@name="adm_cfg_profile"]' "FFECNS"
		#patch_xml -u $STPI '/sound_trigger_platform_info/sound_model_config/param[@name="capture_keyword"]' "PCM_raw, FTRT, 500"
		#patch_xml -u $STPI '/sound_trigger_platform_info/sound_model_config/param[@name="client_capture_read_delay"]' "2000"
	#done
}

iir_patches() {
	for OMIX in ${MPATHS}; do
		MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band1"][@id="0"]' "238395206"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band1"][@id="1"]' "689443228"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band1"][@id="2"]' "205354587"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band1"][@id="3"]' "537398060"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band1"][@id="4"]' "689443228"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band2"][@id="0"]' "262009200"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band2"][@id="1"]' "568438374"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band2"][@id="2"]' "243939794"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band2"][@id="3"]' "569025299"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band2"][@id="4"]' "238100463"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band3"][@id="0"]' "253440447"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band3"][@id="1"]' "842391711"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band3"][@id="2"]' "209259777"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band3"][@id="3"]' "842391711"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band3"][@id="4"]' "194264768"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band4"][@id="0"]' "268435456"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band4"][@id="1"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band4"][@id="2"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band4"][@id="3"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band4"][@id="4"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band5"][@id="0"]' "268435456"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band5"][@id="1"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band5"][@id="2"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band5"][@id="3"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Band5"][@id="4"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Enable Band0"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Enable Band1"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Enable Band2"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Enable Band3"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Enable Band4"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 Enable Band5"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 INP0 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 INP1 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 INP2 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 INP3 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 INP4 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 INP5 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band1"][@id="0"]' "238395206"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band1"][@id="1"]' "689443228"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band1"][@id="2"]' "205354587"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band1"][@id="3"]' "689443228"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band1"][@id="4"]' "175314338"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band2"][@id="0"]' "262009200"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band2"][@id="1"]' "568438374"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band2"][@id="2"]' "243939794"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band2"][@id="3"]' "569025299"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band2"][@id="4"]' "238100463"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band3"][@id="0"]' "253440447"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band3"][@id="1"]' "842391711"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band3"][@id="2"]' "209259777"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band3"][@id="3"]' "842391711"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band3"][@id="4"]' "194264768"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band4"][@id="0"]' "268435456"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band4"][@id="1"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band4"][@id="2"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band4"][@id="3"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band4"][@id="4"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band5"][@id="0"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band5"][@id="1"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band5"][@id="2"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band5"][@id="3"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Band5"][@id="4"]' "0"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Enable Band0"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Enable Band1"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Enable Band2"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Enable Band3"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Enable Band4"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 Enable Band5"]' "1"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 INP0 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 INP1 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 INP2 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 INP3 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 INP4 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR2 INP5 Volume"]' "72"
		patch_xml -u $MIX '/mixer//ctl[@name="IIR1 INP1 MUX"]' "headphones"
		patch_xml -u $MIX '/mixer//ctl[@name="RX1 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer//ctl[@name="RX2 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer//ctl[@name="RX3 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer//ctl[@name="TX1 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer//ctl[@name="TX2 HPF Switch"]' "On"
		patch_xml -u $MIX '/mixer//ctl[@name="TX3 HPF Switch"]' "On"
		done
}

audio_platform_info_int() {
	for OAPLI in ${APINF}; do
    APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OAPLI $APLI
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
    [ "$(xmlstarlet sel -t -m "/audio_platform_info_intcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APLI)" ] || sed -i "/<audio_platform_info_intcodec>/,/<\/audio_platform_info_intcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}" $APLI			
    done
    fi
  done
fi
}

audio_platform_info_ext() {
	for OAPLI in ${APINF}; do
    APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OAPLI $APLI
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
fi
}

audio_platform_info() {
	for OAPLI in ${APINF}; do
    APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OAPLI $APLI
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
    [ "$(xmlstarlet sel -t -m "/audio_platform_info/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APLI)" ] || sed -i "/<audio_platform_info>/,/<\/audio_platform_info>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}" $APLI			
    done
    fi
  done	
fi
}

companders() {
	for OMIX in ${MPATHS}; do
		MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/ctl[@name="SpkrRight COMP Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP1"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback bt-sco-wb"]/ctl[@name="RX_COMP2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX2 Switch"]' "0"
		
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX2 Switch"]' "0"	
		
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP3 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP4 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP5 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP6 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP7 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP8 Switch"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX2"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP1"]' "0"
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP2"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="SpkrLeft COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="SpkrRight COMP Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="WSA_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="WSA_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="RX_COMP1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="RX_COMP2 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX1 Switch"]' "0"
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX2 Switch"]' "0"	
		
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 16 Volume"]' "0"
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 15 Volume"]' "0"
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 29 Volume"]' "0"
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 30 Volume"]' "0"
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 31 Volume"]' "0"
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 32 Volume"]' "0"
		done
}

audio_codec() {
	for OACONF in ${ACONFS}; do
		ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g")"
		cp_ch $ORIGDIR$OACONF $ACONF
		sed -i 's/\t/  /g' $ACONF
		patch_xml -u $ACONF '/configs/property[@name="audio.offload.min.duration.secs"]' "30"
		patch_xml -u $ACONF '/configs/property[@name="persist.vendor.audio.sva.conc.enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="persist.vendor.audio.va_concurrency_enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.dsd.playback.conc.disabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.playback.conc.disabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.rec.playback.conc.disabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.path.for.pcm.voip"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.alac.decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.ape.decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.mpegh.decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.flac.sw.decoder.24bit"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.hw.aac.encoder"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="aac_adts_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="alac_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="ape_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="flac_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="pcm_offload_enabled_16"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="pcm_offload_enabled_24"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="qti_flac_decoder"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="vorbis_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="wma_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="audiosphere_enabled"]' "false"
		patch_xml -u $ACONF '/configs/flag[@name="hifi_audio_enabled"]' "true"
		patch_xml -u $ACONF '/configs/flag[@name="audio_extn_formats_enabled"]' "true"
		done	
		
		if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
			cp_ch -f $FIRMWARE/PNX_TAS2557.bin $MODPATH/system/vendor/firmware/PNX_TAS2557.bin
			cp_ch -f $FIRMWARE/tas2557_uCDSP.bin $MODPATH/system/vendor/firmware/tas2557_uCDSP.bin
			cp_ch -f $FIRMWARE/tas2557_uCDSP_aac.bin $MODPATH/system/vendor/firmware/tas2557_uCDSP_aac.bin
			cp_ch -f $FIRMWARE/tas2557_uCDSP_goer.bin $MODPATH/system/vendor/firmware/tas2557_uCDSP_goer.bin
			cp_ch -f $FIRMWARE/TAS2557MSSMono.bin $MODPATH/system/vendor/firmware/TAS2557MSSMono.bin
			cp_ch -f $FIRMWARE/TAS2557MSSMono_B2N.bin $MODPATH/system/vendor/firmware/TAS2557MSSMono_B2N.bin
			cp_ch -f $FIRMWARE/TAS2557MSSMono_B2N_dvt.bin $MODPATH/system/vendor/firmware/TAS2557MSSMono_B2N_dvt.bin
			cp_ch -f $FIRMWARE/TAS2557MSSMono_B2N_dvt_ICTspk.bin $MODPATH/system/vendor/firmware/TAS2557MSSMono_B2N_dvt_ICTspk.bin
			cp_ch -f $FIRMWARE/TAS2557MSSMono_CTL.bin $MODPATH/system/vendor/firmware/TAS2557MSSMono_CTL.bin
			cp_ch -f $FIRMWARE/TAS2557MSSMono_DRG.bin $MODPATH/system/vendor/firmware/TAS2557MSSMono_DRG.bin
		fi
		if [ "$POCOF1" ]; then
			cp_ch -f $FIRMPOCOF1/tas2559_uCDSP.bin $MODPATH/system/vendor/firmware/tas2559_uCDSP.bin
		fi
		if [ "$MIA2" ]; then
			cp_ch -f $FIRMRN7PRO/tas2563_uCDSP.bin $MODPATH/system/vendor/firmware/tas2563_uCDSP.bin
		fi
}

device_features_system() {
	for ODEVFEA in ${DEVFEA}; do 
		DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g")"
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
			patch_xml -s $DEVFEA '/features/bool[@name="support_voip_record"]' "true"
			patch_xml -s $DEVFEA '/features/integer[@name="support_inner_record"]' "1"
			patch_xml -s $DEVFEA '/features/bool[@name="support_hifi"]' "true"
		done
}

device_features_vendor() {
	for ODEVFEAA in ${DEVFEAA}; do 
		DEVFEAA="$MODPATH$(echo $ODEVFEAA | sed "s|^/vendor|/system/vendor|g")"
		cp_ch $ORIGDIR$ODEVFEAA $DEVFEAA
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
	for OFILE in ${CFGS}; do
	  FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
	  cp_ch -n $ORIGDIR$OFILE $FILE
	  nlsound $FILE
	  case $FILE in
		*.conf) sed -i "/dirac_gef {/,/}/d" $FILE
				sed -i "s/^libraries {/libraries {\n  dirac_gef { #$MODID\n    path $LIBPATCH\/lib\/soundfx\/libdiraceffect.so\n  } #$MODID/g" $FILE
				sed -i "s/^effects {/effects {\n  dirac_gef { #$MODID\n    library dirac_gef\n    uuid 3799D6D1-22C5-43C3-B3EC-D664CF8D2F0D\n  } #$MODID/g" $FILE
				processing_patch "post" "$FILE" "music" "dirac_gef";;
		*.xml) sed -i "/dirac_gef/d" $FILE
			  sed -i "/<libraries>/ a\        <library name=\"dirac_gef\" path=\"libdiraceffect.so\"\/><!--$MODID-->" $FILE
			  sed -i "/<effects>/ a\        <effect name=\"dirac_gef\" library=\"dirac_gef\" uuid=\"3799D6D1-22C5-43C3-B3EC-D664CF8D2F0D\"\/><!--$MODID-->" $FILE
			  processing_patch "post" "$FILE" "music" "dirac_gef";;
			  
	  esac
	  
		cp_ch -f $NEWDIRAC/diracvdd.bin $MODPATH/system/vendor/etc/diracvdd.bin
		cp_ch -f $NEWDIRAC/dirac_resource.dar $MODPATH/system/vendor/lib/rfsa/adsp/dirac_resource.dar
		cp_ch -f $NEWDIRAC/dirac_resource.dar $MODPATH/system/vendor/lib/rfsa/adsp/dirac.so
		cp_ch -f $NEWDIRAC/interfacedb $MODPATH/system/vendor/etc/dirac/interfacedb
		cp_ch -f $NEWDIRAC/libdirac-capiv2.so $MODPATH/system/vendor/lib/rfsa/adsp/libdirac-capiv2.so
		cp_ch -f $NEWDIRAC/libdiraceffect.so $MODPATH/system/vendor/lib/soundfx/libdiraceffect.so
		
		echo -e '\npersist.dirac.acs.controller=gef' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.oppo.syss=true' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.config=64' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.exs.did=29,49' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.ext.did=10,20,29,49' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.ins.did=19,134,150' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.int.did=15,19,134,150' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.ext.appt=0x00011130,0x00011134,0x00011136' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.exs.appt=0x00011130,0x00011131' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.int.appt=0x00011130,0x00011134,0x00011136' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.ins.appt=0x00011130,0x00011131' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.exs.mid=268512739' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.ext.mid=268512737' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.ins.mid=268512738' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.gef.int.mid=268512736' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.path=/vendor/etc/dirac' >> $MODPATH/system.prop
		echo -e '\nro.dirac.acs.storeSettings=1' >> $MODPATH/system.prop
		echo -e '\npersist.dirac.acs.ignore_error=1' >> $MODPATH/system.prop
		done
}

mixer() {
	for OMIX in ${MPATHS}; do
		MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		if ! $NOHIFI; then
		patch_xml -s $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "HIRES"
		patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "HD2"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIRES"
		elif $HIFI; then
		patch_xml -u $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -u $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -u $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -u $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -u $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -s $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -u $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -s $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -u $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -s $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -u $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -s $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -u $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		patch_xml -s $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "HIFI"
		fi
		if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
		patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 ClassD Edge"]' "7"
		patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 Volume"]' "30"
		fi
		patch_xml -s $MIX '/mixer/ctl[@name="headphones]/ctl[@name="PowerCtrl"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="TFA Profile"]' "music"
		patch_xml -s $MIX '/mixer/ctl[@name="PCM_RX_DL_HL Switch"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="RX INT1 MIX3 DSD HPHL Switch"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="RX INT2 MIX3 DSD HPHR Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="HiFi Function"]' "On"
		patch_xml -s $MIX '/mixer/ctl[@name="HiFi Filter"]' "6"
		#ADDED 12.04.2021 by NLSound Team
		patch_xml -s $MIX '/mixer/ctl[@name="RX1 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="RX2 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="RX3 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="TX1 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="TX2 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="TX3 HPF cut off"]' "MIN_3DB_4Hz"
		if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
			echo -e '\nro.sound.alsa=TAS2557' >> $MODPATH/system.prop
		fi
		if [ -f /$sys_tem/vendor/etc/media_codecs_google_audio.xml ]; then
		cp_perm 0 0 0644 $sys_tem/vendor/etc/media_codecs_google_audio.xml /data/adb/modules_update/NLSound/system/vendor/etc/media_codecs_google_audio.xml
		GOOGLE_MEDIA_CODECS=/data/adb/modules_update/NLSound/system/vendor/etc/media_codecs_google_audio.xml
		sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $GOOGLE_MEDIA_CODECS	
		sed -i 's/\" >/\">/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $GOOGLE_MEDIA_CODECS	
		sed -i 's/\" >/\">/g;/aac.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $GOOGLE_MEDIA_CODECS	
		fi
		if [ -f /$sys_tem/vendor/etc/media_codecs_google_audio.xml ]; then
		cp_perm 0 0 0644 $sys_tem/vendor/etc/media_codecs_google_c2_audio.xml /data/adb/modules_update/NLSound/system/vendor/etc/media_codecs_google_c2_audio.xml
		GOOGLE_C2_MEDIA_CODECS=/data/adb/modules_update/NLSound/system/vendor/etc/media_codecs_google_c2_audio.xml
		sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $GOOGLE_C2_MEDIA_CODECS	
		sed -i 's/\" >/\">/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/vorbis.decoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.decoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $GOOGLE_C2_MEDIA_CODECS	
		sed -i 's/\" >/\">/g;/aac.encoder/,/c>/s/\">/\">\n            <Limit name=\"complexity\" range=\"0-8\"  default=\"8\"\/>/g;/aac.encoder/,/c>/s/\">/\">\n            <Feature name=\"bitrate-modes\" value=\"CQ\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/default.*/default=\"8\"\/>/g;/flac.encoder/,/<\/MediaCodec>/s/value.*/value=\"CQ\"\/>/g' $GOOGLE_C2_MEDIA_CODECS	
		fi		
		done
}

fluence() {
	echo -e '\nro.vendor.audio.sdk.fluencetype=none' >> $MODPATH/system.prop
	echo -e '\npersist.audio.fluence.voicecomm=false' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.audio.fluence.voicecall=false' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.audio.fluence.voicerec=false' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.audio.fluence.speaker=false' >> $MODPATH/system.prop
}

decoenco() {
	echo -e '\n#DECODERS&ENCODERS PARAMETERS BY NLSOUND TEAM' >> $MODPATH/system.prop
	echo -e '\nmpq.audio.decode=true' >> $MODPATH/system.prop
	echo -e '\nlpa.decode=false' >> $MODPATH/system.prop
	echo -e '\naudio.decoder_override_check=true' >> $MODPATH/system.prop
	echo -e '\nuse.non-omx.mp3.decoder=false' >> $MODPATH/system.prop
	echo -e '\nuse.non-omx.aac.decoder=false' >> $MODPATH/system.prop
	echo -e '\nlpa.use-stagefright=false' >> $MODPATH/system.prop
	echo -e '\nlpa.releaselock=false' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.flac.sw.decoder.24bit=true' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.aac.sw.decoder.24bit=true' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.use.sw.alac.decoder=true' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.flac.sw.encoder.24bit=true' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.aac.sw.encoder.24bit=true' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.use.sw.ape.decoder=true' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.vorbis.complexity.default=8' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.vorbis.quality=100' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.aac.complexity.default=8' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.aac.quality=100' >> $MODPATH/system.prop
}

hifi() {
	echo -e '\n#HiFi PARAMETERS BY NLSOUND TEAM' >> $MODPATH/system.prop
	echo -e '\nro.audio.hifi=true' >> $MODPATH/system.prop
	echo -e '\npersist.audio.hifi=true' >> $MODPATH/system.prop
	echo -e '\npersist.audio.hifi.volume=72' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.audio.hifi=true' >> $MODPATH/system.prop
	echo -e '\npersist.audio.hifi.int_codec=true' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.feature.hifi_audio.enable=true' >> $MODPATH/system.prop
	echo -e '\nro.vendor.audio.hifi=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.audio.hifi.int_codec=true' >> $MODPATH/system.prop
	echo -e '\nro.hardware.hifi.support=true' >> $MODPATH/system.prop
}

bt_parameters() {
	echo -e '\n#BT PARAMETERS BY NLSOUND TEAM' >> $MODPATH/system.prop
	echo -e '\npersist.service.btui.use_aptx=1' >> $MODPATH/system.prop
	echo -e '\npersist.bt.enableAptXHD=true' >> $MODPATH/system.prop
	echo -e '\npersist.bt.a2dp.aptx_disable=false' >> $MODPATH/system.prop
	echo -e '\npersist.bt.a2dp.aptx_hd_disable=false' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btstack.enable.splita2dp=true ' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btstack.enable.twsplus=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true ' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.qcom.bluetooth.enable.splita2dp=true ' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.qcom.bluetooth.twsp_state.enabled=false ' >> $MODPATH/system.prop
	echo -e '\nro.bluetooth.emb_wp_mode=false' >> $MODPATH/system.prop
	echo -e '\nro.bluetooth.wipower=false ' >> $MODPATH/system.prop
	echo -e '\nro.vendor.bluetooth.wipower=false' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.bt.soc.scram_freqs=192' >> $MODPATH/system.prop
	echo -e '\npersist.bt.a2dp.aac_disable=false' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.bt.aac_frm_ctl.enabled=true' >> $MODPATH/system.prop
	echo -e '\naudio.effect.a2dp.enable=1' >> $MODPATH/system.prop
	echo -e '\nvendor.audio.effect.a2dp.enable=1' >> $MODPATH/system.prop
	echo -e '\nvendor.btstack.absolute_volume=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btstack.absolute_volume=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btstack.avrcp.pos_time=1000' >> $MODPATH/system.prop
	echo -e '\npersist.bluetooth.enabledelayreports=true' >> $MODPATH/system.prop
	echo -e '\nvendor.bt.pts.pbap=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.bt.a2dp.aac_whitelist=false' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.bt.a2dp.addr_check_enabled_for_aac=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.qcom.bluetooth.scram.enabled=false' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.qcom.bluetooth.aac_vbr_ctl.enabled=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.qcom.bluetooth.aptxadaptiver2_1_support=true' >> $MODPATH/system.prop
	echo -e '\npersist.sys.fflag.override.settings_bluetooth_hearing_aid=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btstack.connect.peer_earbud=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btstack.enable.twsplussho=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btstack.enable.swb=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btstack.enable.swbpm=true' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btsatck.absvolfeature=true' >> $MODPATH/system.prop
	echo -e '\npersist.bt.sbc_hd_enabled=1' >> $MODPATH/system.prop
	echo -e '\npersist.bluetooth.sbc_hd_higher_bitrate=1' >> $MODPATH/system.prop
	echo -e '\npersist.vendor.btsatck.absvolfeature=true' >> $MODPATH/system.prop
}

ui_print " "
ui_print " - Select language -"
sleep 1
ui_print " "
ui_print "   Vol Up = English, Vol Down = Русский"
if chooseport; then
		ui_print " "
		ui_print " - You selected English language! -"
		ui_print " "
		ui_print " - Configurate me, pls >.< -"
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
	ui_print " - Added new Dirac -"
	  ui_print "***************************************************"
	  ui_print "* [9/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "* This option will add a new Dirac to the system  *"
	  ui_print "*   If you encounter wheezing from the outside    *"
	  ui_print "*    speaker, first of all when reinstalling      *"
	  ui_print "*               skip this step.                   *"
	  ui_print "***************************************************"
	ui_print "   Added new Dirac?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
		STEP9=true
	fi
	
	ui_print " "
	ui_print " - Disable useless fluence -"
	  ui_print "***************************************************"
	  ui_print "* [10/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*  This option disables useless noise reduction.  *"
	  ui_print "*      This will also affect the quality          *"
	  ui_print "*           of the audio recording                *"
	  ui_print "*        [Recommended for installation]           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "    Install this step?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = YES, Vol Down = NO"
	if chooseport; then
		STEP10=true
	fi

	ui_print " "
	ui_print " - Install other patches in mixer_paths - "
	  ui_print "***************************************************"
	  ui_print "* [11/14]                                         *"
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
	ui_print " " 
	if chooseport; then
	  STEP11=true
	fi
	  
	ui_print " "
	ui_print " - Improve decoders&encoders audio - "
	  ui_print "***************************************************"
	  ui_print "* [12/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*  This option will improve the audio processing  *"
	  ui_print "*    algorithms of the built-in audio decoders    *"
	  ui_print "*                 and encoders                    *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	ui_print " " 
	if chooseport; then
	  STEP12=true
	fi
	
	ui_print " "
	ui_print " - Install patches for Hi-Fi audio - "
	  ui_print "***************************************************"
	  ui_print "* [13/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*   This option will improve the processing of    *"
	  ui_print "*     high-pass audio, as well as eliminate       *"
	  ui_print "*         the problem of audio clipping           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	ui_print " " 
	if chooseport; then
	  STEP13=true
	fi
	
	ui_print " "
	ui_print " - Improve Bluetooth - "
	  ui_print "***************************************************"
	  ui_print "* [14/14]                                         *"
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
	ui_print " " 
	if chooseport; then
	  STEP14=true
	fi
	ui_print " - Processing. . . . -"
	ui_print " "
	ui_print " - You can minimize Magisk and use the device -"
	ui_print " - and then come back here to reboot and apply the changes. -"
	
	if [ $STEP1 = true ]; then
		deep_buffer
	fi
	
	if [ $STEP2 = true ]; then
		patch_headphones
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
		fluence
	fi
	
	if [ $STEP11 = true ]; then
		mixer
	fi
	
	if [ $STEP12 = true ]; then
		decoenco
	fi
	
	if [ $STEP13 = true ]; then
		hifi
	fi
	
	if [ $STEP14 = true ]; then
		bt_parameters
	fi
    ui_print " "
    ui_print " - All done! With love, NLSound Team. - "
    ui_print " "
	
	else
	ui_print " "
	ui_print " - Вы выбрали Русский язык! -"
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
	ui_print " - Добавление нового Dirac -"
	  ui_print "**************************************************"
	  ui_print "* [9/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*     Эта опция добавит новый Dirac в систему    *"
	  ui_print "*    Если вы столкнётесь с хрипами из внешнего   *"
	  ui_print "*  динамика, в первую очередь при переустановке  *"
	  ui_print "*             пропустите данный пункт.           *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Добавить новый Dirac?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP9=true
	fi
	
	ui_print " "
	ui_print " - Отключить бесполезное шумоподавление -"
	  ui_print "***************************************************"
	  ui_print "* [10/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*  Эта опция отключит бесполезное шумоподавление. *"
	  ui_print "*       Это также повлияет на качество            *"
	  ui_print "*            записываемого аудио                  *"
	  ui_print "*        [Рекомендуется для установки]            *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "    Установить этот пункт?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP10=true
	fi

	ui_print " "
	ui_print " - Установить другие патчи в mixer_paths файлы - "
	  ui_print "**************************************************"
	  ui_print "* [11/14]                                        *"
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
	ui_print " " 
	if chooseport; then
		STEP11=true
	fi
	
	ui_print " "
	ui_print " - Улучшить декодеры и инкодеры аудио - "
	  ui_print "***************************************************"
	  ui_print "* [12/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*  Эта опция улучшит алгоритмы аудио обработки    *"
	  ui_print "*    встроенных аудио декодеров и инкодеров.      *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	ui_print " " 
	if chooseport; then
	  STEP12=true
	fi
	
	ui_print " "
	ui_print " - Установка патчей для Hi-Fi аудио - "
	  ui_print "***************************************************"
	  ui_print "* [13/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*         Эта опция улучшит обработку             *"
	  ui_print "*   высоких частот аудио, а также устранит        *"
	  ui_print "*          проблему клиппинга аудио               *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	ui_print " " 
	if chooseport; then
	  STEP13=true
	fi
	
	ui_print " "
	ui_print " - Улучшить Bluetooth - "
	  ui_print "***************************************************"
	  ui_print "* [14/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*      Эта опция улучшит качество аудио в         *"
	  ui_print "*     Bluetooth, а также исправит проблему        *"
	  ui_print "*    исчезновения переключателя AAC кодека.       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	ui_print " " 
	if chooseport; then
	  STEP14=true
	fi
	ui_print " - Обработка. . . . -"
	ui_print " "
	ui_print " - Вы можете свернуть Magisk и пользоваться устройством -"
	ui_print " - а затем вернуться сюда для перезагрузки и применения изменений. -"
    if [ $STEP1 = true ]; then
		deep_buffer
	fi

	if [ $STEP2 = true ]; then
		patch_headphones
	fi

    ui_print " "
    ui_print "   ########================================ 20% готово!"

	if [ $STEP3 = true ]; then
		patch_microphone
	fi

	if [ $STEP4 = true ]; then
		iir_patches
	fi

    ui_print " "
    ui_print "   ################======================== 40% готово!"

	if [ $STEP5 = true ]; then
     if [ -f $APII ]; then
		audio_platform_int
	 elif [ -f $APIE ]; then
        audio_platform_ext
     elif [ -f $API ]; then
        audio_platform_info
     fi
	fi

	if [ $STEP6 = true ]; then
		companders
	fi

    ui_print " "
    ui_print "   ########################================ 60% готово!"

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
    ui_print "   ################################======== 80% готово!"

	if [ $STEP9 = true ]; then
		dirac
	fi

	if [ $STEP10 = true ]; then
		fluence
	fi
	
	if [ $STEP11 = true ]; then
		mixer
	fi
	
	if [ $STEP12 = true ]; then
		decoenco
	fi
	
	if [ $STEP13 = true ]; then
		hifi
	fi
	
	if [ $STEP14 = true ]; then
		bt_parameters
	fi
	
    ui_print " "
    ui_print " - Всё готово! С любовью, NLSound Team. - "
    ui_print " "
fi