-- Maps inventory item names to gear style names.
-- Key: item name as registered in the inventory system / Value: key in Config.Styles
Config.Items = {
    ["nightvision_helmet"]   = "helmet",
    ["nightvision_dual"]   = "dual",
    ["nightvision_goggles"]  = "goggles",
    ["nightvision_fullface"] = "fullface",
}

-- Gear style definitions.
Config.Styles = {
    ["helmet"] = {
        SlotType = "prop",
        Slot     = 0, -- hat
        VignetteMode = "sprite",                         -- スタイル単位でspriteモードを使用
        VignetteFile = "assets/vignette_3lens.png",
        SpriteColor  = {r = 0, g = 0, b = 0, a = 255},
        ConflictingProps = {0},
        ConflictingComponents = {},
        EnableVisor = true,
        EnableToggleAnimation = true,
        EnableCommands = true,
        EnableItemUse = true,
        EnableModes = {
            NVG      = true,
            WhiteNVG = false,
            Fusion   = false,
            Thermal  = true,
            Light    = true,
        },
        PermittedJobs = {
            ["police"]    = 0,
            ["sheriff"]   = 0,
            ["ambulance"] = 0,
        },
        Male   = { DownModel = 118, DownTexture = 0, UpModel = 119, UpTexture = 0 },
        Female = { DownModel = 117, DownTexture = 0, UpModel = 118, UpTexture = 0 },
        Flashlight = {
            offset     = vector3(-0.15, 0.2, 0.185),
            color      = {r = 255, g = 255, b = 255},
            distance   = 60.0,
            brightness = 15.0,
            hardness   = 0.8,
            radius     = 45.0,
            falloff    = 1.0,
        },
        -- High-performance thermal for helmet
        ThermalSettings = {
            MaxNoise          = 0.02,
            Intensity         = 1.5,
            Heatscale         = 0.2,
            FadeStartDistance = 200.0,
            FadeEndDistance   = 350.0,
        },
    },

    ["dual"] = {
        SlotType = "prop",
        Slot     = 0,
        VignetteMode = "sprite",
        VignetteFile = "assets/vignette_2lens.png",
        SpriteColor  = {r = 0, g = 0, b = 0, a = 255},
        ConflictingProps = {0},
        ConflictingComponents = {},
        EnableVisor = true,
        EnableToggleAnimation = true,
        EnableCommands = true,
        EnableItemUse = true,
        EnableModes = {
            NVG      = true,
            WhiteNVG = false,
            Fusion   = false,
            Thermal  = false,
            Light    = true,
        },
        PermittedJobs = {
            ["police"]    = 0,
            ["sheriff"]   = 0,
            ["ambulance"] = 0,
        },
        Male   = { DownModel = 116, DownTexture = 0, UpModel = 117, UpTexture = 0 },
        Female = { DownModel = 115, DownTexture = 0, UpModel = 116, UpTexture = 0 },
        Flashlight = {
            offset     = vector3(-0.15, 0.2, 0.185),
            color      = {r = 255, g = 255, b = 255},
            distance   = 60.0,
            brightness = 15.0,
            hardness   = 0.8,
            radius     = 45.0,
            falloff    = 1.0,
        },
    },

    ["goggles"] = {
        SlotType = "prop",
        VignetteFile = "assets/vignette_goggles.png",
        Slot = 0,
        ConflictingProps = {0},
        ConflictingComponents = {},
        EnableVisor = true,
        EnableToggleAnimation = true,
        EnableCommands = true,
        EnableItemUse = true,
        EnableModes = {
            NVG      = false, -- No NVG for goggles
            WhiteNVG = false,
            Fusion   = false,
            Thermal  = true,
            Light    = true,
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
        -- Goggles: reduced thermal performance
        ThermalSettings = {
            MaxNoise          = 0.2,
            MinNoise          = 0.05,
            Intensity         = 0.7,
            Heatscale         = 0.4,
            FadeStartDistance = 60.0,
            FadeEndDistance   = 120.0,
        },
    },

    ["fullface"] = {
        -- NVGType = "white" は廃止。ホワイトホスファーは WhiteNVG モード(mode=2)として独立。
        SlotType = "component",
        EnableVignette = false, -- Disable vignette for this style
        Slot = 1, -- mask
        ConflictingProps = {0},
        ConflictingComponents = {1},
        EnableVisor = true,
        EnableToggleAnimation = true,
        EnableCommands = true,
        EnableItemUse = true,
        EnableModes = {
            NVG      = false, -- グリーンホスファーは使用しない
            WhiteNVG = true,  -- ホワイトホスファー
            Fusion   = true,  -- フュージョン (ホワイトホスファー + Ped輪郭強調)
            Thermal  = false, -- フルフェイスではサーマルの代わりにフュージョンを使用
            Light    = false, -- No light for fullface
        },
        PermittedJobs = {
            ["police"]    = 0,
            ["sheriff"]   = 0,
            ["ambulance"] = 0,
        },
        Male   = { DownModel = 135, DownTexture = 6, UpModel = 135, UpTexture = 1 },
        Female = { DownModel = 135, DownTexture = 6, UpModel = 135, UpTexture = 1 },
        AnimationSettings = {
            EnableVisorAnim = false, -- No anim for fullface
        },
        SoundSettings = {
            ToggleSound = "photon.mp3",
        },
        ThermalSettings = {
            Heatscale         = 0.3,
        },
    },
}
