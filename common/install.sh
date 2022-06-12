MODID="NLSound"

MIRRORDIR="/data/local/tmp/NLSound"

OTHERTMPDIR="/dev/NLSound"

patch_xml() {
  case "$2" in
    *mixer_paths*.xml) [ $MIXNUM -gt 5 ] || sed -i "\$apatch_xml $1 \$MODPATH$(echo $2 | sed "s|$MODPATH||") '$3' \"$4\"" $MODPATH/.aml.sh;;
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

if [ -f /system/system/build.prop ]; then 
SYSTEM="/system/system"; 
elif [ -f /system_root/system/build.prop ]; then 
SYSTEM="/system_root/system"; 
elif [ -f /system/build.prop ]; then  
SYSTEM="/system"; 
fi


BOOTMODE_CHECKER() {
[ -z $BOOTMODE ] && ps | grep zygote | grep -qv grep && BOOTMODE=true
[ -z $BOOTMODE ] && ps -A 2>/dev/null | grep zygote | grep -qv grep && BOOTMODE=true
[ -z $BOOTMODE ] && BOOTMODE=false
}

if [ $BOOTMODE != true ] && [ -n "$(cat /etc/fstab | grep /vendor)" ]; then 
FVENDOR=true; 
elif [ $BOOTMODE != true ] && [ -d $SYSTEM/vendor ]; then 
FVENDOR=false; 
VENDOR="$SYSTEM/vendor"; 
else 
VENDOR="/vendor"; 
fi

SBPROP="$SYSTEM/build.prop";
VBPROP="$VENDOR/build.prop";
BPROPCHECKER="$SBPROP $VBPROP"

PROPS="$SYSTEM/default.prop $SYSTEM/build.prop $VENDOR/build.prop /data/local.prop /default.prop /build.prop"

GET_ROUTE_PROP() {
case $1 in
-pm) grep -m1 "^$3=" "$2" | cut -d= -f2 | cut -d ' ' -f1;;
*) grep -m1 "^$2=" "$1" | cut -d= -f2;;
esac
}

GET_PROP() {
for f in $PROPS; do
if [ -e "$f" ]; then
PROP="$(GET_ROUTE_PROP "$f" "$1")"
if [ -n "$PROP" ]; then
break
fi
fi
done
if [ -z "$PROP" ]; then
getprop "$1" | cut -c1-
else
printf "$PROP"
fi
}

ARCH_CHECKER() {
DARCH="$(GET_PROP "ro.product.cpu.abi")"
case "$DARCH" in
*x86_64*) arch="x86_64"; libarch="lib64"; ui_print "Warning, Arch $arch Not Supported!";;
*x86*) arch="x86"; libarch="lib"; ui_print "Warning, Arch $arch Not Supported!";;
*arm64*) arch="arm64"; libarch="lib64";;
*armeabi*) arch="arm"; libarch="lib";;
*) arch="unknown"; ui_print "Warning, $arch Not Supported/Found!";;
esac
AAPT="$AADDONS/aapt-$arch"
XMLSTARLET="$AADDONS/xmlstarlet-$arch"
SQLITE3="$TMPDIR/SQLite3/sqlite3-$arch"
FKEYCHECK="$ADDONS/keycheck-$arch"
TINYMIX="$AADDONS/tinymix-$arch"
}

SD617=$(grep "ro.board.platform=msm8952" $BPROPCHECKER)
SD625=$(grep "ro.board.platform=msm8953" $BPROPCHECKER)
SD660=$(grep "ro.board.platform=sdm660" $BPROPCHECKER)
SD662=$(grep "ro.board.platform=bengal" $BPROPCHECKER)
SD665=$(grep "ro.board.platform=trinket" $BPROPCHECKER)
SD670=$(grep "ro.board.platform=sdm670" $BPROPCHECKER)
SD710=$(grep "ro.board.platform=sdm710" $BPROPCHECKER)
SD720G=$(grep "ro.board.platform=atoll" $BPROPCHECKER)
SD730G=$(grep "ro.board.platform=sm6150" $BPROPCHECKER)
SD765G=$(grep "ro.board.platform=lito" $BPROPCHECKER)
SD820=$(grep "ro.board.platform=msm8996" $BPROPCHECKER)
SD835=$(grep "ro.board.platform=msm8998" $BPROPCHECKER)
SD845=$(grep "ro.board.platform=sdm845" $BPROPCHECKER)
SD855=$(grep "ro.board.platform=msmnile" $BPROPCHECKER)
SD865=$(grep "ro.board.platform=kona" $BPROPCHECKER)
SD888=$(grep "ro.board.platform=lahaina" $BPROPCHECKER)
SM8450=$(grep "ro.board.platform=taro" $BPROPCHECKER)

if [ "$SD662" ] || [ "$SD665" ] || [ "$SD670" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730G" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ] || [ "$SM8450" ]; then
  HIFI=true
ui_print " "
ui_print "- Device with support Hi-Fi detected! -"
else
  HIFI=false
ui_print " "
ui_print " - Device without support Hi-Fi detected! -"
fi

RN5PRO=$(grep -E "ro.product.vendor.device=whyred.*" $BPROPCHECKER)
RN6PRO=$(grep -E "ro.product.vendor.device=tulip.*" $BPROPCHECKER)
R7Y3=$(grep -E "ro.product.vendor.device=onclite.*" $BPROPCHECKER)
RN7=$(grep -E "ro.product.vendor.device=lavender.*" $BPROPCHECKER)
RN7PRO=$(grep -E "ro.product.vendor.device=violet.*" $BPROPCHECKER)
RN8=$(grep -E "ro.product.vendor.device=ginkgo.*" $BPROPCHECKER)
RN8T=$(grep -E "ro.product.vendor.device=willow.*" $BPROPCHECKER)
RN9S=$(grep -E "ro.product.vendor.device=curtana.*" $BPROPCHECKER)
RN9PRO=$(grep -E "ro.product.vendor.device=joyeuse.*" $BPROPCHECKER)
RN95G=$(grep -E "ro.product.vendor.device=cannon.*" $BPROPCHECKER)
RN9T=$(grep -E "ro.product.vendor.device=cannong.*" $BPROPCHECKER)
R9T=$(grep -E "ro.product.vendor.device=lime.*" $BPROPCHECKER)

RN10PROMAX=$(grep -E "ro.product.vendor.device=sweetin.*" $BPROPCHECKER)
RN10PRO=$(grep -E "ro.product.vendor.device=sweet.*" $BPROPCHECKER)
RK305G=$(grep -E "ro.product.vendor.device=picasso.*" $BPROPCHECKER)
RK304G=$(grep -E "ro.product.vendor.device=phoenix.*" $BPROPCHECKER)
RK30U=$(grep -E "ro.product.vendor.device=cezanne.*" $BPROPCHECKER)
RK30i5G=$(grep -E "ro.product.vendor.device=picasso48m.*" $BPROPCHECKER)
RK40=$(grep -E "ro.product.vendor.device=alioth.*" $BPROPCHECKER)

MI9SE=$(grep -E "ro.product.vendor.device=grus.*" $BPROPCHECKER)
MICC9E=$(grep -E "ro.product.vendor.device=laurus.*" $BPROPCHECKER)
MICC9=$(grep -E "ro.product.vendor.device=pyxis.*" $BPROPCHECKER)
MINOTECC9PRO=$(grep -E "ro.product.vendor.device=tucana.*" $BPROPCHECKER)
MINOTE10LITE=$(grep -E "ro.product.vendor.device=toco.*" $BPROPCHECKER)
MINOTE10LITEZOOM=$(grep -E "ro.product.vendor.device=vangogh.*" $BPROPCHECKER)
MI9=$(grep -E "ro.product.vendor.device=cepheus.*" $BPROPCHECKER)
MI9T=$(grep -E "ro.product.vendor.device=davinci.*" $BPROPCHECKER)
MI10=$(grep -E "ro.product.vendor.device=umi.*" $BPROPCHECKER)
MI10Ultra=$(grep -E "ro.product.vendor.device=cas.*" $BPROPCHECKER)
MI10i5GRN95G=$(grep -E "ro.product.vendor.device=gauguin.*" $BPROPCHECKER)
MI10LITE=$(grep -E "ro.product.vendor.device=vangogh.*" $BPROPCHECKER)
MI10T=$(grep -E "ro.product.vendor.device=apollo.*" $BPROPCHECKER)
MI10PRO=$(grep -E "ro.product.vendor.device=cmi.*" $BPROPCHECKER)
MI11=$(grep -E "ro.product.vendor.device=venus.*" $BPROPCHECKER)
MI11Lite5G=$(grep -E "ro.product.vendor.device=renoir.*" $BPROPCHECKER)
MI11Lite4G=$(grep -E "ro.product.vendor.device=courbet.*" $BPROPCHECKER)
K20P=$(grep -E "ro.product.vendor.device=raphael.*|ro.product.vendor.device=raphaelin.*|ro.product.vendor.device=raphaels.*" $BPROPCHECKER)
MI8=$(grep -E "ro.product.vendor.device=dipper.*" $BPROPCHECKER)
MI8P=$(grep -E "ro.product.vendor.device=equuleus.*" $BPROPCHECKER)
MI9P=$(grep -E "ro.product.vendor.device=crux.*" $BPROPCHECKER)

MIA2LITE=$(grep -E "ro.product.vendor.device=daisy.*" $BPROPCHECKER)
MIA2=$(grep -E "ro.product.vendor.device=jasmine.*" $BPROPCHECKER)
MIA3=$(grep -E "ro.product.vendor.device=laurel.*" $BPROPCHECKER)

POCOF1=$(grep -E "ro.product.vendor.device=beryllium.*" $BPROPCHECKER)
POCOF2P=$(grep -E "ro.product.vendor.device=lmi.*" $BPROPCHECKER)
POCOF3=$(grep -E "ro.product.vendor.device=alioth.*" $BPROPCHECKER)
POCOF3P=$(grep -E "ro.product.vendor.device=vayu.*" $BPROPCHECKER)
POCOM2P=$(grep -E "ro.product.vendor.device=gram.*" $BPROPCHECKER)
POCOM3=$(grep -E "ro.product.vendor.device=citrus.*" $BPROPCHECKER)
POCOX3=$(grep -E "ro.product.vendor.device=surya.*" $BPROPCHECKER)
POCOX3Pro=$(grep -E "ro.product.vendor.device=vayu.*" $BPROPCHECKER)

ONEPLUS7=$(grep -E "ro.product.vendor.device=guacamoleb.*" $BPROPCHECKER)
ONEPLUS7PRO=$(grep -E "ro.product.vendor.device=guacamole.*" $BPROPCHECKER)
ONEPLUS7TPRO=$(grep -E "ro.product.vendor.device=hotdog.*" $BPROPCHECKER)
ONEPLUS7T=$(grep -E "ro.product.vendor.device=hotdogb.*" $BPROPCHECKER)
ONEPLUS8=$(grep -E "ro.product.vendor.device=instantnoodle.*" $BPROPCHECKER)
ONEPLUS8PRO=$(grep -E "ro.product.vendor.device=instantnoodlep.*" $BPROPCHECKER)
ONEPLUS8T=$(grep -E "ro.product.vendor.device=kebab.*" $BPROPCHECKER)
ONEPLUSNORD=$(grep -E "ro.product.vendor.device=avicii.*" $BPROPCHECKER)
ONEPLUS99PRO9R=$(grep -E "ro.product.vendor.device=lemonade.*" $BPROPCHECKER)

DEVICE=$(getprop ro.product.vendor.device)

ACONF="$(find $SYSTEM $VENDOR -type f -name "audio_configs*.xml")"
AECFGS="$(find $SYSTEM $VENDOR -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
MPATHS="$(find $SYSTEM $VENDOR -type f -name "mixer_paths*.xml")"
APIXML="$(find $SYSTEM $VENDOR -type f -name "audio_platform_info*.xml")"
APIIXML="$(find $SYSTEM $VENDOR -type f -name "audio_platform_info_intcodec*.xml")"
APIEXML="$(find $SYSTEM $VENDOR -type f -name "audio_platform_info_extcodec*.xml")"
DEVFEA="$VENDOR/etc/device_features/$DEVICE.xml"; 
IOPOLICY="$(find $SYSTEM $VENDOR -type f -name "audio_io_policy.conf")"
AUDIOPOLICY="$(find $SYSTEM $VENDOR -type f -name "audio_policy_configuration.xml")"
SNDTRGS="$(find $SYSTEM $VENDOR -type f -name "*sound_trigger_mixer_paths*.xml")"

# destinations
MODAPC=`find $MODPATH/system -type f -name *policy*.conf`
MODAPX=`find $MODPATH/system -type f -name *policy*.xml`
MODAPI=`find $MODPATH/system -type f -name *audio*platform*info*.xml`

NEWdirac=$MODPATH/common/NLSound/newdirac

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

VOLUMES=false
MICROPHONES=false
HIGHBIT=false
COMPANDERS=false
LOLMIXER=false

deep_buffer() {
echo -e '\n#PATCH DEEP BUFFER
audio.deep_buffer.media=false
vendor.audio.deep_buffer.media=false
qc.audio.deep_buffer.media=false
ro.qc.audio.deep_buffer.media=false
persist.vendor.audio.deep_buffer.media=false
vendor.audio.feature.deepbuffer_as_primary.enable=false' >> $MODPATH/system.prop

for OACONF in $ACONF; do
ACONF="$MODPATH$(echo $OACONF | sed "s|^$VENDOR|$SYSTEM/vendor|g")"
patch_xml -u $ACONF '/configs/property[@name="audio.deep_buffer.media"]' "false"
done
}

audio_codec() {
if find $SYSTEM $VENDOR -type f -name "audio_configs*.xml" >/dev/null; then
for OACONF in $ACONFS; do
ACONF="$MODPATH$(echo $OACONF | sed "s|^$VENDOR|$SYSTEM/vendor|g")"
mkdir -p `dirname $ACONF`
cp -f $MAGISKMIRROR$OACONF $ACONF
sed -i 's/\t/  /g' $ACONF
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

device_features() {
if find $SYSTEM $VENDOR -type f -name "$DEVICE*.xml" >/dev/null; then
for ODEVFEA in $DEVFEA; do 
DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^$VENDOR|$SYSTEM/vendor|g")"
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
 fi
}

mixer_modify(){
for OMIX in ${MPATHS}; do
MIX="$MODPATH$(echo $OMIX | sed "s|^$VENDOR|$SYSTEM/vendor|g")"
mkdir -p `dirname $MIX`
cp -f $MAGISKMIRROR$OMIX $MIX
sed -i 's/\t/  /g' $MIX

if $VOLUMES; then
patch_xml -u $MIX '/mixer/ctl[@name="RX0 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX1 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX2 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX3 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX4 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX5 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX6 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX7 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX8 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX0 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX1 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX2 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX3 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX4 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX5 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX6 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX7 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX8 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX0 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX1 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX2 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX3 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX4 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX5 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX6 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX7 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX8 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX0 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX1 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX2 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX3 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX4 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX5 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX6 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX7 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX8 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX0 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX1 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX2 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX3 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX4 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX5 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX6 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX7 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="RX_RX8 Mix Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX0 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX1 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX2 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX3 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX0 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX1 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX2 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX3 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX4 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX5 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX6 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX7 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX8 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX0 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX1 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX2 Digital Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX3 Digital Volume"]' "90"
echo -e '\nro.config.media_vol_steps=30' >> $MODPATH/system.prop
fi

if $MICROPHONES; then
patch_xml -u $MIX '/mixer/ctl[@name="ADC1 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="ADC2 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="ADC3 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="ADC4 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="DEC0 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="DEC1 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="DEC2 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="DEC3 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="DEC4 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="DEC5 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="DEC6 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="DEC7 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="DEC8 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC0 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC1 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC2 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC3 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC4 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC5 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC6 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC7 Volume"]' "90"
patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC8 Volume"]' "90"
patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="ADC1 Volume"]' "12"
patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="ADC2 Volume"]' "12"
patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="ADC3 Volume"]' "12"
patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="ADC1 Volume"]' "12"
patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="ADC3 Volume"]' "12"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX0"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX1"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX2"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX3"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX4"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX5"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX6"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX7"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX8"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX9"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX10"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="DMIC MUX11"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX0"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX1"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX2"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX3"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX4"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX5"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX6"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX7"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX8"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX9"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX10"]' "ZERO"
patch_xml -u $MIX '/mixer/ctl[@name="AMIC MUX11"]' "ZERO"
fi

if $HIGHBIT; then

if find $SYSTEM $VENDOR -type f -name "audio_platform_info*.xml" >/dev/null; then
for OAPIXML in $APIXML; do
APIXMLF="$MODPATH$(echo $OAPIXML | sed "s|^/vendor|/system/vendor|g")"
mkdir -p `dirname $APIXMLF`
cp -f $MAGISKMIRROR$OAPIXMLF $APIXMLF
sed -i 's/\t/  /g' $APIXMLF
if $HIFI; then
patch_xml -s $APIXMLF '/audio_platform_info/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIXMLF '/audio_platform_info/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIXMLF '/audio_platform_info/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
patch_xml -s $APIXMLF '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER"]' "bit_width=32"
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES\" bit_width=\"32\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_REVERSE\" bit_width=\"32\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_PROTECTED\" bit_width=\"32\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES_44_1\" bit_width=\"32\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_SPEAKER\" bit_width=\"32\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_HEADPHONES\" bit_width=\"32\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_BT_A2DP\" bit_width=\"32\" \/>' $APIXMLF
patch_xml -s $APIXMLF '/audio_platform_info/app_types/app[@mode="default"]' "bit_width=32"
patch_xml -s $APIXMLF '/audio_platform_info/app_types/app[@mode="default"]' "max_rate=192000"
if [ ! "$(grep '<app_types>' $APIXMLF)" ]; then
sed -i 's/<\/audio_platform_info>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"69936\" max_rate=\"192000\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info>/' $APIXMLF  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIXMLF)" ] || sed -i '/<audio_platform_info>/,/<\/audio_platform_info>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}' $APIXMLF
done
fi
else
patch_xml -s $APIXMLF '/audio_platform_info/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIXMLF '/audio_platform_info/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIXMLF '/audio_platform_info/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES\" bit_width=\"24\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_REVERSE\" bit_width=\"24\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_PROTECTED\" bit_width=\"24\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES_44_1\" bit_width=\"24\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_SPEAKER\" bit_width=\"24\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_HEADPHONES\" bit_width=\"24\" \/>' $APIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_BT_A2DP\" bit_width=\"24\" \/>' $APIXMLF
patch_xml -s $APIXMLF '/audio_platform_info/app_types/app[@mode="default"]' "bit_width=24"
patch_xml -s $APIXMLF '/audio_platform_info/app_types/app[@mode="default"]' "max_rate=192000"
if [ ! "$(grep '<app_types>' $APIXMLF)" ]; then
sed -i 's/<\/audio_platform_info>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info>/' $APIXMLF  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIXMLF)" ] || sed -i '/<audio_platform_info>/,/<\/audio_platform_info>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}' $APIXMLF
done
fi
fi
done
fi

if find $SYSTEM $VENDOR -type f -name "audio_platform_info_intcodec*.xml" >/dev/null; then
for OAPIIXMLF in $APIIXML; do
APIIXMLF="$MODPATH$(echo $OAPIIXMLF | sed "s|^/vendor|/system/vendor|g")"
mkdir -p `dirname $APIXMLF`
cp -f $MAGISKMIRROR$OAPIIXMLF $APIIXMLF
sed -i 's/\t/  /g' $APIIXMLF
if $HIFI; then
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER"]' "bit_width=32"
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES\" bit_width=\"32\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_REVERSE\" bit_width=\"32\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_PROTECTED\" bit_width=\"32\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES_44_1\" bit_width=\"32\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_SPEAKER\" bit_width=\"32\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_HEADPHONES\" bit_width=\"32\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_BT_A2DP\" bit_width=\"24\" \/>' $APIIXMLF
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/app_types/app[@mode="default"]' "bit_width=32"
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/app_types/app[@mode="default"]' "max_rate=192000"
if [ ! "$(grep '<app_types>' $APIIXMLF)" ]; then
sed -i 's/<\/audio_platform_info_intcodec>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"69936\" max_rate=\"192000\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info_intcodec>/' $APIIXMLF  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info_intcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIIXMLF)" ] || sed -i '/<audio_platform_info_intcodec>/,/<\/audio_platform_info_intcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}' $APIIXMLF
done
fi
else
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES\" bit_width=\"24\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_REVERSE\" bit_width=\"24\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_PROTECTED\" bit_width=\"24\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES_44_1\" bit_width=\"24\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_SPEAKER\" bit_width=\"24\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_HEADPHONES\" bit_width=\"24\" \/>' $APIIXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_BT_A2DP\" bit_width=\"24\" \/>' $APIIXMLF
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/app_types/app[@mode="default"]' "bit_width=24"
patch_xml -s $APIIXMLF '/audio_platform_info_intcodec/app_types/app[@mode="default"]' "max_rate=192000"
if [ ! "$(grep '<app_types>' $APIIXMLF)" ]; then
sed -i 's/<\/audio_platform_info_intcodec>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info_intcodec>/' $APIIXMLF  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info_intcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIIXMLF)" ] || sed -i '/<audio_platform_info_intcodec>/,/<\/audio_platform_info_intcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}' $APIIXMLF
done
fi
fi
done
fi

if find $SYSTEM $VENDOR -type f -name "audio_platform_info_extcodec*.xml" >/dev/null; then
for OAPIEXMLF in $APIEXML; do
APIEXMLF="$MODPATH$(echo $OAPIEXMLF | sed "s|^/vendor|/system/vendor|g")"
mkdir -p `dirname $APIEXMLF`
cp -f $MAGISKMIRROR$OAPIEXMLF $APIEXMLF
sed -i 's/\t/  /g' $APIEXMLF
if $HIFI; then
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER"]' "bit_width=32"
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES\" bit_width=\"32\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_REVERSE\" bit_width=\"32\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_PROTECTED\" bit_width=\"32\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES_44_1\" bit_width=\"32\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_SPEAKER\" bit_width=\"32\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_HEADPHONES\" bit_width=\"32\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_BT_A2DP\" bit_width=\"32\" \/>' $APIEXMLF
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/app_types/app[@mode="default"]' "bit_width=32"
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/app_types/app[@mode="default"]' "max_rate=192000"
if [ ! "$(grep '<app_types>' $APIEXMLF)" ]; then
sed -i 's/<\/audio_platform_info_extcodec>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"69936\" max_rate=\"192000\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info_extcodec>/' $APIEXMLF  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIEXMLF)" ] || sed -i '/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"32\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}' $APIEXMLF
done
fi
else
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/config_params/param[@key="hifi_filter"]' "true"
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/config_params/param[@key="perf_lock_opts"]' "0, 0x0, 0x0, 0x0, 0x0"
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES\" bit_width=\"24\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_REVERSE\" bit_width=\"24\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_SPEAKER_PROTECTED\" bit_width=\"24\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_HEADPHONES_44_1\" bit_width=\"24\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_SPEAKER\" bit_width=\"24\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_GAME_HEADPHONES\" bit_width=\"24\" \/>' $APIEXMLF
sed -i 's/<\/audio_platform_info>/  <bit_width_configs> \n   <device name=\"SND_DEVICE_OUT_BT_A2DP\" bit_width=\"24\" \/>' $APIEXMLF
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/app_types/app[@mode="default"]' "bit_width=24"
patch_xml -s $APIEXMLF '/audio_platform_info_extcodec/app_types/app[@mode="default"]' "max_rate=192000"
if [ ! "$(grep '<app_types>' $APIEXMLF)" ]; then
sed -i 's/<\/audio_platform_info>/  <app_types> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n<app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info_extcodec>/' $APIEXMLF  
else
for i in 69936 69940; do
[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APIEXMLF)" ] || sed -i '/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}' $APIEXMLF
done
fi
fi
done
fi

for OMIX in ${MPATHS}; do
MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
patch_xml -s $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -s $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -s $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
patch_xml -s $MIX '/mixer/path[@name="echo-reference headset"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -s $MIX '/mixer/path[@name="echo-reference headset"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
patch_xml -s $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -s $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "KHZ_96"
patch_xml -s $MIX '/mixer/ctl[@name="Display Port RX Bit Format"]' "S24_3LE"
patch_xml -s $MIX '/mixer/ctl[@name="Display Port RX SampleRate"]' "KHZ_192"

if $HIFI; then
patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_0 RX Format"]' "DSD_DOP"
patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 Channels"]' "Two"
patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_5 RX Format"]' "DSD_DOP"
patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 SampleRate"]' "KHZ_192"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_0 RX Format"]' "DSD_DOP"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_0 TX Format"]' "DSD_DOP"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_TX_0 Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_TX_0 SampleRate"]' "KHZ_192"
patch_xml -s $MIX '/mixer/ctl[@name="TX_CDC_DMA_TX_3 Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX SampleRate"]' "KHZ_96"
if [ "$ONEPLUS7" ] || [ "$ONEPLUS7PRO" ] || [ "$ONEPLUS7TPRO" ] || [ "$ONEPLUS7T" ] || [ "$ONEPLUS8" ] || [ "$ONEPLUS8T" ] || [ "$ONEPLUS8TPRO" ] || [ "$ONEPLUSNORD" ] || [ "$ONEPLUS9PRO9R" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="PRIM_MI2S_RX Format"]' "S24_3LE"
patch_xml -s $MIX '/mixer/ctl[@name="PRIM_MI2S_TX Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_RX Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_RX SampleRate"]' "KHZ_192"
patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_TX Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="QUAT_MI2S_RX Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="QUAT_MI2S_TX Format"]' "S32_LE"
patch_xml -u $MIX '/mixer/ctl[@name="TERT_MI2S_RX Format"]' "S24_3LE"
patch_xml -u $MIX '/mixer/ctl[@name="TERT_MI2S_TX Format"]' "S24_3LE"
patch_xml -s $MIX '/mixer/ctl[@name="QUIN_MI2S_RX Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="QUIN_MI2S_TX Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="PRI_TDM_RX_0 Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="PRI_TDM_TX_0 Format"]' "S32_LE"
patch_xml -s $MIX '/mixer/ctl[@name="PRI_TDM_RX_0 SampleRate"]' "KHZ_176P4"
fi
else
patch_xml -s $MIX '/mixer/ctl[@name="INT0_MI2S_RX Format"]' "S24_3LE"
patch_xml -s $MIX '/mixer/ctl[@name="INT0_MI2S_RX SampleRate"]' "KHZ_192"
patch_xml -s $MIX '/mixer/ctl[@name="INT4_MI2S_RX Format"]' "S24_3LE"
patch_xml -s $MIX '/mixer/ctl[@name="INT3_MI2S_TX SampleRate"]' "KHZ_96"
fi

echo -e '#24-bit fixation by NLSound Team
persist.vendor.audio_hal.dsp_bit_width_enforce_mode=24
persist.audio_hal.dsp_bit_width_enforce_mode=24
vendor.audio_hal.dsp_bit_width_enforce_mode=24
audio_hal.dsp_bit_width_enforce_mode=24
ro.vendor.audio_hal.dsp_bit_width_enforce_mode=24
ro.audio_hal.dsp_bit_width_enforce_mode=24
qcom.vendor.audio_hal.dsp_bit_width_enforce_mode=24
qcom.audio_hal.dsp_bit_width_enforce_mode=24
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
vendor.audio.dsd.sw.encoder.24bit=true
audio.offload.pcm.16bit.enable=true
audio.offload.pcm.24bit.enable=true
audio.offload.pcm.32bit.enable=true
audio.offload.pcm.64bit.enable=true
vendor.audio.offload.pcm.16bit.enable=true
vendor.audio.offload.pcm.24bit.enable=true
vendor.audio.offload.pcm.32bit.enable=true
vendor.audio.offload.pcm.64bit.enable=true' >> $MODPATH/system.prop
done

for OSNDTRG in ${SNDTRGS}; do
STG="$MODPATH$(echo $OSNDTRG | sed "s|^/vendor|/system/vendor|g")"
mkdir -p `dirname $STG`
cp -f $MAGISKMIRROR$OSNDTRG $STG
sed -i 's/\t/  /g' $STG
patch_xml -s $STG '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -s $STG '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
patch_xml -s $STG '/mixer/path[@name="echo-reference headset"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -s $STG '/mixer/path[@name="echo-reference headset"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
patch_xml -s $STG '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
patch_xml -s $STG '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "KHZ_96"
done

sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIXMLF
sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIIXMLF
sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIEXMLF
fi

if $COMPANDERS; then
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

if $LOLMIXER; then
if $HIFI; then
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

if $HIFI; then
patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
patch_xml -u $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-hifi-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-highquality-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-lowpower-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
patch_xml -u $MIX '/mixer/path[@name="hph-class-ab-mode"]/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
else
patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "HD2"
patch_xml -u $MIX '/mixer/ctl[@name="RX HPH HD2 Mode"]' "On"
fi

if [ "$POCOX3" ]; then
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME LEFT"]' "78"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE LEFT"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP LEFT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP LEFT"]' "3"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X RX MODE LEFT"]' "Speaker"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE LEFT"]' "15"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT LEFT"]' "66"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME RIGHT"]' "78"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE RIGHT"]' "7"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP RIGHT"]' "0"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP RIGHT"]' "3"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE RIGHT"]' "15"
patch_xml -s $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT RIGHT"]' "66"
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
fi
done
}

io_policy(){
for OIOPOLICY in $IOPOLICY; do
IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^$VENDOR|$SYSTEM/vendor|g")"
mkdir -p `dirname $IOPOLICY`
cp -f $MAGISKMIRROR$OIOPOLICY $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
done
}

audio_policy() {
for OAUDIOPOLICY in $AUDIOPOLICY; do
AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^$VENDOR|$SYSTEM/vendor|g")"
mkdir -p `dirname $AUDIOPOLICY`
cp -f $MAGISKMIRROR$OAUDIOPOLICY $AUDIOPOLICY
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
persist.audio.hifi.volume=72
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
persist.vendor.audio.delta.refresh=true" >> $MODPATH/system.prop
}

improve_bluetooth() {
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
}

install_function() {	
	  clear_screen
	  ui_print " "
	  ui_print " - You selected Manual mode - "
	  ui_print " "
	  ui_print " - Configurate me, pls >.< - "
	  ui_print " "
	  
	  ui_print "***************************************************"
	  ui_print "* [1/13]                                          *"
	  ui_print "*                   Deep Buffer                   *"
	  ui_print "*                                                 *"
	  ui_print "*             When you click *Install*,           *"
	  ui_print "*           you will disable deep buffer.         *"
	  ui_print "*  He is engaged in increasing the number of low  *"
	  ui_print "*      frequencies by losing detail in them.      *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
		STEP1=true
		sed -i 's/STEP1=false/STEP1=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [2/13]                                          *"
	  ui_print "*            Improving volume levels              *"
	  ui_print "*         and change media volume steps           *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "*      you will increase the volume levels        *"
	  ui_print "*          (wired headphones, speakers)           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  VOLUMES=true
	  sed -i 's/VOLUMES=false/VOLUMES=true/g' $SETTINGS
	  sed -i 's/STEP2=false/STEP2=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [3/13]                                          *"
	  ui_print "*         Improving microphones levels            *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "* you will increase the volume of the microphones *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  MICROPHONES=true
	  sed -i 's/MICROPHONES=false/MICROPHONES=true/g' $SETTINGS
	  sed -i 's/STEP3=false/STEP3=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [4/13]                                          *"
	  ui_print "*          Patching audio platform files          *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "*          you activate this mechanism.           *"
	  ui_print "*                                                 *"
	  ui_print "* Confirming this option will allow the module to *"
	  ui_print "*      use a different audio codec algorithm      *"
	  ui_print "* for your favorite songs, and will also improve  *"
	  ui_print "*    the sound quality during video recording     *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  STEP4=true
	  HIGHBIT=true
	  sed -i 's/STEP4=false/STEP4=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [5/13]                                          *"
	  ui_print "*             Disabling сompanders                *"
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
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  COMPANDERS=true
	  sed -i 's/STEP5=false/STEP5=true/g' $SETTINGS
	  sed -i 's/COMPANDERS=false/COMPANDERS=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [6/13]                                          *"
	  ui_print "*       Configurating interal audio codec         *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "*           you will apply the changes.           *"
	  ui_print "*                                                 *"
	  ui_print "*           This option will configure            *"
	  ui_print "*       your device's internal audio codec.       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	   STEP6=true
	   sed -i 's/STEP6=false/STEP6=true/g' $SETTINGS
	fi
	 
	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [7/13]                                          *"
	  ui_print "*         Patching device_features files          *"
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
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
		STEP7=true
		sed -i 's/STEP7=false/STEP7=true/g' $SETTINGS
	fi

	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [9/13]                                          *"
	  ui_print "*         Other patches in mixer_paths            *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "*           you will apply the changes.           *"
	  ui_print "*                                                 *"
	  ui_print "*     Global sound changes by adjusting the       *"
	  ui_print "*        internal codec of the device.            *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  LOLMIXER=true
	  sed -i 's/LOLMIXER=false/LOLMIXER=true/g' $SETTINGS
	  sed -i 's/STEP9=false/STEP9=true/g' $SETTINGS
	fi
	  
	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [10/13]                                         *"
	  ui_print "*              Tweaks in prop file                *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "*           you will apply the changes.           *"
	  ui_print "*                                                 *"
	  ui_print "*    This option will change the sound quality    *"
	  ui_print "*                  the most.                      *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  STEP10=true
	  sed -i 's/STEP10=false/STEP10=true/g' $SETTINGS
	fi
	
	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [11/13]                                         *"
	  ui_print "*               Improve Bluetooth                 *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "*           you will apply the changes.           *"
	  ui_print "*                                                 *"
	  ui_print "*   This option will improve the audio quality    *"
	  ui_print "*    in Bluetooth, as well as fix the problem     *"
	  ui_print "*      of disappearing the AAC codec switch       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  STEP11=true
	  sed -i 's/STEP11=false/STEP11=true/g' $SETTINGS
	fi
	
	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [12/13]                                         *"
	  ui_print "*              Switch audio output                *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "*           you will apply the changes.           *"
	  ui_print "*                                                 *"
	  ui_print "*  This option will switch DIRECT to DIRECT_PCM,  *"
	  ui_print "*      which will improve the sound detail.       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  STEP12=true
	  sed -i 's/STEP12=false/STEP12=true/g' $SETTINGS
	fi
	
	ui_print " "
	ui_print " "
	  ui_print "***************************************************"
	  ui_print "* [13/13]                                         *"
	  ui_print "*              Turn off useless DRC               *"
	  ui_print "*                                                 *"
	  ui_print "*            When you click *Install*,            *"
	  ui_print "*          you disable this mechanism.            *"
	  ui_print "*                                                 *"
	  ui_print "* DRC Limits the dynamic range of the soundtrack  *"
	  ui_print "*       (the difference between the loudest       *"
	  ui_print "*             and the quietest sounds)            *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "  "
	sleep 1
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	  STEP13=true
	  sed -i 's/STEP13=false/STEP13=true/g' $SETTINGS
	fi

	clear_screen
	ui_print " "
	ui_print " - Processing. . . . -"
	ui_print " "
	ui_print " - You can minimize Magisk and use the device normally -"
	ui_print " - and then come back here to reboot and apply the changes. -"
	ui_print " "
	
	if $STEP1; then
		deep_buffer
	fi
	
	if $STEP4; then
		audio_platform_info
	fi

    ui_print " "
    ui_print "   ########================================ 20% done!"
 
	if $STEP6; then
		audio_codec
	fi
	
	if $STEP7; then
      device_features
	fi
	
    ui_print " "
    ui_print "   ################======================== 40% done!"
	
	if $STEP10; then
		prop
	fi
  
    ui_print " "
    ui_print "   ########################================ 60% done!"
	
	mixer_modify
	
	if $STEP11; then
		improve_bluetooth
	fi
	
	if $STEP12; then
		io_policy
	fi

    ui_print " "
    ui_print "   ################################======== 80% done!"
	
	if $STEP13; then
		audio_policy
	fi

	if $STEP4; then
		addon_settings
	fi
}


addon_settings() {
	clear_screen

	ui_print " "
	ui_print " - You have confirmed the setting for 24-bit audio. (STEP4)"
	ui_print " - Do you want to install an add-on for this item "
	ui_print " - from a third-party author?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = Install, Vol Down = Skip"
	ui_print " "
	if chooseport 60; then
	clear_screen

	ui_print " "
	ui_print " - Running 24-bit addons ..."
	ui_print " "
	ui_print " - Credits: Rei Ryuki | https://t.me/androidryukimods "
	ui_print " "

	sleep 3

	clear_screen

	ui_print " 1. Download TERMINAL app in Play Market"
	ui_print " 2. Enter su to get superuser rights"
	ui_print " 3. Enter the commands you need in the terminal."
	ui_print " ========================================================="
	sleep 3
	ui_print "          C O M M A N D S            "
	ui_print " "
	ui_print " "
	ui_print " setprop hires.primary 1                        "
	ui_print " - Enable Hi-Res to low latency "
	ui_print " playback (primary) output..."
	sleep 2
	ui_print " ---------------------------------------------------------"
	ui_print " setprop hires.32 1                                "
	ui_print " - Forcing audio format PCM to "
	ui_print " 32 bit instead of 24 bit..."
	sleep 2
	ui_print " ---------------------------------------------------------"
	ui_print " setprop hires.float 1                                "
	ui_print " - Enable audio format PCM float..."
	sleep 2
	ui_print " ---------------------------------------------------------"
	ui_print " setprop speaker.bit 16                                   "
	ui_print " - Forcing audio format PCM 16 bit "
	ui_print " to internal speaker..."
	sleep 2
	ui_print " ---------------------------------------------------------"
	ui_print " setprop sample.rate 88                                "
	ui_print " - Forcing sample rate to 88200.."
	ui_print " - Possible values: 88, 96, 128, 176, 192, 352, 384"
	sleep 2
	ui_print " "
	ui_print " ========================================================="
	ui_print " "
	ui_print " Press the volume key UP as soon "
	ui_print " as you finish entering commands."
	ui_print " ========================================================="
	ui_print " Or press the volume down button if "
	ui_print " you don't want to install the addon."
	ui_print " "

	if chooseport 60; then
	clear_screen
	ui_print " - Processing . . . Please, wait . . . "
	ui_print " "

	sed -i 's/addon_install=0/addon_install=1/g' $SETTINGS

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

	ui_print " "
	ui_print " - Addon succesfully installed!"
	sleep 1
	fi
	fi
}


if [ "$(getprop ro.hardware 2>/dev/null)" == "qcom" ]; then
	install_function
fi
	SET_PERM_RM
	
	ui_print " "
    ui_print "   ######################################## 100% done!"
	
    ui_print " "
    ui_print " - All done! With love, NLSound Team. - "
    ui_print " "