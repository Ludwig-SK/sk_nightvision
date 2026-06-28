# [sk_nightvision](https://github.com/Ludwig-SK/sk_nightvision)

マルチスタイル・マルチフレームワーク対応の高度な暗視装備（NVG）スクリプトです。ナイトビジョン・サーマル・フラッシュライトの各モードに加え、StateBagによる周囲プレイヤーへのライト同期、ダメージ時のフラッシュ演出、多様なビネット表示形式を備えています。

---

## 🌟 主な特徴

- **マルチスタイル対応**: ヘルメット・ゴーグル・フルフェイスマスクなど、複数の装備タイプを `shared/items.lua` で自由に定義できます。
- **5つのビジョンモード**: グリーンホスファーNVG・ホワイトホスファーNVG・フュージョン・サーマルビジョン・フラッシュライト（スタイルごとに有効/無効を設定可）。
- **2種類のNVG光電管**: スタイルごとに**グリーンホスファー**（標準の `SetNightvision` 使用）または**ホワイトホスファー**（タイムサイクル＋影なし環境点光源使用）を選択できます。
- **フュージョンモード**: ホワイトホスファー演出に加え、周囲のPedをグロービルボードスプライトでハイライトして見つけやすくします。
- **高度なビネット表示**:
  - **Scaleformモード**: GTA純正の双眼鏡エフェクトを使用。
  - **Spriteモード**: 独自のPNG画像（Runtime Texture）を使用し、スタイルごとに異なるレンズ形状を表現可能。
  - スタイルごとにモードを切り替えられます。`Config.UI.VignetteMode` がグローバルの既定値となり、スタイル側で上書き可能です。
- **バイザー上げ下ろし**: `EnableVisor = true` のスタイルは跳ね上げアニメーション付きでON/OFFを切り替えられます。`false` の場合はアイテム使用で即時ON/OFFします。
- **干渉アイテムの自動退避・復元**: 装備時に干渉する帽子やメガネを自動で保存して取り外し、取り外し時に元の状態へ正確に復元します。
- **フラッシュライト同期**: StateBagを利用して周囲プレイヤーのクライアントにもライトをリアルタイム描画します。自分自身のライトも同様に描画されます。
- **リアクティブ・エフェクト**: 装着中にダメージを受けると、画面の揺れとノイズが一時的に強まるフラッシュ演出が発生します。
- **スマートな自動管理**:
  - 乗車時の自動解除（バイクや軍用車両は除外されるため、タクティカルな運用を妨げません）。
  - 水中潜水時の自動バイザーアップ機能。
  - 他のスクリプトによる服装変更を検知して状態をクリーンアップする整合性チェック。
- **スタイルごとの細かな設定**: アニメーション・サウンドの有無とファイルを装備スタイルごとに個別指定できます。未指定のキーはグローバル設定にフォールバックします。
- **ジョブ制限**: スタイルごとに使用を許可するジョブとグレードを設定できます。
- **マルチフレームワーク対応**: QB-Core・QBX・ESX・ox_inventory・standaloneを自動検出します。

---

## 📦 ファイル構成

```
sk_nightvision/
  client/
    cl_main.lua           -- メインロジック・状態管理
    modules/
      cl_gear.lua         -- 装備・モデル管理
      cl_vision.lua       -- ビジョン効果実装
      cl_ui.lua           -- ビネット・UI描画
      cl_flashlight.lua   -- ライト同期・描画
      cl_utils.lua        -- ユーティリティ・アニメーション
  server/
    sv_main.lua           -- サーバーイベント処理
  shared/
    config.lua            -- グローバル設定
    items.lua             -- アイテム・スタイル定義
  bridge/                 -- フレームワーク接続レイヤー
    _init.lua             -- ブリッジ初期化・フレームワーク自動検出
    qb-core.lua
    qbx_core.lua
    es_extended.lua
    qb-inventory.lua
    esx_inventory.lua
    ox_inventory.lua
  fxmanifest.lua
  assets/                 -- ビネット・グロー用PNGファイル
  html/
    sounds/               -- 効果音ファイル
  locales/
    en.lua
    ja.lua
```

---

## 📜 依存関係

- **[xsound](https://github.com/X-Scripts/xsound)**: 3D空間音声に使用（`Config.UseXSound = false` で無効化可）
- 各種インベントリシステム: **ox_inventory** / **qb-inventory** / **ESX inventory** のいずれか

---

## 🚀 設置方法

1. **ダウンロード**: `sk_nightvision` フォルダを `resources` ディレクトリに配置します。
2. **アイテム登録**: 使用しているインベントリシステムに暗視アイテムを登録します（後述）。
3. **サーバー設定**: `server.cfg` に以下を追加します。
   ```cfg
   ensure xsound
   ensure sk_nightvision
   ```
4. **カスタマイズ**: `shared/config.lua` で基本設定を、`shared/items.lua` で装備スタイルを定義します。

---

## 🛠 インベントリへのアイテム登録例

### ox_inventory の場合
`ox_inventory/data/items.lua` に追加してください。
```lua
['nightvision_helmet'] = {
    label = '四眼暗視ヘルメット',
    weight = 800,
    stack = false,
    close = true,
    description = '暗視・サーマル・ライト機能を備えた防弾ヘルメット。'
},
['nightvision_dual'] = {
    label = '二眼暗視ヘルメット',
    weight = 800,
    stack = false,
    close = true,
    description = '暗視・ライト機能を備えた防弾ヘルメット。'
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
    description = '暗視・フュージョン機能を内蔵した機能性フルフェイスマスク。'
},
```
画像ファイルは `ox_inventory/web/images/` に配置してください。

### qb-core / qb-inventory の場合
`qb-core/shared/items.lua` に追加してください。
```lua
['nightvision_helmet'] = {
    ['name'] = 'nightvision_helmet',
    ['label'] = '四眼暗視ヘルメット',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_helmet.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = '暗視・サーマル・ライト機能を備えた防弾ヘルメット。'
},
['nightvision_dual'] = {
    ['name'] = 'nightvision_dual',
    ['label'] = '二眼暗視ヘルメット',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_dual.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = '暗視・ライト機能を備えた防弾ヘルメット。'
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
    ['description'] = '暗視・フュージョン機能を内蔵した機能性フルフェイスマスク。'
},
```
画像ファイルは `qb-inventory/html/images/` に配置してください。

---

## 🔊 音声ファイルの準備

本スクリプトは `xsound` を通じて周囲のプレイヤーに3D空間音声を再生します。デフォルトの音声ファイル（`goggles_mechanical.mp3`・`goggles_beep.mp3`・`photon.mp3`）はスクリプトに同梱されています。

1. 独自の音声ファイルを使用したい場合は、MP3ファイルを `html/sounds/` フォルダに追加し、各スタイルの `SoundSettings.ToggleSound` / `SoundSettings.SwitchSound` にファイル名を指定してください。
2. `xsound` を使用しない場合は `Config.UseXSound = false` に設定してください。

---

## ⚙ 設定 (shared/config.lua)

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
| `Config.ForceFirstPerson` | NVG・ホワイトNVG・フュージョン・サーマル使用中に一人称カメラを強制するか |
| `Config.MaxVisibleLights` | 周囲プレイヤーのライトを同時に描画する最大数（`0` で無制限） |
| `Config.UI.VignetteMode` | グローバルのビネットモード: `"scaleform"`（純正）または `"sprite"`（カスタム画像）。スタイル側で個別に上書き可能 |
| `Config.UI.GfxDrawOrder` | ビネットの描画レイヤー。`0` でネイティブHUDより奥に描画され、ミニマップ・ステータスアイコンを隠さない |

### `Config.Items` / `Config.Styles`

これらはグローバル設定のデフォルト値を定義する `shared/config.lua` ではなく、**`shared/items.lua`** で定義します。`shared/config.lua` 側の設定（`Config.Thermal`・`Config.WhiteNVG`・`Config.Fusion`・`Config.AnimationSettings`・`Config.XSoundSettings` など）は各スタイルのフォールバック値として機能し、`shared/items.lua` 側のスタイル定義で個別に上書きできます。

`Config.Items` はインベントリのアイテム名とスタイル名の対応を定義します。

```lua
Config.Items = {
    ["nightvision_helmet"]   = "helmet",
    ["nightvision_dual"]     = "dual",
    ["nightvision_goggles"]  = "goggles",
    ["nightvision_fullface"] = "fullface",
}
```

### `Config.Styles`

装備スタイルごとの詳細設定です（`shared/items.lua` で定義）。スタイルは自由に追加・削除できます。

| キー | 説明 |
| :--- | :--- |
| `SlotType` | `"prop"` または `"component"` |
| `Slot` | プロップ/コンポーネントのスロット番号 |
| `VignetteMode` | このスタイルのビネットモード（`"scaleform"` または `"sprite"`）。省略時は `Config.UI.VignetteMode` を使用 |
| `VignetteFile` | spriteモード使用時のPNGファイルパス。省略時は `Config.UI.VignetteFile` を使用 |
| `SpriteColor` | spriteモードの色乗算（`{r, g, b, a}`、各0〜255）。白色ベースのPNGに対して色を適用できる |
| `EnableVignette` | `false` でこのスタイルのビネット表示を無効化 |
| `ConflictingProps` | 装備時に退避するプロップのスロット番号リスト |
| `ConflictingComponents` | 装備時に退避するコンポーネントのスロット番号リスト |
| `EnableVisor` | バイザーの上げ下ろし機能を使用するか |
| `EnableToggleAnimation` | バイザーアニメーションを使用するか |
| `EnableCommands` | キーバインドによる操作を許可するか |
| `EnableItemUse` | アイテム使用による装着を許可するか |
| `EnableModes` | 各ビジョンモードの有効/無効（`NVG` / `WhiteNVG` / `Fusion` / `Thermal` / `Light`） |
| `PermittedJobs` | 使用を許可するジョブ名とグレード（`nil` または省略で全員許可） |
| `Male` / `Female` | プロップ/コンポーネントのモデルID・テクスチャID（`DownModel`/`DownTexture` がバイザーを降ろした状態、`UpModel`/`UpTexture` が上げた状態） |
| `Flashlight` | フラッシュライトの設定: `offset`・`color`・`distance`・`brightness`・`hardness`・`radius`・`falloff` |

#### `EnableModes` とビジョンモードの順番

| モード | キー | 説明 |
| :--- | :--- | :--- |
| 1 | `NVG` | グリーンホスファー暗視 |
| 2 | `WhiteNVG` | ホワイトホスファー暗視（タイムサイクル＋環境点光源） |
| 3 | `Fusion` | ホワイトホスファー＋周囲Pedグローハイライト |
| 4 | `Thermal` | サーマルビジョン |
| 5 | `Light` | フラッシュライト（`Flashlight` 設定が必要） |

モードはこの順番でサイクルします。`false` を設定したモードはスキップされます。

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
| `VisorDownCallbackDelay` | バイザーを降ろすアニメーション中にプロップ切替・ビジョンONを発火するまでの遅延（ミリ秒） |
| `VisorUpCallbackDelay` | バイザーを上げるアニメーション中にビジョンOFFを発火するまでの遅延（ミリ秒） |
| `EquipDict` / `EquipAnim` / `EquipDuration` | 装着アニメーション |
| `EquipCallbackDelay` | 装着アニメーション中にプロップを表示するまでの遅延（ミリ秒） |
| `UnequipDict` / `UnequipAnim` / `UnequipDuration` | 取り外しアニメーション |
| `UnequipCallbackDelay` | 取り外しアニメーション開始後にビジョンをOFFにするまでの遅延（ミリ秒） |

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
| `ColorNear` | 近距離ジオメトリへの色乗算（`{r, g, b}`、各0.0〜1.0）。`{0,0,0}` で色乗算なし |
| `ColorFar` | 遠距離ジオメトリへの色乗算（`{r, g, b}`、各0.0〜1.0） |
| `TimecycleModifier` | サーマル使用中に適用するタイムサイクル |
| `TimecycleStrength` | タイムサイクルの適用強度（0.0〜1.0） |

#### `WhiteNVGSettings`（スタイル個別、省略可）

`EnableModes.WhiteNVG = true` のスタイルで有効です。省略したキーはグローバルの `Config.WhiteNVG` の値が使われます。

| キー | 説明 |
| :--- | :--- |
| `TimecycleModifier` | 白色NVG使用中に適用するタイムサイクル |
| `TimecycleStrength` | タイムサイクルの適用強度 |
| `AmbientLight.radius` | 環境点光源の有効半径（メートル）。大きくすると遠くまで届く |
| `AmbientLight.intensity` | 環境点光源の明るさ倍率。小さくすると控えめになる |
| `AmbientLight.color` | 環境点光源の色（`{r, g, b}`、各0〜255） |

#### `FusionSettings`（スタイル個別、省略可）

`EnableModes.Fusion = true` のスタイルで有効です。省略したキーはグローバルの `Config.Fusion` の値が使われます。ホワイトホスファー系の設定（`TimecycleModifier`・`AmbientLight` 等）も `Config.Fusion` にフォールバックします。

| キー | 説明 |
| :--- | :--- |
| `OutlineColor` | Pedハイライト用グロースプライトの色（`{r, g, b, a}`、各0〜255） |
| `OutlineDistance` | ハイライトを適用する最大距離（メートル） |
| `MaxHighlighted` | 同時ハイライトするPedの最大数（近い順）。混雑エリアでの描画コストを制限する |
| `GlowFile` | グロースプライトのPNGファイルパス |
| `GlowSize` | `GlowRefDistance` での基準スプライトサイズ（画面全体を1とした割合） |
| `GlowRefDistance` | `GlowSize` を適用する基準距離（メートル） |
| `GlowMinSize` / `GlowMaxSize` | スプライトサイズのクランプ範囲 |
| `GlowFadeDistance` | `OutlineDistance` に近づくにつれてグローをフェードアウトさせる距離（メートル） |

---

## 🎮 操作方法

| アクション | コマンド | デフォルトキー |
| :--- | :--- | :--- |
| **装備 / 取り外し** | インベントリからアイテムを使用 | - |
| **バイザー上げ下ろし** | `toggle_nvg` | `H` |
| **ビジョンモード切替** | `cycle_nvg` | `J` |

`EnableVisor = false` のスタイルはバイザー操作がなく、アイテム使用のたびに装備/取り外しが切り替わります。バイザーが降りている状態でのみモード切替が有効です。

---

## 🔒 ジョブ制限

`Config.RestrictByJob = true` の場合、各スタイルの `PermittedJobs` に記載されたジョブ・グレード以上のプレイヤーのみ装備を使用できます。`PermittedJobs` を `nil` または省略するとジョブ制限なしになります。

```lua
PermittedJobs = {
    ["police"]    = 0,  -- police ジョブのグレード0以上
    ["sheriff"]   = 2,  -- sheriff ジョブのグレード2以上
},
```
