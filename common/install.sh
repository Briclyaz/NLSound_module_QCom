#!/bin/bash

MODID="NLSound"
MIRRORDIR="/data/local/tmp/NLSound"
OTHERTMPDIR="/dev/NLSound"
PROP=$MODPATH/system.prop
RESTORE_SETTINGS="/storage/emulated/0/NLSound/settings.nls"
VERSION=$(grep "^version=" /data/adb/modules_update/NLSound/module.prop | cut -d'=' -f2-)
if [ ! -f "$RESTORE_SETTINGS" ]; then
  RESTORE_SETTINGS="/data/adb/modules/NLSound/settings.nls"
fi

LANG=$(settings get system system_locales)
DEVICE=$(getprop ro.product.vendor.device)
if [ "$DEVICE" == "mivendor" ]; then
  DEVICE=$(getprop ro.product.product.name) #mi14ultra - aurora, mi13ultra - ishtar
fi
PROCESSOR=$(getprop ro.board.platform)
ACDB="https://github.com/Briclyaz/NLSound_module_acdb_addon/raw/refs/heads/main/$DEVICE.zip"
ACDBDIR="$MODPATH/system/vendor/etc/acdbdata"

all_files=$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f \
  -name "audio_configs*.xml" -o \
  -name "$DEVICE.xml" -o \
  -name "DeviceFeatures.xml" -o \
  -name "audio_policy_configuration*.xml" -o \
  -name "media_codecs_c2_audio.xml" -o \
  -name "media_codecs_google_audio.xml" -o \
  -name "media_codecs_google_c2_audio.xml" -o \
  -name "media_codecs_dolby_audio.xml" -o \
  -name "audio_io_policy.conf" -o \
  -name "audio_output_policy.conf" -o \
  -name "*resourcemanager*.xml" -o \
  -name "dax-*.xml" -o \
  -name "multimedia_dolby_dax*.xml" -o \
  -name "*mixer_paths*.xml" -o \
  -name "audio_platform_info*.xml" -o \
  -name "audio_effects*.conf" -o \
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
  -name "libasphere*.so" -o \
  -name "libaudiopreprocessing*.so" -o \
  -name "libdownmix*.so" -o \
  -name "libdynproc*.so" -o \
  -name "libeffectproxy*.so" -o \
  -name "libhapticgenerator*.so" -o \
  -name "libldnhncr*.so" -o \
  -name "libqcompostprocbundle*.so" -o \
  -name "libqcomvisualizer*.so" -o \
  -name "libqcomvoiceprocessing*.so" -o \
  -name "libreverbwrapper*.so" -o \
  -name "libshoebox*.so" -o \
  -name "libvisualizer*.so" -o \
  -name "libvolumelistener*.so" -o \
  -name "libdlbvol*.so" -o \
  -name "liboplusupmixeffect*.so" -o \
  -name "libswdap*.so" -o \
  -name "libhwdap*.so" -o \
  -name "libswvqe*.so" -o \
  -name "libswgamedap*.so" -o \
  -name "libquasar*.so" -o \
  -name "libOplusSpatializer*.so" -o \
  -name "libdynproc*.so" -o \
  -name "libbundlewrapper*.so" -o \
  -name "libswspatializer*.so")

case "$PROCESSOR" in "pitti" | "sdm660" | "msm8937" | "msm8953")
  HIFI=false
  ui_print " "
  ui_print " - Device without support Hi-Fi detected! -"
  ui_print " "
  ;;
*)
  HIFI=true
  ui_print " "
  ui_print " - Device with support Hi-Fi detected! -"
  ui_print " "
  ;;
esac

case "$DEVICE" in RE5C82L1* | RE5C3B* | alioth* | ingres* | OnePlus9R* | OnePlus9Pro* | vayu* | star* | OP594DL1* | ishtar* | aurora* | citrus* | juice* | chime* | lime* | surya* | mojito* | sweet* | sweetin* | willow* | a71* | RE54E4L1* | OnePlus9RT* | RE5473* | RE879AL1* | kona* | b0q* | marble* | joyeuse* | curtana* | gram* | excalibur* | bluejay* | oriel* | raven* | cheetah* | panther* | OP595DL1*)
  tinymix_support=true
  ;;
*)
  tinymix_support=false
  ;;
esac

handle_input() {
  while true; do
    case $(timeout 0.01 getevent -lqc 1) in
    *KEY_VOLUMEUP*DOWN*)
      echo "up"
      return
      ;;
    *KEY_VOLUMEDOWN*DOWN*)
      echo "down"
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
      "down") break ;;
      esac
    done
    return $selected
  fi
}

ACONFS=$(echo "$all_files" | grep "audio_configs.*.xml")
AEFFECTCONFS=$(echo "$all_files" | grep "audio_effects.*.conf")
DEVFEAS=$(echo "$all_files" | grep "$DEVICE.xml")
DEVFEASNEW=$(echo "$all_files" | grep "DeviceFeatures.xml")
AUDIOPOLICYS=$(echo "$all_files" | grep "audio_policy_configuration.*.xml")
MCODECS=$(echo "$all_files" | grep -E "media_codecs_c2_audio.xml|media_codecs_google_audio.xml|media_codecs_google_c2_audio.xml")
DCODECS=$(echo "$all_files" | grep "media_codecs_dolby_audio.xml")
IOPOLICYS=$(echo "$all_files" | grep "audio_io_policy.conf")
OUTPUTPOLICYS=$(echo "$all_files" | grep "audio_output_policy.conf")
RESOURCES=$(echo "$all_files" | grep ".*resourcemanager.*.xml")
DAXES=$(echo "$all_files" | grep -E "dax-.*.xml|multimedia_dolby_dax.*.xml")
MPATHS=$(echo "$all_files" | grep ".*mixer_paths.*.xml")
APIXMLS=$(echo "$all_files" | grep "audio_platform_info.*.xml")
MICXARS=$(echo "$all_files" | grep "microphone_characteristics.*.xml")
LIBS=$(echo "$all_files" | grep -E "libdynproc.*.so|libbundlewrapper.*.so|libswvqe.*.so|libquasar.*.so|libOplusSpatializer.*.so|libasphere.*.so|libaudiopreprocessing.*.so|libdownmix.*.so|libdynproc.*.so|libeffectproxy.*.so|libhapticgenerator.*.so|libldnhncr.*.so|libqcompostprocbundle.*.so|libqcomvisualizer.*.so|libqcomvoiceprocessing.*.so|libreverbwrapper.*.so|libshoebox.*.so|libvisualizer.*.so|libvolumelistener.*.so|libdlbvol.*.so|liboplusupmixeffect.*.so|libhwdap.*.so|libswdap.*.so|libswgamedap.*.so|libswspatializer.*.so")
APPS=$(echo "$all_files" | grep -E ".*AudioEffectCenter.*.apk|.*SamsungDAP.*.apk|.*AudioFX.*.apk|.*MusicFX.*.apk")
OLDACDBS=$(echo "$all_files" | grep -E ".*General_cal.acdb|.*Global_cal.acdb|.*Speaker_cal.acdb|.*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb")

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

for MIX in ${MPATHS}; do
  if grep -q 'name="IIR0 Band1" id ="0" value="' "$MIX"; then
    FOUND_IIR=true
    break
  fi
done

#auto-translate for configurator
continue_script=true
if [[ "$LANG" =~ "en-RU" ]] || [[ "$LANG" =~ "ru-" ]]; then
  if [ -f "$RESTORE_SETTINGS" ]; then
    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "       • ПРЕДЫДУЩИЕ НАСТРОЙКИ ОБНАРУЖЕНЫ •         "
    ui_print "                                                   "
    ui_print "  Вы можете установить такие же настройки, что     "
    ui_print "  и в прошлый раз.                                 "
    ui_print "                                                   "
    ui_print "   ЗАМЕТКА:                                        "
    ui_print "  При переходе с одной версии модуля на другую     "
    ui_print "  могут появиться другие пункты, они будут         "
    ui_print "  пропущены, т.к не были записаны ранее.           "
    ui_print "___________________________________________________"
    ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Установить" "Пропустить"
    if [ $? -eq 1 ]; then
      continue_script=false
      old_modpath=$MODPATH
      source "$RESTORE_SETTINGS"
      MODPATH=$old_modpath
      export SAMPLERATE BITNES VOLMIC VOLMEDIA VOLSTEPS STEP6 STEP7 STEP8 STEP9 STEP10 STEP11 STEP12 STEP13 STEP14 STEP15 PATCHACDB DELETEACDB
    else
      ui_print " - Восстановление предыдущих настроек пропущено"
      ui_print " "
      sleep 0.3
    fi
  fi
  if [ $continue_script == true ]; then
    ui_print " - Настрой меня, пожалуйста! >.< - "
    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [1/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "     • ВЫБЕРИТЕ КОЛИЧЕСТВО ШАГОВ ГРОМКОСТИ •       "
    ui_print "                                                   "
    ui_print "  Этот пункт изменит количество шагов громкости    "
    ui_print "  для музыки в вашей системе. Для аудио-вызовов    "
    ui_print "  и иных сценариев шаги останутся прежними.        "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Изменить выбор | [VOL-] - Подтвердить  "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 30 ( ~ 1.1 - 2.0 dB каждый шаг)"
    ui_print "   3. 50 ( ~ 0.8 - 1.4 dB каждый шаг)"
    ui_print "   4. 100 ( ~ 0.4 - 0.7 dB каждый шаг)"
    ui_print " "
    show_menu "[Пропустить]" "30" "50" "100"
    case $? in
    1) VOLSTEPS="false" ;;
    2) VOLSTEPS=30 ;;
    3) VOLSTEPS=50 ;;
    4) VOLSTEPS=100 ;;
    esac
    ui_print " - [*] Выбрано: $VOLSTEPS"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [2/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "      • ВЫБЕРИТЕ УРОВЕНЬ ГРОМКОСТИ МУЗЫКИ •        "
    ui_print "                                                   "
    ui_print "  Этот пункт изменит максимальный порог            "
    ui_print "  громкости музыки в вашей системе. Чем больше     "
    ui_print "  числовое значение, тем выше максимальная         "
    ui_print "  громкость.                                       "
    ui_print "                                                   "
    ui_print "   ПРЕДУПРЕЖДЕНИЕ:                                 "
    ui_print "  Слишком высокие значения могут привести к        "
    ui_print "  искажениям звука.                                "
    ui_print "                                                   "
    ui_print "   ЗАМЕТКА:                                        "
    ui_print "  Не оказывает эффекта на Bluetooth.               "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Изменить выбор | [VOL-] - Подтвердить  "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 78"
    ui_print "   3. 84 (Обычно используется по умолчанию)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    show_menu "[Пропустить]" "78" "84" "90" "96" "102" "108"
    case $? in
    1) VOLMEDIA="false" ;;
    2) VOLMEDIA=78 ;;
    3) VOLMEDIA=84 ;;
    4) VOLMEDIA=90 ;;
    5) VOLMEDIA=96 ;;
    6) VOLMEDIA=102 ;;
    7) VOLMEDIA=108 ;;
    esac
    ui_print " - [*] Выбрано: $VOLMEDIA"
    ui_print ""

    ui_print "  "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [3/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "     • ВЫБРАТЬ ЧУВСТВИТЕЛЬНОСТЬ МИКРОФОНОВ •       "
    ui_print "                                                   "
    ui_print "  Этот пункт изменит чувствительность микрофонов   "
    ui_print "  в вашей системе. Чем больше числовое значение,   "
    ui_print "  тем громче будет звучать запись.                 "
    ui_print "                                                   "
    ui_print "   ПРЕДУПРЕЖДЕНИЕ:                                 "
    ui_print "  Слишком высокие значения могут привести к        "
    ui_print "  искажениям звука.                                "
    ui_print "                                                   "
    ui_print "   ЗАМЕТКА:                                        "
    ui_print "  Не оказывает эффекта на Bluetooth.               "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Изменить выбор | [VOL-] - Подтвердить  "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 78"
    ui_print "   3. 84 (Обычно используется по умолчанию)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    show_menu "[Пропустить]" "78" "84" "90" "96" "102" "108"
    case $? in
    1) VOLMIC="false" ;;
    2) VOLMIC=78 ;;
    3) VOLMIC=84 ;;
    4) VOLMIC=90 ;;
    5) VOLMIC=96 ;;
    6) VOLMIC=102 ;;
    7) VOLMIC=108 ;;
    esac
    ui_print " - [*] Выбрано: $VOLMIC"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [4/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "           • ВЫБЕРИТЕ БИТНОСТЬ АУДИО •             "
    ui_print "                                                   "
    ui_print "  Этот пункт настроит аудио кодек вашего           "
    ui_print "  устройства, заставляя его обрабатывать звук в    "
    ui_print "  соответствии с выбранными параметрами битности   "
    ui_print "  Также этот пункт включит Hi-Fi фильтр, включит   "
    ui_print "  мультипоточную обработку звука вашим DSP и ещё   "
    ui_print "  пару мелочей.                                    "
    ui_print "                                                   "
    ui_print "   ЗАМЕТКА:                                        "
    ui_print "  Не оказывает эффекта на Bluetooth.               "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Изменить выбор | [VOL-] - Подтвердить  "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 16-бит"
    ui_print "   3. 24-бита"
    ui_print "   4. 32-бита (только для SD870 и выше)"
    ui_print "   5. Флоат (только для устройств с аппаратным ЦАП)"
    ui_print " "
    show_menu "[Пропустить]" "16 бит" "24 бита" "32 бита" "Флоат"
    case $? in
    1) BITNES="false" ;;
    2) BITNES="16" ;;
    3) BITNES="24" ;;
    4) BITNES="32" ;;
    5) BITNES="float" ;;
    esac
    ui_print " - [*] Выбрано: $BITNES"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [5/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "       • ВЫБЕРЕТЕ ЧАСТОТУ ДИСКРЕТИЗАЦИИ •          "
    ui_print "                                                   "
    ui_print "  Этот пункт настроит аудио кодек вашего           "
    ui_print "  устройства, заставляя его обрабатывать звук в    "
    ui_print "  соответствии с выбранными параметрами частоты    "
    ui_print "  дискретизации. Также этот пункт включит Hi-Fi    "
    ui_print "  фильтр, включит мультипоточную обработку звука   "
    ui_print "  вашим DSP и ещё пару мелочей.                    "
    ui_print "                                                   "
    ui_print "   ЗАМЕТКА:                                        "
    ui_print "  Не оказывает эффекта на Bluetooth.               "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Изменить выбор | [VOL-] - Подтвердить  "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 44100 Гц"
    ui_print "   3. 48000 Гц"
    ui_print "   4. 96000 Гц"
    ui_print "   5. 192000 Гц"
    ui_print "   6. 384000 Гц (только для SD870 и выше)"
    ui_print " "
    show_menu "[Пропустить]" "44100" "48000" "96000" "192000" "384000"
    case $? in
    "1") SAMPLERATE="false" ;;
    "2") SAMPLERATE="44100" ;;
    "3") SAMPLERATE="48000" ;;
    "4") SAMPLERATE="96000" ;;
    "5") SAMPLERATE="192000" ;;
    "6") SAMPLERATE="384000" ;;
    esac

    ui_print " - [*] Выбрано: $SAMPLERATE"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [6/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "       • ОТКЛЮЧИТЬ ЗВУКОВЫЕ ВМЕШАТЕЛЬСТВА •        "
    ui_print "                                                   "
    ui_print "  Этот пункт отключит различные системные          "
    ui_print "  оптимизации звука, такие как компрессоры и       "
    ui_print "  прочие бессмысленные механизмы, которые          "
    ui_print "  мешают нормальной передаче аудио.                "
    ui_print "                                                   "
    ui_print "  Отключение защиты динамика может привести к      "
    ui_print "  хрипам                                           "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Изменить выбор | [VOL-] - Подтвердить  "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. Установить"
    ui_print "   3. Установить + отключить защиту динамика"
    ui_print " "
    show_menu "[Пропустить]" "Установить" "Отключить защиту"
    case $? in
    "1") STEP6="false" ;;
    "2") STEP6="true" ;;
    "3") STEP6="no_prot" ;;
    esac
    ui_print " - [*] Выбрано: $STEP6"
    ui_print " "
    ui_print " "

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [7/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "       • ПАТЧИНГ DEVICE_FEATURES ФАЙЛА(-ОВ) •      "
    ui_print "                                                   "
    ui_print "  Этот пункт сделает следующее:                    "
    ui_print "  - Разблокирует частоты дискретизации аудио       "
    ui_print "    вплоть до 192000 Гц;                           "
    ui_print "  - Включит HD запись аудио в камере;              "
    ui_print "  - Улучшит качество записи VoIP;                  "
    ui_print "  - Включит поддержку HD записи вашего голоса      "
    ui_print "    в приложениях;                                 "
    ui_print "  - Включит поддержку Hi-Fi на поддерживаемых      "
    ui_print "    устройствах.                                   "
    ui_print "                                                   "
    ui_print "  И многое другое...                               "
    ui_print "___________________________________________________"
    if [ -n "$DEVFEASNEW" ] || [ -n "$DEVFEAS" ]; then
      ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "Установить" "Пропустить"
      [ $? -eq 1 ] && STEP7=true
    else
      ui_print " Автоматически пропущено, не может быть установлен "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [8/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "   • ДРУГИЕ ПАТЧИ ДЛЯ MIXER_PATHS ФАЙЛА (-ОВ) •    "
    ui_print "                                                   "
    ui_print "  Эта опция изменит роуты аудио, удалит всё        "
    ui_print "  лишнее и постарается изменить конфигурацию       "
    ui_print "  аудио потока таким образом, чтобы аудио          "
    ui_print "  обрабатывалось наикратчайшим образом по пути     "
    ui_print "  к аудио кодеку вашего устройства. Также она      "
    ui_print "  отключит различные частотные отсечки и           "
    ui_print "  обрезки, которые якобы находятся вне предела     "
    ui_print "  слышимости человека.                             "
    ui_print "                                                   "
    ui_print "  Содержит АВТОРСКИЕ настройки аудио кодека для    "
    ui_print "  для поддерживаемых устройств, например:          "
    ui_print "  - Poco X3 NFC (surya);                           "
    ui_print "  - Poco X3 Pro (vayu);                            "
    ui_print "  - Redmi Note 10 Pro (sweet);                     "
    ui_print "  - Redmi Note 10 Pro Max (sweetin);               "
    ui_print "  - Mi 11 Ultra (star).                            "
    ui_print "                                                   "
    ui_print "  Эти параметры значительным образом улучшают      "
    ui_print "  качество стерео вашего устройства, общий         "
    ui_print "  объём, музыкальность, стерео сцену, исправлют    "
    ui_print "  баланс громкости в динамиках.                    "
    ui_print "___________________________________________________"
    ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Установить" "Пропустить"
    [ $? -eq 1 ] && STEP8=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [9/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "      • ТВИКИ ДЛЯ BUILD.PROP ФАЙЛА (-ОВ) •         "
    ui_print "                                                   "
    ui_print "  Содержит огромное количество глобальных          "
    ui_print "  настроек, которые значительно изменят            "
    ui_print "  качество аудио к лучшему. Не сомневайтесь,       "
    ui_print "  соглашайтесь на установку.                       "
    ui_print "___________________________________________________"
    ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Установить" "Пропустить"
    [ $? -eq 1 ] && STEP9=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [10/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "             • УЛУЧШИТЬ BLUETOOTH •                "
    ui_print "                                                   "
    ui_print "  Эта опция постарается по максимуму улучшить      "
    ui_print "  качество аудио в Bluetooth, а также исправит     "
    ui_print "  проблему самопроизвольного переключения AAC      "
    ui_print "  кодека в положение ВЫКЛЮЧЕНО.                    "
    ui_print "___________________________________________________"
    ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Установить" "Пропустить"
    [ $? -eq 1 ] && STEP10=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [11/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "            • ИЗМЕНИТЬ АУДИО ВЫХОД •               "
    ui_print "                                                   "
    ui_print "  Эта опция переключит DIRECT на DIRECT_PCM,       "
    ui_print "  обладающий большей детальностью и качеством.     "
    ui_print "  Может привести к отсутствию звука в таких        "
    ui_print "  приложениях как: TikTok, YouTube, а также в      "
    ui_print "  различных мобильных играх.                       "
    ui_print "___________________________________________________"
    if [ -n "$IOPOLICYS" ] || [ -n "$OUTPUTPOLICYS" ]; then
      ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "Установить" "Пропустить"
      [ $? -eq 1 ] && STEP11=true
    else
      ui_print " Автоматически пропущено, не может быть установлен "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [12/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "      • УСТАНОВИТЬ КАСТОМНЫЙ ПРЕСЕТ IIR •          "
    ui_print "                                                   "
    ui_print "  IIR влияет на итоговую кривую частотной          "
    ui_print "  характеристики обработанного звука вашим DSP.    "
    ui_print "  Можно сказать, что это предустановки в виде      "
    ui_print "  системного эквалайзера.                          "
    ui_print "___________________________________________________"
    if [ "$FOUND_IIR" == "true" ]; then
      ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "Установить" "Пропустить"
      [ $? -eq 1 ] && STEP12=true
    else
      ui_print " Автоматически пропущено, не может быть установлен "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [13/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "       • ИГНОРИРОВАТЬ ВСЕ АУДИО ЭФФЕКТЫ •          "
    ui_print "                                                   "
    ui_print "  Этот пункт отключит все аудио эффекты на         "
    ui_print "  системном уровне. Это сломает XiaomiParts,       "
    ui_print "  Dirac, Dolby и прочие эквалайзеры.               "
    ui_print "  Значительно повышает качество аудио для          "
    ui_print "  качественных наушников. Звук станет более        "
    ui_print "  чистым.                                          "
    ui_print "                                                   "
    ui_print "   ЗАМЕТКА:                                        "
    ui_print "  Если 15 пункт будет выбран вместе с этим,        "
    ui_print "  Dolby Atmos продолжит работать.                  "
    ui_print "                                                   "
    ui_print "  Дополнительное удаление библиотек может          "
    ui_print "  привести к проблемам. Сломает плеер VLC,         "
    ui_print "  регулировка громкости станет работать иначе      "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Изменить выбор | [VOL-] - Подтвердить  "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. Установить"
    ui_print "   3. Дополнительное удаление библиотек"
    ui_print " "
    show_menu "[Пропустить]" "Установить" "Дополнительное удаление"
    case $? in
    "1") STEP13="false" ;;
    "2") STEP13="true" ;;
    "3") STEP13="ext_rm" ;;
    esac
    ui_print " - [*] Выбрано: $STEP13"
    ui_print " "

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [14/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "     • УСТАНОВИТЬ ПЕРСОНАЛИЗИРОВАННЫЕ ТВИКИ •      "
    ui_print "                                                   "
    ui_print "  Эта опция дополнительно настроит аудио кодек     "
    ui_print "  вашего устройства при помощи tinymix функции и   "
    ui_print "  mixer_paths. Она улучшит качество аудио, но      "
    ui_print "  совместима с ограниченным количеством устройств  "
    if [ $tinymix_support == false ]; then
      ui_print "                                                   "
      ui_print "   ПРЕДУПРЕЖДЕНИЕ:                                 "
      ui_print "  Параметры не подобраны под ваше устройство. При  "
      ui_print "  установке будут использоваться общие настройки,  "
      ui_print "  возможно возникновение проблем.                  "
    fi
    ui_print "___________________________________________________"
    ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Установить" "Пропустить"
    [ $? -eq 1 ] && STEP14=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [15/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "           • НАСТРОИТЬ DOLBY ATMOS •               "
    ui_print "                                                   "
    ui_print "  Эта опция доп-но настроит ваш Dolby, если он     "
    ui_print "  имеется в системе (как системный, так и          "
    ui_print "  несистемный/кастомный), для лучшего качества     "
    ui_print "  звучания путём отключения различных мусорных     "
    ui_print "  функций и механизмов, например компрессоров,     "
    ui_print "  аудио-регуляторов и так далее.                   "
    ui_print "                                                   "
    ui_print "   ЗАМЕТКА:                                        "
    ui_print "  Если 13 пункт был выбран вместе с этим,          "
    ui_print "  Dolby Atmos продолжит работать.                  "
    ui_print "___________________________________________________"
    if [ -n "$DAXES" ] || [ -n "$DCODECS" ]; then
      ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "Установить" "Пропустить"
      [ $? -eq 1 ] && STEP15=true
    else
      ui_print " Автоматически пропущено, не может быть установлен "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [16/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    if [ -n "$OLDACDBS" ]; then
      ui_print "             • УДАЛИТЬ ACDB ФАЙЛЫ •                "
      ui_print "                                                   "
      ui_print "  Эта опция может отключить все ограничения для    "
      ui_print "  вывода звука через AUX, Bluetooth и динамики     "
      ui_print "  устройтсва.                                      "
      ui_print "                                                   "
      ui_print "   ОПИСАНИЕ ПУНКТОВ:                               "
      ui_print "  2. Удаляет ограничения для вывода через AUX,     "
      ui_print "  Bluetooth и HDMI, не затрагивая General_cal.     "
      ui_print "                                                   "
      ui_print "  3. Аналогичен второму пункту, но кроме           "
      ui_print "  базовых ограничений удаляет General_cal.         "
      ui_print "  Рекомендуется к установке только если выбор      "
      ui_print "  данного пункта не приведет к отсутствию звука.   "
      ui_print "                                                   "
      ui_print "  4. Аналогичен третьему, но так же удаляет        "
      ui_print "  ограничения по выводу звука через динамики       "
      ui_print "  устройства. Крайне небезопасный пункт, может     "
      ui_print "  привести к повреждению динамиков на высокой      "
      ui_print "  громкости, убирая все ограничения на НЧ.         "
      ui_print "                                                   "
      ui_print "   ПРЕДУПРЕЖДЕНИЕ:                                 "
      ui_print "  Соглашение на установку этого пункта может       "
      ui_print "  нанести аппаратные повреждения в случае          "
      ui_print "  неаккуратного пользования устройством (например, "
      ui_print "  слишком высокая громкость), а также приводить к  "
      ui_print "  бесконечному запуску. В то же время, эти         "
      ui_print "  параметры весьма эффективны и сильно влияют на   "
      ui_print "  звучание вашего смартфона.                       "
      ui_print "  Будьте аккуратны и помните, что мы не несём      "
      ui_print "  никакой ответственности за ваши действия.        "
      ui_print "___________________________________________________"
      ui_print "   [VOL+] - Изменить выбор | [VOL-] - Подтвердить  "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   1. Пропустить (Без каких-либо изменений)"
      ui_print "   2. Базовое удаление .acdb файлов"
      ui_print "   3. Базовое удаление + удаление General_cal"
      ui_print "   4. Базовое удаление + удаление ограничений"
      ui_print "      динамика и General_cal"
      ui_print " "
      show_menu "[Пропустить]" "Базовое" "General_cal" "Динамики"
      case $? in
      "1") DELETEACDB="false" ;;
      "2") DELETEACDB="Basic" ;;
      "3") DELETEACDB="General" ;;
      "4") DELETEACDB="Speaker" ;;
      esac
      ui_print " - [*] Выбрано: $DELETEACDBINT"
      ui_print ""
    else
      ui_print "      • УСТАНОВИТЬ ПРОПАТЧЕННЫЕ ACDB ФАЙЛЫ •       "
      ui_print "                                                   "
      ui_print "  Эта опция отключит лимитеры и изменит режим      "
      ui_print "  работы ресемплера в файлах ACDB                  "
      ui_print "                                                   "
      ui_print "   ЗАМЕТКА:                                        "
      ui_print "  На смартфонах от BBK может не влиять на звук     "
      ui_print "  из за некоторых ограничений                      "
      ui_print "___________________________________________________"
      case "$DEVICE" in alioth* | Pong* | marble* | RE5465* | mondrian* | ishtar* | aurora* | REE2B2L1*)
        ui_print "    [VOL+] - Установить | [VOL-] - Пропустить      "
        ui_print "___________________________________________________"
        ui_print " "
        show_menu "Установить" "Пропустить"
        [ $? -eq 1 ] && PATCHACDB=true
        ;;
      *)
        ui_print " Автоматически пропущено, не может быть установлен "
        ui_print "___________________________________________________"
        ;;
      esac
    fi
    ui_print " "
  fi
  ui_print "================== ВАШИ НАСТРОЙКИ ================="
  ui_print "                                                   "
  ui_print "┌──────────────────────────────────────────"
  ui_print "│N │         Настройки           │      Значения"
  ui_print "├──────────────────────────────────────────"
  ui_print "│1 │ Кол-во шагов громкости      │ ${VOLSTEPS}"
  ui_print "│2 │ Макс. уровень громкости     │ ${VOLMEDIA}"
  ui_print "│3 │ Чувствительность микрофонов │ ${VOLMIC}"
  ui_print "│4 │ Аудио формат                │ ${BITNES}"
  ui_print "│5 │ Частота дискретизации       │ ${SAMPLERATE}"
  ui_print "│6 │ Отключить вмешательства     │ ${STEP6}"
  ui_print "│7 │ Патчинг device_features     │ ${STEP7}"
  ui_print "│8 │ Другие патчи mixer_paths    │ ${STEP8}"
  ui_print "│9 │ Твики для build.prop        │ ${STEP9}"
  ui_print "│10│ Улучшить Bluetooth          │ ${STEP10}"
  ui_print "│11│ Изменить аудио выход        │ ${STEP11}"
  ui_print "│12│ Кастомный пресет IIR        │ ${STEP12}"
  ui_print "│13│ Игнорировать эффекты        │ ${STEP13}"
  ui_print "│14│ Персонализированные твики   │ ${STEP14}"
  ui_print "│15│ Настроить Dolby Atmos       │ ${STEP15}"
  ui_print "│16│ Изменить ACDB               │ $([ "$PATCHACDB" != "false" ] && echo "$PATCHACDB" || echo "$DELETEACDB")"
  ui_print "├──────────────────────────────────────────"
  ui_print "│           Информация об устройстве"
  ui_print "├──────────────────────────────────────────"
  ui_print "│  Версия модуля        │ $VERSION"
  ui_print "│  Устройство           │ $DEVICE"
  ui_print "└──────────────────────────────────────────"
  ui_print " "
  ui_print " - Установка начата, пожалуйста подождите"
  ui_print " "
elif [[ "$LANG" =~ "zh-r" ]]; then
  if [ -f "$RESTORE_SETTINGS" ]; then
    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "               • 检测到之前的配置 •                  "
    ui_print "                                                   "
    ui_print "  是否沿用之前的配置？                               "
    ui_print "                                                   "
    ui_print "   注：                                            "
    ui_print "  版本新增设置可能因为旧配置不包含而被禁用。           "
    ui_print "___________________________________________________"
    ui_print "           [音量+] - 确认 [音量-] - 跳过             "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "安装" "跳过"
    if [ $? -eq 1 ]; then
      continue_script=false
      old_modpath=$MODPATH
      source "$RESTORE_SETTINGS"
      MODPATH=$old_modpath
      export SAMPLERATE BITNES VOLMIC VOLMEDIA VOLSTEPS STEP6 STEP7 STEP8 STEP9 STEP10 STEP11 STEP12 STEP13 STEP14 STEP15
    else
      ui_print " - 弃用之前的配置"
      ui_print " "
      sleep 0.3
    fi
  fi
  if [ $continue_script == true ]; then
    ui_print " - 请配置我 >.< -  "
    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [1/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "                  • 设置音量阶数 •                  "
    ui_print "                                                   "
    ui_print "  将会改变系统媒体音量阶数，                           "
    ui_print "  对于视频通话或其他场景，                             "
    ui_print "  音量阶数不会被更改。                               "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - 更改選擇 | [VOL-] - 確認            "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. 跳过 (不更改)"
    ui_print "   2. 30 (~ 1.1 - 2.0 dp 每阶)"
    ui_print "   3. 50 (~ 0.8 - 1.4 dp 每阶)"
    ui_print "   4. 100 (~ 0.4 - 0.7 dp 每阶)"
    ui_print " "
    show_menu "[跳过]" "30" "50" "100"
    case $? in
    1) VOLSTEPS="false" ;;
    2) VOLSTEPS=30 ;;
    3) VOLSTEPS=50 ;;
    4) VOLSTEPS=100 ;;
    esac
    ui_print " - [*] 選擇: $VOLSTEPS"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [2/16]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "                    • 设置媒体音量 •                "
    ui_print "                                                   "
    ui_print "  将会更改系统媒体音量的最大阈值，                      "
    ui_print "  所选数值越大，最大音量越大。                        "
    ui_print "                                                   "
    ui_print "   警告：                                           "
    ui_print "  数值过高可能失真。                                  "
    ui_print "                                                    "
    ui_print "   注：                                             "
    ui_print "  不影响蓝牙音量。                                  "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - 更改選擇 | [VOL-] - 確認            "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. 跳过 (不会更改)"
    ui_print "   2. 78"
    ui_print "   3. 84 (通常的默认值)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    show_menu "[跳过]" "78" "84" "90" "96" "102" "108"
    case $? in
    1) VOLMEDIA="false" ;;
    2) VOLMEDIA=78 ;;
    3) VOLMEDIA=84 ;;
    4) VOLMEDIA=90 ;;
    5) VOLMEDIA=96 ;;
    6) VOLMEDIA=102 ;;
    7) VOLMEDIA=108 ;;
    esac
    ui_print " - [*] 選擇: $VOLMEDIA"
    ui_print ""

    ui_print "  "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [3/16]                                           "
    ui_print "                                                  "
    ui_print "                                                   "
    ui_print "                • 设置麦克风灵敏度 •                "
    ui_print "                                                  "
    ui_print "  将更改系统麦克风灵敏度，                            "
    ui_print "  数值越高，录音声音就越大。                         "
    ui_print "                                                  "
    ui_print "   警告：                                          "
    ui_print "  数值过高可能失真。                                "
    ui_print "                                                  "
    ui_print "   注：                                            "
    ui_print "  蓝牙状态下无效。                                  "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - 更改選擇 | [VOL-] - 確認            "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. 跳过 (不会更改)"
    ui_print "   2. 78"
    ui_print "   3. 84 (通常的默认值)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    show_menu "[跳过]" "78" "84" "90" "96" "102" "108"
    case $? in
    1) VOLMIC="false" ;;
    2) VOLMIC=78 ;;
    3) VOLMIC=84 ;;
    4) VOLMIC=90 ;;
    5) VOLMIC=96 ;;
    6) VOLMIC=102 ;;
    7) VOLMIC=108 ;;
    esac
    ui_print " - [*] 選擇: $VOLMIC"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [4/16]                                           "
    ui_print "                                                  "
    ui_print "                                                   "
    ui_print "                   • 选择音频格式 •                "
    ui_print "                                                  "
    ui_print "  将更改设备的音频编码器，                          "
    ui_print "  强制使用指定比特率处理音频。                       "
    ui_print "  此外，还将启用Hi-Fi滤波器，                       "
    ui_print "  启用DSP多线程音频处理，和其他小修改。               "
    ui_print "                                                  "
    ui_print "   注：                                            "
    ui_print "  蓝牙状态下无效。                                     "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - 更改選擇 | [VOL-] - 確認            "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. 跳过 (不更改)"
    ui_print "   2. 16-bit"
    ui_print "   3. 24-bit"
    ui_print "   4. 32-bit (仅适用于 SD870 及更高版本)"
    ui_print "   5. Float"
    ui_print " "
    show_menu "[跳过]" "16 bit" "24 bit" "32 bit" "Float"
    case $? in
    1) BITNES="false" ;;
    2) BITNES="16" ;;
    3) BITNES="24" ;;
    4) BITNES="32" ;;
    5) BITNES="float" ;;
    esac
    ui_print " - [*] 選擇: $BITNES"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [5/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "                  • 选择音频格式  •                 "
    ui_print "                                                  "
    ui_print "  将更改设备的音频编码器，                          "
    ui_print "  使其根据选定的采样率处理音频，                     "
    ui_print "  此外，还将启用Hi-Fi滤波器，                        "
    ui_print "  启用DSP多线程音频处理，和其他小修改。               "
    ui_print "                                                  "
    ui_print "   注：                                          "
    ui_print "  蓝牙状态下无效。                      "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - 更改選擇 | [VOL-] - 確認            "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. 跳过 (不更改)"
    ui_print "   2. 44100 Hz"
    ui_print "   3. 48000 Hz"
    ui_print "   4. 96000 Hz"
    ui_print "   5. 192000 Hz"
    ui_print "   6. 384000 Hz (仅适用于 SD870 及更高版本)"
    ui_print " "
    show_menu "[跳过]" "44100" "48000" "96000" "192000" "384000"
    case $? in
    "1") SAMPLERATE="false" ;;
    "2") SAMPLERATE="44100" ;;
    "3") SAMPLERATE="48000" ;;
    "4") SAMPLERATE="96000" ;;
    "5") SAMPLERATE="192000" ;;
    "6") SAMPLERATE="384000" ;;
    esac

    ui_print " - [*] 選擇: $SAMPLERATE"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [6/16]                                           "
    ui_print "                                                   "
    ui_print "                                                  "
    ui_print "                  • 关闭声音干扰 •                  "
    ui_print "                                                  "
    ui_print "  将禁用系统各种音频优化，                            "
    ui_print "  如：压缩器，限制器，和其他干扰正常音频的不必要机制。  "
    ui_print "                                                   "
    ui_print "  禁用揚聲器保護可能導致失真                         "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - 更改選擇 | [VOL-] - 確認            "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. 跳過 (不做任何更改)"
    ui_print "   2. 設置"
    ui_print "   3. 設置 + 禁用揚聲器保護"
    ui_print " "
    show_menu "[跳過]" "設置" "禁用揚聲器保護"
    case $? in
    "1") STEP6="false" ;;
    "2") STEP6="true" ;;
    "3") STEP6="no_prot" ;;
    esac
    ui_print " - [*] 選擇: $STEP6"
    ui_print " "
    ui_print " "

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [7/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "                   • 修补设备文件 •          "
    ui_print "                                                  "
    ui_print "  此操作有以下效果：                "
    ui_print "  - 解锁最高音频采样率 192000 Hz；    "
    ui_print "  - 在相机中启用 HD 音频录制。          "
    ui_print "  - 提高 VoIP 录音质量；                   "
    ui_print "  - 在支持的设备上启用 Hi-Fi。        "
    ui_print "  - 在 app 中启用 HD 录音支持；            "
    ui_print "  - 等......                                "
    ui_print "___________________________________________________"
    if [ -n "$DEVFEASNEW" ] || [ -n "$DEVFEAS" ]; then
      ui_print "           [音量+] -安装 [音量-] -跳过              "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "音量" "跳过"
      [ $? -eq 1 ] && STEP7=true
    else
      ui_print "                自動跳過，無法安裝                  "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [8/16]                                           "
    ui_print "                                                  "
    ui_print "                                                   "
    ui_print "            • MIXER_PATHS 文件的其他修补 •            "
    ui_print "                                                  "
    ui_print "  将更改音频路由，删除任何多余内容；   "
    ui_print "  并尝试更改音频流配置，使音频以更短的      "
    ui_print "  路径到达音频处理器，它将禁用各种对频率的截止                                "
    ui_print "  和限制，即使这些频率被认为超出人类听力范围。     "
    ui_print "                                                  "
    ui_print "  包含以下受支持设备的自定义音频编解码器设置：        "
    ui_print "  - Poco X3 NFC (surya);                          "
    ui_print "  - Poco X3 Pro (vayu);                           "
    ui_print "  - Redmi Note 10 (mojito);                       "
    ui_print "  - Redmi Note 10 Pro (sweet/in);                 "
    ui_print "  - Mi 11 Ultra (star);                           "
    ui_print "  - 和其他更多机型......                   "
    ui_print "                                                  "
    ui_print "  这些设置显著提高了设备立体声质量、整体音量、             "
    ui_print "  音感、立体声场景、并优化了扬声器的音量平衡。         "
    ui_print "___________________________________________________"
    ui_print "             [音量+] -安装 [音量-] -跳过          "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "音量" "跳过"
    [ $? -eq 1 ] && STEP8=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [9/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "              • 调整 BUILD.PROP 文件 •             "
    ui_print "                                                  "
    ui_print "  包含大量全局设置，这些设置将显著改善音频质量，         "
    ui_print "  不要犹豫，同意安装！    "
    ui_print "___________________________________________________"
    ui_print "             [音量+] -安装 [音量-] -跳过          "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "音量" "跳过"
    [ $? -eq 1 ] && STEP9=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [10/16]                                          "
    ui_print "                                                   "
    ui_print "                                                  "
    ui_print "                  • 改善蓝牙音频 •                "
    ui_print "                                                  "
    ui_print "  将最大限度的改善蓝牙中的音频质量，    "
    ui_print "  并解决 ACC 编码器自动关闭的问题。    "
    ui_print "___________________________________________________"
    ui_print "            [音量+] -安装 [音量-] -跳过          "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "音量" "跳过"
    [ $? -eq 1 ] && STEP10=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [11/16]                                          "
    ui_print "                                                  "
    ui_print "                                                   "
    ui_print "                   • 切换音频输出 •               "
    ui_print "                                                  "
    ui_print "  将从 DIRECT 切换至 DIRECT_PCM，      "
    ui_print "  其拥有更好的细节和质量。            "
    ui_print "                                                  "
    ui_print " 警告：                                         "
    ui_print "  这可能会导致 TikTok、YouTube及         "
    ui_print "  各种手机游戏等应用没有声音。        "
    ui_print "                                                  "
    ui_print "___________________________________________________"
    if [ -n "$IOPOLICYS" ] || [ -n "$OUTPUTPOLICYS" ]; then
      ui_print "           [音量+] -安装 [音量-] -跳过              "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "音量" "跳过"
      [ $? -eq 1 ] && STEP11=true
    else
      ui_print "                自動跳過，無法安裝                  "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [12/16]                                          "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "             • 为 IIR 安装自定义预设 •       "
    ui_print "                                                  "
    ui_print "  IIR 会影响 DSP 处理后音频的最终频率响应曲线。    "
    ui_print "  相当于系统均衡器形式的预设。             "
    ui_print "___________________________________________________"
    if [ "$FOUND_IIR" == "true" ]; then
      ui_print "           [音量+] -安装 [音量-] -跳过              "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "音量" "跳过"
      [ $? -eq 1 ] && STEP12=true
    else
      ui_print "                自動跳過，無法安裝                  "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [13/16]                                          "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "                • 忽略全部音频效果 •            "
    ui_print "                                                  "
    ui_print "  将禁用系统的全部音频效果。包括       "
    ui_print "  XiaomiParts、Dirac、Dolby和其他均衡器。   "
    ui_print "  这大大提高了高品质耳机的音质。      "
    ui_print "                                                  "
    ui_print "   注：                                          "
    ui_print "  如果安装，声音会变得更干燥、更清晰、更平坦。         "
    ui_print "  建议大多数用户跳过此项。                                "
    ui_print "                                                  "
    ui_print "  移除額外的函式庫可能會導致問題，                     "
    ui_print "  這將會破壞 VLC 播放器，                             "
    ui_print "  並且音量控制方式會有所不同。                       "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - 更改選擇 | [VOL-] - 確認            "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. 跳過（不進行任何更改）"
    ui_print "   2. 安裝"
    ui_print "   3. 移除額外的函式庫"
    ui_print " "
    show_menu "[跳過]" "安裝" "移除額外函式庫"
    case $? in
    "1") STEP13="false" ;;
    "2") STEP13="true" ;;
    "3") STEP13="ext_rm" ;;
    esac
    ui_print " - [*] 已選擇: $STEP13"
    ui_print " "

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [14/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "     • 安裝個人化調整 •                             "
    ui_print "                                                   "
    ui_print "  此選項將使用 tinymix 功能和 mixer_paths 進一步配置 "
    ui_print "  您的設備音頻編解碼器。它將改善音頻質量，但僅與有限   "
    ui_print "  數量的設備兼容。                                  "
    if [ $tinymix_support == false ]; then
      ui_print "                                                   "
      ui_print "   警告:                                            "
      ui_print "  參數不適用於您的設備。將使用通用設置，可能會導致問題。"
    fi
    ui_print "___________________________________________________"
    ui_print "    [VOL+] - 安裝 | [VOL-] - 跳過                  "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "音量" "跳过"
    [ $? -eq 1 ] && STEP14=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [15/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "              • 配置杜比 atmos •                    "
    ui_print "                                                   "
    ui_print "  该选项将额外调整您的杜比，如果它是 系统中存在        "
    ui_print "  系统和 非系统/自定义），以提高质量                  "
    ui_print "  关闭各种垃圾声音 功能和机制，如压缩机、音频控制等。   "
    ui_print "                                                    "
    ui_print "  备注：                                            "
    ui_print "  如果同时选择了第 13 项、杜比全景声将继续工作。       "
    ui_print "___________________________________________________"
    if [ -n "$DAXES" ] || [ -n "$DCODECS" ]; then
      ui_print "           [音量+] -安装 [音量-] -跳过              "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "音量" "跳过"
      [ $? -eq 1 ] && STEP15=true
    else
      ui_print "                自動跳過，無法安裝                  "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [16/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    if [ -n "$OLDACDBS" ]; then
      ui_print "             • 移除 ACDB 文件 •                  "
      ui_print "                                                   "
      ui_print "  此選項可能禁用設備通過 AUX、藍牙和揚聲器的       "
      ui_print "  所有音頻輸出限制。                              "
      ui_print "                                                   "
      ui_print "   選項描述:                                      "
      ui_print "  2. 移除 AUX、藍牙和 HDMI 的輸出限制，            "
      ui_print "  不影響 General_cal。                            "
      ui_print "                                                   "
      ui_print "  3. 與第二項類似，但還會移除 General_cal。        "
      ui_print "  僅當選擇此項不會導致無聲時推薦使用。             "
      ui_print "                                                   "
      ui_print "  4. 與第三項類似，但還會移除揚聲器的音頻輸出限制。"
      ui_print "  非常危險，可能在高音量下損壞揚聲器，因為移除了   "
      ui_print "  所有低頻限制。                                   "
      ui_print "                                                 "
      ui_print "   警告:                                          "
      ui_print "  同意此選項可能導致硬件損壞（例如音量過高），     "
      ui_print "  並可能導致無限重啟。同時，這些參數對您的         "
      ui_print "  智能手機音質影響顯著。請謹慎操作，並記住我們    "
      ui_print "  不對您的操作負任何責任。                         "
      ui_print "___________________________________________________"
      ui_print "        [VOL+] - 更改選擇 | [VOL-] - 確認            "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   1. 跳過 (無更改)"
      ui_print "   2. 基本刪除 .acdb 文件"
      ui_print "   3. 基本刪除 + 刪除 General_cal"
      ui_print "   4. 基本刪除 + 刪除揚聲器和 General_cal 的限制"
      ui_print " "
      show_menu "[跳過]" "基本刪除" "General_cal" "刪除揚聲器和 General_cal"
      case $? in
      "1") DELETEACDB="false" ;;
      "2") DELETEACDB="Basic" ;;
      "3") DELETEACDB="General" ;;
      "4") DELETEACDB="Speaker" ;;
      esac
      ui_print " - [*] 已選擇: $DELETEACDBINT"
      ui_print ""
    else
      ui_print "          • 安装已打补丁的 ACDB 文件 •               "
      ui_print "                                                   "
      ui_print "  该选项将禁用限制器并更改模式                        "
      ui_print "  ACDB 文件中的重采样器操作                          "
      ui_print "                                                   "
      ui_print "   备注：                                           "
      ui_print "  步步高智能手机的声音可能不受影响 由于某些限制        "
      ui_print "___________________________________________________"
      case "$DEVICE" in alioth* | Pong* | marble* | RE5465* | mondrian* | ishtar* | aurora* | REE2B2L1*)
        ui_print "           [音量+] -安装 [音量-] -跳过              "
        ui_print "___________________________________________________"
        ui_print " "
        show_menu "音量" "跳过"
        [ $? -eq 1 ] && PATCHACDB=true
        ;;
      *)
        ui_print " 自动跳过，无法安装 "
        ui_print "___________________________________________________"
        ;;
      esac
    fi
    ui_print " "
  fi
  ui_print "===================== 您的配置 ====================="
  ui_print "                                                   "
  ui_print "┌──────────────────────────────────────────"
  ui_print "│N │            自訂           │      價值"
  ui_print "├──────────────────────────────────────────"
  ui_print "│1 │ 音量阶数                   │ ${VOLSTEPS}"
  ui_print "│2 │ 音量阈值                   │ ${VOLMEDIA}"
  ui_print "│3 │ 麦克风灵敏度                │ ${VOLMIC}"
  ui_print "│4 │ 音频格式                   │ ${BITNES}"
  ui_print "│5 │ 采样率                     │ ${SAMPLERATE}"
  ui_print "│6 │ 关闭声音干扰                │ ${STEP6}"
  ui_print "│7 │ 修补 device_features 文件  │ ${STEP7}"
  ui_print "│8 │ 对 mixer_paths 的其他修补   │ ${STEP8}"
  ui_print "│9 │ 调整 build.prop            │ ${STEP9}"
  ui_print "│10│ 改善蓝牙音质                │ ${STEP10}"
  ui_print "│11│ 切换音频输出                │ ${STEP11}"
  ui_print "│12│ 为 IIR 自定义预设           │ ${STEP12}"
  ui_print "│13│ 忽略全部音频效果             │ ${STEP13}"
  ui_print "│14│ 個性化調整                  │ ${STEP14}"
  ui_print "│15│ 配置杜比 atmos              │ ${STEP15}"
  ui_print "│16│ 修改 ACDB 文件              │ $([ "$PATCHACDB" != "false" ] && echo "$PATCHACDB" || echo "$DELETEACDB")"
  ui_print "├──────────────────────────────────────────"
  ui_print "│                    设备信息"
  ui_print "├──────────────────────────────────────────"
  ui_print "│  模块版本               │ $VERSION"
  ui_print "│  设备                  │ $DEVICE"
  ui_print "└──────────────────────────────────────────"
  ui_print " "
  ui_print " - 安装正在进行，请坐和放宽......"
  ui_print " "
else
  if [ -f "$RESTORE_SETTINGS" ]; then
    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "         • PREVIOUS SETTINGS DETECTED •            "
    ui_print "                                                   "
    ui_print "  You can restore the configuration from your      "
    ui_print "  previous installation.                           "
    ui_print "                                                   "
    ui_print "   NOTE:                                           "
    ui_print "  Recently added items may be skipped while        "
    ui_print "  updating to a newer release of the module.       "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - Install | [VOL-] - Skip           "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Install" "Skip"
    if [ $? -eq 1 ]; then
      continue_script=false
      old_modpath=$MODPATH
      source "$RESTORE_SETTINGS"
      MODPATH=$old_modpath
      export SAMPLERATE BITNES VOLMIC VOLMEDIA VOLSTEPS STEP6 STEP7 STEP8 STEP9 STEP10 STEP11 STEP12 STEP13 STEP14 STEP15
    else
      ui_print " - Restoring previous settings skipped"
      ui_print " "
      sleep 0.3
    fi
  fi
  if [ $continue_script == true ]; then
    ui_print " - Configurate me, pls >.< - "
    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [1/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "            • SELECT VOLUME STEPS •                "
    ui_print "                                                   "
    ui_print "  Change the total number of volume steps for      "
    ui_print "  media playback.                                  "
    ui_print "  Volume steps for calls, notifications and        "
    ui_print "  alarms will not be affected.                     "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Skip (No changes will be made)"
    ui_print "   2. 30 ( ~ 1.1 - 2.0 dB per step)"
    ui_print "   3. 50 ( ~ 0.8 - 1.4 dB per step)"
    ui_print "   4. 100 ( ~ 0.4 - 0.7 dB per step)"
    ui_print " "
    show_menu "[Skip]" "30" "50" "100"
    case $? in
    "1") VOLSTEPS="false" ;;
    "2") VOLSTEPS="30" ;;
    "3") VOLSTEPS="50" ;;
    "4") VOLSTEPS="100" ;;
    esac
    ui_print " - [*] Selected: $VOLSTEPS"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [2/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "             • SELECT VOLUME LEVEL •               "
    ui_print "                                                   "
    ui_print "  Raise the volume level for media playback.       "
    ui_print "  A higher value increases the output limit.       "
    ui_print "                                                   "
    ui_print "   WARNING:                                        "
    ui_print "  Volume levels that are too high may              "
    ui_print "  cause distortion.                                "
    ui_print "                                                   "
    ui_print "   NOTE:                                           "
    ui_print "  Does not affect Bluetooth.                       "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Skip (No changes will be made)"
    ui_print "   2. 78"
    ui_print "   3. 84 (The default on most devices)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    show_menu "[Skip]" "78" "84" "90" "96" "102" "108"
    case $? in
    "1") VOLMEDIA="false" ;;
    "2") VOLMEDIA="78" ;;
    "3") VOLMEDIA="84" ;;
    "4") VOLMEDIA="90" ;;
    "5") VOLMEDIA="96" ;;
    "6") VOLMEDIA="102" ;;
    "7") VOLMEDIA="108" ;;
    esac
    ui_print " - [*] Selected: $VOLMEDIA"
    ui_print ""

    ui_print "  "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [3/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "        • SELECT MICROPHONE SENSITIVITY •          "
    ui_print "                                                   "
    ui_print "  Adjust the sensitivity of your device's          "
    ui_print "  built-in microphones. A higher value will        "
    ui_print "  make recordings sound louder.                    "
    ui_print "                                                   "
    ui_print "   WARNING:                                        "
    ui_print "  Volume levels that are too high may              "
    ui_print "  cause distortion.                                "
    ui_print "                                                   "
    ui_print "   NOTE:                                           "
    ui_print "  Does not affect Bluetooth.                       "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Skip (No changes will be made)"
    ui_print "   2. 78"
    ui_print "   3. 84 (The default on most devices)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    show_menu "[Skip]" "78" "84" "90" "96" "102" "108"
    case $? in
    "1") VOLMIC="false" ;;
    "2") VOLMIC="78" ;;
    "3") VOLMIC="84" ;;
    "4") VOLMIC="90" ;;
    "5") VOLMIC="96" ;;
    "6") VOLMIC="102" ;;
    "7") VOLMIC="108" ;;
    esac
    ui_print " - [*] Selected: $VOLMIC"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [4/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "              • SELECT BIT DEPTH •                 "
    ui_print "                                                   "
    ui_print "  Configure the audio codec to process streams     "
    ui_print "  at the desired bit depth.                        "
    ui_print "  This also enables DSP multithreading and         "
    ui_print "  applies a few more tweaks.                       "
    ui_print "                                                   "
    ui_print "   NOTE:                                           "
    ui_print "  Does not affect Bluetooth.                       "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Skip (No changes will be made)"
    ui_print "   2. 16-bit"
    ui_print "   3. 24-bit"
    ui_print "   4. 32-bit (Only for SM8250 and higher)"
    ui_print "   5. Float"
    ui_print " "
    show_menu "[Skip]" "16 bit" "24 bit" "32 bit" "Float"
    case $? in
    "1") BITNES="false" ;;
    "2") BITNES="16" ;;
    "3") BITNES="24" ;;
    "4") BITNES="32" ;;
    "5") BITNES="float" ;;
    esac
    ui_print " - [*] Selected: $BITNES"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [5/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "             • SELECT SAMPLE RATE •                "
    ui_print "                                                   "
    ui_print "  Configure the audio codec to process streams     "
    ui_print "  at the desired sample rate.                      "
    ui_print "  This also enables DSP multithreading and         "
    ui_print "  applies a few more tweaks.                       "
    ui_print "                                                   "
    ui_print "   NOTE:                                           "
    ui_print "  Does not affect Bluetooth.                       "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Skip (No changes will be made)"
    ui_print "   2. 44100 Hz"
    ui_print "   3. 48000 Hz"
    ui_print "   4. 96000 Hz"
    ui_print "   5. 192000 Hz"
    ui_print "   6. 384000 Hz (Only for SM8250 and higher)"
    ui_print " "
    show_menu "[Skip]" "44100" "48000" "96000" "192000" "384000"
    case $? in
    "1") SAMPLERATE="false" ;;
    "2") SAMPLERATE="44100" ;;
    "3") SAMPLERATE="48000" ;;
    "4") SAMPLERATE="96000" ;;
    "5") SAMPLERATE="192000" ;;
    "6") SAMPLERATE="384000" ;;
    esac

    ui_print " - [*] Selected: $SAMPLERATE"
    ui_print ""

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [6/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "        • TURN OFF SOUND INTERFERENCE •            "
    ui_print "                                                   "
    ui_print "  Disable various system-level DSPs such as        "
    ui_print "  limiters, compressors and other unnecessary      "
    ui_print "  effects that restrict dynamic range, making      "
    ui_print "  the output sound muddy.                          "
    ui_print "                                                   "
    ui_print "  Disabling speaker protection may lead to         "
    ui_print "  distortion                                       "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Skip (No changes)"
    ui_print "   2. Set"
    ui_print "   3. Set + disable speaker protection"
    ui_print " "
    show_menu "[Skip]" "Set" "disable protection"
    case $? in
    "1") STEP6="false" ;;
    "2") STEP6="true" ;;
    "3") STEP6="no_spkr_prot" ;;
    esac
    ui_print " - [*] Selected: $STEP6"
    ui_print " "
    ui_print " "

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [7/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "         • PATCH DEVICE_FEATURES FILES •           "
    ui_print "                                                   "
    ui_print "  This step will do the following:                 "
    ui_print "  - Unlock audio sample rates up to 192000 Hz;     "
    ui_print "  - Enable HD audio recording for calls,           "
    ui_print "    voice notes and videos;                        "
    ui_print "  - Improve VoIP audio quality;                    "
    ui_print "  - Enable Hi-Fi support (on some devices)         "
    ui_print "                                                   "
    ui_print "  And much more...                                 "
    ui_print "___________________________________________________"
    if [ -n "$DEVFEASNEW" ] || [ -n "$DEVFEAS" ]; then
      ui_print "        [VOL+] - Install | [VOL-] - skip           "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "Install" "Skip"
      [ $? -eq 1 ] && STEP7=true
    else
      ui_print "    Automatically skipped, cannot be installed     "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [8/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "           • PATCH MIXER_PATHS FILES •             "
    ui_print "                                                   "
    ui_print "  This step reroutes the audio stream to take      "
    ui_print "  the shortest path from the player to your        "
    ui_print "  headphones.                                      "
    ui_print "  Additionally, it improves bass response by       "
    ui_print "  disabling the high pass filter.                  "
    ui_print "                                                   "
    ui_print "  Contains custom audio codec settings for         "
    ui_print "  supported devices, such as:                      "
    ui_print "  - Poco X3 NFC (surya);                           "
    ui_print "  - Poco X3 Pro (vayu);                            "
    ui_print "  - Redmi Note 10 (mojito);                        "
    ui_print "  - Redmi Note 10 Pro (sweet/in);                  "
    ui_print "  - Mi 11 Ultra (star);                            "
    ui_print "    And countless other models                     "
    ui_print "                                                   "
    ui_print "  These changes greatly enhance the stereo         "
    ui_print "  imaging capabilities of said devices by          "
    ui_print "  fine-turning their channel balance, resulting    "
    ui_print "  in a more nuanced sound.                         "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - Install | [VOL-] - skip           "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Install" "Skip"
    [ $? -eq 1 ] && STEP8=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [9/15]                                            "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "           • TWEAK BUILD.PROP FILES •              "
    ui_print "                                                   "
    ui_print "  This step installs a large number of global      "
    ui_print "  tweaks that will significantly improve your      "
    ui_print "  device's audio quality. We strongly advise       "
    ui_print "  our users to install this patchset!              "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - Install | [VOL-] - skip           "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Install" "Skip"
    [ $? -eq 1 ] && STEP9=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [10/15]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "             • IMPROVE BLUETOOTH •                 "
    ui_print "                                                   "
    ui_print "  Improve Bluetooth audio quality and fix          "
    ui_print "  a bug that causes the AAC codec to randomly      "
    ui_print "  switch off at times.                             "
    ui_print "___________________________________________________"
    ui_print "        [VOL+] - Install | [VOL-] - skip           "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Install" "Skip"
    [ $? -eq 1 ] && STEP10=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [11/15]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "            • SWITCH AUDIO OUTPUT •                "
    ui_print "                                                   "
    ui_print "  Switch from DIRECT to DIRECT_PCM output,         "
    ui_print "  which greatly improves sound detail.             "
    ui_print "                                                   "
    ui_print "   WARNING:                                          "
    ui_print "  May cause lack of sound in applications          "
    ui_print "  such as TikTok, YouTube, and many games.         "
    ui_print "                                                   "
    ui_print "___________________________________________________"
    if [ -n "$IOPOLICYS" ] || [ -n "$OUTPUTPOLICYS" ]; then
      ui_print "        [VOL+] - Install | [VOL-] - skip           "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "Install" "Skip"
      [ $? -eq 1 ] && STEP11=true
    else
      ui_print "    Automatically skipped, cannot be installed     "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [12/15]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "       • INSTALL CUSTOM IIR FILTER PRESET •        "
    ui_print "                                                   "
    ui_print "  IIR filters change the system-wide frequency     "
    ui_print "  response curve at the output stage. In other     "
    ui_print "  words, they are a system-wide equalizer.         "
    ui_print "                                                   "
    ui_print "  This custom preset will boost the upper-low      "
    ui_print "  and lower-mid frequencies.                       "
    ui_print "___________________________________________________"
    if [ "$FOUND_IIR" == "true" ]; then
      ui_print "        [VOL+] - Install | [VOL-] - skip           "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "Install" "Skip"
      [ $? -eq 1 ] && STEP12=true
    else
      ui_print "    Automatically skipped, cannot be installed     "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [13/15]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "          • IGNORE ALL AUDIO EFFECTS •             "
    ui_print "                                                   "
    ui_print "  Disable all audio effects on a system level.     "
    ui_print "  This breaks XiaomiParts, Dirac, Dolby, and       "
    ui_print "  other equalizers. Drastically improves audio     "
    ui_print "  clarity for high-quality headphones.             "
    ui_print "                                                   "
    ui_print "   NOTE:                                           "
    ui_print "  This modification will result in a flat          "
    ui_print "  sound signature.                                 "
    ui_print "  Most users are advised to skip this step.        "
    ui_print "                                                   "
    ui_print "  Additional library removal may                   "
    ui_print "  cause issues. It will break VLC player,          "
    ui_print "  and volume control will work differently.        "
    ui_print "___________________________________________________"
    ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
    ui_print "___________________________________________________"
    ui_print " "
    ui_print "   1. Skip (No changes)"
    ui_print "   2. Install"
    ui_print "   3. Additional library removal"
    ui_print " "
    show_menu "[Skip]" "Install" "Additional removal"
    case $? in
    "1") STEP13="false" ;;
    "2") STEP13="true" ;;
    "3") STEP13="ext_rm" ;;
    esac
    ui_print " - [*] Selected: $STEP13"
    ui_print " "

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [14/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "     • INSTALL PERSONALIZED TWEAKS •               "
    ui_print "                                                   "
    ui_print "  This option will further configure your device's "
    ui_print "  audio codec using the tinymix function and       "
    ui_print "  mixer_paths. It will improve audio quality, but  "
    ui_print "  is compatible with a limited number of devices.  "
    if [ $tinymix_support == false ]; then
      ui_print "                                                   "
      ui_print "   WARNING:                                        "
      ui_print "  The parameters are not suitable for your device. "
      ui_print "  Common settings will be used, which may cause    "
      ui_print "  issues.                                          "
    fi
    ui_print "___________________________________________________"
    ui_print "    [VOL+] - Install | [VOL-] - Skip               "
    ui_print "___________________________________________________"
    ui_print " "
    show_menu "Install" "Skip"
    [ $? -eq 1 ] && STEP14=true

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [15/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print "             • CONFIGURE DOLBY ATMOS •             "
    ui_print "                                                   "
    ui_print "  This option will additionally customize your     "
    ui_print "  Dolby if your Dolby is available in the system   "
    ui_print "  (both systemic and non-system/custom), for       "
    ui_print "  better quality of the sound by turning off       "
    ui_print "  the various garbage sounds functions and         "
    ui_print "  mechanisms, such as compressors, audio controls  "
    ui_print "  and so on.                                       "
    ui_print "                                                   "
    ui_print "   NOTE:                                           "
    ui_print "  If item 13 was selected in conjunction with this,"
    ui_print "  Dolby Atmos will continue to work.               "
    ui_print "___________________________________________________"
    if [ -n "$DAXES" ] || [ -n "$DCODECS" ]; then
      ui_print "        [VOL+] - Install | [VOL-] - skip           "
      ui_print "___________________________________________________"
      ui_print " "
      show_menu "Install" "Skip"
      [ $? -eq 1 ] && STEP15=true
    else
      ui_print "    Automatically skipped, cannot be installed     "
      ui_print "___________________________________________________"
    fi

    ui_print " "
    ui_print "___________________________________________________"
    ui_print "                                                   "
    ui_print "                                                   "
    ui_print " [16/16]                                           "
    ui_print "                                                   "
    ui_print "                                                   "
    if [ -n "$OLDACDBS" ]; then
      ui_print "             • REMOVE ACDB FILES •                 "
      ui_print "                                                   "
      ui_print "  This option may disable all restrictions for     "
      ui_print "  audio output via AUX, Bluetooth, and speakers    "
      ui_print "  of the device.                                   "
      ui_print "                                                   "
      ui_print "   DESCRIPTION OF OPTIONS:                         "
      ui_print "  2. Removes restrictions for output via AUX,      "
      ui_print "  Bluetooth, and HDMI, without affecting           "
      ui_print "  General_cal.                                     "
      ui_print "                                                   "
      ui_print "  3. Similar to the second option but also         "
      ui_print "  removes General_cal. Recommended only if         "
      ui_print "  selecting this option does not result in         "
      ui_print "  no sound.                                        "
      ui_print "                                                   "
      ui_print "  4. Similar to the third option but also removes  "
      ui_print "  restrictions on speaker output. Highly unsafe,   "
      ui_print "  may damage speakers at high volume by removing   "
      ui_print "  all low-frequency restrictions.                  "
      ui_print "                                                   "
      ui_print "   WARNING:                                        "
      ui_print "  Agreeing to this option may cause hardware       "
      ui_print "  damage in case of careless usage (e.g., too      "
      ui_print "  high volume), and may also lead to infinite      "
      ui_print "  reboot loops. However, these parameters are      "
      ui_print "  highly effective and greatly influence your      "
      ui_print "  smartphone's sound quality.                      "
      ui_print "  Be careful and remember that we bear no          "
      ui_print "  responsibility for your actions.                 "
      ui_print "___________________________________________________"
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   1. Skip (No changes)"
      ui_print "   2. Basic .acdb file removal"
      ui_print "   3. Basic removal + General_cal removal"
      ui_print "   4. Basic removal + speaker and General_cal"
      ui_print "      restrictions removal"
      ui_print " "
      show_menu "[Skip]" "Basic" "General_cal" "Speaker"
      case $? in
      "1") DELETEACDB="false" ;;
      "2") DELETEACDB="Basic" ;;
      "3") DELETEACDB="General" ;;
      "4") DELETEACDB="Speaker" ;;
      esac
      ui_print " - [*] Selected: $DELETEACDB"
      ui_print ""
    else
      ui_print "        • Install patched ACDB files •             "
      ui_print "                                                   "
      ui_print "  This option will disable the limiters and change "
      ui_print "  the mode of resampler operation in ACDB files    "
      ui_print "                                                   "
      ui_print "   NOTE:                                           "
      ui_print "  On smartphones from BBK, the sound may not be    "
      ui_print "  affected due to certain restrictions             "
      ui_print "___________________________________________________"
      case "$DEVICE" in alioth* | Pong* | marble* | RE5465* | mondrian* | ishtar* | aurora* | REE2B2L1*)
        ui_print "    [VOL+] - Install | [VOL-] - skip             "
        ui_print "___________________________________________________"
        ui_print " "
        show_menu "Install" "Skip"
        [ $? -eq 1 ] && PATCHACDB=true
        ;;
      *)
        ui_print "    Automatically skipped, cannot be installed     "
        ui_print "___________________________________________________"
        ;;
      esac
    fi
    ui_print " "
  fi
  ui_print "================== YOUR SETTINGS =================="
  ui_print "                                                   "
  ui_print "┌──────────────────────────────────────────"
  ui_print "│N │          Settings           │      Values"
  ui_print "├──────────────────────────────────────────"
  ui_print "│1 │ Volume steps                │ ${VOLSTEPS}"
  ui_print "│2 │ Volume level                │ ${VOLMEDIA}"
  ui_print "│3 │ Microphone sensitivity      │ ${VOLMIC}"
  ui_print "│4 │ Bit depth configuration     │ ${BITNES}"
  ui_print "│5 │ Sample rate configuration   │ ${SAMPLERATE}"
  ui_print "│6 │ Turn off sound interference │ ${STEP6}"
  ui_print "│7 │ Patch device_features files │ ${STEP7}"
  ui_print "│8 │ Patch mixer_paths files     │ ${STEP8}"
  ui_print "│9 │ Tweak build.prop files      │ ${STEP9}"
  ui_print "│10│ Improve Bluetooth           │ ${STEP10}"
  ui_print "│11│ Switch audio output         │ ${STEP11}"
  ui_print "│12│ Сustom IIR filter preset    │ ${STEP12}"
  ui_print "│13│ Ignore all audio effects    │ ${STEP13}"
  ui_print "│14│ Personalized tweaks         │ ${STEP14}"
  ui_print "│15│ Configure Dolby Atmos       │ ${STEP15}"
  ui_print "│16│ Modify the ACDB file        │ $([ "$PATCHACDB" != "false" ] && echo "$PATCHACDB" || echo "$DELETEACDB")"
  ui_print "├──────────────────────────────────────────"
  ui_print "│                  Device info"
  ui_print "├──────────────────────────────────────────"
  ui_print "│  Module version       │ $VERSION"
  ui_print "│  Device               │ $DEVICE"
  ui_print "└──────────────────────────────────────────"
  ui_print " "
  ui_print " - Installation started, please wait a few seconds"
  ui_print " "
fi
# Writing settings
mkdir -p "/storage/emulated/0/NLSound" && echo -e "#installer options\n#Below you can see the decoding of the names of the points,\n#or trust the numerical values of the points.\n\n#STEP1=Select volume steps\n#STEP2=Increase media volumes\n#STEP3=Improving microphones sensitivity\n#STEP4=Select audio format (16..float)\n#STEP5=Select sampling rates (96..384000)\n#STEP6=Turn off sound interference\n#STEP7=Patching device_features files\n#STEP8=Other patches in mixer_paths files\n#STEP9=Tweaks for build.prop files\n#STEP10=Improve bluetooth\n#STEP11=Switch audio output (DIRECT -> DIRECT_PCM)\n#STEP12=Install custom preset for iir\n#STEP13=Ignore all audio effects\n#STEP14=Install experimental tweaks for tinymix\n#STEP15=Configure Dolby Atmos\n#PATCHACDB=Install patched ACDB files\n#DELETEACDB=Deleting acdb files\n\nModule version: $VERSION\nDevice: $DEVICE\n\nVOLSTEPS=$VOLSTEPS\nVOLMEDIA=$VOLMEDIA\nVOLMIC=$VOLMIC\nBITNES=$BITNES\nSAMPLERATE=$SAMPLERATE\nSTEP6=$STEP6\nSTEP7=$STEP7\nSTEP8=$STEP8\nSTEP9=$STEP9\nSTEP10=$STEP10\nSTEP11=$STEP11\nSTEP12=$STEP12\nSTEP13=$STEP13\nSTEP14=$STEP14\nSTEP15=$STEP15\nPATCHACDB=$PATCHACDB\nDELETEACDB=$DELETEACDB" >"/storage/emulated/0/NLSound/settings.nls"

case "$SAMPLERATE" in
"44100") RATE="KHZ_44P1" max_samplerate_192="KHZ_44P1" max_samplerate_96="KHZ_44P1" ;;
"48000") RATE="KHZ_48" max_samplerate_192="KHZ_48" max_samplerate_96="KHZ_48" ;;
"96000") RATE="KHZ_96" max_samplerate_192="KHZ_96" max_samplerate_96="KHZ_96" ;;
"192000") RATE="KHZ_192" max_samplerate_192="KHZ_192" max_samplerate_96="KHZ_96" ;;
"384000") RATE="KHZ_384" max_samplerate_192="KHZ_192" max_samplerate_96="KHZ_96" ;;
esac
case "$BITNES" in
"16") bit_width="16" max_bit_width_24="16" FORMAT="S16_LE" max_format_24="S16_LE" ;;
"24") bit_width="24" max_bit_width_24="24" FORMAT="S24_LE" max_format_24="S24_LE" ;;
"32") bit_width="32" max_bit_width_24="24" FORMAT="S32_LE" max_format_24="S24_LE" ;;
"float") bit_width="32" max_bit_width_24="24" FORMAT="S32_LE" max_format_24="S24_LE" ;;
esac
case "$DELETEACDB" in
"Basic") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb") ;;
"General") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb|.*General_cal.acdb|.*Global_cal.acdb") ;;
"Speaker") OLDACDBS=$(echo "$OLDACDBS" | grep -E ".*Headset_cal.acdb|.*Hdmi_cal.acdb|.*Bluetooth_cal.acdb|.*General_cal.acdb|.*Speaker_cal.acdb|.*Global_cal.acdb") ;;
esac
if [ "$STEP15" == "true" ]; then
  LIBS=$(echo "$LIBS" | sed 's|/.*libswdap.*.so||g')
fi
if [ "$STEP13" == "true" ]; then
  LIBS=$(echo "$LIBS" | sed 's|/.*libdynproc.*.so||g' | sed 's|/.*libbundlewrapper.*.so||g')
fi

for OAPIXML in ${APIXMLS}; do
  {
    APIXML="$MODPATH$(echo $OAPIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f "$ORIGDIR$OAPIXML" "$APIXML"
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
    if [ "$STEP6" == "true" ] || [ "$STEP6" == "no_prot" ]; then
      sed -i 's/param key="native_audio_mode" value=".*"/param key="native_audio_mode" value="multiple_mix_dsp"/g' $APIXML
      sed -i 's/param key="hfp_pcm_dev_id" value=".*"/param key="hfp_pcm_dev_id" value="39"/g' $APIXML
      sed -i 's/param key="input_mic_max_count" value=".*"/param key="input_mic_max_count" value="4"/g' $APIXML
      sed -i 's/param key="true_32_bit" value=".*"/param key="true_32_bit" value="true"/g' $APIXML
      sed -i 's/param key="hifi_filter" value=".*"/param key="hifi_filter" value="true"/g' $APIXML
      sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIXML
      if [ "$STEP6" == "no_prot" ]; then
        sed -i 's/param key="config_spk_protection" value=".*"/param key="config_spk_protection" value="false"/g' $APIXML
      fi
    fi
  } &
done

if [ "$STEP6" == "true" ] || [ "$STEP6" == "no_prot" ]; then
  {
    #patching audio_configs.xml
    for OACONFS in ${ACONFS}; do
      ACFG="$MODPATH$(echo $OACONFS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f $ORIGDIR$OACONFS $ACFG
      if [ "$STEP6" == "no_prot" ]; then
        sed -i 's/"spkr_protection" value="true"/"spkr_protection" value="false"/g' $ACFG
      fi
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
      cp_ch -f $ORIGDIR$OMCODECS $MEDIACODECS
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
      cp_ch -f $ORIGDIR$OARESOURCES $RES
      if [ "$STEP6" == "no_prot" ]; then
        sed -i 's/<speaker_protection_enabled>1/<speaker_protection_enabled>0/g' $RES
        sed -i 's/<ras_enabled>1/<ras_enabled>0/g' $RES
      fi
      sed -i 's/<param key="hifi_filter" value="false"/<param key="hifi_filter" value="true"/g' $RES
      sed -i 's/param key="native_audio_mode" value=".*"/param key="native_audio_mode" value="multiple_mix_dsp"/g' $RES
      sed -i 's/param key="oplus_ear_protection_enable" value=".*"/param key="oplus_ear_protection_enable" value="false"/g' $RES
      sed -i 's/<ext_ec_ref_enabled>0/<ext_ec_ref_enabled>1/g' $RES
      sed -i 's/<param lpi_enable="true"/<param lpi_enable="false"/g' $RES
      sed -i 's/param key="oplus_hdr_record" value="false"/param key="oplus_hdr_record" value="true"/g' $RES
      sed -i '/<!--HIFI Filter Headphones-Uncomment this when param key hifi_filter is true/,/-->/{s/^ *<!--\(.*\)$/\1/; s/^\(.*\)-->/\1/; /^ *HIFI Filter Headphones-Uncomment this when param key hifi_filter is true *$/d}' $RES
    done
    #patching microphone_characteristics files
    for OMICXAR in ${MICXARS}; do
      MICXAR="$MODPATH$(echo $OMICXAR | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f "$ORIGDIR$OMICXAR" "$MICXAR"
      sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $MICXAR
    done
  } &
fi

if [ "$STEP7" == "true" ]; then
  {
    for ODEVFEA in ${DEVFEAS}; do
      DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f $ORIGDIR$ODEVFEA $DEVFEA
      sed -i 's/name="support_powersaving_mode" value=true/name="support_powersaving_mode" value=false/g' $DEVFEA
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
      sed -i 's/<bool name="support_powersaving_mode">false/<bool name="support_powersaving_mode">true/g' $DEVFEA
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
      if [ "$STEP13" == "true" ] && [ "$STEP15" == "false" ]; then
        sed -i 's/name="support_dolby" value=true/name="support_dolby" value=false/g' $DEVFEA
        sed -i 's/<bool name="support_dolby">true/<bool name="support_dolby">false/g' $DEVFEA
      else
        sed -i 's/name="support_dolby" value=false/name="support_dolby" value=true/g' $DEVFEA
        sed -i 's/<bool name="support_dolby">false/<bool name="support_dolby">true/g' $DEVFEA
      fi
    done
    for ODEVFEANEW in ${DEVFEASNEW}; do
      DEVFEANEW="$MODPATH$(echo $ODEVFEANEW | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f $ORIGDIR$ODEVFEANEW $DEVFEANEW
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
vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
tunnel.audiovideo.decode=true
tunnel.decode=true
qc.tunnel.audio.encode=true
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
persist.audio.hifi.int_codec=true
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
persist.audio.lowlatency.rec=true
persist.vendor.audio.record.ull.support=true
vendor.usb.analog_audioacc_disabled=false
vendor.audio.enable.cirrus.speaker=true
vendor.audio.trace.enable=true
vendor.audio.powerop=true
vendor.audio.read.wsatz.type=true
vendor.audio.powerhal.power.ul=true
vendor.audio.powerhal.power.dl=true
vendor.audio.hal.boot.timeout.ms=5000
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
vendor.audio.spkr_prot.tx.sampling_rate=96000
vendor.audio.spkr_prot.rx.sampling_rate=96000
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
vendor.media.support.mvc=true
ro.audio.resampler.psd.enable_at_samplerate=96000
ro.audio.resampler.psd.halflength=240
ro.audio.resampler.psd.stopband=20
ro.audio.resampler.psd.cutoff_percent=100
ro.audio.resampler.psd.tbwcheat=110
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
    if [ "$STEP6" == "no_prot" ]; then
      echo -e "\n
persist.vendor.audio.speaker.prot.enable=false
vendor.audio.feature.spkr_prot.enable=false
persist.config.speaker_protect_enabled=0" >>$PROP
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
config.disable_bluetooth=false
persist.bluetooth.a2dp_aac_abr.enable=false
persist.bluetooth.a2dp_offload.aidl_flag=aidl
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
persist.vendor.bluetooth.leaudio_mode=off
persist.vendor.bluetooth.prefferedrole=master
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
persist.vendor.bt.splita2dp.44_1_war=true
persist.vendor.btstack.enable.lpa=false
persist.vendor.qcom.bluetooth.a2dp_mcast_test.enabled=false
persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true
persist.vendor.qcom.bluetooth.aac_vbr_ctl.enabled=true
persist.vendor.qcom.bluetooth.aidl_hal=true
persist.vendor.qcom.bluetooth.aptxadaptiver2_1_support=true
persist.vendor.qcom.bluetooth.dualmode_transport_support=true
persist.vendor.qcom.bluetooth.enable.swb=true
persist.vendor.qcom.bluetooth.enable.swbpm=true
persist.vendor.qcom.bluetooth.lossless_aptx_adaptive_le.enabled=true
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
ro.vendor.audio.btsamplerate.adaptive=true
ro.vendor.audio.screenrecorder.bothrecord=0
ro.vendor.bluetooth.csip_qti=true
vendor.bluetooth.ldac.abr=false
vendor.media.audiohal.btwbs=true
audio.effect.a2dp.enable=1
vendor.audio.effect.a2dp.enable=1
" >>$PROP
  } &
fi

if [ "$STEP13" == "true" ] || [ "$STEP13" == "ext_rm" ]; then
  {
    for OAEFFECTCONF in ${AEFFECTCONFS}; do
      AEFFECTCONF="$MODPATH$(echo $OAEFFECTCONF | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f "$ORIGDIR$OAEFFECTCONF" "$AEFFECTCONF"
      sed -i 's/\/lib\/soundfx/\/lib64\/soundfx/g' "$AEFFECTCONF"
    done
    for OLIB in ${LIBS}; do
      LIB="$MODPATH$(echo $OLIB | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      mkdir -p "$(dirname "$LIB")"
      touch "$LIB"
    done
    if [ "$STEP15" != "true" ]; then
      for OAPP in ${APPS}; do
        APP="$MODPATH$(echo $OAPP | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
        mkdir -p "$(dirname "$APP")"
        touch "$APP"
      done
      echo -e "\n
ro.product.dolby_vision.enabled=0
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
    fi
    echo -e "\n
# Disable all effects by NLSound Team
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
persist.sys.phh.disable_audio_effects=1
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
persist.audio.disable_reverb=true
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
persist.audio.faux_effects=false" >>$PROP
  } &
fi

#patching audio_io_policy file
for OIOPOLICY in ${IOPOLICYS}; do
  {
    IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OIOPOLICY $IOPOLICY

    if [ "$STEP11" == "true" ]; then
      # Patching direct_pcm 24 and 32 bit routes, ignore 16-bit route only if DIRECT_PCM is not already present
      sed -i '/direct_pcm_24/,/compress_passthrough/{/AUDIO_OUTPUT_FLAG_DIRECT_PCM/!s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/}' "$IOPOLICY"
      sed -i '/compress_offload_24/,/inputs/{/AUDIO_OUTPUT_FLAG_DIRECT_PCM/!s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/}' "$IOPOLICY"
    fi

    if [ "$BITNES" == "24" ]; then
      # Patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_24_BIT_PACKED/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 24/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $IOPOLICY
    fi

    if [ "$BITNES" == "32" ]; then
      # Patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_32_BIT/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 32/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $IOPOLICY
    fi

    if [ "$BITNES" == "float" ]; then
      # Patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_FLOAT/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 32/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $IOPOLICY
    fi
  } &
done

#patching audio_output_policy file
for OOUTPUTPOLICY in ${OUTPUTPOLICYS}; do
  {
    OUTPUTPOLICY="$MODPATH$(echo $OOUTPUTPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OOUTPUTPOLICY $OUTPUTPOLICY

    if [ "$STEP11" == "true" ]; then
      # Patching direct_pcm 24 and 32 bit routes, ignore 16-bit route only if DIRECT_PCM is not already present
      sed -i '/direct_pcm_24/,/compress_passthrough/{/AUDIO_OUTPUT_FLAG_DIRECT_PCM/!s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/}' "$OUTPUTPOLICY"
      sed -i '/compress_offload_24/,/inputs/{/AUDIO_OUTPUT_FLAG_DIRECT_PCM/!s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/}' "$OUTPUTPOLICY"
    fi

    if [ "$BITNES" == "24" ]; then
      # Patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_24_BIT_PACKED/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 24/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $OUTPUTPOLICY
    fi

    if [ "$BITNES" == "32" ]; then
      # Patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_32_BIT/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 32/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $OUTPUTPOLICY
    fi

    if [ "$BITNES" == "float" ]; then
      # Patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_FLOAT/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 32/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $OUTPUTPOLICY
    fi
  } &
done

#patching audio_policy_configuration
for OAUDIOPOLICY in ${AUDIOPOLICYS}; do
  {
    AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OAUDIOPOLICY $AUDIOPOLICY
    if [ "$STEP6" == "true" ] || [ "$STEP6" == "no_prot" ]; then
      sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
    fi
  } &
done

for OMIX in ${MPATHS}; do
  {
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OMIX $MIX
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

    if [ "$STEP6" == "true" ] || [ "$STEP6" == "no_prot" ]; then
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
      if [ "$HIFI" == "true" ]; then
        sed -i 's/\(name="RX[0-9] HPF cut off" value="\)[^"]*"/\1CF_NEG_3DB_4HZ"/g' $MIX
        sed -i 's/\(name="TX[0-9] HPF cut off" value="\)[^"]*"/\1CF_NEG_3DB_4HZ"/g' $MIX
        sed -i 's/name="RX_HPH_PWR_MODE" value=".*"/name="RX_HPH_PWR_MODE" value="LOHIFI"/g' $MIX
        sed -i 's/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="CLS_H_HIFI"/g' $MIX
      else
        sed -i 's/\(name="RX[0-9] HPF cut off" value="\)[^"]*"/\1MIN_3DB_4Hz"/g' $MIX
        sed -i 's/\(name="TX[0-9] HPF cut off" value="\)[^"]*"/\1MIN_3DB_4Hz"/g' $MIX
        sed -i 's/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="HD2"/g' $MIX
        sed -i 's/name="RX HPH HD2 Mode" value=".*"/name="RX HPH HD2 Mode" value="On"/g' $MIX
      fi

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
      sed -i 's/name="EC Reference Channels" value=".*"/name="EC Reference Channels" value="Two"/g' $MIX
      sed -i 's/name="DS2 OnOff" value=".*"/name="DS2 OnOff" value="1"/g' $MIX
      if ! grep -q '<path name="hph-highquality-mode">' "$MIX"; then
        sed -i '/<\/mixer>/i\
    <path name="hph-highquality-mode">\
    </path>' "$MIX"
      fi

      if [ "$BITNES" != "false" ]; then
        sed -i 's/name="SLIM_7_RX Format" value=".*"/name="SLIM_7_RX Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="SLIMBUS_7_RX Format" value=".*"/name="SLIMBUS_7_RX Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="SLIM7_RX ADM Format" value=".*"/name="SLIM7_RX ADM Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="SLIMBUS7_RX ADM Format" value=".*"/name="SLIMBUS7_RX ADM Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="ASM Bit Width" value=".*"/name="ASM Bit Width" value="'$max_bit_width_24'"/g' $MIX
        sed -i 's/name="AFE Input Bit Format" value=".*"/name="AFE Input Bit Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="EC Reference Bit Format" value=".*"/name="EC Reference Bit Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="Display Port1 RX Bit Format" value=".*"/name="Display Port1 RX Bit Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="Display Port RX Bit Format" value=".*"/name="Display Port RX Bit Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="QUIN_MI2S_TX Format" value=".*"/name="QUIN_MI2S_TX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="QUIN_MI2S_RX Format" value=".*"/name="QUIN_MI2S_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="QUAT_MI2S_TX Format" value=".*"/name="QUAT_MI2S_TX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="QUAT_MI2S_RX Format" value=".*"/name="QUAT_MI2S_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="PRIM_MI2S_TX Format" value=".*"/name="PRIM_MI2S_TX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="PRIM_MI2S_RX Format" value=".*"/name="PRIM_MI2S_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_0 Format" value=".*"/name="RX_CDC_DMA_RX_0 Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_1 Format" value=".*"/name="RX_CDC_DMA_RX_1 Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_2 Format" value=".*"/name="RX_CDC_DMA_RX_2 Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_3 Format" value=".*"/name="RX_CDC_DMA_RX_3 Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_5 Format" value=".*"/name="RX_CDC_DMA_RX_5 Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="SEC_MI2S_RX Format" value=".*"/name="SEC_MI2S_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SEC_MI2S_TX Format" value=".*"/name="SEC_MI2S_TX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SEN_MI2S_TX Format" value=".*"/name="SEN_MI2S_TX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SEN_MI2S_RX Format" value=".*"/name="SEN_MI2S_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SLIM_6_RX Format" value=".*"/name="SLIM_6_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SLIM_5_RX Format" value=".*"/name="SLIM_5_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SLIM_4_TX Format" value=".*"/name="SLIM_4_TX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SLIM_2_RX Format" value=".*"/name="SLIM_2_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SLIM_0_TX Format" value=".*"/name="SLIM_0_TX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="SLIM_0_RX Format" value=".*"/name="SLIM_0_RX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_TX_2 Format" value=".*"/name="WSA_CDC_DMA_TX_2 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_TX_1 Format" value=".*"/name="WSA_CDC_DMA_TX_1 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_RX_1 Format" value=".*"/name="WSA_CDC_DMA_RX_1 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_RX_0 Format" value=".*"/name="WSA_CDC_DMA_RX_0 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="VA_CDC_DMA_TX_2 Format" value=".*"/name="VA_CDC_DMA_TX_2 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="VA_CDC_DMA_TX_1 Format" value=".*"/name="VA_CDC_DMA_TX_1 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="VA_CDC_DMA_TX_0 Format" value=".*"/name="VA_CDC_DMA_TX_0 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="USB_AUDIO_TX Format" value=".*"/name="USB_AUDIO_TX Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="USB_AUDIO_RX Format" value=".*"/name="USB_AUDIO_RX Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="TX_CDC_DMA_TX_4 Format" value=".*"/name="TX_CDC_DMA_TX_4 Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="TX_CDC_DMA_TX_3 Format" value=".*"/name="TX_CDC_DMA_TX_3 Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="TX_CDC_DMA_TX_0 Format" value=".*"/name="TX_CDC_DMA_TX_0 Format" value="'$FORMAT'"/g' $MIX
        sed -i 's/name="TERT_TDM_RX_1 Format" value=".*"/name="TERT_TDM_RX_1 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="TERT_TDM_RX_0 Format" value=".*"/name="TERT_TDM_RX_0 Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="TERT_MI2S_TX Format" value=".*"/name="TERT_MI2S_TX Format" value="'$max_format_24'"/g' $MIX
        sed -i 's/name="TERT_MI2S_RX Format" value=".*"/name="TERT_MI2S_RX Format" value="'$max_format_24'"/g' $MIX
      fi

      if [ "$SAMPLERATE" != "false" ]; then
        sed -i 's/name="SEN_MI2S_TX SampleRate" value=".*"/name="SEN_MI2S_TX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="SEN_MI2S_RX SampleRate" value=".*"/name="SEN_MI2S_RX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="SEC_MI2S_TX SampleRate" value=".*"/name="SEC_MI2S_TX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="SEC_MI2S_RX SampleRate" value=".*"/name="SEC_MI2S_RX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_5 SampleRate" value=".*"/name="RX_CDC_DMA_RX_5 SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_3 SampleRate" value=".*"/name="RX_CDC_DMA_RX_3 SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_2 SampleRate" value=".*"/name="RX_CDC_DMA_RX_2 SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_1 SampleRate" value=".*"/name="RX_CDC_DMA_RX_1 SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="RX_CDC_DMA_RX_0 SampleRate" value=".*"/name="RX_CDC_DMA_RX_0 SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="SLIM_7_RX SampleRate" value=".*"/name="SLIM_7_RX SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="SLIMBUS_7_RX SampleRate" value=".*"/name="SLIMBUS_7_RX SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="SLIM7_RX ADM SampleRate" value=".*"/name="SLIM7_RX ADM SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="SLIMBUS7_RX ADM SampleRate" value=".*"/name="SLIMBUS7_RX ADM SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="BT SampleRate" value=".*"/name="BT SampleRate" value="'$max_samplerate_96'"/g' $MIX
        sed -i 's/name="BT SampleRate TX" value=".*"/name="BT SampleRate TX" value="'$max_samplerate_96'"/g' $MIX
        sed -i 's/name="BT SampleRate RX" value=".*"/name="BT SampleRate RX" value="'$max_samplerate_96'"/g' $MIX
        sed -i 's/name="QUIN_MI2S_TX SampleRate" value=".*"/name="QUIN_MI2S_TX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="QUIN_MI2S_RX SampleRate" value=".*"/name="QUIN_MI2S_RX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="QUAT_MI2S_TX SampleRate" value=".*"/name="QUAT_MI2S_TX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="QUAT_MI2S_RX SampleRate" value=".*"/name="QUAT_MI2S_RX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="PRIM_MI2S_TX SampleRate" value=".*"/name="PRIM_MI2S_TX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="PRIM_MI2S_RX SampleRate" value=".*"/name="PRIM_MI2S_RX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_TX_2 SampleRate" value=".*"/name="WSA_CDC_DMA_TX_2 SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_TX_1 SampleRate" value=".*"/name="WSA_CDC_DMA_TX_1 SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_TX_0 SampleRate" value=".*"/name="WSA_CDC_DMA_TX_0 SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_RX_1 SampleRate" value=".*"/name="WSA_CDC_DMA_RX_1 SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="WSA_CDC_DMA_RX_0 SampleRate" value=".*"/name="WSA_CDC_DMA_RX_0 SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="VA_CDC_DMA_TX_2 SampleRate" value=".*"/name="VA_CDC_DMA_TX_2 SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="VA_CDC_DMA_TX_1 SampleRate" value=".*"/name="VA_CDC_DMA_TX_1 SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="VA_CDC_DMA_TX_0 SampleRate" value=".*"/name="VA_CDC_DMA_TX_0 SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="USB_AUDIO_TX SampleRate" value=".*"/name="USB_AUDIO_TX SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="USB_AUDIO_RX SampleRate" value=".*"/name="USB_AUDIO_RX SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="TX_CDC_DMA_TX_4 SampleRate" value=".*"/name="TX_CDC_DMA_TX_4 SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="TX_CDC_DMA_TX_3 SampleRate" value=".*"/name="TX_CDC_DMA_TX_3 SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="TX_CDC_DMA_TX_0 SampleRate" value=".*"/name="TX_CDC_DMA_TX_0 SampleRate" value="'$RATE'"/g' $MIX
        sed -i 's/name="TERT_MI2S_TX SampleRate" value=".*"/name="TERT_MI2S_TX SampleRate" value="'$max_samplerate_192'"/g' $MIX
        sed -i 's/name="TERT_MI2S_RX SampleRate" value=".*"/name="TERT_MI2S_RX SampleRate" value="'$max_samplerate_192'"/g' $MIX
      fi

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
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_HIFI
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
tinymix_new set "PCM Source" ASP
' >>$MODPATH/service.
      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$max_format_24'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$max_format_24'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "USB_AUDIO_TX Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "TX_CDC_DMA_TX_3 Format" '$FORMAT'
tinymix_new set "TX_CDC_DMA_TX_4 Format" '$FORMAT'
tinymix_new set "TERT_MI2S_RX Format" '$FORMAT'
tinymix_new set "TERT_MI2S_TX Format" '$FORMAT'
' >>$MODPATH/service.
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$max_samplerate_192'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$max_samplerate_192'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$max_samplerate_192'
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "TX_CDC_DMA_TX_3 SampleRate" '$RATE'
tinymix_new set "TX_CDC_DMA_TX_4 SampleRate" '$RATE'
tinymix_new set "TERT_MI2S_RX SampleRate" '$RATE'
tinymix_new set "TERT_MI2S_TX SampleRate" '$RATE' 
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
' >>$MODPATH/service
      fi
      ;;
    esac

    # [ "$POCOF4GT", "$ONEPLUS9R", "$ONEPLUS9Pro" ]
    case "$DEVICE" in ingres* | OnePlus9R* | OnePlus9Pro*)
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
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_samplerate_192'
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "TERT_MI2S_TX SampleRate" '$max_samplerate_192' 
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$POCOX3Pro" ]
    case "$DEVICE" in vayu*)
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
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_samplerate_192'
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "TERT_MI2S_TX SampleRate" '$max_samplerate_192'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$MI13U", "$MI14U" ]
    case "$DEVICE" in ishtar* | aurora*)
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
tinymix_new set "VA_CDC_DMA_TX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "VA_CDC_DMA_TX_1 SampleRate" '$max_samplerate_192'
tinymix_new set "VA_CDC_DMA_TX_2 SampleRate" '$max_samplerate_192'
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "VA_CDC_DMA_TX_0 Format" '$max_format_24'
tinymix_new set "VA_CDC_DMA_TX_1 Format" '$max_format_24'
tinymix_new set "VA_CDC_DMA_TX_2 Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$R12P+" ]
    case "$DEVICE" in RE5C82L1* | RE5C3B*)
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

    # [ "$POCOX3" ]
    case "$DEVICE" in surya*)
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
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
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
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_samplerate_192'
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
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_samplerate_192'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$S22U" ]
    case "$DEVICE" in b0q*)
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
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_samplerate_192'
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "TERT_MI2S_TX SampleRate" '$max_samplerate_192'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$POCOF5" ]
    case "$DEVICE" in marble*)
      echo -e '\n
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "RX HPH Mode" CLS_H_LOHIFI
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX_HPH HD2 Mode" ON
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "TX0 MODE" ADC_HIFI
tinymix_new set "TX1 MODE" ADC_HIFI
tinymix_new set "TX2 MODE" ADC_HIFI
tinymix_new set "TX3 MODE" ADC_HIFI
tinymix_new set "HPH Idle Detect" ON
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "AUX_HPF Enable" 0
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$RN9PRO", "$RN9S", "$POCOM2P", "$RN9PMAX" ]
    case "$DEVICE" in joyeuse* | curtana* | gram* | excalibur*)
      echo -e '\n
tinymix_new set "HiFi Filter" 1
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "HPHL Volume" 20
tinymix_new set "HPHR Volume" 20
tinymix_new set "Amp Output Level" 22
tinymix_new set "TAS25XX_ALGO_BYPASS" TRUE
tinymix_new set "TAS2562 IVSENSE ENABLE" On
tinymix_new set "EC Reference Channels" Two
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
tinymix_new set "TERT_MI2S_RX Format" '$max_format_24'
tinymix_new set "SEN_MI2S_RX Format" '$max_format_24'
tinymix_new set "QUIN_MI2S_RX Format" '$max_format_24'
tinymix_new set "QUAT_MI2S_RX Format" '$max_format_24'
tinymix_new set "SEC_MI2S_RX Format" '$max_format_24'
tinymix_new set "PRIM_MI2S_RX Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_3 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_samplerate_192'
tinymix_new set "Display Port RX SampleRate" '$max_samplerate_192'
tinymix_new set "Display Port1 RX SampleRate" '$max_samplerate_192'
tinymix_new set "SEN_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "QUIN_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "QUAT_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "SEC_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "PRIM_MI2S_RX SampleRate" '$max_samplerate_192'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$PIXEL6a", "$PIXEL6", "$PIXEL6Pro", "$PIXEL7", "$PIXEL7Pro" ]
    case "$DEVICE" in bluejay* | oriel* | raven* | cheetah* | panther*)
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
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
' >>$MODPATH/service.sh
      fi
      ;;
    esac

    # [ "$OP12"]
    case "$DEVICE" in OP595DL1*)
      echo -e '\n
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "AUX_HPF Enable" 0
tinymix_new set "HPH Idle Detect" ON
tinymix_new set "RX HPH Mode" CLS_H_HIFI
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
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

    if [ $tinymix_support == false ]; then
      echo -e '\n
tinymix_new set "DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "DEC3 MODE" ADC_HIGH_PERF
tinymix_new set "DEC4 MODE" ADC_HIGH_PERF
tinymix_new set "DEC5 MODE" ADC_HIGH_PERF
tinymix_new set "DEC6 MODE" ADC_HIGH_PERF
tinymix_new set "DEC7 MODE" ADC_HIGH_PERF
tinymix_new set "DS2 OnOff" 1
tinymix_new set "EC Reference Channels" Two
tinymix_new set "HDR12 MUX" HDR12
tinymix_new set "HDR34 MUX" HDR34
tinymix_new set "HiFi Filter" 1
tinymix_new set "HPH Idle Detect" ON
tinymix_new set "LPI Enable" 0
tinymix_new set "PCM Source" DSP
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
tinymix_new set "RCV PCM Source" DSP
tinymix_new set "RX HPH Mode" CLS_H_LOHIFI
tinymix_new set "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix_new set "RX_HPH_PWR_MODE" LOHIFI
tinymix_new set "RX_Softclip Enable" 1
tinymix_new set "Set Custom Stereo OnOff" 1
tinymix_new set "TERT_MI2S_TX LSM Function" AUDIO
tinymix_new set "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix_new set "TERT_TDM_RX_1 Header Type" Entertainment
tinymix_new set "TERT_TDM_TX_0 LSM Function" AUDIO
tinymix_new set "TX0 MODE" ADC_LO_HIF
tinymix_new set "TX1 MODE" ADC_LO_HIF
tinymix_new set "TX2 MODE" ADC_LO_HIF
tinymix_new set "TX3 MODE" ADC_LO_HIF
tinymix_new set "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix_new set "VA_DEC3 MODE" ADC_HIGH_PERF
' >>$MODPATH/service.sh

      if [ "$BITNES" != "false" ]; then
        echo -e '\n
tinymix_new set "QUIN_MI2S_RX Format" '$max_format_24'
tinymix_new set "Display Port RX Bit Format" '$max_format_24'
tinymix_new set "Display Port1 RX Bit Format" '$max_format_24'
tinymix_new set "EC Reference Bit Format" '$max_format_24'
tinymix_new set "PRIM_MI2S_RX Format" '$max_format_24'
tinymix_new set "ASM Bit Width" '$max_bit_width_24'
tinymix_new set "QUAT_MI2S_RX Format" '$max_format_24'
tinymix_new set "AFE Input Bit Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_0 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_1 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_2 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_3 Format" '$FORMAT'
tinymix_new set "RX_CDC_DMA_RX_5 Format" '$FORMAT'
tinymix_new set "TERT_TDM_RX_1 Format" '$max_format_24'
tinymix_new set "SLIM_0_RX Format" '$max_format_24'
tinymix_new set "SLIM_2_RX Format" '$max_format_24'
tinymix_new set "SLIM_5_RX Format" '$max_format_24'
tinymix_new set "SLIM_6_RX Format" '$max_format_24'
tinymix_new set "TERT_MI2S_RX Format" '$max_format_24'
tinymix_new set "SEC_MI2S_RX Format" '$max_format_24'
tinymix_new set "SEN_MI2S_RX Format" '$max_format_24'
tinymix_new set "TERT_TDM_RX_0 Format" '$max_format_24'
tinymix_new set "USB_AUDIO_RX Format" '$FORMAT'
tinymix_new set "WSA_CDC_DMA_RX_0 Format" '$max_format_24'
tinymix_new set "WSA_CDC_DMA_RX_1 Format" '$max_format_24'
' >>$MODPATH/service.sh
      fi
      if [ "$SAMPLERATE" != "false" ]; then
        echo -e '\n
tinymix_new set "BT SampleRate RX" '$max_samplerate_96'
tinymix_new set "BT SampleRate TX" '$max_samplerate_96'
tinymix_new set "BT SampleRate" '$max_samplerate_96'
tinymix_new set "PRIM_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "QUAT_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "QUIN_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "RX_CDC_DMA_RX_0 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_1 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_2 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_3 SampleRate" '$RATE'
tinymix_new set "RX_CDC_DMA_RX_5 SampleRate" '$RATE'
tinymix_new set "TERT_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "SEC_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "SEN_MI2S_RX SampleRate" '$max_samplerate_192'
tinymix_new set "USB_AUDIO_RX SampleRate" '$RATE'
tinymix_new set "USB_AUDIO_TX SampleRate" '$RATE'
tinymix_new set "WSA_CDC_DMA_RX_0 SampleRate" '$max_samplerate_192'
tinymix_new set "WSA_CDC_DMA_RX_1 SampleRate" '$max_samplerate_192'
' >>$MODPATH/service.sh
      fi
    fi
    if [ "$VOLMEDIA" != "false" ]; then
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
    fi

    echo -e '\nkill $(pidof audioserver)' >>$MODPATH/service.sh
  } &
fi

#patching dolby anus and dolby media codecs files
if [ "$STEP15" == "true" ]; then
  {
    for ODCODECS in ${DCODECS}; do
      DOLBYCODECS="$MODPATH$(echo $ODCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f $ORIGDIR$ODCODECS $DOLBYCODECS
      sed -i 's/name="sample-rate" ranges=".*"/name="sample-rate" ranges="44100,48000"/g' $DOLBYCODECS
      sed -i 's/name="bitrate" ranges=".*"/name="bitrate" ranges="44100-6144000"/g' $DOLBYCODECS
    done
    for OADAXES in ${DAXES}; do
      DAX="$MODPATH$(echo $OADAXES | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f $ORIGDIR$OADAXES $DAX
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
ro.vendor.audio.dolby.vision.support=true
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
if [ "$STEP14" == "true" ]; then
  {
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
ui_print " - All done! With love, NLSound Team. - "
ui_print " "
