<div align="center">

[ [English](README.md) ] • [ **Русский** ] • [ [繁體中文](README_ZH.md) ]

# 🎵 NLSound

### Системный модуль комплексного улучшения качества звука для Android.

[![GitHub Release](https://img.shields.io/github/v/release/Briclyaz/NLSound_module_QCom?style=for-the-badge&color=blue&logo=github)](https://github.com/Briclyaz/NLSound_module_QCom/releases)
[![Downloads](https://img.shields.io/github/downloads/Briclyaz/NLSound_module_QCom/total?style=for-the-badge&logo=github&color=34D399)](https://github.com/Briclyaz/NLSound_module_QCom/releases)
[![GitHub Stars](https://img.shields.io/github/stars/Briclyaz/NLSound_module_QCom?style=for-the-badge&color=gold&logo=github)](https://github.com/Briclyaz/NLSound_module_QCom/stargazers)
[![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange?style=for-the-badge&logo=android)](https://github.com/Briclyaz/NLSound_module_QCom)
[![Platform](https://img.shields.io/badge/Platform-Qualcomm%20%7C%20MediaTek-blue?style=for-the-badge)](https://github.com/Briclyaz/NLSound_module_QCom)
[![License](https://img.shields.io/github/license/Briclyaz/NLSound_module_QCom?style=for-the-badge&color=gray)](LICENSE)
[![Telegram Updates](https://img.shields.io/badge/Channel-@nlsound__updates-2CA5E0?style=for-the-badge&logo=telegram)](https://t.me/nlsound_updates)
[![Telegram Support](https://img.shields.io/badge/Support-@nlsound__support-2CA5E0?style=for-the-badge&logo=telegram)](https://t.me/nlsound_support)

<br>

<a href="https://github.com/Briclyaz/NLSound_module_QCom/releases/latest">
  <img src="https://img.shields.io/badge/⚡_СКАЧАТЬ_АКТУАЛЬНЫЙ_РЕЛИЗ-0969DA?style=for-the-badge&logo=github&logoColor=white" height="42" alt="Скачать актуальный релиз"/>
</a>

</div>

---

## ❓ Что такое NLSound и зачем он нужен?

По умолчанию стоковый Android настраивает звук крайне консервативно. Чтобы защитить миниатюрные встроенные динамики от перегрузки и дребезжания, система **сжимает динамический диапазон**, **срезает глубокий суб-бас**, ограничивает шкалу громкости **всего 15 грубыми шагами** и занижает битрейт Bluetooth.

**NLSound** — это системный модуль для устройств с Root-доступом. Он безопасно снимает заводские программные лимитеры, калибрует низкоуровневые регистры аудиочипов и раскрывает реальные возможности встроенного ЦАП, усилителей и микрофонов вашего смартфона.

> [!NOTE]
> **Без фоновых приложений и жора аккумулятора:** NLSound изменяет системные конфигурации и регистры драйверов напрямую. После установки модуль работает полностью в фоне на системном уровне, не требуя сторонних приложений или постоянно работающих служб.

---

## ⚡ Почему NLSound? (Сравнение со стоком)

| Функция | Стоковый Android 📱 | С модулем NLSound 🎵 |
| :--- | :--- | :--- |
| **Шаги громкости** | Всего 15 шагов (резкие скачки) | **30, 50 или 100 плавных делений** |
| **Глубокий саб-бас** | Срезается ниже 25–40 Гц | **Полный диапазон вплоть до 4 Гц** |
| **Динамика (DRC)** | Сжата, громкость приглушается | **Естественная, открытая динамика** |
| **Звук при разряде АКБ**| Падает громкость ниже 20% заряда | **Никакого троттлинга и сжатия звука** |
| **Bluetooth SBC** | Ограничен стандартным битрейтом | **Разблокирован режим SBC HD Dual Channel** |
| **Громкость Bluetooth** | Тихий звук на ряде наушников | **Absolute Volume отключен (полный гейн)** |
| **Прямой вывод звука** | Принудительный микшер AudioFlinger | **Бит-перфект режим Direct PCM** |
| **Dolby Atmos** | Скачки громкости и пустое эхо | **Чистый, сбалансированный профиль** |

---

## 🏗️ Схема прохождения аудиосигнала

```text
[ Плееры (Poweramp / UAPP / Apple Music / Spotify / Я.Музыка) ]
                           │
                           ▼
             ┌───────────────────────────┐
             │   Android AudioFlinger    │ ──► [ОБХОД ЧЕРЕЗ DIRECT_PCM]
             │  (Лишний ресемплинг/микс) │
             └───────────────────────────┘
                           │
                           ▼
             ┌───────────────────────────┐
             │    Лимитеры и компрессия  │ ──► [ОТКЛЮЧЕНЫ DRC И СРЕЗЫ 25 ГЦ]
             └───────────────────────────┘
                           │
                           ▼
             ┌───────────────────────────┐
             │   Аппаратный ЦАП / SmartPA│ ──► [САБ-БАС 4 ГЦ И РЕЖИМ HI-FI]
             └───────────────────────────┘
                           │
                           ▼
              🎧 Наушники / 🔊 Динамики / 📶 Bluetooth HD
```

---

## 🚀 Ключевые возможности

### 🎚️ 1. Плавная регулировка и аппаратный гейн
* **Больше шагов громкости:** Увеличивает шкалу мультимедиа с 15 до **30, 50 или 100 делений** для плавной и точной настройки.
* **Аппаратное усиление:** Раздельная настройка цифрового гейна в микшере для динамиков и проводных наушников без вмешательства в Bluetooth.
* **Чувствительность микрофонов:** Точечная регулировка цифрового тракта записи (DEC) для усиления тихих голосов без перегрузки.

### 🎧 2. Настоящий Hi-Fi и открытый саб-бас
* **Саб-бас без ограничений (4 Гц):** Снижает частоту среза заводского High-Pass фильтра (HPF) наушников с ~25 Гц до **4 Гц**, возвращая глубокий осязаемый бас.
* **Прямой вывод Direct PCM:** Активирует флаги `DIRECT_PCM`, позволяя совместимым плеерам (Poweramp, UAPP, Neutron) передавать звук в ЦАП напрямую, в обход системного микшера.
* **Выбор битности и частоты:** Возможность задать базовую разрядность (до 24/32 бит) и частоту дискретизации (до 96/192/384 кГц) в политиках системы.

### 🔇 3. Отключение динамического сжатия и DRC
* **Без урезания динамики:** Отключает Dynamic Range Compression (DRC) и софтклиппинг, исключая кашу в сложных инструментальных треках.
* **Без троттлинга от батареи:** Запрещает системе программно душить громкость динамиков при падении заряда аккумулятора.

### 📶 4. Оптимизация Bluetooth-аудио
* **SBC HD Dual Channel:** Разблокирует высокий битрейт для универсального кодека SBC.
* **Улучшения aptX Adaptive:** Активирует расширенные параметры aptX Adaptive 2.1/2.2 и Lossless LE.
* **Решение проблемы тихого звука:** Комплексно отключает Absolute Volume, исправляя баг низкой громкости на беспроводных наушниках.

### 🎛️ 5. Очистка эффектов и тюнинг Dolby Atmos
* **Чистый тракт:** Отключает фазовые искажения, синтетическое эхо и виртуализаторы, сохраняя работу ручных эквалайзеров и шумоподавления звонков.
* **Тюнинг Dolby Atmos DAX:** Убирает эффект «звука из бочки», отключает резкие скачки громкости (volume leveler) и зажатость диалогов.

### 📱 6. Индивидуальные аппаратные пресеты под модели
* Автоматически распознает чипы на шинах платы (Cirrus Logic, TI TAS, NXP TFA, Awinic, Qualcomm WSA/WCD).
* Применяет готовые, оптимизированные регистры микшера (`tinymix`) для десятков смартфонов Xiaomi, OnePlus, Realme, Samsung, Sony и Google Pixel.

---

## 📱 Поддержка устройств и оборудования

<details>
<summary><b>Нажмите, чтобы посмотреть список моделей с индивидуальными пресетами</b></summary>
<br>

* **Xiaomi / POCO / Redmi:** 
  * Xiaomi 14 Ultra (`aurora`), Xiaomi 13 Ultra (`ishtar`), Xiaomi 11 Ultra (`star`), Xiaomi 10 Pro (`cmi`), Mi 10 (`umi`);
  * POCO F5 / Redmi Note 12 Turbo (`marble`), POCO F3 / Redmi K40 (`alioth`), POCO X3 Pro (`vayu`), POCO X3 NFC (`surya`), POCO M3 / Redmi 9T (`citrus`, `juice`, `chime`, `lime`);
  * Redmi Note 10 Pro (`sweet`, `mojito`), Redmi Note 9 Pro (`joyeuse`, `curtana`, `gram`, `excalibur`).
* **OnePlus:** 
  * OnePlus 13 (`OP5D55L1`), OnePlus 12 (`OP595DL1`), OnePlus 12R / Ace 2 Pro (`OP5D3BL1`, `OP5D2BL1`), OnePlus Ace 3 (`OP5929L1`);
  * OnePlus 9R, OnePlus 9 Pro (`ingres`), линейка OnePlus 7 / 7T / 7 Pro (`guacamole`, `hotdog`).
* **Realme:** 
  * Realme 12 Pro+ (`RE5C82L1`, `RE5C3B`), Realme GT Neo 5 (`RE5C4FL1`), Realme GT Neo / GT 2 (`RE5473`, `RE879AL1`, `kona`).
* **Google Pixel:** 
  * Pixel 8 и Pixel 8 Pro (`shiba`, `husky`);
  * Pixel 7 Pro с аппаратным байпасом DSP (`cheetah`);
  * Pixel 6, Pixel 6 Pro, Pixel 6a, Pixel 7 (`bluejay`, `oriole`, `raven`, `panther`).
* **Samsung & Sony:** 
  * Samsung Galaxy S22 Ultra (`b0q`);
  * Sony Xperia 1 II (`XQ-AT52`), Sony Xperia 5 IV (`XQ-CQ62`).
* *Для остальных моделей автоматически генерируется адаптивный профиль на базе обнаруженных аудиочипов.*

</details>

<details>
<summary><b>Распознаваемое аудиооборудование (ЦАП и усилители)</b></summary>
<br>

NLSound сканирует системные шины (`I2C`, `SoundWire`, `Slimbus`, `Platform`) для точной настройки:
* **Усилители динамиков:** Cirrus Logic (CS35L41), Texas Instruments (TAS25xx), NXP / Goodix (TFA98xx), Awinic (AW88xx), Maxim Integrated (MAX98373), Qualcomm WSA (WSA88xx).
* **Аудиокодеки и ЦАП:** Qualcomm WCD (Aqstic / Bolero Hi-Fi), ESS Sabre, Asahi Kasei (AKM).

</details>

---

## 🛠️ Интерактивный установщик

При прошивке архива в root-менеджере запускается интерактивное меню, управляемое **клавишами громкости**:

<div align="center">
<table>
<tr>
<td>
<b>&nbsp;&nbsp;🔴&nbsp;&nbsp;🟡&nbsp;&nbsp;🟢&nbsp;&nbsp;&nbsp;&nbsp;terminal — nlsound-installer</b>
<hr>
<pre>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 [01/15] ШАГИ РЕГУЛИРОВКИ ГРОМКОСТИ
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Изменяет количество делений на шкале
 громкости мультимедиа (в стоке Android всего 15).

 [*] Рекомендуется 30 или 50: регулировка плавнее,
 но не требует слишком долгих нажатий.

  [VOL+] След. пункт ┃   [VOL-] Выбрать

 1. Пропустить • По умолчанию (15 шагов)
 2. 30 шагов   • [Рекомендуется] Оптимально
 3. 50 шагов   • Очень плавная шкала
 4. 100 шагов  • Максимально плавно
</pre>
</td>
</tr>
</table>
</div>

* **[VOL+]** — Перемещение по списку / Подтверждение действия.
* **[VOL-]** — Выбор выделенного пункта / Пропуск шага.

> [!TIP]
> **Восстановление в один клик:** При обновлении модуля достаточно нажать **[VOL+]** на первом экране, чтобы автоматически восстановить прошлые настройки за секунду!

---

## 📋 Совместимость и требования

> [!IMPORTANT]
> Наличие Root-прав (через Magisk v24+, KernelSU или APatch) строго обязательно для модификации низкоуровневых политик аудио-HAL и регистров драйверов.

* **Root-менеджеры:** [Magisk](https://github.com/topjohnwu/Magisk) (v24+), [KernelSU](https://github.com/tiann/KernelSU) или [APatch](https://github.com/bmax121/APatch).
* **Архитектура оверлеев:** Полная поддержка Magic Mount, **KernelSU OverlayFS** и **Mountify** (чистое удаление без блокировок файлов).
* **Сторонние аудиомоды:** 100% совместимость с Audio Modification Library (AML), ViPER4Android и JamesDSP.
* **Процессоры:**
  * **Qualcomm Snapdragon:** Полная поддержка (от Snapdragon 625 до 8 Elite).
  * **MediaTek:** Базовая поддержка платформ Dimensity и Helio.
* **Версии Android:** Android 9.0 — Android 15+.

---

## 📥 Установка

1. Скачайте свежий `.zip` архив из раздела [Releases](https://github.com/Briclyaz/NLSound_module_QCom/releases) или нашего [Telegram-канала](https://t.me/nlsound_updates).
2. Откройте приложение **Magisk**, **KernelSU** или **APatch**.
3. Перейдите во вкладку **Модули** и нажмите **Установить из хранилища**.
4. Выберите скачанный `.zip` файл.
5. Настройте нужные опции с помощью **клавиш громкости**.
6. Перезагрузите устройство после окончания прошивки.

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

*Если вам нравится проект, поддержите его звёздочкой на GitHub! ⭐*

</div>

---

## 💬 Поддержка и сообщество

Есть вопросы, пожелания или нашли ошибку?
* 📢 **Новости и обновления:** [@nlsound_updates](https://t.me/nlsound_updates)
* 💬 **Чат техподдержки:** [@nlsound_support](https://t.me/nlsound_support)

---

<div align="center">

**Сделано с ❤️ командой NLSound**

*Некоммерческий проект с открытым исходным кодом. Без рекламы и платных функций.*

</div>
