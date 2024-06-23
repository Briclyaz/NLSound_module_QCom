#!/bin/bash
MODID="NLSound"
MIRRORDIR="/data/local/tmp/NLSound"
OTHERTMPDIR="/dev/NLSound"
SETTINGS=$MODPATH/settings.nls
RESTORE_SETTINGS=/data/adb/modules/NLSound/settings.nls
SERVICE=$MODPATH/service.sh
PROP=$MODPATH/system.prop

LANG=$(settings get system system_locales)
DEVICE=$(getprop ro.product.vendor.device)
PROCESSOR=$(getprop ro.board.platform)
AUDIOCARD=$(echo "$(cat /proc/asound/cards)" | awk -F'[- ]' '{print $5}')
if [[ $AUDIOCARD =~ ^...$ ]]; then
  AUDIOCARD=$(echo "$(cat /proc/asound/cards)" | awk -F'[- ]' '{print $4}')
fi

all_files=$(find /system /vendor /system_ext /mi_ext /product /odm /my_product -type f \
  -name "audio_configs*.xml" -o \
  -name "$DEVICE.xml" -o \
  -name "DeviceFeatures.xml" -o \
  -name "audio_policy_configuration*.xml" -o \
  -name "media_codecs_c2_audio.xml" -o \
  -name "media_codecs_google_audio.xml" -o \
  -name "media_codecs_google_c2_audio.xml" -o \
  -name "audio_io_policy.conf" -o \
  -name "audio_output_policy.conf" -o \
  -name "resourcemanager_${AUDIOCARD}_*.xml" -o \
  -name "dax-*.xml" -o \
  -name "mixer_paths*.xml" -o \
  -name "mixer_paths_${AUDIOCARD}_*.xml" -o \
  -name "audio_platform_info*.xml")

all_vendor_AUDIOCARD_files=$(find /vendor/etc/audio/*${AUDIOCARD}* -type f \
  -name "mixer_paths*.xml" -o \
  -name "mixer_paths_overlay*.xml" -o \
  -name "audio_platform_info*.xml")

all_vendor_audio_files=$(find /vendor/etc/audio -type f \
  -name "mixer_paths*.xml" -o \
  -name "audio_platform_*.xml")

# [ "$TG2", "$SD662", "$SD665", "$SD670", "$SD710", "$SD720G", "$SD730G", "$SD765G", "$SD820", "$SD835", "$SD845", "$SD855", "$SD865", "$SD888", "$SM6375", "$SM8450", "$SM8550", "$SM8650" ]
case "$PROCESSOR" in "gs201" | "bengal" | "trinket" | "sdm670" | "sdm710" | "atoll" | "sm6150" | "lito" | "msm8996" | "msm8998" | "sdm845" | "msmnile" | "kona" | "lahaina" | "holi" | "taro" | "kalama" | "pineapple")
  HIFI=true
  ui_print " "
  ui_print " - Device with support Hi-Fi detected! -"
  ui_print " "
  ;;
*)
  HIFI=false
  ui_print " "
  ui_print " - Device without support Hi-Fi detected! -"
  ui_print " "
  ;;
esac

ACONFS=$(echo "$all_files" | grep "audio_configs.*.xml")
DEVFEAS=$(echo "$all_files" | grep "$DEVICE.xml")
DEVFEASNEW=$(echo "$all_files" | grep "DeviceFeatures.xml")
AUDIOPOLICYS=$(echo "$all_files" | grep "audio_policy_configuration.*.xml")
MCODECS=$(echo "$all_files" | grep -E "media_codecs_c2_audio.xml|media_codecs_google_audio.xml|media_codecs_google_c2_audio.xml")
IOPOLICYS=$(echo "$all_files" | grep "audio_io_policy.conf")
OUTPUTPOLICYS=$(echo "$all_files" | grep "audio_output_policy.conf")
RESOURCES=$(echo "$all_files" | grep "resourcemanager_${AUDIOCARD}_.*.xml")
DAXES=$(echo "$all_files" | grep "dax-.*.xml")

RAPIDMIX=$(echo "$all_vendor_audio_files" | grep "mixer_paths.*.xml")
if [[ -z "$RAPIDMIX" ]]; then
  MPATHS=$(echo "$all_files" | grep "mixer_paths.*.xml")
else
  DPATHS=$(echo "$all_files" | grep "mixer_paths_${AUDIOCARD}_.*.xml")
  OMPATHS=$(echo "$all_vendor_AUDIOCARD_files" | grep "mixer_paths_overlay.*.xml")
  MPATHS="$DPATHS $OMPATHS"
  if [[ -z "$DPATHS" ]]; then
    MPATHS=$(echo "$all_vendor_AUDIOCARD_files" | grep "mixer_paths.*.xml")
  fi
fi

RAPIDPLAT=$(echo "$all_vendor_audio_files" | grep "audio_platform_.*.xml")
if [[ -z "$RAPIDPLAT" ]]; then
  APIXMLS=$(echo "$all_files" | grep "audio_platform_info.*.xml")
else
  APIXMLS=$(echo "$all_vendor_AUDIOCARD_files" | grep "audio_platform_info.*.xml")
fi

mkdir -p $MODPATH/tools
cp_ch $MODPATH/common/addon/External-Tools/tools/$ARCH32/\* $MODPATH/tools/.

VOLSTEPS=Skip
VOLMEDIA=Skip
VOLMIC=Skip
BITNES=Skip
SAMPLERATE=Skip
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

#auto-translate for configurator
continue_script=true
if [[ "$LANG" =~ "en-RU" ]] || [[ "$LANG" =~ "ru-" ]]; then
  if [ -f "$RESTORE_SETTINGS" ]; then
    ui_print " "
    ui_print "***************************************************"
    ui_print "*                                                 *"
    ui_print "*       • ПРЕДЫДУЩИЕ НАСТРОЙКИ ОБНАРУЖЕНЫ •       *"
    ui_print "*                                                 *"
    ui_print "*  Вы можете установить такие же настройки, что   *"
    ui_print "*  и в прошлый раз.                               *"
    ui_print "*                                                 *"
    ui_print "*   ЗАМЕТКА:                                      *"
    ui_print "*  При переходе с одной версии модуля на другую   *"
    ui_print "*  могут появиться другие пункты, они будут       *"
    ui_print "*  пропущены, т.к не были записаны ранее.         *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
    ui_print "***************************************************"
    ui_print " "
    if chooseport 60; then
      continue_script=false
      old_modpath=$MODPATH
      source "$RESTORE_SETTINGS"
      MODPATH=$old_modpath
      export SAMPLERATE BITNES VOLMIC VOLMEDIA VOLSTEPS STEP6 STEP7 STEP8 STEP9 STEP10 STEP11 STEP12 STEP13 STEP14 STEP15 STEP16
      (
        sed -i 's/VOLSTEPS=skip/VOLSTEPS='$VOLSTEPS'/g' $SETTINGS
        sed -i 's/VOLMEDIA=skip/VOLMEDIA='$VOLMEDIA'/g' $SETTINGS
        sed -i 's/VOLMIC=skip/VOLMIC='$VOLMIC'/g' $SETTINGS
        sed -i 's/BITNES=skip/BITNES='$BITNES'/g' $SETTINGS
        sed -i 's/SAMPLERATE=skip/SAMPLERATE='$SAMPLERATE'/g' $SETTINGS
        sed -i "s/STEP6=false/STEP6=$STEP6/g" "$SETTINGS"
        sed -i "s/STEP7=false/STEP7=$STEP7/g" "$SETTINGS"
        sed -i "s/STEP8=false/STEP8=$STEP8/g" "$SETTINGS"
        sed -i "s/STEP9=false/STEP9=$STEP9/g" "$SETTINGS"
        sed -i "s/STEP10=false/STEP10=$STEP10/g" "$SETTINGS"
        sed -i "s/STEP11=false/STEP11=$STEP11/g" "$SETTINGS"
        sed -i "s/STEP12=false/STEP12=$STEP12/g" "$SETTINGS"
        sed -i "s/STEP13=false/STEP13=$STEP13/g" "$SETTINGS"
        sed -i "s/STEP14=false/STEP14=$STEP14/g" "$SETTINGS"
        sed -i "s/STEP15=false/STEP15=$STEP15/g" "$SETTINGS"
        sed -i "s/STEP16=false/STEP16=$STEP16/g" "$SETTINGS"
      ) &
    else
      ui_print " - Восстановление предыдущих настроек пропущено"
      ui_print " "
      sleep 0.3
    fi
  fi
  if [ $continue_script == true ]; then
    ui_print " - Настрой меня, пожалуйста! >.< - "
    ui_print " "
    ui_print "***************************************************"
    ui_print "* [1/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*     • ВЫБЕРИТЕ КОЛИЧЕСТВО ШАГОВ ГРОМКОСТИ •     *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт изменит количество шагов громкости  *"
    ui_print "*  для музыки в вашей системе. Для аудио-вызовов  *"
    ui_print "*  и иных сценариев шаги останутся прежними.      *"
    ui_print "*_________________________________________________*"
    ui_print "*        [VOL+] - Выбор | [VOL-] - Принять        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 30 ( ~ 1.1 - 2.0 dB каждый шаг)"
    ui_print "   3. 50 ( ~ 0.8 - 1.4 dB каждый шаг)"
    ui_print "   4. 100 ( ~ 0.4 - 0.7 dB каждый шаг)"
    ui_print " "
    VOLSTEPSINT=1
    while true; do
      ui_print " - $VOLSTEPSINT"
      "$VKSEL" && VOLSTEPSINT="$((VOLSTEPSINT + 1))" || break
      [[ "$VOLSTEPSINT" -gt "4" ]] && VOLSTEPSINT=1
    done
    case "$VOLSTEPSINT" in
    "1") VOLSTEPS="Skip" ;;
    "2") VOLSTEPS="30" ;;
    "3") VOLSTEPS="50" ;;
    "4") VOLSTEPS="100" ;;
    esac
    ui_print " - [*] Выбрано: $VOLSTEPS"
    ui_print ""
    sed -i 's/VOLSTEPS=skip/VOLSTEPS='$VOLSTEPS'/g' $SETTINGS

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [2/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*      • ВЫБЕРИТЕ УРОВЕНЬ ГРОМКОСТИ МУЗЫКИ •      *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт изменит максимальный порог          *"
    ui_print "*  громкости музыки в вашей системе. Чем больше   *"
    ui_print "*  числовое значение, тем выше максимальная       *"
    ui_print "*  громкость.                                     *"
    ui_print "*                                                 *"
    ui_print "*   ПРЕДУПРЕЖДЕНИЕ:                               *"
    ui_print "*  Слишком высокие значения могут привести к      *"
    ui_print "*  искажениям звука.                              *"
    ui_print "*                                                 *"
    ui_print "*   ЗАМЕТКА:                                      *"
    ui_print "*  Не оказывает эффекта на Bluetooth.             *"
    ui_print "*_________________________________________________*"
    ui_print "*        [VOL+] - Выбор | [VOL-] - Принять        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 78"
    ui_print "   3. 84 (Обычно используется по умолчанию)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    VOLMEDIAINT=1
    while true; do
      ui_print " - $VOLMEDIAINT"
      "$VKSEL" && VOLMEDIAINT="$((VOLMEDIAINT + 1))" || break
      [[ "$VOLMEDIAINT" -gt "7" ]] && VOLMEDIAINT=1
    done
    case "$VOLMEDIAINT" in
    "1") VOLMEDIA="Skip" ;;
    "2") VOLMEDIA="78" ;;
    "3") VOLMEDIA="84" ;;
    "4") VOLMEDIA="90" ;;
    "5") VOLMEDIA="96" ;;
    "6") VOLMEDIA="102" ;;
    "7") VOLMEDIA="108" ;;
    esac
    ui_print " - [*] Выбрано: $VOLMEDIA"
    ui_print ""
    sed -i 's/VOLMEDIA=skip/VOLMEDIA='$VOLMEDIA'/g' $SETTINGS

    ui_print "  "
    ui_print "***************************************************"
    ui_print "* [3/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*     • ВЫБРАТЬ ЧУВСТВИТЕЛЬНОСТЬ МИКРОФОНОВ •     *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт изменит чувствительность микрофонов *"
    ui_print "*  в вашей системе. Чем больше числовое значение, *"
    ui_print "*  тем громче будет звучать запись.               *"
    ui_print "*                                                 *"
    ui_print "*   ПРЕДУПРЕЖДЕНИЕ:                               *"
    ui_print "*  Слишком высокие значения могут привести к      *"
    ui_print "*  искажениям звука.                              *"
    ui_print "*                                                 *"
    ui_print "*   ЗАМЕТКА:                                      *"
    ui_print "*  Не оказывает эффекта на Bluetooth.             *"
    ui_print "*_________________________________________________*"
    ui_print "*        [VOL+] - Выбор | [VOL-] - Принять        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 78"
    ui_print "   3. 84 (Обычно используется по умолчанию)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    VOLMICINT=1
    while true; do
      ui_print " - $VOLMICINT"
      "$VKSEL" && VOLMICINT="$((VOLMICINT + 1))" || break
      [[ "$VOLMICINT" -gt "7" ]] && VOLMICINT=1
    done
    case "$VOLMICINT" in
    "1") VOLMIC="Skip" ;;
    "2") VOLMIC="78" ;;
    "3") VOLMIC="84" ;;
    "4") VOLMIC="90" ;;
    "5") VOLMIC="96" ;;
    "6") VOLMIC="102" ;;
    "7") VOLMIC="108" ;;
    esac
    ui_print " - [*] Выбрано: $VOLMIC"
    ui_print ""
    sed -i 's/VOLMIC=skip/VOLMIC='$VOLMIC'/g' $SETTINGS

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [4/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*            • ВЫБРАТЬ АУДИО ФОРМАТ •             *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт настроит аудио кодек вашего         *"
    ui_print "*  устройства, заставляя его обрабатывать звук в  *"
    ui_print "*  соответствии с выбранными параметрами. После   *"
    ui_print "*  установки этого пункта вы не увидите *-бит в   *"
    ui_print "*  логах, модуль не будет вводить вас в           *"
    ui_print "*  заблуждение выдуманными цифрами. Однако, вы    *"
    ui_print "*  услышите положительные изменения в звуке.      *"
    ui_print "*                                                 *"
    ui_print "*   ЗАМЕТКА:                                      *"
    ui_print "*  Не оказывает эффекта на Bluetooth.             *"
    ui_print "*_________________________________________________*"
    ui_print "*        [VOL+] - Выбор | [VOL-] - Принять        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 24-бит"
    ui_print "   3. 32-бит (только для SD870 и выше)"
    ui_print "   4. Флоат (формат данных с плавающей точкой)"
    ui_print " "
    BITNESINT=1
    while true; do
      ui_print " - $BITNESINT"
      "$VKSEL" && BITNESINT="$((BITNESINT + 1))" || break
      [[ "$BITNESINT" -gt "4" ]] && BITNESINT=1
    done
    case "$BITNESINT" in
    "1") BITNES="Skip" ;;
    "2") BITNES="24" ;;
    "3") BITNES="32" ;;
    "4") BITNES="float" ;;
    esac
    ui_print " - [*] Выбрано: $BITNES"
    ui_print ""
    sed -i 's/BITNES=skip/BITNES='$BITNES'/g' $SETTINGS

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [5/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*        • ВЫБРАТЬ ЧАСТОТУ ДИСКРЕТИЗАЦИИ •        *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт настроит аудио кодек вашего         *"
    ui_print "*  устройства, заставляя его обрабатывать звук в  *"
    ui_print "*  соответствии с выбранными параметрами. После   *"
    ui_print "*  установки этого пункта вы не увидите *-Гц в    *"
    ui_print "*  логах, модуль не будет вводить вас в           *"
    ui_print "*  заблуждение выдуманными цифрами. Однако, вы    *"
    ui_print "*  услышите положительные изменения в звуке.      *"
    ui_print "*                                                 *"
    ui_print "*   ЗАМЕТКА:                                      *"
    ui_print "*  Не оказывает эффекта на Bluetooth.             *"
    ui_print "*_________________________________________________*"
    ui_print "*        [VOL+] - Выбор | [VOL-] - Принять        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Пропустить (Без каких-либо изменений)"
    ui_print "   2. 96000 Гц"
    ui_print "   3. 192000 Гц"
    ui_print "   4. 384000 Гц (только для SD870 и выше)"
    ui_print " "
    SAMPLERATEINT=1
    while true; do
      ui_print "  - $SAMPLERATEINT"
      "$VKSEL" && SAMPLERATEINT="$((SAMPLERATEINT + 1))" || break
      [[ "$SAMPLERATEINT" -gt "4" ]] && SAMPLERATEINT=1
    done
    case "$SAMPLERATEINT" in
    "1") SAMPLERATE="Skip" ;;
    "2") SAMPLERATE="96000" ;;
    "3") SAMPLERATE="192000" ;;
    "4") SAMPLERATE="384000" ;;
    esac
    ui_print " - [*] Выбрано: $SAMPLERATE"
    ui_print ""
    sed -i 's/SAMPLERATE=skip/SAMPLERATE='$SAMPLERATE'/g' $SETTINGS

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [6/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*       • ОТКЛЮЧИТЬ ЗВУКОВЫЕ ВМЕШАТЕЛЬСТВА •      *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт отключит различные системные        *"
    ui_print "*  оптимизации звука, такие как компрессоры и     *"
    ui_print "*  прочие бессмысленные механизмы, которые        *"
    ui_print "*  мешают нормальной передаче аудио.              *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*      • НАСТРОИТЬ ВСТРОЕННЫЙ АУДИО КОДЕК •       *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт настроит аудио кодек вашего         *"
    ui_print "*  устройства. Он постарается отключить глубокий  *"
    ui_print "*  буфер, позволяя вашему DSP чипу обрабатывать   *"
    ui_print "*  аудио с более хорошим качеством.               *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*       • ПАТЧИНГ DEVICE_FEATURES ФАЙЛА(-ОВ) •    *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт сделает следующее:                  *"
    ui_print "*  - Разблокирует частоты дискретизации аудио     *"
    ui_print "*    вплоть до 192000 Гц;                         *"
    ui_print "*  - Включит HD запись аудио в камере;            *"
    ui_print "*  - Улучшит качество записи VoIP;                *"
    ui_print "*  - Включит поддержку HD записи вашего голоса    *"
    ui_print "*    в приложениях;                               *"
    ui_print "*  - Включит поддержку Hi-Fi на поддерживаемых    *"
    ui_print "*    устройствах.                                 *"
    ui_print "*                                                 *"
    ui_print "*  И многое другое...                             *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*   • ДРУГИЕ ПАТЧИ ДЛЯ MIXER_PATHS ФАЙЛА (-ОВ) •  *"
    ui_print "*                                                 *"
    ui_print "*  Эта опция изменит роуты аудио, удалит всё      *"
    ui_print "*  лишнее и постарается изменить конфигурацию     *"
    ui_print "*  аудио потока таким образом, чтобы аудио        *"
    ui_print "*  обрабатывалось наикратчайшим образом по пути   *"
    ui_print "*  к аудио кодеку вашего устройства. Также она    *"
    ui_print "*  отключит различные частотные отсечки и         *"
    ui_print "*  обрезки, которые якобы находятся вне предела   *"
    ui_print "*  слышимости человека.                           *"
    ui_print "*                                                 *"
    ui_print "*  Содержит АВТОРСКИЕ настройки аудио кодека для  *"
    ui_print "*  для поддерживаемых устройств, например:        *"
    ui_print "*  - Poco X3 NFC (surya);                         *"
    ui_print "*  - Poco X3 Pro (vayu);                          *"
    ui_print "*  - Redmi Note 10 Pro (sweet);                   *"
    ui_print "*  - Redmi Note 10 Pro Max (sweetin);             *"
    ui_print "*  - Mi 11 Ultra (star).                          *"
    ui_print "*                                                 *"
    ui_print "*  Эти параметры значительным образом улучшают    *"
    ui_print "*  качество стерео вашего устройства, общий       *"
    ui_print "*  объём, музыкальность, стерео сцену, исправлют  *"
    ui_print "*  баланс громкости в динамиках.                  *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*      • ТВИКИ ДЛЯ BUILD.PROP ФАЙЛА (-ОВ) •       *"
    ui_print "*                                                 *"
    ui_print "*  Содержит огромное количество глобальных        *"
    ui_print "*  настроек, которые значительно изменят          *"
    ui_print "*  качество аудио к лучшему. Не сомневайтесь,     *"
    ui_print "*  соглашайтесь на установку.                     *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*             • УЛУЧШИТЬ BLUETOOTH •              *"
    ui_print "*                                                 *"
    ui_print "*  Эта опция постарается по максимуму улучшить    *"
    ui_print "*  качество аудио в Bluetooth, а также исправит   *"
    ui_print "*  проблему самопроизвольного переключения AAC    *"
    ui_print "*  кодека в положение ВЫКЛЮЧЕНО.                  *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*            • ИЗМЕНИТЬ АУДИО ВЫХОД •             *"
    ui_print "*                                                 *"
    ui_print "*  Эта опция переключит DIRECT на DIRECT_PCM,     *"
    ui_print "*  обладающий большей детальностью и качеством.   *"
    ui_print "*  Может привести к отсутствию звука в таких      *"
    ui_print "*  приложениях как: TikTok, YouTube, а также в    *"
    ui_print "*  различных мобильных играх.                     *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*      • УСТАНОВИТЬ КАСТОМНЫЙ ПРЕСЕТ IIR •        *"
    ui_print "*                                                 *"
    ui_print "*  IIR влияет на итоговую кривую частотной        *"
    ui_print "*  характеристики. По умолчанию установлены       *"
    ui_print "*  параметры с акцентом на детальность низких     *"
    ui_print "*  частот. После применения этого пункта вы       *"
    ui_print "*  услышите положительные изменения в             *"
    ui_print "*  детальности аудио.                             *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
    ui_print "***************************************************"
    ui_print " "
    if chooseport 60; then
      STEP13=true
      sed -i 's/STEP13=false/STEP13=true/g' $SETTINGS
    fi

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [14/16]                                         *"
    ui_print "*                                                 *"
    ui_print "*       • ИГНОРИРОВАТЬ ВСЕ АУДИО ЭФФЕКТЫ •        *"
    ui_print "*                                                 *"
    ui_print "*  Этот пункт отключит все аудио эффекты на       *"
    ui_print "*  системном урвоне. Это сломает XiaomiParts,     *"
    ui_print "*  Dirac, Dolby и прочие эквалайзеры.             *"
    ui_print "*  Значительно повышает качество аудио для        *"
    ui_print "*  качественных наушников.                        *"
    ui_print "*                                                 *"
    ui_print "*   ЗАМЕТКА:                                      *"
    ui_print "*  Если вы согласитесь, звук станет более сухим,  *"
    ui_print "*  чистым, плоским. Большинству рекомендуется     *"
    ui_print "*  просто пропустить данный пункт.                *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*      • УСТАНОВИТЬ ЭКСПЕРИМЕНТАЛЬНЫЕ ТВИКИ •     *"
    ui_print "*                                                 *"
    ui_print "*  Эта опция дополнительно настроит аудио кодек   *"
    ui_print "*  вашего устройства при помощи tinymix функции.  *"
    ui_print "*  Она значительно улучшит качество аудио, но     *"
    ui_print "*  совместима только с ограниченным количеством   *"
    ui_print "*  устройств.                                     *"
    ui_print "*                                                 *"
    ui_print "*   ПРЕДУПРЕЖДЕНИЕ:                               *"
    ui_print "*  Эти параметры могут привести к разным          *"
    ui_print "*  проблемам вплоть до полного bootloop вашего    *"
    ui_print "*  устройства. Используйте на свой страх и риск!  *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
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
    ui_print "*           • НАСТРОИТЬ DOLBY ATMOS •             *"
    ui_print "*                                                 *"
    ui_print "*  Эта опция доп-но настроит ваш Dolby, если он   *"
    ui_print "*  имеется в системе (как системный, так и        *"
    ui_print "*  несистемный/кастомный), для лучшего качества   *"
    ui_print "*  звучания путём отключения различных мусорных   *"
    ui_print "*  функций и механизмов, например компрессоров,   *"
    ui_print "*  аудио-регуляторов и так далее.                 *"
    ui_print "*_________________________________________________*"
    ui_print "*    [VOL+] - Установить | [VOL-] - Пропустить    *"
    ui_print "***************************************************"
    ui_print " "
    if chooseport 60; then
      STEP16=true
      sed -i 's/STEP16=false/STEP16=true/g' $SETTINGS
    fi
  fi
  ui_print " - ВАШИ НАСТРОЙКИ: "
  ui_print " 1. Количество шагов громкости: $VOLSTEPS"
  ui_print " 2. Максимальный уровень громкости: $VOLMEDIA"
  ui_print " 3. Чувствительность микрофонов: $VOLMIC"
  ui_print " 4. Выбранный аудио формат: $BITNES"
  ui_print " 5. Выбранная частота дискретизации: $SAMPLERATE"
  ui_print " 6. Отключить звуковые вмешательства: $STEP6"
  ui_print " 7. Настроить встроенный аудио кодек: $STEP7"
  ui_print " 8. Патчинг device_features файла (-ов): $STEP8"
  ui_print " 9. Другие патчи для mixer_paths файла (-ов): $STEP9"
  ui_print " 10. Твики для build.prop файла (-ов): $STEP10"
  ui_print " 11. Улучшить bluetooth: $STEP11"
  ui_print " 12. Изменить аудио выход: $STEP12"
  ui_print " 13. Установить кастомный пресет для IIR: $STEP13"
  ui_print " 14. Игнорировать все аудио эффекты: $STEP14"
  ui_print " 15. Установить экспериментальные твики: $STEP15"
  ui_print " 16. Настроить Dolby Atmos: $STEP16"
  ui_print " "
  ui_print " - Установка начата, пожалуйста подождите пару секунд"
  ui_print " "
  (
    # notification
    echo -e '\n' >>"$MODPATH/service.sh"
    echo "sleep 32" >>"$MODPATH/service.sh"
    echo "su -lp 2000 -c \"cmd notification post -S bigtext -t 'Уведомление от NLSound' 'Tag' 'Модификация загружена и работает, приятного прослушивания! Свайпните чтобы закрыть это уведомление :)'\"" >>"$MODPATH/service.sh"
  ) &
else
  if [ -f "$RESTORE_SETTINGS" ]; then
    ui_print " "
    ui_print "***************************************************"
    ui_print "*                                                 *"
    ui_print "*         • PREVIOUS SETTINGS DETECTED •          *"
    ui_print "*                                                 *"
    ui_print "*  You can set the same settings as last time.    *"
    ui_print "*                                                 *"
    ui_print "*   NOTE:                                         *"
    ui_print "*  When transitioning from one version of the     *"
    ui_print "*  module to another, there may be additional     *"
    ui_print "*  items that will be skipped, as they weren't    *"
    ui_print "*  recorded before.                               *"
    ui_print "*_________________________________________________*"
    ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
    ui_print "***************************************************"
    ui_print " "
    if chooseport 60; then
      continue_script=false
      old_modpath=$MODPATH
      source "$RESTORE_SETTINGS"
      MODPATH=$old_modpath
      export SAMPLERATE BITNES VOLMIC VOLMEDIA VOLSTEPS STEP6 STEP7 STEP8 STEP9 STEP10 STEP11 STEP12 STEP13 STEP14 STEP15 STEP16
      (
        sed -i 's/VOLSTEPS=skip/VOLSTEPS='$VOLSTEPS'/g' $SETTINGS
        sed -i 's/VOLMEDIA=skip/VOLMEDIA='$VOLMEDIA'/g' $SETTINGS
        sed -i 's/VOLMIC=skip/VOLMIC='$VOLMIC'/g' $SETTINGS
        sed -i 's/BITNES=skip/BITNES='$BITNES'/g' $SETTINGS
        sed -i 's/SAMPLERATE=skip/SAMPLERATE='$SAMPLERATE'/g' $SETTINGS
        sed -i "s/STEP6=false/STEP6=$STEP6/g" "$SETTINGS"
        sed -i "s/STEP7=false/STEP7=$STEP7/g" "$SETTINGS"
        sed -i "s/STEP8=false/STEP8=$STEP8/g" "$SETTINGS"
        sed -i "s/STEP9=false/STEP9=$STEP9/g" "$SETTINGS"
        sed -i "s/STEP10=false/STEP10=$STEP10/g" "$SETTINGS"
        sed -i "s/STEP11=false/STEP11=$STEP11/g" "$SETTINGS"
        sed -i "s/STEP12=false/STEP12=$STEP12/g" "$SETTINGS"
        sed -i "s/STEP13=false/STEP13=$STEP13/g" "$SETTINGS"
        sed -i "s/STEP14=false/STEP14=$STEP14/g" "$SETTINGS"
        sed -i "s/STEP15=false/STEP15=$STEP15/g" "$SETTINGS"
        sed -i "s/STEP16=false/STEP16=$STEP16/g" "$SETTINGS"
      ) &
    else
      ui_print " - Restoring previous settings skipped"
      ui_print " "
      sleep 0.3
    fi
  fi
  if [ $continue_script == true ]; then
    ui_print " - Configurate me, pls >.< - "
    ui_print " "
    ui_print "***************************************************"
    ui_print "* [1/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*            • SELECT VOLUME STEPS •              *"
    ui_print "*                                                 *"
    ui_print "*  This item will change the number of volume     *"
    ui_print "*  steps for music in your system. For audio      *"
    ui_print "*  calls and other scenarios, the steps will      *"
    ui_print "*  remain the same.                               *"
    ui_print "*_________________________________________________*"
    ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Skip (No changes will be made)"
    ui_print "   2. 30 ( ~ 1.1 - 2.0 dB per step)"
    ui_print "   3. 50 ( ~ 0.8 - 1.4 dB per step)"
    ui_print "   4. 100 ( ~ 0.4 - 0.7 dB per step)"
    ui_print " "
    VOLSTEPSINT=1
    while true; do
      ui_print " - $VOLSTEPSINT"
      "$VKSEL" && VOLSTEPSINT="$((VOLSTEPSINT + 1))" || break
      [[ "$VOLSTEPSINT" -gt "3" ]] && VOLSTEPSINT=1
    done
    case "$VOLSTEPSINT" in
    "1") VOLSTEPS="Skip" ;;
    "2") VOLSTEPS="30" ;;
    "3") VOLSTEPS="50" ;;
    "4") VOLSTEPS="100" ;;
    esac
    ui_print " - [*] Selected: $VOLSTEPS"
    ui_print ""
    sed -i 's/VOLSTEPS=skip/VOLSTEPS='$VOLSTEPS'/g' $SETTINGS

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [2/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*          • SELECT VOLUMES FOR MEDIA •           *"
    ui_print "*                                                 *"
    ui_print "*  This item will change the maximum threshold    *"
    ui_print "*  of music volume in your system. The greater    *"
    ui_print "*  the numeric value, the higher the maximum      *"
    ui_print "*  volume.                                        *"
    ui_print "*                                                 *"
    ui_print "*   WARNING:                                      *"
    ui_print "*  Values that are too high may cause sound       *"
    ui_print "*  distortion.                                    *"
    ui_print "*                                                 *"
    ui_print "*   NOTE:                                         *"
    ui_print "*  Does not affect Bluetooth.                     *"
    ui_print "*_________________________________________________*"
    ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Skip (Without any changes)"
    ui_print "   2. 78"
    ui_print "   3. 84 (Is usually the default)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    VOLMEDIAINT=1
    while true; do
      ui_print " - $VOLMEDIAINT"
      "$VKSEL" && VOLMEDIAINT="$((VOLMEDIAINT + 1))" || break
      [[ "$VOLMEDIAINT" -gt "7" ]] && VOLMEDIAINT=1
    done
    case "$VOLMEDIAINT" in
    "1") VOLMEDIA="Skip" ;;
    "2") VOLMEDIA="78" ;;
    "3") VOLMEDIA="84" ;;
    "4") VOLMEDIA="90" ;;
    "5") VOLMEDIA="96" ;;
    "6") VOLMEDIA="102" ;;
    "7") VOLMEDIA="108" ;;
    esac
    ui_print " - [*] Selected: $VOLMEDIA"
    ui_print ""
    sed -i 's/VOLMEDIA=skip/VOLMEDIA='$VOLMEDIA'/g' $SETTINGS

    ui_print "  "
    ui_print "***************************************************"
    ui_print "* [3/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*     • SELECT MICROPHONE SENSITIVITY •           *"
    ui_print "*                                                 *"
    ui_print "*  This item will change the sensitivity of the   *"
    ui_print "*  microphones in your system. The higher the     *"
    ui_print "*  numerical value, the louder the recording will *"
    ui_print "*  sound.                                         *"
    ui_print "*                                                 *"
    ui_print "*   WARNING:                                      *"
    ui_print "*  Values that are too high may cause sound       *"
    ui_print "*  distortion.                                    *"
    ui_print "*                                                 *"
    ui_print "*   NOTE:                                         *"
    ui_print "*  Does not affect Bluetooth.                     *"
    ui_print "*_________________________________________________*"
    ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Skip (Without any changes)"
    ui_print "   2. 78"
    ui_print "   3. 84 (Is usually the default)"
    ui_print "   4. 90"
    ui_print "   5. 96"
    ui_print "   6. 102"
    ui_print "   7. 108"
    ui_print " "
    VOLMICINT=1
    while true; do
      ui_print " - $VOLMICINT"
      "$VKSEL" && VOLMICINT="$((VOLMICINT + 1))" || break
      [[ "$VOLMICINT" -gt "7" ]] && VOLMICINT=1
    done
    case "$VOLMICINT" in
    "1") VOLMIC="Skip" ;;
    "2") VOLMIC="78" ;;
    "3") VOLMIC="84" ;;
    "4") VOLMIC="90" ;;
    "5") VOLMIC="96" ;;
    "6") VOLMIC="102" ;;
    "7") VOLMIC="108" ;;
    esac
    ui_print " - [*] Selected: $VOLMIC"
    ui_print ""
    sed -i 's/VOLMIC=skip/VOLMIC='$VOLMIC'/g' $SETTINGS

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [4/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*            • SELECT AUDIO FORMAT •              *"
    ui_print "*                                                 *"
    ui_print "*  This item will configure the audio codec of    *"
    ui_print "*  your device, forcing it to process sound       *"
    ui_print "*  according to the selected parameters. After    *"
    ui_print "*  installation, you will not see *-bit in the    *"
    ui_print "*  logs, the module will not deceive you with     *"
    ui_print "*  fictitious figures. However, you will hear     *"
    ui_print "*  positive changes in the sound.                 *"
    ui_print "*                                                 *"
    ui_print "*   NOTE:                                         *"
    ui_print "*  Does not affect Bluetooth.                     *"
    ui_print "*_________________________________________________*"
    ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Skip (No changes will be made)"
    ui_print "   2. 24-bit"
    ui_print "   3. 32-bit (only for SD870 and higher)"
    ui_print "   4. Float"
    ui_print " "
    BITNESINT=1
    while true; do
      ui_print " - $BITNESINT"
      "$VKSEL" && BITNESINT="$((BITNESINT + 1))" || break
      [[ "$BITNESINT" -gt "4" ]] && BITNESINT=1
    done
    case "$BITNESINT" in
    "1") BITNES="Skip" ;;
    "2") BITNES="24" ;;
    "3") BITNES="32" ;;
    "4") BITNES="float" ;;
    esac
    ui_print " - [*] Selected: $BITNES"
    ui_print ""
    sed -i 's/BITNES=skip/BITNES='$BITNES'/g' $SETTINGS

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [5/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*            • SELECT SAMPLING RATE •             *"
    ui_print "*                                                 *"
    ui_print "*  This item will configure the audio codec of    *"
    ui_print "*  your device, forcing it to process sound       *"
    ui_print "*  according to the selected parameters. After    *"
    ui_print "*  installation, you will not see *-Hz in the     *"
    ui_print "*  logs, the module will not deceive you with     *"
    ui_print "*  fictitious figures. However, you will hear     *"
    ui_print "*  positive changes in the sound.                 *"
    ui_print "*                                                 *"
    ui_print "*   NOTE:                                         *"
    ui_print "*  Does not affect Bluetooth.                     *"
    ui_print "*_________________________________________________*"
    ui_print "*       [VOL+] - select | [VOL-] - confirm        *"
    ui_print "***************************************************"
    ui_print " "
    ui_print "   1. Skip (No changes will be made)"
    ui_print "   2. 96000 Hz"
    ui_print "   3. 192000 Hz"
    ui_print "   4. 384000 Hz (only for SD870 and higher)"
    ui_print " "
    SAMPLERATEINT=1
    while true; do
      ui_print "  - $SAMPLERATEINT"
      "$VKSEL" && SAMPLERATEINT="$((SAMPLERATEINT + 1))" || break
      [[ "$SAMPLERATEINT" -gt "4" ]] && SAMPLERATEINT=1
    done
    case "$SAMPLERATEINT" in
    "1") SAMPLERATE="Skip" ;;
    "2") SAMPLERATE="96000" ;;
    "3") SAMPLERATE="192000" ;;
    "4") SAMPLERATE="384000" ;;
    esac
    ui_print " - [*] Selected: $SAMPLERATE"
    ui_print ""
    sed -i 's/SAMPLERATE=skip/SAMPLERATE='$SAMPLERATE'/g' $SETTINGS

    ui_print " "
    ui_print "***************************************************"
    ui_print "* [6/16]                                          *"
    ui_print "*                                                 *"
    ui_print "*        • TURN OFF SOUND INTERFERENCE •          *"
    ui_print "*                                                 *"
    ui_print "*  This step will disable various system audio    *"
    ui_print "*  optimizations, such as compressors, limiters,  *"
    ui_print "*  and other unnecessary mechanisms that          *"
    ui_print "*  interfere with normal audio perception.        *"
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
    ui_print "*  This option will configure your device's       *"
    ui_print "*  internal audio codec. For example, it will     *"
    ui_print "*  try to disable the deep buffer slightly,       *"
    ui_print "*  allowing the external DSP chip to process      *"
    ui_print "*  audio with higher quality and many more        *"
    ui_print "*  useful little things.                          *"
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
    ui_print "*  This item will do the following:               *"
    ui_print "*  - Unlock audio sampling rates up to 192000 Hz; *"
    ui_print "*  - Enable HD audio recording in the camcorder;  *"
    ui_print "*  - Improve VoIP recording quality;              *"
    ui_print "*  - Enable HD voice recording support in apps;   *"
    ui_print "*  - Enable Hi-Fi support on supported devices.   *"
    ui_print "*                                                 *"
    ui_print "*  And much more...                               *"
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
    ui_print "*      • OTHER PATCHES IN MIXER_PATHS FILES •     *"
    ui_print "*                                                 *"
    ui_print "*  This option will change the audio routing,     *"
    ui_print "*  remove anything superfluous, and try to alter  *"
    ui_print "*  the audio stream configuration so that the     *"
    ui_print "*  audio is processed in the shortest path to     *"
    ui_print "*  the device's audio codec. It will disable      *"
    ui_print "*  various frequency cut-offs and limits that     *"
    ui_print "*  are supposedly beyond human hearing.           *"
    ui_print "*                                                 *"
    ui_print "*  Contains AUTHOR'S audio codec settings for     *"
    ui_print "*  supported devices, for instance:               *"
    ui_print "*  - Poco X3 NFC (surya);                         *"
    ui_print "*  - Poco X3 Pro (vayu);                          *"
    ui_print "*  - Redmi Note 10 (mojito);                      *"
    ui_print "*  - Redmi Note 10 Pro (sweet);                   *"
    ui_print "*  - Redmi Note 10 Pro Max (sweetin);             *"
    ui_print "*  - Mi 11 Ultra (star).                          *"
    ui_print "*                                                 *"
    ui_print "*  These settings significantly improve the       *"
    ui_print "*  stereo quality of your device, the overall     *"
    ui_print "*  volume, musicality, the stereo scene, and      *"
    ui_print "*  corrects the balance of volume in speakers.    *"
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
    ui_print "*         • TWEAKS FOR BUILD.PROP FILES •         *"
    ui_print "*                                                 *"
    ui_print "*  Contains a huge amount of global settings      *"
    ui_print "*  that will significantly change audio quality   *"
    ui_print "*  for the better. Do not hesitate to agree to    *"
    ui_print "*  the installation.                              *"
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
    ui_print "*             • IMPROVE BLUETOOTH •               *"
    ui_print "*                                                 *"
    ui_print "*  This option will try to maximize the           *"
    ui_print "*  improvement of audio quality in Bluetooth,     *"
    ui_print "*  as well as fix the problem of spontaneous      *"
    ui_print "*  AAC codec switching to OFF position.           *"
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
    ui_print "*            • SWITCH AUDIO OUTPUT •              *"
    ui_print "*                                                 *"
    ui_print "*  This option will switch DIRECT to DIRECT_PCM,  *"
    ui_print "*  which has more detail and quality. This may    *"
    ui_print "*  lead to no sound in apps such as TikTok,       *"
    ui_print "*  YouTube, as well as various mobile games.      *"
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
    ui_print "*        • INSTALL CUSTOM PRESET FOR IIR •        *"
    ui_print "*                                                 *"
    ui_print "*  IIR affects the final frequency curve          *"
    ui_print "*  characteristic. By default, the settings       *"
    ui_print "*  are tuned towards the clarity of the low       *"
    ui_print "*  frequencies. After applying this item, you     *"
    ui_print "*  will hear positive changes in audio detail.    *"
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
    ui_print "* [14/16]                                         *"
    ui_print "*                                                 *"
    ui_print "*          • IGNORE ALL AUDIO EFFECTS •           *"
    ui_print "*                                                 *"
    ui_print "*  This item will disable all audio effects on    *"
    ui_print "*  the system level. This will break XiaomiParts, *"
    ui_print "*  Dirac, Dolby, and other equalizers. It greatly *"
    ui_print "*  enhances audio quality for high-quality        *"
    ui_print "*  headphones.                                    *"
    ui_print "*                                                 *"
    ui_print "*   NOTE:                                         *"
    ui_print "*  If you agree, the sound will become drier,     *"
    ui_print "*  cleaner, flatter. Most users are recommended   *"
    ui_print "*  to skip this item.                             *"
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
    ui_print "*         • INSTALL EXPERIMENTAL TWEAKS •         *"
    ui_print "*                                                 *"
    ui_print "*  This option will further adjust your device's  *"
    ui_print "*  audio codec using the tinymix function. It     *"
    ui_print "*  will significantly improve audio quality, but  *"
    ui_print "*  is only compatible with a limited number of    *"
    ui_print "*  devices.                                       *"
    ui_print "*                                                 *"
    ui_print "*   WARNING:                                      *"
    ui_print "*  These parameters can lead to various issues    *"
    ui_print "*  up to a complete bootloop of your device.      *"
    ui_print "*  Use at your own risk!                          *"
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
    ui_print "*           • CONFIGURE DOLBY ATMOS •             *"
    ui_print "*                                                 *"
    ui_print "*  This option will additionally configure your   *"
    ui_print "*  Dolby if it is available in the system (both   *"
    ui_print "*  system and non-system/custom), for better      *"
    ui_print "*  sound quality by disabling various unnecessary *"
    ui_print "*  features and mechanisms, such as compressors,  *"
    ui_print "*  audio regulators, and so on.                   *"
    ui_print "*_________________________________________________*"
    ui_print "*        [VOL+] - Install | [VOL-] - skip         *"
    ui_print "***************************************************"
    ui_print " "
    if chooseport 60; then
      STEP16=true
      sed -i 's/STEP16=false/STEP16=true/g' $SETTINGS
    fi
  fi
  ui_print " - YOUR SETTINGS: "
  ui_print " 1. Volume steps: $VOLSTEPS"
  ui_print " 2. Volume levels: $VOLMEDIA"
  ui_print " 3. Microphone levels: $VOLMIC"
  ui_print " 4. Audio format configuration: $BITNES"
  ui_print " 5. Sample rate configuration: $SAMPLERATE"
  ui_print " 6. Turn off sound interference: $STEP6"
  ui_print " 7. Configurating interal audio codec: $STEP7"
  ui_print " 8. Patching device_features files: $STEP8"
  ui_print " 9. Other patches in mixer_paths files: $STEP9"
  ui_print " 10. Tweaks for build.prop files: $STEP10"
  ui_print " 11. Improve bluetooth: $STEP11"
  ui_print " 12. Switch audio output: $STEP12"
  ui_print " 13. Install custom preset for IIR: $STEP13"
  ui_print " 14. Ignore all audio effects: $STEP14"
  ui_print " 15. Install experimental tweaks: $STEP15"
  ui_print " 16. Configure Dolby Atmos: $STEP16"
  ui_print " "
  ui_print " - Installation started, please wait a few seconds"
  ui_print " "
  (
    # notification
    echo -e '\n' >>"$MODPATH/service.sh"
    echo "sleep 32" >>"$MODPATH/service.sh"
    echo "su -lp 2000 -c \"cmd notification post -S bigtext -t 'NLSound Notification' 'Tag' 'Modification load and works, enjoy listening! Swipe for close this notification :)'\"" >>"$MODPATH/service.sh"
  ) &
fi

if [ "$BITNES" != "Skip" ] || [ "$SAMPLERATE" != "Skip" ]; then
  (
    for OAPIXML in ${APIXMLS}; do
      APIXML="$MODPATH$(echo $OAPIXML | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f "$ORIGDIR$OAPIXML" "$APIXML"
      if [ "$BITNES" != "Skip" ]; then
        sed -i 's/device name="SND_DEVICE_OUT_SPEAKER" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER" bit_width="'$BITNES'"/g' $APIXML
        sed -i 's/device name="SND_DEVICE_OUT_HEADPHONES" bit_width=".*"/device name="SND_DEVICE_OUT_HEADPHONES" bit_width="'$BITNES'"/g' $APIXML
        sed -i 's/device name="SND_DEVICE_OUT_SPEAKER_REVERSE" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER_REVERSE" bit_width="'$BITNES'"/g' $APIXML
        sed -i 's/device name="SND_DEVICE_OUT_SPEAKER_PROTECTED" bit_width=".*"/device name="SND_DEVICE_OUT_SPEAKER_PROTECTED" bit_width="'$BITNES'"/g' $APIXML
        sed -i 's/device name="SND_DEVICE_OUT_HEADPHONES_44_1" bit_width=".*"/device name="SND_DEVICE_OUT_HEADPHONES_44_1" bit_width="'$BITNES'"/g' $APIXML
        sed -i 's/device name="SND_DEVICE_OUT_GAME_SPEAKER" bit_width=".*"/device name="SND_DEVICE_OUT_GAME_SPEAKER" bit_width="'$BITNES'"/g' $APIXML
        sed -i 's/device name="SND_DEVICE_OUT_GAME_HEADPHONES" bit_width=".*"/device name="SND_DEVICE_OUT_GAME_HEADPHONES" bit_width="'$BITNES'"/g' $APIXML
        sed -i 's/device name="SND_DEVICE_OUT_BT_A2DP" bit_width=".*"/device name="SND_DEVICE_OUT_BT_A2DP" bit_width="'$BITNES'"/g' $APIXML
        sed -i 's/\(app uc_type=".*" mode="default" bit_width="\)[^"]*"/\1'$BITNES'"/g' $APIXML
      fi
      if [ "$SAMPLERATE" != "Skip" ]; then
        sed -i 's/\(app uc_type=".*" mode="default" bit_width=".*" id=".*" max_rate="\)[^"]*"/\1'$SAMPLERATE'"/g' $APIXML
      fi
      sed -i 's/AUDIO_MICROPHONE_CHANNEL_MAPPING_PROCESSED/AUDIO_MICROPHONE_CHANNEL_MAPPING_DIRECT/g' $APIXML
      sed -i 's/param key="hifi_filter" value="false"/param key="hifi_filter" value="true"/g' $APIXML
      sed -i 's/param key="config_spk_protection" value="true"/param key="config_spk_protection" value="false"/g' $APIXML
      sed -i '/^ *#/d; /^ *$/d' $APIXML
    done
  ) &
fi

#patch audio_configs.xml
if [ "$STEP7" == "true" ]; then
  (
    for OACONFS in ${ACONFS}; do
      ACFG="$MODPATH$(echo $OACONFS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f $ORIGDIR$OACONFS $ACFG
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
      sed -i 's/"spkr_protection" value="true"/"spkr_protection" value="false"/g' $ACFG
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
      sed -i '/^ *#/d; /^ *$/d' $ACFG
    done
  ) &
fi

if [ "$STEP8" == "true" ]; then
  (
    for ODEVFEA in ${DEVFEAS}; do
      DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f $ORIGDIR$ODEVFEA $DEVFEA
      sed -i 's/name="support_powersaving_mode" value=true/name="support_powersaving_mode" value=false/g' $DEVFEA
      sed -i 's/name="support_samplerate_48000" value=false/name="support_samplerate_48000" value=true/g' $DEVFEA
      sed -i 's/name="support_samplerate_96000" value=false/name="support_samplerate_96000" value=true/g' $DEVFEA
      sed -i 's/name="support_samplerate_192000" value=false/name="support_samplerate_192000" value=true/g' $DEVFEA
      sed -i 's/name="support_samplerate_352000" value=false/name="support_samplerate_352000" value=true/g' $DEVFEA
      sed -i 's/name="support_samplerate_384000" value=false/name="support_samplerate_384000" value=true/g' $DEVFEA
      sed -i 's/name="support_low_latency" value=false/name="support_low_latency" value=true/g' $DEVFEA
      sed -i 's/name="support_mid_latency" value=true/name="support_mid_latency" value=false/g' $DEVFEA
      sed -i 's/name="support_high_latency" value=true/name="support_high_latency" value=false/g' $DEVFEA
      sed -i 's/name="support_playback_device" value=false/name="support_playback_device" value=true/g' $DEVFEA
      sed -i 's/name="support_boost_mode" value=false/name="support_boost_mode" value=true/g' $DEVFEA
      sed -i 's/name="support_hifi" value=false/name="support_hifi" value=true/g' $DEVFEA
      sed -i 's/name="support_dolby" value=false/name="support_dolby" value=true/g' $DEVFEA
      sed -i 's/name="support_hd_record_param" value=false/name="support_hd_record_param" value=true/g' $DEVFEA
      sed -i 's/name="support_stereo_record" value=false/name="support_stereo_record" value=true/g' $DEVFEA
      sed -i '/^ *#/d; /^ *$/d' $DEVFEA
    done
    for ODEVFEANEW in ${DEVFEASNEW}; do
      DEVFEANEW="$MODPATH$(echo $ODEVFEANEW | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
      cp_ch -f $ORIGDIR$ODEVFEANEW $DEVFEANEW
      sed -i -e '1 s/^/<feature name="android.hardware.audio.pro"/>\n/;' $DEVFEANEW
      sed -i -e '2 s/^/<feature name="android.hardware.broadcastradio"/>\n/;' $DEVFEANEW
      sed -i '/^ *#/d; /^ *$/d' $DEVFEANEW
    done
  ) &
fi

if [ "$STEP10" == "true" ]; then
  (
    echo -e "\n
# Better parameters audio by NLSound Team
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
audio.decoder_override_check=true
media.aac_51_output_enabled=true
mm.enable.smoothstreaming=true
mmp.enable.3g2=true
vendor.mm.enable.qcom_parser=63963135
vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
qc.tunnel.audio.encode=true
ro.vendor.af.raise_bt_thread_prio=true
vendor.qc2audio.suspend.enabled=false
media.stagefright.thumbnail.prefer_hw_codecs=true
tunnel.audiovideo.decode=true
tunnel.decode=true
lpa.decode=false
lpa30.decode=false
lpa.use-stagefright=false
lpa.releaselock=false
audio.playback.mch.downsample=false
vendor.audio.playback.mch.downsample=false
persist.vendor.audio.playback.mch.downsample=false
vendor.audio.feature.dsm_feedback.enable=true
vendor.audio.feature.dynamic_ecns.enable=true
vendor.audio.feature.external_dsp.enable=true
vendor.audio.feature.external_qdsp.enable=true
vendor.audio.feature.receiver_aided_stereo.enable=true
vendor.audio.feature.source_track.enable=true
vendor.audio.feature.extn_resampler.enable=true
vendor.audio.feature.extn_formats.enable=true
vendor.audio.feature.extn_flac_decoder.enable=true
vendor.audio.feature.extn_compress_format.enable=false
vendor.audio.feature.spkr_protection.enable=false
vendor.audio.feature.usb_burst_mode.enable=false
vendor.audio.feature.usb_offload_sidetone_volume.enable=false
vendor.audio.feature.external_speaker.enable=true
vendor.audio.feature.external_speaker_tfa.enable=true
vendor.audio.feature.ext_hw_plugin.enable=true
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
ro.vendor.audio.hifi=true
ro.config.hifi_config_state=1
ro.config.hifi_enhance_support=1
ro.hardware.hifi.support=true
persist.audio.hifi=true
persist.audio.hifi.volume=1
persist.audio.hifi.int_codec=true
persist.audio.hifi_adv_support=1
persist.audio.hifi.volume=90
persist.vendor.audio.hifi_enabled=true
persist.vendor.audio.hifi.int_codec=true
effect.reverb.pcm=1
sys.vendor.atmos.passthrough=enable
ro.vendor.audio.elus.enable=true
ro.vendor.audio.3d.audio.support=true
ro.vendor.audio.surround.support=true
ro.vendor.media.video.meeting.support=true
persist.vendor.audio.ambisonic.capture=true
persist.vendor.audio.ambisonic.auto.profile=true
audio.record.delay=0
vendor.voice.dsd.playback.conc.disabled=false
vendor.audio.3daudio.record.enable=true
vendor.audio.ull_record_period_multiplier=2
ro.vendor.audio.voice.change.support=true
ro.vendor.audio.voice.change.youme.support=true
ro.vendor.audio.voice.change.version=2
vendor.audio.hdr.record.enable=true
ro.vendor.audio.recording.hd=true
ro.vendor.audio.sdk.ssr=false
ro.qc.sdk.audio.ssr=false
ro.ril.enable.amr.wideband=1
ro.vendor.audio.crystal_talk_record.supported=true
ro.vendor.audio.crystal_talk.supported=true
persist.vendor.audio.spf_restart=true
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
vendor.audio.LL.coeff=100
vendor.audio.caretaker.at=true
vendor.audio.matrix.limiter.enable=0
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.hal.output.suspend.supported=true
vendor.audio.snd_card.open.retries=50
vendor.audio.AT.blocking=true
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.camera.unsupport_low_latency=false 
vendor.audio.tfa9874.dsp.enabled=true
vendor.audio.c2.preferred=true
vendor.qc2audio.suspend.enabled=true
vendor.qc2audio.per_frame.flac.dec.enabled=true
ro.audio.flinger_standbytime_ms=2000
vendor.audio.lowpower=false
vendor.audio.compress_capture.enabled=false 
vendor.audio.compress_capture.aac=false
vendor.audio.rt.mode=23
vendor.audio.rt.mode=true
vendor.audio.rt.mode.onlyfast=false
vendor.audio.cpu.sched=true
vendor.audio.cpu.sched.onlyfast=true
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
ro.audio.resampler.psd.cutoff_percent=99
ro.audio.resampler.psd.tbwcheat=100
ro.audio.soundtrigger.lowpower=false
ro.vendor.audio.frame_count_needed_constant=32768
ro.vendor.audio.soundtrigger.wakeupword=5
ro.vendor.audio.ce.compensation.need=true
ro.vendor.audio.ce.compensation.value=5
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
ro.vendor.audio.spk.clean=true
ro.vendor.audio.pastandby=true
ro.vendor.audio.dpaudio=true
ro.vendor.audio.spk.stereo=true
ro.vendor.audio.soundtrigger.adjconf=true
ro.vendor.audio.dualadc.support=true
ro.vendor.audio.meeting.mode=true
ro.vendor.media.support.omx2=true
ro.vendor.platform.disable.audiorawout=false
ro.vendor.platform.has.realoutputmode=true
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
media.recorder.show_manufacturer_and_model=true
persist.vendor.audio.format.24bit=true
persist.vendor.audio.speaker.stereo=true
persist.vendor.audio.ll_playback_bargein=true
qcom.hw.aac.encoder=true
qcom.hw.aac.decoder=true
ro.vendor.audio.hw.aac.encoder=true
ro.vendor.audio.hw.aac.decoder=true
ro.audio.spatializer_enabled=false
persist.vendor.audio.spatializer.speaker_enabled=false
" >>$PROP
  ) &
fi

if [ "$STEP11" == "true" ]; then
  (
    echo -e "\n
# Bluetooth parameters by NLSound Team
audio.effect.a2dp.enable=1
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
persist.vendor.qcom.bluetooth.scram.enabled=false
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
ro.vendor.audio.btsamplerate.adaptive=true
ro.vendor.audio.screenrecorder.bothrecord=0
ro.vendor.bluetooth.csip_qti=true
vendor.audio.effect.a2dp.enable=1
vendor.bluetooth.ldac.abr=false 
vendor.media.audiohal.btwbs=true
" >>$PROP
  ) &
fi

#patching audio_io_policy file
for OIOPOLICY in ${IOPOLICYS}; do
  (
    IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OIOPOLICY $IOPOLICY

    if [ "$STEP12" == "true" ]; then
      #start patching direct_pcm 24 and 32 bit routes, ignore 16-bit route
      sed -i '/direct_pcm_24/,/compress_passthrough/s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/' $IOPOLICY
      sed -i '/compress_offload_24/,/inputs/s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/' $IOPOLICY
    #end patching direct_pcm routes for 24 and 32 bit
    fi

    if [ "$BITNES" == "24" ]; then
      #start patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_24_BIT_PACKED/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 24/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $IOPOLICY
    #end patching deep_buffer
    fi

    if [ "$BITNES" == "32" ]; then
      #start patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_32_BIT/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 32/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $IOPOLICY
    #end patching deep_buffer
    fi

    if [ "$BITNES" == "float" ]; then
      #start patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/AUDIO_FORMAT_PCM_FLOAT/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width float/' $IOPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $IOPOLICY
    #end patching deep_buffer
    fi
    sed -i '/^ *#/d; /^ *$/d' $IOPOLICY
  ) &
done

#patching audio_output_policy file
for OOUTPUTPOLICY in ${OUTPUTPOLICYS}; do
  (
    OUTPUTPOLICY="$MODPATH$(echo $OOUTPUTPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OOUTPUTPOLICY $OUTPUTPOLICY

    if [ "$STEP12" == "true" ]; then
      #start patching direct_pcm 24 and 32 bit routes, ignore 16-bit route
      sed -i '/direct_pcm_24/,/compress_passthrough/s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/' $OUTPUTPOLICY
      sed -i '/compress_offload_24/,/inputs/s/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/' $OUTPUTPOLICY
    #end patching direct_pcm routes for 24 and 32 bit
    fi

    if [ "$BITNES" == "24" ]; then
      #start patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_24_BIT_PACKED/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 24/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $OUTPUTPOLICY
    #end patching deep_buffer
    fi

    if [ "$BITNES" == "32" ]; then
      #start patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/formats AUDIO_FORMAT_PCM_32_BIT/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width 32/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $OUTPUTPOLICY
    #end patching deep_buffer
    fi

    if [ "$BITNES" == "float" ]; then
      #start patching deep_buffer
      sed -i '/deep_buffer/,/direct_pcm_16/s/formats .*/AUDIO_FORMAT_PCM_FLOAT/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/bit_width .*/bit_width float/' $OUTPUTPOLICY
      sed -i '/deep_buffer/,/direct_pcm_16/s/sampling_rates .*/sampling_rates 44100|48000|88200|96000|176400|192000|352800|384000/' $OUTPUTPOLICY
    #end patching deep_buffer
    fi
    sed -i '/^ *#/d; /^ *$/d' $OUTPUTPOLICY
  ) &
done

#patching audio_policy_configuration
for OAUDIOPOLICY in ${AUDIOPOLICYS}; do
  (
    AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OAUDIOPOLICY $AUDIOPOLICY
    sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
    if [ "$BITNES" != "Skip" ] || [ "$SAMPLERATE" != "Skip" ]; then
      case $SAMPLERATE in
      "96000")
        samplingRates="44100,48000,96000"
        ;;
      "192000")
        samplingRates="44100,48000,96000,192000"
        ;;
      "384000")
        samplingRates="44100,48000,96000,192000,384000"
        ;;
      *)
        samplingRates="44100,48000"
        ;;
      esac
      case $BITNES in
      "24")
        sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>\
                    <profile name="" format="AUDIO_FORMAT_PCM_8_24_BIT"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $AUDIOPOLICY
        sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>\
                    <profile name="" format="AUDIO_FORMAT_PCM_8_24_BIT"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $AUDIOPOLICY
        ;;
      "32")
        sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $AUDIOPOLICY
        sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $AUDIOPOLICY
        ;;
      "float")
        sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_FLOAT"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $AUDIOPOLICY
        sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_FLOAT"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $AUDIOPOLICY
        ;;
      *)
        sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $AUDIOPOLICY
        sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT"\
                             samplingRates="'$samplingRates'"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO,AUDIO_CHANNEL_OUT_MONO"/>' $AUDIOPOLICY
        ;;
      esac
    fi
    sed -i '/^ *#/d; /^ *$/d' $AUDIOPOLICY
  ) &
done

#patching media codecs files
for OMCODECS in ${MCODECS}; do
  (
    MEDIACODECS="$MODPATH$(echo $OMCODECS | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OMCODECS $MEDIACODECS
    sed -i 's/name="sample-rate" ranges=".*"/name="sample-rate" ranges="1-655350"/g' $MEDIACODECS
    sed -i 's/name="bitrate-modes" value="CBR"/name="bitrate-modes" value="CQ"/g' $MEDIACODECS
    sed -i 's/name="complexity" range="0-10"  default=".*"/name="complexity" range="0-10"  default="10"/g' $MEDIACODECS
    sed -i 's/name="complexity" range="0-8"  default=".*"/name="complexity" range="0-8"  default="8"/g' $MEDIACODECS
    sed -i 's/name="quality" range="0-100"  default=".*"/name="quality" range="0-100"  default="100"/g' $MEDIACODECS
    sed -i 's/name="bitrate" range=".*"/name="bitrate" range="1-21000000"/g' $MEDIACODECS
    sed -i '/^ *#/d; /^ *$/d' $MEDIACODECS
  ) &
done

for OMIX in ${MPATHS}; do
  (
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OMIX $MIX
    if [ "$VOLMEDIA" != "Skip" ]; then
      sed -i 's/\(name="RX[0-8] Digital Volume" value="\)[^"]*"/\1'$VOLMEDIA'"/g' $MIX
      sed -i 's/\(name="WSA_RX[0-3] Digital Volume" value="\)[^"]*"/\1'$VOLMEDIA'"/g' $MIX
      sed -i 's/\(name="RX_RX[0-3] Digital Volume" value="\)[^"]*"/\1'$VOLMEDIA'"/g' $MIX
    fi

    if [ "$STEP13" == "true" ]; then
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
      sed -i 's/\(name="IIR0 Enable Band[0-5]" value="\)[^"]*"/\11"/g' $MIX
      sed -i 's/\(name="IIR0 INP[0-5] Volume" value="\)[^"]*"/\154"/g' $MIX
      sed -i 's/\(name="IIR0 INP[0-3] MUX" value="\)[^"]*"/\1RX2"/g' $MIX
    fi

    if [ "$VOLMIC" != "Skip" ]; then
      sed -i 's/\(name="ADC[0-4] Volume" value="\)[^"]*"/\112"/g' $MIX
      sed -i 's/\(name="DEC[0-8] Volume" value="\)[^"]*"/\1'$VOLMIC'"/g' $MIX
      sed -i 's/\(name="TX_DEC[0-8] Volume" value="\)[^"]*"/\1'$VOLMIC'"/g' $MIX
    fi

    if [ "$STEP6" == "true" ]; then
      sed -i 's/\(COMP[0-8]* Switch" value="\)1"/\10"/g' $MIX
      sed -i 's/\(WSA_COMP[1-8] Switch" value="\)1"/\10"/g' $MIX
      sed -i 's/\(RX_COMP[1-8] Switch" value="\)1"/\10"/g' $MIX
      sed -i 's/"HPHL_COMP Switch" value="1"/"HPHL_COMP Switch" value="0"/g' $MIX
      sed -i 's/"HPHR_COMP Switch" value="1"/"HPHR_COMP Switch" value="0"/g' $MIX
      sed -i 's/"HPHL Compander" value="1"/"HPHL Compander" value="0"/g' $MIX
      sed -i 's/"HPHR Compander" value="1"/"HPHR Compander" value="0"/g' $MIX
      sed -i 's/\(Softclip[0-8] Enable" value="\)0"/\11"/g' $MIX
      sed -i 's/\(RX_Softclip[0-7]* Enable" value="\)0"/\11"/g' $MIX
      sed -i 's/\(WSA_Softclip[0-7] Enable" value="\)0"/\11"/g' $MIX
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
      sed -i 's/\(RX INT[0-4] DEM MUX" value="\)NORMAL_DSM_OUT"/\1CLSH_DSM_OUT"/g' $MIX
    fi

    if [ "$STEP9" == "true" ]; then
      if [ "$HIFI" == "true" ]; then
        sed -i 's/\(name="RX[1-7] HPF cut off" value="\)[^"]*"/\1CF_NEG_3DB_4HZ"/g' $MIX
        sed -i 's/\(name="TX[1-7] HPF cut off" value="\)[^"]*"/\1CF_NEG_3DB_4HZ"/g' $MIX
        sed -i 's/name="RX_HPH_PWR_MODE" value=".*"/name="RX_HPH_PWR_MODE" value="LOHIFI"/g' $MIX
        sed -i 's/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="CLS_H_LOHIFI"/g' $MIX
      else
        sed -i 's/\(name="RX[1-5] HPF cut off" value="\)[^"]*"/\1MIN_3DB_4Hz"/g' $MIX
        sed -i 's/\(name="TX[1-5] HPF cut off" value="\)[^"]*"/\1MIN_3DB_4Hz"/g' $MIX
        sed -i 's/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="HD2"/g' $MIX
        sed -i 's/name="RX HPH HD2 Mode" value=".*"/name="RX HPH HD2 Mode" value="On"/g' $MIX
      fi

      # [ "$RN5PRO", "$MI9", "$MI8", "$MI8P", "$MI9P", "$MIA2" ]
      case "$DEVICE" in "whyred" | "cepheus" | "dipper" | "equuleus" | "crux" | "jasmine")
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
      sed -i 's/name="PowerCtrl" value=".*"/name="PowerCtrl" value="0"/g' $MIX
      sed -i 's/name="DSD_L Switch" value=".*"/name="DSD_L Switch" value="1"/g' $MIX
      sed -i 's/name="DSD_R Switch" value=".*"/name="DSD_R Switch" value="1"/g' $MIX
      sed -i 's/name="RCV AMP PCM Gain" value=".*"/name="RCV AMP PCM Gain" value="20"/g' $MIX
      sed -i 's/name="AMP PCM Gain" value=".*"/name="AMP PCM Gain" value="20"/g' $MIX
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

      # [ "$PIXEL6a", "$PIXEL6", "$PIXEL6Pro", "$PIXEL7", "$PIXEL7Pro", "$PIXEL8", "$PIXEL8Pro" ]
      case "$DEVICE" in "bluejay" | "oriel" | "raven" | "cheetah" | "panther" | "shiba" | "husky")
        sed -i 's/name="AMP PCM Gain" value=".*"/name="AMP PCM Gain" value="14"/g' $MIX
        sed -i 's/name="Digital PCM Volume" value=".*"/name="Digital PCM Volume" value="865"/g' $MIX
        sed -i 's/name="Boost Peak Current Limit" value=".*"/name="Boost Peak Current Limit" value="3.50A"/g' $MIX
        ;;
      esac

      # [ "$MI11U", "$MI14U", "$ONEPLUS11GLOBAL", "$MI13U", "$POCOM3", "$R9T", "$RN10", "$RN10PRO", "$RN10PROMAX", "$RN8T", "$A71", "$RMEGTNEO2", "$RMEGTNEO3T", "$ONEPLUS9RT", "$S22U", "$POCOF5", "$RN9PRO", "$RN9S", "$POCOM2P" ]
      case "$DEVICE" in "star" | "mivendor" | "OP594DL1" | "citrus" | "lime" | "chime" | "juice" | "mojito" | "sweet" | "sweetin" | "willow" | "A71" | "RE5473" | "RE879AL1" | "kona" | "RE54E4L1" | "OnePlus9RT" | "b0q" | "marble" | "joyeuse" | "curtana" | "gram")
        sed -i 's/name="RX HPH Mode" value=".*"/name="RX HPH Mode" value="CLS_H_HIFI"/g' $MIX
        ;;
      esac
    fi
    sed -i '/^ *#/d; /^ *$/d' $MIX
    #end mixer patching function
  ) &
done

for OARESOURCES in ${RESOURCES}; do
  (
    RES="$MODPATH$(echo $OARESOURCES | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
    cp_ch -f $ORIGDIR$OARESOURCES $RES
    sed -i 's/<param key="hifi_filter" value="false"/<param key="hifi_filter" value="true"/g' $RES
    sed -i 's/<speaker_protection_enabled>1/<speaker_protection_enabled>0/g' $RES
    # bootloop issue sed -i '/_HEADPHONE<\/id>/,/        -->/{/        <!--HIFI Filter Headphones-Uncomment this when param key hifi_filter is true/d; /        -->/d}' $RES
  ) &
done

if [ "$VOLSTEPS" != "Skip" ]; then
  (
    echo -e "\nro.config.media_vol_steps=$VOLSTEPS" >>$PROP
  ) &
fi

if [ "$STEP14" == "true" ]; then
  (
    echo -e "\n
# Disable all effects by NLSound Team
ro.audio.ignore_effects=true
ro.vendor.audio.ignore_effects=true
vendor.audio.ignore_effects=true
persist.audio.ignore_effects=true
persist.vendor.audio.ignore_effects=true
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
BPF=Off" >>$PROP
  ) &
fi

if [ "$STEP15" == "true" ]; then
  (
    # [ "$POCOF3", "$POCOF4GT", "$ONEPLUS9R", "$ONEPLUS9Pro" ]
    case "$DEVICE" in "alioth" | "ingres" | "OnePlus9R" | "OnePlus9Pro")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S24_LE
tinymix "USB_AUDIO_RX Format" S24_3LE
tinymix "USB_AUDIO_TX Format" S24_3LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_96
tinymix "USB_AUDIO_TX SampleRate" KHZ_96
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_MI2S_RX Format" S24_3LE
tinymix "TERT_MI2S_TX Format" S24_3LE
tinymix "TERT_MI2S_RX SampleRate" KHZ_96
tinymix "TERT_MI2S_TX SampleRate" KHZ_96 
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_0 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_1 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "TX_CDC_DMA_TX_3 Format" S24_3LE
tinymix "TX_CDC_DMA_TX_4 Format" S24_3LE
tinymix "TX_CDC_DMA_TX_3 SampleRate" KHZ_96
tinymix "TX_CDC_DMA_TX_4 SampleRate" KHZ_96
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
tinymix "Cirrus SP Channel Swap Duration" 9600
tinymix "Display Port RX Bit Format" S24_3LE
tinymix "Display Port1 RX Bit Format" S24_3LE
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
tinymix "RCV Noise Gate" 16382
tinymix "Noise Gate" 16382
tinymix "AUX_HPF Enable" 0
tinymix "SLIM9_TX ADM Channels" Two
tinymix "Voip Evrc Min Max Rate Config" 4 4
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$POCOX3Pro" ]
    case "$DEVICE" in "vayu")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "ASM Bit Width" 32
tinymix "AFE Input Bit Format" S24_3LE
tinymix "USB_AUDIO_RX Format" S24_3LE
tinymix "USB_AUDIO_TX Format" S24_3LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_384
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S24_3LE
tinymix "TERT_TDM_RX_1 Format" S24_3LE
tinymix "TERT_MI2S_RX Format" S24_3LE
tinymix "TERT_MI2S_TX Format" S24_3LE
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
tinymix "WSA_CDC_DMA_RX_0 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_1 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S24_LE
tinymix "SLIM_6_RX Format" S24_LE
tinymix "SLIM_0_RX Format" S24_LE
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
tinymix "TAS256X PLAYBACK VOLUME LEFT" 56
tinymix "TAS256X LIM MAX ATTN LEFT" 0
tinymix "TAS256X LIM INFLECTION POINT LEFT" 0
tinymix "TAS256X LIM ATTACT RATE LEFT" 0
tinymix "TAS256X LIM RELEASE RATE LEFT" 7
tinymix "TAS256X LIM ATTACK STEP LEFT" 0
tinymix "TAS256X LIM RELEASE STEP LEFT" 3
tinymix "TAS256X RX MODE LEFT" Speaker
tinymix "TAS256X BOOST VOLTAGE LEFT" 15
tinymix "TAS256X BOOST CURRENT LEFT" 59
tinymix "TAS256X PLAYBACK VOLUME RIGHT" 56
tinymix "TAS256X LIM MAX ATTN RIGHT" 0
tinymix "TAS256X LIM INFLECTION POINT RIGHT" 0
tinymix "TAS256X LIM ATTACT RATE RIGHT" 0
tinymix "TAS256X LIM RELEASE RATE RIGHT" 7
tinymix "TAS256X LIM ATTACK STEP RIGHT" 0
tinymix "TAS256X LIM RELEASE STEP RIGHT" 3
tinymix "TAS256X BOOST VOLTAGE RIGHT" 12
tinymix "TAS256X BOOST CURRENT RIGHT" 55
tinymix "TAS256X VBAT LPF LEFT" DISABLE
tinymix "TAS256X VBAT LPF RIGHT" DISABLE
tinymix "TAS256x Profile id" 1
tinymix "TAS25XX_SMARTPA_ENABLE" ENABLE
tinymix "Amp Output Level" 22
tinymix "TAS25XX_ALGO_PROFILE" MUSIC
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$MI11U", "$ONEPLUS11GLOBAL", "$MI13U", "$MI14U" ]
    case "$DEVICE" in "star" | "OP594DL1" | "mivendor")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "ASM Bit Width" 32
tinymix "AFE Input Bit Format" S24_LE
tinymix "USB_AUDIO_RX Format" S24_3LE
tinymix "USB_AUDIO_TX Format" S24_3LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_192
tinymix "USB_AUDIO_TX SampleRate" KHZ_192
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S24_3LE
tinymix "TERT_TDM_RX_1 Format" S24_3LE
tinymix "TERT_MI2S_RX Format" S24_3LE
tinymix "TERT_MI2S_TX Format" S24_3LE
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
tinymix "WSA_CDC_DMA_RX_0 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_1 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_192
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_192
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S24_3LE
tinymix "SLIM_6_RX Format" S24_3LE
tinymix "SLIM_0_RX Format" S24_3LE
tinymix "SLIM_0_TX Format" S24_3LE
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
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "RCV Noise Gate" 16383
tinymix "Noise Gate" 16383
tinymix "DS2 OnOff" 1
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$POCOM3", "$R9T" ]
    case "$DEVICE" in "citrus" | "juice" | "chime" | "lime")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S32_LE
tinymix "USB_AUDIO_RX Format" S32_LE
tinymix "USB_AUDIO_TX Format" S32_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_96
tinymix "USB_AUDIO_TX SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_96
tinymix "TX_CDC_DMA_TX_3 Format" S24_3LE
tinymix "TX_CDC_DMA_TX_4 Format" S32_LE
tinymix "TX_CDC_DMA_TX_3 SampleRate" KHZ_96
tinymix "TX_CDC_DMA_TX_4 SampleRate" KHZ_96
tinymix "DEC0 MODE" ADC_HIGH_PERF
tinymix "DEC1 MODE" ADC_HIGH_PERF
tinymix "DEC2 MODE" ADC_HIGH_PERF
tinymix "DEC3 MODE" ADC_HIGH_PERF
tinymix "LPI Enable" 0
tinymix "Playback 0 Compress" 0
tinymix "Playback 4 Compress" 0
tinymix "Playback 9 Compress" 0
tinymix "Compress Playback 11 Volume" 0
tinymix "Compress Playback 25 Volume" 0
tinymix "Compress Playback 26 Volume" 0
tinymix "Compress Playback 27 Volume" 0
tinymix "Compress Playback 28 Volume" 0
tinymix "Compress Playback 36 Volume" 0
tinymix "Compress Gapless Playback" 0
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "EC Reference Channels" Two
tinymix "EC Reference Bit Format" S24_LE
tinymix "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix "RX_HPH_PWR_MODE" LOHIFI
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "RX_Softclip Enable" 1
tinymix "DS2 OnOff" 1
tinymix "HPH Idle Detect" ON
tinymix "Set Custom Stereo OnOff" 1
tinymix "AUX_HPF Enable" 0
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$POCOX3" ]
    case "$DEVICE" in "surya")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S24_LE
tinymix "USB_AUDIO_RX Format" S24_3LE
tinymix "USB_AUDIO_TX Format" S24_3LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_96
tinymix "USB_AUDIO_TX SampleRate" KHZ_96
tinymix "TERT_TDM_RX_0 Format" S24_3LE
tinymix "TERT_TDM_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_96
tinymix "Playback 0 Compress" 0
tinymix "Playback 1 Compress" 0
tinymix "Playback 4 Compress" 0
tinymix "Playback 13 Compress" 0
tinymix "Playback 16 Compress" 0
tinymix "Playback 27 Compress" 0
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
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "DS2 OnOff" 1
tinymix "TAS256X PLAYBACK VOLUME LEFT" 56
tinymix "TAS256X LIM MAX ATTN LEFT" 0
tinymix "TAS256X LIM INFLECTION POINT LEFT" 0
tinymix "TAS256X LIM ATTACT RATE LEFT" 0
tinymix "TAS256X LIM RELEASE RATE LEFT" 7
tinymix "TAS256X LIM ATTACK STEP LEFT" 0
tinymix "TAS256X LIM RELEASE STEP LEFT" 3
tinymix "TAS256X RX MODE LEFT" Speaker
tinymix "TAS256X BOOST VOLTAGE LEFT" 12
tinymix "TAS256X BOOST CURRENT LEFT" 56
tinymix "TAS256X PLAYBACK VOLUME RIGHT" 56
tinymix "TAS256X LIM MAX ATTN RIGHT" 0
tinymix "TAS256X LIM INFLECTION POINT RIGHT" 0
tinymix "TAS256X LIM ATTACT RATE RIGHT" 0
tinymix "TAS256X LIM RELEASE RATE RIGHT" 7
tinymix "TAS256X LIM ATTACK STEP RIGHT" 
tinymix "TAS256X LIM RELEASE STEP RIGHT" 3
tinymix "TAS256X BOOST VOLTAGE RIGHT" 12
tinymix "TAS256X BOOST CURRENT RIGHT" 56
tinymix "TAS256X VBAT LPF LEFT" DISABLE
tinymix "TAS256X VBAT LPF RIGHT" DISABLE
tinymix "TAS256x Profile id" 1
tinymix "TAS25XX_SMARTPA_ENABLE" ENABLE
tinymix "Amp Output Level" 22
tinymix "TAS25XX_ALGO_PROFILE" MUSIC
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$RN10", "$RN10PRO", "$RN10PROMAX", "$RN8T", "$A71", "$RMEGTNEO3T", "$ONEPLUS9RT" ]
    case "$DEVICE" in "mojito" | "sweet" | "sweetin" | "willow" | "A71" | "RE54E4L1" | "OnePlus9RT")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S24_LE
tinymix "USB_AUDIO_RX Format" S32_LE
tinymix "USB_AUDIO_TX Format" S32_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_96
tinymix "USB_AUDIO_TX SampleRate" KHZ_96
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S24_LE
tinymix "TERT_TDM_RX_1 Format" S24_LE
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_0 Format" S24_LE
tinymix "WSA_CDC_DMA_RX_1 Format" S24_LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S24_LE
tinymix "SLIM_6_RX Format" S24_LE
tinymix "SLIM_0_RX Format" S24_LE
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
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "RX_Softclip Enable" 1
tinymix "RCV Noise Gate" 16383
tinymix "Noise Gate" 16383
tinymix "DS2 OnOff" 1
tinymix "aw882_xx_rx_switch" Enable
tinymix "aw882_xx_tx_switch" Enable
tinymix "aw882_copp_switch" Enable
tinymix "aw_dev_0_prof" Receiver
tinymix "aw_dev_0_switch" Enable
tinymix "aw_dev_1_prof" Receiver
tinymix "aw_dev_1_switch" Enable
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$RMEGTNEO2" ]
    case "$DEVICE" in "RE5473" | "RE879AL1" | "kona")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S24_LE
tinymix "USB_AUDIO_RX Format" S24_LE
tinymix "USB_AUDIO_TX Format" S24_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_96
tinymix "USB_AUDIO_TX SampleRate" KHZ_96
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S24_LE
tinymix "TERT_TDM_RX_1 Format" S24_LE
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_0 Format" S24_LE
tinymix "WSA_CDC_DMA_RX_1 Format" S24_LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S24_LE
tinymix "SLIM_6_RX Format" S24_LE
tinymix "SLIM_0_RX Format" S24_LE
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
tinymix "Playback 4 Compress" 0
tinymix "Playback 9 Compress" 0
tinymix "Compress Playback 11 Volume" 0
tinymix "Compress Playback 25 Volume" 0
tinymix "Compress Playback 26 Volume" 0
tinymix "Compress Playback 27 Volume" 0
tinymix "Compress Playback 28 Volume" 0
tinymix "Compress Playback 37 Volume" 0
tinymix "Cirrus SP Load Config" Load
tinymix "Display Port RX Bit Format" S24_3LE
tinymix "Display Port1 RX Bit Format" S24_3LE
tinymix "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "RCV Noise Gate" 16383
tinymix "Noise Gate" 16383
tinymix "DS2 OnOff" 1
tinymix "aw882_xx_rx_switch" Enable
tinymix "aw882_xx_tx_switch" Enable
tinymix "aw882_copp_switch" Enable
tinymix "aw_dev_0_prof" Receiver
tinymix "aw_dev_0_switch" Enable
tinymix "aw_dev_1_prof" Receiver
tinymix "aw_dev_1_switch" Enable
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$S22U" ]
    case "$DEVICE" in "b0q")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "ASM Bit Width" 32
tinymix "AFE Input Bit Format" S24_LE
tinymix "USB_AUDIO_RX Format" S24_LE
tinymix "USB_AUDIO_TX Format" S24_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_96
tinymix "USB_AUDIO_TX SampleRate" KHZ_96
tinymix "RCV PCM Source" DSP
tinymix "PCM Source" DSP
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "TERT_TDM_RX_0 Format" S24_3LE
tinymix "TERT_TDM_RX_1 Format" S24_3LE
tinymix "TERT_MI2S_RX Format" S24_3LE
tinymix "TERT_MI2S_TX Format" S24_3LE
tinymix "TERT_MI2S_RX SampleRate" KHZ_96
tinymix "TERT_MI2S_TX SampleRate" KHZ_96
tinymix "TERT MI2S RX Format" NATIVE_DSD_DATA
tinymix "TERT MI2S TX Format" NATIVE_DSD_DATA
tinymix "TERT_TDM_RX_0 Header Type" Entertainment 
tinymix "TERT_TDM_RX_1 Header Type" Entertainment 
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_0 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_1 Format" S24_3LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "SLIM_4_TX Format" DSD_DOP
tinymix "SLIM_2_RX Format" DSD_DOP
tinymix "SLIM_5_RX Format" S24_3LE
tinymix "SLIM_6_RX Format" S24_3LE
tinymix "SLIM_0_RX Format" S24_3LE
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
tinymix "RCV Noise Gate" 16383
tinymix "Noise Gate" 16383
tinymix "Haptics Source" A2H
tinymix "Static MCLK Mode" 24
tinymix "Force Frame32" 1
tinymix "A2H Tuning" 5
tinymix "LPI Enable" 0
tinymix "DMIC_RATE OVERRIDE" CLK_2P4MHZ
tinymix "DS2 OnOff" 1
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$POCOF5" ]
    case "$DEVICE" in "marble")
      echo -e '\n
audioserver=false
while :
do
tinymix "RX_Softclip Enable" 1
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_LOHIFI
tinymix "DEC0 MODE" ADC_HIGH_PERF
tinymix "DEC1 MODE" ADC_HIGH_PERF
tinymix "DEC2 MODE" ADC_HIGH_PERF
tinymix "DEC3 MODE" ADC_HIGH_PERF
tinymix "DEC4 MODE" ADC_HIGH_PERF
tinymix "DEC5 MODE" ADC_HIGH_PERF
tinymix "DEC6 MODE" ADC_HIGH_PERF
tinymix "DEC7 MODE" ADC_HIGH_PERF
tinymix "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix "RX_HPH HD2 Mode" ON
tinymix "RX_HPH_PWR_MODE" LOHIFI
tinymix "VA_DEC0 MODE" ADC_HIGH_PERF
tinymix "VA_DEC1 MODE" ADC_HIGH_PERF
tinymix "VA_DEC2 MODE" ADC_HIGH_PERF
tinymix "VA_DEC3 MODE" ADC_HIGH_PERF
tinymix "TX0 MODE" ADC_HIFI
tinymix "TX1 MODE" ADC_HIFI
tinymix "TX2 MODE" ADC_HIFI
tinymix "TX3 MODE" ADC_HIFI
tinymix "HPH Idle Detect" ON
tinymix "HDR12 MUX" HDR12
tinymix "HDR34 MUX" HDR34
tinymix "AUX_HPF Enable" 0
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$RN9PRO", "$RN9S", "$POCOM2P" ]
    case "$DEVICE" in "joyeuse" | "curtana" | "gram")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "Amp Output Level" 22
tinymix "TAS25XX_SMARTPA_ENABLE" DISABLE
tinymix "TAS25XX_ALGO_BYPASS" TRUE
tinymix "TAS25XX_ALGO_PROFILE" MUSIC
tinymix "TAS2562 IVSENSE ENABLE" On
tinymix "ASM Bit Width" 24
tinymix "AFE Input Bit Format" S24_LE
tinymix "USB_AUDIO_RX Format" S24_LE
tinymix "USB_AUDIO_TX Format" S24_LE
tinymix "USB_AUDIO_RX SampleRate" KHZ_96
tinymix "USB_AUDIO_TX SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_3 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_3 SampleRate" KHZ_96
tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_0 Format" S24_LE
tinymix "WSA_CDC_DMA_RX_1 Format" S24_LE
tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_96
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
tinymix "Playback 0 Compress" 0
tinymix "Playback 4 Compress" 0
tinymix "Playback 9 Compress" 0
tinymix "Display Port RX Bit Format" S24_3LE
tinymix "Display Port1 RX Bit Format" S24_3LE
tinymix "EC Reference Bit Format" S24_LE
tinymix "EC Reference Channels" Two
tinymix "TERT_MI2S_RX Format" S24_LE
tinymix "TERT_MI2S_TX Format" S24_LE
tinymix "TERT_MI2S_RX SampleRate" KHZ_96
tinymix "TERT_MI2S_TX SampleRate" KHZ_96
tinymix "Compress Playback 11 Volume" 0
tinymix "Compress Playback 25 Volume" 0
tinymix "Compress Playback 26 Volume" 0
tinymix "Compress Playback 27 Volume" 0
tinymix "Compress Playback 28 Volume" 0
tinymix "Compress Playback 37 Volume" 0
tinymix "Compress Gapless Playback" 0
tinymix "RX_HPH HD2 Mode" ON
tinymix "RX_HPH_PWR_MODE" LOHIFI
tinymix "RX INT0 DEM MUX" CLSH_DSM_OUT
tinymix "RX INT1 DEM MUX" CLSH_DSM_OUT
tinymix "SEN_MI2S_TX Format" S24_LE
tinymix "QUIN_MI2S_TX Format" S24_LE
tinymix "QUAT_MI2S_TX Format" S24_LE
tinymix "SEC_MI2S_TX Format" S24_LE
tinymix "PRIM_MI2S_TX Format" S24_LE
tinymix "SEN_MI2S_RX Format" S24_LE
tinymix "QUIN_MI2S_RX Format" S24_LE
tinymix "QUAT_MI2S_RX Format" S24_LE
tinymix "SEC_MI2S_RX Format" S24_LE
tinymix "PRIM_MI2S_RX Format" S24_LE
tinymix "SEN_MI2S_TX SampleRate" KHZ_96
tinymix "QUIN_MI2S_TX SampleRate" KHZ_96
tinymix "QUAT_MI2S_TX SampleRate" KHZ_96
tinymix "SEC_MI2S_TX SampleRate" KHZ_96
tinymix "PRIM_MI2S_TX SampleRate" KHZ_96
tinymix "SEN_MI2S_RX SampleRate" KHZ_96
tinymix "QUIN_MI2S_RX SampleRate" KHZ_96
tinymix "QUAT_MI2S_RX SampleRate" KHZ_96
tinymix "SEC_MI2S_RX SampleRate" KHZ_96
tinymix "PRIM_MI2S_RX SampleRate" KHZ_96
tinymix "VA_CDC_DMA_TX_2 SampleRate" KHZ_96
tinymix "VA_CDC_DMA_TX_1 SampleRate" KHZ_96
tinymix "VA_CDC_DMA_TX_0 SampleRate" KHZ_96
tinymix "TX_CDC_DMA_TX_4 SampleRate" KHZ_96
tinymix "TX_CDC_DMA_TX_3 SampleRate" KHZ_96
tinymix "TX_CDC_DMA_TX_0 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_TX_2 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_TX_1 SampleRate" KHZ_96
tinymix "WSA_CDC_DMA_TX_0 SampleRate" KHZ_96
tinymix "VA_CDC_DMA_TX_2 Format" S24_LE
tinymix "VA_CDC_DMA_TX_1 Format" S24_LE
tinymix "VA_CDC_DMA_TX_0 Format" S24_LE
tinymix "TX_CDC_DMA_TX_4 Format" S24_LE
tinymix "TX_CDC_DMA_TX_3 Format" S24_LE
tinymix "TX_CDC_DMA_TX_0 Format" S24_LE
tinymix "WSA_CDC_DMA_TX_2 Format" S24_LE
tinymix "WSA_CDC_DMA_TX_1 Format" S24_LE
tinymix "AUX_HPF Enable" 0
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac

    # [ "$PIXEL6a", "$PIXEL6", "$PIXEL6Pro", "$PIXEL7", "$PIXEL7Pro" ]
    case "$DEVICE" in "bluejay" | "oriel" | "raven" | "cheetah" | "panther")
      echo -e '\n
audioserver=false
while :
do
tinymix "HiFi Filter" 1
tinymix "RX_Softclip Enable" 1
tinymix "BT SampleRate" KHZ_96
tinymix "BT SampleRate RX" KHZ_96
tinymix "BT SampleRate TX" KHZ_96
tinymix "HPHL Volume" 20
tinymix "HPHR Volume" 20
tinymix "RX HPH Mode" CLS_H_HIFI
tinymix "AMP PCM Gain" 14
tinymix "Digital PCM Volume" 865
tinymix "Boost Peak Current Limit" 3.50A
if [ "$audioserver" == "false" ]; then
  kill $(pidof audioserver)
  audioserver=true
fi;
sleep 4
done
' >>$MODPATH/service.sh
      ;;
    esac
  ) &
fi

#patching dolby anus
if [ "$STEP16" == "true" ]; then
  (
    for OADAXES in ${DAXES}; do
      DAX="$MODPATH$(echo $OADAXES | sed "s|^/vendor|/system/vendor|g" | sed "s|^/system_ext|/system/system_ext|g" | sed "s|^/product|/system/product|g" | sed "s|^/my_product|/system/my_product|g" | sed "s|^/odm|/system/vendor/odm|g" | sed "s|^/mi_ext|/system/mi_ext|g")"
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
      sed -i 's/<regulator-enable value="true"/<volume-leveler-enable value="false"/g' $DAX
      sed -i 's/<regulator-speaker-dist-enable value="true"/<regulator-speaker-dist-enable value="false"/g' $DAX
      sed -i 's/<regulator-sibilance-suppress-enable value="true"/<regulator-sibilance-suppress-enable value="false"/g' $DAX
      sed -i 's/bass-mbdrc-enable value="true"/bass-mbdrc-enable value="false"/g' $DAX
      sed -i 's/threshold_low=".*" threshold_high=".*"/threshold_low="0" threshold_high="0"/g' $DAX
      sed -i 's/isolated_band="true"/isolated_band="false"/g' $DAX
      sed -i '/endpoint_type="headphone"/,/<\/tuning>/s/<audio-optimizer-enable value="true"/<audio-optimizer-enable value="false"/g' $DAX
      sed -i '/<output-mode>/,/<\/output-mode>' $DAX
      sed -i '/<mix_matrix>/,/</output-mode>' $DAX
    done
  ) &
fi

wait
ui_print " "
ui_print " - All done! With love, NLSound Team. - "
ui_print " "
