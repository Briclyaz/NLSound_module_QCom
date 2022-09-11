(
# properties
#hresetprop vendor.audio.flac.sw.decoder.32bit true
resetprop vendor.audio.flac.sw.decoder.24bit true
#hresetprop audio.offload.pcm.32bit.enabled true
resetprop audio.offload.pcm.24bit.enabled true
resetprop audio.offload.pcm.16bit.enabled true
resetprop -p --delete persist.vendor.audio_hal.dsp_bit_width_enforce_mode
resetprop -n persist.vendor.audio_hal.dsp_bit_width_enforce_mode 24

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
