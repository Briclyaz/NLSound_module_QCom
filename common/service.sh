(

# restart
killall mediaserver
killall audioserver
killall audio-hal
killall /system/bin/hw/android.hardware.audio.service
killall audio-hal-2-0
killall /system/bin/hw/android.hardware.audio@2.0-service
killall audio-hal-4-0-msd
killall vendor.audio-hal
killall /vendor/bin/hw/android.hardware.audio.service
killall vendor.audio-hal-2-0
killall /vendor/bin/hw/android.hardware.audio@2.0-service
killall vendor.audio-hal-4-0-msd

) 2>/dev/null

sleep 60
su -lp 2000 -c "cmd notification post -S bigtext -t 'NLSound Notification' 'Tag' 'NLSound modification works, enjoy listening'"