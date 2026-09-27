<div align="center">

# 🎵 NLSound

### An open-source, system-level audio enhancement module for Android.

[![Magisk](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange?style=for-the-badge&logo=android)](https://github.com/Briclyaz/NLSound_module_QCom)
[![Platform](https://img.shields.io/badge/Platform-Qualcomm%20%7C%20MediaTek-blue?style=for-the-badge)](https://github.com/Briclyaz/NLSound_module_QCom)
[![Telegram Updates](https://img.shields.io/badge/Channel-@nlsound__updates-2CA5E0?style=for-the-badge&logo=telegram)](https://t.me/nlsound_updates)
[![Telegram Support](https://img.shields.io/badge/Support-@nlsound__support-2CA5E0?style=for-the-badge&logo=telegram)](https://t.me/nlsound_support)

</div>

---

## ❓ What is NLSound and why do you need it?

By default, stock Android treats your audio hardware very conservatively. To prevent cheap built-in speakers from rattling, Android heavily **compresses audio dynamics**, **cuts deep sub-bass frequencies**, enforces **coarse 15-step volume sliders**, and limits Bluetooth bitrate.

**NLSound** is an all-in-one system audio module for rooted Android devices. It safely removes software limiters, tunes low-level hardware registers, and unlocks the true capabilities of your phone's DAC, speaker amplifiers, and microphones.

> 💡 **No background apps or battery drain:** NLSound modifies system configurations and driver registers directly. Once installed, it works completely in the background without needing companion apps or background services.

---

## 🚀 Key Features at a Glance

### 🎚️ 1. Smooth Volume & Hardware Gain
* **More Volume Steps:** Increases the media volume slider from the stock 15 steps to **30, 50, or 100 steps** for precise, smooth control.
* **Independent Preamp Boost:** Fine-tune the hardware digital output level for speakers and wired headphones without affecting Bluetooth audio.
* **Microphone Sensitivity:** Adjust digital recording gain (DEC) to boost quiet voices or prevent clipping in noisy environments.

### 🎧 2. True Hi-Fi & Sub-Bass Restoration
* **Sub-bass Unlocked (4 Hz):** Lowers the built-in headphone High-Pass Filter (HPF) cutoff from ~25 Hz down to **4 Hz**, restoring deep, physical sub-bass in wired headphones.
* **Direct PCM Routing:** Unlocks `DIRECT_PCM` flags, allowing supported players (Poweramp, UAPP, Neutron) to send untouched audio straight to the DAC, bypassing the Android OS mixer.
* **Custom Bit Depth & Sample Rate:** Configure system-wide PCM targets (up to 24/32-bit and 96/192/384 kHz) without forced downsampling.

### 🔇 3. Dynamic Limiters & DRC Removal
* **Disable Audio Throttling:** Removes Dynamic Range Compression (DRC) and artificial low-battery volume throttling.
* **Softclip & Compander Off:** Disables aggressive volume compression that flattens dynamic range during intense music passages.

### 📶 4. Enhanced Wireless (Bluetooth) Audio
* **SBC HD Dual Channel:** Unlocks high-bitrate playback for the universal SBC codec.
* **aptX Adaptive Enhancements:** Enables advanced aptX Adaptive 2.1/2.2 and Lossless LE profiles.
* **Fix Quiet Headphones:** Disables Android's buggy Absolute Volume feature, fixing low-volume issues on wireless headphones.

### 🎛️ 5. Clean Effects & Dolby Atmos Tuning
* **Effects Cleanup:** Disables fake spatializers, phase delays, and synthetic reverbs while preserving your favorite graphic equalizers and call audio clarity.
* **Dolby Atmos DAX Tuning:** Removes the hollow "audio in a bucket" effect, turns off annoying volume pumping, and flattens dialogue compression.

### 📱 6. Model-Specific Hardware Register Presets
* Automatically identifies onboard hardware (Cirrus Logic, Texas Instruments TAS, NXP TFA, Awinic, Qualcomm WSA/WCD).
* Pre-configured, device-tailored ALSA mixer parameters (`tinymix`) for dozens of popular Xiaomi, OnePlus, Realme, Samsung, Sony, and Google Pixel smartphones.

---

## 🛠️ Step-by-Step Interactive Installer

When flashing NLSound in your root manager, an interactive terminal menu lets you choose exactly what you want using your **Volume Buttons**:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 [01/15] VOLUME CONTROL STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Changes the number of steps on the media
 volume slider (stock Android has only 15).

 [*] 30 or 50 is recommended for balanced control.

  [VOL+] Next item   ┃   [VOL-] Select

 1. Skip      • Default (15 steps)
 2. 30 steps  • [Recommended] Balanced
 3. 50 steps  • Smooth control
 4. 100 steps • Fine-grained control
```

* **[VOL+]** — Move down the list / Confirm installation.
* **[VOL-]** — Select highlighted option / Skip step.
* **1-Click Profile Restore:** When updating the module, press **[VOL+]** at the first prompt to automatically restore your previous configuration!

---

## 📋 Compatibility & Requirements

* **Root Solution:** [Magisk](https://github.com/topjohnwu/Magisk) (v24+), [KernelSU](https://github.com/tiann/KernelSU), or [APatch](https://github.com/bmax121/APatch).
* **Overlay Architecture:** Fully compatible with Magic Mount, **KernelSU OverlayFS**, and **Mountify**.
* **Audio Mods:** 100% compatible with Audio Modification Library (AML), ViPER4Android, and JamesDSP.
* **Processors:**
  * **Qualcomm Snapdragon:** Comprehensive support (Snapdragon 625 up to 8 Elite).
  * **MediaTek:** Preliminary support for Dimensity and Helio platforms.
* **Android Versions:** Android 9.0 up to Android 15+.

---

## 📥 Installation

1. Download the latest release `.zip` from [Releases](https://github.com/Briclyaz/NLSound_module_QCom/releases) or our [Telegram Channel](https://t.me/nlsound_updates).
2. Open **Magisk**, **KernelSU**, or **APatch** app.
3. Go to the **Modules** section and select **Install from storage**.
4. Select the downloaded `.zip` file.
5. Follow the on-screen prompts using your **Volume Keys**.
6. Reboot your device after the installation finishes.

---

## 💬 Support & Community

Have questions, suggestions, or want to report a bug?
* 📢 **Announcements & Updates:** [@nlsound_updates](https://t.me/nlsound_updates)
* 💬 **Community Support Chat:** [@nlsound_support](https://t.me/nlsound_support)

---

<div align="center">

**Made with ❤️ by the NLSound Team**

*Non-commercial, open-source project. No ads, no tracking, no paid paywalls.*

</div>
