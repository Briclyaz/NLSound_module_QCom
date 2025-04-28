#!/bin/bash
# 安裝器選單描述 (繁體中文版)

SELECTE="- [*] 已選擇："
SMENU="安裝 跳過"
SMENU1="跳過 30 50 100"
SMENU2="跳過 78 84 90 96 102 108"
SMENU4="跳過 16位元 24位元 32位元 浮點"
SMENU5="跳過 44100 48000 96000 192000 384000"
SMENU13="跳過 部分禁用 全部禁用"
SMENU16="跳過 基礎 General_cal 揚聲器"
INSTALLSKIP="       [VOL+] - 安裝 | [VOL-] - 跳過"
SMENUAUTOSKIP="            無法安裝，已自動跳過"
SMENUSKIP="- 已跳過設定恢復"

RESTORE="
              • 檢測到先前設定 •

           您可以使用與上次相同的設定

$SEPARATOR
       [VOL+] - 安裝 | [VOL-] - 跳過"

STRINGSTEP1="
請設定我！>.< - 

$SEPARATOR

[1/16]

               • 選擇音量級數 •

          此選項將更改系統音樂音量級數
         通話和其他音訊場景將保持原設定

$SEPARATOR
       [VOL+] 變更選擇 | [VOL-] 確認
$SEPARATOR

1. 跳過 (無更改)
2. 30 (每級 ~1.1-2.0 dB)
3. 50 (每級 ~0.8-1.4 dB)
4. 100 (每級 ~0.4-0.7 dB)"

STRINGSTEP2="
[2/16]

            • 選擇音樂音量等級 •

         此選項將更改音樂最大音量閾值
           數值越大，最大音量越高

                   警告：
           數值過高可能導致音訊失真

                   注意：
               不影響藍牙裝置

$SEPARATOR
       [VOL+] 變更選擇 | [VOL-] 確認
$SEPARATOR

1. 跳過 (無更改)
2. 78
3. 84 (多數裝置預設值)
4. 90
5. 96
6. 102
7. 108"

STRINGSTEP3="
[3/16]

              • 選擇麥克風敏感度 •

           此選項將更改系統麥克風敏感度
             數值越大，錄音音量越高

                    警告：
            數值過高可能導致音訊失真

                    注意：
                不影響藍牙裝置

$SEPARATOR
       [VOL+] 變更選擇 | [VOL-] 確認
$SEPARATOR

1. 跳過 (無更改)
2. 78
3. 84 (多數裝置預設值)
4. 90
5. 96
6. 102
7. 108"

STRINGSTEP4="
[4/16]

              • 選擇音訊位元深度 •

           此選項將配置裝置音訊處理參數

$SEPARATOR
       [VOL+] 變更選擇 | [VOL-] 確認
$SEPARATOR

1. 跳過 (無更改)
2. 16 位元
3. 24 位元
4. 32 位元
5. 浮點 (最佳品質)"

STRINGSTEP5="
[5/16]

                • 選擇採樣率 •

          此選項將配置裝置音訊處理參數

$SEPARATOR
       [VOL+] 變更選擇 | [VOL-] 確認
$SEPARATOR

1. 跳過 (無更改)
2. 44100 Hz
3. 48000 Hz
4. 96000 Hz
5. 192000 Hz
6. 384000 Hz"

STRINGSTEP6="
[6/16]

              • 停用音訊干預 •

          此選項將停用系統各種影響正常
              音訊傳輸的優化功能

$SEPARATOR
       [VOL+] - 安裝 | [VOL-] - 跳過"

STRINGSTEP7="
[7/16]

        • 修補 device_features 檔案 •

        此選項將啟用 Hi-Fi 支援、HD 錄音
         解鎖採樣率並提升 VoIP 通話品質"

STRINGSTEP8="
[8/16]

          • 其他 mixer_paths 修補 •

          停用超出人類聽覺範圍的頻率截剪
           提升細節表現力、音場和音樂性

$SEPARATOR
       [VOL+] - 安裝 | [VOL-] - 跳過"

STRINGSTEP9="
[9/16]

            • build.prop 調整 •

            對音質影響最大的選項之一
            包含大量全局設定，可顯著
                提升音訊品質

$SEPARATOR
       [VOL+] - 安裝 | [VOL-] - 跳過"

STRINGSTEP10="
[10/16]

              • 改進藍牙音質 •

          最大限度提升藍牙音質，並修復
          AAC 編解碼器自動關閉的問題

$SEPARATOR
       [VOL+] - 安裝 | [VOL-] - 跳過"

STRINGSTEP11="
[11/16]

               • 變更音訊輸出 •

        將 DIRECT 切換為 DIRECT_PCM
           以獲得更好的細節和音質

$SEPARATOR"

STRINGSTEP12="
[12/16]

            • 安裝自訂 IIR 預設 •

           IIR 影響 DSP 處理後聲音的
            最終頻率響應曲線，相當於
               系統級等化器預設

$SEPARATOR"

STRINGSTEP13="
[13/16]

               • 忽略音訊效果 •

           通過停用音訊處理來提升音質
           會導致 XiaomiParts、Dirac
               Dolby 等音效失效

                    注意：
         當選擇此選項時，第15項將無法被選擇。

$SEPARATOR
       [VOL+] 變更選擇 | [VOL-] 確認
$SEPARATOR

1. 跳過 (無更改)
2. 停用部分音效
3. 停用全部音效。顯著提升音質
但會降低音量並可能導致部分應用異常"

STRINGSTEP14="
[14/16]

              • 安裝個性化調整 •

          僅相容部分裝置。根據裝置型號
        應用不同參數，修改 mixer_paths
              和 tinymix 設定

                   注意：
         啟用可改善第4、5項的應用效果

$SEPARATOR
       [VOL+] - 安裝 | [VOL-] - 跳過"

STRINGSTEP15="
[15/16]

            • Dolby Atmos 設定 •

            通過停用冗余功能和機制
            進一步調校 Dolby 音效

$SEPARATOR"

STRINGSTEP16="
           • 修改 ACDB 檔案 •

移除 AUX、藍牙和裝置揚聲器的
所有輸出限制

 選項說明：
2. 移除 AUX/藍牙/HDMI 限制
不影響 General_cal

3. 同選項2，但移除 General_cal
僅在不會導致無聲時建議使用

4. 同選項3，但移除揚聲器限制
高風險 - 可能因移除低頻限制
在高音量時損壞揚聲器

 警告：
不當使用(如高音量)可能導致硬體損壞
和系統卡頓。這些參數效果顯著但風險高
我們不承擔任何責任

$SEPARATOR
       [VOL+] 變更選擇 | [VOL-] 確認
$SEPARATOR

1. 跳過 (無更改)
2. 基礎 .acdb 刪除
3. 基礎 + General_cal 刪除
4. 基礎 + 揚聲器限制刪除 + General_cal 刪除"

STRINGSTEP161="
          • 安裝修改版 ACDB 檔案 •

         停用限制器並修改 ACDB 檔案中
             重採樣器的工作模式

                  注意：
        在 BBK 集團裝置上可能因限制失效"

final_print_text() {
    cat << EOF
$SEPARATOR
        
                ◍ 您的設定 ◍
          
     1  音量級數               $VOLSTEPS 
     2  最大音量等級            $VOLMEDIA 
     3  麥克風敏感度            $VOLMIC 
     4  音訊格式               $BITNES 
     5  採樣率                 $SAMPLERATE 
     6  停用干預               $STEP6 
     7  device_features 修補  $STEP7 
     8  其他 mixer_paths 修補  $STEP8 
     9  build.prop 調整       $STEP9 
    10  藍牙改進               $STEP10 
    11  音訊輸出變更            $STEP11 
    12  自訂 IIR 預設          $STEP12 
    13  忽略音效               $STEP13 
    14  個性化調整             $STEP14 
    15  Dolby Atmos 設定      $STEP15 
    16  ACDB 修改             $([  $PATCHACDB  !=  false  ] && echo  $PATCHACDB  || echo  $DELETEACDB ) 

$SEPARATOR

               • 裝置信息 •

       模組版本        $VERSION 
       裝置型號        $DEVICE 
  
$SEPARATOR

 - 安裝已開始，請稍候 
EOF
}