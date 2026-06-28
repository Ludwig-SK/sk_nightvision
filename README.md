# [sk_nightvision](https://github.com/Ludwig-SK/sk_nightvision)

An advanced multi-style, multi-framework Night Vision Goggle (NVG) script. Features nightvision, thermal, and flashlight modes, StateBag-based flashlight sync to nearby players, a damage flash effect, and flexible vignette overlay support.

---

## 🌟 Features

- **Multi-style support**: Define any number of gear styles (helmets, goggles, full-face masks, etc.) in `shared/items.lua`.
- **5 vision modes**: Green phosphor NVG, white phosphor NVG, Fusion, thermal vision, and flashlight — each individually enabled or disabled per style.
- **Two NVG phosphor types**: Choose **green phosphor** (standard `SetNightvision`) or **white phosphor** (timecycle + shadowless ambient point light) per style.
- **Fusion mode**: White phosphor effect combined with a glow billboard sprite drawn over nearby peds to make them easier to spot.
- **Advanced vignette overlay**:
  - **Scaleform mode**: Uses the native GTA binoculars effect.
  - **Sprite mode**: Loads a custom PNG via Runtime Texture, allowing a unique lens shape per style.
  - The mode can be overridden per style. `Config.UI.VignetteMode` sets the global default.
- **Visor raise/lower**: Styles with `EnableVisor = true` toggle on/off with a flip animation. Styles with `false` toggle immediately on item use.
- **Conflicting item save/restore**: Hats, glasses, and other conflicting props/components are automatically saved on equip and restored exactly on unequip.
- **Flashlight sync**: Uses StateBag to draw flashlights on nearby players' clients in real time. The local player's own light is also rendered.
- **Reactive damage effect**: Taking damage while equipped causes a brief screen shake and noise flash.
- **Smart auto-management**:
  - Auto-unequip on entering a vehicle (bikes and military vehicles are exempt).
  - Auto-visor-up when swimming underwater.
  - Integrity check that detects external outfit changes and cleans up state.
- **Per-style fine-tuning**: Animation and sound settings can be specified individually per style; any omitted key falls back to the global default.
- **Job restriction**: Restrict each style to specific jobs and grades.
- **Multi-framework**: Auto-detects QB-Core, QBX, ESX, ox_inventory, and standalone.

---

## 📦 File Structure

```
sk_nightvision/
  client/
    cl_main.lua           -- Main logic and state management
    modules/
      cl_gear.lua         -- Gear and model management
      cl_vision.lua       -- Vision effect implementation
      cl_ui.lua           -- Vignette and UI rendering
      cl_flashlight.lua   -- Flashlight sync and rendering
      cl_utils.lua        -- Utilities and animation helpers
  server/
    sv_main.lua           -- Server-side event handling
  shared/
    config.lua            -- Global settings and fallback defaults
    items.lua             -- Item and style definitions
  bridge/                 -- Framework abstraction layer
    _init.lua             -- Bridge initialisation and auto-detection
    qb-core.lua
    qbx_core.lua
    es_extended.lua
    qb-inventory.lua
    esx_inventory.lua
    ox_inventory.lua
  fxmanifest.lua
  assets/                 -- Vignette and glow PNG files
  html/
    sounds/               -- Sound effect files
  locales/
    en.lua
    ja.lua
```

---

## 📜 Dependencies

- **[xsound](https://github.com/X-Scripts/xsound)**: Used for 3D spatial audio (can be disabled via `Config.UseXSound = false`)
- An inventory system: **ox_inventory** / **qb-inventory** / **ESX inventory**

---

## 🚀 Installation

1. **Download**: Place the `sk_nightvision` folder in your `resources` directory.
2. **Register items**: Add the nightvision items to your inventory system (see below).
3. **Server config**: Add the following to `server.cfg`:
   ```cfg
   ensure xsound
   ensure sk_nightvision
   ```
4. **Customise**: Edit `shared/config.lua` for global settings and `shared/items.lua` for gear styles.

---

## 🛠 Inventory Item Registration

### ox_inventory
Add to `ox_inventory/data/items.lua`:
```lua
['nightvision_helmet'] = {
    label = 'Quad-Lens NVG Helmet',
    weight = 800,
    stack = false,
    close = true,
    description = 'Ballistic helmet with NVG, thermal, and light capabilities.'
},
['nightvision_dual'] = {
    label = 'Dual-Lens NVG Helmet',
    weight = 800,
    stack = false,
    close = true,
    description = 'Ballistic helmet with NVG and light capabilities.'
},
['nightvision_goggles'] = {
    label = 'Tactical Goggles',
    weight = 300,
    stack = false,
    close = true,
    description = 'Lightweight strap-mounted thermal and light device.'
},
['nightvision_fullface'] = {
    label = 'Tactical Full-Face Mask',
    weight = 800,
    stack = false,
    close = true,
    description = 'Full-face mask with integrated NVG and Fusion capabilities.'
},
```
Place image files in `ox_inventory/web/images/`.

### qb-core / qb-inventory
Add to `qb-core/shared/items.lua`:
```lua
['nightvision_helmet'] = {
    ['name'] = 'nightvision_helmet',
    ['label'] = 'Quad-Lens NVG Helmet',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_helmet.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Ballistic helmet with NVG, thermal, and light capabilities.'
},
['nightvision_dual'] = {
    ['name'] = 'nightvision_dual',
    ['label'] = 'Dual-Lens NVG Helmet',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_dual.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Ballistic helmet with NVG and light capabilities.'
},
['nightvision_goggles'] = {
    ['name'] = 'nightvision_goggles',
    ['label'] = 'Tactical Goggles',
    ['weight'] = 300,
    ['type'] = 'item',
    ['image'] = 'nightvision_goggles.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Lightweight strap-mounted thermal and light device.'
},
['nightvision_fullface'] = {
    ['name'] = 'nightvision_fullface',
    ['label'] = 'Tactical Full-Face Mask',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_fullface.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Full-face mask with integrated NVG and Fusion capabilities.'
},
```
Place image files in `qb-inventory/html/images/`.

---

## 🔊 Sound Files

This script plays 3D spatial audio to nearby players via `xsound`. The default sound files (`goggles_mechanical.mp3`, `goggles_beep.mp3`, `photon.mp3`) are included.

1. To use custom sounds, add MP3 files to `html/sounds/` and set `SoundSettings.ToggleSound` / `SoundSettings.SwitchSound` in the relevant style.
2. To disable xsound entirely, set `Config.UseXSound = false`.

---

## ⚙ Configuration (shared/config.lua)

### Global Settings

| Key | Description |
| :--- | :--- |
| `Config.Framework` | Framework selection. `"auto"` for auto-detection (`"qb"` / `"qbx"` / `"esx"` / `"standalone"` also accepted) |
| `Config.Language` | UI language (`"ja"` / `"en"`) |
| `Config.EnableNotifications` | Enable or disable on-screen notifications |
| `Config.EnableSounds` | Enable or disable all sound playback |
| `Config.UseXSound` | Enable or disable 3D spatial audio via xsound |
| `Config.RestrictByJob` | Enable or disable job-based gear restrictions |
| `Config.AutoUnequipInVehicle` | Auto-unequip on entering a vehicle (bikes and military vehicles are exempt) |
| `Config.ForceFirstPerson` | Force first-person camera while NVG, White NVG, Fusion, or Thermal is active |
| `Config.MaxVisibleLights` | Maximum number of nearby player flashlights rendered simultaneously (`0` for unlimited) |
| `Config.UI.VignetteMode` | Global vignette mode: `"scaleform"` (native) or `"sprite"` (custom PNG). Can be overridden per style |
| `Config.UI.GfxDrawOrder` | Vignette draw layer passed to `SetScriptGfxDrawOrder`. `0` renders behind the native HUD so the minimap and status icons remain visible |

### `Config.Items` / `Config.Styles`

These are defined in **`shared/items.lua`**, not in `shared/config.lua`. The settings in `shared/config.lua` (such as `Config.Thermal`, `Config.WhiteNVG`, `Config.Fusion`, `Config.AnimationSettings`, and `Config.XSoundSettings`) act as fallback defaults for each style; individual style definitions in `shared/items.lua` can override any of these keys.

`Config.Items` maps inventory item names to style names:

```lua
Config.Items = {
    ["nightvision_helmet"]   = "helmet",
    ["nightvision_dual"]     = "dual",
    ["nightvision_goggles"]  = "goggles",
    ["nightvision_fullface"] = "fullface",
}
```

### `Config.Styles`

Defines each gear style (defined in `shared/items.lua`). Styles can be freely added or removed.

| Key | Description |
| :--- | :--- |
| `SlotType` | `"prop"` or `"component"` |
| `Slot` | Prop or component slot index |
| `VignetteMode` | Vignette mode for this style (`"scaleform"` or `"sprite"`). Falls back to `Config.UI.VignetteMode` if omitted |
| `VignetteFile` | PNG file path for sprite mode. Falls back to `Config.UI.VignetteFile` if omitted |
| `SpriteColor` | Color multiplier for sprite mode (`{r, g, b, a}`, 0–255 each). Useful for tinting a white-base PNG |
| `EnableVignette` | Set to `false` to disable the vignette overlay for this style |
| `ConflictingProps` | List of prop slot indices to save and clear on equip |
| `ConflictingComponents` | List of component slot indices to save and clear on equip |
| `EnableVisor` | Whether this style supports visor raise/lower |
| `EnableToggleAnimation` | Whether to play the visor flip animation |
| `EnableCommands` | Whether keybind commands are active for this style |
| `EnableItemUse` | Whether the item can be used to equip this style |
| `EnableModes` | Enable/disable each vision mode (`NVG` / `WhiteNVG` / `Fusion` / `Thermal` / `Light`) |
| `PermittedJobs` | Map of job names to minimum grade. Omit or set to `nil` for no restriction |
| `Male` / `Female` | Prop/component model and texture IDs (`DownModel`/`DownTexture` = visor down, `UpModel`/`UpTexture` = visor up) |
| `Flashlight` | Flashlight settings: `offset`, `color`, `distance`, `brightness`, `hardness`, `radius`, `falloff` |

#### `EnableModes` and Vision Mode Cycle Order

| # | Key | Description |
| :--- | :--- | :--- |
| 1 | `NVG` | Green phosphor nightvision |
| 2 | `WhiteNVG` | White phosphor nightvision (timecycle + ambient point light) |
| 3 | `Fusion` | White phosphor + glow highlight on nearby peds |
| 4 | `Thermal` | Thermal vision |
| 5 | `Light` | Flashlight (requires a `Flashlight` definition) |

Modes cycle in this order. Any mode set to `false` is skipped.

#### `AnimationSettings` (per style, optional)

Omitted keys fall back to `Config.AnimationSettings`.

| Key | Description |
| :--- | :--- |
| `EnableEquipAnim` | Enable or disable the equip animation |
| `EnableVisorAnim` | Enable or disable the visor flip animation |
| `EnableUnequipAnim` | Enable or disable the unequip animation |
| `VisorDownDict` / `VisorDownAnim` | Animation for lowering the visor |
| `VisorUpDict` / `VisorUpAnim` | Animation for raising the visor |
| `DurationMS` | Visor animation duration (ms) |
| `VisorDownCallbackDelay` | Delay (ms) into the down animation before switching the prop and activating vision |
| `VisorUpCallbackDelay` | Delay (ms) into the up animation before deactivating vision |
| `EquipDict` / `EquipAnim` / `EquipDuration` | Equip animation |
| `EquipCallbackDelay` | Delay (ms) into the equip animation before showing the prop |
| `UnequipDict` / `UnequipAnim` / `UnequipDuration` | Unequip animation |
| `UnequipCallbackDelay` | Delay (ms) after the unequip animation starts before turning off vision |

#### `SoundSettings` (per style, optional)

Omitted keys fall back to `Config.XSoundSettings`.

| Key | Description |
| :--- | :--- |
| `EnableToggleSound` | Enable or disable sound on visor toggle |
| `EnableSwitchSound` | Enable or disable sound on mode switch |
| `ToggleSound` | MP3 filename played on visor toggle |
| `SwitchSound` | MP3 filename played on mode switch |
| `Volume` | Volume (0.0–1.0) |
| `Distance` | Distance at which 3D audio is audible (meters) |

#### `ThermalSettings` (per style, optional)

Omitted keys fall back to `Config.Thermal`.

| Key | Description |
| :--- | :--- |
| `MaxNoise` | Maximum noise/grain overlay amount (0.0–1.0) |
| `MinNoise` | Minimum noise/grain overlay amount |
| `Intensity` | Brightness of highlighted heat sources |
| `Heatscale` | Heat source detection sensitivity. Low values highlight only strong sources; high values cause walls and terrain to glow |
| `FadeStartDistance` | Distance at which the image begins to fade (meters) |
| `FadeEndDistance` | Distance at which the image is fully faded (meters) |
| `ColorNear` | Color tint applied to nearby geometry (`{r, g, b}`, 0.0–1.0 each). Use `{0,0,0}` for no tint |
| `ColorFar` | Color tint applied to distant geometry (`{r, g, b}`, 0.0–1.0 each) |
| `TimecycleModifier` | Timecycle modifier applied while thermal is active |
| `TimecycleStrength` | Timecycle modifier strength (0.0–1.0) |

#### `WhiteNVGSettings` (per style, optional)

Active when `EnableModes.WhiteNVG = true`. Omitted keys fall back to `Config.WhiteNVG`.

| Key | Description |
| :--- | :--- |
| `TimecycleModifier` | Timecycle modifier applied during white NVG |
| `TimecycleStrength` | Timecycle modifier strength |
| `AmbientLight.radius` | Effective radius of the ambient point light (meters). Larger values reach further |
| `AmbientLight.intensity` | Brightness multiplier of the ambient point light. Smaller values are dimmer |
| `AmbientLight.color` | Color of the ambient point light (`{r, g, b}`, 0–255 each) |

#### `FusionSettings` (per style, optional)

Active when `EnableModes.Fusion = true`. Omitted keys fall back to `Config.Fusion`. White phosphor settings (`TimecycleModifier`, `AmbientLight`, etc.) also fall back to `Config.Fusion`.

| Key | Description |
| :--- | :--- |
| `OutlineColor` | Color of the ped glow billboard sprite (`{r, g, b, a}`, 0–255 each) |
| `OutlineDistance` | Maximum distance (meters) at which peds are highlighted |
| `MaxHighlighted` | Maximum number of peds highlighted simultaneously (nearest first). Limits per-frame draw cost in crowded areas |
| `GlowFile` | Path to the glow sprite PNG |
| `GlowSize` | Base sprite size (fraction of screen width) at `GlowRefDistance` |
| `GlowRefDistance` | Reference distance (meters) at which `GlowSize` is applied |
| `GlowMinSize` / `GlowMaxSize` | Clamp range for the scaled sprite size |
| `GlowFadeDistance` | The glow fades out over this distance as a ped approaches `OutlineDistance` |

---

## 🎮 Controls

| Action | Command | Default Key |
| :--- | :--- | :--- |
| **Equip / Unequip** | Use item from inventory | - |
| **Visor raise/lower** | `toggle_nvg` | `H` |
| **Cycle vision mode** | `cycle_nvg` | `J` |

Styles with `EnableVisor = false` have no visor toggle; using the item equips or unequips directly. Mode cycling is only available while the visor is down.

---

## 🔒 Job Restrictions

When `Config.RestrictByJob = true`, only players whose job and grade meet the requirements in `PermittedJobs` can use the gear. Omitting `PermittedJobs` or setting it to `nil` removes all restrictions.

```lua
PermittedJobs = {
    ["police"]  = 0,  -- police job, grade 0 or above
    ["sheriff"] = 2,  -- sheriff job, grade 2 or above
},
```
