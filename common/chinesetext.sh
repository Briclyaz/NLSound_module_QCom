#!/bin/bash
# 安裝器選單描述 (繁體中文版 - 統一緊湊風格)

SELECTE="- [*] 已選擇："
SMENU="安裝 跳過"
SMENU1="跳過 30 50 100"
SMENU2="跳過 78 84 90 96 102 108"
SMENU4="跳過 16位元 24位元 32位元 浮點"
SMENU5="跳過 44100 48000 96000 192000 384000"
SMENU12="跳過 部分停用 全部停用"
SMENU15="跳過 基礎 General_cal 揚聲器"

INSTALLSKIP="
  [VOL+] 安裝        ┃   [VOL-] 跳過
"
SMENUAUTOSKIP="  本裝置不支援 (已自動跳過)"
SMENUSKIP="- 已跳過先前設定恢復"

RESTORE="
 檢測到先前的設定
$SEPARATOR

 發現上次安裝時儲存的配置檔。

 是否直接恢復上次的設定？

  [VOL+] 恢復設定檔
  [VOL-] 從頭手動重新配置
"

STRINGSTEP1="
 [01/15] 音量調整級數 (細緻音量)
$SEPARATOR

 修改媒體音量滑桿的階數段數
 (原生 Android 預設僅有 15 級)。

 [*] 建議選擇 30 或 50 級：調整更平滑，
 且按鍵次數適中。

  [VOL+] 下一個      ┃   [VOL-] 選擇

 1. 跳過      • 系統預設 (15 級)
 2. 30 級     • [建議] 均衡適中
 3. 50 級     • 平滑微調
 4. 100 級    • 極度細微 (需按多次)
"

STRINGSTEP2="
 [02/15] 硬體輸出增益 (MIXER)
$SEPARATOR

 提高外放揚聲器與有線耳機在 ALSA
 混音器中的數位音量。

 [i] 原廠標準值為 84。
 [!] 高於 96 在最大音量時可能會有破音失真。
 [!] 對藍牙音訊無效。

  [VOL+] 下一個      ┃   [VOL-] 選擇

 1. 跳過      • 保持原廠音量
 2. 78        • 低於原廠
 3. 84        • 原廠標準 [安全]
 4. 90        • 輕微增強
 5. 96        • 明顯提升 [最佳平衡]
 6. 102       • 很大音量 (有破音風險)
 7. 108       • 極限增益 (容易失真)
"

STRINGSTEP3="
 [03/15] 麥克風收音靈敏度 (DEC)
$SEPARATOR

 調節通話、錄影與語音訊息時的
 麥克風數位增益 (DEC)。

 [i] 原廠標準值為 84。數值過高會放大
 環境底噪、空間回音與雜音。

  [VOL+] 下一個      ┃   [VOL-] 選擇

 1. 跳過      • 保持原廠數值
 2. 78        • 降低靈敏度 (適合吵雜環境)
 3. 84        • 原廠標準 [安全]
 4. 90        • 輕微增強
 5. 96        • 適合說話聲音偏小者
 6. 102       • 高靈敏度 (底噪較明顯)
 7. 108       • 極限靈敏度 (可能爆音)
"

STRINGSTEP4="
 [04/15] 音訊位元深度 (BIT DEPTH)
$SEPARATOR

 在系統音訊設定 (audio_policy 及
 audio_platform) 中設定 PCM 位元深度。

 [*] 建議選擇 24 位元。32 位元及浮點
 並非所有硬體解碼晶片皆支援。

  [VOL+] 下一個      ┃   [VOL-] 選擇

 1. 跳過      • 系統預設
 2. 16 位元   • 標準 16-bit PCM
 3. 24 位元   • [建議] 24-bit PCM
 4. 32 位元   • 32-bit PCM
 5. 浮點      • 32-bit 浮點精度
"

STRINGSTEP5="
 [05/15] 音訊採樣率 (SAMPLE RATE)
$SEPARATOR

 設定系統硬體音訊輸出的預設取樣頻率。

 [i] Android 預設為 48 kHz。選擇 96 kHz
 可原生播放 Hi-Res 無損音訊，避免被強制降頻。

  [VOL+] 下一個      ┃   [VOL-] 選擇

 1. 跳過      • 系統預設
 2. 44100 Hz  • CD 音訊標準
 3. 48000 Hz  • Android / 影片標準
 4. 96000 Hz  • [建議] Hi-Res
 5. 192000 Hz • 高解析度 (耗電稍增)
 6. 384000 Hz • 極限頻率
"

STRINGSTEP6="
 [06/15] 停用 DRC 與動態限制器
$SEPARATOR

 在混音器與設定檔中停用動態範圍壓縮 (DRC)、
 軟削波 (softclip) 及軟體音量壓制。

 • 恢復原始動態範圍，聲音更開闊紮實
 • 消除低電量時的軟體音量限制
 [!] 小型外放揚聲器在最高音量時可能會破音。
$INSTALLSKIP"

STRINGSTEP7="
 [07/15] 原廠 HI-FI 隱藏功能
$SEPARATOR

 啟用小米、一加、Realme 與 OPPO
 的底層原廠音訊開關：

 • 開啟 24 位元 HD 高畫質錄音
 • 啟用 Hi-Fi DAC 與低延遲模式
 • 注入 android.hardware.audio.pro 專業權限
"

STRINGSTEP8="
 [08/15] 耳機高通濾波器調整 (4 HZ)
$SEPARATOR

 將 mixer_paths 中耳機輸出的高通濾波器
 (HPF) 截止頻率由 ~25 Hz 降至 4 Hz。

 • 釋放真實的極低頻 (Sub-Bass) 重低音細節
 • 將耳機驅動電路切換至 Hi-Fi 高品質供電模式
$INSTALLSKIP"

STRINGSTEP9="
 [09/15] 系統屬性調校 (SYSTEM.PROP)
$SEPARATOR

 優化底層 AudioFlinger 與音訊驅動屬性：

 • 調校 Android 重採樣濾波係數
 • 降低 AAudio MMAP 音訊輸出延遲
 • 停用 AAC 編碼器的動態範圍壓縮
$INSTALLSKIP"

STRINGSTEP10="
 [10/15] 藍牙音訊全方位優化
$SEPARATOR

 提升藍牙無線音訊傳輸品質：

 • 解鎖 SBC 編碼高位元率模式 (SBC Dual Channel / HD)
 • 優化 AptX Adaptive 參數
 • 停用「絕對音量」(徹底解決部分藍牙
   耳機音量過小的問題)
$INSTALLSKIP"

STRINGSTEP11="
 [11/15] DIRECT PCM 直通輸出
$SEPARATOR

 在音訊輸出策略中加入 DIRECT_PCM 旗標。

 允許相容播放器 (如 Poweramp、UAPP、Neutron)
 繞過 AudioFlinger 混音器，將無損訊號直送 DAC。
"

STRINGSTEP12="
 [12/15] 系統音效處理策略
$SEPARATOR

 管理系統層級的後製音效
 (空間音訊、殘響、原廠等化器)。

 [!] 選擇「全部停用」將同時關閉
     Dolby Atmos、Dirac 與米音。

  [VOL+] 下一個      ┃   [VOL-] 選擇

 1. 跳過      • 保留現有所有音效
 2. 部分停用  • [建議] 關閉假 3D 與殘響，
                保留基礎等化器
 3. 全部停用  • 完全關閉所有音效庫 (純淨輸出)
"

STRINGSTEP13="
 [13/15] 機型專屬 TINYMIX 硬體調校
$SEPARATOR

 開機時針對您的手機晶片套用專屬的
 ALSA 混音器暫存器指令：

 • 調校智慧功放晶片 (Cirrus Logic, TAS, SmartPA)
 • 優化耳機推力與麥克風 ADC 採樣增益
$INSTALLSKIP"

STRINGSTEP14="
 [14/15] DOLBY ATMOS 杜比全景聲調校
$SEPARATOR

 優化杜比全景聲 (DAX) 設定檔：

 • 停用自動音量平衡 (避免音量忽大忽小)
 • 關閉破壞相位的人工 3D 環繞與人聲壓縮
 • 呈現更平直、自然的聲音表現
"

STRINGSTEP15="
 [15/15] 清除 QUALCOMM ACDB 硬體限制
$SEPARATOR

 高通 ACDB 檔案包含原廠的 DSP 音量上限
 以及硬體保護限制。

 此選項可清空指定校準檔以解除硬體上限：

  [VOL+] 下一個      ┃   [VOL-] 選擇

 1. 跳過      • 保持原廠校準檔案
 2. 基礎      • [安全] 解除耳機 / 藍牙 / HDMI 限制
 3. 通用      • 基礎 + 清除 General 通用校準
 4. 揚聲器    • [注意] 清除外放限制 (最大音量可能有雜音)
"

STRINGSTEP151="
 [15/15] 安裝預調校 ACDB 檔案
$SEPARATOR

 已為您的機型找到經過驗證的專屬
 ACDB 補丁檔案。

 安全解除硬體音量限制，避免驅動異常。
"

final_print_text() {
  cat <<EOF
$SEPARATOR
              已配置設定總覽
$SEPARATOR

  01 音量調節級數         : $VOLSTEPS
  02 音樂最大音量         : $VOLMEDIA
  03 麥克風靈敏度         : $VOLMIC
  04 音訊位元深度         : $BITNES
  05 音訊採樣頻率         : $SAMPLERATE
  06 停用限制器與動態壓縮 : $STEP6
  07 原廠 Hi-Fi 隱藏特性  : $STEP7
  08 超低音與混音器補丁   : $STEP8
  09 build.prop 系統調校  : $STEP9
  10 藍牙音訊深度優化     : $STEP10
  11 Direct PCM 直通輸出  : $STEP11
  12 音訊效果停用策略     : $STEP12
  13 機型專屬硬體調校     : $STEP13
  14 杜比 Dolby Atmos 調校: $STEP14
  15 ACDB 校準修改        : $([ "$PATCHACDB" != "false" ] && echo "$PATCHACDB" || echo "$DELETEACDB")

$SEPARATOR
  裝置型號 : $DEVICE
  模組版本 : $VERSION
$SEPARATOR

 正在應用配置並修補系統檔案...
 請稍候...
EOF
}

HW_HEADER="             [ 裝置音訊硬體檢測 ]"
HW_CIRRUS="揚聲器擴大機晶片 : Cirrus Logic (CS35L41)"
HW_TFA="揚聲器擴大機晶片 : NXP / Goodix TFA"
HW_TAS="揚聲器擴大機晶片 : Texas Instruments (TAS)"
HW_AWINIC="揚聲器擴大機晶片 : Awinic (AW88xx)"
HW_MAXIM="揚聲器擴大機晶片 : Maxim Integrated"
HW_WSA="揚聲器擴大機晶片 : Qualcomm WSA"
HW_WCD="主要音訊編解碼器 : Qualcomm WCD (Aqstic Hi-Fi)"
HW_ESS="獨立 Hi-Fi DAC   : ESS Sabre"
HW_AKM="獨立 Hi-Fi DAC   : Asahi Kasei (AKM)"
HW_SOC="主要音訊編解碼器 : 處理器整合式音訊解碼 (SoC)"