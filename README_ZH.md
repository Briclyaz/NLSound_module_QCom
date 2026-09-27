<div align="center">

[ [English](README.md) ] • [ [Русский](README_RU.md) ] • [ **繁體中文** ]

# 🎵 NLSound

### 適用於 Android 的開源系統級音訊全方位優化模組。

[![GitHub Release](https://img.shields.io/github/v/release/Briclyaz/NLSound_module_QCom?style=for-the-badge&color=blue&logo=github)](https://github.com/Briclyaz/NLSound_module_QCom/releases)
[![Downloads](https://img.shields.io/github/downloads/Briclyaz/NLSound_module_QCom/total?style=for-the-badge&logo=github&color=34D399)](https://github.com/Briclyaz/NLSound_module_QCom/releases)
[![GitHub Stars](https://img.shields.io/github/stars/Briclyaz/NLSound_module_QCom?style=for-the-badge&color=gold&logo=github)](https://github.com/Briclyaz/NLSound_module_QCom/stargazers)
[![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange?style=for-the-badge&logo=android)](https://github.com/Briclyaz/NLSound_module_QCom)
[![Platform](https://img.shields.io/badge/Platform-Qualcomm%20%7C%20MediaTek-blue?style=for-the-badge)](https://github.com/Briclyaz/NLSound_module_QCom)
[![License](https://img.shields.io/github/license/Briclyaz/NLSound_module_QCom?style=for-the-badge&color=gray)](LICENSE)
[![Telegram Updates](https://img.shields.io/badge/Channel-@nlsound__updates-2CA5E0?style=for-the-badge&logo=telegram)](https://t.me/nlsound_updates)
[![Telegram Support](https://img.shields.io/badge/Support-@nlsound__support-2CA5E0?style=for-the-badge&logo=telegram)](https://t.me/nlsound_support)

</div>

---

## ❓ 什麼是 NLSound？為什麼你需要它？

原生 Android 系統在音訊輸出設定上極為保守。為了防止便宜的外放揚聲器產生破音雜音，系統預設會**強烈壓縮音訊動態**、**硬性切除極低頻超重低音**、僅提供**粗糙的 15 級音量滑桿**，並限制藍牙傳輸位元率。

**NLSound** 是一款專為已 Root 的 Android 裝置打造的全方位底層音訊模組。它能安全解除軟體限制器、調校硬體暫存器，完整釋放手機 DAC 解碼晶片、外放功放與麥克風的真正硬體潛能。

> 💡 **無背景應用程式、不額外耗電：** NLSound 直接修改系統音訊設定檔與驅動暫存器。安裝後在系統底層靜默運作，完全不需要常駐 App 或背景服務。

---

## ⚡ 為什麼選擇 NLSound？(與原生系統對比)

| 功能特性 | 原生 Android 📱 | 安裝 NLSound 後 🎵 |
| :--- | :--- | :--- |
| **音量調節段數** | 僅 15 級 (音量變化突兀) | **30、50 或 100 級平滑微調** |
| **超重低音下潛** | 25–40 Hz 以下被強制切除 | **完整下潛至 4 Hz 極低頻** |
| **動態壓縮 (DRC)** | 動態受限、音量被強制壓制 | **釋放原始動態、飽滿有力** |
| **低電量音質限制** | 低於 20% 電量時自動弱化音質 | **完全解除降質限制** |
| **藍牙 SBC 編碼** | 受限於標準低位元率 | **解鎖 SBC HD Dual Channel 高位元率** |
| **藍牙耳機音量** | 部分耳機音量偏小異常 | **停用絕對音量 (恢復完整推力)** |
| **直通音訊輸出** | 被 AudioFlinger 強制重採樣混音 | **Bit-Perfect 純淨 Direct PCM 模式** |
| **杜比全景聲** | 音量忽大忽小、聲音空洞假環繞 | **平直、自然、乾淨的聲學曲線** |

---

## 🏗️ 音訊訊號路徑架構圖

```text
[ 音樂播放器 (Poweramp / UAPP / Apple Music / KKBOX) ]
                           │
                           ▼
             ┌───────────────────────────┐
             │   Android AudioFlinger    │ ──► [透過 DIRECT_PCM 繞過二次混音]
             │   (強制重採樣/系統混音器) │
             └───────────────────────────┘
                           │
                           ▼
             ┌───────────────────────────┐
             │    硬體限制器與動態壓縮   │ ──► [移除 DRC 與 25Hz 高通濾波切除]
             └───────────────────────────┘
                           │
                           ▼
             ┌───────────────────────────┐
             │   硬體 DAC 與智慧功放晶片 │ ──► [4Hz 極低頻與 Hi-Fi 高推力模式]
             └───────────────────────────┘
                           │
                           ▼
              🎧 有線耳機 / 🔊 外放揚聲器 / 📶 高解析藍牙 HD
```

---

## 🚀 核心功能一覽

### 🎚️ 1. 平滑音量微調與硬體增益
* **更細膩的音量級數：** 將媒體音量階數由原生 15 級提升至 **30、50 或 100 級**，音量調節更平滑順手。
* **硬體數位前級增益：** 獨立調節外放揚聲器與有線耳機在混音器中的數位音量，不影響藍牙耳機。
* **麥克風收音靈敏度：** 精準調節通話與錄影時的麥克風數位增益 (DEC)，適合小聲說話者，避免爆音。

### 🎧 2. 真 Hi-Fi 與極低頻超重低音釋放
* **解鎖 4 Hz 極低頻：** 將有線耳機硬體高通濾波器 (HPF) 截止頻率由 ~25 Hz 降至 **4 Hz**，找回深沉震撼的極低頻細節。
* **Direct PCM 直通輸出：** 啟用 `DIRECT_PCM` 旗標，允許相容播放器 (Poweramp、UAPP、Neutron) 直接與 DAC 通訊，杜絕系統雜音與二次重採樣。
* **自訂位元深度與取樣率：** 可在系統層級指定音訊處理精度 (最高支援 24/32 位元及 96/192/384 kHz)。

### 🔇 3. 停用動態範圍壓縮 (DRC) 與限制器
* **還原無損動態：** 停用 Dynamic Range Compression (DRC) 與軟削波 (softclip)，複雜樂器大編制不再渾濁。
* **解除低電量限制：** 徹底消除手機低電量時系統對外放揚聲器的強制壓制與音質劣化。

### 📶 4. 藍牙無線音訊深度優化
* **SBC HD Dual Channel：** 為泛用性最高的 SBC 編碼解鎖高位元率高品質傳輸。
* **aptX Adaptive 全面增強：** 啟用 aptX Adaptive 2.1/2.2 規格與 Lossless LE 設定。
* **解決耳機聲音過小問題：** 全面停用 Absolute Volume 絕對音量，解決部分藍牙耳機聲音偏小的頑疾。

### 🎛️ 5. 淨化音效處理與杜比全景聲調校
* **移除假環繞殘響：** 關閉破壞相位的假 3D 與人工殘響，同時完整保留手動等化器與通話降噪功能。
* **Dolby Atmos DAX 專業調校：** 消除「悶在桶子裡」的空洞感，關閉激進的音量平衡器 (防止忽大忽小) 與人聲壓縮。

### 📱 6. 機型專屬硬體暫存器調校
* 自動掃描主機板匯流排晶片 (Cirrus Logic、TI TAS、NXP TFA、Awinic、Qualcomm WSA/WCD)。
* 為小米、OnePlus、Realme、三星、Sony 與 Google Pixel 等眾多熱門機型套用專屬的 `tinymix` 暫存器調音。

---

## 📱 機型與硬體晶片支援列表

<details>
<summary><b>點擊展開查看具備專屬硬體調校的機型名單</b></summary>
<br>

* **小米 / POCO / 紅米：** 
  * 小米 14 Ultra (`aurora`)、小米 13 Ultra (`ishtar`)、小米 11 Ultra (`star`)、小米 10 Pro (`cmi`)、小米 10 (`umi`)；
  * POCO F5 / 紅米 Note 12 Turbo (`marble`)、POCO F3 / 紅米 K40 (`alioth`)、POCO X3 Pro (`vayu`)、POCO X3 NFC (`surya`)、POCO M3 / 紅米 9T (`citrus`, `juice`, `chime`, `lime`)；
  * 紅米 Note 10 Pro (`sweet`, `mojito`)、紅米 Note 9 Pro (`joyeuse`, `curtana`, `gram`, `excalibur`)。
* **OnePlus (一加)：** 
  * 一加 13 (`OP5D55L1`)、一加 12 (`OP595DL1`)、一加 12R / Ace 2 Pro (`OP5D3BL1`, `OP5D2BL1`)、一加 Ace 3 (`OP5929L1`)；
  * 一加 9R、一加 9 Pro (`ingres`)、一加 7 / 7T / 7 Pro 系列 (`guacamole`, `hotdog`)。
* **Realme (真我)：** 
  * Realme 12 Pro+ (`RE5C82L1`, `RE5C3B`)、Realme GT Neo 5 (`RE5C4FL1`)、Realme GT Neo / GT 2 (`RE5473`, `RE879AL1`, `kona`)。
* **Google Pixel：** 
  * Pixel 8 及 Pixel 8 Pro (`shiba`, `husky`)；
  * 具備獨立 DSP 旁路優化的 Pixel 7 Pro (`cheetah`)；
  * Pixel 6、Pixel 6 Pro、Pixel 6a、Pixel 7 (`bluejay`, `oriole`, `raven`, `panther`)。
* **三星與 Sony：** 
  * 三星 Galaxy S22 Ultra (`b0q`)；
  * Sony Xperia 1 II (`XQ-AT52`)、Sony Xperia 5 IV (`XQ-CQ62`)。
* *未列出之機型將依據偵測到的功放晶片自動套用通用最佳化設定。*

</details>

<details>
<summary><b>可自動辨識之音訊硬體 (DAC 與功放)</b></summary>
<br>

NLSound 會掃描硬體匯流排介面 (`I2C`、`SoundWire`、`Slimbus`、`Platform`) 進行專屬調校：
* **外放功放晶片：** Cirrus Logic (CS35L41)、Texas Instruments (TAS25xx)、NXP / Goodix (TFA98xx)、Awinic (AW88xx)、Maxim Integrated (MAX98373)、Qualcomm WSA (WSA88xx)。
* **音訊編解碼器 / DAC：** Qualcomm WCD (Aqstic / Bolero Hi-Fi)、ESS Sabre、Asahi Kasei (AKM)。

</details>

---

## 🛠️ 互動式終端安裝器

在 Root 管理器中刷入模組時，將啟動由**音量鍵**控制的互動式選單：

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 [01/15] 音量調整級數 (細緻音量)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 修改媒體音量滑桿的階數段數
 (原生 Android 預設僅有 15 級)。

 [*] 建議選擇 30 或 50 級：調整更平滑，
 且按鍵次數適中。

  [VOL+] 下一個      ┃   [VOL-] 選擇

 1. 跳過      • 系統預設 (15 級)
 2. 30 級     • [建議] 均衡適中
 3. 50 級     • 平滑微調
 4. 100 級    • 極度細微 (需按多次)
```

* **[VOL+]** — 移動至下一個選項 / 確認安裝。
* **[VOL-]** — 選擇目前項目 / 跳過設定。
* **一鍵還原設定檔：** 日後更新模組時，只需在首個畫面按下 **[VOL+]**，即可直接還原先前的全部設定！

---

## 📋 相容性與系統需求

* **Root 方案：** [Magisk](https://github.com/topjohnwu/Magisk) (v24+)、[KernelSU](https://github.com/tiann/KernelSU) 或 [APatch](https://github.com/bmax121/APatch)。
* **掛載架構：** 完整相容 Magic Mount、**KernelSU OverlayFS** 與 **Mountify** (乾淨卸載無鎖定殘留)。
* **第三方音效模組：** 100% 相容 Audio Modification Library (AML)、ViPER4Android 與 JamesDSP。
* **處理器平台：**
  * **高通驍龍 (Snapdragon)：** 完整支援 (驍龍 625 至 8 Elite)。
  * **聯發科 (MediaTek)：** 基礎支援天璣 (Dimensity) 與 Helio 系列。
* **Android 版本：** Android 9.0 至 Android 15+。

---

## 📥 安裝步驟

1. 從 [Releases](https://github.com/Briclyaz/NLSound_module_QCom/releases) 頁面或我們的 [Telegram 頻道](https://t.me/nlsound_updates) 下載最新版 `.zip` 檔案。
2. 開啟 **Magisk**、**KernelSU** 或 **APatch** 應用程式。
3. 進入**模組**分頁，點選**從儲存空間安裝**。
4. 選擇下載的 `.zip` 檔案。
5. 依照畫面提示，使用**音量鍵**選擇所需功能。
6. 安裝完成後重新啟動手機即可享受純淨音質。

---

## ⭐ Star History

<div align="center">

<a href="https://star-history.com/#Briclyaz/NLSound_module_QCom&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Briclyaz/NLSound_module_QCom&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Briclyaz/NLSound_module_QCom&type=Date" />
    <img alt="NLSound Star History Chart" src="https://api.star-history.com/svg?repos=Briclyaz/NLSound_module_QCom&type=Date" width="750" />
  </picture>
</a>

<br><br>

[![Star on GitHub](https://img.shields.io/badge/Leave%20a%20Star-⭐-gold?style=for-the-badge&logo=github)](https://github.com/Briclyaz/NLSound_module_QCom/stargazers)

*If you appreciate the sound improvements, please support the project with a star!*

</div>

---

## 💬 支援與社群

有任何疑問、建議或問題回報？
* 📢 **官方公告與更新頻道：** [@nlsound_updates](https://t.me/nlsound_updates)
* 💬 **社群支援討論群：** [@nlsound_support](https://t.me/nlsound_support)

---

<div align="center">

**由 NLSound Team 用心製作 ❤️**

*非商業開源專案，無廣告、無追蹤、無收費牆。*

</div>
