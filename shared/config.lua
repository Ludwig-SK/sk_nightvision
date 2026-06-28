Config = {}

-- =========================================================================================
-- [1] General Global Settings
-- =========================================================================================

-- Framework to use.
-- "auto" detects automatically on startup (recommended).
-- Explicit options: "qb" (QB-Core) / "qbx" (QBX) / "esx" (ESX) / "standalone"
Config.Framework = "auto"

-- Language code for notifications and locales.
-- Supported: "ja" (Japanese) / "en" (English)
-- Additional languages can be added by placing a file in the locales/ folder.
Config.Language = "ja"

-- Whether to show on-screen notifications for actions such as equipping and unequipping.
Config.EnableNotifications = true

-- Enables or disables all sound playback.
Config.EnableSounds = true

-- Enables or disables 3D positional audio via xsound.
-- Set to false if xsound is not installed or if audio should be disabled entirely.
Config.UseXSound = true

-- true: enforces the job restrictions defined in each style's PermittedJobs.
-- false: all players can use any gear regardless of job (PermittedJobs is ignored).
Config.RestrictByJob = true

-- true: automatically unequips the gear when entering a standard vehicle.
-- Bikes (class 8) and military vehicles (class 13) are exempt.
Config.AutoUnequipInVehicle = true

-- true: forces first-person camera (view mode 4) while NVG, White NVG, or Thermal is active.
Config.ForceFirstPerson = true

-- Maximum number of flashlights to draw simultaneously for nearby players.
-- Set to 0 for unlimited. High values may impact performance in crowded areas.
Config.MaxVisibleLights = 8



-- =========================================================================================
-- [2] Item Global Defaults & Keybinds
-- =========================================================================================

-- Keybind configuration.
Config.ControlKeys = {
    -- Key assigned to the toggle_nvg command (visor up/down).
    ToggleGoggles    = "H",
    -- Key assigned to the cycle_nvg command (cycle vision modes).
    CycleVisionModes = "J",
    -- Controller button for visor toggle.
    -- Specify a key name from the CONTROL_IDS table (e.g. "INPUT_CONTEXT").
    -- Set to nil if not needed or to avoid conflicts with keyboard bindings.
    PadToggle = nil,
    PadCycle  = nil,
}

-- Settings for the overlay displayed while a vision mode is active.
Config.UI = {
    -- true: shows the lens frame overlay while NVG or Thermal is active
    EnableVignette = true,

    -- "scaleform" : Original BINOCULARS movie method.
    -- "sprite"    : Custom PNG image method using RuntimeTextures.
    -- If a sprite file is missing, it automatically falls back to scaleform.
    VignetteMode = "scaleform",

    -- Used for scaleform mode.
    TextureDict = "sk_nightvision_ui",
    TextureName = "vignette",

    -- Global default for sprite mode.
    -- If a style doesn't specify its own VignetteFile, this value is used.
    VignetteFile = "assets/vignette.png",
    SpriteColor  = {r = 255, g = 255, b = 255, a = 255},

    -- Draw order for the vignette overlay, passed to SetScriptGfxDrawOrder.
    -- Lower values render behind the native HUD (minimap, status icons, etc).
    -- See eGfxDrawOrder:
    --   0: before HUD (priority low)   1: before HUD   2: before HUD (priority high)
    --   3: after HUD (priority low)    4: after HUD    5: after HUD (priority high)
    --   6-8: after fade
    GfxDrawOrder = 0,
}

-- Global sound settings. Any key omitted in a style's SoundSettings falls back to these values.
Config.XSoundSettings = {
    EnableToggleSound = true,  -- Enable/disable sound on visor toggle (global default)
    EnableSwitchSound = true,  -- Enable/disable sound on mode switch (global default)
    ToggleSound = "goggles_mechanical.mp3",
    SwitchSound = "goggles_beep.mp3",
    Volume   = 0.5,   -- Volume (0.0-1.0)
    Distance = 10.0,  -- Distance at which 3D audio is audible (meters)
}

-- Global animation settings. Any key omitted in a style's AnimationSettings falls back to these values.
Config.AnimationSettings = {
    EnableEquipAnim   = true,  -- Enable/disable the equip animation (global default)
    EnableVisorAnim   = true,  -- Enable/disable the visor toggle animation (global default)
    EnableUnequipAnim = true,  -- Enable/disable the unequip animation (global default)
    VisorDownDict   = "anim@mp_helmets@on_foot",
    VisorDownAnim   = "visor_down",
    VisorUpDict     = "anim@mp_helmets@on_foot",
    VisorUpAnim     = "visor_up",
    DurationMS      = 450,
    -- Delay (ms) to trigger prop switch and vision ON when visor goes down.
    VisorDownCallbackDelay = 400,
    -- Delay (ms) to turn off vision when visor starts going up.
    VisorUpCallbackDelay   = 0,

    EquipDict       = "veh@common@fp_helmet@",
    EquipAnim       = "put_on_helmet",
    EquipDuration   = 1500,
    -- Delay (ms) when hands reach the head to show the helmet prop.
    EquipCallbackDelay = 900,

    UnequipDict     = "veh@common@fp_helmet@",
    UnequipAnim     = "take_off_helmet_stand",
    UnequipDuration = 500,
    -- Delay (ms) to turn off vision when unequip animation starts.
    UnequipCallbackDelay = 0,
}

-- Global thermal vision parameter tuning.
-- Any key omitted in a style's ThermalSettings falls back to these values.
Config.Thermal = {
    -- SeethroughSetNoiseAmountMax: maximum grain/noise overlay amount (0.0-1.0; higher = grainier)
    MaxNoise          = 0.1,
    -- SeethroughSetNoiseAmountMin: minimum grain/noise overlay amount
    MinNoise          = 0.0,
    -- SeethroughSetHiLightIntensity: brightness of highlighted heat sources
    Intensity         = 1.0,
    -- SeethroughSetHeatscale: heat source threshold/sensitivity (index 0).
    -- Low values highlight only strong heat sources; high values cause walls and terrain to glow.
    Heatscale         = 0.3,
    -- SeethroughSetFadeStartDistance: distance at which the image begins to fade (meters)
    FadeStartDistance = 100.0,
    -- SeethroughSetFadeEndDistance: distance at which the image is fully faded (meters)
    FadeEndDistance   = 200.0,
    -- SeethroughSetColorNear: color tint applied to nearby geometry (RGB, 0.0-1.0).
    -- Set to {0,0,0} to apply no tint and rely solely on the ThermalVision timecycle.
    ColorNear         = {r = 0.0, g = 0.0, b = 0.0},
    -- SeethroughSetColorFar: color tint applied to distant geometry (RGB, 0.0-1.0).
    ColorFar          = {r = 0.0, g = 0.0, b = 0.0},
    -- TimecycleModifier applied while thermal is active
    TimecycleModifier = "ThermalVision",
    TimecycleStrength = 1.0,
}

-- White phosphor NVG settings (used when EnableModes.WhiteNVG = true).
-- TimecycleModifier: the timecycle applied instead of SetNightvision.
-- AmbientLight: a point light placed at the camera to illuminate the scene,
-- drawn with DrawLightWithRange (no shadow). radius is the distance at which
-- the light fades to zero, so a larger radius with a lower intensity reaches
-- farther while staying dim overall.
--   radius    : effective radius of the light (meters)
--   intensity : brightness multiplier
--   color     : RGB color of the light (should be white/near-white for white phosphor look)
Config.WhiteNVG = {
    TimecycleModifier = "MichaelColorCodeBright",
    TimecycleStrength = 1.0,
    AmbientLight = {
        radius    = 300.0,
        intensity = 10.0,
        color     = {r = 255, g = 255, b = 255},
    },
}

-- Fusion mode settings (used when EnableModes.Fusion = true).
-- Combines the White NVG effect with a glow billboard sprite drawn over nearby peds.
-- TimecycleModifier/Strength/AmbientLight: same as White NVG.
-- OutlineColor: RGBA color used to tint the glow sprite (bright orange by default).
-- OutlineDistance: maximum distance (meters) at which peds are highlighted.
-- MaxHighlighted: maximum number of peds highlighted at once (nearest first),
--   bounding the per-frame draw cost in crowded areas.
-- GlowFile: path to the glow sprite texture (white with radial alpha falloff).
-- GlowSize / GlowRefDistance: the sprite is drawn at GlowSize (screen-fraction)
--   when the ped is at GlowRefDistance meters, and scales inversely with distance.
-- GlowMinSize / GlowMaxSize: clamp range for the scaled sprite size.
-- GlowFadeDistance: the glow fades out over this distance as a ped approaches OutlineDistance.
Config.Fusion = {
    TimecycleModifier = "MichaelColorCodeBright",
    TimecycleStrength = 1.0,
    AmbientLight = {
        radius    = 300.0,
        intensity = 10.0,
        color     = {r = 255, g = 255, b = 255},
    },
    OutlineColor     = {r = 255, g = 140, b = 0, a = 200},
    OutlineDistance  = 80.0,
    MaxHighlighted   = 15,
    GlowFile         = "assets/ped_glow.png",
    GlowSize         = 0.05,
    GlowRefDistance  = 10.0,
    GlowMinSize      = 0.02,
    GlowMaxSize      = 0.10,
    GlowFadeDistance = 15.0,
}
