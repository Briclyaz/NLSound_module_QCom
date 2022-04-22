(

MODPATH=${0%/*}

# properties
#hresetprop vendor.audio.flac.sw.decoder.32bit true
resetprop vendor.audio.flac.sw.decoder.24bit true
#hresetprop audio.offload.pcm.32bit.enabled true
resetprop audio.offload.pcm.24bit.enabled true
resetprop audio.offload.pcm.16bit.enabled true
resetprop -p --delete persist.vendor.audio_hal.dsp_bit_width_enforce_mode
resetprop -n persist.vendor.audio_hal.dsp_bit_width_enforce_mode 24

# restart
PROP=`getprop ro.build.version.sdk`
if [ "$PROP" -ge 24 ]; then
  killall audioserver
else
  killall mediaserver
fi

) 2>/dev/null