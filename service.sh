#!/system/bin/sh

resetprop -w sys.boot_completed 0 && sleep 10

settings put global audio_safe_volume_state 0

resetprop -d media.resolution.limit.16bit
resetprop -d media.resolution.limit.24bit
resetprop -d media.resolution.limit.32bit

resetprop -d audio.resolution.limit.16bit
resetprop -d audio.resolution.limit.24bit
resetprop -d audio.resolution.limit.32bit
