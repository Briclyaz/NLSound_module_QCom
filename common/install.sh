#!/system/bin/sh

MODID="NLSound"
NLSDIR="/data/adb/modules/NLSound"
MIRRORDIR="/data/local/tmp/NLSound"
OTHERTMPDIR="/dev/NLSound"
PROP="$MODPATH/system.prop"
RESTORE_SETTINGS="$NLSDIR/settings.nls"
VERSION="$(grep "^version=" "$MODPATH/module.prop" | cut -d'=' -f2-)"

LANG="$(settings get system system_locales)"
DEVICE="$(getprop ro.product.vendor.device)"
if [ "$DEVICE" == "mivendor" ]; then
  DEVICE="$(getprop ro.product.device)" # mi14ultra - aurora, mi13ultra - ishtar, RN13 - sapphire
fi
PROCESSOR="$(getprop ro.board.platform)"
case "$(getprop ro.hardware)" in mt*)
  isMTK=true
  ;;
esac

normalize_path() {
  local file="$1"

  if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ] || [ -d "/data/adb/modules/magisk_overlayfs" ] || [ -d "/data/adb/modules/mountify" ] || [ -d "/data/adb/metamodules" ]; then
    case "$file" in
      /system/vendor/*)     echo "${file#/system}" ;;
      /system/product/*)    echo "${file#/system}" ;;
      /system/system_ext/*) echo "${file#/system}" ;;
      /system/odm/*)        echo "${file#/system}" ;;
      /system/my_product/*) echo "${file#/system}" ;;
      /system/*)            echo "$file" ;;
      /*)                   echo "$file" ;;
      *)                    echo "/$file" ;;
    esac
  else
    case "$file" in
      /system/* | /system)  echo "$file" ;;
      *)                    echo "/system/${file#/}" ;;
    esac
  fi
}

ACDB="https://github.com/Briclyaz/NLSound_module_acdb_addon/raw/refs/heads/main/$DEVICE.zip"
ACDBDIR="$MODPATH$(normalize_path "/vendor/etc/acdbdata")"
SEPARATOR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# import language strings
if [[ "$LANG" =~ "en-RU" ]] || [[ "$LANG" =~ "ru-" ]]; then
  source "$MODPATH/common/russiantext.sh"
elif [[ "$LANG" =~ "zh-" ]]; then
  source "$MODPATH/common/chinesetext.sh"
else
  source "$MODPATH/common/englishtext.sh"
fi

# Добавляем пути рут-менеджеров в PATH (Magisk, KernelSU, APatch)
export PATH="/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH"

# Собираем существующие каталоги
SEARCH_DIRS=""
for d in /system /vendor /system_ext /mi_ext /product /odm /my_product; do
  [ -d "$d" ] && SEARCH_DIRS="$SEARCH_DIRS $d/"
done

while IFS= read -r file; do
  case "$file" in
  */audio_configs*.xml) ACONFS="$ACONFS$file"$'\n' ;;
  */"$DEVICE".xml) DEVFEAS="$DEVFEAS$file"$'\n' ;;
  */oplus.product.feature*.xml|\
  */oplus.product.features*.xml|\
  */realme_product_rom_feature*.xml|\
  */realme_product_rom_oplus_feature*.xml|\
  */oplus_feature_config.xml|\
  */com.oplus.features*.xml|\
  */com.oppo.features*.xml|\
  */com.realme.features*.xml|\
  */com.oplus.app-features.xml|\
  */com.oplus.oplus-feature.xml)
  DEVFEAS="$DEVFEAS$file"$'\n';;
  */DeviceFeatures.xml|\
  */handheld_core_hardware.xml|\
  */platform.xml|\
  */android.hardware.audio.pro.xml) 
  DEVFEASNEW="$DEVFEASNEW$file"$'\n' ;;
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
  */audio_effects*.conf) AEFFECTCONFS="$AEFFECTCONFS$file"$'\n' ;;
  */audio_effects*.xml) AEFFECTXMLS="$AEFFECTXMLS$file"$'\n' ;;
  */microphone_characteristics*.xml) MICXARS="$MICXARS$file"$'\n' ;;
  */*audio_device*.xml) ADEVS="$ADEVS$file"$'\n' ;;
  */*aurisys_config*.xml) AURCONFS="$AURCONFS$file"$'\n' ;;
  */*AudioParamOptions*.xml) APAROPTS="$APAROPTS$file"$'\n' ;;
  */*backend_conf*.xml) BACKEND_CONFS="$BACKEND_CONFS$file"$'\n' ;;
  */*AudioEffectCenter*.apk | */*AudioFX*.apk | */*MusicFX*.apk | */*SamsungDAP*.apk) APPS="$APPS$file"$'\n' ;;
  */*Headset_cal.acdb | */*Hdmi_cal.acdb | */*Bluetooth_cal.acdb | */*Speaker_cal.acdb | */*General_cal.acdb | */*Global_cal.acdb) OLDACDBS="$OLDACDBS$file"$'\n' ;;
  */maximum_substreams) SUBSTREAMS="$SUBSTREAMS$file"$'\n' ;;
  */high_perf_mode | */impedance_detect_en) SUSFLAGS="$SUSFLAGS$file"$'\n' ;;
  *) ;; 
  esac
done < <(
  find -H $SEARCH_DIRS \
    \( -path "*/lib" -o -path "*/lib64" -o -path "*/framework" -o -path "*/fonts" -o -path "*/bin" \) -prune -o \
    \( -type f -o -type l \) \( \
      -name "*.xml" -o \
      -name "*.conf" -o \
      -name "*.acdb" -o \
      -name "*.apk" \
    \) -print 2>/dev/null

  if [ -d /sys/module ]; then
    find /sys/module -maxdepth 3 -type f \( \
      -name "maximum_substreams" -o \
      -name "high_perf_mode" -o \
      -name "impedance_detect_en" \
    \) -print 2>/dev/null
  fi
)

HAS_TFA=false HAS_CIRRUS=false HAS_TAS=false HAS_AWINIC=false HAS_MAXIM=false
HAS_WSA=false HAS_WCD=false HAS_ESS=false HAS_AKM=false
pa_found=false
codec_found=false

is_chip_connected() {
  local drv
  for drv in /sys/bus/i2c/drivers/*"$1"* \
             /sys/bus/soundwire/drivers/*"$1"* \
             /sys/bus/slimbus/drivers/*"$1"* \
             /sys/bus/platform/drivers/*"$1"*; do
    [ -d "$drv" ] && ls "$drv" 2>/dev/null | grep -qEv '^(bind|unbind|uevent|module)$' && return 0
  done
  return 1
}

detect_pa() {
  if is_chip_connected "$2"; then
    eval "$1=true"
    ui_print "  [+] $3"
    pa_found=true
  fi
}

detect_codec() {
  if [ "$codec_found" = "true" ]; then return 0; fi
  if echo "$SYS_AUDIO" | grep -qE "$2" || is_chip_connected "$2"; then
    eval "$1=true"
    ui_print "  [+] $3"
    codec_found=true
  fi
}

SYS_AUDIO="$(
  {
    cat /proc/asound/cards /proc/asound/pcm 2>/dev/null
    ls -d /sys/bus/soundwire/drivers/* /sys/bus/soundwire/devices/* 2>/dev/null
    ls -d /sys/bus/slimbus/drivers/* /sys/bus/slimbus/devices/* 2>/dev/null
    ls -d /sys/bus/i2c/drivers/* /sys/bus/i2c/devices/* 2>/dev/null
    ls -d /sys/bus/platform/drivers/* 2>/dev/null
    ls -d /sys/devices/platform/soc/*macro* /sys/devices/platform/soc/*audio* 2>/dev/null
    [ -d /proc/device-tree ] && grep -saoE '[a-zA-Z0-9_-]+(wcd|bolero|macro|es9|ak4|cs4)[a-zA-Z0-9_-]+' /proc/device-tree 2>/dev/null
    # Проверка характерных аппаратных регистров кодека в микшерах устройства
    [ -n "$MPATHS" ] && grep -siohE 'wcd|bolero|rx_macro|tx_macro|rx int0 dem mux|dec0 mode|es9[0-9]{3}|ak4[0-9]{3}' $MPATHS 2>/dev/null
  } | tr '[:upper:]' '[:lower:]'
)"

ui_print " "
ui_print "$SEPARATOR"
ui_print "$HW_HEADER"
ui_print "$SEPARATOR"

detect_pa HAS_CIRRUS "cs35l" "$HW_CIRRUS"
detect_pa HAS_TFA    "tfa9"  "$HW_TFA"
detect_pa HAS_TAS    "tas25" "$HW_TAS"
detect_pa HAS_AWINIC "aw88"  "$HW_AWINIC"
detect_pa HAS_MAXIM  "max98" "$HW_MAXIM"
detect_pa HAS_WSA    "wsa88" "$HW_WSA"

detect_codec HAS_ESS "es90[0-9]{2}|es92[0-9]{2}|es93[0-9]{2}|sabredac" "$HW_ESS"
detect_codec HAS_AKM "ak43[0-9]{2}|ak44[0-9]{2}|ak49[0-9]{2}" "$HW_AKM"
detect_codec HAS_WCD "wcd|bolero|rx_macro|tx_macro|lpass.*macro|dec0 mode|rx int0 dem mux" "$HW_WCD"

[ "$codec_found" = "true" ] || ui_print "$HW_SOC"

ui_print "$SEPARATOR"
ui_print " "

handle_input() {
  while true; do
    case $(getevent -lq 2>/dev/null | grep -m 1 -E 'KEY_VOLUME(UP|DOWN).*DOWN') in
      *KEY_VOLUMEUP*)   echo "up"; return ;;
      *KEY_VOLUMEDOWN*) echo "down"; return ;;
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
        return $selected
        ;;
      esac
    done
  fi
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
PATCHACDB=false
DELETEACDB=false

continue_script=true
if [ -f "$RESTORE_SETTINGS" ]; then
  echo -e "\n$RESTORE"
  show_menu $SMENU
  if [ $? -eq 1 ]; then
    continue_script=false
    source "$RESTORE_SETTINGS"
    export SAMPLERATE BITNES VOLMIC VOLMEDIA VOLSTEPS STEP6 STEP7 STEP8 STEP9 STEP10 STEP11 STEP12 STEP13 STEP14 PATCHACDB DELETEACDB
  else
    echo -e "$SMENUSKIP\n\n"
    sleep 0.3
  fi
fi

if [ "$continue_script" = "true" ]; then
  # 01. Volume steps
  echo -e "\n$STRINGSTEP1"
  show_menu $SMENU1
  case $? in
  1) VOLSTEPS="false" ;;
  2) VOLSTEPS="30" ;;
  3) VOLSTEPS="50" ;;
  4) VOLSTEPS="100" ;;
  esac

  # 02. Media volume
  echo -e "\n\n\n$STRINGSTEP2"
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

  # 03. Mic sensitivity
  echo -e "\n\n\n$STRINGSTEP3"
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

  # 04. Bit depth
  echo -e "\n\n\n$STRINGSTEP4"
  show_menu $SMENU4
  case $? in
  1) BITNES="false" ;;
  2) BITNES="16" ;;
  3) BITNES="24" ;;
  4) BITNES="32" ;;
  5) BITNES="float" ;;
  esac

  # 05. Sample rate
  echo -e "\n\n\n$STRINGSTEP5"
  show_menu $SMENU5
  case $? in
  1) SAMPLERATE="false" ;;
  2) SAMPLERATE="44100" ;;
  3) SAMPLERATE="48000" ;;
  4) SAMPLERATE="96000" ;;
  5) SAMPLERATE="192000" ;;
  6) SAMPLERATE="384000" ;;
  esac

  # 06. DRC & Limiters
  echo -e "\n\n\n$STRINGSTEP6\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP6=true

  # 07. Vendor Hi-Fi
  echo -e "\n\n\n$STRINGSTEP7"
  if [ -n "$DEVFEASNEW" ] || [ -n "$DEVFEAS" ]; then
    echo -e "$INSTALLSKIP"
    show_menu $SMENU
    [ $? -eq 1 ] && STEP7=true
  else
    echo -e "$SMENUAUTOSKIP\n"
  fi

  # 08. Sub-bass
  echo -e "\n\n\n$STRINGSTEP8\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP8=true

  # 09. build.prop
  echo -e "\n\n\n$STRINGSTEP9\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP9=true

  # 10. Bluetooth
  echo -e "\n\n\n$STRINGSTEP10\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP10=true

  # 11. Direct PCM
  echo -e "\n\n\n$STRINGSTEP11"
  if [ -n "$IOPOLICYS" ] || [ -n "$OUTPUTPOLICYS" ]; then
    echo -e "$INSTALLSKIP"
    show_menu $SMENU
    [ $? -eq 1 ] && STEP11=true
  else
    echo -e "$SMENUAUTOSKIP\n"
  fi

  # 12. Audio effects
  echo -e "\n\n\n$STRINGSTEP12"
  show_menu $SMENU12
  case $? in
  1) STEP12="false" ;;
  2) STEP12="part" ;;
  3) STEP12="full" ;;
  esac

  # 13. Hardware tweaks
  echo -e "\n\n\n$STRINGSTEP13\n"
  show_menu $SMENU
  [ $? -eq 1 ] && STEP13=true

  # 14. Dolby Atmos
  echo -e "\n\n\n$STRINGSTEP14"
  if { [ -n "$DAXES" ] || [ -n "$DCODECS" ]; } && [ "$STEP12" != "full" ]; then
    echo -e "$INSTALLSKIP"
    show_menu $SMENU
    [ $? -eq 1 ] && STEP14=true
  else
    echo -e "$SMENUAUTOSKIP\n"
  fi

  # 15. ACDB
  echo -e "\n\n\n"
  if [ -n "$OLDACDBS" ]; then
    ui_print "$STRINGSTEP15"
    show_menu $SMENU15
    case $? in
    1) DELETEACDB="false" ;;
    2) DELETEACDB="Basic" ;;
    3) DELETEACDB="General" ;;
    4) DELETEACDB="Speaker" ;;
    esac
  else
    echo -e "$STRINGSTEP151"
    case "$DEVICE" in alioth* | Pong* | marble* | RE5465* | mondrian* | ishtar* | aurora* | REE2B2L1* | PQ83A01*)
      echo -e "$INSTALLSKIP"
      show_menu $SMENU
      [ $? -eq 1 ] && PATCHACDB=true
      ;;
    *)
      echo -e "$SMENUAUTOSKIP\n"
      ;;
    esac
  fi
fi

echo -e "\n\n"
final_print_text
ui_print " "

# Writing settings
echo -e "#installer options\n#Below you can see the decoding of the names of the points,\n#or trust the numerical values of the points.\n\n#STEP1=Select volume steps\n#STEP2=Increase media volumes\n#STEP3=Improving microphones sensitivity\n#STEP4=Select audio format (16..float)\n#STEP5=Select sampling rates (96..384000)\n#STEP6=Turn off sound interference\n#STEP7=Patching device_features files\n#STEP8=Other patches in mixer_paths files\n#STEP9=Tweaks for build.prop files\n#STEP10=Improve bluetooth\n#STEP11=Switch audio output (DIRECT -> DIRECT_PCM)\n#STEP12=Ignore all audio effects\n#STEP13=Install experimental tweaks for tinymix\n#STEP14=Configure Dolby Atmos\n#PATCHACDB=Install patched ACDB files\n#DELETEACDB=Deleting acdb files\n\n#Module version: $VERSION\n#Device: $DEVICE\n\nVOLSTEPS=$VOLSTEPS\nVOLMEDIA=$VOLMEDIA\nVOLMIC=$VOLMIC\nBITNES=$BITNES\nSAMPLERATE=$SAMPLERATE\nSTEP6=$STEP6\nSTEP7=$STEP7\nSTEP8=$STEP8\nSTEP9=$STEP9\nSTEP10=$STEP10\nSTEP11=$STEP11\nSTEP12=$STEP12\nSTEP13=$STEP13\nSTEP14=$STEP14\nPATCHACDB=$PATCHACDB\nDELETEACDB=$DELETEACDB" > "$MODPATH/settings.nls"

case "$SAMPLERATE" in
  "44100")
    RATE="KHZ_44P1" max_rate_192="KHZ_44P1" max_rate_96="KHZ_44P1" mtk_rate="7"
    CUTOFF="90"
    ;;
  "48000")
    RATE="KHZ_48"   max_rate_192="KHZ_48"   max_rate_96="KHZ_48"   mtk_rate="8"
    CUTOFF="90"
    ;;
  "96000")
    RATE="KHZ_96"   max_rate_192="KHZ_96"   max_rate_96="KHZ_96"   mtk_rate="10"
    CUTOFF="93"
    ;;
  "192000")
    RATE="KHZ_192"  max_rate_192="KHZ_192"  max_rate_96="KHZ_96"   mtk_rate="12"
    CUTOFF="93"
    ;;
  "384000")
    RATE="KHZ_384"  max_rate_192="KHZ_192"  max_rate_96="KHZ_96"   mtk_rate="12"
    CUTOFF="93"
    ;;
  *)
    RATE="KHZ_48"   max_rate_192="KHZ_48"   max_rate_96="KHZ_48"   mtk_rate="8"
    CUTOFF="90"
    ;;
esac

case "$BITNES" in
  "16")
    STOPBAND="100"
    ;;
  "24"|"32")
    STOPBAND="144"
    ;;
  *)
    STOPBAND="144"
    ;;
esac

case "$BITNES" in
"16") bit_width="16" max_bit_width_24="16" FORMAT="S16_LE" max_format_24="S16_LE" apc_format="AUDIO_FORMAT_PCM_16_BIT" res_format="PAL_AUDIO_FMT_PCM_S16_LE" ;;
"24") bit_width="24" max_bit_width_24="24" FORMAT="S24_LE" max_format_24="S24_LE" apc_format="AUDIO_FORMAT_PCM_24_BIT_PACKED" res_format="PAL_AUDIO_FMT_PCM_S24_LE" ;;
"32") bit_width="32" max_bit_width_24="24" FORMAT="S32_LE" max_format_24="S24_LE" apc_format="AUDIO_FORMAT_PCM_32_BIT" res_format="PAL_AUDIO_FMT_PCM_S32_LE" ;;
"float") bit_width="32" max_bit_width_24="24" FORMAT="S32_LE" max_format_24="S24_LE" apc_format="AUDIO_FORMAT_PCM_FLOAT" res_format="PAL_AUDIO_FMT_PCM_S32_LE" ;;
esac

case "$DELETEACDB" in
"Basic") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb") ;;
"General") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb|.*General_cal.acdb|.*Global_cal.acdb") ;;
"Speaker") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb|.*General_cal.acdb|.*Speaker_cal.acdb|.*Global_cal.acdb") ;;
esac

if [ "$BITNES" != "false" ] || [ "$SAMPLERATE" != "false" ] || [ "$STEP6" == "true" ]; then
  {
    for OAPIXML in ${APIXMLS}; do
      APIXML="$MODPATH$(normalize_path "$OAPIXML")"
      cp_ch "$ORIGDIR$OAPIXML" "$APIXML"
      if [ "$BITNES" != "false" ]; then
        sed -i 's/device name="SND_DEVICE_OUT_SPEAKER" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER" bit_width="'$bit_width'"/g
                s/device name="SND_DEVICE_OUT_HEADPHONES" bit_width=".*"/device name="SND_DEVICE_OUT_HEADPHONES" bit_width="'$bit_width'"/g
                s/device name="SND_DEVICE_OUT_SPEAKER_REVERSE" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER_REVERSE" bit_width="'$bit_width'"/g
                s/device name="SND_DEVICE_OUT_SPEAKER_PROTECTED" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER_PROTECTED" bit_width="'$bit_width'"/g
                s/device name="SND_DEVICE_OUT_HEADPHONES_44_1" bit_width=".*"/device name="SND_DEVICE_OUT_HEADPHONES_44_1" bit_width="'$bit_width'"/g
                s/device name="SND_DEVICE_OUT_GAME_SPEAKER" bit_width=".*"/device name="SND_DEVICE_OUT_GAME_SPEAKER" bit_width="'$bit_width'"/g
                s/device name="SND_DEVICE_OUT_GAME_HEADPHONES" bit_width=".*"/device name="SND_DEVICE_OUT_GAME_HEADPHONES" bit_width="'$bit_width'"/g
                s/device name="SND_DEVICE_OUT_BT_A2DP" bit_width=".*"/device name="SND_DEVICE_OUT_BT_A2DP" bit_width="'$bit_width'"/g
                s/\(app uc_type=".*" mode="default" bit_width="\)[^"]*"/\1'$bit_width'"/g' $APIXML
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        sed -i 's/\(app uc_type=".*" mode="default" bit_width=".*" id=".*" max_rate="\)[^"]*"/\1'$SAMPLERATE'"/g' $APIXML
      fi
      if [ "$STEP6" == "true" ]; then
        sed -i 's/param key="native_audio_mode" value="false"/param key="native_audio_mode" value="true"/g
                s/param key="hfp_pcm_dev_id" value=".*"/param key="hfp_pcm_dev_id" value="39"/g
                s/param key="input_mic_max_count" value=".*"/param key="input_mic_max_count" value="4"/g
                s/param key="true_32_bit" value=".*"/param key="true_32_bit" value="true"/g
                s/param key="hifi_filter" value=".*"/param key="hifi_filter" value="true"/g
                s/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g
                s/param key="config_spk_protection" value=".*"/param key="config_spk_protection" value="false"/g
                s/param key="native_audio_44.1k_support" value=".*"/param key="native_audio_44.1k_support" value="true"/g
                s/param key="usb_output_direct_pcm" value=".*"/param key="usb_output_direct_pcm" value="true"/g
                s/param key="bit_perfect_supported" value=".*"/param key="bit_perfect_supported" value="true"/g
                s/param key="usb_offload_burst_mode" value=".*"/param key="usb_offload_burst_mode" value="true"/g
                s/param key="avoid_processing" value=".*"/param key="avoid_processing" value="true"/g
                s/param key="dsp_bit_width" value=".*"/param key="dsp_bit_width" value="24"/g' $APIXML
      fi
    done
    #patching resourcemanager files
    for OARESOURCES in ${RESOURCES}; do
      RES="$MODPATH$(normalize_path "$OARESOURCES")"
      cp_ch $ORIGDIR$OARESOURCES $RES
      if [ "$STEP6" == "true" ]; then
        sed -i 's/<param key="hifi_filter" value="false"/<param key="hifi_filter" value="true"/g
                s/param key="native_audio_mode" value="false"/param key="native_audio_mode" value="true"/g
                s/param key="oplus_ear_protection_enable" value=".*"/param key="oplus_ear_protection_enable" value="false"/g
                s/<param lpi_enable="true"/<param lpi_enable="false"/g
                s/param key="oplus_hdr_record" value="false"/param key="oplus_hdr_record" value="true"/g
                s/param key="adsp_ssr_support" value="yes"/param key="adsp_ssr_support" value="no"/g
                #s/<fractional_sr>1/<fractional_sr>0/g # need test
                s/param key="lowbattery_speaker_profile_support" value="true"/param key="lowbattery_speaker_profile_support" value="false"/g
                s/param key="oplus_check_speaker" value="true"/param key="oplus_check_speaker" value="false"/g
                s/param key="config_spk_protection" value=".*"/param key="config_spk_protection" value="false"/g
                s/param key="native_audio_44.1k_support" value=".*"/param key="native_audio_44.1k_support" value="true"/g
                s/param key="usb_output_direct_pcm" value=".*"/param key="usb_output_direct_pcm" value="true"/g
                s/param key="bit_perfect_supported" value=".*"/param key="bit_perfect_supported" value="true"/g
                s/param key="usb_offload_burst_mode" value=".*"/param key="usb_offload_burst_mode" value="true"/g
                s/param key="avoid_processing" value=".*"/param key="avoid_processing" value="true"/g
                s/param key="dsp_bit_width" value=".*"/param key="dsp_bit_width" value="24"/g
                /<!--HIFI Filter Headphones-Uncomment this when param key hifi_filter is true/,/-->/{s/^ *<!--\(.*\)$/\1/; s/^\(.*\)-->/\1/; /^ *HIFI Filter Headphones-Uncomment this when param key hifi_filter is true *$/d}' $RES
        # [ "$R12P+, OP13, OPPOFX6P" ]
        case "$DEVICE" in RE5C82L1* | RE5C3B* | OP5D55L1*| OP528BL1*)
          sed -i 's/<speaker_protection_enabled>1/<speaker_protection_enabled>0/g
                  s/<ras_enabled>1/<ras_enabled>0/g' $RES
          ;;
        esac
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        # [ "R12P+" ]
        case "$DEVICE" in RE5C82L1* | RE5C3B*)
          if [ "$SAMPLERATE" != "44100" ] && [ "$SAMPLERATE" != "384000" ]; then #breaks the sound from the speakers at this sampling rate, on other devices it causes the speaker to fail
            sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /<id>PAL_DEVICE_OUT_SPEAKER<\/id>/!b; s/<samplerate>(44100|48000|96000|192000|384000)<\/samplerate>/<samplerate>'"$SAMPLERATE"'<\/samplerate>/g}' "$RES"
          fi
          ;;
        esac
        #changing sampling frequency PAL_DEVICE_OUT_HANDSET breaks calls
        sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /<id>(PAL_DEVICE_NONE|PAL_DEVICE_OUT_PROXY|PAL_DEVICE_OUT_WIRED_HEADSET|PAL_DEVICE_OUT_WIRED_HEADPHONE)<\/id>/!b; s/<samplerate>(44100|48000|96000|192000|384000)<\/samplerate>/<samplerate>'"$SAMPLERATE"'<\/samplerate>/g}
                   #BT
                   /<out-device>/{:a; N; /<\/out-device>/!ba; /<id>(PAL_DEVICE_OUT_BLUETOOTH_SCO)<\/id>/!b; s/<samplerate>(8000|44100|48000|96000|192000|384000)<\/samplerate>/<samplerate>'"$SAMPLERATE"'<\/samplerate>/g}' "$RES"
      fi
      if [ "$BITNES" != "false" ]; then
        case "$DEVICE" in RE5C82L1* | RE5C3B* | OP5D55L1*)
          sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /<id>PAL_DEVICE_OUT_SPEAKER<\/id>/!b; s/<bit_width>(16|24|32)<\/bit_width>/<bit_width>'"$bit_width"'<\/bit_width>/g}' "$RES" ;;
        esac
        case "$DEVICE" in RE5C82L1* | RE5C3B* | OP5D55L1*)
            sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /PAL_DEVICE_OUT_SPEAKER/!b; s/<supported_bit_format>[^<]*/<supported_bit_format>'"$res_format"'/g}' "$RES"
            sed -i -E '/<upd_rx_(handset|speaker)>/{:a; N; /<\/upd_rx_(handset|speaker)>/!ba; \
            s/bit_width="(16|24|32)"/bit_width="'"$bit_width"'"/g; \
            s/bit_fmt="[^"]*"/bit_fmt="'"$res_format"'"/g}' "$RES" ;;
        esac
        # EDIT: PAL_DEVICE_OUT_HANDSET DELETED
        sed -i -E '/<out-device>/{:a; N; /<\/out-device>/!ba; /<id>(PAL_DEVICE_NONE|PAL_DEVICE_OUT_PROXY|PAL_DEVICE_OUT_WIRED_HEADSET|PAL_DEVICE_OUT_WIRED_HEADPHONE)<\/id>/!b; s/<bit_width>(16|24|32)<\/bit_width>/<bit_width>'"$bit_width"'<\/bit_width>/g}' "$RES"  
      fi
    done

    #patching audio_policy_configuration 
    for OAUDIOPOLICY in ${AUDIOPOLICYS}; do
      AUDIOPOLICY="$MODPATH$(normalize_path "$OAUDIOPOLICY")"
      cp_ch $ORIGDIR$OAUDIOPOLICY $AUDIOPOLICY
      if [ "$STEP6" == "true" ]; then
        sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        sed -i -E "/<mixPort name=\"(virtual output.*|usb_accessory output|deep_buffer|direct_pcm|usb_surround_sound)\"/,/<\/mixPort>/ {/<profile /{:$;N;/\/>/!b$;s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/}}" "$AUDIOPOLICY"  
        sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_SPEAKER|AUDIO_DEVICE_OUT_IP|AUDIO_DEVICE_OUT_USB_ACCESSORY|AUDIO_DEVICE_OUT_WIRED_HEADSET|AUDIO_DEVICE_OUT_WIRED_HEADPHONE|AUDIO_DEVICE_OUT_LINE|AUDIO_DEVICE_OUT_AUX_DIGITAL|AUDIO_DEVICE_OUT_PROXY|AUDIO_DEVICE_OUT_FM|AUDIO_DEVICE_OUT_USB_DEVICE|AUDIO_DEVICE_OUT_USB_HEADSET)\"[^>]*>/ {:a; N; /<\/devicePort>/!ba; s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/g}" "$AUDIOPOLICY"
        sed -i -E "/<mixPort name=\"(hearing aid output|a2dp_lhdc output)\"/,/<\/mixPort>/ {/<profile /{:$;N;/\/>/!b$;s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/}}" "$AUDIOPOLICY"
        sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_BLUETOOTH_A2DP|AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_HEADPHONES|AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_SPEAKER)\"/,/<\/devicePort>/ {/<profile /{:$;N;/\/>/!b$;s/samplingRates=\"[^\"]*\"/samplingRates=\"$SAMPLERATE\"/}}" "$AUDIOPOLICY"
      fi
      if [ "$BITNES" != "false" ]; then
        sed -i -E "/<mixPort name=\"(virtual output.*|usb_accessory output|deep_buffer|direct_pcm|usb_surround_sound)\"/,/<\/mixPort>/ {/<profile /{:$;N;/\/>/!b$;s/format=\"[^\"]*\"/format=\"$apc_format\"/}}" "$AUDIOPOLICY"
        sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_SPEAKER|AUDIO_DEVICE_OUT_IP|AUDIO_DEVICE_OUT_USB_ACCESSORY|AUDIO_DEVICE_OUT_WIRED_HEADSET|AUDIO_DEVICE_OUT_WIRED_HEADPHONE|AUDIO_DEVICE_OUT_LINE|AUDIO_DEVICE_OUT_AUX_DIGITAL|AUDIO_DEVICE_OUT_PROXY|AUDIO_DEVICE_OUT_FM|AUDIO_DEVICE_OUT_USB_DEVICE|AUDIO_DEVICE_OUT_USB_HEADSET)\"[^>]*>/ {:a; N; /<\/devicePort>/!ba; s/format=\"[^\"]*\"/format=\"$apc_format\"/g}" "$AUDIOPOLICY"
        sed -i -E "/<mixPort name=\"(hearing aid output|a2dp_lhdc output)\"/,/<\/mixPort>/ {/<profile /{:$;N;/\/>/!b$;s/format=\"[^\"]*\"/format=\"$apc_format\"/}}" "$AUDIOPOLICY"
        sed -i -E "/<devicePort [^>]*type=\"(AUDIO_DEVICE_OUT_BLUETOOTH_A2DP|AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_HEADPHONES|AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_SPEAKER)\"/,/<\/devicePort>/ {/<profile /{:$;N;/\/>/!b$;s/format=\"[^\"]*\"/format=\"$apc_format\"/}}" "$AUDIOPOLICY"
      fi
    done

    #patching backend_conf.xml
    for OBACKEND_CONF in ${BACKEND_CONFS}; do
      BACKEND_CONF="$MODPATH$(normalize_path "$OBACKEND_CONF")"
      cp_ch "$ORIGDIR$OBACKEND_CONF" "$BACKEND_CONF"

      if [ "$SAMPLERATE" != "false" ]; then
        sed -i "/<device/s/rate=\"[0-9]*\"/rate=\"$SAMPLERATE\"/g" "$BACKEND_CONF"
      fi

      if [ "$BITNES" != "false" ]; then
        sed -i "/<device/s/bits=\"[0-9]*\"/bits=\"$bit_width\"/g" "$BACKEND_CONF"
      fi
    done

    #patching audio_configs.xml
    if [ "$STEP6" == "true" ] || [ "$BITNES" != "false" ]; then
      for OACONFS in ${ACONFS}; do
        ACFG="$MODPATH$(normalize_path "$OACONFS")"
        cp_ch $ORIGDIR$OACONFS $ACFG
        if [ "$STEP6" == "true" ]; then
          sed -i \
            -e 's/"spkr_protection" value="[^"]*"/"spkr_protection" value="false"/g' \
            -e 's/"audio.deep_buffer.media" value="[^"]*"/"audio.deep_buffer.media" value="false"/g' \
            -e 's/"audio.offload.disable" value="[^"]*"/"audio.offload.disable" value="false"/g' \
            -e 's/"audio.offload.min.duration.secs" value="[^"]*"/"audio.offload.min.duration.secs" value="10"/g' \
            -e 's/"audio.offload.video" value="[^"]*"/"audio.offload.video" value="false"/g' \
            -e 's/"persist.vendor.audio.sva.conc.enabled" value="[^"]*"/"persist.vendor.audio.sva.conc.enabled" value="false"/g' \
            -e 's/"persist.vendor.audio.va_concurrency_enabled" value="[^"]*"/"persist.vendor.audio.va_concurrency_enabled" value="false"/g' \
            -e 's/"vendor.audio.av.streaming.offload.enable" value="[^"]*"/"vendor.audio.av.streaming.offload.enable" value="true"/g' \
            -e 's/"vendor.audio.offload.track.enable" value="[^"]*"/"vendor.audio.offload.track.enable" value="true"/g' \
            -e 's/"vendor.audio.offload.multiple.enabled" value="[^"]*"/"vendor.audio.offload.multiple.enabled" value="true"/g' \
            -e 's/"vendor.audio.rec.playback.conc.disabled" value="[^"]*"/"vendor.audio.rec.playback.conc.disabled" value="false"/g' \
            -e 's/"vendor.voice.conc.fallbackpath" value="[^"]*"/"vendor.voice.conc.fallbackpath" value=""/g' \
            -e 's/"vendor.voice.dsd.playback.conc.disabled" value="[^"]*"/"vendor.voice.dsd.playback.conc.disabled" value="false"/g' \
            -e 's/"vendor.voice.path.for.pcm.voip" value="[^"]*"/"vendor.voice.path.for.pcm.voip" value="false"/g' \
            -e 's/"vendor.voice.playback.conc.disabled" value="[^"]*"/"vendor.voice.playback.conc.disabled" value="false"/g' \
            -e 's/"vendor.voice.record.conc.disabled" value="[^"]*"/"vendor.voice.record.conc.disabled" value="false"/g' \
            -e 's/"vendor.voice.voip.conc.disabled" value="[^"]*"/"vendor.voice.voip.conc.disabled" value="false"/g' \
            -e 's/"audio_extn_formats_enabled" value="[^"]*"/"audio_extn_formats_enabled" value="true"/g' \
            -e 's/"audio_extn_hdmi_spk_enabled" value="[^"]*"/"audio_extn_hdmi_spk_enabled" value="true"/g' \
            -e 's/"use_xml_audio_policy_conf" value="[^"]*"/"use_xml_audio_policy_conf" value="true"/g' \
            -e 's/"voice_concurrency" value="[^"]*"/"voice_concurrency" value="false"/g' \
            -e 's/"afe_proxy_enabled" value="[^"]*"/"afe_proxy_enabled" value="true"/g' \
            -e 's/"compress_voip_enabled" value="[^"]*"/"compress_voip_enabled" value="false"/g' \
            -e 's/"fm_power_opt" value="[^"]*"/"fm_power_opt" value="true"/g' \
            -e 's/"battery_listener_enabled" value="[^"]*"/"battery_listener_enabled" value="false"/g' \
            -e 's/"compress_capture_enabled" value="[^"]*"/"compress_capture_enabled" value="false"/g' \
            -e 's/"compress_metadata_needed" value="[^"]*"/"compress_metadata_needed" value="false"/g' \
            -e 's/"dynamic_ecns_enabled" value="[^"]*"/"dynamic_ecns_enabled" value="true"/g' \
            -e 's/"custom_stereo_enabled" value="[^"]*"/"custom_stereo_enabled" value="true"/g' \
            -e 's/"ext_hw_plugin_enabled" value="[^"]*"/"ext_hw_plugin_enabled" value="true"/g' \
            -e 's/"ext_qdsp_enabled" value="[^"]*"/"ext_qdsp_enabled" value="true"/g' \
            -e 's/"ext_spkr_enabled" value="[^"]*"/"ext_spkr_enabled" value="true"/g' \
            -e 's/"ext_spkr_tfa_enabled" value="[^"]*"/"ext_spkr_tfa_enabled" value="true"/g' \
            -e 's/"keep_alive_enabled" value="[^"]*"/"keep_alive_enabled" value="true"/g' \
            -e 's/"hifi_audio_enabled" value="[^"]*"/"hifi_audio_enabled" value="true"/g' \
            -e 's/"extn_resampler" value="[^"]*"/"extn_resampler" value="true"/g' \
            -e 's/"extn_flac_decoder" value="[^"]*"/"extn_flac_decoder" value="true"/g' \
            -e 's/"extn_compress_format" value="[^"]*"/"extn_compress_format" value="true"/g' \
            -e 's/"usb_offload_sidetone_vol_enabled" value="[^"]*"/"usb_offload_sidetone_vol_enabled" value="false"/g' \
            -e 's/"usb_offload_burst_mode" value="[^"]*"/"usb_offload_burst_mode" value="true"/g' \
            -e 's/"pcm_offload_enabled_16" value="[^"]*"/"pcm_offload_enabled_16" value="true"/g' \
            -e 's/"pcm_offload_enabled_24" value="[^"]*"/"pcm_offload_enabled_24" value="true"/g' \
            -e 's/"pcm_offload_enabled_32" value="[^"]*"/"pcm_offload_enabled_32" value="true"/g' \
            -e 's/"a2dp_offload_enabled" value="[^"]*"/"a2dp_offload_enabled" value="true"/g' \
            -e 's/"vendor.audio.use.sw.alac.decoder" value="[^"]*"/"vendor.audio.use.sw.alac.decoder" value="true"/g' \
            -e 's/"vendor.audio.use.sw.ape.decoder" value="[^"]*"/"vendor.audio.use.sw.ape.decoder" value="true"/g' \
            -e 's/"vendor.audio.use.sw.mpegh.decoder" value="[^"]*"/"vendor.audio.use.sw.mpegh.decoder" value="true"/g' \
            -e 's/"vendor.audio.hw.aac.encoder" value="[^"]*"/"vendor.audio.hw.aac.encoder" value="true"/g' \
            -e 's/"aac_adts_offload_enabled" value="[^"]*"/"aac_adts_offload_enabled" value="true"/g' \
            -e 's/"alac_offload_enabled" value="[^"]*"/"alac_offload_enabled" value="true"/g' \
            -e 's/"ape_offload_enabled" value="[^"]*"/"ape_offload_enabled" value="true"/g' \
            -e 's/"flac_offload_enabled" value="[^"]*"/"flac_offload_enabled" value="true"/g' \
            -e 's/"qti_flac_decoder" value="[^"]*"/"qti_flac_decoder" value="true"/g' \
            -e 's/"vorbis_offload_enabled" value="[^"]*"/"vorbis_offload_enabled" value="true"/g' \
            -e 's/"wma_offload_enabled" value="[^"]*"/"wma_offload_enabled" value="true"/g' \
            -e 's/"vendor.audio.offload.gapless.enabled" value="[^"]*"/"vendor.audio.offload.gapless.enabled" value="true"/g' \
            -e 's/"vendor.audio.offload.passthrough" value="[^"]*"/"vendor.audio.offload.passthrough" value="true"/g' \
            -e 's/"vendor.audio.parser.ip.buffer.size" value="[^"]*"/"vendor.audio.parser.ip.buffer.size" value="262144"/g' \
            "$ACFG"
        fi
        if [ "$BITNES" != "false" ]; then
          sed -i 's/"vendor.audio.flac.sw.decoder.'"${bit_width}"'bit" value="false"/"vendor.audio.flac.sw.decoder.'"${bit_width}"'bit" value="true"/g' $ACFG
        fi
      done
    fi
  } &
fi

if [ "$STEP6" == "true" ]; then
  {
    echo -e "\n
persist.vendor.audio.speaker.prot.enable=false
vendor.audio.feature.spkr_prot.enable=false
persist.config.speaker_protect_enabled=0" >>$PROP
    #patching media codecs files
    for OMCODECS in ${MCODECS}; do
    MEDIACODECS="$MODPATH$(normalize_path "$OMCODECS")"
    cp_ch "$ORIGDIR$OMCODECS" "$MEDIACODECS"

    sed -i -E '/<MediaCodec [^>]*flac/,/<\/MediaCodec>/ {
        s/name="sample-rate" ranges="[^"]*"/name="sample-rate" ranges="8000-192000"/g
        s/name="channel-count" max="[0-9]*"/name="channel-count" max="8"/g
        s/name="bitrate" ranges?="[^"]*"/name="bitrate" range="1-21000000"/g
    }' "$MEDIACODECS"

    sed -i -E '/<MediaCodec [^>]*aac\.decoder/,/<\/MediaCodec>/ {
        s/name="sample-rate" ranges="[^"]*"/name="sample-rate" ranges="7350-96000"/g
        s/name="channel-count" max="[0-9]*"/name="channel-count" max="8"/g
        s/name="bitrate" ranges?="[^"]*"/name="bitrate" range="8000-640000"/g
    }' "$MEDIACODECS"

    sed -i -E '/<MediaCodec [^>]*aac\.encoder/,/<\/MediaCodec>/ {
        s/name="channel-count" max="[0-9]*"/name="channel-count" max="6"/g
        s/name="bitrate" ranges?="[^"]*"/name="bitrate" range="8000-512000"/g
    }' "$MEDIACODECS"

    sed -i -E '/<MediaCodec [^>]*opus/,/<\/MediaCodec>/ {
        s/name="channel-count" max="[0-9]*"/name="channel-count" max="8"/g
        s/name="bitrate" ranges?="[^"]*"/name="bitrate" range="6000-510000"/g
    }' "$MEDIACODECS"

    sed -i -E '/<MediaCodec [^>]*vorbis/,/<\/MediaCodec>/ {
        s/name="sample-rate" ranges="[^"]*"/name="sample-rate" ranges="8000-192000"/g
        s/name="channel-count" max="[0-9]*"/name="channel-count" max="8"/g
    }' "$MEDIACODECS"

    sed -i -E '/<MediaCodec [^>]*(eac3|ac4|ac3)/,/<\/MediaCodec>/ {
        s/name="sample-rate" ranges="[^"]*"/name="sample-rate" ranges="32000-48000"/g
        s/name="channel-count" max="[0-9]*"/name="channel-count" max="8"/g
        s/name="bitrate" ranges?="[^"]*"/name="bitrate" range="32000-6144000"/g
    }' "$MEDIACODECS"
    done
    #patching microphone_characteristics files
    for OMICXAR in ${MICXARS}; do
      MICXAR="$MODPATH$(normalize_path "$OMICXAR")"
      cp_ch "$ORIGDIR$OMICXAR" "$MICXAR"
      sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $MICXAR
    done

    for OSUBSTREAM in ${SUBSTREAMS}; do
      echo "[ -f '$OSUBSTREAM' ] && echo 4096 > '$OSUBSTREAM'" >> "$MODPATH/service.sh"
    done
    for OSUSFLAG in ${SUSFLAGS}; do
      echo "[ -f '$OSUSFLAG' ] && echo 1 > '$OSUSFLAG'" >> "$MODPATH/service.sh"
    done
    
    #MTK
    for OAURCONF in ${AURCONFS}; do
      AURCONF="$MODPATH$(normalize_path "$OAURCONF")"
      cp_ch $ORIGDIR$OAURCONF $AURCONF
      sed -i '/library.*name="mtk_bessound"/,/\/library/{
                s/sample_rate="[^"]*"/sample_rate="8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"/g
                s/audio_format="[^"]*"/audio_format="AUDIO_FORMAT_PCM_32_BIT"/g
              }
              /library.*name="mtk_iir"/,/\/library/{
                s/sample_rate="[^"]*"/sample_rate="8000,11025,12000,16000,22050,24000,32000,44100,48000,64000,88200,96000,128000,176400,192000,384000"/g
                s/audio_format="[^"]*"/audio_format="AUDIO_FORMAT_PCM_32_BIT"/g
              }' $AURCONF
    done
    
    for OADEV in ${ADEVS}; do
      ADEV="$MODPATH$(normalize_path "$OADEV")"
      cp_ch $ORIGDIR$OADEV $ADEV
      sed -i 's/name="Audio_Speaker_class_Switch" value="[^"]*"/name="Audio_Speaker_class_Switch" value="CLASSH"/g' $ADEV
    done
    
    for OAPAROPTS in ${APAROPTS}; do 
      APAR="$MODPATH$(normalize_path "$OAPAROPTS")"
      cp_ch $ORIGDIR$OAPAROPTS $APAR
      sed -i 's/Param name="MTK_AURISYS_FRAMEWORK_SUPPORT" value=".*"/Param name="MTK_AURISYS_FRAMEWORK_SUPPORT" value="yes"/g
              s/Param name="MTK_AUDIO" value=".*"/Param name="MTK_AUDIO" value="yes"/g
              s/Param name="MTK_HIFIAUDIO_SUPPORT" value=".*"/Param name="MTK_HIFIAUDIO_SUPPORT" value="yes"/g
              s/Param name="MTK_BESLOUDNESS_SUPPORT" value=".*"/Param name="MTK_BESLOUDNESS_SUPPORT" value="no"/g
              s/Param name="MTK_BESLOUDNESS_RUN_WITH_HAL" value=".*"/Param name="MTK_BESLOUDNESS_RUN_WITH_HAL" value="no"/g
              s/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V5" value=".*"/Param name="VIR_AUDIO_BLOUD_CUSTOMPARAMETER_V5" value="no"/g
              s/Param name="MTK_AUDIO_HIERARCHICAL_PARAM_SUPPORT" value=".*"/Param name="MTK_AUDIO_HIERARCHICAL_PARAM_SUPPORT" value="yes"/g
              s/Param name="SPK_PATH_NO_ANA" value=".*"/Param name="SPK_PATH_NO_ANA" value="yes"/g
              s/Param name="RCV_PATH_INT" value=".*"/Param name="RCV_PATH_INT" value="yes"/g
              s/Param name="VIR_SCENE_CUSTOMIZATION_SUPPORT" value=".*"/Param name="VIR_SCENE_CUSTOMIZATION_SUPPORT" value="no"/g
              s/Param name="MTK_A2DP_OFFLOAD_SUPPORT" value=".*"/Param name="MTK_A2DP_OFFLOAD_SUPPORT" value="no"/g' $APAR
    done
  } &
fi

if [ "$STEP7" = "true" ] || [ "$STEP12" != "false" ]; then
    for ODEVFEA in ${DEVFEAS}; do
        DEVFEA="$MODPATH$(normalize_path "$ODEVFEA")"
        cp_ch "$ORIGDIR$ODEVFEA" "$DEVFEA"

        if [ "$STEP7" = "true" ]; then
          sed -i '
              s/name="support_samplerate_48000" value=false/name="support_samplerate_48000" value=true/g
              s/name="support_samplerate_96000" value=false/name="support_samplerate_96000" value=true/g
              s/name="support_samplerate_192000" value=false/name="support_samplerate_192000" value=true/g
              s/name="support_samplerate_352000" value=false/name="support_samplerate_352000" value=true/g
              s/name="support_samplerate_384000" value=false/name="support_samplerate_384000" value=true/g
              s/<bool name="support_samplerate_48000">false/<bool name="support_samplerate_48000">true/g
              s/<bool name="support_samplerate_96000">false/<bool name="support_samplerate_96000">true/g
              s/<bool name="support_samplerate_192000">false/<bool name="support_samplerate_192000">true/g
              s/<bool name="support_samplerate_352000">false/<bool name="support_samplerate_352000">true/g
              s/<bool name="support_samplerate_384000">false/<bool name="support_samplerate_384000">true/g
              s/name="support_low_latency" value=false/name="support_low_latency" value=true/g
              s/name="support_mid_latency" value=false/name="support_mid_latency" value=true/g
              s/name="support_high_latency" value=false/name="support_high_latency" value=true/g
              s/name="support_boost_mode" value=true/name="support_boost_mode" value=false/g
              s/<bool name="support_low_latency">false/<bool name="support_low_latency">true/g
              s/<bool name="support_mid_latency">false/<bool name="support_mid_latency">true/g
              s/<bool name="support_high_latency">false/<bool name="support_high_latency">true/g
              s/<bool name="support_boost_mode">true/<bool name="support_boost_mode">false/g
              s/name="support_dolby" value=false/name="support_dolby" value=true/g
              s/<bool name="support_dolby">false/<bool name="support_dolby">true/g
              s/name="support_hifi" value=false/name="support_hifi" value=true/g
              s/<bool name="support_hifi">false/<bool name="support_hifi">true/g
              s/name="support_playback_device" value=false/name="support_playback_device" value=true/g
              s/<bool name="support_playback_device">false/<bool name="support_playback_device">true/g
              s/name="support_audio_share" value=false/name="support_audio_share" value=true/g
              s/<bool name="support_audio_share">false/<bool name="support_audio_share">true/g
              s/name="support_lhdc_offload" value=false/name="support_lhdc_offload" value=true/g
              s/<bool name="support_lhdc_offload">false/<bool name="support_lhdc_offload">true/g
              s/name="support_bluetooth_boost" value=true/name="support_bluetooth_boost" value=false/g
              s/<bool name="support_bluetooth_boost">true/<bool name="support_bluetooth_boost">false/g
              s/name="support_a2dp_latency" value=false/name="support_a2dp_latency" value=true/g
              s/<bool name="support_a2dp_latency">false/<bool name="support_a2dp_latency">true/g
              s/name="support_24bit_record" value=false/name="support_24bit_record" value=true/g
              s/<bool name="support_24bit_record">false/<bool name="support_24bit_record">true/g
              s/name="support_hd_record_param" value=false/name="support_hd_record_param" value=true/g
              s/<bool name="support_hd_record_param">false/<bool name="support_hd_record_param">true/g
              s/name="support_stereo_record" value=false/name="support_stereo_record" value=true/g
              s/<bool name="support_stereo_record">false/<bool name="support_stereo_record">true/g
              s/name="support_interview_record_param" value=false/name="support_interview_record_param" value=true/g
              s/<bool name="support_interview_record_param">false/<bool name="support_interview_record_param">true/g
              s/name="support_camera_audio_focus" value=false/name="support_camera_audio_focus" value=true/g
              s/<bool name="support_camera_audio_focus">false/<bool name="support_camera_audio_focus">true/g
              s/name="support_phone_call_noise_suppression" value=true/name="support_phone_call_noise_suppression" value=false/g
              s/<bool name="support_phone_call_noise_suppression">true/<bool name="support_phone_call_noise_suppression">false/g
              s/name="support_earback" value=false/name="support_earback" value=true/g
              s/<bool name="support_earback">false/<bool name="support_earback">true/g
          ' "$DEVFEA"
        fi

        if [ "$STEP12" != "false" ]; then
            sed -i '
                s/name="support_dolby" value=true/name="support_dolby" value=false/g
                s/<bool name="support_dolby">true/<bool name="support_dolby">false/g
            ' "$DEVFEA"
        fi
    done
fi

if [ "$STEP7" = "true" ]; then
    for ODEVFEANEW in ${DEVFEASNEW}; do
        DEVFEANEW="$MODPATH$(normalize_path "$ODEVFEANEW")"
        cp_ch "$ORIGDIR$ODEVFEANEW" "$DEVFEANEW"

        if [ -f "$DEVFEANEW" ]; then
            sed -i '/name="android.hardware.audio.pro"/d; /name="android.hardware.broadcastradio"/d' "$DEVFEANEW"
            sed -i '
            /<permissions>/a \    <feature name="android.hardware.audio.pro"/>
            /<config>/a \    <feature name="android.hardware.audio.pro"/>
            ' "$DEVFEANEW"
        fi
    done
fi

if [ "$BITNES" != "false" ]; then
  {
    echo -e "\n
persist.audio.format.${bit_width}bit=true
persist.vendor.audio.format.${bit_width}bit=true
" >>$PROP
  } &
fi

if [ "$STEP9" = "true" ]; then
  echo -e "\n
# --- Dynamic Resampler by NLSound (${BITNES:-24}bit / ${SAMPLERATE:-48000}Hz) ---
ro.audio.resampler.psd.enable_at_samplerate=0
ro.audio.resampler.psd.stopband=$STOPBAND
ro.audio.resampler.psd.cutoff_percent=$CUTOFF
ro.audio.resampler.psd.tbwcheat=0
ro.audio.flinger_standbytime_ms=3000
audio.safemedia.csd.force=false
audio.safemedia.bypass=true
audio.sys.routing.latency=0
media.stagefright.audio.cbk=true
ro.aac_drc_effect_type=-1
aac_drc_heavy=0
aac_drc_cut=0
aac_drc_boost=0
aac_drc_enc_target_level=0
aac_drc_reference_level=-1
aaudio.mmap_policy=2
aaudio.mmap_exclusive_policy=2
aaudio.hw_burst_min_usec=4000
aaudio.mixer_bursts=2
persist.audio.hifi.int_codec=true
persist.vendor.audio.hifi.int_codec=true
vendor.audio.feature.hifi_audio.enable=true
vendor.audio.feature.extn_formats.enable=true
vendor.audio.feature.extn_flac_decoder.enable=true
vendor.audio.feature.extn_resampler.enable=true
vendor.qc2audio.per_frame.flac.dec.enabled=true
vendor.audio.usb.disable.sidetone=true
vendor.audio.tunnel.encode=false
vendor.audio.playback.dsp.pathdelay=false
vendor.audio.adm.buffering.ms=2
" >> "$PROP"

  if [ "$isMTK" = "true" ]; then
    echo -e "\n
ro.vendor.mtk_hifiaudio_support=1
ro.vendor.mtk_audio_alac_support=1
ro.vendor.mtk_audio_ape_support=1
ro.vendor.mtk_audio_flac_support=1
persist.vendor.audiohal.besloudness_state=0
" >> "$PROP"
  fi
fi

if [ "$STEP10" = "true" ]; then
  echo -e "\n
persist.bluetooth.disableabsvol=true
persist.bluetooth.a2dp_aac.vbr_supported=true
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.vendor.qcom.bluetooth.aptxadaptiver2_1_support=true
persist.vendor.qcom.bluetooth.aptxadaptiver2_2_support=true
persist.vendor.qcom.bluetooth.lossless_aptx_adaptive_le.enabled=true
persist.vendor.qcom.bluetooth.aac_vbr_ctl.enabled=true
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.qcom.bluetooth.enable.swb=true
persist.vendor.qcom.bluetooth.enable.swbpm=true
persist.vendor.qcom.bluetooth.dualmode_transport_support=true
vendor.btstack.absolute_volume=false
persist.vendor.btstack.absolute_volume=false
persist.vendor.btstack.absvolfeature=false
" >> "$PROP"
fi

if [ "$STEP12" != "false" ]; then
{
  if [ "$STEP12" = "part" ]; then

    cat << 'EOF' >> "$PROP"

ro.audio.spatializer_enabled=false
ro.audio.spatializer_binaural_enabled=false
ro.audio.spatializer_transaural_enabled=false
persist.vendor.audio.spatializer.enabled=false
ro.vendor.audio.sfx.dirac=false
persist.vendor.audio.dirac.enable=false
vendor.audio.dirac.enable=false
ro.vendor.audio.sfx.harmankardon=false
ro.vendor.audio.misound.bluetooth.enable=false
persist.vendor.audio.misoundasc=false
ro.vendor.audio.sfx.audiovisual=false
ro.vendor.audio.sfx.oreality=false
persist.vendor.audio.oreality.enable=false
ro.vendor.audio.dts.sfx=false
vendor.audio.dts.sfx=false
persist.audio.dts_effects=false
ro.vendor.audio.sfx.waves=false
persist.vendor.audio.waves.enable=false
ro.vendor.audio.sfx.holosound=false
persist.vendor.audio.holosound.enable=false
EOF

      for OAEFFECTXML in ${AEFFECTXMLS}; do
        AEFFECTXML="$MODPATH$(normalize_path "$OAEFFECTXML")"
        if [ -f "$ORIGDIR$OAEFFECTXML" ]; then
          mkdir -p "$(dirname "$AEFFECTXML")"
          cp_ch "$ORIGDIR$OAEFFECTXML" "$AEFFECTXML"

          sed -i \
            -e '/<effect name="reverb"/d' \
            -e '/<effect name="preset_reverb"/d' \
            -e '/<effect name="environmental_reverb"/d' \
            -e '/<effect name="loudness_enhancer"/d' \
            -e '/<effect name="dynamics_processing"/d' \
            -e '/<effect name="dirac"/d' \
            -e '/<effect name="misound"/d' \
            -e '/<effect name="sa3d"/d' \
            -e '/<effect name="dts"/d' \
            -e '/<effect name="waves"/d' \
            -e '/<library name="dirac"/d' \
            -e '/<library name="misound"/d' \
            -e '/<library name="dts"/d' \
            -e '/<library name="waves"/d' \
            -e '/<preprocess>/,/<\/preprocess>/c\<preprocess>\n</preprocess>' \
            -e 's/processing format="16bit"/processing format="float"/g' \
            -e 's/processing format="24bit"/processing format="float"/g' \
            "$AEFFECTXML"

          chmod 644 "$AEFFECTXML"
        fi
      done

      # 2. Патчинг audio_effects.conf (частичный)
      if [ -z "$AEFFECTCONFS" ]; then
        for std_conf in /system/etc/audio_effects.conf /vendor/etc/audio_effects.conf /system/vendor/etc/audio_effects.conf /odm/etc/audio_effects.conf /vendor/etc/audio/audio_effects.conf; do
          if [ -e "$std_conf" ] || { [ -n "$ORIGDIR" ] && [ -e "$ORIGDIR$std_conf" ]; }; then
            AEFFECTCONFS="$AEFFECTCONFS$std_conf"$'\n'
          fi
        done
      fi

      for OAEFFECTCONF in ${AEFFECTCONFS}; do
        [ -z "$OAEFFECTCONF" ] && continue
        AEFFECTCONF="$MODPATH$(normalize_path "$OAEFFECTCONF")"
        
        SRC_CONF=""
        if [ -n "$ORIGDIR" ] && [ -e "$ORIGDIR$OAEFFECTCONF" ]; then
          SRC_CONF="$ORIGDIR$OAEFFECTCONF"
        elif [ -e "$OAEFFECTCONF" ]; then
          SRC_CONF="$OAEFFECTCONF"
        fi

        if [ -n "$SRC_CONF" ]; then
          mkdir -p "$(dirname "$AEFFECTCONF")"

          awk '
          BEGIN {
            skip = 0
            depth = 0
            skip_depth = 0
          }
          {
            line = $0

            if (skip == 0 && line ~ /^[[:space:]]*pre_processing[[:space:]]*\{/) {
              print "pre_processing {\n}"
              skip = 1
              skip_depth = depth
            }

            if (skip == 0) {
              if (line ~ /^[[:space:]]*[-a-zA-Z0-9_]*(reverb|dirac|misound|dts|waves|sa3d|downmix|loudness_enhancer|dynamics_processing)[-a-zA-Z0-9_]*[[:space:]]*\{/) {
                skip = 1
                skip_depth = depth
              }
            }

            opens = gsub(/[{]/, "{", line)
            closes = gsub(/[}]/, "}", line)
            depth += (opens - closes)

            if (skip == 1) {
              if (depth <= skip_depth) {
                skip = 0
              }
              next
            }

            print $0
          }' "$SRC_CONF" > "${AEFFECTCONF}.tmp" && mv "${AEFFECTCONF}.tmp" "$AEFFECTCONF"

          chmod 644 "$AEFFECTCONF"
        fi
      done

    elif [ "$STEP12" == "full" ]; then

      for OAPP in ${APPS}; do
        APP="$MODPATH$(normalize_path "$OAPP")"
        mkdir -p "$(dirname "$APP")"
        touch "$APP"
      done

      cat << 'EOF' >> "$PROP"

vendor.audio.hph_mbdrc.enabled=false
vendor.audio.vol_based_mbdrc.enabled=false
vendor.audio.feature.matrix.limiter.enable=false
persist.vendor.audio.playback.mch.downsample=false
vendor.audio.playback.mch.downsample=false
ro.audio.ignore_effects=true
ro.audio.spatializer_enabled=false
ro.audio.spatializer_binaural_enabled=false
ro.audio.spatializer_transaural_enabled=false
ro.audio.spatializer.headtracking_enabled=false
persist.vendor.audio.spatializer.enabled=false
persist.vendor.audio.spatializer.speaker_enabled=false
ro.vendor.audio.dolby.dax.support=false
ro.vendor.dolby.dax.version=none
ro.vendor.audio.dolby.surround.enable=false
ro.vendor.audio.nosupport_bt_dolby=true
vendor.audio.dolby.ds2.enabled=false
persist.vendor.audio.dolby.disable=true
ro.vendor.audio.sfx.dirac=false
persist.vendor.audio.dirac.enable=false
vendor.audio.dirac.enable=false
ro.dirac.acs.controller=none
persist.dirac.acs.ignore=true
ro.vendor.audio.sfx.harmankardon=false
ro.vendor.audio.misound.bluetooth.enable=false
persist.vendor.audio.misoundasc=false
ro.vendor.audio.sfx.audiovisual=false
ro.vendor.audio.sfx.oreality=false
persist.vendor.audio.oreality.enable=false
ro.vendor.audio.dts.sfx=false
vendor.audio.dts.sfx=false
persist.audio.dts_effects=false
vendor.audio.use.dts_eagle=false
ro.vendor.audio.sfx.waves=false
persist.vendor.audio.waves.enable=false
ro.vendor.audio.sfx.holosound=false
persist.vendor.audio.holosound.enable=false
audio.safx.pbe.enabled=false
audio.pp.asphere.enabled=false
EOF

      DEF_VOL_UUID="110773a0-0c09-11e2-b77e-0800200c9a66"
      DEF_AEC_UUID="bb392e00-9472-11e1-a870-0002a5d5c51b"
      DEF_NS_UUID="c06c8400-9472-11e1-9f4c-0002a5d5c51b"

      for OAEFFECTXML in ${AEFFECTXMLS}; do
        AEFFECTXML="$MODPATH$(normalize_path "$OAEFFECTXML")"
        mkdir -p "$(dirname "$AEFFECTXML")"

        VOL_UUID=""
        AEC_UUID=""
        NS_UUID=""
        PREPROC_LIB=""

        if [ -f "$ORIGDIR$OAEFFECTXML" ]; then
          VOL_UUID=$(grep -E 'name="volume"|name="volume_listener"' "$ORIGDIR$OAEFFECTXML" | sed -n 's/.*uuid="\([^"]*\)".*/\1/p' | head -n 1)
          AEC_UUID=$(grep -E 'name="aec"' "$ORIGDIR$OAEFFECTXML" | sed -n 's/.*uuid="\([^"]*\)".*/\1/p' | head -n 1)
          NS_UUID=$(grep -E 'name="ns"' "$ORIGDIR$OAEFFECTXML" | sed -n 's/.*uuid="\([^"]*\)".*/\1/p' | head -n 1)
          PREPROC_LIB=$(grep -E 'name="pre_proc"|name="qcom_pre_proc"|name="audiopreprocessing"' "$ORIGDIR$OAEFFECTXML" | sed -n 's/.*path="\([^"]*\)".*/\1/p' | head -n 1)
        fi

        [ -z "$VOL_UUID" ] && VOL_UUID="$DEF_VOL_UUID"
        [ -z "$AEC_UUID" ] && AEC_UUID="$DEF_AEC_UUID"
        [ -z "$NS_UUID" ] && NS_UUID="$DEF_NS_UUID"
        [ -z "$PREPROC_LIB" ] && PREPROC_LIB="libaudiopreprocessing.so"

        cat << EOF > "$AEFFECTXML"
<?xml version="1.0" encoding="UTF-8"?>
<audio_effects_conf version="2.0" xmlns="http://schemas.android.com/audio/audio_effects_conf/2.0">
    <libraries>
        <library name="bundle" path="libbundlewrapper.so"/>
        <library name="pre_proc" path="${PREPROC_LIB}"/>
    </libraries>
    <effects>
        <effect name="volume" library="bundle" uuid="${VOL_UUID}"/>
        <effect name="aec" library="pre_proc" uuid="${AEC_UUID}"/>
        <effect name="ns" library="pre_proc" uuid="${NS_UUID}"/>
    </effects>
    <postprocess>
    </postprocess>
    <preprocess>
        <stream type="voice_communication">
            <apply effect="aec"/>
            <apply effect="ns"/>
        </stream>
    </preprocess>
</audio_effects_conf>
EOF
        chmod 644 "$AEFFECTXML"
      done

      for OAEFFECTCONF in ${AEFFECTCONFS}; do
        AEFFECTCONF="$MODPATH$(normalize_path "$OAEFFECTCONF")"
        mkdir -p "$(dirname "$AEFFECTCONF")"

        VOL_UUID=""
        AEC_UUID=""
        NS_UUID=""
        BUNDLE_PATH=""
        PREPROC_PATH=""

        SRC_CONF="$OAEFFECTCONF"
        [ -n "$ORIGDIR" ] && [ -f "$ORIGDIR$OAEFFECTCONF" ] && SRC_CONF="$ORIGDIR$OAEFFECTCONF"

        if [ -f "$SRC_CONF" ]; then
          VOL_UUID=$(grep -A 4 -E '^[[:blank:]]*(volume|volume_listener)[[:blank:]]*\{' "$SRC_CONF" 2>/dev/null | grep -E 'uuid[[:blank:]]+' | awk '{print $2}' | tr -d '"' | head -n 1)
          AEC_UUID=$(grep -A 4 -E '^[[:blank:]]*aec[[:blank:]]*\{' "$SRC_CONF" 2>/dev/null | grep -E 'uuid[[:blank:]]+' | awk '{print $2}' | tr -d '"' | head -n 1)
          NS_UUID=$(grep -A 4 -E '^[[:blank:]]*ns[[:blank:]]*\{' "$SRC_CONF" 2>/dev/null | grep -E 'uuid[[:blank:]]+' | awk '{print $2}' | tr -d '"' | head -n 1)

          BUNDLE_PATH=$(sed -n -E '/^[[:blank:]]*bundle[[:blank:]]*\{/,/\}/p' "$SRC_CONF" 2>/dev/null | grep -E 'path[[:blank:]]+' | awk '{print $2}' | tr -d '"' | head -n 1)
          PREPROC_PATH=$(sed -n -E '/^[[:blank:]]*(pre_proc|qcom_pre_proc|audiopreprocessing)[[:blank:]]*\{/,/\}/p' "$SRC_CONF" 2>/dev/null | grep -E 'path[[:blank:]]+' | awk '{print $2}' | tr -d '"' | head -n 1)
        fi

        [ -z "$VOL_UUID" ] && VOL_UUID="$DEF_VOL_UUID"
        [ -z "$AEC_UUID" ] && AEC_UUID="$DEF_AEC_UUID"
        [ -z "$NS_UUID" ] && NS_UUID="$DEF_NS_UUID"
        [ -z "$BUNDLE_PATH" ] && BUNDLE_PATH="libbundlewrapper.so"
        [ -z "$PREPROC_PATH" ] && PREPROC_PATH="libaudiopreprocessing.so"

        cat << EOF > "$AEFFECTCONF"
# Minimal clean audio_effects.conf by NLSound
libraries {
  bundle {
    path ${BUNDLE_PATH}
  }
  pre_proc {
    path ${PREPROC_PATH}
  }
}

effects {
  volume {
    library bundle
    uuid ${VOL_UUID}
  }
  aec {
    library pre_proc
    uuid ${AEC_UUID}
  }
  ns {
    library pre_proc
    uuid ${NS_UUID}
  }
}

pre_processing {
  voice_communication {
    aec {
    }
    ns {
    }
  }
}
EOF
        chmod 644 "$AEFFECTCONF"
      done

    fi
  } &
fi

if [ "$STEP11" == "true" ] || [ "$BITNES" != "false" ] || [ "$SAMPLERATE" != "false" ]; then
  {
    # Патчинг audio_io_policy.conf
    for OIOPOLICY in ${IOPOLICYS}; do
      IOPOLICY="$MODPATH$(normalize_path "$OIOPOLICY")"
      cp_ch "$ORIGDIR$OIOPOLICY" "$IOPOLICY"
      
      if [ "$STEP11" == "true" ]; then
        sed -i -E '/[[:blank:]]*(direct_pcm_24|direct_pcm_32)[[:blank:]]*\{/,/\}/ {
          /AUDIO_OUTPUT_FLAG_DIRECT_PCM/! s/(flags[[:blank:]]+.*AUDIO_OUTPUT_FLAG_DIRECT)/\1|AUDIO_OUTPUT_FLAG_DIRECT_PCM/g
        }' "$IOPOLICY"
      fi
      
      if [ "$BITNES" != "false" ]; then
        for section in direct_pcm_16 direct_pcm_24 direct_pcm_32 mmap_no_irq hifi; do
          sed -i -E "/^[[:blank:]]*$section[[:blank:]]*\{/,/\}/ {
            s/(bit_width[[:blank:]]+)[0-9]+/\1$bit_width/g
            s/(formats[[:blank:]]+)[^[:space:]]+/\1$apc_format/g
          }" "$IOPOLICY"
        done
      fi
    
      if [ "$SAMPLERATE" != "false" ]; then
        for section in direct_pcm_24 direct_pcm_32 hifi; do
          sed -i -E "/^[[:blank:]]*$section[[:blank:]]*\{/,/\}/ {
            /$SAMPLERATE/! s/(sampling_rates[[:blank:]]+)(.*)/\1\2|$SAMPLERATE/g
          }" "$IOPOLICY"
        done
      fi
    done

  # Патчинг audio_output_policy.conf
  for OOUTPUTPOLICY in ${OUTPUTPOLICYS}; do
  
    OUTPUTPOLICY="$MODPATH$(normalize_path "$OOUTPUTPOLICY")"
    cp_ch "$ORIGDIR$OOUTPUTPOLICY" "$OUTPUTPOLICY"
  
    if [ "$STEP11" == "true" ]; then
      sed -i -E '/[[:blank:]]*(direct_pcm_24|direct_pcm_32)[[:blank:]]*\{/,/\}/ {
        /AUDIO_OUTPUT_FLAG_DIRECT_PCM/! s/(flags[[:blank:]]+.*AUDIO_OUTPUT_FLAG_DIRECT)/\1|AUDIO_OUTPUT_FLAG_DIRECT_PCM/g
      }' "$OUTPUTPOLICY"
    fi
  
    if [ "$BITNES" != "false" ]; then
      for section in direct_pcm_16 direct_pcm_24 direct_pcm_32 mmap_no_irq hifi; do
        sed -i -E "/^[[:blank:]]*$section[[:blank:]]*\{/,/\}/ {
          s/(bit_width[[:blank:]]+)[0-9]+/\1$bit_width/g
          s/(formats[[:blank:]]+)[^[:space:]]+/\1$apc_format/g
        }" "$OUTPUTPOLICY"
      done
    fi
  
    if [ "$SAMPLERATE" != "false" ]; then
      for section in direct_pcm_24 direct_pcm_32 hifi; do
        sed -i -E "/^[[:blank:]]*$section[[:blank:]]*\{/,/\}/ {
          /$SAMPLERATE/! s/(sampling_rates[[:blank:]]+)(.*)/\1\2|$SAMPLERATE/g
        }" "$OUTPUTPOLICY"
      done
    fi
  done
  } &
fi

if [ "$VOLMEDIA" != "false" ] || [ "$VOLMIC" != "false" ] || [ "$STEP6" == "true" ] || [ "$STEP8" == "true" ]; then
  for OMIX in ${MPATHS}; do
    {
      MIX="$MODPATH$(normalize_path "$OMIX")"
      cp_ch $ORIGDIR$OMIX $MIX

      if [ "$VOLMEDIA" != "false" ]; then
        for IDX in 1 2; do
          sed -i "s/\(name=\"RX${IDX} Digital Volume\" value=\"\)[^\"]*\"/\1${VOLMEDIA}\"/g
                  s/\(name=\"WSA_RX${IDX} Digital Volume\" value=\"\)[^\"]*\"/\1${VOLMEDIA}\"/g
                  s/\(name=\"RX_RX${IDX} Digital Volume\" value=\"\)[^\"]*\"/\1${VOLMEDIA}\"/g" "$MIX"
        done
      fi

      if [ "$VOLMIC" != "false" ]; then
        sed -i -E "
          s/(name=\"DEC[0-2] Volume\" value=\")[^\"]*\"/\1${VOLMIC}\"/g
          s/(name=\"TX_DEC[0-2] Volume\" value=\")[^\"]*\"/\1${VOLMIC}\"/g
        " "$MIX"
      fi

      if [ "$STEP6" == "true" ]; then
        sed -i -E '
          s/name="([^"]*COMP[^"]*|[^"]*[Cc]ompander[^"]*)" value="[^"]*"/name="\1" value="0"/g
          s/name="([^"]*MBDRC[^"]*|[^"]*DRC[^"]*)" value="[^"]*"/name="\1" value="0"/g
          s/name="([^"]*[Ss]oftclip[^"]*)" value="[^"]*"/name="\1" value="0"/g
          s/name="([^"]*Noise Gate[^"]*)" value="[^"]*"/name="\1" value="0"/g
          s/name="Boost Class-H Tracking Enable" value="0"/name="Boost Class-H Tracking Enable" value="1"/g
          s/name="DRE DRE Switch" value="0"/name="DRE DRE Switch" value="1"/g
          s/name="RX INT[0-9] DEM MUX" value="NORMAL_DSM_OUT"/name="\1" value="CLSH_DSM_OUT"/g
        ' "$MIX"
      fi

      if [ "$STEP8" == "true" ]; then
        case "$PROCESSOR" in "pitti" | "sdm660" | "msm8937" | "msm8953")
          sed -i 's/\(name="RX[0-9] HPF cut off" value="\)[^"]*"/\1MIN_3DB_4Hz"/g
                  s/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="HD2"/g
                  s/name="RX HPH HD2 Mode" value=".*"/name="RX HPH HD2 Mode" value="On"/g' $MIX
          ;;
        *)
          sed -i 's/\(name="RX[0-9] HPF cut off" value="\)[^"]*"/\1CF_NEG_3DB_4HZ"/g
                  s/name="RX_HPH_PWR_MODE" value=".*"/name="RX_HPH_PWR_MODE" value="HIFI"/g
                  s/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="CLS_H_HIFI"/g
                  s/name="HPH Interpolator Mode" value="[^"]*"/name="HPH Interpolator Mode" value="PURE_HIFI"/g
                  s/name="HPH Type" value="[^"]*"/name="HPH Type" value="HQ"/g' $MIX
          ;;
        esac

        # [ "$RN5PRO", "$MI9", "$MI8", "$MI8P", "$MI9P", "$MIA2" ]
        case "$DEVICE" in whyred* | cepheus* | dipper* | equuleus* | crux* | jasmine*)
          sed -i 's/name="TAS2557 ClassD Edge" value=".*"/name="TAS2557 ClassD Edge" value="7"/g
                  s/name="TAS2557 Volume" value=".*"/name="TAS2557 Volume" value="30"/g' $MIX
          echo -e '\nro.sound.alsa=TAS2557' >>$PROP
          ;;
        esac

         sed -i '
          s/name="PowerCtrl" value=".*"/name="PowerCtrl" value="0"/g
          s/name="DSD_L Switch" value=".*"/name="DSD_L Switch" value="1"/g
          s/name="DSD_R Switch" value=".*"/name="DSD_R Switch" value="1"/g
          s/name="Amp DSP Enable" value=".*"/name="Amp DSP Enable" value="1"/g
          s/name="BDE AMP Enable" value=".*"/name="BDE AMP Enable" value="0"/g
          s/name="Amp Volume Location" value=".*"/name="Amp Volume Location" value="1"/g
          s/name="Adsp Working Mode" value=".*"/name="Adsp Working Mode" value="full"/g
          s/name="RX_Native" value=".*"/name="RX_Native" value="ON"/g
          s/name="HiFi Function" value=".*"/name="HiFi Function" value="On"/g
          s/name="HiFi Filter" value=".*"/name="HiFi Filter" value="1"/g
          s/name="Audiosphere Enable" value=".*"/name="Audiosphere Enable" value="Off"/g
          s/name="MSM ASphere Set Param" value=".*"/name="MSM ASphere Set Param" value="0"/g
          s/name="RX INT1 DEM MUX" value=".*"/name="RX INT1 DEM MUX" value="CLSH_DSM_OUT"/g
          s/name="RX INT0 DEM MUX" value=".*"/name="RX INT0 DEM MUX" value="CLSH_DSM_OUT"/g
          s/name="LPI Enable" value=".*"/name="LPI Enable" value="0"/g
          s/name="HDR34 MUX" value=".*"/name="HDR34 MUX" value="HDR34"/g
          s/name="HDR12 MUX" value=".*"/name="HDR12 MUX" value="HDR12"/g
          s/name="DS2 OnOff" value=".*"/name="DS2 OnOff" value="0"/g
        ' "$MIX"

        if [ "$HAS_TFA" = "true" ] || grep -qiE 'name="TFA|name="Tfa Enable' "$MIX"; then
          sed -i '
            s/name="Tfa Enable" value=".*"/name="Tfa Enable" value="1"/g
            s/name="TFA987X_ALGO_STATUS" value=".*"/name="TFA987X_ALGO_STATUS" value="ENABLE"/g
            s/name="TFA987X_TX_ENABLE" value=".*"/name="TFA987X_TX_ENABLE" value="ENABLE"/g
          ' "$MIX"
        fi

        if [ "$HAS_CIRRUS" = "true" ] || grep -qi 'name="Cirrus SP' "$MIX"; then
          sed -i '
            s/name="Cirrus SP Load Config" value=".*"/name="Cirrus SP Load Config" value="Load"/g
            s/name="Cirrus SP Channel Swap Duration" value=".*"/name="Cirrus SP Channel Swap Duration" value="9600"/g
          ' "$MIX"
        fi

        if [ "$HAS_TAS" = "true" ] || grep -qi 'name="TAS25' "$MIX"; then
          sed -i '
            s/name="TAS25XX_SMARTPA_ENABLE" value=".*"/name="TAS25XX_SMARTPA_ENABLE" value="ENABLE"/g
            s/name="TAS25XX_ALGO_PROFILE" value=".*"/name="TAS25XX_ALGO_PROFILE" value="MUSIC"/g
            s/name="TAS256x Profile id" value=".*"/name="TAS256x Profile id" value="1"/g
          ' "$MIX"
        fi

        if [ "$HAS_AWINIC" = "true" ] || grep -qi 'name="aw882' "$MIX"; then
          sed -i '
            s/name="aw882_xx_rx_switch" value=".*"/name="aw882_xx_rx_switch" value="Enable"/g
            s/name="aw882_xx_tx_switch" value=".*"/name="aw882_xx_tx_switch" value="Enable"/g
            s/name="aw882_copp_switch" value=".*"/name="aw882_copp_switch" value="Enable"/g
          ' "$MIX"
        fi

        if [ "$HAS_MAXIM" = "true" ] || grep -qi 'name="MAX98' "$MIX"; then
          sed -i '
            s/name="MAX98373 DSP Enable" value=".*"/name="MAX98373 DSP Enable" value="1"/g
          ' "$MIX"
        fi

        if [ "$HAS_WSA" = "true" ] || grep -qi 'name="WSA_RX' "$MIX"; then
          sed -i '
            s/name="WSA_Softclip0 Enable" value=".*"/name="WSA_Softclip0 Enable" value="0"/g
            s/name="WSA_Softclip1 Enable" value=".*"/name="WSA_Softclip1 Enable" value="0"/g
          ' "$MIX"
        fi

        # [ "$PIXEL6a", "$PIXEL6", "$PIXEL6Pro", "$PIXEL7", "$PIXEL7Pro" ]
        case "$DEVICE" in bluejay* | oriole* | raven* | cheetah* | panther*)
          sed -i 's/name="AMP PCM Gain" value=".*"/name="AMP PCM Gain" value="14"/g
                  s/name="Digital PCM Volume" value=".*"/name="Digital PCM Volume" value="830"/g
                  s/name="Boost Peak Current Limit" value=".*"/name="Boost Peak Current Limit" value="3.50A"/g' $MIX
          ;;
        esac
        
        # [ "$PIXEL8", "$PIXEL8Pro" ]
        case "$DEVICE" in shiba* | husky*)
          sed -i 's/name="AMP PCM Gain" value=".*"/name="AMP PCM Gain" value="14"/g
                  s/name="R AMP PCM Gain" value=".*"/name="R AMP PCM Gain" value="14"/g
                  s/name="Digital PCM Volume" value=".*"/name="Digital PCM Volume" value="830"/g
                  s/name="R Digital PCM Volume" value=".*"/name="R Digital PCM Volume" value="830"/g
                  s/name="Boost Peak Current Limit" value=".*"/name="Boost Peak Current Limit" value="3.50A"/g
                  s/name="R Boost Peak Current Limit" value=".*"/name="R Boost Peak Current Limit" value="3.50A"/g' $MIX
          ;;
        esac
        
      fi
    } &
  done
fi

if [ "$VOLSTEPS" != "false" ]; then
  {
    echo -e "\nro.config.media_vol_steps=$VOLSTEPS
    persist.vendor.media.volume_steps=$VOLSTEPS
    persist.media.volume_steps=$VOLSTEPS
    vendor.media.volume_steps=$VOLSTEPS
    media.volume_steps=$VOLSTEPS" >> $PROP
    echo -e "\nsettings put system volume_steps_music $VOLSTEPS" >>$MODPATH/service.sh
  } &
fi

if [ "$STEP13" = "true" ]; then
  tinymix_support=false

  {
    cat << 'EOF'

until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 3
done

sleep 5
EOF

    case "$DEVICE" in
      alioth*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Noise Gate" 0
tinymix_ext set "RCV Noise Gate" 0
tinymix_ext set "RX_HPH HD2 Mode" ON
EOF
        ;;

      cmi*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
EOF
        ;;

      vayu*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RCV PCM Source" DSP
tinymix_ext set "PCM Source" DSP
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix_ext set "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix_ext set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_ext set "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix_ext set "SLIM_4_TX Format" DSD_DOP
tinymix_ext set "SLIM_2_RX Format" DSD_DOP
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Compress Playback 11 Volume" 0 0
tinymix_ext set "Compress Playback 25 Volume" 0 0
tinymix_ext set "Compress Playback 26 Volume" 0 0
tinymix_ext set "Compress Playback 27 Volume" 0 0
tinymix_ext set "Compress Playback 28 Volume" 0 0
tinymix_ext set "Compress Playback 37 Volume" 0 0
tinymix_ext set "Compress Gapless Playback" 0
tinymix_ext set "RCV Noise Gate" 16383
tinymix_ext set "Noise Gate" 16383
tinymix_ext set "RCV Digital PCM Volume" 830
tinymix_ext set "Digital PCM Volume" 830
tinymix_ext set "RCV Class-H Head Room" 127
tinymix_ext set "Class-H Head Room" 127
tinymix_ext set "RCV PCM Soft Ramp" 30ms
tinymix_ext set "PCM Soft Ramp" 30ms
tinymix_ext set "RCV DSP Set AMBIENT" 16777215
tinymix_ext set "DSP Set AMBIENT" 16777215
tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "TERT_TDM_TX_0 LSM Function" AUDIO
tinymix_ext set "TERT_MI2S_TX LSM Function" AUDIO
tinymix_ext set "TAS256X PLAYBACK VOLUME LEFT" 56
tinymix_ext set "TAS256X LIM MAX ATTN LEFT" 0
tinymix_ext set "TAS256X LIM INFLECTION POINT LEFT" 0
tinymix_ext set "TAS256X LIM ATTACT RATE LEFT" 0
tinymix_ext set "TAS256X LIM RELEASE RATE LEFT" 7
tinymix_ext set "TAS256X LIM ATTACK STEP LEFT" 0
tinymix_ext set "TAS256X LIM RELEASE STEP LEFT" 3
tinymix_ext set "TAS256X RX MODE LEFT" Speaker
tinymix_ext set "TAS256X BOOST VOLTAGE LEFT" 15
tinymix_ext set "TAS256X BOOST CURRENT LEFT" 59
tinymix_ext set "TAS256X PLAYBACK VOLUME RIGHT" 56
tinymix_ext set "TAS256X LIM MAX ATTN RIGHT" 0
tinymix_ext set "TAS256X LIM INFLECTION POINT RIGHT" 0
tinymix_ext set "TAS256X LIM ATTACT RATE RIGHT" 0
tinymix_ext set "TAS256X LIM RELEASE RATE RIGHT" 7
tinymix_ext set "TAS256X LIM ATTACK STEP RIGHT" 0
tinymix_ext set "TAS256X LIM RELEASE STEP RIGHT" 3
tinymix_ext set "TAS256X BOOST VOLTAGE RIGHT" 12
tinymix_ext set "TAS256X BOOST CURRENT RIGHT" 55
tinymix_ext set "TAS256X VBAT LPF LEFT" DISABLE
tinymix_ext set "TAS256X VBAT LPF RIGHT" DISABLE
tinymix_ext set "TAS256x Profile id" 1
tinymix_ext set "TAS25XX_SMARTPA_ENABLE" ENABLE
tinymix_ext set "Amp Output Level" 22
tinymix_ext set "TAS25XX_ALGO_PROFILE" MUSIC
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "TERT_TDM_RX_0 Format" $max_format_24
tinymix_ext set "TERT_TDM_RX_1 Format" $max_format_24
tinymix_ext set "TERT_MI2S_RX Format" $max_format_24
tinymix_ext set "TERT_MI2S_TX Format" $max_format_24
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
tinymix_ext set "WSA_CDC_DMA_RX_0 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_RX_1 Format" $max_format_24
tinymix_ext set "SLIM_5_RX Format" $max_format_24
tinymix_ext set "SLIM_6_RX Format" $max_format_24
tinymix_ext set "SLIM_0_RX Format" $max_format_24
tinymix_ext set "SLIM_0_TX Format" $max_format_24
tinymix_ext set "Display Port RX Bit Format" $max_format_24
tinymix_ext set "Display Port1 RX Bit Format" $max_format_24
tinymix_ext set "EC Reference Bit Format" $max_format_24
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "WSA_CDC_DMA_RX_0 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_RX_1 SampleRate" $max_rate_192
tinymix_ext set "TERT_MI2S_RX SampleRate" $max_rate_192
tinymix_ext set "TERT_MI2S_TX SampleRate" $max_rate_192
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
EOF
        fi
        ;;

      ishtar* | aurora*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
EOF
        ;;

      star* | OP594DL1*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "PCM Source" DSP
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "RCV Noise Gate" 16383
tinymix_ext set "Noise Gate" 16383
tinymix_ext set "DS2 OnOff" 1
EOF
        ;;

      citrus* | juice* | chime* | lime*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "LPI Enable" 0
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Compress Playback 25 Volume" 0 0
tinymix_ext set "Compress Playback 26 Volume" 0 0
tinymix_ext set "Compress Playback 27 Volume" 0 0
tinymix_ext set "Compress Playback 28 Volume" 0 0
tinymix_ext set "Compress Playback 36 Volume" 0 0
tinymix_ext set "Compress Gapless Playback" 0
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "HPH Idle Detect" ON
tinymix_ext set "Set Custom Stereo OnOff" 1
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "Voip Evrc Min Max Rate Config" 4 4
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "TX_CDC_DMA_TX_0 Format" $FORMAT
tinymix_ext set "TX_CDC_DMA_TX_3 Format" $FORMAT
tinymix_ext set "TX_CDC_DMA_TX_4 Format" $FORMAT
tinymix_ext set "EC Reference Bit Format" $max_format_24
tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_3 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_3 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
tinymix_ext set "TX_CDC_DMA_TX_0 SampleRate" $RATE
tinymix_ext set "TX_CDC_DMA_TX_3 SampleRate" $RATE
tinymix_ext set "TX_CDC_DMA_TX_4 SampleRate" $RATE
tinymix_ext set "VA_CDC_DMA_TX_0 SampleRate" $max_rate_192
tinymix_ext set "VA_CDC_DMA_TX_1 SampleRate" $max_rate_192
tinymix_ext set "VA_CDC_DMA_TX_2 SampleRate" $max_rate_192
tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "VA_CDC_DMA_TX_0 Format" $max_format_24
tinymix_ext set "VA_CDC_DMA_TX_1 Format" $max_format_24
tinymix_ext set "VA_CDC_DMA_TX_2 Format" $max_format_24
EOF
        fi
        ;;

      surya*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 16
tinymix_ext set "HPHR Volume" 16
tinymix_ext set "RX HPH Mode" CLS_H_LOHIFI
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 1 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 13 Compress" 0
tinymix_ext set "Playback 16 Compress" 0
tinymix_ext set "Playback 27 Compress" 0
tinymix_ext set "Playback 39 Compress" 0
tinymix_ext set "Compress Playback 15 Volume" 0 0
tinymix_ext set "Compress Playback 29 Volume" 0 0
tinymix_ext set "Compress Playback 30 Volume" 0 0
tinymix_ext set "Compress Playback 31 Volume" 0 0
tinymix_ext set "Compress Playback 32 Volume" 0 0
tinymix_ext set "Compress Playback 41 Volume" 0 0
tinymix_ext set "Compress Playback 42 Volume" 0 0
tinymix_ext set "Compress Playback 43 Volume" 0 0
tinymix_ext set "Compress Playback 44 Volume" 0 0
tinymix_ext set "Compress Playback 45 Volume" 0 0
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "TAS256x Profile id" 1
tinymix_ext set "TAS25XX_SMARTPA_ENABLE" ENABLE
tinymix_ext set "TAS25XX_ALGO_PROFILE" MUSIC
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "TERT_TDM_RX_0 Format" $max_format_24
tinymix_ext set "TERT_TDM_RX_1 Format" $max_format_24
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
tinymix_ext set "Display Port RX Bit Format" $max_format_24
tinymix_ext set "Display Port1 RX Bit Format" $max_format_24
tinymix_ext set "EC Reference Bit Format" $max_format_24
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
EOF
        fi
        ;;

      mojito* | sweet* | sweetin* | willow* | a71* | RE54E4L1* | OnePlus9RT*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RCV PCM Source" DSP
tinymix_ext set "PCM Source" DSP
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "SLIM_4_TX Format" DSD_DOP
tinymix_ext set "SLIM_2_RX Format" DSD_DOP
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 1 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 13 Compress" 0
tinymix_ext set "Playback 16 Compress" 0
tinymix_ext set "Playback 27 Compress" 0
tinymix_ext set "Compress Playback 15 Volume" 0 0
tinymix_ext set "Compress Playback 29 Volume" 0 0
tinymix_ext set "Compress Playback 30 Volume" 0 0
tinymix_ext set "Compress Playback 31 Volume" 0 0
tinymix_ext set "Compress Playback 32 Volume" 0 0
tinymix_ext set "Compress Playback 41 Volume" 0 0
tinymix_ext set "Compress Playback 42 Volume" 0 0
tinymix_ext set "Compress Playback 43 Volume" 0 0
tinymix_ext set "Compress Playback 44 Volume" 0 0
tinymix_ext set "Compress Playback 45 Volume" 0 0
tinymix_ext set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_ext set "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "RCV Noise Gate" 16383
tinymix_ext set "Noise Gate" 16383
tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "aw882_xx_rx_switch" Enable
tinymix_ext set "aw882_xx_tx_switch" Enable
tinymix_ext set "aw882_copp_switch" Enable
tinymix_ext set "aw_dev_0_prof" Receiver
tinymix_ext set "aw_dev_1_prof" Receiver
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "Display Port RX Bit Format" $max_format_24
tinymix_ext set "Display Port1 RX Bit Format" $max_format_24
tinymix_ext set "EC Reference Bit Format" $max_format_24
tinymix_ext set "TERT_TDM_RX_0 Format" $max_format_24
tinymix_ext set "TERT_TDM_RX_1 Format" $max_format_24
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
tinymix_ext set "WSA_CDC_DMA_RX_0 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_RX_1 Format" $max_format_24
tinymix_ext set "SLIM_5_RX Format" $max_format_24
tinymix_ext set "SLIM_6_RX Format" $max_format_24
tinymix_ext set "SLIM_0_RX Format" $max_format_24
tinymix_ext set "SLIM_0_TX Format" $max_format_24
tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "WSA_CDC_DMA_RX_0 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_RX_1 SampleRate" $max_rate_192
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
EOF
        fi
        ;;

      marble*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_LOHIFI
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "HPH Idle Detect" ON
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "AUX_HPF Enable" 0
EOF
        ;;

      joyeuse* | curtana* | gram* | excalibur*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "Amp Output Level" 22
tinymix_ext set "TAS25XX_ALGO_BYPASS" TRUE
tinymix_ext set "TAS2562 IVSENSE ENABLE" On
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Compress Playback 7 Volume" 0 0
tinymix_ext set "Compress Playback 11 Volume" 0 0
tinymix_ext set "Compress Playback 24 Volume" 0 0
tinymix_ext set "Compress Playback 25 Volume" 0 0
tinymix_ext set "Compress Playback 26 Volume" 0 0
tinymix_ext set "Compress Playback 27 Volume" 0 0
tinymix_ext set "Compress Playback 28 Volume" 0 0
tinymix_ext set "Compress Playback 37 Volume" 0 0
tinymix_ext set "Compress Gapless Playback" 0
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "HPH Idle Detect" ON
tinymix_ext set "RX_HPH HD2 Mode" ON
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "Set Custom Stereo OnOff" 1
tinymix_ext set "DEC0_BCS Switch" 1
tinymix_ext set "SLIMBUS_0_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_1_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_2_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_3_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_4_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_5_TX LSM Function" AUDIO
tinymix_ext set "TERT_MI2S_TX LSM Function" AUDIO
tinymix_ext set "QUAT_MI2S_TX LSM Function" AUDIO
tinymix_ext set "INT3_MI2S_TX LSM Function" AUDIO
tinymix_ext set "TX_CDC_DMA_TX_3 LSM Function" AUDIO
tinymix_ext set "QUIN_TDM_TX_0 LSM Function" AUDIO
tinymix_ext set "TERT_TDM_TX_0 LSM Function" AUDIO
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_3 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
tinymix_ext set "WSA_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "WSA_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "Display Port RX Bit Format" $max_format_24
tinymix_ext set "Display Port1 RX Bit Format" $max_format_24
tinymix_ext set "EC Reference Bit Format" $max_format_24
tinymix_ext set "SEN_MI2S_RX Format" $max_format_24
tinymix_ext set "QUIN_MI2S_RX Format" $max_format_24
tinymix_ext set "QUAT_MI2S_RX Format" $max_format_24
tinymix_ext set "SEC_MI2S_RX Format" $max_format_24
tinymix_ext set "PRIM_MI2S_RX Format" $max_format_24
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_3 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "WSA_CDC_DMA_RX_0 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_RX_1 SampleRate" $max_rate_192
tinymix_ext set "Display Port RX SampleRate" $max_rate_192
tinymix_ext set "Display Port1 RX SampleRate" $max_rate_192
tinymix_ext set "SEN_MI2S_RX SampleRate" $max_rate_192
tinymix_ext set "QUIN_MI2S_RX SampleRate" $max_rate_192
tinymix_ext set "QUAT_MI2S_RX SampleRate" $max_rate_192
tinymix_ext set "SEC_MI2S_RX SampleRate" $max_rate_192
tinymix_ext set "PRIM_MI2S_RX SampleRate" $max_rate_192
EOF
        fi
        ;;

      umi*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 24
tinymix_ext set "HPHR Volume" 24
tinymix_ext set "AMP PCM Gain" 14
tinymix_ext set "RCV AMP PCM Gain" 14
tinymix_ext set "RX HPH Mode" CLS_H_LOHIFI
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "Cirrus SP Channel Swap Duration" 9600
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "Set Custom Stereo OnOff" 1
tinymix_ext set "PCM Source" ASP
tinymix_ext set "RCV PCM Source" ASP
EOF
        ;;

      # --- OnePlus ---
      OnePlus9R*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "WSA_Softclip0 Enable" 0
tinymix_ext set "WSA_Softclip1 Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Compress Playback 11 Volume" 0 0
tinymix_ext set "Compress Playback 25 Volume" 0 0
tinymix_ext set "Compress Playback 26 Volume" 0 0
tinymix_ext set "Compress Playback 27 Volume" 0 0
tinymix_ext set "Compress Playback 28 Volume" 0 0
tinymix_ext set "Compress Playback 37 Volume" 0 0
tinymix_ext set "Compress Gapless Playback" 0
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "SLIM9_TX ADM Channels" Two
tinymix_ext set "Voip Evrc Min Max Rate Config" 4 4
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "TERT_MI2S_RX Format" $max_format_24
tinymix_ext set "TERT_MI2S_TX Format" $max_format_24
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_3 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
tinymix_ext set "WSA_CDC_DMA_RX_0 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_RX_1 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_TX_1 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_TX_2 Format" $max_format_24
tinymix_ext set "TX_CDC_DMA_TX_0 Format" $FORMAT
tinymix_ext set "TX_CDC_DMA_TX_3 Format" $FORMAT
tinymix_ext set "TX_CDC_DMA_TX_4 Format" $FORMAT
tinymix_ext set "Display Port RX Bit Format" $max_format_24
tinymix_ext set "Display Port1 RX Bit Format" $max_format_24
tinymix_ext set "EC Reference Bit Format" $max_format_24
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "TX_CDC_DMA_TX_0 SampleRate" $RATE
tinymix_ext set "TX_CDC_DMA_TX_3 SampleRate" $RATE
tinymix_ext set "TX_CDC_DMA_TX_4 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_3 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
tinymix_ext set "WSA_CDC_DMA_RX_0 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_RX_1 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_TX_1 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_TX_2 SampleRate" $max_rate_192
tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
EOF
        fi
        ;;

      ingres* | OnePlus9Pro*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RCV PCM Source" DSP
tinymix_ext set "PCM Source" DSP
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "Cirrus SP Channel Swap Duration" 9600
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Compress Playback 11 Volume" 0 0
tinymix_ext set "Compress Playback 25 Volume" 0 0
tinymix_ext set "Compress Playback 26 Volume" 0 0
tinymix_ext set "Compress Playback 27 Volume" 0 0
tinymix_ext set "Compress Playback 28 Volume" 0 0
tinymix_ext set "Compress Playback 37 Volume" 0 0
tinymix_ext set "Compress Gapless Playback" 0
tinymix_ext set "RCV Noise Gate" 16382
tinymix_ext set "Noise Gate" 16382
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "SLIM9_TX ADM Channels" Two
tinymix_ext set "Voip Evrc Min Max Rate Config" 4 4
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "TERT_MI2S_RX Format" $max_format_24
tinymix_ext set "TERT_MI2S_TX Format" $max_format_24
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
tinymix_ext set "WSA_CDC_DMA_RX_0 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_RX_1 Format" $max_format_24
tinymix_ext set "TX_CDC_DMA_TX_3 Format" $FORMAT
tinymix_ext set "TX_CDC_DMA_TX_4 Format" $FORMAT
tinymix_ext set "Display Port RX Bit Format" $max_format_24
tinymix_ext set "Display Port1 RX Bit Format" $max_format_24
tinymix_ext set "EC Reference Bit Format" $max_format_24
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "TX_CDC_DMA_TX_3 SampleRate" $RATE
tinymix_ext set "TX_CDC_DMA_TX_4 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
tinymix_ext set "WSA_CDC_DMA_RX_0 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_RX_1 SampleRate" $max_rate_192
tinymix_ext set "TERT_MI2S_RX SampleRate" $max_rate_192
tinymix_ext set "TERT_MI2S_TX SampleRate" $max_rate_192
tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
EOF
        fi
        ;;

      guacamole* | hotdog* | OnePlus7* | OnePlus7T* | OnePlus7Pro* | OnePlus7TPro*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HD Voice Enable" 1
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "HiFi Filter" 1
tinymix_ext set "HiFi Function" On
tinymix_ext set "Compress Gapless Playback" 0
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 1 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 13 Compress" 0
tinymix_ext set "Playback 16 Compress" 0
tinymix_ext set "Playback 27 Compress" 0
tinymix_ext set "Playback 42 Compress" 0
tinymix_ext set "Playback 43 Compress" 0
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "AMIC_1_2 PWR MODE" HIGH_PERF
tinymix_ext set "AMIC_3_4 PWR MODE" HIGH_PERF
tinymix_ext set "AMIC_5_6 PWR MODE" HIGH_PERF
tinymix_ext set "SLIM_4_TX Format" DSD_DOP
tinymix_ext set "SLIM_2_RX Format" DSD_DOP
tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "Set Custom Stereo OnOff" 1
tinymix_ext set "SLIMBUS_0_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_1_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_2_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_3_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_4_TX LSM Function" AUDIO
tinymix_ext set "SLIMBUS_5_TX LSM Function" AUDIO
tinymix_ext set "TERT_MI2S_TX LSM Function" AUDIO
tinymix_ext set "QUAT_MI2S_TX LSM Function" AUDIO
tinymix_ext set "INT3_MI2S_TX LSM Function" AUDIO
tinymix_ext set "TX_CDC_DMA_TX_3 LSM Function" AUDIO
tinymix_ext set "QUIN_TDM_TX_0 LSM Function" AUDIO
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT2 DEM MUX" CLSH_DSM_OUT
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "EC Reference Bit Format" $max_format_24
tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $max_bit_width_24
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "TERT_MI2S_RX Format" $max_format_24
tinymix_ext set "TERT_MI2S_TX Format" $max_format_24
tinymix_ext set "Display Port RX Bit Format" $max_format_24
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "TERT_MI2S_RX SampleRate" $max_rate_192
tinymix_ext set "TERT_MI2S_TX SampleRate" $max_rate_192
tinymix_ext set "EC Reference SamplRate" $SAMPLERATE
tinymix_ext set "Display Port RX Sample Rate" $max_rate_192
tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
EOF
        fi
        ;;

      OP595DL1* | OP5929L1*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "HPH Idle Detect" ON
EOF
        ;;

      OP5D55L1*)
        tinymix_support=true
        cat << EOF

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "HPH Idle Detect" ON
tinymix_ext set "WSA2_RX0 Digital Volume" $VOLMEDIA
tinymix_ext set "WSA2_RX1 Digital Volume" $VOLMEDIA
tinymix_ext set "HPHR Volume" 24
tinymix_ext set "HPHL Volume" 24
tinymix_ext set "HPHL_COMP Switch" 0
tinymix_ext set "HPHR_COMP Switch" 0
tinymix_ext set "HPHL Compander" 0
tinymix_ext set "HPHR Compander" 0
tinymix_ext set "WSA2_RX INT0 VBAT WSA2 RX0 VBAT Enable" 0
tinymix_ext set "WSA2_RX INT1 VBAT WSA2 RX1 VBAT Enable" 0
tinymix_ext set "HPHR XTALK" 1
tinymix_ext set "HPHL XTALK" 1
tinymix_ext set "LDOH Enable" 1
tinymix_ext set "PM_QOS Vote" Enable
tinymix_ext set "aw882xx_copp_switch" Disable
EOF
        ;;

      OP5D3BL1* | OP5D2BL1*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX_COMP1 Switch" 0
tinymix_ext set "RX_COMP2 Switch" 0
tinymix_ext set "HPH Idle Detect" ON
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "LPI Enable" 0
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "HPHL_COMP Switch" 0
tinymix_ext set "HPHR_COMP Switch" 0
tinymix_ext set "HPHL Compander" 0
tinymix_ext set "HPHR Compander" 0
EOF
        ;;

      # --- Realme / Oppo ---
      RE5C82L1* | RE5C3B*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "Ext_Amp_Boost_Volume" Level_4
tinymix_ext set "TX CH1 PWR" L3
tinymix_ext set "TX CH3 PWR" L3
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "AUX PATH Mode" HP_MODE
tinymix_ext set "Ext_Amp_Mode" Music
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX_COMP1 Switch" 0
tinymix_ext set "RX_COMP2 Switch" 0
tinymix_ext set "HPHL_COMP Switch" 0
tinymix_ext set "HPHR_COMP Switch" 0
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPH Idle Detect" ON
tinymix_ext set "PM_QOS Vote" Enable
EOF
        ;;

      RE5473* | RE879AL1* | kona*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RCV PCM Source" DSP
tinymix_ext set "PCM Source" DSP
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "SLIM_4_TX Format" DSD_DOP
tinymix_ext set "SLIM_2_RX Format" DSD_DOP
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Compress Playback 11 Volume" 0 0
tinymix_ext set "Compress Playback 25 Volume" 0 0
tinymix_ext set "Compress Playback 26 Volume" 0 0
tinymix_ext set "Compress Playback 27 Volume" 0 0
tinymix_ext set "Compress Playback 28 Volume" 0 0
tinymix_ext set "Compress Playback 37 Volume" 0 0
tinymix_ext set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_ext set "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "RCV Noise Gate" 16383
tinymix_ext set "Noise Gate" 16383
tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "aw882_xx_rx_switch" Enable
tinymix_ext set "aw882_xx_tx_switch" Enable
tinymix_ext set "aw882_copp_switch" Enable
tinymix_ext set "aw_dev_0_prof" Receiver
tinymix_ext set "aw_dev_1_prof" Receiver
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "TERT_TDM_RX_0 Format" $max_format_24
tinymix_ext set "TERT_TDM_RX_1 Format" $max_format_24
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
tinymix_ext set "WSA_CDC_DMA_RX_0 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_RX_1 Format" $max_format_24
tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "SLIM_5_RX Format" $max_format_24
tinymix_ext set "SLIM_6_RX Format" $max_format_24
tinymix_ext set "SLIM_0_RX Format" $max_format_24
tinymix_ext set "SLIM_0_TX Format" $max_format_24
tinymix_ext set "Display Port RX Bit Format" $max_format_24
tinymix_ext set "Display Port1 RX Bit Format" $max_format_24
tinymix_ext set "EC Reference Bit Format" $max_format_24
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
tinymix_ext set "WSA_CDC_DMA_RX_0 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_RX_1 SampleRate" $max_rate_192
EOF
        fi
        ;;

      OP528BL1*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "TFA98XX ANA Volume" 3
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPH Idle Detect" ON
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "EAR_RDAC Switch" 1
tinymix_ext set "AUX_RDAC Switch" 1
tinymix_ext set "HPHL_RDAC Switch" 1
tinymix_ext set "HPHR_RDAC Switch" 1
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
EOF
        ;;

      RE5C4FL1*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "AUX_HPF Enable" 0
EOF
        ;;

      # --- Samsung ---
      b0q*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RCV PCM Source" DSP
tinymix_ext set "PCM Source" DSP
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix_ext set "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix_ext set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_ext set "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix_ext set "SLIM_4_TX Format" DSD_DOP
tinymix_ext set "SLIM_2_RX Format" DSD_DOP
tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "EC Reference Channels" Two
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Compress Playback 11 Volume" 0 0
tinymix_ext set "Compress Playback 25 Volume" 0 0
tinymix_ext set "Compress Playback 26 Volume" 0 0
tinymix_ext set "Compress Playback 27 Volume" 0 0
tinymix_ext set "Compress Playback 28 Volume" 0 0
tinymix_ext set "Compress Playback 37 Volume" 0 0
tinymix_ext set "Compress Gapless Playback" 0
tinymix_ext set "RCV Noise Gate" 16383
tinymix_ext set "Noise Gate" 16383
tinymix_ext set "Haptics Source" A2H
tinymix_ext set "Static MCLK Mode" 24
tinymix_ext set "Force Frame32" 1
tinymix_ext set "A2H Tuning" 5
tinymix_ext set "LPI Enable" 0
tinymix_ext set "DMIC_RATE OVERRIDE" CLK_2P4MHZ
tinymix_ext set "DS2 OnOff" 1
EOF
        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "TERT_TDM_RX_0 Format" $max_format_24
tinymix_ext set "TERT_TDM_RX_1 Format" $max_format_24
tinymix_ext set "TERT_MI2S_RX Format" $max_format_24
tinymix_ext set "TERT_MI2S_TX Format" $max_format_24
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_1 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_2 Format" $FORMAT
tinymix_ext set "RX_CDC_DMA_RX_5 Format" $FORMAT
tinymix_ext set "WSA_CDC_DMA_RX_0 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_RX_1 Format" $max_format_24
tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "USB_AUDIO_RX Format" $FORMAT
tinymix_ext set "USB_AUDIO_TX Format" $FORMAT
tinymix_ext set "SLIM_5_RX Format" $max_format_24
tinymix_ext set "SLIM_6_RX Format" $max_format_24
tinymix_ext set "SLIM_0_RX Format" $max_format_24
tinymix_ext set "SLIM_0_TX Format" $max_format_24
tinymix_ext set "Display Port RX Bit Format" $max_format_24
tinymix_ext set "Display Port1 RX Bit Format" $max_format_24
tinymix_ext set "EC Reference Bit Format" $max_format_24
EOF
        fi
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "WSA_CDC_DMA_RX_0 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_RX_1 SampleRate" $max_rate_192
tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
tinymix_ext set "USB_AUDIO_RX SampleRate" $RATE
tinymix_ext set "USB_AUDIO_TX SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_1 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_2 SampleRate" $RATE
tinymix_ext set "RX_CDC_DMA_RX_5 SampleRate" $RATE
tinymix_ext set "TERT_MI2S_RX SampleRate" $max_rate_192
tinymix_ext set "TERT_MI2S_TX SampleRate" $max_rate_192
EOF
        fi
        ;;

      # --- Google Pixel ---
      bluejay* | oriel* | raven* | panther*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "HPHL Volume" 20
tinymix_ext set "HPHR Volume" 20
tinymix_ext set "AoC Speaker Mixer ASP Mode" ASP_OFF
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "AMP PCM Gain" 14
tinymix_ext set "Digital PCM Volume" 865
tinymix_ext set "Boost Peak Current Limit" 3.50A
EOF
        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "BT SampleRate" $max_rate_96
tinymix_ext set "BT SampleRate RX" $max_rate_96
EOF
        fi
        ;;

      cheetah*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "AMP PCM Gain" 18
tinymix_ext set "R AMP PCM Gain" 20
tinymix_ext set "AoC Speaker Mixer ASP Mode" ASP_OFF
tinymix_ext set "Boost Class-H Tracking Enable" 0
tinymix_ext set "R Boost Class-H Tracking Enable" 0
tinymix_ext set "DSP Bypass" 1
EOF
        ;;

      shiba* | husky*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "AMP PCM Gain" 14
tinymix_ext set "R AMP PCM Gain" 14
tinymix_ext set "Digital PCM Volume" 830
tinymix_ext set "R Digital PCM Volume" 830
tinymix_ext set "Boost Peak Current Limit" 4.00A
tinymix_ext set "R Boost Peak Current Limit" 4.00A
EOF
        ;;

      # --- Sony Xperia ---
      XQ-AT52*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "HDR12 MUX" HDR34
tinymix_ext set "L AMP PCM Gain" 14
tinymix_ext set "R AMP PCM Gain" 14
tinymix_ext set "HiFi Filter" 1
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "RX_HPH HD2 Mode" ON
tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "Set Custom Stereo OnOff" 1
EOF
        ;;

      XQ-CQ62*)
        tinymix_support=true
        cat << 'EOF'

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC4 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC5 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC6 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC7 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_ext set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_ext set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_ext set "RX HPH Mode" CLS_H_HIFI
tinymix_ext set "RX_HPH_PWR_MODE" LOHIFI
tinymix_ext set "TX0 MODE" ADC_LO_HIF
tinymix_ext set "TX1 MODE" ADC_LO_HIF
tinymix_ext set "TX2 MODE" ADC_LO_HIF
tinymix_ext set "TX3 MODE" ADC_LO_HIF
tinymix_ext set "HDR12 MUX" HDR12
tinymix_ext set "HDR34 MUX" HDR34
tinymix_ext set "RX_COMP1 Switch" 0
tinymix_ext set "RX_COMP2 Switch" 0
tinymix_ext set "AUX_HPF Enable" 0
tinymix_ext set "HPHL_COMP Switch" 0
tinymix_ext set "HPHR_COMP Switch" 0
tinymix_ext set "LPI Enable" 0
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "LDOH Enable" 1
tinymix_ext set "PM_QOS Vote" Enable
tinymix_ext set "L Boost Target Voltage" 170
tinymix_ext set "R Boost Target Voltage" 170
tinymix_ext set "L PCM Source" ASP
tinymix_ext set "R PCM Source" ASP
EOF
        ;;
    esac

    if [ "$tinymix_support" != "true" ]; then
      if [ "$isMTK" = "true" ]; then
        cat << 'EOF'

tinymix_ext set "I2S0_HD_Mux" "Low_Jitter"
tinymix_ext set "I2S1_HD_Mux" "Low_Jitter"
tinymix_ext set "I2S2_HD_Mux" "Low_Jitter"
tinymix_ext set "I2S3_HD_Mux" "Low_Jitter"
tinymix_ext set "I2S5_HD_Mux" "Low_Jitter"
EOF
        if [ "$SAMPLERATE" != "false" ]; then
          echo "tinymix_ext set \"Audio_SineGen_SampleRate\" $mtk_rate"
        fi
      else

        cat << 'EOF'

tinymix_ext set "DS2 OnOff" 1
tinymix_ext set "HPH Idle Detect" ON
tinymix_ext set "Playback 0 Compress" 0
tinymix_ext set "Playback 1 Compress" 0
tinymix_ext set "Playback 13 Compress" 0
tinymix_ext set "Playback 16 Compress" 0
tinymix_ext set "Playback 27 Compress" 0
tinymix_ext set "Playback 39 Compress" 0
tinymix_ext set "Playback 4 Compress" 0
tinymix_ext set "Playback 9 Compress" 0
tinymix_ext set "Compress Gapless Playback" 0
tinymix_ext set "Compress Playback 11 Volume" 0 0
tinymix_ext set "Compress Playback 15 Volume" 0 0
tinymix_ext set "Compress Playback 25 Volume" 0 0
tinymix_ext set "Compress Playback 26 Volume" 0 0
tinymix_ext set "Compress Playback 27 Volume" 0 0
tinymix_ext set "Compress Playback 28 Volume" 0 0
tinymix_ext set "Compress Playback 29 Volume" 0 0
tinymix_ext set "Compress Playback 30 Volume" 0 0
tinymix_ext set "Compress Playback 31 Volume" 0 0
tinymix_ext set "Compress Playback 32 Volume" 0 0
tinymix_ext set "Compress Playback 36 Volume" 0 0
tinymix_ext set "Compress Playback 37 Volume" 0 0
tinymix_ext set "Compress Playback 41 Volume" 0 0
tinymix_ext set "Compress Playback 42 Volume" 0 0
tinymix_ext set "Compress Playback 43 Volume" 0 0
tinymix_ext set "Compress Playback 44 Volume" 0 0
tinymix_ext set "Compress Playback 45 Volume" 0 0
tinymix_ext set "RX_Softclip Enable" 0
tinymix_ext set "Set Custom Stereo OnOff" 1
EOF

        if [ "$BITNES" != "false" ]; then
          cat << EOF

tinymix_ext set "ASM Bit Width" $max_bit_width_24
tinymix_ext set "AFE Input Bit Format" $FORMAT
tinymix_ext set "EC Reference Bit Format" $max_format_24
tinymix_ext set "RX_CDC_DMA_RX_0 Format" $FORMAT
EOF
          if [ "$HAS_WSA" = "true" ]; then
            cat << EOF
tinymix_ext set "WSA_CDC_DMA_RX_0 Format" $max_format_24
tinymix_ext set "WSA_CDC_DMA_RX_1 Format" $max_format_24
EOF
          fi
        fi

        if [ "$SAMPLERATE" != "false" ]; then
          cat << EOF

tinymix_ext set "RX_CDC_DMA_RX_0 SampleRate" $RATE
EOF
          if [ "$HAS_WSA" = "true" ]; then
            cat << EOF
tinymix_ext set "WSA_CDC_DMA_RX_0 SampleRate" $max_rate_192
tinymix_ext set "WSA_CDC_DMA_RX_1 SampleRate" $max_rate_192
EOF
          fi
        fi
      fi
    fi


    if [ "$HAS_CIRRUS" = "true" ]; then
      cat << 'EOF'

tinymix_ext set "Cirrus SP Channel Swap Duration" 9600
EOF
    fi

    if [ "$HAS_TAS" = "true" ]; then
      cat << 'EOF'

tinymix_ext set "TAS25XX_SMARTPA_ENABLE" ENABLE
tinymix_ext set "TAS25XX_ALGO_PROFILE" MUSIC
tinymix_ext set "TAS256x Profile id" 1
EOF
    fi

    if [ "$HAS_AWINIC" = "true" ]; then
      cat << 'EOF'

tinymix_ext set "aw882_xx_rx_switch" Enable
tinymix_ext set "aw882_xx_tx_switch" Enable
tinymix_ext set "aw882_copp_switch" Enable
EOF
    fi

    if [ "$HAS_WCD" = "true" ]; then
      cat << 'EOF'

tinymix_ext set "DEC0 MODE" ADC_HIGH_PERF
tinymix_ext set "DEC1 MODE" ADC_HIGH_PERF
EOF
    fi

  } >> "$MODPATH/service.sh"
fi

if [ "$VOLMEDIA" != "false" ]; then
  echo -e '\n
tinymix_ext set "RX_RX0 Digital Volume" '$VOLMEDIA'
tinymix_ext set "RX_RX1 Digital Volume" '$VOLMEDIA'
tinymix_ext set "RX_RX2 Digital Volume" '$VOLMEDIA'
tinymix_ext set "RX_RX0 Mix Digital Volume" '$VOLMEDIA'
tinymix_ext set "RX_RX1 Mix Digital Volume" '$VOLMEDIA'
tinymix_ext set "RX_RX2 Mix Digital Volume" '$VOLMEDIA'
tinymix_ext set "VA_DEC0 Volume" '$VOLMEDIA'
tinymix_ext set "VA_DEC1 Volume" '$VOLMEDIA'
tinymix_ext set "VA_DEC2 Volume" '$VOLMEDIA'
tinymix_ext set "VA_DEC3 Volume" '$VOLMEDIA'
' >>$MODPATH/service.sh
fi

# Patching Dolby Atmos and Dolby media codecs files
if [ "$STEP14" = "true" ]; then

    for ODCODECS in ${DCODECS}; do
        DOLBYCODECS="$MODPATH$(normalize_path "$ODCODECS")"
        cp_ch "$ORIGDIR$ODCODECS" "$DOLBYCODECS"

        sed -i 's/<Limit name="channel-count" max="[0-9]*"/<Limit name="channel-count" max="8"/g' "$DOLBYCODECS"
        sed -i -E 's/name="bitrate" ranges?="[^"]*"/name="bitrate" range="32000-6144000"/g' "$DOLBYCODECS"
        sed -i 's/name="sample-rate" ranges="[^"]*"/name="sample-rate" ranges="32000-48000"/g' "$DOLBYCODECS"
    done

    for OADAXES in ${DAXES}; do
        DAX="$MODPATH$(normalize_path "$OADAXES")"
        cp_ch "$ORIGDIR$OADAXES" "$DAX"

       case "$DEVICE" in
            # Xiaomi 13 Ultra / 13 Pro (ishtar / aurora) — Стабильный максимальный бас
            ishtar*|aurora*)

                sed -i '
                s/hearing-protection-enable value="true"/hearing-protection-enable value="false"/g
                s/graphic-equalizer-enable value="false"/graphic-equalizer-enable value="true"/g
                s/reverb-suppression-enable value="true"/reverb-suppression-enable value="false"/g
                ' "$DAX"

                sed -i '
                /<endpoint_type id="headphone">/,/<\/endpoint_type>/ {
                    s/volume-leveler-enable value="true"/volume-leveler-enable value="false"/g
                    s/volume-leveler-compressor-enable value="true"/volume-leveler-compressor-enable value="false"/g
                    s/ieq-enable value="true"/ieq-enable value="false"/g
                    s/virtualizer-enable value="true"/virtualizer-enable value="false"/g
                    s/surround-decoder-enable value="true"/surround-decoder-enable value="false"/g
                    s/dialog-enhancer-enable value="true"/dialog-enhancer-enable value="false"/g
                    s/volmax-boost value="[0-9]*"/volmax-boost value="0"/g
                }
                /<tuning name="headphone"/,/<\/tuning>/ {
                    s/bass-enhancer-boost value="[0-9]*"/bass-enhancer-boost value="0"/g
                    s/audio-optimizer-enable value="true"/audio-optimizer-enable value="false"/g
                }
                ' "$DAX"

                sed -i '
                /<endpoint_type id="speaker">/,/<\/endpoint_type>/ {
                    s/bass-enhancer-enable value="false"/bass-enhancer-enable value="true"/g
                    s/virtual-bass-process-enable value="false"/virtual-bass-process-enable value="true"/g
                    s/volume-leveler-enable value="false"/volume-leveler-enable value="true"/g
                }
                /<profile id="2" name="Music"/,/<\/profile>/ {
                    s/surround-boost value="0"/surround-boost value="64"/g
                }
                ' "$DAX"

                sed -i '
                /<tuning name="speaker_landscape"/,/<\/tuning>/ {
                    s/bass-enhancer-boost value="[0-9]*"/bass-enhancer-boost value="192"/g
                    s/bass-enhancer-cutoff-frequency value="[0-9]*"/bass-enhancer-cutoff-frequency value="160"/g
                    s/harmonic_2="[0-9\-]*"/harmonic_2="0"/g
                    s/harmonic_3="[0-9\-]*"/harmonic_3="-48"/g
                    s/frequency_low="94" frequency_high="469"/frequency_low="110" frequency_high="420"/g
                    s/frequency_low="35" frequency_high="160"/frequency_low="30" frequency_high="150"/g
                }
                /<tuning name="speaker_portrait"/,/<\/tuning>/ {
                    s/bass-enhancer-boost value="[0-9]*"/bass-enhancer-boost value="192"/g
                    s/bass-enhancer-cutoff-frequency value="[0-9]*"/bass-enhancer-cutoff-frequency value="160"/g
                    s/harmonic_2="[0-9\-]*"/harmonic_2="0"/g
                    s/harmonic_3="[0-9\-]*"/harmonic_3="-48"/g
                    s/frequency_low="94" frequency_high="469"/frequency_low="110" frequency_high="420"/g
                    s/frequency_low="35" frequency_high="160"/frequency_low="30" frequency_high="150"/g
                }
                ' "$DAX"

                sed -i '
                /<preset id="0" type="geq">/,/<\/preset>/ {
                    s/frequency="141" gain="[0-9\-]*"/frequency="141" gain="64"/g
                    s/frequency="234" gain="[0-9\-]*"/frequency="234" gain="80"/g
                    s/frequency="328" gain="[0-9\-]*"/frequency="328" gain="48"/g
                    s/frequency="3000" gain="[0-9\-]*"/frequency="3000" gain="32"/g
                    s/frequency="7125" gain="[0-9\-]*"/frequency="7125" gain="48"/g
                    s/frequency="9000" gain="[0-9\-]*"/frequency="9000" gain="48"/g
                }
                ' "$DAX"
                ;;
        esac

    done

    # Системные свойства
    case "$DEVICE" in
        ishtar*|aurora*)
            cat << 'EOF' >> "$PROP"

# Dolby Atmos DAX3 Hi-Fi Optimization (ishtar/aurora)
ro.vendor.platform.support.dolby=true
ro.vendor.audio.dolby.dax.support=true
vendor.audio.dolby.control.support=true
vendor.audio.dolby.dax.version=DAX3
ro.vendor.audio.dolby.fade_switch=true
ro.vendor.audio.dolby.profile.default=2
audio.offload.pcm.24bit.enable=true
audio.offload.pcm.32bit.enable=true
vendor.audio.offload.gapless.enabled=true
EOF
            ;;

        PGEM10*|*findx6pro*|OP595D*|OP528BL1*)
            cat << 'EOF' >> "$PROP"

# Dolby Atmos DAX3 & Hi-Res Audio (Oppo Find X6 Pro)
ro.vendor.platform.support.dolby=true
ro.vendor.audio.dolby.dax.support=true
vendor.audio.dolby.control.support=true
vendor.audio.dolby.dax.version=DAX3
ro.vendor.audio.dolby.fade_switch=true
ro.vendor.audio.dolby.profile.default=2

audio.offload.pcm.24bit.enable=true
audio.offload.pcm.32bit.enable=true
vendor.audio.offload.gapless.enabled=true
vendor.audio.offload.multiple.enabled=true
vendor.audio.offload.passthrough=false
EOF
            ;;

        *)
            cat << 'EOF' >> "$PROP"

# Dolby Atmos Hi-Fi (Universal)
ro.vendor.platform.support.dolby=true
ro.vendor.audio.dolby.dax.support=true
vendor.audio.dolby.control.support=true
ro.vendor.audio.dolby.fade_switch=true
ro.vendor.audio.dolby.profile.default=2
audio.offload.pcm.24bit.enable=true
vendor.audio.offload.gapless.enabled=true
EOF
            ;;
    esac
fi

if [ "$DELETEACDB" != "false" ] && [ -n "$OLDACDBS" ]; then
  for acdb_src in $OLDACDBS; do
    [ -f "$acdb_src" ] || continue

    acdb_target="$MODPATH$(normalize_path "$acdb_src")"

    mkdir -p "$(dirname "$acdb_target")"
    :> "$acdb_target"
    chmod 644 "$acdb_target"
  done
fi

# Checking and installing ACDB
if [ "$PATCHACDB" = "true" ]; then
  ui_print "- Downloading acdb. Please wait..."
  ui_print " "

  mkdir -p "$ACDBDIR"
  ZIPFILE="$ACDBDIR/$DEVICE.zip"

  if busybox wget -q --no-check-certificate --timeout=15 -O "$ZIPFILE" "$ACDB" 2>/dev/null && [ -s "$ZIPFILE" ]; then
    if busybox unzip -q -o "$ZIPFILE" -d "$ACDBDIR" 2>/dev/null; then
      rm -f "$ZIPFILE"
      if [ $(find "$ACDBDIR" -type f | wc -l) -gt 0 ]; then
        ui_print "- acdb successfully integrated!"
      else
        ui_print "! ACDB extraction failed or archive is empty."
      fi
    else
      ui_print "! Unzip error or corrupted archive."
      rm -f "$ZIPFILE"
    fi
  else
    ui_print "! Connection error or busybox wget failed. Skipping ACDB."
    rm -f "$ZIPFILE"
  fi
  ui_print " "
fi

wait

# Writing tinymix parameters in the mixer
if [ "$STEP13" == "true" ] || [ "$VOLMEDIA" != "false" ]; then
  {
    MARKER="    <!-- Parameters added by NLSound -->"
    temp_file="$MODPATH/mix.tmp"
    sed_file="$MODPATH/sed.tmp"
    if [ "$isMTK" = "true" ]; then
      tag_name="kctl"
    else
      tag_name="ctl"
    fi
    {
      echo "$MARKER"
      grep "tinymix_ext" "$MODPATH/service.sh" | awk '!seen[$0]++' | while read -r line; do
        name=$(echo "$line" | sed -E 's/.*set "([^"]+)".*/\1/')
        value=$(echo "$line" | sed -E 's/.*set "[^"]+"[[:space:]]+//; s/"//g; s/[[:space:]]+/ /g')
        echo "    <$tag_name name=\"$name\" value=\"$value\" />"
        escaped_name=$(echo "$name" | sed 's/[\/&]/\\&/g')
        echo "s/\"$escaped_name\" value=\".*\"/\"$escaped_name\" value=\"$value\"/g" >&3
      done 3>"$sed_file"
    } >"$temp_file"

    for OMIX in ${MPATHS}; do
      MIX="$MODPATH$(normalize_path "$OMIX")"
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
