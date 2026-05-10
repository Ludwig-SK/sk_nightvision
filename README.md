# sk_nightvision

A multi-style, multi-framework night vision gear script for FiveM. Features three vision modes — Night Vision, Thermal, and Flashlight — along with StateBag-based flashlight synchronization to nearby players.

---

## 🌟 Features

- **Multi-style support**: Define any number of gear types (helmet, goggles, full-face mask, etc.) in `config.lua`.
- **Three vision modes**: Night Vision, Thermal Vision, and Flashlight. Each mode can be enabled or disabled per style.
- **Visor toggle**: Styles with `EnableVisor = true` flip the visor up/down with an animation. Styles with `EnableVisor = false` toggle on/off instantly when the item is used.
- **Automatic conflicting item restore**: Props and components that conflict with the gear (hats, glasses, etc.) are saved and cleared on equip, then fully restored on unequip. Restoring works correctly even after switching between styles.
- **Flashlight synchronization**: Uses StateBag to render the flashlight on nearby players' clients. The local player's own light is also rendered.
- **Per-style animation and sound settings**: Animation and sound behavior — including which files to play — can be configured individually per style. Any omitted keys fall back to the global settings.
- **Job restrictions**: Restrict each style to specific jobs and grades.
- **Multi-framework support**: Automatically detects QB-Core, QBX, ESX, ox_inventory, and standalone.

---

## 📦 File Structure

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

## 🛠 Registering Items in Your Inventory

### ox_inventory
Add the following to `ox_inventory/data/items.lua`.

```lua
['nightvision_helmet'] = {
    label = 'Night Vision Helmet',
    weight = 800,
    stack = false,
    close = true,
    description = 'A ballistic helmet with night vision, thermal, and flashlight capabilities.'
},
['nightvision_goggles'] = {
    label = 'Tactical Goggles',
    weight = 300,
    stack = false,
    close = true,
    description = 'Lightweight strap-mounted thermal and light device.'
},
['nightvision_fullface'] = {
    label = 'Functional Full-Face Mask',
    weight = 800,
    stack = false,
    close = true,
    description = 'A full-face mask with built-in night vision and thermal capabilities.'
},
```

Place image files in `ox_inventory/web/images/`.

### qb-core / qb-inventory
Add the following to `qb-core/shared/items.lua`.

```lua
['nightvision_helmet'] = {
    ['name'] = 'nightvision_helmet',
    ['label'] = 'Night Vision Helmet',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_helmet.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A ballistic helmet with night vision, thermal, and flashlight capabilities.'
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
    ['label'] = 'Functional Full-Face Mask',
    ['weight'] = 800,
    ['type'] = 'item',
    ['image'] = 'nightvision_fullface.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A full-face mask with built-in night vision and thermal capabilities.'
},
```

Place image files in `qb-inventory/html/images/`.

---

## 🔊 Audio Setup

This script uses `xsound` to play 3D positional audio to nearby players. The default audio files (`goggles_mechanical.mp3`, `goggles_beep.mp3`, and `photon.mp3`) are included with the script.

1. To use custom audio files, add your MP3 files to the `html/sounds/` folder and specify the filenames in each style's `SoundSettings.ToggleSound` / `SoundSettings.SwitchSound`.
2. To disable xsound entirely, set `Config.UseXSound = false`.

---

## ⚙ Configuration (config.lua)

### Global Settings

| Key | Description |
| :--- | :--- |
| `Config.Framework` | Framework to use. `"auto"` for automatic detection. Also accepts `"qb"`, `"qbx"`, `"esx"`, or `"standalone"`. |
| `Config.Language` | Language to use (`"ja"` or `"en"`) |
| `Config.EnableNotifications` | Enable or disable notifications |
| `Config.EnableSounds` | Enable or disable all sounds |
| `Config.UseXSound` | Enable or disable 3D positional audio via xsound |
| `Config.RestrictByJob` | Enable or disable job-based restrictions |
| `Config.AutoUnequipInVehicle` | Automatically unequip gear when entering a vehicle |
| `Config.ForceFirstPerson` | Force first-person camera while NVG or Thermal is active |
| `Config.RequireScopeForVision` | Only activate vision effects while aiming through a sniper scope |

### `Config.Items`

Maps inventory item names to style names.

```lua
Config.Items = {
    ["nightvision_helmet"]   = "helmet",
    ["nightvision_goggles"]  = "goggles",
    ["nightvision_fullface"] = "fullface",
}
```

### `Config.Styles`

Detailed settings for each gear style. Styles can be freely added or removed.

| Key | Description |
| :--- | :--- |
| `SlotType` | `"prop"` or `"component"` |
| `Slot` | Slot number for the prop or component |
| `ConflictingProps` | List of prop slot numbers to save and clear on equip |
| `ConflictingComponents` | List of component slot numbers to save and clear on equip |
| `EnableVisor` | Whether to use visor toggle. If `false`, the item equips/unequips directly on use with no visor action. |
| `EnableToggleAnimation` | Whether to play the visor animation (only applies when `EnableVisor = true`) |
| `EnableCommands` | Allow keybind-based operation |
| `EnableItemUse` | Allow equipping via item use |
| `EnableModes` | Enable or disable each of `NVG`, `Thermal`, and `Light` individually |
| `PermittedJobs` | Jobs and minimum grades allowed to use this style. Omit or set to `nil` to allow all players. |
| `Male` / `Female` | Model and texture IDs for the prop or component. `DownModel`/`DownTexture` is the visor-down state; `UpModel`/`UpTexture` is the visor-up state. |
| `Flashlight` | Flashlight settings: offset, color, distance, brightness, etc. |

#### `AnimationSettings` (per-style, optional)

Any omitted keys fall back to the global `Config.AnimationSettings`.

| Key | Description |
| :--- | :--- |
| `EnableEquipAnim` | Enable or disable the equip animation |
| `EnableVisorAnim` | Enable or disable the visor toggle animation |
| `EnableUnequipAnim` | Enable or disable the unequip animation |
| `VisorDownDict` / `VisorDownAnim` | Animation for visor-down |
| `VisorUpDict` / `VisorUpAnim` | Animation for visor-up |
| `DurationMS` | Duration of the visor animation in milliseconds |
| `EquipDict` / `EquipAnim` / `EquipDuration` | Equip animation |
| `UnequipDict` / `UnequipAnim` / `UnequipDuration` | Unequip animation |

#### `SoundSettings` (per-style, optional)

Any omitted keys fall back to the global `Config.XSoundSettings`.

| Key | Description |
| :--- | :--- |
| `EnableToggleSound` | Enable or disable sound on visor toggle |
| `EnableSwitchSound` | Enable or disable sound on mode switch |
| `ToggleSound` | MP3 filename to play on visor toggle |
| `SwitchSound` | MP3 filename to play on mode switch |
| `Volume` | Volume level (0.0 to 1.0) |
| `Distance` | Distance at which 3D audio is audible (in meters) |

### `Config.ControlKeys`

| Key | Description |
| :--- | :--- |
| `ToggleGoggles` | Keybind for visor toggle (default: `"H"`) |
| `CycleVisionModes` | Keybind for cycling vision modes (default: `"J"`) |
| `PadToggle` | Controller button for visor toggle. Set to `nil` to disable. |
| `PadCycle` | Controller button for mode cycling. Set to `nil` to disable. |

---

## 🎮 Controls

| Action | Input |
| :--- | :--- |
| **Equip / Unequip** | Use the item from inventory |
| **Visor Toggle** | `H` key (styles with `EnableVisor = true` only) |
| **Cycle Vision Mode** | `J` key (only available while visor is down) |

Styles with `EnableVisor = false` have no visor action. Each item use toggles the gear on or off directly.

---

## 🔒 Job Restrictions

When `Config.RestrictByJob = true`, only players whose job and grade meet the requirements defined in each style's `PermittedJobs` can use that gear. Omitting `PermittedJobs` or setting it to `nil` allows all players.

```lua
PermittedJobs = {
    ["police"]  = 0,  -- police job, grade 0 or above
    ["sheriff"] = 2,  -- sheriff job, grade 2 or above
},
```

---

## 📜 Dependencies

- **[xsound](https://github.com/Xogy/xsound)**: Used for 3D positional audio. Can be disabled with `Config.UseXSound = false`.
- One of the following inventory systems: ox_inventory / qb-inventory / ESX inventory
