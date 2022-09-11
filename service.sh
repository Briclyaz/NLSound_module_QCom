#!/system/bin/sh

# restart
if [ "$API" -ge 24 ]; then
  killall audioserver
else
  killall mediaserver
fi

#!/system/bin/sh
MODDIR=${0%/*}
INFO=/data/adb/modules/.NLSound-files
MODID=NLSound
LIBDIR=/system/vendor
MODPATH=/data/adb/modules/NLSound
MODDIR=${0%/*}
INFO=/data/adb/modules/.NLSound-files
MODID=NLSound
LIBDIR=/system/vendor
MODPATH=/data/adb/modules/NLSound
MODDIR=${0%/*}
INFO=/data/adb/modules/.NLSound-files
MODID=NLSound
LIBDIR=/system/vendor
MODPATH=/data/adb/modules/NLSound

#AML FIX by reiryuki@GitHub
DIR=$AML/system/vendor/odm/etc
if [ -d $DIR ] && [ ! -f $AML/disable ]; then
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi

while :
do
  tinymix "HiFi Filter" 1
  tinymix "ASM Bit Width" 32
  tinymix "AFE Input Bit Format" S32_LE
  tinymix "USB_AUDIO_RX Format" S32_LE
  tinymix "USB_AUDIO_TX Format" S32_LE
  tinymix "USB_AUDIO_RX SampleRate" KHZ_384
  tinymix "USB_AUDIO_TX SampleRate" KHZ_384
  tinymix "RCV Digital PCM Volume" 830
  tinymix "Digital PCM Volume" 830
  tinymix "RCV PCM Source" DSP
  tinymix "PCM Source" DSP
  tinymix "RCV PCM Soft Ramp" Off
  tinymix "PCM Soft Ramp" Off
  tinymix "HDR12 MUX" HDR12
  tinymix "HDR34 MUX" HDR34
  tinymix "RX_CDC_DMA_RX_0 Format" S24_3LE
  tinymix "RX_CDC_DMA_RX_1 Format" S24_3LE
  tinymix "RX_CDC_DMA_RX_2 Format" S24_3LE
  tinymix "RX_CDC_DMA_RX_5 Format" S24_3LE
  tinymix "RX_CDC_DMA_RX_0 SampleRate" KHZ_192
  tinymix "RX_CDC_DMA_RX_1 SampleRate" KHZ_192
  tinymix "RX_CDC_DMA_RX_2 SampleRate" KHZ_192
  tinymix "RX_CDC_DMA_RX_5 SampleRate" KHZ_192
  tinymix "WSA_CDC_DMA_RX_0 Format" S32_LE
  tinymix "WSA_CDC_DMA_RX_1 Format" S32_LE
  tinymix "WSA_CDC_DMA_RX_0 SampleRate" KHZ_384
  tinymix "WSA_CDC_DMA_RX_1 SampleRate" KHZ_384
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
  tinymix "RCV Noise Gate" 0
  tinymix "Noise Gate" 0
  tinymix "Display Port1 RX Bit Format" S24_3LE
  sleep 2
done

#credits - yzyhk904/audio-misc-settings@GitHub
function additionalSettings()
{
    if [ "`getprop persist.sys.phh.disable_audio_effects`" = "0" ]; then
        
        type resetprop 1>/dev/null 2>&1
        if [ $? -eq 0 ]; then
            resetprop ro.audio.ignore_effects true
        else
            type resetprop_phh 1>/dev/null 2>&1
            if [ $? -eq 0 ]; then
                resetprop_phh ro.audio.ignore_effects true
            else
                return 1
            fi
        fi
        
        if [ "`getprop init.svc.audioserver`" = "running" ]; then
            setprop ctl.restart audioserver
        fi
        
    elif [ "`getprop ro.system.build.version.release`" -ge "12" ]; then
        
        local audioHal
        setprop ctl.restart audioserver
        audioHal="$(getprop |sed -nE 's/.*init\.svc\.(.*audio-hal[^]]*).*/\1/p')"
        setprop ctl.restart "$audioHal" 1>"/dev/null" 2>&1
        setprop ctl.restart vendor.audio-hal-2-0 1>"/dev/null" 2>&1
        setprop ctl.restart audio-hal-2-0 1>"/dev/null" 2>&1
        
    fi
    settings put system volume_steps_music 100
}

(((sleep 31; additionalSettings)  0<&- &>"/dev/null" &) &)