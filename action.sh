#!/system/bin/sh

# ==============================================================================
#  NLSound Tools - Модуль расширенной диагностики и управления аудиосистемой
# ==============================================================================

MODPATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
DUMPS_DIR="$MODPATH/dumps"
SERVICE_SH="$MODPATH/service.sh"
mkdir -p "$DUMPS_DIR"

# Выбор доступной утилиты tinymix
if command -v tinymix_ext >/dev/null 2>&1; then
  TM_BIN="tinymix_ext"
else
  TM_BIN="tinymix"
fi

# ------------------------------------------------------------------------------
#  1. Универсальное автоопределение кнопок громкости
# ------------------------------------------------------------------------------
get_volume_event_node() {
  local dev
  for dev in /dev/input/event*; do
    [ -e "$dev" ] || continue
    if getevent -p "$dev" 2>/dev/null | grep -qE 'KEY_VOLUMEUP|KEY_VOLUMEDOWN'; then
      echo "$dev"
      return 0
    fi
  done
  echo "/dev/input/event2" # Fallback, если не определилось
}

EVENT_NODE=$(get_volume_event_node)

handle_input() {
  while true; do
    case $(getevent -lqc "$EVENT_NODE" 2>/dev/null | grep -m1 'DOWN') in
      *KEY_VOLUMEUP*)   echo "up"; return ;;
      *KEY_VOLUMEDOWN*) echo "down"; return ;;
    esac
  done
}

show_menu() {
  local selected=1
  local total=$#
  while true; do
    eval "local current=\"\$$selected\""
    echo "➔ $current"
    echo " "
    case $(handle_input) in
      "up")   selected=$((selected % total + 1)) ;;
      "down") return $selected ;;
    esac
  done
}

open_file() {
  sleep 0.1
  am start -a android.intent.action.VIEW -d "file://$1" -t "text/plain" >/dev/null 2>&1 || cat "$1"
}

open_tg() {
  sleep 0.1
  am start -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || \
  am start -a android.intent.action.VIEW -d "$2" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
#  2. Диагностические функции
# ------------------------------------------------------------------------------

# Проверка физического состояния аппаратного ЦАП (ALSA Kernel)
check_bitperfect() {
  local output="$DUMPS_DIR/bitperfect_status.txt"
  {
    echo "======================================================="
    echo "       АППАРАТНЫЙ СТАТУС ЦАП (ALSA /proc/asound)"
    echo "======================================================="
    echo "Время проверки: $(date)"
    echo "Примечание: Для фиксации Bit-Perfect запустите трек в плеере."
    echo "-------------------------------------------------------"

    local active_found=false
    for hw in /proc/asound/card*/pcm*p/sub*/hw_params; do
      if [ -f "$hw" ]; then
        local data
        data=$(cat "$hw" 2>/dev/null)
        if [ -n "$data" ] && [ "$data" != "closed" ]; then
          active_found=true
          echo "[АКТИВНЫЙ ТРАКТ]: $hw"
          echo "$data"
          echo "-------------------------------------------------------"
        fi
      fi
    done

    if [ "$active_found" = false ]; then
      echo "Статус: Все аппаратные аудио-тракты закрыты (звук не играет)."
      echo "Включите воспроизведение музыки и повторите тест."
    fi
  } > "$output"

  open_file "$output"
}

# Проверка активного Bluetooth A2DP кодека и его параметров
check_bluetooth() {
  local output="$DUMPS_DIR/bluetooth_status.txt"
  {
    echo "======================================================="
    echo "           ТЕКУЩИЙ СТАТУС BLUETOOTH A2DP"
    echo "======================================================="
    echo "Время: $(date)"
    echo "-------------------------------------------------------"
    echo "--- [1] Текущий активный кодек и конфигурация стека ---"
    dumpsys audio 2>/dev/null | grep -A 10 -i "A2DP current codec"
    echo ""
    echo "--- [2] Статус службы Bluetooth A2DP ---"
    dumpsys bluetooth_manager 2>/dev/null | grep -A 25 -i "A2DP state"
  } > "$output"

  open_file "$output"
}

# Проверка цепочек аудиоэффектов в AudioFlinger
check_effects() {
  local output="$DUMPS_DIR/effects_status.txt"
  {
    echo "======================================================="
    echo "         ЦЕПОЧКИ ЭФФЕКТОВ (AUDIOFLINGER EFFECT CHAINS)"
    echo "======================================================="
    echo "Время: $(date)"
    echo "Если эффект-процессинг отключен (Step 13), секции должны быть пусты."
    echo "-------------------------------------------------------"
    dumpsys media.audio_flinger 2>/dev/null | grep -A 25 -E "Effect Chains|effects:"
  } > "$output"

  open_file "$output"
}

# Глубокий перезапуск аудиосервера и вендорных HAL
restart_audio_stack() {
  echo " "
  echo "Перезапуск звуковой подсистемы..."
  # Остановка вендорных HAL чипсета
  pkill -f -9 "android.hardware.audio.*service" 2>/dev/null
  pkill -f -9 "vendor.qti.audio-hal" 2>/dev/null
  # Остановка AudioFlinger / Audioserver
  killall -9 audioserver 2>/dev/null || kill -9 $(pidof audioserver) 2>/dev/null
  sleep 1.5
  echo "Аудиостек успешно перезагружен!"
  sleep 1
}

# Сбор единого отчета для техподдержки
create_support_pack() {
  local report_dir="$DUMPS_DIR/support_pack"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local archive="/sdcard/NLSound_Report_${timestamp}.tar.gz"

  rm -rf "$report_dir"
  mkdir -p "$report_dir"

  echo " "
  echo "Сбор диагностических данных... Пожалуйста, подождите."

  dumpsys media.audio_flinger > "$report_dir/audio_flinger.txt" 2>&1
  dumpsys media.audio_policy > "$report_dir/audio_policy.txt" 2>&1
  "$TM_BIN" contents > "$report_dir/tinymix_contents.txt" 2>&1
  getprop > "$report_dir/system_props.txt" 2>&1
  dmesg | grep -iE 'audio|snd|codec|wcd|tas25|tfa|aw88' > "$report_dir/dmesg_audio.txt" 2>&1
  logcat -d -s AudioFlinger:V AudioPolicyManager:V > "$report_dir/logcat_audio.txt" 2>&1
  [ -f "$SERVICE_SH" ] && cp "$SERVICE_SH" "$report_dir/service.sh"

  tar -czf "$archive" -C "$DUMPS_DIR" "support_pack" 2>/dev/null
  rm -rf "$report_dir"

  echo " "
  echo "======================================================="
  echo "Отчет готов и сохранен:"
  echo "$archive"
  echo "Отправьте этот архив в группу техподдержки."
  echo "======================================================="
  sleep 3
}

# Оригинальная проверка 14 пункта модуля
tinymix_check() {
(
    OUTPUT="$DUMPS_DIR/tinymix_check.txt"
    TMP_DIR="$DUMPS_DIR/tinymix_tmp"
    EXP="$TMP_DIR/expected.txt"
    CNT="$TMP_DIR/contents.txt"
    mkdir -p "$TMP_DIR"

    if ! grep -q '^tinymix_ext set' "$SERVICE_SH"; then
        echo "No tinymix settings found in service.sh" >"$OUTPUT"
        open_file "$OUTPUT"; rm -rf "$TMP_DIR"; return 0
    fi

    awk -F'"' '/^tinymix_ext set/{
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3)
        print $2 "|" $3
    }' "$SERVICE_SH" >"$EXP"

    "$TM_BIN" contents >"$CNT"

    awk  -v h1="$header_control"   -v h2="$header_expected" \
         -v h3="$header_actual"    -v h4="$header_status"   \
         -v st1="$stats_total"     -v st2="$stats_applied"  \
         -v st3="$stats_mismatched" -v st4="$stats_absent" \
         -v st5="$stats_novalue"   -v st6="$stats_invalid" '

    function dlen(s,  t){ t=s; gsub(/[\200-\277]/,"",t); return length(t) }
    function cell(str,w,  n){ printf "%s",str; for(n=w-dlen(str); n>0; n--) printf " " }
    function line(w1,w2,w3,w4,  i){
        for(i=0;i<w1;i++) printf "-"; printf "-+-"
        for(i=0;i<w2;i++) printf "-"; printf "-+-"
        for(i=0;i<w3;i++) printf "-"; printf "-+-"
        for(i=0;i<w4;i++) printf "-"; printf "\n"
    }

    BEGIN{
        FS="\t"
        cw=dlen(h1); ew=dlen(h2); aw=dlen(h3); sw=dlen(h4)
        ln=total=ok=fail=not_found=no_value=fail_bool=0
    }

    FNR==NR{
        if(NF<4||$4=="") next
        ctrl=$4; sub(/^[[:space:]]+|[[:space:]]+$/,"",ctrl)
        typemap[ctrl]=$2
        val=$NF; sub(/\(.*/,"",val); sub(/^[[:space:]]+|[[:space:]]+$/,"",val)
        valmap[ctrl]=val
        next
    }

    {
        split($0,a,"|")
        ctrl=a[1]; sub(/^[[:space:]]+|[[:space:]]+$/,"",ctrl)
        expected=a[2]; sub(/^[[:space:]]+|[[:space:]]+$/,"",expected)
        if(ctrl=="") next

        ln++

        if(expected==""){
            actual="-"; status="FAIL"; no_value++
        }
        else if(!(ctrl in typemap)){
            actual="-"; status="FAIL"; not_found++
        }
        else{
            type=typemap[ctrl]; value=valmap[ctrl]
            actual=value; status="FAIL"

            if(type=="BOOL"){
                if(value~/[Oo][Nn]/)          actual=1
                else if(value~/[Oo][Ff][Ff]/) actual=0
                if(expected~/^[01]$/) status=(expected==actual?"OK":"FAIL")
                else { fail_bool++; status="FAIL" }
            }
            else if(type=="ENUM"){
                n=split(value,b,">"); last=b[n]
                sub(/^[[:space:]]+|[[:space:]]+$/,"",last)
                split(last,c,/[, ]+/); actual=c[1]
                status=(expected==actual?"OK":"FAIL")
            }
            else if(type=="INT"||type=="BYTE"){
                tmp=value
                gsub(/[^0-9, ]/,"",tmp); gsub(/,/, " ",tmp)
                gsub(/[ ]+/," ",tmp); sub(/^[ ]| $/,"",tmp)
                m=split(tmp,d," "); actual=""
                for(i=1;i<=m;i++){
                    x=d[i]; sub(/^0+/,"",x); if(x=="")x=0
                    actual=actual (i>1?" ":"") x
                }
                status=(expected==actual?"OK":"FAIL")
            }
            else{
                actual=value
                status=(expected==actual?"OK":"FAIL")
            }
        }

        total++; if(status=="OK") ok++; else if(expected!="") fail++

        C1[ln]=ctrl; C2[ln]=expected; C3[ln]=actual; C4[ln]=status

        if(dlen(ctrl)    >cw) cw=dlen(ctrl)
        if(dlen(expected)>ew) ew=dlen(expected)
        if(dlen(actual)  >aw) aw=dlen(actual)
        if(dlen(status)  >sw) sw=dlen(status)
    }

    END{
        cell(h1,cw); printf " | "; cell(h2,ew); printf " | "
        cell(h3,aw); printf " | "; cell(h4,sw); printf "\n"
        line(cw,ew,aw,sw)

        for(i=1;i<=ln;i++){
            cell(C1[i],cw); printf " | "; cell(C2[i],ew); printf " | "
            cell(C3[i],aw); printf " | "; cell(C4[i],sw); printf "\n"
        }

        printf "\n%s: %d\n", st1,total
        if(ok)        printf "%s: %d\n", st2,ok
        if(fail)      printf "%s: %d\n", st3,fail
        if(not_found) printf "%s: %d\n", st4,not_found
        if(no_value)  printf "%s: %d\n", st5,no_value
        if(fail_bool) printf "%s: %d\n", st6,fail_bool
    }' "$CNT" "$EXP" >"$OUTPUT"

    open_file "$OUTPUT"
    rm -rf "$TMP_DIR"
)
}

# ------------------------------------------------------------------------------
#  3. Локализация и формирование интерфейса
# ------------------------------------------------------------------------------
LANG=$(settings get system system_locales)

if [[ "$LANG" =~ "ru-" ]]; then
  echo "  "
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " "
  echo "            • NLSound Tools •"
  echo " "
  echo "  Расширенный комплекс диагностики аудио"
  echo " "
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " [VOL+] Выбрать пункт | [VOL-] Подтвердить"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " "
  echo "   1. Выйти"
  echo "   2. Проверить Bit-Perfect (ALSA HW)"
  echo "   3. Проверить 14 пункт (Tinymix check)"
  echo "   4. Статус Bluetooth и кодеков"
  echo "   5. Проверить отключение эффектов"
  echo "   6. Полный дамп (Flinger, Tinymix, Props)"
  echo "   7. Глубокий перезапуск аудиостека"
  echo "   8. Собрать отчет для техподдержки (.tar.gz)"
  echo "   9. Перейти в канал обновлений"
  echo "   10. Перейти в группу техподдержки"
  echo " "
  text='"Выйти" "Проверить Bit-Perfect (ALSA)" "Проверить 14 пункт" "Статус Bluetooth" "Проверить эффекты" "Полный дамп" "Перезапуск аудиостека" "Собрать отчет (.tar.gz)" "Канал обновлений" "Группа техподдержки"'
  header_control="Настройка"
  header_expected="Ожидаемое"
  header_actual="Текущее"
  header_status="Результат"
  stats_total="Всего настроек"
  stats_applied="Применено верно"
  stats_mismatched="Не совпадает"
  stats_absent="Нет в системе"
  stats_novalue="Не задано значение"
  stats_invalid="Недопустимый формат"

elif [[ "$LANG" =~ "zh-" ]]; then
  echo " "
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " "
  echo "              • NLSound 工具 •"
  echo " "
  echo "             進階音訊診斷控制台"
  echo " "
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "     [VOL+] - 變更選擇 | [VOL-] - 確認"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " "
  echo "   1. 退出"
  echo "   2. 檢查 Bit-Perfect (ALSA 硬體)"
  echo "   3. 檢查第 14 項 (Tinymix check)"
  echo "   4. 藍牙與編解碼器狀態"
  echo "   5. 檢查音訊效果鏈"
  echo "   6. 完整傾印 (Flinger, Tinymix, Props)"
  echo "   7. 深度重啟音訊堆疊"
  echo "   8. 匯出技術支援報告 (.tar.gz)"
  echo "   9. 前往更新頻道"
  echo "   10. 前往支援群組"
  echo " "
  text='"退出" "檢查 Bit-Perfect (ALSA)" "檢查第 14 項" "藍牙狀態" "檢查音效鏈" "完整傾印" "重啟音訊堆疊" "匯出支援報告 (.tar.gz)" "前往更新頻道" "前往支援群組"'
  header_control="Control"
  header_expected="Expected"
  header_actual="Actual"
  header_status="Status"
  stats_total="總設定數"
  stats_applied="正確套用"
  stats_mismatched="數值不符"
  stats_absent="缺席的"
  stats_novalue="無設定值"
  stats_invalid="格式錯誤"

else
  echo "  "
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " "
  echo "             • NLSound Tools •"
  echo " "
  echo "        Advanced Audio Diagnostics Suite"
  echo " "
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " [VOL+] Change selection | [VOL-] Confirm"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " "
  echo "   1. Exit"
  echo "   2. Check Bit-Perfect (ALSA HW)"
  echo "   3. Check item 14 (Tinymix check)"
  echo "   4. Bluetooth & Codec Status"
  echo "   5. Check Effect Chains"
  echo "   6. Full Dump (Flinger, Tinymix, Props)"
  echo "   7. Deep Audio Stack Restart"
  echo "   8. Create Support Report (.tar.gz)"
  echo "   9. Go to updates channel"
  echo "   10. Go to support group"
  echo " "
  text='"Exit" "Check Bit-Perfect (ALSA)" "Check item 14" "Bluetooth Status" "Check Effects" "Full Dump" "Restart Audio Stack" "Create Report (.tar.gz)" "Updates channel" "Support group"'
  header_control="Control"
  header_expected="Expected"
  header_actual="Actual"
  header_status="Status"
  stats_total="Total settings"
  stats_applied="Applied correctly"
  stats_mismatched="Mismatched"
  stats_absent="Absent"
  stats_novalue="No value"
  stats_invalid="Invalid format"
fi

# ------------------------------------------------------------------------------
#  4. Обработка выбора пользователя
# ------------------------------------------------------------------------------
eval show_menu "$text"
case $? in
  1) 
    exit 0 
    ;;
  2) 
    check_bitperfect 
    ;;
  3) 
    tinymix_check 
    ;;
  4) 
    check_bluetooth 
    ;;
  5) 
    check_effects 
    ;;
  6) 
    dumpsys media.audio_flinger > "$DUMPS_DIR/flinger.txt"
    "$TM_BIN" contents > "$DUMPS_DIR/tinymix.txt"
    getprop > "$DUMPS_DIR/props.txt"
    echo "Дампы сохранены в $DUMPS_DIR"
    open_file "$DUMPS_DIR/flinger.txt"
    ;;
  7) 
    restart_audio_stack 
    ;;
  8) 
    create_support_pack 
    ;;
  9) 
    open_tg 'tg://resolve?domain=nlsound_updates' 'https://t.me/nlsound_updates' 
    ;;
  10) 
    open_tg 'tg://resolve?domain=nlsound_support' 'https://t.me/nlsound_support' 
    ;;
esac