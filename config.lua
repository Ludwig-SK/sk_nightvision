Config = {}

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

-- Maps inventory item names to gear style names.
-- Key: item name as registered in the inventory system / Value: key in Config.Styles
Config.Items = {
    ["nightvision_helmet"]   = "helmet",
    ["nightvision_goggles"]  = "goggles",
    ["nightvision_fullface"] = "fullface",
}

-- Gear style definitions.
-- Styles can be freely added or removed. Link them to Config.Items using matching key names.
Config.Styles = {
    ["helmet"] = {
        -- NVG phosphor type: "green" (default, uses SetNightvision) or "white" (uses timecycle + ambient light).
        -- Omitting this field defaults to "green".
        -- NVGType = "green",
        -- Whether to use a prop (hat slot, etc.) or a component (mask slot, etc.).
        -- "prop": uses SetPedPropIndex / ClearPedProp
        -- "component": uses SetPedComponentVariation
        SlotType = "prop",

        -- Slot number for the prop or component.
        -- Props:      0=hat, 1=glasses, 2=ear, 6=watch, 7=bracelet
        -- Components: 1=mask, 3=torso, 4=legs, 5=hands, 6=feet, 7=accessory, 8=undershirt, 9=armor, 10=decal, 11=tops
        Slot = 0,

        -- List of prop slot numbers to save and clear on equip.
        -- These are automatically restored when the gear is removed.
        -- Example: {0} saves and clears the hat slot (slot 0) when equipping a helmet.
        ConflictingProps = {0},

        -- List of component slot numbers to save and clear on equip.
        ConflictingComponents = {},

        -- true: enables visor toggle (H key to flip up/down)
        -- false: each item use directly equips or unequips the gear with no visor action
        EnableVisor = true,

        -- Whether to play the visor animation when toggling (only applies when EnableVisor = true).
        -- Can also be controlled individually via AnimationSettings.EnableVisorAnim.
        EnableToggleAnimation = true,

        -- true: allows operation via keybinds (toggle_nvg / cycle_nvg commands)
        EnableCommands = true,

        -- true: allows equipping by using the item from inventory
        EnableItemUse = true,

        -- Enables or disables each vision mode.
        -- Disabled modes are skipped during cycleVision.
        EnableModes = {
            NVG     = true,  -- Night Vision
            Thermal = true,  -- Thermal Vision
            Light   = true,  -- Flashlight
        },

        -- Maps job names to the minimum grade required to use this style.
        -- Key: job name / Value: minimum grade (0 = no grade restriction)
        -- Omit this field or set it to nil to allow all players regardless of job.
        -- Example: ["police"] = 2 allows only police job grade 2 or above.
        PermittedJobs = {
            ["police"]    = 0,
            ["sheriff"]   = 0,
            ["ambulance"] = 0,
        },

        -- Model and texture IDs for the prop or component.
        -- DownModel/DownTexture: visor-down state (vision active)
        -- UpModel/UpTexture: visor-up state (standby)
        -- Omitting UpModel or setting it to -1 always uses DownModel.
        Male   = { DownModel = 118, DownTexture = 0, UpModel = 119, UpTexture = 0 },
        Female = { DownModel = 117, DownTexture = 0, UpModel = 118, UpTexture = 0 },

        -- Flashlight settings (used when EnableModes.Light = true).
        Flashlight = {
            offset     = vector3(-0.15, 0.2, 0.185),  -- Light origin offset from the head bone (meters)
            color      = {r = 255, g = 255, b = 255},  -- Light color (RGB, 0-255)
            distance   = 60.0,   -- Maximum range of the light (meters)
            brightness = 15.0,   -- Light intensity
            hardness   = 0.8,    -- Edge sharpness of the spotlight (0.0=soft, 1.0=hard)
            radius     = 45.0,   -- Spread angle of the spotlight (larger = wider)
            falloff    = 1.0,    -- Edge falloff (sharpness of the beam boundary)
        },

        -- Per-style animation settings.
        -- Any omitted key falls back to the corresponding value in Config.AnimationSettings.
        -- Omitting the entire table uses the global settings as-is.
        AnimationSettings = {
            EnableEquipAnim   = true,  -- Enable/disable the equip animation
            EnableVisorAnim   = true,  -- Enable/disable the visor toggle animation
            EnableUnequipAnim = true,  -- Enable/disable the unequip animation
            VisorDownDict   = "anim@mp_helmets@on_foot",
            VisorDownAnim   = "visor_down",
            VisorUpDict     = "anim@mp_helmets@on_foot",
            VisorUpAnim     = "visor_up",
            DurationMS      = 750,   -- Visor animation duration (milliseconds)
            EquipDict       = "veh@common@fp_helmet@",
            EquipAnim       = "put_on_helmet",
            EquipDuration   = 1500,  -- Equip animation duration (milliseconds)
            UnequipDict     = "veh@common@fp_helmet@",
            UnequipAnim     = "take_off_helmet_stand",
            UnequipDuration = 500,   -- Unequip animation duration (milliseconds)
        },

        -- Per-style sound settings.
        -- Any omitted key falls back to the corresponding value in Config.XSoundSettings.
        SoundSettings = {
            EnableToggleSound = true,  -- Enable/disable sound on visor toggle
            EnableSwitchSound = true,  -- Enable/disable sound on mode switch
            ToggleSound = "goggles_mechanical.mp3",  -- Audio file played on visor toggle
            SwitchSound = "goggles_beep.mp3",        -- Audio file played on mode switch
            Volume   = 0.5,   -- Volume (0.0-1.0)
            Distance = 10.0,  -- Distance at which 3D audio is audible (meters)
        },

        -- Per-style thermal settings.
        -- Any omitted key falls back to the corresponding value in Config.Thermal.
        -- Omitting the entire table uses the global settings as-is.
        -- helmet: high-performance thermal. Very low noise, long range, sensitive heat detection.
        -- ColorNear/ColorFar are kept at zero to avoid tinting background geometry.
        ThermalSettings = {
            MaxNoise          = 0.02,
            MinNoise          = 0.0,
            Intensity         = 1.5,
            Heatscale         = 0.2,
            FadeStartDistance = 200.0,
            FadeEndDistance   = 350.0,
            ColorNear         = {r = 0.0, g = 0.0, b = 0.0},
            ColorFar          = {r = 0.0, g = 0.0, b = 0.0},
            TimecycleModifier = "ThermalVision",
            TimecycleStrength = 1.0,
        },
    },

    ["goggles"] = {
        -- NVGType = "green",  -- default
        SlotType = "prop",
        Slot = 0,
        ConflictingProps = {0},
        ConflictingComponents = {},
        EnableVisor = true,
        EnableToggleAnimation = true,
        EnableCommands = true,
        EnableItemUse = true,
        EnableModes = {
            NVG     = false,  -- Night Vision not used for this style
            Thermal = true,
            Light   = true,
        },
        PermittedJobs = {
            ["police"]    = 0,
            ["sheriff"]   = 0,
            ["ambulance"] = 0,
        },
        Male   = { DownModel = 147, DownTexture = 0, UpModel = 148, UpTexture = 0 },
        Female = { DownModel = 146, DownTexture = 0, UpModel = 147, UpTexture = 0 },
        Flashlight = {
            offset     = vector3(0.0, 0.2, 0.15),
            color      = {r = 255, g = 255, b = 255},
            distance   = 60.0,
            brightness = 15.0,
            hardness   = 0.8,
            radius     = 45.0,
            falloff    = 1.0,
        },
        AnimationSettings = {
            EnableEquipAnim   = true,
            EnableVisorAnim   = true,
            EnableUnequipAnim = true,
            VisorDownDict   = "anim@mp_helmets@on_foot",
            VisorDownAnim   = "visor_down",
            VisorUpDict     = "anim@mp_helmets@on_foot",
            VisorUpAnim     = "visor_up",
            DurationMS      = 750,
            EquipDict       = "veh@common@fp_helmet@",
            EquipAnim       = "put_on_helmet",
            EquipDuration   = 1500,
            UnequipDict     = "veh@common@fp_helmet@",
            UnequipAnim     = "take_off_helmet_stand",
            UnequipDuration = 500,
        },
        SoundSettings = {
            EnableToggleSound = true,
            EnableSwitchSound = true,
            ToggleSound = "goggles_mechanical.mp3",
            SwitchSound = "goggles_beep.mp3",
            Volume   = 0.5,
            Distance = 10.0,
        },

        -- goggles: slightly reduced thermal performance. More noise, shorter range, dimmer highlight.
        -- ColorNear/ColorFar are kept at zero to avoid tinting background geometry.
        ThermalSettings = {
            MaxNoise          = 0.2,
            MinNoise          = 0.05,
            Intensity         = 0.7,
            Heatscale         = 0.4,
            FadeStartDistance = 60.0,
            FadeEndDistance   = 120.0,
            ColorNear         = {r = 0.0, g = 0.0, b = 0.0},
            ColorFar          = {r = 0.0, g = 0.0, b = 0.0},
            TimecycleModifier = "ThermalVision",
            TimecycleStrength = 1.0,
        },
    },

    ["fullface"] = {
        -- White phosphor NVG: uses timecycle + ambient point light instead of SetNightvision.
        NVGType = "white",
        -- Component type (uses the mask slot).
        SlotType = "component",
        Slot = 1,  -- Mask slot
        ConflictingProps = {0},
        ConflictingComponents = {1},
        EnableVisor = true,
        EnableToggleAnimation = true,
        EnableCommands = true,
        EnableItemUse = true,
        EnableModes = {
            NVG     = true,
            Thermal = true,
            Light   = false,  -- Flashlight not used for this style
        },
        PermittedJobs = {
            ["police"]    = 0,
            ["sheriff"]   = 0,
            ["ambulance"] = 0,
        },
        -- When SlotType = "component", DownModel/UpModel specify the component's DrawableId.
        Male   = { DownModel = 135, DownTexture = 6, UpModel = 135, UpTexture = 1 },
        Female = { DownModel = 135, DownTexture = 6, UpModel = 135, UpTexture = 1 },
        Flashlight = {
            offset     = vector3(0.0, 0.1, 0.15),
            color      = {r = 255, g = 255, b = 255},
            distance   = 60.0,
            brightness = 15.0,
            hardness   = 0.8,
            radius     = 45.0,
            falloff    = 1.0,
        },
        AnimationSettings = {
            EnableEquipAnim   = true,
            EnableVisorAnim   = false,  -- Visor animation not used for this style
            EnableUnequipAnim = true,
            VisorDownDict   = "anim@mp_helmets@on_foot",
            VisorDownAnim   = "visor_down",
            VisorUpDict     = "anim@mp_helmets@on_foot",
            VisorUpAnim     = "visor_up",
            DurationMS      = 750,
            EquipDict       = "veh@common@fp_helmet@",
            EquipAnim       = "put_on_helmet",
            EquipDuration   = 1500,
            UnequipDict     = "veh@common@fp_helmet@",
            UnequipAnim     = "take_off_helmet_stand",
            UnequipDuration = 500,
        },
        SoundSettings = {
            EnableToggleSound = true,
            EnableSwitchSound = true,
            ToggleSound = "photon.mp3",        -- Uses a style-specific audio file
            SwitchSound = "goggles_beep.mp3",
            Volume   = 0.5,
            Distance = 10.0,
        },

        -- Per-style white phosphor NVG settings.
        -- Any omitted key falls back to the corresponding value in Config.WhiteNVG.
        -- Omitting the entire table uses the global settings as-is.
        -- WhiteNVGSettings = {
        --     TimecycleModifier = "MichaelColorCodeBright",
        --     TimecycleStrength = 1.0,
        --     AmbientLight = {
        --         radius    = 50.0,
        --         intensity = 20.0,
        --         color     = {r = 255, g = 255, b = 255},
        --     },
        -- },

        -- fullface: near-global thermal performance.
        -- ColorNear/ColorFar are kept at zero to avoid tinting background geometry.
        -- Slightly reduced Heatscale compared to helmet for a calmer image.
        ThermalSettings = {
            Heatscale         = 0.3,
            ColorNear         = {r = 0.0, g = 0.0, b = 0.0},
            ColorFar          = {r = 0.0, g = 0.0, b = 0.0},
        },
    },
}

-- Enables or disables all sound playback.
Config.EnableSounds = true

-- Enables or disables 3D positional audio via xsound.
-- Set to false if xsound is not installed or if audio should be disabled entirely.
Config.UseXSound = true

-- Global sound settings. Any key omitted in a style's SoundSettings falls back to these values.
Config.XSoundSettings = {
    EnableToggleSound = true,  -- Enable/disable sound on visor toggle (global default)
    EnableSwitchSound = true,  -- Enable/disable sound on mode switch (global default)
    ToggleSound = "goggles_mechanical.mp3",
    SwitchSound = "goggles_beep.mp3",
    Volume   = 0.5,   -- Volume (0.0-1.0)
    Distance = 10.0,  -- Distance at which 3D audio is audible (meters)
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

-- White phosphor NVG settings (used when NVGType = "white").
-- TimecycleModifier: the timecycle applied instead of SetNightvision.
-- AmbientLight: a point light placed at the camera to illuminate the scene.
--   radius    : effective radius of the light (meters)
--   intensity : brightness multiplier
--   color     : RGB color of the light (should be white/near-white for white phosphor look)
Config.WhiteNVG = {
    TimecycleModifier = "MichaelColorCodeBright",
    TimecycleStrength = 1.0,
    AmbientLight = {
        radius    = 50.0,
        intensity = 20.0,
        color     = {r = 255, g = 255, b = 255},
    },
}

-- Settings for the overlay (BINOCULARS scaleform) displayed while a vision mode is active.
Config.UI = {
    -- true: shows the lens frame overlay while NVG or Thermal is active
    EnableVignette = true,
    TextureDict = "sk_nightvision_ui",
    TextureName = "vignette",
}

-- true: automatically unequips the gear when entering a standard vehicle.
-- Bikes (class 8) and military vehicles (class 13) are exempt.
Config.AutoUnequipInVehicle = true

-- true: enforces the job restrictions defined in each style's PermittedJobs.
-- false: all players can use any gear regardless of job (PermittedJobs is ignored).
Config.RestrictByJob = true

-- true: forces first-person camera (view mode 4) while NVG or Thermal is active.
Config.ForceFirstPerson = true

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

-- Global animation settings. Any key omitted in a style's AnimationSettings falls back to these values.
Config.AnimationSettings = {
    EnableEquipAnim   = true,  -- Enable/disable the equip animation (global default)
    EnableVisorAnim   = true,  -- Enable/disable the visor toggle animation (global default)
    EnableUnequipAnim = true,  -- Enable/disable the unequip animation (global default)
    VisorDownDict   = "anim@mp_helmets@on_foot",
    VisorDownAnim   = "visor_down",
    VisorUpDict     = "anim@mp_helmets@on_foot",
    VisorUpAnim     = "visor_up",
    DurationMS      = 750,
    EquipDict       = "veh@common@fp_helmet@",
    EquipAnim       = "put_on_helmet",
    EquipDuration   = 1500,
    UnequipDict     = "veh@common@fp_helmet@",
    UnequipAnim     = "take_off_helmet_stand",
    UnequipDuration = 500,
}
