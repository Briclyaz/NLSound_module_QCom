MODDIR=${0%/*}

# destinations
MODAPC=`find $MODDIR/system -type f -name *policy*.conf`
MODAPX=`find $MODDIR/system -type f -name *policy*.xml`
MODAPI=`find $MODDIR/system -type f -name *audio*platform*info*.xml`

# patch audio policy conf
if echo $MODAPC | grep -Eq conf; then
  if ! grep -Eq deep_buffer_24 $MODAPC; then
    sed -i '/^outputs/a\
  deep_buffer_24 {\
    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates 192000\
    bit_width 24\
    app_type 69940\
  }' $MODAPC
  fi
  if ! grep -Eq default_24bit $MODAPC; then
    sed -i '/^outputs/a\
  default_24bit {\
    flags AUDIO_OUTPUT_FLAG_PRIMARY\
    formats AUDIO_FORMAT_PCM_24_BIT_PACKED\
    sampling_rates 192000\
    bit_width 24\
    app_type 69937\
  }' $MODAPC
  fi
#h  if ! grep -Eq deep_buffer_32 $MODAPC; then
#h    sed -i '/^outputs/a\
#h  deep_buffer_32 {\
#h    flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER\
#h    formats AUDIO_FORMAT_PCM_32_BIT\
#h    sampling_rates 192000\
#h    bit_width 32\
#h    app_type 69942\
#h  }' $MODAPC
#h  fi
#h  if ! grep -Eq default_32bit $MODAPC; then
#h    sed -i '/^outputs/a\
#h  default_32bit {\
#h    flags AUDIO_OUTPUT_FLAG_PRIMARY\
#h    formats AUDIO_FORMAT_PCM_32_BIT\
#h    sampling_rates 192000\
#h    bit_width 32\
#h    app_type 69937\
#h  }' $MODAPC
#h  fi
fi

# patch audio policy xml
if echo $MODAPX | grep -Eq xml; then
  sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"\
                             samplingRates="192000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
  sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"\
                             samplingRates="192000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
#h  sed -i '/AUDIO_OUTPUT_FLAG_DEEP_BUFFER/a\
#h                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"\
#h                             samplingRates="192000"\
#h                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
#h  sed -i '/AUDIO_OUTPUT_FLAG_PRIMARY/a\
#h                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"\
#h                             samplingRates="192000"\
#h                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>' $MODAPX
  sed -i '/<mixPort name="primary input"/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_8_24_BIT"\
                             samplingRates="8000,11025,12000,16000,22050,24000,32000,44100,48000,88200,96000"\
                             channelMasks="AUDIO_CHANNEL_IN_MONO,AUDIO_CHANNEL_IN_STEREO,AUDIO_CHANNEL_IN_FRONT_BACK,AUDIO_CHANNEL_INDEX_MASK_3"/>' $MODAPX
  sed -i '/AUDIO_INPUT_FLAG_FAST/a\
                    <profile name="" format="AUDIO_FORMAT_PCM_8_24_BIT"\
                             samplingRates="8000,11025,12000,16000,22050,24000,32000,44100,48000,88200,96000"\
                             channelMasks="AUDIO_CHANNEL_IN_MONO,AUDIO_CHANNEL_IN_STEREO,AUDIO_CHANNEL_IN_FRONT_BACK,AUDIO_CHANNEL_INDEX_MASK_3"/>' $MODAPX
fi

# patch audio platform info
if echo $MODAPI | grep -Eq xml; then
  sed -i 's/bit_width="16/bit_width="24/g' $MODAPI
#h  sed -i 's/bit_width="24/bit_width="32/g' $MODAPI
#s  if ! grep -Eq '<bit_width_configs>' $MODAPI; then
#s    sed -i '/<audio_platform_info>/a\
#s    <bit_width_configs>\
#s        <device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"/>\
#s    </bit_width_configs>' $MODAPI
#s  elif ! grep -Eq 'SND_DEVICE_OUT_SPEAKER" bit_width=' $MODAPI; then
#s    sed -i '/<bit_width_configs>/a\
#s        <device name="SND_DEVICE_OUT_SPEAKER" bit_width="16"/>' $MODAPI
#s  else
#s    sed -i 's/SND_DEVICE_OUT_SPEAKER" bit_width="24/SND_DEVICE_OUT_SPEAKER" bit_width="16/g' $MODAPI
#s    sed -i 's/SND_DEVICE_OUT_SPEAKER" bit_width="32/SND_DEVICE_OUT_SPEAKER" bit_width="16/g' $MODAPI
#s  fi
fi










