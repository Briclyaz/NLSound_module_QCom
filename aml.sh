MODPATH=${0%/*}

# destinations
MODAPC=`find $MODPATH/system -type f -name *policy*.conf`
MODAPX=`find $MODPATH/system -type f -name *policy*.xml`
MODAPI=`find $MODPATH/system -type f -name *audio*platform*info*.xml`

# patch audio policy conf
if [ "$MODAPC" ]; then
  if ! grep -Eq deep_buffer_24 $MODAPC; then
    sed -i '/^outputs/a\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates 44100|48000\
    bit_width 24\
    app_type 69940\
  }' $MODAPC
  fi
#p  if ! grep -Eq default_24bit $MODAPC; then
#p    sed -i '/^outputs/a\
#p  default_24bit {\
#p    flags AUDIO_OUTPUT_FLAG_PRIMARY\
#p    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
#p    sampling_rates 44100|48000\
#p    bit_width 24\
#p    app_type 69937\
#p  }' $MODAPC
#p  fi
#h  if ! grep -Eq deep_buffer_32 $MODAPC; then
#h    sed -i '/^outputs/a\
#h  deep_buffer_32 {\
#h    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
#h    formats AUDIO_FORMAT_PCM_32_BIT\
#h    sampling_rates 44100|48000\
#h    bit_width 32\
#h    app_type 69940\
#h  }' $MODAPC
#h  fi
#h#p  if ! grep -Eq default_32bit $MODAPC; then
#h#p    sed -i '/^outputs/a\
#h#p  default_32bit {\
#h#p    flags AUDIO_OUTPUT_FLAG_PRIMARY\
#h#p    formats AUDIO_FORMAT_PCM_32_BIT\
#h#p    sampling_rates 44100|48000\
#h#p    bit_width 32\
#h#p    app_type 69937\
#h#p  }' $MODAPC
#h#p  fi
#f  if ! grep -Eq deep_buffer_float $MODAPC; then
#f    sed -i '/^outputs/a\
#f  deep_buffer_float {\
#f    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
#f    formats AUDIO_FORMAT_PCM_FLOAT\
#f    sampling_rates 44100|48000\
#f    app_type 69940\
#f  }' $MODAPC
#f  fi
#f#p  if ! grep -Eq default_float $MODAPC; then
#f#p    sed -i '/^outputs/a\
#f#p  default_float {\
#f#p    flags AUDIO_OUTPUT_FLAG_PRIMARY\
#f#p    formats AUDIO_FORMAT_PCM_FLOAT\
#f#p    sampling_rates 44100|48000\
#f#p    app_type 69937\
#f#p  }' $MODAPC
#f#p  fi
fi

# patch audio policy xml
if [ "$MODAPX" ]; then
  sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"\
                             samplingRates="44100,48000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
#p  sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
#p                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"\
#p                             samplingRates="44100,48000"\
#p                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
#h  sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
#h                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"\
#h                             samplingRates="44100,48000"\
#h                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
#h#p  sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
#h#p                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"\
#h#p                             samplingRates="44100,48000"\
#h#p                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
#f  sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
#f                    <profile name="" format="AUDIO_FORMAT_PCM_FLOAT"\
#f                             samplingRates="44100,48000"\
#f                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
#f#p  sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
#f#p                    <profile name="" format="AUDIO_FORMAT_PCM_FLOAT"\
#f#p                             samplingRates="44100,48000"\
#f#p                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
fi

# patch audio platform info
if [ "$MODAPI" ]; then
  if ! grep -Eq '<bit_width_configs>' $MODAPI; then
    sed -i '/<audio_platform_info>/a\
    <bit_width_configs>\
        <device name="SND_DEVICE_OUT_HEADPHONES" bit_width="24"/>\
        <device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"/>\
    </bit_width_configs>' $MODAPI
  fi
  if ! grep -Eq '<device name="SND_DEVICE_OUT_SPEAKER" bit_width=' $MODAPI; then
    sed -i '/<bit_width_configs>/a\
        <device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"/>' $MODAPI
  fi
  if ! grep -Eq '<device name="SND_DEVICE_OUT_HEADPHONES" bit_width=' $MODAPI; then
    sed -i '/<bit_width_configs>/a\
        <device name="SND_DEVICE_OUT_HEADPHONES" bit_width="24"/>' $MODAPI
  fi
  sed -i 's/<device name="SND_DEVICE_OUT_HEADPHONES" bit_width="16"/<device name="SND_DEVICE_OUT_HEADPHONES" bit_width="24"/g' $MODAPI
  sed -i 's/<device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"/<device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"/g' $MODAPI
#h  sed -i 's/<device name="SND_DEVICE_OUT_HEADPHONES" bit_width="24"/<device name="SND_DEVICE_OUT_HEADPHONES" bit_width="32"/g' $MODAPI
#h  sed -i 's/<device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"/<device name="SND_DEVICE_OUT_SPEAKER" bit_width="32"/g' $MODAPI
#s  sed -i 's/<device name="SND_DEVICE_OUT_SPEAKER" bit_width="24"/<device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"/g' $MODAPI
#s  sed -i 's/<device name="SND_DEVICE_OUT_SPEAKER" bit_width="32"/<device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"/g' $MODAPI
fi