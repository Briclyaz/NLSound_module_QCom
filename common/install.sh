#!/bin/bash

MODID="NLSound"
MIRRORDIR="/data/local/tmp/NLSound"
OTHERTMPDIR="/dev/NLSound"
PROP=$MODPATH/system.prop
RESTORE_SETTINGS="/data/adb/modules/NLSound/settings.nls"
VERSION=$(grep "^version=" /data/adb/modules_update/NLSound/module.prop | cut -d'=' -f2-)
if [ ! -f "$RESTORE_SETTINGS" ]; then
  RESTORE_SETTINGS="/storage/emulated/0/NLSound/settings.nls"
fi

LANG=$(settings get system system_locales)
DEVICE=$(getprop ro.product.vendor.device)
if [ "$DEVICE" == "mivendor" ]; then
  DEVICE=$(getprop ro.product.product.name) #mi14ultra - aurora, mi13ultra - ishtar
fi
PROCESSOR=$(getprop ro.board.platform)
ACDB="https://github.com/Briclyaz/NLSound_module_acdb_addon/raw/refs/heads/main/$DEVICE.zip"
ACDBDIR="$MODPATH/system/vendor/etc/acdbdata"
SEPARATOR="———————————————————————————————————————————"

while IFS= read -r file; do
  case "$file" in
  */audio_configs*.xml) ACONFS="$ACONFS$file"$'\n' ;;
  */"$DEVICE".xml) DEVFEAS="$DEVFEAS$file"$'\n' ;;
  */DeviceFeatures.xml) DEVFEASNEW="$DEVFEASNEW$file"$'\n' ;;
  */*audio_policy_configuration*.xml) AUDIOPOLICYS="$AUDIOPOLICYS$file"$'\n' ;;
  */media_codecs_c2_audio.xml | */media_codecs_google_audio.xml | */media_codecs_google_c2_audio.xml) MCODECS="$MCODECS$file"$'\n' ;;
  */media_codecs_dolby_audio.xml) DCODECS="$DCODECS$file"$'\n' ;;
  */audio_io_policy.conf) IOPOLICYS="$IOPOLICYS$file"$'\n' ;;
  */audio_output_policy.conf) OUTPUTPOLICYS="$OUTPUTPOLICYS$file"$'\n' ;;
  */*resourcemanager*.xml) RESOURCES="$RESOURCES$file"$'\n' ;;
  */dap-*.xml | */dax-*.xml | */*dolby_dax*.xml) DAXES="$DAXES$file"$'\n' ;;
  */*mixer_paths*.xml) MPATHS="$MPATHS$file"$'\n' ;;
  */audio_platform_info*.xml) APIXMLS="$APIXMLS$file"$'\n' ;;
  */audio_effects*.xml) AEFFECTXMLS="$AEFFECTXMLS$file"$'\n' ;;
  */microphone_characteristics*.xml) MICXARS="$MICXARS$file"$'\n' ;;
  */*AudioEffectCenter*.apk | */*AudioFX*.apk | */*MusicFX*.apk | */*SamsungDAP*.apk) APPS="$APPS$file"$'\n' ;;
  */*Headset_cal.acdb | */*Hdmi_cal.acdb | */*Bluetooth_cal.acdb | */*Speaker_cal.acdb | */*General_cal.acdb | */*Global_cal.acdb) OLDACDBS="$OLDACDBS$file"$'\n' ;;
  */maximum_substreams) SUBSTREAMS="$SUBSTREAMS$file"$'\n' ;;
  */high_perf_mode | */impedance_detect_en) SUSFLAGS="$SUSFLAGS$file"$'\n' ;;
  esac
done < <(find /system /vendor /system_ext /mi_ext /product /odm /my_product /sys/module -type f \( \
  -name "audio_configs*.xml" -o \
  -name "$DEVICE.xml" -o \
  -name "DeviceFeatures.xml" -o \
  -name "*audio_policy_configuration*.xml" -o \
  -name "media_codecs_c2_audio.xml" -o \
  -name "media_codecs_google_audio.xml" -o \
  -name "media_codecs_google_c2_audio.xml" -o \
  -name "media_codecs_dolby_audio.xml" -o \
  -name "audio_io_policy.conf" -o \
  -name "audio_output_policy.conf" -o \
  -name "*resourcemanager*.xml" -o \
  -name "dap-*.xml" -o \
  -name "dax-*.xml" -o \
  -name "*dolby_dax*.xml" -o \
  -name "*mixer_paths*.xml" -o \
  -name "audio_platform_info*.xml" -o \
  -name "audio_effects*.xml" -o \
  -name "microphone_characteristics*.xml" -o \
  -name "*Headset_cal.acdb" -o \
  -name "*Hdmi_cal.acdb" -o \
  -name "*Bluetooth_cal.acdb" -o \
  -name "*Speaker_cal.acdb" -o \
  -name "*General_cal.acdb" -o \
  -name "*Global_cal.acdb" -o \
  -name "*AudioEffectCenter*.apk" -o \
  -name "*AudioFX*.apk" -o \
  -name "*MusicFX*.apk" -o \
  -name "*SamsungDAP*.apk" -o \
  -name "high_perf_mode" -o \
  -name "impedance_detect_en" -o \
  -name "maximum_substreams" \
  \) -print 2>/dev/null)

handle_input() {
  while true; do
    case $(timeout 0.01 getevent -lqc 1 2>/dev/null) in
    *KEY_VOLUMEUP*DOWN*)
      ui_print "up"
      return
      ;;
    *KEY_VOLUMEDOWN*DOWN*)
      ui_print "down"
      return
      ;;
    esac
  done
}

show_menu() {
  local selected=1
  local total=$#
  if [ $total -eq 2 ]; then
    while true; do
      case $(handle_input) in
      "up") return 1 ;;
      "down") return 2 ;;
      esac
    done
  else
    while true; do
      eval "local current=\"\$$selected\""
      ui_print "➔ $current"
      ui_print " "
      case $(handle_input) in
      "up") selected=$((selected % total + 1)) ;;
      "down")
        ui_print "$SELECTE $current"
        break
        ;;
      esac
    done
    return $selected
  fi
}

check_version() {
  version=$(grep -m1 '^Module version: ' "$1" | cut -d' ' -f3-) || return 1
  [ -z "$version" ] && return 1
  major=$(echo "$version" | sed 's/v\([0-9]*\).*/\1/; s/[^0-9]//g; q')
  minor=$(echo "$version" | sed 's/.*\.\([0-9]*\).*/\1/; s/[^0-9]//g; q')
  [ -z "$minor" ] && minor=0
  if [ "$major" -gt 4 ] || { [ "$major" -eq 4 ] && [ "$minor" -gt 3 ]; }; then
    return 0
  fi
  test_num=$(echo "$version" | sed -n 's/.*test-\([0-9]\{4,\}\).*/\1/p')
  [ -n "$test_num" ] && [ "$test_num" -gt 1454 ] && return 0
  return 1
}

VOLSTEPS=false
VOLMEDIA=false
VOLMIC=false
BITNES=false
SAMPLERATE=false
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
PATCHACDB=false
DELETEACDB=false

# import language strings
if [[ "$LANG" =~ "en-RU" ]] || [[ "$LANG" =~ "ru-" ]]; then
  source "$MODPATH/common/russiantext.sh"
elif [[ "$LANG" =~ "zh-" ]]; then
  source "$MODPATH/common/chinatext.sh"
else
  source "$MODPATH/common/englishtext.sh"
fi

for MIX in ${MPATHS}; do
  if [[ "$FOUND_IIR" != "true" ]] && grep -q 'name="IIR0 Band1" id ="0" value="' "$MIX"; then
    FOUND_IIR=true
  fi
  if [[ "$FLOAT_LE" != "true" ]] && grep -q 'FLOAT_LE' "$MIX"; then
    FLOAT_LE=true
  fi
  if [[ "$FOUND_IIR" == "true" ]] && [[ "$FLOAT_LE" == "true" ]]; then
    break
  fi
done

continue_script=true
if [ -f "$RESTORE_SETTINGS" ] && check_version "$RESTORE_SETTINGS"; then
  echo -e "\n\n$SEPARATOR\n$RESTORE\n$SEPARATOR\n"
  show_menu $SMENU
  if [ $? -eq 1 ]; then
    continue_script=false
    old_modpath=$MODPATH
    source "$RESTORE_SETTINGS"
    MODPATH=$old_modpath
    export SAMPLERATE BITNES VOLMIC VOLMEDIA VOLSTEPS STEP6 STEP7 STEP8 STEP9 STEP10 STEP11 STEP12 STEP13 STEP14 STEP15 PATCHACDB DELETEACDB
  else
    echo -e "$SMENUSKIP\n\n\n"
    sleep 0.3
  fi
fi
if [ $continue_script == true ]; then
  echo -e "\n$STRINGSTEP1"
  show_menu $SMENU1
  case $? in
  1) VOLSTEPS="false" ;;
  2) VOLSTEPS="30" ;;
  3) VOLSTEPS="50" ;;
  4) VOLSTEPS="100" ;;
  esac

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP2"
  show_menu $SMENU2
  case $? in
  1) VOLMEDIA="false" ;;
  2) VOLMEDIA="78" ;;
  3) VOLMEDIA="84" ;;
  4) VOLMEDIA="90" ;;
  5) VOLMEDIA="96" ;;
  6) VOLMEDIA="102" ;;
  7) VOLMEDIA="108" ;;
  esac

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP3"
  show_menu $SMENU2
  case $? in
  1) VOLMIC="false" ;;
  2) VOLMIC="78" ;;
  3) VOLMIC="84" ;;
  4) VOLMIC="90" ;;
  5) VOLMIC="96" ;;
  6) VOLMIC="102" ;;
  7) VOLMIC="108" ;;
  esac

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP4"
  show_menu $SMENU4
  case $? in
  1) BITNES="false" ;;
  2) BITNES="16" ;;
  3) BITNES="24" ;;
  4) BITNES="32" ;;
  5) BITNES="float" ;;
  esac

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP5"
  show_menu $SMENU5
  case $? in
  1) SAMPLERATE="false" ;;
  2) SAMPLERATE="44100" ;;
  3) SAMPLERATE="48000" ;;
  4) SAMPLERATE="96000" ;;
  5) SAMPLERATE="192000" ;;
  6) SAMPLERATE="384000" ;;
  esac

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP6\n$SEPARATOR\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP6=true

  echo -e "\n\n\n$SEPARATOR\n$STRINGSTEP7\n$SEPARATOR"
  if [ -n "$DEVFEASNEW" ] || [ -n "$DEVFEAS" ]; then
    echo -e "$INSTALLSKIP\n$SEPARATOR"
    show_menu $SMENU
    [ $? -eq 1 ] && STEP7=true
  else
    echo -e "$SMENUAUTOSKIP\n$SEPARATOR"
  fi

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP8\n$SEPARATOR\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP8=true

  echo -e "\n\n\n$SEPARATOR\n$STRINGSTEP9\n$SEPARATOR\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP9=true

  echo -e "\n\n\n$SEPARATOR\n$STRINGSTEP10\n$SEPARATOR\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP10=true

  echo -e "\n\n\n$SEPARATOR\n$STRINGSTEP11"
  if [ -n "$IOPOLICYS" ] || [ -n "$OUTPUTPOLICYS" ]; then
    echo -e "$INSTALLSKIP\n$SEPARATOR"
    show_menu $SMENU
    [ $? -eq 1 ] && STEP11=true
  else
    echo -e "$SMENUAUTOSKIP\n$SEPARATOR"
  fi

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP12"
  if [ "$FOUND_IIR" == "true" ]; then
    echo -e "$INSTALLSKIP\n$SEPARATOR"
    show_menu $SMENU
    [ $? -eq 1 ] && STEP12=true
  else
    echo -e "$SMENUAUTOSKIP\n$SEPARATOR"
  fi

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP13\n"
  show_menu $SMENU13
  case $? in
  1) STEP13="false" ;;
  2) STEP13="part" ;;
  3) STEP13="full" ;;
  esac

  echo -e "\n\n\n\n$SEPARATOR\n$STRINGSTEP14\n$SEPARATOR\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP14=true

  echo -e "\n\n\n$SEPARATOR\n$STRINGSTEP15"
  if { [ -n "$DAXES" ] || [ -n "$DCODECS" ]; } && [ "$STEP13" == "false" ]; then
    echo -e "$INSTALLSKIP\n$SEPARATOR\n"
    show_menu $SMENU
    [ $? -eq 1 ] && STEP15=true
  else
    echo -e "$SMENUAUTOSKIP\n$SEPARATOR\n"
  fi

  echo -e "\n\n\n$SEPARATOR\n\n[16/16]\n"
  if [ -n "$OLDACDBS" ]; then
    ui_print "$STRINGSTEP16"
    show_menu $SMENU16
    case $? in
    1) DELETEACDB="false" ;;
    2) DELETEACDB="Basic" ;;
    3) DELETEACDB="General" ;;
    4) DELETEACDB="Speaker" ;;
    esac
  else
    echo -e "$STRINGSTEP161\n\n$SEPARATOR"
    case "$DEVICE" in alioth* | Pong* | marble* | RE5465* | mondrian* | ishtar* | aurora* | REE2B2L1*)
      echo -e "$INSTALLSKIP\n$SEPARATOR\n"
      show_menu $SMENU
      [ $? -eq 1 ] && PATCHACDB=true
      ;;
    *)
      echo -e "$SMENUAUTOSKIP\n$SEPARATOR\n"
      ;;
    esac
  fi
fi
echo -e "\n\n"
final_print_text
ui_print " "

# Writing settings
mkdir -p "/storage/emulated/0/NLSound" && echo -e "#installer options\n#Below you can see the decoding of the names of the points,\n#or trust the numerical values of the points.\n\n#STEP1=Select volume steps\n#STEP2=Increase media volumes\n#STEP3=Improving microphones sensitivity\n#STEP4=Select audio format (16..float)\n#STEP5=Select sampling rates (96..384000)\n#STEP6=Turn off sound interference\n#STEP7=Patching device_features files\n#STEP8=Other patches in mixer_paths files\n#STEP9=Tweaks for build.prop files\n#STEP10=Improve bluetooth\n#STEP11=Switch audio output (DIRECT -> DIRECT_PCM)\n#STEP12=Install custom preset for iir\n#STEP13=Ignore all audio effects\n#STEP14=Install experimental tweaks for tinymix\n#STEP15=Configure Dolby Atmos\n#PATCHACDB=Install patched ACDB files\n#DELETEACDB=Deleting acdb files\n\nModule version: $VERSION\nDevice: $DEVICE\n\nVOLSTEPS=$VOLSTEPS\nVOLMEDIA=$VOLMEDIA\nVOLMIC=$VOLMIC\nBITNES=$BITNES\nSAMPLERATE=$SAMPLERATE\nSTEP6=$STEP6\nSTEP7=$STEP7\nSTEP8=$STEP8\nSTEP9=$STEP9\nSTEP10=$STEP10\nSTEP11=$STEP11\nSTEP12=$STEP12\nSTEP13=$STEP13\nSTEP14=$STEP14\nSTEP15=$STEP15\nPATCHACDB=$PATCHACDB\nDELETEACDB=$DELETEACDB" >"/storage/emulated/0/NLSound/settings.nls" && cp_ch -f "/storage/emulated/0/NLSound/settings.nls" "$MODPATH/settings.nls"

case "$SAMPLERATE" in
"44100") RATE="KHZ_44P1" max_rate_192="KHZ_44P1" max_rate_96="KHZ_44P1" ;;
"48000") RATE="KHZ_48" max_rate_192="KHZ_48" max_rate_96="KHZ_48" ;;
"96000") RATE="KHZ_96" max_rate_192="KHZ_96" max_rate_96="KHZ_96" ;;
"192000") RATE="KHZ_192" max_rate_192="KHZ_192" max_rate_96="KHZ_96" ;;
"384000") RATE="KHZ_384" max_rate_192="KHZ_192" max_rate_96="KHZ_96" ;;
esac
case "$BITNES" in
"16") bit_width="16" max_bit_width_24="16" FORMAT="S16_LE" max_format_24="S16_LE" apc_format="AUDIO_FORMAT_PCM_16_BIT" res_format="PAL_AUDIO_FMT_PCM_S16_LE" ;;
"24") bit_width="24" max_bit_width_24="24" FORMAT="S24_LE" max_format_24="S24_LE" apc_format="AUDIO_FORMAT_PCM_24_BIT_PACKED" res_format="PAL_AUDIO_FMT_PCM_S24_LE" ;;
"32") bit_width="32" max_bit_width_24="24" FORMAT="S32_LE" max_format_24="S24_LE" apc_format="AUDIO_FORMAT_PCM_32_BIT" res_format="PAL_AUDIO_FMT_PCM_S32_LE" ;;
"float")
  FORMAT="$([[ "$FLOAT_LE" == "true" ]] && echo "FLOAT_LE" || echo "S32_LE")"
  max_format_24="$([[ "$FLOAT_LE" == "true" ]] && echo "FLOAT_LE" || echo "S24_LE")"
  bit_width="32" max_bit_width_24="24" apc_format="AUDIO_FORMAT_PCM_FLOAT" res_format="PAL_AUDIO_FMT_PCM_FLOAT_LE"
  ;;
esac
case "$DELETEACDB" in
"Basic") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb") ;;
"General") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb|.*General_cal.acdb|.*Global_cal.acdb") ;;
"Speaker") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb|.*General_cal.acdb|.*Speaker_cal.acdb|.*Global_cal.acdb") ;;
esac

for OAPIXML in ${APIXMLS}; do
  {
    APIXML="$MODPATH$(echo $OAPIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch "$ORIGDIR$OAPIXML" "$APIXML"
    if [ "$BITNES" != "false" ]; then
      sed -i 's/device name="SND_DEVICE_OUT_SPEAKER" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER" bit_width="'$bit_width'"/g' $APIXML
      sed -i 's/device name="SND_DEVICE_OUT_HEADPHONES" bit_width=".*"/device name="SND_DEVICE_OUT_HEADPHONES" bit_width="'$bit_width'"/g' $APIXML
      sed -i 's/device name="SND_DEVICE_OUT_SPEAKER_REVERSE" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER_REVERSE" bit_width="'$bit_width'"/g' $APIXML
      sed -i 's/device name="SND_DEVICE_OUT_SPEAKER_PROTECTED" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER_PROTECTED" bit_width="'$bit_width'"/g' $APIXML
      sed -i 's/device name="SND_DEVICE_OUT_HEADPHONES_44_1" bit_width=".*"/device name="SND_DEVICE_OUT_HEADPHONES_44_1" bit_width="'$bit_width'"/g' $APIXML
      sed -i 's/device name="SND_DEVICE_OUT_GAME_SPEAKER" bit_width=".*"/device name="SND_DEVICE_OUT_GAME_SPEAKER" bit_width="'$bit_width'"/g' $APIXML
      sed -i 's/device name="SND_DEVICE_OUT_GAME_HEADPHONES" bit_width=".*"/device name="SND_DEVICE_OUT_GAME_HEADPHONES" bit_width="'$bit_width'"/g' $APIXML
      sed -i 's/device name="SND_DEVICE_OUT_BT_A2DP" bit_width=".*"/device name="SND_DEVICE_OUT_BT_A2DP" bit_width="'$bit_width'"/g' $APIXML
      sed -i 's/\(app uc_type=".*" mode="default" bit_width="\)[^"]*"/\1'$bit_width'"/g' $APIXML
    fi
    if [ "$SAMPLERATE" != "false" ]; then
      sed -i 's/\(app uc_type=".*" mode="default" bit_width=".*" id=".*" max_rate="\)[^"]*"/\1'$SAMPLERATE'"/g' $APIXML
    fi
    if [ "$STEP6" == "true" ]; then
      sed -i 's/param key="native_audio_mode" value=".*"/param key="native_audio_mode" value="multiple_mix_dsp"/g' $APIXML
      sed -i 's/param key="hfp_pcm_dev_id" value=".*"/param key="hfp_pcm_dev_id" value="39"/g' $APIXML
      sed -i 's/param key="input_mic_max_count" value=".*"/param key="input_mic_max_count" value="4"/g' $APIXML
      sed -i 's/param key="true_32_bit" value=".*"/param key="true_32_bit" value="true"/g' $APIXML
      sed -i 's/param key="hifi_filter" value=".*"/param key="hifi_filter" value="true"/g' $APIXML
      sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIXML
      sed -i 's/param key="config_spk_protection" value=".*"/param key="config_spk_protection" value="false"/g' $APIXML
    fi
  } &
done

if [ "$STEP6" == "true" ]; then
  {
    echo -e "\n
persist.vendor.audio.speaker.prot.enable=false
vendor.audio.feature.spkr_prot.enable=false
persist.config.speaker_protect_enabled=0" >>$PROP
    #patching audio_configs.xml
    for OACONFS in ${ACONFS}; do
      ACFG="$MODPATH$(echo $OACONFS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch $ORIGDIR$OACONFS $ACFG
      sed -i 's/"spkr_protection" value="true"/"spkr_protection" value="false"/g' $ACFG
      sed -i 's/"audio.deep_buffer.media" value="true"/"audio.deep_buffer.media" value="false"/g' $ACFG
      sed -i 's/"audio.offload.disable" value="false"/"audio.offload.disable" value="true"/g' $ACFG
      sed -i 's/"audio.offload.min.duration.secs" value="*."/"audio.offload.min.duration.secs" value="30"/g' $ACFG
      sed -i 's/"audio.offload.video" value="true"/"audio.offload.video" value="false"/g' $ACFG
      sed -i 's/"persist.vendor.audio.sva.conc.enabled" value="true"/"persist.vendor.audio.sva.conc.enabled" value="false"/g' $ACFG
      sed -i 's/"persist.vendor.audio.va_concurrency_enabled" value="true"/"persist.vendor.audio.va_concurrency_enabled" value="false"/g' $ACFG
      sed -i 's/"vendor.audio.av.streaming.offload.enable" value="true"/"vendor.audio.av.streaming.offload.enable" value="false"/g' $ACFG
      sed -i 's/"vendor.audio.offload.track.enable" value="true"/"vendor.audio.offload.track.enable" value="false"/g' $ACFG
      sed -i 's/"vendor.audio.offload.multiple.enabled" value="true"/"vendor.audio.offload.multiple.enabled" value="false"/g' $ACFG
      sed -i 's/"vendor.audio.rec.playback.conc.disabled" value="true"/"vendor.audio.rec.playback.conc.disabled" value="false"/g' $ACFG
      sed -i 's/"vendor.voice.conc.fallbackpath" value="*."/"vendor.voice.conc.fallbackpath" value=""/g' $ACFG
      sed -i 's/"vendor.voice.dsd.playback.conc.disabled" value="true"/"vendor.voice.dsd.playback.conc.disabled" value="false"/g' $ACFG
      sed -i 's/"vendor.voice.path.for.pcm.voip" value="true"/"vendor.voice.path.for.pcm.voip" value="false"/g' $ACFG
      sed -i 's/"vendor.voice.playback.conc.disabled" value="true"/"vendor.voice.playback.conc.disabled" value="false"/g' $ACFG
      sed -i 's/"vendor.voice.record.conc.disabled" value="true"/"vendor.voice.record.conc.disabled" value="false"/g' $ACFG
      sed -i 's/"vendor.voice.voip.conc.disabled" value="true"/"vendor.voice.voip.conc.disabled" value="false"/g' $ACFG
      sed -i 's/"audio_extn_formats_enabled" value="false"/"audio_extn_formats_enabled" value="true"/g' $ACFG
      sed -i 's/"audio_extn_hdmi_spk_enabled" value="false"/"audio_extn_hdmi_spk_enabled" value="true"/g' $ACFG
      sed -i 's/"use_xml_audio_policy_conf" value="false"/"use_xml_audio_policy_conf" value="true"/g' $ACFG
      sed -i 's/"voice_concurrency" value="true"/"voice_concurrency" value="false"/g' $ACFG
      sed -i 's/"afe_proxy_enabled" value="false"/"afe_proxy_enabled" value="true"/g' $ACFG
      sed -i 's/"compress_voip_enabled" value="true"/"compress_voip_enabled" value="false"/g' $ACFG
      sed -i 's/"fm_power_opt" value="false"/"fm_power_opt" value="true"/g' $ACFG
      sed -i 's/"battery_listener_enabled" value="true"/"battery_listener_enabled" value="false"/g' $ACFG
      sed -i 's/"compress_capture_enabled" value="true"/"compress_capture_enabled" value="false"/g' $ACFG
      sed -i 's/"compress_metadata_needed" value="true"/"compress_metadata_needed" value="false"/g' $ACFG
      sed -i 's/"dynamic_ecns_enabled" value="false"/"dynamic_ecns_enabled" value="true"/g' $ACFG
      sed -i 's/"custom_stereo_enabled" value="false"/"custom_stereo_enabled" value="true"/g' $ACFG
      sed -i 's/"ext_hw_plugin_enabled" value="false"/"ext_hw_plugin_enabled" value="true"/g' $ACFG
      sed -i 's/"ext_qdsp_enabled" value="false"/"ext_qdsp_enabled" value="true"/g' $ACFG
      sed -i 's/"ext_spkr_enabled" value="false"/"ext_spkr_enabled" value="true"/g' $ACFG
      sed -i 's/"ext_spkr_tfa_enabled" value="false"/"ext_spkr_tfa_enabled" value="true"/g' $ACFG
      sed -i 's/"keep_alive_enabled" value="false"/"keep_alive_enabled" value="true"/g' $ACFG
      sed -i 's/"hifi_audio_enabled" value="false"/"hifi_audio_enabled" value="true"/g' $ACFG
      sed -i 's/"extn_resampler" value="false"/"extn_resampler" value="true"/g' $ACFG
      sed -i 's/"extn_flac_decoder" value="true"/"extn_flac_decoder" value="false"/g' $ACFG
      sed -i 's/"extn_compress_format" value="false"/"extn_compress_format" value="true"/g' $ACFG
      sed -i 's/"usb_offload_sidetone_vol_enabled" value="true"/"usb_offload_sidetone_vol_enabled" value="false"/g' $ACFG
      sed -i 's/"usb_offload_burst_mode" value="true"/"usb_offload_burst_mode" value="false"/g' $ACFG
      sed -i 's/"pcm_offload_enabled_16" value="true"/"pcm_offload_enabled_16" value="false"/g' $ACFG
      sed -i 's/"pcm_offload_enabled_24" value="true"/"pcm_offload_enabled_24" value="false"/g' $ACFG
      sed -i 's/"pcm_offload_enabled_32" value="true"/"pcm_offload_enabled_32" value="false"/g' $ACFG
      sed -i 's/"a2dp_offload_enabled" value="true"/"a2dp_offload_enabled" value="false"/g' $ACFG
      sed -i 's/"vendor.audio.use.sw.alac.decoder" value="false"/"vendor.audio.use.sw.alac.decoder" value="true"/g' $ACFG
      sed -i 's/"vendor.audio.use.sw.ape.decoder" value="false"/"vendor.audio.use.sw.ape.decoder" value="true"/g' $ACFG
      sed -i 's/"vendor.audio.use.sw.mpegh.decoder" value="false"/"vendor.audio.use.sw.mpegh.decoder" value="true"/g' $ACFG
      sed -i 's/"vendor.audio.flac.sw.decoder.24bit" value="false"/"vendor.audio.flac.sw.decoder.24bit" value="true"/g' $ACFG
      sed -i 's/"vendor.audio.hw.aac.encoder" value="false"/"vendor.audio.hw.aac.encoder" value="true"/g' $ACFG
      sed -i 's/"aac_adts_offload_enabled" value="true"/"aac_adts_offload_enabled" value="false"/g' $ACFG
      sed -i 's/"alac_offload_enabled" value="true"/"alac_offload_enabled" value="false"/g' $ACFG
      sed -i 's/"ape_offload_enabled" value="true"/"ape_offload_enabled" value="false"/g' $ACFG
      sed -i 's/"flac_offload_enabled" value="true"/"flac_offload_enabled" value="false"/g' $ACFG
      sed -i 's/"qti_flac_decoder" value="false"/"qti_flac_decoder" value="true"/g' $ACFG
      sed -i 's/"vorbis_offload_enabled" value="true"/"vorbis_offload_enabled" value="false"/g' $ACFG
      sed -i 's/"wma_offload_enabled" value="true"/"wma_offload_enabled" value="false"/g' $ACFG
    done
    #patching media codecs files
    for OMCODECS in ${MCODECS}; do
      MEDIACODECS="$MODPATH$(echo $OMCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch $ORIGDIR$OMCODECS $MEDIACODECS
      sed -i 's/name="sample-rate" ranges=".*"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
      sed -i 's/name="bitrate-modes" value="CBR"/name="bitrate-modes" value="CQ"/g' $MEDIACODECS
      sed -i 's/name="complexity" range="0-10"  default=".*"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
      sed -i 's/name="complexity" range="0-8"  default=".*"/name="complexity" range="0-8"  default="8"/g' $MEDIACODECS
      sed -i 's/name="quality" range="0-100"  default=".*"/name="quality" range="0-100"  default="100"/g' $MEDIACODECS
      sed -i 's/name="bitrate" range=".*"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
    done
    #patching resourcemanager files
    for OARESOURCES in ${RESOURCES}; do
      RES="$MODPATH$(echo $OARESOURCES | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch $ORIGDIR$OARESOURCES $RES
      sed -i 's/<speaker_protection_enabled>1/<speaker_protection_enabled>0/g' $RES
      sed -i 's/<ras_enabled>1/<ras_enabled>0/g' $RES
      sed -i 's/<param key="hifi_filter" value="false"/<param key="hifi_filter" value="true"/g' $RES
      sed -i 's/param key="native_audio_mode" value=".*"/param key="native_audio_mode" value="multiple_mix_dsp"/g' $RES
      sed -i 's/param key="oplus_ear_protection_enable" value=".*"/param key="oplus_ear_protection_enable" value="false"/g' $RES
      sed -i 's/<param lpi_enable="true"/<param lpi_enable="false"/g' $RES
      sed -i 's/param key="oplus_hdr_record" value="false"/param key="oplus_hdr_record" value="true"/g' $RES
      #sed -i 's/<fractional_sr>1/<fractional_sr>0/g' $RES need test
      sed -i '/<!--HIFI Filter Headphones-Uncomment this when param key hifi_filter is true/,/-->/{s/^ *<!--\(.*\)$/\1/; s/^\(.*\)-->/\1/; /^ *HIFI Filter Headphones-Uncomment this when param key hifi_filter is true *$/d}' $RES
      # [ "$R12P+", "$OP12" ]
      case "$DEVICE" in RE5C82L1* | RE5C3B* | OP595DL1*)
        sed -i 's/<ext_ec_ref_enabled>0/<ext_ec_ref_enabled>1/g' $RES
        ;;
      esac

      if [ "$SAMPLERATE" != "false" ]; then
        # [ "$R12P+" ]
        case "$DEVICE" in RE5C82L1* | RE5C3B*)
          if [ "$SAMPLERATE" != "44100" ] && [ "$SAMPLERATE" != "384000" ]; then #breaks the sound from the speakers at this sampling rate, on other devices it causes the speaker to fail
            sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /<id>PAL_DEVICE_OUT_SPEAKER<\/id>/!b; s/<samplerate>(44100|48000|96000|192000|384000)<\/samplerate>/<samplerate>'"$SAMPLERATE"'<\/samplerate>/g}' "$RES"
          fi
          ;;
        esac
        sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /<id>(PAL_DEVICE_NONE|PAL_DEVICE_OUT_ULTRASOUND|PAL_DEVICE_OUT_PROXY|PAL_DEVICE_OUT_WIRED_HEADSET|PAL_DEVICE_OUT_WIRED_HEADPHONE|PAL_DEVICE_OUT_HANDSET)<\/id>/!b; s/<samplerate>(44100|48000|96000|192000|384000)<\/samplerate>/<samplerate>'"$SAMPLERATE"'<\/samplerate>/g}' "$RES"
        #BT
        sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /<id>(PAL_DEVICE_OUT_BLUETOOTH_A2DP|PAL_DEVICE_OUT_BLUETOOTH_SCO)<\/id>/!b; s/<samplerate>(8000|44100|48000|96000|192000|384000)<\/samplerate>/<samplerate>'"$SAMPLERATE"'<\/samplerate>/g}' "$RES"
      fi
      if [ "$BITNES" != "false" ]; then
        sed -i "s/<supported_bit_format>.*</<supported_bit_format>$res_format</g" $RES
        sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /<id>(PAL_DEVICE_NONE|PAL_DEVICE_OUT_SPEAKER|PAL_DEVICE_OUT_ULTRASOUND|PAL_DEVICE_OUT_PROXY|PAL_DEVICE_OUT_WIRED_HEADSET|PAL_DEVICE_OUT_WIRED_HEADPHONE|PAL_DEVICE_OUT_HANDSET)<\/id>/!b; s/<bit_width>(16|24|32)<\/bit_width>/<bit_width>'"$bit_width"'<\/bit_width>/g}' "$RES"
        #changing the BT bit width leads to problems, so we only change the samplerate
      fi
    done
    #patching microphone_characteristics files
    for OMICXAR in ${MICXARS}; do
      MICXAR="$MODPATH$(echo $OMICXAR | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch "$ORIGDIR$OMICXAR" "$MICXAR"
      sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $MICXAR
    done
    #maximum_substream
    for OSUBSTREAM in ${SUBSTREAMS}; do
      SUBSTREAM="$MODPATH$(echo $OSUBSTREAM | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      mkdir -p "$(dirname "$SUBSTREAM")"
      echo "4096" >$SUBSTREAM
    done
    #other flags
    for OSUSFLAG in ${SUSFLAGS}; do
      SUSFLAG="$MODPATH$(echo $OSUSFLAG | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      mkdir -p "$(dirname "$SUSFLAG")"
      echo "1" >$SUSFLAG
    done
  } &
fi

if [ "$STEP7" == "true" ]; then
  {
    for ODEVFEA in ${DEVFEAS}; do
      DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch $ORIGDIR$ODEVFEA $DEVFEA
      sed -i 's/name="support_samplerate_48000" value=false/name="support_samplerate_48000" value=true/g' $DEVFEA
      sed -i 's/name="support_samplerate_96000" value=false/name="support_samplerate_96000" value=true/g' $DEVFEA
      sed -i 's/name="support_samplerate_192000" value=false/name="support_samplerate_192000" value=true/g' $DEVFEA
      sed -i 's/name="support_samplerate_352000" value=false/name="support_samplerate_352000" value=true/g' $DEVFEA
      sed -i 's/name="support_samplerate_384000" value=false/name="support_samplerate_384000" value=true/g' $DEVFEA
      sed -i 's/name="support_low_latency" value=false/name="support_low_latency" value=true/g' $DEVFEA
      sed -i 's/name="support_mid_latency" value=false/name="support_mid_latency" value=true/g' $DEVFEA
      sed -i 's/name="support_high_latency" value=false/name="support_high_latency" value=true/g' $DEVFEA
      sed -i 's/name="support_playback_device" value=false/name="support_playback_device" value=true/g' $DEVFEA
      sed -i 's/name="support_boost_mode" value=false/name="support_boost_mode" value=true/g' $DEVFEA
      sed -i 's/name="support_hifi" value=false/name="support_hifi" value=true/g' $DEVFEA
      sed -i 's/name="support_hd_record_param" value=false/name="support_hd_record_param" value=true/g' $DEVFEA
      sed -i 's/name="support_stereo_record" value=false/name="support_stereo_record" value=true/g' $DEVFEA
      sed -i 's/<bool name="support_samplerate_48000">false/<bool name="support_samplerate_48000">true/g' $DEVFEA
      sed -i 's/<bool name="support_samplerate_96000">false/<bool name="support_samplerate_96000">true/g' $DEVFEA
      sed -i 's/<bool name="support_samplerate_192000">false/<bool name="support_samplerate_192000">true/g' $DEVFEA
      sed -i 's/<bool name="support_samplerate_352000">false/<bool name="support_samplerate_352000">true/g' $DEVFEA
      sed -i 's/<bool name="support_samplerate_384000">false/<bool name="support_samplerate_384000">true/g' $DEVFEA
      sed -i 's/<bool name="support_low_latency">false/<bool name="support_hifi">true/g' $DEVFEA
      sed -i 's/<bool name="support_mid_latency">false/<bool name="support_mid_latency">true/g' $DEVFEA
      sed -i 's/<bool name="support_high_latency">false/<bool name="support_high_latency">true/g' $DEVFEA
      sed -i 's/<bool name="support_playback_device">false/<bool name="support_playback_device">true/g' $DEVFEA
      sed -i 's/<bool name="support_boost_mode">false/<bool name="support_boost_mode">true/g' $DEVFEA
      sed -i 's/<bool name="support_hifi">false/<bool name="support_hifi">true/g' $DEVFEA
      sed -i 's/<bool name="support_hd_record_param">false/<bool name="support_hd_record_param">true/g' $DEVFEA
      sed -i 's/<bool name="support_stereo_record">false/<bool name="support_stereo_record">true/g' $DEVFEA
      sed -i 's/<bool name="support_24bit_record">false/<bool name="support_24bit_record">true/g' $DEVFEA
      if [ "$STEP13" != "false" ]; then
        sed -i 's/name="support_dolby" value=true/name="support_dolby" value=false/g' $DEVFEA
        sed -i 's/<bool name="support_dolby">true/<bool name="support_dolby">false/g' $DEVFEA
      else
        sed -i 's/name="support_dolby" value=false/name="support_dolby" value=true/g' $DEVFEA
        sed -i 's/<bool name="support_dolby">false/<bool name="support_dolby">true/g' $DEVFEA
      fi
    done
    for ODEVFEANEW in ${DEVFEASNEW}; do
      DEVFEANEW="$MODPATH$(echo $ODEVFEANEW | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch $ORIGDIR$ODEVFEANEW $DEVFEANEW
      sed -i -e '1 s/^/<feature name="android.hardware.audio.pro"/>\n/;' $DEVFEANEW
      sed -i -e '2 s/^/<feature name="android.hardware.broadcastradio"/>\n/;' $DEVFEANEW
    done
  } &
fi

if [ "$STEP9" == "true" ]; then
  {
    echo -e "\n
# Better parameters audio by NLSound Team
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
vendor.qc2audio.suspend.enabled=false
vendor.qc2audio.per_frame.flac.dec.enabled=true
audio.decoder_override_check=true
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
vendor.audio.feature.extn_resampler.enable=true
vendor.audio.feature.extn_formats.enable=true
vendor.audio.feature.extn_flac_decoder.enable=true
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
vendor.audio.feature.battery_listener.enable=false
vendor.audio.feature.custom_stereo.enable=true
vendor.audio.feature.wsa.enable=true
vendor.audio.usb.super_hifi=true
ro.audio.hifi=true
ro.vendor.audio.hifi=true
persist.audio.hifi.int_codec=true
persist.audio.hifi_adv_support=1
ro.config.hifi_enhance_support=1
ro.config.hifi_config_state=1
ro.hardware.hifi.support=true
persist.audio.hifi=true
persist.audio.hifi.volume=90
persist.vendor.audio.hifi_enabled=true
persist.vendor.audio.hifi.int_codec=true
vendor.audio.keep_alive.disabled=false
ro.vendor.audio.elus.enable=true
ro.vendor.audio.3d.audio.support=true
ro.vendor.audio.surround.support=true
sys.vendor.atmos.passthrough=enable
ro.vendor.media.video.meeting.support=true
persist.vendor.audio.ambisonic.capture=true
persist.vendor.audio.ambisonic.auto.profile=true
audio.record.delay=0
vendor.voice.dsd.playback.conc.disabled=false
vendor.audio.3daudio.record.enable=true
ro.vendor.audio.recording.hd=true
ro.vendor.audio.sdk.ssr=true
ro.qc.sdk.audio.ssr=true
persist.vendor.audio.record.ull.support=true
vendor.usb.analog_audioacc_disabled=false
vendor.audio.enable.cirrus.speaker=true
vendor.audio.trace.enable=true
vendor.audio.powerhal.power.ul=true
vendor.audio.powerhal.power.dl=true
vendor.audio.hal.boot.timeout.ms=5000
vendor.audio.LL.coeff=100
vendor.audio.caretaker.at=true
vendor.audio.matrix.limiter.enable=0
vendor.audio.hal.output.suspend.supported=false
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.tfa9874.dsp.enabled=true
vendor.audio.lowpower=false
vendor.audio.compress_capture.enabled=false
vendor.audio.compress_capture.aac=false
vendor.audio.rt.mode=23
vendor.audio.rt.mode.onlyfast=false
vendor.media.support.mvc=true
ro.audio.resampler.psd.enable_at_samplerate=44100
ro.audio.resampler.psd.halflength=520
ro.audio.resampler.psd.stopband=194
ro.audio.resampler.psd.cutoff_percent=100
ro.audio.resampler.psd.tbwcheat=0
ro.audio.soundtrigger.lowpower=false
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
ro.vendor.media.support.ffmpeg.adec=true
ro.vendor.platform.support.av1=true
ro.vendor.platform.has.tuner=1
ro.vendor.platform.disable.audiorawout=false
ro.vendor.platform.has.realoutputmode=true
ro.vendor.platform.support.dts=true
ro.vendor.usb.support_analog_audio=true
ro.mediaserver.64b.enable=true
persist.audio.hp=true
persist.sys.audio.source=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.cca.enabled=false
persist.vendor.audio.misoundasc=true
persist.vendor.audio.okg_hotword_ext_dsp=true
persist.vendor.audio.format.24bit=true
persist.vendor.audio.speaker.stereo=true
persist.vendor.audio_hal.dsp_bit_width_enforce_mode=24
persist.vendor.audio.ll_playback_bargein=true
effect.reverb.pcm=1
audio.safemedia.bypass=true
" >>$PROP
    # [ "$ONEPLUS9R" ]
    if [[ "$DEVICE" != OnePlus9R* ]]; then
      echo -e "\n
vendor.audio.spkr_prot.tx.sampling_rate=96000
" >>$PROP
    fi
  } &
fi

if [ "$STEP10" == "true" ]; then
  {
    echo -e "\n
# Bluetooth parameters by NLSound Team
bluetooth.profile.a2dp.source.enabled=true
bluetooth.profile.bap.broadcast.assist.enabled=true
bluetooth.profile.bap.broadcast.source.enabled=true
bluetooth.profile.bap.unicast.client.enabled=true
bluetooth.profile.ccp.server.enabled=true
bluetooth.profile.csip.set_coordinator.enabled=true
bluetooth.profile.hap.client.enabled=true
bluetooth.profile.mcp.server.enabled=true
bluetooth.profile.vcp.controller.enabled=true
persist.bluetooth.a2dp_aac_abr.enable=false
persist.bluetooth.bluetooth_audio_hal.disabled=false
persist.bluetooth.dualconnection.supported=true
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.bt.a2dp.aac_disable=false
persist.bt.a2dp.aptx_hd_disable=false
persist.bt.power.down=false
persist.bt.sbc_hd_enabled=1
persist.service.btui.use_aptx=1
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true
persist.vendor.audio.sys.a2h_delay_for_a2dp=50
persist.vendor.bluetooth.prefferedrole=master
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
persist.vendor.bt.splita2dp.44_1_war=true
persist.vendor.btstack.enable.lpa=false
persist.vendor.qcom.bluetooth.a2dp_mcast_test.enabled=false
persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true
persist.vendor.qcom.bluetooth.aac_vbr_ctl.enabled=true
persist.vendor.qcom.bluetooth.aptxadaptiver2_1_support=true
persist.vendor.qcom.bluetooth.dualmode_transport_support=true
persist.vendor.qcom.bluetooth.enable.swb=true
persist.vendor.qcom.bluetooth.enable.swbpm=true
persist.vendor.qcom.bluetooth.lossless_aptx_adaptive_le.enabled=true
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
ro.vendor.audio.btsamplerate.adaptive=true
ro.vendor.bluetooth.csip_qti=true
vendor.bluetooth.ldac.abr=false
vendor.media.audiohal.btwbs=true
" >>$PROP
  } &
fi

if [ "$STEP13" == "part" ] || [ "$STEP13" == "full" ]; then
  {
    for OAPP in ${APPS}; do
      APP="$MODPATH$(echo $OAPP | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      mkdir -p "$(dirname "$APP")"
      touch "$APP"
    done
    echo -e "\n
# Disable all effects by NLSound Team
persist.sys.phh.disable_audio_effects=1
persist.sys.phh.disable_soundvolume_effect=1
audio.effect.a2dp.enable=0
vendor.audio.effect.a2dp.enable=0
vendor.audio.tunnel.encode=false
tunnel.audio.encode=false
tunnel.audiovideo.decode=false
tunnel.decode=false
qc.tunnel.audio.encode=false
ro.vendor.audio.soundfx.usb=false
ro.vendor.audio.sfx.speaker=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false
ro.vendor.audio.sfx.independentequalizer=false
ro.audio.spatializer_enabled=false
persist.vendor.audio.spatializer.speaker_enabled=false
vendor.audio.ignore_effects=true
persist.audio.ignore_effects=true
persist.vendor.audio.ignore_effects=true
ro.audio.disable_audio_effects=1
vendor.audio.disable_audio_effects=1
low.pass.filter=Off
middle.pass.filter=Off
high.pass.filter=Off
band.pass.filter=Off
LPF=Off
MPF=Off
HPF=Off
BPF=Off
# Fuck Misound process
ro.vendor.audio.soundfx.force_disabled=true
ro.vendor.audio.soundfx.force_bypass=true
ro.vendor.audio.misound.bluetooth.enable=false
ro.vendor.audio.sfx.harmankardon=false
ro.vendor.audio.sfx.scenario=false
ro.vendor.audio.game.mode=false
persist.vendor.audio.misoundasc=false
audio.deep_buffer.enable=false
persist.audio.global_fx=false
persist.audio.disable_effects=true
persist.audio.hq_fx=false
persist.audio.disable_equalizer=true
persist.audio.disable_srs=true
persist.audio.disable_bassboost=true
persist.audio.disable_virtualizer=true
persist.audio.disable_compression=true
persist.audio.dsp.enable=false
persist.audio.dual_mic=false
persist.audio.aec_enable=false
persist.audio.ns_enable=false
persist.audio.noise.suppression=false
persist.audio.volume.equalizer=false
persist.audio.volume.leveler=false
persist.audio.dts_effects=false
persist.audio.enable_ffv=false
persist.audio.biquad_filter=false
persist.audio.faux_effects=false
ro.vendor.dolby.dax.version=none
ro.vendor.audio.dolby.dax.support=false
ro.vendor.audio.dolby.surround.enable=false
ro.vendor.audio.dolby.fade_switch=false
ro.vendor.audio.dolby.dax3_3point8=false
ro.vendor.audio.nosupport_bt_dolby=true
ro.vendor.platform.support.dolby=false
persist.vendor.audio.dolby.disable=true
vendor.audio.dolby.ds2.enabled=false
persist.audio.disable_dolby=true" >>$PROP
    if [ "$STEP13" == "part" ]; then
      for OAEFFECTXML in ${AEFFECTXMLS}; do
        AEFFECTXML="$MODPATH$(echo "$OAEFFECTXML" | sed "s|^/vendor|/system/vendor|g; s|^/system_ext|/system/system_ext|g; s|^/product|/system/product|g; s|^/mi_ext|/system/mi_ext|g")"
        cp_ch "$ORIGDIR$OAEFFECTXML" "$AEFFECTXML"
        sed -i '/<effectProxy/,/<\/effectProxy>/d' "$AEFFECTXML"
        sed -i '/<libraries>/,/<\/libraries>/c\<libraries>\n    <library name="bundle" path="libbundlewrapper.so"/>\n    <library name="dynamics_processing" path="libdynproc.so"/>\n</libraries>' "$AEFFECTXML"
        sed -i '/<effects>/,/<\/effects>/c\<effects>\n    <effect name="volume" library="bundle" uuid="'"$(sed -n '/<effect name="volume"/ {s/.*uuid="\([^"]*\)".*/\1/p;q}' "$AEFFECTXML")"'"/>\n    <effect name="dynamics_processing" library="dynamics_processing" uuid="'"$(sed -n '/<effect name="dynamics_processing"/ {s/.*uuid="\([^"]*\)".*/\1/p;q}' "$AEFFECTXML")"'"/>\n</effects>' "$AEFFECTXML"
        sed -i '/<postprocess>/,/<\/postprocess>/c\<postprocess>\n</postprocess>' "$AEFFECTXML"
        sed -i '/<preprocess>/,/<\/preprocess>/c\<preprocess>\n</preprocess>' "$AEFFECTXML"
      done
    else
      echo -e "\nro.audio.ignore_effects=true" >>$PROP
    fi
  } &
fi

#patching audio_io_policy file
for OIOPOLICY in ${IOPOLICYS}; do
  {
    IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch $ORIGDIR$OIOPOLICY $IOPOLICY

    if [ "$STEP11" == "true" ]; then
      # Patching direct_pcm 24 and 32 bit routes, ignore 16-bit route only if DIRECT_PCM is not already present
      sed -i '/direct_pcm_24/,/compress_passthrough/{/AUDIO_OUTPUT_FLAG_DIRECT_PCM/!s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/}' "$IOPOLICY"
      sed -i '/compress_offload_24/,/inputs/{/AUDIO_OUTPUT_FLAG_DIRECT_PCM/!s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/}' "$IOPOLICY"
    fi
    
    if [ "$BITNES" != "false" ]; then
      for section in deep_buffer default voip_rx direct_pcm_16 direct_pcm_24 direct_pcm_32 compress_offload_16 compress_offload_24 default_24; do
        sed -i "/^  $section {/,/^  }/ {
          s/formats .*/formats $apc_format/
          s/bit_width .*/bit_width $bit_width/
        }" "$IOPOLICY"
      done
    fi

    if [ "$SAMPLERATE" != "false" ]; then
      for section in deep_buffer default voip_rx direct_pcm_16 direct_pcm_24 direct_pcm_32 compress_offload_16 compress_offload_24 default_24; do
        sed -i "/^  $section {/,/^  }/ {
          s/sampling_rates .*/sampling_rates $SAMPLERATE/
        }" "$IOPOLICY"
      done
    fi
  } &
done

#patching audio_output_policy file
for OOUTPUTPOLICY in ${OUTPUTPOLICYS}; do
  {
    OUTPUTPOLICY="$MODPATH$(echo $OOUTPUTPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch $ORIGDIR$OOUTPUTPOLICY $OUTPUTPOLICY

    if [ "$STEP11" == "true" ]; then
      # Patching direct_pcm 24 and 32 bit routes, ignore 16-bit route only if DIRECT_PCM is not already present
      sed -i '/direct_pcm_24/,/compress_passthrough/{/AUDIO_OUTPUT_FLAG_DIRECT_PCM/!s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/}' "$OUTPUTPOLICY"
      sed -i '/compress_offload_24/,/inputs/{/AUDIO_OUTPUT_FLAG_DIRECT_PCM/!s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/}' "$OUTPUTPOLICY"
    fi

    if [ "$BITNES" != "false" ]; then
      for section in deep_buffer default voip_rx direct_pcm_16 direct_pcm_24 direct_pcm_32 compress_offload_16 compress_offload_24 default_24; do
        sed -i "/^  $section {/,/^  }/ {
          s/formats .*/formats $apc_format/
          s/bit_width .*/bit_width $bit_width/
        }" "$OUTPUTPOLICY"
      done
    fi

    if [ "$SAMPLERATE" != "false" ]; then
      for section in deep_buffer default voip_rx direct_pcm_16 direct_pcm_24 direct_pcm_32 compress_offload_16 compress_offload_24 default_24; do
        sed -i "/^  $section {/,/^  }/ {
          s/sampling_rates .*/sampling_rates $SAMPLERATE/
        }" "$OUTPUTPOLICY"
      done
    fi
  } &
done

#patching audio_policy_configuration
for OAUDIOPOLICY in ${AUDIOPOLICYS}; do
  {
    AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch $ORIGDIR$OAUDIOPOLICY $AUDIOPOLICY
    if [ "$STEP6" == "true" ]; then
      sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
    fi
    if [ "$SAMPLERATE" != "false" ]; then
      sed -i -E "/<mixPort name=\"(raw|primary output|r_submix output|virtual output.*|voice_tx|voice_rx|usb_accessory output|deep_buffer|mmap_no_irq_out|direct_pcm|incall_music_uplink|usb_surround_sound)\"/,/<\/mixPort>/ {/<profile /{:$;N;/\/>/!b$;s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/}}" "$AUDIOPOLICY"
      sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_SPEAKER|AUDIO_DEVICE_OUT_REMOTE_SUBMIX|AUDIO_DEVICE_OUT_IP|AUDIO_DEVICE_OUT_USB_ACCESSORY|AUDIO_DEVICE_OUT_EARPIECE|AUDIO_DEVICE_OUT_WIRED_HEADSET|AUDIO_DEVICE_OUT_WIRED_HEADPHONE|AUDIO_DEVICE_OUT_LINE|AUDIO_DEVICE_OUT_TELEPHONY_TX|AUDIO_DEVICE_OUT_AUX_DIGITAL|AUDIO_DEVICE_OUT_PROXY|AUDIO_DEVICE_OUT_FM|AUDIO_DEVICE_OUT_USB_DEVICE|AUDIO_DEVICE_OUT_USB_HEADSET)\"[^>]*>/ {:a; N; /<\/devicePort>/!ba; s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/g}" "$AUDIOPOLICY"
      #BT
      sed -i -E "/<mixPort name=\"(hearing aid output|a2dp_lhdc output)\"/,/<\/mixPort>/ {/<profile /{:$;N;/\/>/!b$;s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/}}" "$AUDIOPOLICY"
      sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_BLUETOOTH_A2DP|AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_HEADPHONES|AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_SPEAKER)\"/,/<\/devicePort>/ {/<profile /{:$;N;/\/>/!b$;s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/}}" "$AUDIOPOLICY"
      sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_BLUETOOTH_SCO|AUDIO_DEVICE_OUT_BLUETOOTH_SCO_HEADSET|AUDIO_DEVICE_OUT_BLUETOOTH_SCO_CARKIT)\"[^>]*>/ {:a; N; /<\/devicePort>/!ba; s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/g}" "$AUDIOPOLICY"
    fi
    if [ "$BITNES" != "false" ]; then
      #changing the bit width on raw output causes problems in pubg
      sed -i -E "/<mixPort name=\"(primary output|r_submix output|virtual output.*|voice_tx|voice_rx|usb_accessory output|deep_buffer|mmap_no_irq_out|direct_pcm|incall_music_uplink|usb_surround_sound)\"/,/<\/mixPort>/ {/<profile /{:$;N;/\/>/!b$;s/format=\"[^\"]*\"/format=\"$apc_format\"/}}" "$AUDIOPOLICY"
      sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_SPEAKER|AUDIO_DEVICE_OUT_REMOTE_SUBMIX|AUDIO_DEVICE_OUT_IP|AUDIO_DEVICE_OUT_USB_ACCESSORY|AUDIO_DEVICE_OUT_EARPIECE|AUDIO_DEVICE_OUT_WIRED_HEADSET|AUDIO_DEVICE_OUT_WIRED_HEADPHONE|AUDIO_DEVICE_OUT_LINE|AUDIO_DEVICE_OUT_TELEPHONY_TX|AUDIO_DEVICE_OUT_AUX_DIGITAL|AUDIO_DEVICE_OUT_PROXY|AUDIO_DEVICE_OUT_FM|AUDIO_DEVICE_OUT_USB_DEVICE|AUDIO_DEVICE_OUT_USB_HEADSET)\"[^>]*>/ {:a; N; /<\/devicePort>/!ba; s/format=\"[^\"]*\"/format=\"$apc_format\"/g}" "$AUDIOPOLICY"
      #BT
      sed -i -E "/<mixPort name=\"(hearing aid output|a2dp_lhdc output)\"/,/<\/mixPort>/ {/<profile /{:$;N;/\/>/!b$;s/format=\"[^\"]*\"/format=\"$apc_format\"/}}" "$AUDIOPOLICY"
      sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_BLUETOOTH_A2DP|AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_HEADPHONES|AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_SPEAKER)\"/,/<\/devicePort>/ {/<profile /{:$;N;/\/>/!b$;s/format=\"[^\"]*\"/format=\"$apc_format\"/}}" "$AUDIOPOLICY"
      sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_BLUETOOTH_SCO|AUDIO_DEVICE_OUT_BLUETOOTH_SCO_HEADSET|AUDIO_DEVICE_OUT_BLUETOOTH_SCO_CARKIT)\"[^>]*>/ {:a; N; /<\/devicePort>/!ba; s/format=\"[^\"]*\"/format=\"$apc_format\"/g}" "$AUDIOPOLICY"
    fi
  } &
done

for OMIX in ${MPATHS}; do
  {
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch $ORIGDIR$OMIX $MIX
    if [ "$VOLMEDIA" != "false" ]; then
      sed -i 's/\(name="RX[0-9] Digital Volume" value="\)[^"]*"/\1'$VOLMEDIA'"/g' $MIX
      sed -i 's/\(name="WSA_RX[0-9] Digital Volume" value="\)[^"]*"/\1'$VOLMEDIA'"/g' $MIX
      sed -i 's/\(name="RX_RX[0-9] Digital Volume" value="\)[^"]*"/\1'$VOLMEDIA'"/g' $MIX
    fi

    if [ "$STEP12" == "true" ]; then
      sed -i 's/name="IIR0 Band1" id ="0" value=".*"/name="IIR0 Band1" id ="0" value="268833620"/g' $MIX
      sed -i 's/name="IIR0 Band1" id ="1" value=".*"/name="IIR0 Band1" id ="1" value="537398060"/g' $MIX
      sed -i 's/name="IIR0 Band1" id ="2" value=".*"/name="IIR0 Band1" id ="2" value="267510580"/g' $MIX
      sed -i 's/name="IIR0 Band1" id ="3" value=".*"/name="IIR0 Band1" id ="3" value="537398060"/g' $MIX
      sed -i 's/name="IIR0 Band1" id ="4" value=".*"/name="IIR0 Band1" id ="4" value="267908744"/g' $MIX
      sed -i 's/name="IIR0 Band2" id ="0" value=".*"/name="IIR0 Band2" id ="0" value="266468108"/g' $MIX
      sed -i 's/name="IIR0 Band2" id ="1" value=".*"/name="IIR0 Band2" id ="1" value="544862876"/g' $MIX
      sed -i 's/name="IIR0 Band2" id ="2" value=".*"/name="IIR0 Band2" id ="2" value="262421829"/g' $MIX
      sed -i 's/name="IIR0 Band2" id ="3" value=".*"/name="IIR0 Band2" id ="3" value="544862876"/g' $MIX
      sed -i 's/name="IIR0 Band2" id ="4" value=".*"/name="IIR0 Band2" id ="4" value="260454481"/g' $MIX
      sed -i 's/name="IIR0 Band3" id ="0" value=".*"/name="IIR0 Band3" id ="0" value="262913321"/g' $MIX
      sed -i 's/name="IIR0 Band3" id ="1" value=".*"/name="IIR0 Band3" id ="1" value="559557058"/g' $MIX
      sed -i 's/name="IIR0 Band3" id ="2" value=".*"/name="IIR0 Band3" id ="2" value="252311547"/g' $MIX
      sed -i 's/name="IIR0 Band3" id ="3" value=".*"/name="IIR0 Band3" id ="3" value="559557058"/g' $MIX
      sed -i 's/name="IIR0 Band3" id ="4" value=".*"/name="IIR0 Band3" id ="4" value="246789412"/g' $MIX
      sed -i 's/name="IIR0 Band4" id ="0" value=".*"/name="IIR0 Band4" id ="0" value="294517138"/g' $MIX
      sed -i 's/name="IIR0 Band4" id ="1" value=".*"/name="IIR0 Band4" id ="1" value="572289454"/g' $MIX
      sed -i 's/name="IIR0 Band4" id ="2" value=".*"/name="IIR0 Band4" id ="2" value="210943778"/g' $MIX
      sed -i 's/name="IIR0 Band4" id ="3" value=".*"/name="IIR0 Band4" id ="3" value="572289454"/g' $MIX
      sed -i 's/name="IIR0 Band4" id ="4" value=".*"/name="IIR0 Band4" id ="4" value="237025461"/g' $MIX
      sed -i 's/name="IIR0 Band5" id ="0" value=".*"/name="IIR0 Band5" id ="0" value="329006442"/g' $MIX
      sed -i 's/name="IIR0 Band5" id ="1" value=".*"/name="IIR0 Band5" id ="1" value="711929387"/g' $MIX
      sed -i 's/name="IIR0 Band5" id ="2" value=".*"/name="IIR0 Band5" id ="2" value="110068469"/g' $MIX
      sed -i 's/name="IIR0 Band5" id ="3" value=".*"/name="IIR0 Band5" id ="3" value="711929387"/g' $MIX
      sed -i 's/name="IIR0 Band5" id ="4" value=".*"/name="IIR0 Band5" id ="4" value="170639455"/g' $MIX
      sed -i 's/\(name="IIR0 Enable Band[0-9]" value="\)[^"]*"/\11"/g' $MIX
      sed -i 's/\(name="IIR0 INP[0-9] Volume" value="\)[^"]*"/\154"/g' $MIX
      sed -i 's/\(name="IIR0 INP[0-9] MUX" value="\)[^"]*"/\1RX2"/g' $MIX
    fi

    if [ "$VOLMIC" != "false" ]; then
      sed -i 's/\(name="ADC[0-9] Volume" value="\)[^"]*"/\112"/g' $MIX
      sed -i 's/\(name="DEC[0-9] Volume" value="\)[^"]*"/\1'$VOLMIC'"/g' $MIX
      sed -i 's/\(name="TX_DEC[0-9] Volume" value="\)[^"]*"/\1'$VOLMIC'"/g' $MIX
    fi

    if [ "$STEP6" == "true" ]; then
      sed -i 's/\(COMP[0-9]* Switch" value="\)1"/\10"/g' $MIX
      sed -i '/_COMP/s/value="[^"]*"/value="0"/g' $MIX
      sed -i '/compander/s/value="[^"]*"/value="false"/g' $MIX
      sed -i 's/\(WSA_COMP[0-9] Switch" value="\)1"/\10"/g' $MIX
      sed -i 's/\(RX_COMP[0-9] Switch" value="\)1"/\10"/g' $MIX
      sed -i 's/"HPHL_COMP Switch" value="1"/"HPHL_COMP Switch" value="0"/g' $MIX
      sed -i 's/"HPHR_COMP Switch" value="1"/"HPHR_COMP Switch" value="0"/g' $MIX
      sed -i 's/"HPHL Compander" value="1"/"HPHL Compander" value="0"/g' $MIX
      sed -i 's/"HPHR Compander" value="1"/"HPHR Compander" value="0"/g' $MIX
      sed -i 's/\(Softclip[0-9] Enable" value="\)0"/\11"/g' $MIX
      sed -i 's/\(RX_Softclip[0-9]* Enable" value="\)0"/\11"/g' $MIX
      sed -i 's/\(WSA_Softclip[0-9] Enable" value="\)0"/\11"/g' $MIX
      sed -i 's/name="COMP0 RX1" value=".*"/name="COMP0 RX1" value="0"/g' $MIX
      sed -i 's/name="COMP0 RX2" value=".*"/name="COMP0 RX2" value="0"/g' $MIX
      sed -i 's/name="COMP1" value=".*"/name="COMP1" value="0"/g' $MIX
      sed -i 's/name="COMP2" value=".*"/name="COMP2" value="0"/g' $MIX
      sed -i 's/name="SpkrLeft COMP Switch" value=".*"/name="SpkrLeft COMP Switch" value="0"/g' $MIX
      sed -i 's/name="SpkrRight COMP Switch" value=".*"/name="SpkrRight COMP Switch" value="0"/g' $MIX
      sed -i 's/"SpkrLeft BOOST Switch" value="1"/"SpkrLeft BOOST Switch" value="0"/g' $MIX
      sed -i 's/"SpkrRight BOOST Switch" value="1"/"SpkrRight BOOST Switch" value="0"/g' $MIX
      sed -i 's/"SpkrLeft SWR DAC_Port Switch" value="1"/"SpkrLeft SWR DAC_Port Switch" value="0"/g' $MIX
      sed -i 's/"SpkrRight SWR DAC_Port Switch" value="1"/"SpkrRight SWR DAC_Port Switch" value="0"/g' $MIX
      sed -i 's/"HPHL_RDAC Switch" value="0"/"HPHL_RDAC Switch" value="1"/g' $MIX
      sed -i 's/"HPHR_RDAC Switch" value="0"/"HPHR_RDAC Switch" value="1"/g' $MIX
      sed -i 's/"AUX_RDAC Switch" value="0"/"AUX_RDAC Switch" value="1"/g' $MIX
      sed -i 's/"EAR_RDAC Switch" value="0"/"EAR_RDAC Switch" value="1"/g' $MIX
      sed -i 's/"Boost Class-H Tracking Enable" value="0"/"Boost Class-H Tracking Enable" value="1"/g' $MIX
      sed -i 's/"DRE DRE Switch" value="0"/"DRE DRE Switch" value="1"/g' $MIX
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
      sed -i 's/\(RX INT[0-9] DEM MUX" value="\)NORMAL_DSM_OUT"/\1CLSH_DSM_OUT"/g' $MIX
    fi

    if [ "$STEP8" == "true" ]; then
      case "$PROCESSOR" in "pitti" | "sdm660" | "msm8937" | "msm8953")
        sed -i 's/\(name="RX[0-9] HPF cut off" value="\)[^"]*"/\1MIN_3DB_4Hz"/g' $MIX
        sed -i 's/\(name="TX[0-9] HPF cut off" value="\)[^"]*"/\1MIN_3DB_4Hz"/g' $MIX
        sed -i 's/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="HD2"/g' $MIX
        sed -i 's/name="RX HPH HD2 Mode" value=".*"/name="RX HPH HD2 Mode" value="On"/g' $MIX
        ;;
      *)
        sed -i 's/\(name="RX[0-9] HPF cut off" value="\)[^"]*"/\1CF_NEG_3DB_4HZ"/g' $MIX
        sed -i 's/\(name="TX[0-9] HPF cut off" value="\)[^"]*"/\1CF_NEG_3DB_4HZ"/g' $MIX
        sed -i 's/name="RX_HPH_PWR_MODE" value=".*"/name="RX_HPH_PWR_MODE" value="LOHIFI"/g' $MIX
        sed -i 's/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="CLS_H_LOHIFI"/g' $MIX
        ;;
      esac

      # [ "$RN5PRO", "$MI9", "$MI8", "$MI8P", "$MI9P", "$MIA2" ]
      case "$DEVICE" in whyred* | cepheus* | dipper* | equuleus* | crux* | jasmine*)
        sed -i 's/name="TAS2557 ClassD Edge" value=".*"/name="TAS2557 ClassD Edge" value="7"/g' $MIX
        sed -i 's/name="TAS2557 Volume" value=".*"/name="TAS2557 Volume" value="30"/g' $MIX
        echo -e '\nro.sound.alsa=TAS2557' >>$PROP
        ;;
      esac

      sed -i 's/name="Tfa Enable" value=".*"/name="Tfa Enable" value="1"/g' $MIX
      sed -i 's/name="TFA Profile" value=".*"/name="TFA Profile" value="music"/g' $MIX
      sed -i 's/name="DK Profile" value=".*"/name="DK Profile" value="receiver"/g' $MIX
      sed -i 's/name="TFA987X_ALGO_STATUS" value=".*"/name="TFA987X_ALGO_STATUS" value="ENABLE"/g' $MIX
      sed -i 's/name="TFA987X_TX_ENABLE" value=".*"/name="TFA987X_TX_ENABLE" value="ENABLE"/g' $MIX
      sed -i 's/name="Ext_Amp_Mode" value=".*"/name="Ext_Amp_Mode" value="Music"/g' $MIX
      sed -i 's/name="AUX PATH Mode" value=".*"/name="AUX PATH Mode" value="HP_MODE"/g' $MIX
      sed -i 's/name="PowerCtrl" value=".*"/name="PowerCtrl" value="0"/g' $MIX
      sed -i 's/name="DSD_L Switch" value=".*"/name="DSD_L Switch" value="1"/g' $MIX
      sed -i 's/name="DSD_R Switch" value=".*"/name="DSD_R Switch" value="1"/g' $MIX
      sed -i 's/name="Amp DSP Enable" value=".*"/name="Amp DSP Enable" value="1"/g' $MIX
      sed -i 's/name="BDE AMP Enable" value=".*"/name="BDE AMP Enable" value="1"/g' $MIX
      sed -i 's/name="Amp Volume Location" value=".*"/name="Amp Volume Location" value="1"/g' $MIX
      sed -i 's/name="Ext Spk Boost" value=".*"/name="Ext Spk Boost" value="ENABLE"/g' $MIX
      sed -i 's/name="Adsp Working Mode" value=".*"/name="Adsp Working Mode" value="full"/g' $MIX
      sed -i 's/name="RX_Native" value=".*"/name="RX_Native" value="ON"/g' $MIX
      sed -i 's/name="HPH Idle Detect" value=".*"/name="HPH Idle Detect" value="ON"/g' $MIX
      sed -i 's/name="Set Custom Stereo OnOff" value=".*"/name="Set Custom Stereo OnOff" value="1"/g' $MIX
      sed -i 's/name="HiFi Function" value=".*"/name="HiFi Function" value="On"/g' $MIX
      sed -i 's/name="HiFi Filter" value=".*"/name="HiFi Filter" value="1"/g' $MIX
      sed -i 's/name="App Type Gain" value=".*"/name="App Type Gain" value="8192"/g' $MIX
      sed -i 's/name="Audiosphere Enable" value=".*"/name="Audiosphere Enable" value="On"/g' $MIX
      sed -i 's/name="MSM ASphere Set Param" value=".*"/name="MSM ASphere Set Param" value="1"/g' $MIX
      sed -i 's/name="Load acoustic model" value=".*"/name="Load acoustic model" value="1"/g' $MIX
      sed -i 's/name="AUX_HPF Enable" value=".*"/name="AUX_HPF Enable" value="Off"/g' $MIX
      sed -i 's/name="A2DP_HPF Enable" value=".*"/name="A2DP_HPF Enable" value="Off"/g' $MIX
      sed -i 's/name="BT_HPF Enable" value=".*"/name="BT_HPF Enable" value="Off"/g' $MIX
      sed -i 's/name="HPF Enable" value=".*"/name="HPF Enable" value="Off"/g' $MIX
      sed -i 's/name="A2DP_LPF Enable" value=".*"/name="A2DP_LPF Enable" value="Off"/g' $MIX
      sed -i 's/name="BT_LPF Enable" value=".*"/name="BT_LPF Enable" value="Off"/g' $MIX
      sed -i 's/name="LPF Enable" value=".*"/name="LPF Enable" value="Off"/g' $MIX
      sed -i 's/name="AUX_BPF Enable" value=".*"/name="AUX_BPF Enable" value="Off"/g' $MIX
      sed -i 's/name="A2DP_BPF Enable" value=".*"/name="A2DP_BPF Enable" value="Off"/g' $MIX
      sed -i 's/name="BT_BPF Enable" value=".*"/name="BT_BPF Enable" value="Off"/g' $MIX
      sed -i 's/name="BPF Enable" value=".*"/name="BPF Enable" value="Off"/g' $MIX
      sed -i 's/name="TERT_MI2S_TX LSM Function" value=".*"/name="TERT_MI2S_TX LSM Function" value="AUDIO"/g' $MIX
      sed -i 's/name="TERT_TDM_TX_0 LSM Function" value=".*"/name="TERT_TDM_TX_0 LSM Function" value="AUDIO"/g' $MIX
      sed -i 's/name="TERT_TDM_RX_1 Header Type" value=".*"/name="TERT_TDM_RX_1 Header Type" value="Entertainment"/g' $MIX
      sed -i 's/name="TERT_TDM_RX_0 Header Type" value=".*"/name="TERT_TDM_RX_0 Header Type" value="Entertainment"/g' $MIX
      sed -i 's/name="RX_Softclip Enable" value=".*"/name="RX_Softclip Enable" value="1"/g' $MIX
      sed -i 's/name="RX INT1 DEM MUX" value=".*"/name="RX INT1 DEM MUX" value="CLSH_DSM_OUT"/g' $MIX
      sed -i 's/name="RX INT0 DEM MUX" value=".*"/name="RX INT0 DEM MUX" value="CLSH_DSM_OUT"/g' $MIX
      sed -i 's/name="RCV PCM Source" value=".*"/name="RCV PCM Source" value="DSP"/g' $MIX
      sed -i 's/name="PCM Source" value=".*"/name="PCM Source" value="DSP"/g' $MIX
      sed -i 's/name="LPI Enable" value=".*"/name="LPI Enable" value="0"/g' $MIX
      sed -i 's/name="HDR34 MUX" value=".*"/name="HDR34 MUX" value="HDR34"/g' $MIX
      sed -i 's/name="HDR12 MUX" value=".*"/name="HDR12 MUX" value="HDR12"/g' $MIX
      sed -i 's/name="DS2 OnOff" value=".*"/name="DS2 OnOff" value="1"/g' $MIX

      # [ "$PIXEL6a", "$PIXEL6", "$PIXEL6Pro", "$PIXEL7", "$PIXEL7Pro", "$PIXEL8", "$PIXEL8Pro" ]
      case "$DEVICE" in bluejay* | oriel* | raven* | cheetah* | panther* | shiba* | husky*)
        sed -i 's/name="AMP PCM Gain" value=".*"/name="AMP PCM Gain" value="14"/g' $MIX
        sed -i 's/name="Digital PCM Volume" value=".*"/name="Digital PCM Volume" value="865"/g' $MIX
        sed -i 's/name="Boost Peak Current Limit" value=".*"/name="Boost Peak Current Limit" value="3.50A"/g' $MIX
        ;;
      esac
    fi
  } &
done

if [ "$VOLSTEPS" != "false" ]; then
  {
    echo -e "\nro.config.media_vol_steps=$VOLSTEPS" >>$PROP
    echo -e "\nsettings put system volume_steps_music $VOLSTEPS" >>$MODPATH/service.sh
  } &
fi

if [ "$STEP14" == "true" ]; then
  {
    # [ "$POCOF3" ]
    case "$DEVICE" in alioth*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "TX0 MODE" ADC_LO_HIF
tinymix_new set "TX1 MODE" ADC_LO_HIF
tinymix_new set "TX2 MODE" ADC_LO_HIF
tinymix_new set "TX3 MODE" ADC_LO_HIF
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$POCOF4GT", "$ONEPLUS9R", "$ONEPLUS9Pro" ]
    case "$DEVICE" in ingres* | OnePlus9R* | OnePlus9Pro*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "RCV PCM Source" DSP
tinymix_new set "PCM Source" DSP
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "TX0 MODE" ADC_LO_HIF
tinymix_new set "TX1 MODE" ADC_LO_HIF
tinymix_new set "TX2 MODE" ADC_LO_HIF
tinymix_new set "TX3 MODE" ADC_LO_HIF
tinymix_new set "Cirrus SP Load Config" Load
tinymix_new set "Cirrus SP Channel Swap Duration" 9600
tinymix_new set "EC Reference Channels" Two
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 9 Compress" 0
tinymix_new set "Compress Playback 11 Volume" 0 0
tinymix_new set "Compress Playback 25 Volume" 0 0
tinymix_new set "Compress Playback 26 Volume" 0 0
tinymix_new set "Compress Playback 27 Volume" 0 0
tinymix_new set "Compress Playback 28 Volume" 0 0
tinymix_new set "Compress Playback 37 Volume" 0 0
tinymix_new set "Compress Gapless Playback" 0
tinymix_new set "RCV Noise Gate" 16382
tinymix_new set "Noise Gate" 16382
tinymix_new set "AUX_HPF Enable" 0
tinymix_new set "SLIM9_TX ADM Channels" Two
tinymix_new set "Voip Evrc Min Max Rate Config" 4 4
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "TERT_MI2S_RX Format" '$max_format_24'
tinymix_new set "TERT_MI2S_TX Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$max_format_24'
tinymix_new set "TX_CDC_DMA_TX_3 Format" '$FORMAT'
tinymix_new set "TX_CDC_DMA_TX_4 Format" '$FORMAT'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "TX_CDC_DMA_TX_3 SampleRate" '$RATE'
tinymix_new set "TX_CDC_DMA_TX_4 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_rate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_rate_192'
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_rate_192'
tinymix_new set "TERT_MI2S_TX SampleRate" '$max_rate_192' 
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$POCOX3Pro" ]
    case "$DEVICE" in vayu*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "RCV PCM Source" DSP
tinymix_new set "PCM Source" DSP
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix_new set "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix_new set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_new set "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix_new set "SLIM_4_TX Format" DSD_DOP
tinymix_new set "SLIM_2_RX Format" DSD_DOP
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "TX0 MODE" ADC_LO_HIF
tinymix_new set "TX1 MODE" ADC_LO_HIF
tinymix_new set "TX2 MODE" ADC_LO_HIF
tinymix_new set "TX3 MODE" ADC_LO_HIF
tinymix_new set "Cirrus SP Load Config" Load
tinymix_new set "EC Reference Channels" Two
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 9 Compress" 0
tinymix_new set "Compress Playback 11 Volume" 0 0
tinymix_new set "Compress Playback 25 Volume" 0 0
tinymix_new set "Compress Playback 26 Volume" 0 0
tinymix_new set "Compress Playback 27 Volume" 0 0
tinymix_new set "Compress Playback 28 Volume" 0 0
tinymix_new set "Compress Playback 37 Volume" 0 0
tinymix_new set "Compress Gapless Playback" 0
tinymix_new set "RCV Noise Gate" 16383
tinymix_new set "Noise Gate" 16383
tinymix_new set "RCV Digital PCM Volume" 830
tinymix_new set "Digital PCM Volume" 830
tinymix_new set "RCV Class-H Head Room" 127
tinymix_new set "Class-H Head Room" 127
tinymix_new set "RCV PCM Soft Ramp" 30ms
tinymix_new set "PCM Soft Ramp" 30ms
tinymix_new set "RCV DSP Set AMBIENT" 16777215
tinymix_new set "DSP Set AMBIENT" 16777215
tinymix_new set "DS2 OnOff" 1
tinymix_new set "TERT_TDM_TX_0 LSM Function" AUDIO
tinymix_new set "TERT_MI2S_TX LSM Function" AUDIO
tinymix_new set "TAS256X PLAYBACK VOLUME LEFT" 56
tinymix_new set "TAS256X LIM MAX ATTN LEFT" 0
tinymix_new set "TAS256X LIM INFLECTION POINT LEFT" 0
tinymix_new set "TAS256X LIM ATTACT RATE LEFT" 0
tinymix_new set "TAS256X LIM RELEASE RATE LEFT" 7
tinymix_new set "TAS256X LIM ATTACK STEP LEFT" 0
tinymix_new set "TAS256X LIM RELEASE STEP LEFT" 3
tinymix_new set "TAS256X RX MODE LEFT" Speaker
tinymix_new set "TAS256X BOOST VOLTAGE LEFT" 15
tinymix_new set "TAS256X BOOST CURRENT LEFT" 59
tinymix_new set "TAS256X PLAYBACK VOLUME RIGHT" 56
tinymix_new set "TAS256X LIM MAX ATTN RIGHT" 0
tinymix_new set "TAS256X LIM INFLECTION POINT RIGHT" 0
tinymix_new set "TAS256X LIM ATTACT RATE RIGHT" 0
tinymix_new set "TAS256X LIM RELEASE RATE RIGHT" 7
tinymix_new set "TAS256X LIM ATTACK STEP RIGHT" 0
tinymix_new set "TAS256X LIM RELEASE STEP RIGHT" 3
tinymix_new set "TAS256X BOOST VOLTAGE RIGHT" 12
tinymix_new set "TAS256X BOOST CURRENT RIGHT" 55
tinymix_new set "TAS256X VBAT LPF LEFT" DISABLE
tinymix_new set "TAS256X VBAT LPF RIGHT" DISABLE
tinymix_new set "TAS256x Profile id" 1
tinymix_new set "TAS25XX_SMARTPA_ENABLE" ENABLE
tinymix_new set "Amp Output Level" 22
tinymix_new set "TAS25XX_ALGO_PROFILE" MUSIC
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "TERT_TDM_RX_0 Format" '$max_format_24'
tinymix_new set "TERT_TDM_RX_1 Format" '$max_format_24'
tinymix_new set "TERT_MI2S_RX Format" '$max_format_24'
tinymix_new set "TERT_MI2S_TX Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$max_format_24'
tinymix_new set "SLIM_5_RX Format" '$max_format_24'
tinymix_new set "SLIM_6_RX Format" '$max_format_24'
tinymix_new set "SLIM_0_RX Format" '$max_format_24'
tinymix_new set "SLIM_0_TX Format" '$max_format_24'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_rate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_rate_192'
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_rate_192'
tinymix_new set "TERT_MI2S_TX SampleRate" '$max_rate_192'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$MI13U", "$MI14U" ]
    case "$DEVICE" in ishtar* | aurora*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$MI11U", "$ONEPLUS11GLOBAL" ]
    case "$DEVICE" in star* | OP594DL1*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "PCM Source" DSP
tinymix_new set "Cirrus SP Load Config" Load
tinymix_new set "EC Reference Channels" Two
tinymix_new set "RCV Noise Gate" 16383
tinymix_new set "Noise Gate" 16383
tinymix_new set "DS2 OnOff" 1
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$POCOM3", "$R9T" ]
    case "$DEVICE" in citrus* | juice* | chime* | lime*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "LPI Enable" 0
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 9 Compress" 0
tinymix_new set "Compress Playback 25 Volume" 0 0
tinymix_new set "Compress Playback 26 Volume" 0 0
tinymix_new set "Compress Playback 27 Volume" 0 0
tinymix_new set "Compress Playback 28 Volume" 0 0
tinymix_new set "Compress Playback 36 Volume" 0 0
tinymix_new set "Compress Gapless Playback" 0
tinymix_new set "EC Reference Channels" Two
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "DS2 OnOff" 1
tinymix_new set "HPH Idle Detect" ON
tinymix_new set "Set Custom Stereo OnOff" 1
tinymix_new set "AUX_HPF Enable" 0
tinymix_new set "Voip Evrc Min Max Rate Config" 4 4
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "TX_CDC_DMA_TX_0 Format" '$FORMAT'
tinymix_new set "TX_CDC_DMA_TX_3 Format" '$FORMAT'
tinymix_new set "TX_CDC_DMA_TX_4 Format" '$FORMAT'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_3 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_3 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "TX_CDC_DMA_TX_0 SampleRate" '$RATE'
tinymix_new set "TX_CDC_DMA_TX_3 SampleRate" '$RATE'
tinymix_new set "TX_CDC_DMA_TX_4 SampleRate" '$RATE'
tinymix_new set "VA_CDC_DMA_TX_0 SampleRate" '$max_rate_192'
tinymix_new set "VA_CDC_DMA_TX_1 SampleRate" '$max_rate_192'
tinymix_new set "VA_CDC_DMA_TX_2 SampleRate" '$max_rate_192'
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "VA_CDC_DMA_TX_0 Format" '$max_format_24'
tinymix_new set "VA_CDC_DMA_TX_1 Format" '$max_format_24'
tinymix_new set "VA_CDC_DMA_TX_2 Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$R12P+" ]
    case "$DEVICE" in RE5C82L1* | RE5C3B*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "Ext_Amp_Boost_Volume" Level_4
tinymix_new set "TX CH1 PWR" L3
tinymix_new set "TX CH3 PWR" L3
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "AUX PATH Mode" HP_MODE
tinymix_new set "Ext_Amp_Mode" Music
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX_COMP1 Switch" 0
tinymix_new set "RX_COMP2 Switch" 0
tinymix_new set "HPHL_COMP Switch" 0
tinymix_new set "HPHR_COMP Switch" 0
tinymix_new set "AUX_HPF Enable" 0
tinymix_new set "HPHR_RDAC Switch" 1
tinymix_new set "HPHL_RDAC Switch" 1
tinymix_new set "AUX_RDAC Switch" 1
tinymix_new set "EAR_RDAC Switch" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPH Idle Detect" ON
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$Oneplus 7 series" ]
    case "$DEVICE" in guacamole* | hotdog* | OnePlus7* | OnePlus7T* | OnePlus7Pro* | OnePlus7TPro*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HD Voice Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "HiFi Filter" 1
tinymix_new set "HiFi Function" On
tinymix_new set "Compress Gapless Playback" 0
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 1 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 13 Compress" 0
tinymix_new set "Playback 16 Compress" 0
tinymix_new set "Playback 27 Compress" 0
tinymix_new set "Playback 42 Compress" 0
tinymix_new set "Playback 43 Compress" 0
tinymix_new set "EC Reference Channels" Two
tinymix_new set "AMIC_1_2 PWR MODE" HIGH_PERF
tinymix_new set "AMIC_3_4 PWR MODE" HIGH_PERF
tinymix_new set "AMIC_5_6 PWR MODE" HIGH_PERF
tinymix_new set "SLIM_4_TX Format" DSD_DOP
tinymix_new set "SLIM_2_RX Format" DSD_DOP
tinymix_new set "DS2 OnOff" 1
tinymix_new set "Set Custom Stereo OnOff" 1
tinymix_new set "SLIMBUS_0_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_1_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_2_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_3_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_4_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_5_TX LSM Function" AUDIO
tinymix_new set "TERT_MI2S_TX LSM Function" AUDIO
tinymix_new set "QUAT_MI2S_TX LSM Function" AUDIO
tinymix_new set "INT3_MI2S_TX LSM Function" AUDIO
tinymix_new set "TX_CDC_DMA_TX_3 LSM Function" AUDIO
tinymix_new set "QUIN_TDM_TX_0 LSM Function" AUDIO
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT2 DEM MUX" CLSH_DSM_OUT
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "EC Reference Bit Format" '$max_format_24'
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$max_bit_width_24'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "TERT_MI2S_RX Format" '$max_format_24'
tinymix_new set "TERT_MI2S_TX Format" '$max_format_24'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_rate_192'
tinymix_new set "TERT_MI2S_TX SampleRate" '$max_rate_192'
tinymix_new set "EC Reference SamplRate" '$SAMPLERATE'
tinymix_new set "Display Port RX Sample Rate" '$max_rate_192'
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$POCOX3" ]
    case "$DEVICE" in surya*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 16
tinymix_new set "HPHR Volume" 16
tinymix_new set "RX HPH Mode" CLS_H_LOHIFI
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 1 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 13 Compress" 0
tinymix_new set "Playback 16 Compress" 0
tinymix_new set "Playback 27 Compress" 0
tinymix_new set "Playback 39 Compress" 0
tinymix_new set "Compress Playback 15 Volume" 0 0
tinymix_new set "Compress Playback 29 Volume" 0 0
tinymix_new set "Compress Playback 30 Volume" 0 0
tinymix_new set "Compress Playback 31 Volume" 0 0
tinymix_new set "Compress Playback 32 Volume" 0 0
tinymix_new set "Compress Playback 41 Volume" 0 0
tinymix_new set "Compress Playback 42 Volume" 0 0
tinymix_new set "Compress Playback 43 Volume" 0 0
tinymix_new set "Compress Playback 44 Volume" 0 0
tinymix_new set "Compress Playback 45 Volume" 0 0
tinymix_new set "EC Reference Channels" Two
tinymix_new set "DS2 OnOff" 1
tinymix_new set "TAS256x Profile id" 1
tinymix_new set "TAS25XX_SMARTPA_ENABLE" ENABLE
tinymix_new set "TAS25XX_ALGO_PROFILE" MUSIC
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "TERT_TDM_RX_0 Format" '$max_format_24'
tinymix_new set "TERT_TDM_RX_1 Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$RN10", "$RN10PRO", "$RN10PROMAX", "$RN8T", "$A71", "$RMEGTNEO3T", "$ONEPLUS9RT" ]
    case "$DEVICE" in mojito* | sweet* | sweetin* | willow* | a71* | RE54E4L1* | OnePlus9RT*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "RCV PCM Source" DSP
tinymix_new set "PCM Source" DSP
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "SLIM_4_TX Format" DSD_DOP
tinymix_new set "SLIM_2_RX Format" DSD_DOP
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "TX0 MODE" ADC_LO_HIF
tinymix_new set "TX1 MODE" ADC_LO_HIF
tinymix_new set "TX2 MODE" ADC_LO_HIF
tinymix_new set "TX3 MODE" ADC_LO_HIF
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 1 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 13 Compress" 0
tinymix_new set "Playback 16 Compress" 0
tinymix_new set "Playback 27 Compress" 0
tinymix_new set "Compress Playback 15 Volume" 0 0
tinymix_new set "Compress Playback 29 Volume" 0 0
tinymix_new set "Compress Playback 30 Volume" 0 0
tinymix_new set "Compress Playback 31 Volume" 0 0
tinymix_new set "Compress Playback 32 Volume" 0 0
tinymix_new set "Compress Playback 41 Volume" 0 0
tinymix_new set "Compress Playback 42 Volume" 0 0
tinymix_new set "Compress Playback 43 Volume" 0 0
tinymix_new set "Compress Playback 44 Volume" 0 0
tinymix_new set "Compress Playback 45 Volume" 0 0
tinymix_new set "Cirrus SP Load Config" Load
tinymix_new set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_new set "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix_new set "EC Reference Channels" Two
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "RCV Noise Gate" 16383
tinymix_new set "Noise Gate" 16383
tinymix_new set "DS2 OnOff" 1
tinymix_new set "aw882_xx_rx_switch" Enable
tinymix_new set "aw882_xx_tx_switch" Enable
tinymix_new set "aw882_copp_switch" Enable
tinymix_new set "aw_dev_0_prof" Receiver
tinymix_new set "aw_dev_1_prof" Receiver
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
tinymix_new set "TERT_TDM_RX_0 Format" '$max_format_24'
tinymix_new set "TERT_TDM_RX_1 Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$max_format_24'
tinymix_new set "SLIM_5_RX Format" '$max_format_24'
tinymix_new set "SLIM_6_RX Format" '$max_format_24'
tinymix_new set "SLIM_0_RX Format" '$max_format_24'
tinymix_new set "SLIM_0_TX Format" '$max_format_24'
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_rate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_rate_192'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$RMEGTNEO2" ]
    case "$DEVICE" in RE5473* | RE879AL1* | kona*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "RCV PCM Source" DSP
tinymix_new set "PCM Source" DSP
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "SLIM_4_TX Format" DSD_DOP
tinymix_new set "SLIM_2_RX Format" DSD_DOP
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "TX0 MODE" ADC_LO_HIF
tinymix_new set "TX1 MODE" ADC_LO_HIF
tinymix_new set "TX2 MODE" ADC_LO_HIF
tinymix_new set "TX3 MODE" ADC_LO_HIF
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 9 Compress" 0
tinymix_new set "Compress Playback 11 Volume" 0 0
tinymix_new set "Compress Playback 25 Volume" 0 0
tinymix_new set "Compress Playback 26 Volume" 0 0
tinymix_new set "Compress Playback 27 Volume" 0 0
tinymix_new set "Compress Playback 28 Volume" 0 0
tinymix_new set "Compress Playback 37 Volume" 0 0
tinymix_new set "Cirrus SP Load Config" Load
tinymix_new set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_new set "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix_new set "EC Reference Channels" Two
tinymix_new set "RCV Noise Gate" 16383
tinymix_new set "Noise Gate" 16383
tinymix_new set "DS2 OnOff" 1
tinymix_new set "aw882_xx_rx_switch" Enable
tinymix_new set "aw882_xx_tx_switch" Enable
tinymix_new set "aw882_copp_switch" Enable
tinymix_new set "aw_dev_0_prof" Receiver
tinymix_new set "aw_dev_1_prof" Receiver
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "TERT_TDM_RX_0 Format" '$max_format_24'
tinymix_new set "TERT_TDM_RX_1 Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$max_format_24'
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "SLIM_5_RX Format" '$max_format_24'
tinymix_new set "SLIM_6_RX Format" '$max_format_24'
tinymix_new set "SLIM_0_RX Format" '$max_format_24'
tinymix_new set "SLIM_0_TX Format" '$max_format_24'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_rate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_rate_192'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$S22U" ]
    case "$DEVICE" in b0q*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "RCV PCM Source" DSP
tinymix_new set "PCM Source" DSP
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix_new set "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix_new set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_new set "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix_new set "SLIM_4_TX Format" DSD_DOP
tinymix_new set "SLIM_2_RX Format" DSD_DOP
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "TX0 MODE" ADC_LO_HIF
tinymix_new set "TX1 MODE" ADC_LO_HIF
tinymix_new set "TX2 MODE" ADC_LO_HIF
tinymix_new set "TX3 MODE" ADC_LO_HIF
tinymix_new set "Cirrus SP Load Config" Load
tinymix_new set "EC Reference Channels" Two
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 9 Compress" 0
tinymix_new set "Compress Playback 11 Volume" 0 0
tinymix_new set "Compress Playback 25 Volume" 0 0
tinymix_new set "Compress Playback 26 Volume" 0 0
tinymix_new set "Compress Playback 27 Volume" 0 0
tinymix_new set "Compress Playback 28 Volume" 0 0
tinymix_new set "Compress Playback 37 Volume" 0 0
tinymix_new set "Compress Gapless Playback" 0
tinymix_new set "RCV Noise Gate" 16383
tinymix_new set "Noise Gate" 16383
tinymix_new set "Haptics Source" A2H
tinymix_new set "Static MCLK Mode" 24
tinymix_new set "Force Frame32" 1
tinymix_new set "A2H Tuning" 5
tinymix_new set "LPI Enable" 0
tinymix_new set "DMIC_RATE OVERRIDE" CLK_2P4MHZ
tinymix_new set "DS2 OnOff" 1
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "TERT_TDM_RX_0 Format" '$max_format_24'
tinymix_new set "TERT_TDM_RX_1 Format" '$max_format_24'
tinymix_new set "TERT_MI2S_RX Format" '$max_format_24'
tinymix_new set "TERT_MI2S_TX Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$max_format_24'
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "SLIM_5_RX Format" '$max_format_24'
tinymix_new set "SLIM_6_RX Format" '$max_format_24'
tinymix_new set "SLIM_0_RX Format" '$max_format_24'
tinymix_new set "SLIM_0_TX Format" '$max_format_24'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_rate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_rate_192'
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_rate_192'
tinymix_new set "TERT_MI2S_TX SampleRate" '$max_rate_192'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$POCOF5" ]
    case "$DEVICE" in marble*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_LOHIFI
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX_HPH HD2 Mode" ON
tinymix_new set "HPH Idle Detect" ON
tinymix_new set "TX0 MODE" ADC_HIFI
tinymix_new set "TX1 MODE" ADC_HIFI
tinymix_new set "TX2 MODE" ADC_HIFI
tinymix_new set "TX3 MODE" ADC_HIFI
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "AUX_HPF Enable" 0
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$RN9PRO", "$RN9S", "$POCOM2P", "$RN9PMAX" ]
    case "$DEVICE" in joyeuse* | curtana* | gram* | excalibur*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "Amp Output Level" 22
tinymix_new set "TAS25XX_ALGO_BYPASS" TRUE
tinymix_new set "TAS2562 IVSENSE ENABLE" On
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 9 Compress" 0
tinymix_new set "Compress Playback 7 Volume" 0 0
tinymix_new set "Compress Playback 11 Volume" 0 0
tinymix_new set "Compress Playback 24 Volume" 0 0
tinymix_new set "Compress Playback 25 Volume" 0 0
tinymix_new set "Compress Playback 26 Volume" 0 0
tinymix_new set "Compress Playback 27 Volume" 0 0
tinymix_new set "Compress Playback 28 Volume" 0 0
tinymix_new set "Compress Playback 37 Volume" 0 0
tinymix_new set "Compress Gapless Playback" 0
tinymix_new set "RX_HPH HD2 Mode" ON
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "HPH Idle Detect" ON
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "AUX_HPF Enable" 0
tinymix_new set "DS2 OnOff" 1
tinymix_new set "Set Custom Stereo OnOff" 1
tinymix_new set "SLIMBUS_0_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_1_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_2_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_3_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_4_TX LSM Function" AUDIO
tinymix_new set "SLIMBUS_5_TX LSM Function" AUDIO
tinymix_new set "TERT_MI2S_TX LSM Function" AUDIO
tinymix_new set "QUAT_MI2S_TX LSM Function" AUDIO
tinymix_new set "INT3_MI2S_TX LSM Function" AUDIO
tinymix_new set "TX_CDC_DMA_TX_3 LSM Function" AUDIO
tinymix_new set "QUIN_TDM_TX_0 LSM Function" AUDIO
tinymix_new set "TERT_TDM_TX_0 LSM Function" AUDIO
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_3 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$max_format_24'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
tinymix_new set "SEN_MI2S_RX Format" '$max_format_24'
tinymix_new set "QUIN_MI2S_RX Format" '$max_format_24'
tinymix_new set "QUAT_MI2S_RX Format" '$max_format_24'
tinymix_new set "SEC_MI2S_RX Format" '$max_format_24'
tinymix_new set "PRIM_MI2S_RX Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_3 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_rate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_rate_192'
tinymix_new set "Display Port RX SampleRate" '$max_rate_192'
tinymix_new set "Display Port1 RX SampleRate" '$max_rate_192'
tinymix_new set "SEN_MI2S_RX SampleRate" '$max_rate_192'
tinymix_new set "QUIN_MI2S_RX SampleRate" '$max_rate_192'
tinymix_new set "QUAT_MI2S_RX SampleRate" '$max_rate_192'
tinymix_new set "SEC_MI2S_RX SampleRate" '$max_rate_192'
tinymix_new set "PRIM_MI2S_RX SampleRate" '$max_rate_192'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$PIXEL6a", "$PIXEL6", "$PIXEL6Pro", "$PIXEL7", "$PIXEL7Pro" ]
    case "$DEVICE" in bluejay* | oriel* | raven* | cheetah* | panther*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "AMP PCM Gain" 14
tinymix_new set "Digital PCM Volume" 865
tinymix_new set "Boost Peak Current Limit" 3.50A
' >>$MODPATH/service.sh
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$OP12" ]
    case "$DEVICE" in OP595DL1*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "AUX_HPF Enable" 0
tinymix_new set "HPH Idle Detect" ON
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "TFA Profile" speaker
tinymix_new set "TX0 MODE" ADC_HIFI
tinymix_new set "TX1 MODE" ADC_HIFI
tinymix_new set "TX2 MODE" ADC_HIFI
tinymix_new set "TX3 MODE" ADC_HIFI
tinymix_new set "HPHL_COMP Switch" 0
tinymix_new set "HPHR_COMP Switch" 0
tinymix_new set "RX_COMP1 Switch" 0
tinymix_new set "RX_COMP2 Switch" 0
tinymix_new set "HPHL Compander" 0
tinymix_new set "HPHR Compander" 0
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$MI10" ]
    case "$DEVICE" in umi*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 24
tinymix_new set "HPHR Volume" 24
tinymix_new set "AMP PCM Gain" 20
tinymix_new set "RCV AMP PCM Gain" 20
tinymix_new set "RX HPH Mode" CLS_H_LOHIFI
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "Cirrus SP Load Config" Load
tinymix_new set "Cirrus SP Channel Swap Duration" 9600
tinymix_new set "AUX_HPF Enable" 0
tinymix_new set "Set Custom Stereo OnOff" 1
tinymix_new set "PCM Source" ASP
tinymix_new set "RCV PCM Source" ASP
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "Xperia 1 2" ]
    case "$DEVICE" in XQ-AT52*)
      tinymix_support=true
      echo -e '\n
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "HDR12 MUX" HDR34
tinymix_new set "L AMP PCM Gain" 20
tinymix_new set "R AMP PCM Gain" 20
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "AUX_HPF Enable" 0
tinymix_new set "RX_HPH HD2 Mode" ON
tinymix_new set "DS2 OnOff" 1
tinymix_new set "Set Custom Stereo OnOff" 1
' >>$MODPATH/service.sh
      ;;
    esac

    #other devices
    if [ "$tinymix_support" != "true" ]; then
      echo -e '\n
tinymix_new set "DS2 OnOff" 1
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "HiFi Filter" 1
tinymix_new set "HPH Idle Detect" ON
tinymix_new set "LPI Enable" 0
tinymix_new set "PCM Source" ASP
tinymix_new set "RCV PCM Source" ASP
tinymix_new set "Playback 0 Compress" 0
tinymix_new set "Playback 1 Compress" 0
tinymix_new set "Playback 13 Compress" 0
tinymix_new set "Playback 16 Compress" 0
tinymix_new set "Playback 27 Compress" 0
tinymix_new set "Playback 39 Compress" 0
tinymix_new set "Playback 4 Compress" 0
tinymix_new set "Playback 9 Compress" 0
tinymix_new set "Compress Gapless Playback" 0
tinymix_new set "Compress Playback 11 Volume" 0 0
tinymix_new set "Compress Playback 15 Volume" 0 0
tinymix_new set "Compress Playback 25 Volume" 0 0
tinymix_new set "Compress Playback 26 Volume" 0 0
tinymix_new set "Compress Playback 27 Volume" 0 0
tinymix_new set "Compress Playback 28 Volume" 0 0
tinymix_new set "Compress Playback 29 Volume" 0 0
tinymix_new set "Compress Playback 30 Volume" 0 0
tinymix_new set "Compress Playback 31 Volume" 0 0
tinymix_new set "Compress Playback 32 Volume" 0 0
tinymix_new set "Compress Playback 36 Volume" 0 0
tinymix_new set "Compress Playback 37 Volume" 0 0
tinymix_new set "Compress Playback 41 Volume" 0 0
tinymix_new set "Compress Playback 42 Volume" 0 0
tinymix_new set "Compress Playback 43 Volume" 0 0
tinymix_new set "Compress Playback 44 Volume" 0 0
tinymix_new set "Compress Playback 45 Volume" 0 0
tinymix_new set "RX HPH Mode" CLS_H_LOHIFI
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "Set Custom Stereo OnOff" 1
' >>$MODPATH/service.sh
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "EC Reference Bit Format" '$max_format_24'
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_3 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "BT SampleRate RX" '$max_rate_96'
tinymix_new set "BT SampleRate TX" '$max_rate_96'
tinymix_new set "BT SampleRate" '$max_rate_96'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_3 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_rate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_rate_192'
' >>$MODPATH/service.sh
      fi
    fi
  } &
fi

if [ "$VOLMEDIA" != "false" ]; then
  {
    echo -e '\n
tinymix_new set "RX_RX0 Digital Volume" '$VOLMEDIA'
tinymix_new set "RX_RX1 Digital Volume" '$VOLMEDIA'
tinymix_new set "RX_RX2 Digital Volume" '$VOLMEDIA'
tinymix_new set "RX_RX0 Mix Digital Volume" '$VOLMEDIA'
tinymix_new set "RX_RX1 Mix Digital Volume" '$VOLMEDIA'
tinymix_new set "RX_RX2 Mix Digital Volume" '$VOLMEDIA'
tinymix_new set "VA_DEC0 Volume" '$VOLMEDIA'
tinymix_new set "VA_DEC1 Volume" '$VOLMEDIA'
tinymix_new set "VA_DEC2 Volume" '$VOLMEDIA'
tinymix_new set "VA_DEC3 Volume" '$VOLMEDIA'
tinymix_new set "VA_DEC4 Volume" '$VOLMEDIA'
tinymix_new set "VA_DEC5 Volume" '$VOLMEDIA'
tinymix_new set "VA_DEC6 Volume" '$VOLMEDIA'
tinymix_new set "VA_DEC7 Volume" '$VOLMEDIA'
' >>$MODPATH/service.sh
  } &
fi

#patching dolby anus and dolby media codecs files
if [ "$STEP15" == "true" ]; then
  {
    for ODCODECS in ${DCODECS}; do
      DOLBYCODECS="$MODPATH$(echo $ODCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch $ORIGDIR$ODCODECS $DOLBYCODECS
      sed -i 's/name="sample-rate" ranges=".*"/name="sample-rate" ranges="44100,48000"/g' $DOLBYCODECS
      sed -i 's/name="bitrate" ranges=".*"/name="bitrate" ranges="44100-6144000"/g' $DOLBYCODECS
    done
    for OADAXES in ${DAXES}; do
      DAX="$MODPATH$(echo $OADAXES | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch $ORIGDIR$OADAXES $DAX
      sed -i 's/<mi-dv-leveler-steering-enable value="true"/<mi-dv-leveler-steering-enable value="false"/g' $DAX
      sed -i 's/<mi-ieq-steering-enable value="true"/<mi-ieq-steering-enable value="false"/g' $DAX
      sed -i 's/<mi-surround-compressor-steering-enable value="true"/<mi-surround-compressor-steering-enable value="false"/g' $DAX
      sed -i 's/<mi-adaptive-virtualizer-steering-enable value="true"/<mi-adaptive-virtualizer-steering-enable value="false"/g' $DAX
      sed -i 's/<reverb-suppression-enable value="true"/<reverb-suppression-enable value="false"/g' $DAX
      sed -i 's/<mi-dialog-enhancer-steering-enable value="true"/<mi-dialog-enhancer-steering-enable value="false"/g' $DAX
      sed -i 's/<dialog-enhancer-enable value="true"/<dialog-enhancer-enable value="false"/g' $DAX
      sed -i 's/<mi-virtualizer-binaural-steering-enable value="true"/<mi-virtualizer-binaural-steering-enable value="false"/g' $DAX
      sed -i 's/<peak-value value=".*"/<peak-value value="256"/g' $DAX
      sed -i 's/<surround-decoder-enable value="true"/<surround-decoder-enable value="false"/g' $DAX
      sed -i 's/<hearing-protection-enable value="true"/<hearing-protection-enable value="false"/g' $DAX
      sed -i 's/<volume-leveler-enable value="true"/<volume-leveler-enable value="false"/g' $DAX
      sed -i 's/<height-filter-mode value=".*"/<height-filter-mode value="0"/g' $DAX
      sed -i 's/<volume-leveler-compressor-enable value="true"/<volume-leveler-compressor-enable value="false"/g' $DAX
      sed -i 's/<complex-equalizer-enable value="true"/<complex-equalizer-enable value="false"/g' $DAX
      sed -i 's/<regulator-speaker-dist-enable value="true"/<regulator-speaker-dist-enable value="false"/g' $DAX
      sed -i 's/<regulator-sibilance-suppress-enable value="true"/<regulator-sibilance-suppress-enable value="false"/g' $DAX
      sed -i 's/bass-mbdrc-enable value="true"/bass-mbdrc-enable value="false"/g' $DAX
      sed -i 's/threshold_low=".*" threshold_high=".*"/threshold_low="0" threshold_high="0"/g' $DAX
      sed -i 's/isolated_band="true"/isolated_band="false"/g' $DAX
      sed -i '/endpoint_type="headphone"/,/<\/tuning>/s/<audio-optimizer-enable value="true"/<audio-optimizer-enable value="false"/g' $DAX
      sed -i '/<output-mode>/,/<\/output-mode>' $DAX
      sed -i '/<mix_matrix>/,/</output-mode>' $DAX
    done
    echo -e "\n
ro.vendor.audio.dolby.eq.half=true
ro.vendor.audio.dolby.dax.support=true
ro.vendor.audio.dolby.surround.enable=true
ro.vendor.audio.dolby.fade_switch=true
vendor.audio.dolby.control.support=true
vendor.audio.dolby.control.tunning.by.volume.support=true
vendor.audio.dolby.ds2.enabled=true
ro.vendor.platform.support.dolby=true" >>$PROP
  } &
fi

if [ "$DELETEACDB" != "false" ]; then
  {
    for OOLDACDBS in ${OLDACDBS}; do
      OLDACDBS="$MODPATH$(echo $OOLDACDBS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      mkdir -p "$(dirname "$OLDACDBS")"
      touch "$OLDACDBS"
    done
  } &
fi

# Checking for internet connection before installing ACDB
if [ "$PATCHACDB" == "true" ]; then
  if ! timeout 3 ping -c 1 github.com >/dev/null 2>&1; then
    ui_print "! No Internet, skipping ACDB."
  else
    ui_print "- Downloading acdb. Please wait..."
    ui_print " "
    mkdir -p "$ACDBDIR"
    wget -P "$ACDBDIR" --no-check-certificate "$ACDB"
    unzip -d "$ACDBDIR" "$ACDBDIR/$DEVICE.zip"
    rm -rf "$ACDBDIR/$DEVICE.zip"
    if [ $(find "$ACDBDIR" -type f | wc -l) -gt 0 ]; then
      ui_print "- acdb successfully integrated!"
    else
      ui_print "! Connection error: ACDB skipped."
    fi
    ui_print " "
  fi
fi
wait

# Writing tinymix parameters in the mixer
if [ "$STEP14" == "true" ] || [ "$VOLMEDIA" != "false" ]; then
  {
    echo -e '\nkill $(pidof audioserver)' >>$MODPATH/service.sh
    MARKER="    <!-- Parameters added by NLSound -->"
    temp_file="/storage/emulated/0/NLSound/mix.tmp"
    sed_file="/storage/emulated/0/NLSound/sed.tmp"
    {
      echo "$MARKER"
      grep "tinymix_new" "$MODPATH/service.sh" | while read -r line; do
        name=$(echo "$line" | sed -E 's/.*set "([^"]+)".*/\1/')
        value=$(echo "$line" | sed -E 's/.*set "[^"]+"[[:space:]]+//; s/"//g; s/[[:space:]]+/ /g')
        echo "    <ctl name=\"$name\" value=\"$value\" />"
        escaped_name=$(echo "$name" | sed 's/[\/&]/\\&/g')
        echo "s/\"$escaped_name\" value=\".*\"/\"$escaped_name\" value=\"$value\"/g" >&3
      done 3>"$sed_file"
    } >"$temp_file"

    for OMIX in ${MPATHS}; do
      MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      [ -s "$sed_file" ] && sed -i -f "$sed_file" "$MIX"
      if ! grep -q "$MARKER" "$MIX"; then
        indent=$(sed -n '/<\/mixer>/{x;p;d}' "$MIX" | grep -o '^[[:space:]]*')
        awk -v marker="$MARKER" -v indent="$indent" -v new_content="$(sed "s/^/$indent/" "$temp_file")" '
      BEGIN {gsub(/\n/, "\n" indent, new_content)}
      /<\/mixer>/ {print new_content}
      {print}
    ' "$MIX" >"${MIX}.tmp" && mv "${MIX}.tmp" "$MIX"
      fi
    done
    rm -f "$temp_file" "$sed_file"
  } &
fi

wait
ui_print " "
ui_print " - With love, NLSound Team"
ui_print " "
