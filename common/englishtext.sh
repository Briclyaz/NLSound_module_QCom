#!/bin/bash
# Installer menu descriptions for English localization (Unified Compact UI)

SELECTE="- [*] Selected:"
SMENU="install skip"
SMENU1="skip 30 50 100"
SMENU2="skip 78 84 90 96 102 108"
SMENU4="skip 16_bit 24_bit 32_bit Float"
SMENU5="skip 44100 48000 96000 192000 384000"
SMENU12="skip disable_part disable_all"
SMENU15="skip basic General_cal speakers"

INSTALLSKIP="
  [VOL+] Install     ┃   [VOL-] Skip
"
SMENUAUTOSKIP="  Not supported on this device (Skipped)"
SMENUSKIP="- Previous settings skipped"

RESTORE="
 PREVIOUS SETTINGS DETECTED
$SEPARATOR

 A saved profile from your previous
 installation was found on this device.

 Would you like to restore it?

  [VOL+] Restore profile
  [VOL-] Configure manually from scratch
"

STRINGSTEP1="
 [01/15] VOLUME CONTROL STEPS
$SEPARATOR

 Changes the number of steps on the media
 volume slider (stock Android has only 15).

 [*] 30 or 50 is recommended for smoother
 control without too many button clicks.

  [VOL+] Next item   ┃   [VOL-] Select

 1. Skip      • Default (15 steps)
 2. 30 steps  • [Recommended] Balanced
 3. 50 steps  • Smooth control
 4. 100 steps • Fine-grained control
"

STRINGSTEP2="
 [02/15] MAXIMUM HARDWARE VOLUME (MIXER)
$SEPARATOR

 Adjusts digital preamp gain in mixer_paths
 for built-in speakers and wired headphones.

 [i] Stock value is 84.
 [!] Values above 96 may cause clipping on peaks.
 [!] Does not affect Bluetooth audio.

  [VOL+] Next item   ┃   [VOL-] Select

 1. Skip      • Keep stock level
 2. 78        • Lower than stock
 3. 84        • Stock level [Safe]
 4. 90        • Moderate boost
 5. 96        • Noticeable boost [Clean limit]
 6. 102       • High boost (risk of distortion)
 7. 108       • Maximum gain (high distortion)
"

STRINGSTEP3="
 [03/15] MICROPHONE SENSITIVITY (DEC)
$SEPARATOR

 Adjusts digital recording gain for calls,
 voice notes, and video recordings.

 [i] Stock value is 84. High values amplify
 background noise, room echo, and hiss.

  [VOL+] Next item   ┃   [VOL-] Select

 1. Skip      • Keep stock sensitivity
 2. 78        • Lower gain (for noisy places)
 3. 84        • Stock level [Safe]
 4. 90        • Slight boost
 5. 96        • Recommended for quiet voices
 6. 102       • High sensitivity
 7. 108       • Maximum gain (distortion risk)
"

STRINGSTEP4="
 [04/15] AUDIO BIT DEPTH
$SEPARATOR

 Sets default PCM bit depth in audio policy
 and platform configuration files.

 [*] 24-bit is recommended. 32-bit and Float
 are not supported by all hardware codecs.

  [VOL+] Next item   ┃   [VOL-] Select

 1. Skip      • System default
 2. 16 bit    • Standard 16-bit PCM
 3. 24 bit    • [Recommended] 24-bit PCM
 4. 32 bit    • 32-bit PCM
 5. Float     • 32-bit Floating Point
"

STRINGSTEP5="
 [05/15] AUDIO SAMPLING RATE
$SEPARATOR

 Sets primary hardware output sample rate
 in system audio configuration files.

 [i] Android default is 48 kHz. Selecting 96 kHz
 allows native Hi-Res playback without downsampling.

  [VOL+] Next item   ┃   [VOL-] Select

 1. Skip      • System default
 2. 44100 Hz  • Standard CD rate
 3. 48000 Hz  • Android / Video standard
 4. 96000 Hz  • [Recommended] Hi-Res
 5. 192000 Hz • High rate (higher CPU load)
 6. 384000 Hz • Maximum rate
"

STRINGSTEP6="
 [06/15] DISABLE SOUND LIMITERS & DRC
$SEPARATOR

 Disables Dynamic Range Compression (DRC),
 soft-clipping, and software volume limiters.

 • Restores natural audio dynamics
 • Removes volume throttling and ducking
 [!] Small speakers may distort at max volume.
$INSTALLSKIP"

STRINGSTEP7="
 [07/15] UNLOCK VENDOR HI-FI FEATURES
$SEPARATOR

 Enables hidden audio flags in OEM configs
 for Xiaomi, OnePlus, Realme, and Oppo:

 • Unlocks 24-bit HD voice recording
 • Enables native DAC Hi-Fi modes
 • Injects Pro-Audio system permission
"

STRINGSTEP8="
 [08/15] HEADPHONE HIGH-PASS FILTER (4 HZ)
$SEPARATOR

 Lowers the built-in headphone High-Pass Filter
 (HPF) cutoff in mixer_paths from ~25 Hz to 4 Hz.

 • Restores deep sub-bass reproduction
 • Switches headphone amp to Hi-Fi power mode
$INSTALLSKIP"

STRINGSTEP9="
 [09/15] BUILD.PROP ENGINE TWEAKS
$SEPARATOR

 Tweaks low-level Android audio properties:

 • Configures resampler filter coefficients
 • Reduces latency in AAudio MMAP stack
 • Disables dynamic range compression in AAC
$INSTALLSKIP"

STRINGSTEP10="
 [10/15] BLUETOOTH AUDIO OPTIMIZATION
$SEPARATOR

 Optimizes wireless audio configuration:

 • Enables Dual Channel high bitrate for SBC (SBC HD)
 • Optimizes AptX Adaptive parameters
 • Disables Absolute Volume (fixes low volume bugs
   on certain wireless headphones)
$INSTALLSKIP"

STRINGSTEP11="
 [11/15] DIRECT PCM AUDIO ROUTING
$SEPARATOR

 Adds DIRECT_PCM flags to audio output policies.

 Allows compatible players (Poweramp, UAPP, Neutron)
 to route audio straight to the DAC, bypassing the
 standard Android AudioFlinger mixer.
"

STRINGSTEP12="
 [12/15] AUDIO EFFECTS POLICY
$SEPARATOR

 Controls built-in system audio processing
 (spatial audio, reverbs, vendor equalizers).

 [!] Selecting 'Disable all' will skip
     Dolby Atmos tuning in Step 14.

  [VOL+] Next item   ┃   [VOL-] Select

 1. Skip        • Keep all equalizers active
 2. Partial     • [Recommended] Removes fake 3D
                  and reverbs, keeps equalizers
 3. Disable all • Completely disables all effect
                  libraries (disables Dolby/Dirac)
"

STRINGSTEP13="
 [13/15] HARDWARE-SPECIFIC TWEAKS (TINYMIX)
$SEPARATOR

 Applies boot-time ALSA mixer adjustments
 tailored specifically to your device model:

 • Optimizes smart amplifier chips (Cirrus, TAS, SmartPA)
 • Adjusts headphone output power and ADC gains
$INSTALLSKIP"

STRINGSTEP14="
 [14/15] DOLBY ATMOS TUNING
$SEPARATOR

 Reconfigures Dolby Atmos processing parameters:

 • Disables volume leveler (prevents volume pumping)
 • Disables fake surround delay and dialog compression
 • Delivers a cleaner, more balanced output
"

STRINGSTEP15="
 [15/15] ACDB CALIBRATION OVERRIDES
$SEPARATOR

 Qualcomm ACDB files store factory DSP volume
 caps and hardware limiters.

 This option zeroes selected calibration files:

  [VOL+] Next item   ┃   [VOL-] Select

 1. Skip      • Keep stock calibration
 2. Basic     • [Safe] Unlocks AUX, BT, and HDMI
 3. General   • Basic + clears common calibration
 4. Speakers  • [Caution] Clears speaker limits
                (may rattle at maximum volume)
"

STRINGSTEP151="
 [15/15] INSTALL PRE-PATCHED ACDB
$SEPARATOR

 A custom-tuned, model-specific ACDB profile
 was found for your device.

 Safely lifts hardware volume limits without
 causing driver instability.
"

final_print_text() {
  cat <<EOF
$SEPARATOR
          CONFIGURATION SUMMARY
$SEPARATOR

  01 Volume steps count        : $VOLSTEPS
  02 Max volume level          : $VOLMEDIA
  03 Mic sensitivity           : $VOLMIC
  04 Audio bit depth           : $BITNES
  05 Audio sample rate         : $SAMPLERATE
  06 Limiters & DRC disabled   : $STEP6
  07 Vendor Hi-Fi features     : $STEP7
  08 Sub-bass & mixer patches  : $STEP8
  09 build.prop optimizations  : $STEP9
  10 Bluetooth enhancements    : $STEP10
  11 Direct PCM routing        : $STEP11
  12 Audio effects policy      : $STEP12
  13 Device hardware tweaks    : $STEP13
  14 Dolby Atmos Hi-Fi profile : $STEP14
  15 ACDB modifications        : $([ "$PATCHACDB" != "false" ] && echo "$PATCHACDB" || echo "$DELETEACDB")

$SEPARATOR
  Device model   : $DEVICE
  Module version : $VERSION
$SEPARATOR

 Installing modules and patching files...
 Please wait...
EOF
}

HW_HEADER="          [ AUDIO HARDWARE DETECTED ]"
HW_CIRRUS="Speaker Amplifier    : Cirrus Logic (CS35L41)"
HW_TFA="Speaker Amplifier    : NXP / Goodix TFA"
HW_TAS="Speaker Amplifier    : Texas Instruments (TAS)"
HW_AWINIC="Speaker Amplifier    : Awinic (AW88xx)"
HW_MAXIM="Speaker Amplifier    : Maxim Integrated"
HW_WSA="Speaker Amplifier    : Qualcomm WSA"
HW_WCD="Primary Audio Codec  : Qualcomm WCD (Aqstic Hi-Fi)"
HW_ESS="Dedicated Hi-Fi DAC  : ESS Sabre"
HW_AKM="Dedicated Hi-Fi DAC  : Asahi Kasei (AKM)"
HW_SOC="Primary Audio Codec  : Integrated Processor Codec (SoC)"