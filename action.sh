#!/system/bin/sh

handle_input() {
  while true; do
    case $(timeout 0.01 getevent -lqc 1 2>/dev/null) in
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
  while true; do
    eval "local current=\"\$$selected\""
    echo "➔ $current"
    echo " "
    case $(handle_input) in
      "up") selected=$((selected % total + 1)) ;;
      "down") break ;;
    esac
  done
  return $selected
}

open_file() {
  sleep 0.1
  am start -a android.intent.action.VIEW -d "file://$1" -t "text/plain" >/dev/null 2>&1 ;
}

open_tg() {
  sleep 0.1
  am start -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || \
  am start -a android.intent.action.VIEW -d "$2" >/dev/null 2>&1
}

LANG=$(settings get system system_locales)
if [[ "$LANG" =~ "ru-" ]]; then
  echo "  "
  echo "———————————————————————————————————————————"
  echo " "
  echo "            • NLSound Tools •"
  echo " "
  echo " Вспомогательные функции модуля, которые"
  echo "           могут быть полезны"
  echo " "
  echo "———————————————————————————————————————————"
  echo " [VOL+] Изменить выбор | [VOL-] Подтвердить"
  echo "———————————————————————————————————————————"
  echo " "
  echo "   1. Выйти"
  echo "   2. Дамп audio_flinger"
  echo "   3. Дамп tinymix"
  echo "   4. Перезагрузить аудиосервер"
  echo "   5. Вывести файловую структуру"
  echo "   6. Перейти в канал обновлений"
  echo "   7. Перейти в группу техподдержки"
  echo " "
  text='"Выйти" "Дамп audio_flinger" "Дамп tinymix" "Перезагрузить аудиосервер" "Вывести файловую структуру" "Канал обновлений" "Группа техподдержки"'
elif [[ "$LANG" =~ "zh-" ]]; then
  echo "  "
  echo "———————————————————————————————————————————"
  echo " "
  echo "              • NLSound 工具 •"
  echo " "
  echo "                模組的輔助功能， "
  echo "                  可能會有用"
  echo " "
  echo "———————————————————————————————————————————"
  echo "     [VOL+] - 變更選擇 | [VOL-] - 確認"
  echo "———————————————————————————————————————————"
  echo " "
  echo "   1. 退出"
  echo "   2. 傾印 audio_flinger"
  echo "   3. 傾印 tinymix"
  echo "   4. 重新啟動音訊伺服器"
  echo "   5. 顯示檔案結構"
  echo "   6. 前往更新頻道"
  echo "   7. 前往支援群組"
  echo " "
  text='"退出" "傾印 audio_flinger" "傾印 tinymix" "重新啟動音訊伺服器" "顯示檔案結構" "前往更新頻道" "前往支援群組"'
else
  echo "  "
  echo "———————————————————————————————————————————"
  echo " "
  echo "             • NLSound Tools •"
  echo " "
  echo "      Auxiliary module functions that"
  echo "              may be useful"
  echo " "
  echo "———————————————————————————————————————————"
  echo " [VOL+] Change selection | [VOL-] Confirm"
  echo "———————————————————————————————————————————"
  echo " "
  echo "   1. Exit"
  echo "   2. Dump audio_flinger"
  echo "   3. Dump tinymix"
  echo "   4. Restart audio server"
  echo "   5. Display file structure"
  echo "   6. Go to updates channel"
  echo "   7. Go to support group"
  echo " "
  text='"Exit" "Dump audio_flinger" "Dump tinymix" "Restart audio server" "Display file structure" "Updates channel" "Support group"'
fi

BASE_DIR="/storage/emulated/0/NLSound"
eval show_menu "$text"
case $? in
  1) exit 0 ;;
  2) dumpsys media.audio_flinger > "$BASE_DIR/flinger.txt"; open_file "$BASE_DIR/flinger.txt" ;;
  3) tinymix_new contents > "$BASE_DIR/tinymix.txt"; open_file "$BASE_DIR/tinymix.txt" ;;
  4) kill $(pidof audioserver) ;;
  5) tree "/data/adb/modules/NLSound" > "$BASE_DIR/tree.txt"; open_file "$BASE_DIR/tree.txt" ;;
  6) open_tg 'tg://resolve?domain=nlsound_updates' 'https://t.me/nlsound_updates' ;;
  7) open_tg 'tg://resolve?domain=nlsound_support' 'https://t.me/nlsound_support' ;;
esac
