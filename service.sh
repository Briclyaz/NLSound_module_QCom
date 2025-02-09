#!/system/bin/sh

until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 4
done

settings put global audio_safe_volume_state 0

resetprop -p --delete media.resolution.limit.16bit
resetprop -p --delete media.resolution.limit.24bit
resetprop -p --delete media.resolution.limit.32bit

resetprop -p --delete audio.resolution.limit.16bit
resetprop -p --delete audio.resolution.limit.24bit
resetprop -p --delete audio.resolution.limit.32bit
