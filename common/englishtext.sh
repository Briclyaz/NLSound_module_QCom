#!/bin/bash
# Installer menu descriptions for English localization

SELECTE="- [*] Selected:"
SMENU="install skip"
SMENU1="skip 30 50 100"
SMENU2="skip 78 84 90 96 102 108"
SMENU4="skip 16_bit 24_bit 32_bit Float"
SMENU5="skip 44100 48000 96000 192000 384000"
SMENU13="skip disable_part disable_all"
SMENU16="skip basic General_cal speakers"
INSTALLSKIP="     [VOL+] - Install | [VOL-] - Skip"
SMENUAUTOSKIP="  Installation not possible, auto-skipped"
SMENUSKIP="- Settings restore skipped"

RESTORE="
       • PREVIOUS SETTINGS DETECTED •

You can install the same settings as
last time.

$SEPARATOR
     [VOL+] - Install | [VOL-] - Skip"

STRINGSTEP1="
Please configure me! >.< - 

$SEPARATOR

[1/16]

     • CHOOSE NUMBER OF VOLUME STEPS •

This will change the number of volume
steps for music in your system. Call
audio and other scenarios will keep
default steps.

$SEPARATOR
 [VOL+] Change selection | [VOL-] Confirm
$SEPARATOR

1. Skip (No changes)
2. 30 (~1.1-2.0 dB per step)
3. 50 (~0.8-1.4 dB per step)
4. 100 (~0.4-0.7 dB per step)"

STRINGSTEP2="
[2/16]

       • CHOOSE MUSIC VOLUME LEVEL •

This will change maximum volume threshold
for music. Higher value means louder
maximum volume.

 WARNING:
Excessively high values may cause audio
distortion.

 NOTE:
No effect on Bluetooth.

$SEPARATOR
 [VOL+] Change selection | [VOL-] Confirm
$SEPARATOR

1. Skip (No changes)
2. 78
3. 84 (Default in most cases)
4. 90
5. 96
6. 102
7. 108"

STRINGSTEP3="
[3/16]

     • SELECT MICROPHONE SENSITIVITY •

This will change microphone sensitivity
in your system. Higher values make
recordings louder.

 WARNING:
Excessively high values may cause audio
distortion.

 NOTE:
No effect on Bluetooth.

$SEPARATOR
 [VOL+] Change selection | [VOL-] Confirm
$SEPARATOR

1. Skip (No changes)
2. 78
3. 84 (Default in most cases)
4. 90
5. 96
6. 102
7. 108"

STRINGSTEP4="
[4/16]

         • SELECT AUDIO BIT DEPTH •

This will configure audio processing
parameters for your device.

$SEPARATOR
 [VOL+] Change selection | [VOL-] Confirm
$SEPARATOR

1. Skip (No changes)
2. 16 bit
3. 24 bit
4. 32 bit
5. Float (Best quality)"

STRINGSTEP5="
[5/16]

          • SELECT SAMPLING RATE •

This will configure audio processing
parameters for your device.

$SEPARATOR
 [VOL+] Change selection | [VOL-] Confirm
$SEPARATOR

1. Skip (No changes)
2. 44100 Hz
3. 48000 Hz
4. 96000 Hz
5. 192000 Hz
6. 384000 Hz"

STRINGSTEP6="
[6/16]

      • DISABLE AUDIO INTERVENTIONS •

This will disable various system sound
optimizations that interfere with normal
audio transmission.

$SEPARATOR
     [VOL+] - Install | [VOL-] - Skip"

STRINGSTEP7="
[7/16]

     • PATCHING DEVICE_FEATURES FILE •

This option enables Hi-Fi support, HD
audio recording, unlocks sample rates,
and improves VoIP recording quality"

STRINGSTEP8="
[8/16]

     • ADDITIONAL MIXER_PATHS PATCHES •

This disables various frequency cuts
that are supposedly beyond human hearing.
Improves detail, soundstage and musicality.

$SEPARATOR
     [VOL+] - Install | [VOL-] - Skip"

STRINGSTEP9="
[9/16]

          • BUILD.PROP TWEAKS •

This is one of the most impactful audio
modifications. Contains numerous global
settings that significantly improve
audio quality.

$SEPARATOR
     [VOL+] - Install | [VOL-] - Skip"

STRINGSTEP10="
[10/16]

          • IMPROVE BLUETOOTH •

This will maximally improve Bluetooth
audio quality and fix automatic AAC codec
switching to OFF position.

$SEPARATOR
     [VOL+] - Install | [VOL-] - Skip"

STRINGSTEP11="
[11/16]

         • CHANGE AUDIO OUTPUT •

This switches DIRECT to DIRECT_PCM for
better detail and quality.

$SEPARATOR"

STRINGSTEP12="
[12/16]

      • INSTALL CUSTOM IIR PRESET •

IIR affects final frequency response curve
of DSP-processed sound. Essentially acts as
system-wide equalizer presets.

$SEPARATOR"

STRINGSTEP13="
[13/16]

        • IGNORE AUDIO EFFECTS •

Significantly improves audio quality by
disabling processing. Breaks XiaomiParts,
Dirac, Dolby and other equalizers.

 NOTE:
When this option is selected, item 15 will
become unavailable for selection

$SEPARATOR
 [VOL+] Change selection | [VOL-] Confirm
$SEPARATOR

1. Skip (No changes)
2. Disable some audio effects
3. Disable all audio effects. Improves
quality but reduces volume and may cause
issues with some apps"

STRINGSTEP14="
[14/16]

      • INSTALL PERSONALIZED TWEAKS •

Compatible with limited devices. Applies
different parameters depending on device.
Modifies both mixer_paths and tinymix.

 NOTE:
Enabling improves proper application of
steps: 4, 5

$SEPARATOR
     [VOL+] - Install | [VOL-] - Skip"

STRINGSTEP15="
[15/16]

         • CONFIGURE DOLBY ATMOS •

Additional Dolby tuning for better sound
quality by disabling various redundant
functions and mechanisms.

$SEPARATOR"

STRINGSTEP16="
           • MODIFY ACDB FILES •

This can remove all output limitations
for AUX, Bluetooth and device speakers.

 OPTION DESCRIPTIONS:
2. Removes limits for AUX/Bluetooth/HDMI
without touching General_cal.

3. Same as 2 but also removes General_cal.
Only use if it doesn't cause audio loss.

4. Same as 3 but removes speaker limits.
Very dangerous - may damage speakers at
high volumes by removing all LF limits.

 WARNING:
Agreeing may cause hardware damage from
improper use (e.g., high volume), and
bootloops. These parameters are effective
but risky. We take no responsibility.

$SEPARATOR
 [VOL+] Change selection | [VOL-] Confirm
$SEPARATOR

1. Skip (No changes)
2. Basic .acdb removal
3. Basic + General_cal removal
4. Basic + Speaker limits removal +
General_cal removal"

STRINGSTEP161="
  • INSTALL PATCHED ACDB FILES •

Disables limiters and changes resampler
mode in ACDB files.

 NOTE:
May not work on BBK smartphones due to
certain restrictions"

final_print_text() {
     cat <<EOF
$SEPARATOR
        
            ◍ YOUR SETTINGS ◍
          
  1  Volume steps count         $VOLSTEPS 
  2  Max volume level           $VOLMEDIA 
  3  Microphone sensitivity     $VOLMIC 
  4  Audio format               $BITNES 
  5  Sampling rate              $SAMPLERATE 
  6  Disable interventions      $STEP6 
  7  device_features patches    $STEP7 
  8  Additional mixer_paths     $STEP8 
  9  build.prop tweaks          $STEP9 
 10  Bluetooth improvements     $STEP10 
 11  Audio output change        $STEP11 
 12  Custom IIR preset          $STEP12 
 13  Ignored effects            $STEP13 
 14  Personalized tweaks        $STEP14 
 15  Dolby Atmos config         $STEP15 
 16  ACDB modifications         $([ $PATCHACDB != false ] && echo $PATCHACDB || echo $DELETEACDB) 

$SEPARATOR

         • DEVICE INFORMATION •

  Module version      $VERSION 
  Device              $DEVICE 
  
$SEPARATOR

 - Installation started, please wait 
EOF
}
