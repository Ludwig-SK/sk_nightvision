# [sk_nightvision](https://github.com/Ludwig-SK/sk_nightvision)

マルチスタイル・マルチフレームワーク対応の暗視装備スクリプトです。ナイトビジョン・サーマル・フラッシュライトの3モードと、StateBagによる周囲プレイヤーへのライト同期を備えます。

---

## 🌟 主な特徴

- **マルチスタイル対応**: ヘルメット・ゴーグル・フルフェイスマスクなど、複数の装備タイプを `config.lua` で自由に定義できます。
- **3つのビジョンモード**: ナイトビジョン・サーマルビジョン・フラッシュライト（スタイルごとに有効/無効を設定可）。
- **2種類のNVG光電管タイプ**: スタイルごとに**緑色光電管**（標準の `SetNightvision` 使用）または**白色光電管**（タイムサイクル＋環境点光源使用）を選択できます。サーマルの各パラメータもスタイルごとに細かく設定可能です。
- **バイザー上げ下ろし**: `EnableVisor = true` のスタイルはバイザーの跳ね上げアニメーション付きでON/OFFを切り替えられます。`EnableVisor = false` のスタイルはアイテム使用で即時ON/OFFします。
- **干渉アイテムの自動復元**: 装備時に干渉するプロップ・コンポーネント（帽子・メガネ等）を自動で退避し、取り外し時に元通り復元します。スタイルを切り替えた場合も最初に退避した状態まで正しく復元されます。
- **フラッシュライト同期**: StateBagを利用して周囲プレイヤーのクライアントでもライトを描画します。自分自身のライトも同様に描画されます。
- **スタイルごとの細かな設定**: アニメーション・サウンドの有無とファイルを装備スタイルごとに個別指定できます。未指定のキーはグローバル設定にフォールバックします。
- **ジョブ制限**: スタイルごとに使用を許可するジョブとグレードを設定できます。
- **マルチフレームワーク対応**: QB-Core・QBX・ESX・ox_inventory・standaloneを自動検出します。

---

## 📦 ファイル構成

```
sk_nightvision/
  client.lua
  server.lua
  config.lua
  fxmanifest.lua
  html/
    sounds/
      goggles_beep.mp3
      goggles_mechanical.mp3
      photon.mp3
  locales/
    en.lua
    ja.lua
```

---

## 🛠 インベントリへのアイテム登録

### ox_inventory の場合
`ox_inventory/data/items.lua` に追加してください。

```lua
['nightvision_helmet'] = {
    label = '暗視ヘルメット',
    weight = 800,
    stack = false,
    close = true,
    description = '暗視・サーマル・ライト機能を備えた防弾ヘルメット。'
},
['nightvision_goggles'] = {
    label = 'タクティカルゴーグル',
    weight = 300,
    stack = false,
    close = true,
    description = 'ストラップ固定式の軽量なサーマル・ライト装置。'
},
['nightvision_fullface'] = {
    label = '機能性フルフェイスマスク',
    weight = 800,
    stack = false,
    close = true,
    description = '暗視・サーマル機能を内蔵した機能性フルフェイスマスク。'
},
```

画像ファイルは `ox_inventory/web/images/` に配置してください。

### qb-core / qb-inventory の場合
`qb-core/shared/items.lua` に追加してください。

```lua
['nightvision_helmet'] = {
    ['name'] = 'nightvision_helmet',
    ['label'] = '暗視ヘルメット',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_helmet.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = '暗視・サーマル・ライト機能を備えた防弾ヘルメット。'
},
['nightvision_goggles'] = {
    ['name'] = 'nightvision_goggles',
    ['label'] = 'タクティカルゴーグル',
    ['weight'] = 300,
    ['type'] = 'item',
    ['image'] = 'nightvision_goggles.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'ストラップ固定式の軽量なサーマル・ライト装置。'
},
['nightvision_fullface'] = {
    ['name'] = 'nightvision_fullface',
    ['label'] = '機能性フルフェイスマスク',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_fullface.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = '暗視・サーマル機能を内蔵した機能性フルフェイスマスク。'
},
```

画像ファイルは `qb-inventory/html/images/` に配置してください。

---

## 🔊 音声ファイルの準備

本スクリプトは `xsound` を通じて周囲のプレイヤーに3D空間音声を再生します。デフォルトの音声ファイル（`goggles_mechanical.mp3`・`goggles_beep.mp3`・`photon.mp3`）はスクリプトに同梱されています。

1. 独自の音声ファイルを使用したい場合は、MP3ファイルを `html/sounds/` フォルダに追加し、各スタイルの `SoundSettings.ToggleSound` / `SoundSettings.SwitchSound` にファイル名を指定してください。
2. `xsound` を使用しない場合は `Config.UseXSound = false` に設定してください。

---

## ⚙ 設定 (config.lua)

### グローバル設定

| キー | 説明 |
| :--- | :--- |
| `Config.Framework` | フレームワーク指定。`"auto"` で自動検出（`"qb"` / `"qbx"` / `"esx"` / `"standalone"` も指定可） |
| `Config.Language` | 使用言語（`"ja"` / `"en"`） |
| `Config.EnableNotifications` | 通知の有効/無効 |
| `Config.EnableSounds` | サウンド機能の有効/無効 |
| `Config.UseXSound` | xsoundによる3D空間音声の有効/無効 |
| `Config.RestrictByJob` | ジョブ制限の有効/無効 |
| `Config.AutoUnequipInVehicle` | 乗車時の自動解除の有効/無効（バイク・軍用車両は対象外） |
| `Config.ForceFirstPerson` | NVG・サーマル使用中に一人称カメラを強制するか |

### `Config.Items`

インベントリのアイテム名とスタイル名の対応を定義します。

```lua
Config.Items = {
    ["nightvision_helmet"]   = "helmet",
    ["nightvision_goggles"]  = "goggles",
    ["nightvision_fullface"] = "fullface",
}
```

### `Config.Styles`

装備スタイルごとの詳細設定です。スタイルは自由に追加・削除できます。

| キー | 説明 |
| :--- | :--- |
| `NVGType` | NVGの光電管タイプ: `"green"`（デフォルト）または `"white"`。詳細は[NVG光電管タイプ](#-nvg光電管タイプ)を参照。 |
| `SlotType` | `"prop"` または `"component"` |
| `Slot` | プロップ/コンポーネントのスロット番号 |
| `ConflictingProps` | 装備時に退避するプロップのスロット番号リスト |
| `ConflictingComponents` | 装備時に退避するコンポーネントのスロット番号リスト |
| `EnableVisor` | バイザーの上げ下ろし機能を使用するか。`false` の場合はアイテム使用でON/OFFを切り替え |
| `EnableToggleAnimation` | バイザーアニメーションを使用するか（`EnableVisor = true` のスタイルのみ有効） |
| `EnableCommands` | キーバインドによる操作を許可するか |
| `EnableItemUse` | アイテム使用による装着を許可するか |
| `EnableModes` | `NVG` / `Thermal` / `Light` それぞれの有効/無効 |
| `PermittedJobs` | 使用を許可するジョブ名とグレード（`nil` または省略で全員許可） |
| `Male` / `Female` | プロップ/コンポーネントのモデルID・テクスチャID。`DownModel`/`DownTexture` がバイザーを降ろした状態、`UpModel`/`UpTexture` が上げた状態 |
| `Flashlight` | フラッシュライトの設定: `offset`・`color`・`distance`・`brightness`・`hardness`・`radius`・`falloff` |

#### `AnimationSettings`（スタイル個別、省略可）

省略したキーはグローバルの `Config.AnimationSettings` の値が使われます。

| キー | 説明 |
| :--- | :--- |
| `EnableEquipAnim` | 装着時アニメーションの有効/無効 |
| `EnableVisorAnim` | バイザー上げ下ろし時アニメーションの有効/無効 |
| `EnableUnequipAnim` | 取り外し時アニメーションの有効/無効 |
| `VisorDownDict` / `VisorDownAnim` | バイザーを降ろすアニメーション |
| `VisorUpDict` / `VisorUpAnim` | バイザーを上げるアニメーション |
| `DurationMS` | バイザーアニメーションの長さ（ミリ秒） |
| `EquipDict` / `EquipAnim` / `EquipDuration` | 装着アニメーション |
| `UnequipDict` / `UnequipAnim` / `UnequipDuration` | 取り外しアニメーション |

#### `SoundSettings`（スタイル個別、省略可）

省略したキーはグローバルの `Config.XSoundSettings` の値が使われます。

| キー | 説明 |
| :--- | :--- |
| `EnableToggleSound` | バイザー上げ下ろし時の音声再生の有効/無効 |
| `EnableSwitchSound` | モード切替時の音声再生の有効/無効 |
| `ToggleSound` | バイザー上げ下ろし時に再生するMP3ファイル名 |
| `SwitchSound` | モード切替時に再生するMP3ファイル名 |
| `Volume` | 音量（0.0〜1.0） |
| `Distance` | 3D音声の聞こえる距離（メートル） |

#### `ThermalSettings`（スタイル個別、省略可）

省略したキーはグローバルの `Config.Thermal` の値が使われます。

| キー | 説明 |
| :--- | :--- |
| `MaxNoise` | ノイズ/グレインの最大量（0.0〜1.0） |
| `MinNoise` | ノイズ/グレインの最小量 |
| `Intensity` | 熱源ハイライトの明るさ |
| `Heatscale` | 熱源の検出感度。低い値は強い熱源のみ強調し、高い値は壁や地面も光らせる |
| `FadeStartDistance` | 映像がフェードアウトし始める距離（メートル） |
| `FadeEndDistance` | 映像が完全にフェードアウトする距離（メートル） |
| `ColorNear` | 近距離のジオメトリへの色乗算（`{r, g, b}`、各0.0〜1.0）。`{0,0,0}` で色乗算なし |
| `ColorFar` | 遠距離のジオメトリへの色乗算（`{r, g, b}`、各0.0〜1.0） |
| `TimecycleModifier` | サーマル使用中に適用するタイムサイクル |
| `TimecycleStrength` | タイムサイクルの適用強度（0.0〜1.0） |

#### `WhiteNVGSettings`（スタイル個別、省略可・`NVGType = "white"` のみ有効）

省略したキーはグローバルの `Config.WhiteNVG` の値が使われます。

| キー | 説明 |
| :--- | :--- |
| `TimecycleModifier` | 白色NVG使用中に適用するタイムサイクル |
| `TimecycleStrength` | タイムサイクルの適用強度 |
| `AmbientLight.radius` | 環境点光源の有効半径（メートル） |
| `AmbientLight.intensity` | 環境点光源の明るさ倍率 |
| `AmbientLight.color` | 環境点光源の色（`{r, g, b}`、各0〜255） |

### `Config.ControlKeys`

| キー | 説明 |
| :--- | :--- |
| `ToggleGoggles` | バイザー上げ下ろしのキーバインド（デフォルト: `"H"`） |
| `CycleVisionModes` | モード切替のキーバインド（デフォルト: `"J"`） |
| `PadToggle` | コントローラー用のバイザー操作ボタン（不要な場合は `nil`） |
| `PadCycle` | コントローラー用のモード切替ボタン（不要な場合は `nil`） |

---

## 💡 NVG光電管タイプ

各スタイルは `NVGType` フィールドでNVGの描画方式を個別に指定できます。

### `"green"`（デフォルト）
`SetNightvision` を使用する、従来の緑色光電管スタイルです。`NVGType` を省略した場合はこのタイプになります。

### `"white"`
タイムサイクル（デフォルト: `MichaelColorCodeBright`）とカメラ位置への影なし環境点光源を組み合わせた、白色光電管スタイルです。グローバル設定は `Config.WhiteNVG`、スタイル個別の上書きは `WhiteNVGSettings` で行います。

```lua
-- 白色光電管スタイルの設定例
NVGType = "white",
WhiteNVGSettings = {              -- 省略可。省略したキーは Config.WhiteNVG にフォールバック
    TimecycleModifier = "MichaelColorCodeBright",
    TimecycleStrength = 1.0,
    AmbientLight = {
        radius    = 50.0,
        intensity = 20.0,
        color     = {r = 255, g = 255, b = 255},
    },
},
```

---

## 🎮 操作方法

| アクション | 操作 |
| :--- | :--- |
| **装備 / 取り外し** | インベントリからアイテムを使用 |
| **バイザー上げ下ろし** | `H` キー（`EnableVisor = true` のスタイルのみ） |
| **ビジョンモード切替** | `J` キー（バイザーが降りている状態で有効） |

`EnableVisor = false` のスタイルはバイザー操作がなく、アイテム使用のたびに装備/取り外しが切り替わります。

---

## 🔒 ジョブ制限

`Config.RestrictByJob = true` の場合、各スタイルの `PermittedJobs` に記載されたジョブ・グレード以上のプレイヤーのみ装備を使用できます。`PermittedJobs` を `nil` または省略するとジョブ制限なしになります。

```lua
PermittedJobs = {
    ["police"]    = 0,  -- police ジョブのグレード0以上
    ["sheriff"]   = 2,  -- sheriff ジョブのグレード2以上
},
```

---

## 📜 依存関係

- **[xsound](https://github.com/X-Scripts/xsound)**: 3D空間音声に使用（`Config.UseXSound = false` で無効化可）
- 各種インベントリシステム（ox_inventory / qb-inventory / ESX inventory）のいずれか
