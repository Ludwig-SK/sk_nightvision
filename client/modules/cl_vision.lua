-- Vision Effects Logic
-- Vision mode numbers (cycle order):
--   0: OFF
--   1: NVG (green phosphor)
--   2: White NVG (white phosphor)
--   3: Fusion (white phosphor + ped glow highlight)
--   4: Thermal
--   5: Light

local VIEW_MODE_FIRST_PERSON  = 4
local PED_GLOW_HEIGHT_OFFSET  = 0.6  -- world-space Z offset toward chest for glow sprite center
local POLL_INTERVAL_FUSION    = 500  -- ms between ped scan cycles in Fusion mode

local isWhiteNVGActive   = false
local cachedWhiteNVGLight = nil
local isFusionActive     = false

-- Shared runtime texture used to draw a glow billboard at highlighted peds in Fusion mode.
local PED_GLOW_TXD_NAME = "sk_nv_ped_glow_shared"
local pedGlowTexture    = nil
local isPedGlowLoaded   = false

-- Creates the shared runtime TXD/texture slot for the ped glow sprite.
function initPedGlowSlot()
    local txd = CreateRuntimeTxd(PED_GLOW_TXD_NAME)
    pedGlowTexture = CreateRuntimeTexture(txd, "glow", 256, 256)
end

-- Loads the ped glow PNG into the shared texture slot.
-- Retries asynchronously for up to 2 seconds if not immediately ready.
function loadPedGlowTexture()
    if not pedGlowTexture then return end
    local filePath = Config.Fusion.GlowFile or "assets/ped_glow.png"
    isPedGlowLoaded = SetRuntimeTextureImage(pedGlowTexture, filePath)
    if not isPedGlowLoaded then
        Citizen.CreateThread(function()
            local attempts = 0
            while not isPedGlowLoaded and attempts < 20 do
                Wait(100)
                isPedGlowLoaded = SetRuntimeTextureImage(pedGlowTexture, filePath)
                attempts = attempts + 1
            end
            if not isPedGlowLoaded then
                print("^1[sk_nightvision] Warning: Failed to load ped glow texture: " .. filePath .. "^0")
            end
        end)
    end
end

-- Returns a setting value from the style's WhiteNVGSettings, falling back to Config.WhiteNVG.
local function getWhiteNVGSetting(style, key, subkey)
    if subkey then
        local styleVal = style and style.WhiteNVGSettings and style.WhiteNVGSettings[key] and style.WhiteNVGSettings[key][subkey]
        if styleVal ~= nil then return styleVal end
        return Config.WhiteNVG[key] and Config.WhiteNVG[key][subkey]
    end
    if style and style.WhiteNVGSettings and style.WhiteNVGSettings[key] ~= nil then
        return style.WhiteNVGSettings[key]
    end
    return Config.WhiteNVG[key]
end

-- Returns a setting value from the style's FusionSettings, falling back to Config.Fusion.
local function getFusionSetting(style, key, subkey)
    if subkey then
        local styleVal = style and style.FusionSettings and style.FusionSettings[key] and style.FusionSettings[key][subkey]
        if styleVal ~= nil then return styleVal end
        return Config.Fusion[key] and Config.Fusion[key][subkey]
    end
    if style and style.FusionSettings and style.FusionSettings[key] ~= nil then
        return style.FusionSettings[key]
    end
    return Config.Fusion[key]
end

-- Tracks peds currently highlighted in Fusion mode.
local highlightedPeds = {}

-- Clears all active vision effects. Pass keepScaleform=true to retain the scaleform handle.
function clearVisionEffects(keepScaleform)
    ClearTimecycleModifier()
    SetNightvision(false)
    SetSeethrough(false)
    SeethroughReset()
    isWhiteNVGActive  = false
    cachedWhiteNVGLight = nil
    isFusionActive    = false
    highlightedPeds   = {}
    if not keepScaleform then
        if NV_State.scaleformHandle then
            SetScaleformMovieAsNoLongerNeeded(NV_State.scaleformHandle)
            NV_State.scaleformHandle = nil
        end
    end
end

-- Applies the visual effect for the given vision mode.
-- silent suppresses notifications; skipVignette skips scaleform preloading.
function applyVisionEffect(mode, silent, skipVignette)
    local isVisionMode = (mode >= 1 and mode <= 4)
    local styleData = Config.Styles[NV_State.activeStyle]
    local resolvedVignetteMode = (styleData and styleData.VignetteMode) or Config.UI.VignetteMode

    local incomingNeedsScaleform = Config.UI.EnableVignette
        and not skipVignette
        and resolvedVignetteMode == "scaleform"
        and isVisionMode

    clearVisionEffects(incomingNeedsScaleform)

    if mode == 1 then
        if incomingNeedsScaleform and not NV_State.scaleformHandle then
            NV_State.scaleformHandle = loadScaleform("BINOCULARS")
        end
        SetNightvision(true)
        SetTimecycleModifier("NightVision")
        SetTimecycleModifierStrength(1.0)
        if not silent then notify(L('nvg_on'), 'success') end

    elseif mode == 2 then
        if incomingNeedsScaleform and not NV_State.scaleformHandle then
            NV_State.scaleformHandle = loadScaleform("BINOCULARS")
        end
        local style = Config.Styles[NV_State.activeStyle]
        SetTimecycleModifier(getWhiteNVGSetting(style, "TimecycleModifier"))
        SetTimecycleModifierStrength(getWhiteNVGSetting(style, "TimecycleStrength") + 0.0)
        isWhiteNVGActive = true
        cachedWhiteNVGLight = {
            color     = getWhiteNVGSetting(style, "AmbientLight", "color") or {r = 255, g = 255, b = 255},
            radius    = (getWhiteNVGSetting(style, "AmbientLight", "radius")    or 300.0) + 0.0,
            intensity = (getWhiteNVGSetting(style, "AmbientLight", "intensity") or 10.0)  + 0.0,
        }
        if not silent then notify(L('white_nvg_on'), 'success') end

    elseif mode == 3 then
        if incomingNeedsScaleform and not NV_State.scaleformHandle then
            NV_State.scaleformHandle = loadScaleform("BINOCULARS")
        end
        local style = Config.Styles[NV_State.activeStyle]
        SetTimecycleModifier(getFusionSetting(style, "TimecycleModifier"))
        SetTimecycleModifierStrength(getFusionSetting(style, "TimecycleStrength") + 0.0)
        isWhiteNVGActive = true
        cachedWhiteNVGLight = {
            color     = getFusionSetting(style, "AmbientLight", "color") or {r = 255, g = 255, b = 255},
            radius    = (getFusionSetting(style, "AmbientLight", "radius")    or 300.0) + 0.0,
            intensity = (getFusionSetting(style, "AmbientLight", "intensity") or 10.0)  + 0.0,
        }
        isFusionActive = true
        if not silent then notify(L('fusion_on'), 'success') end

    elseif mode == 4 then
        local style = Config.Styles[NV_State.activeStyle]
        local styleThermal = style and style.ThermalSettings or {}
        local d = Config.Thermal

        local maxNoise   = (styleThermal.MaxNoise          ~= nil and styleThermal.MaxNoise          or d.MaxNoise)          + 0.0
        local minNoise   = (styleThermal.MinNoise          ~= nil and styleThermal.MinNoise          or d.MinNoise)          + 0.0
        local intensity  = (styleThermal.Intensity         ~= nil and styleThermal.Intensity         or d.Intensity)         + 0.0
        local heatscale  = (styleThermal.Heatscale         ~= nil and styleThermal.Heatscale         or d.Heatscale)         + 0.0
        local fadeStart  = (styleThermal.FadeStartDistance ~= nil and styleThermal.FadeStartDistance or d.FadeStartDistance) + 0.0
        local fadeEnd    = (styleThermal.FadeEndDistance   ~= nil and styleThermal.FadeEndDistance   or d.FadeEndDistance)   + 0.0
        local colorNear  = styleThermal.ColorNear  or d.ColorNear
        local colorFar   = styleThermal.ColorFar   or d.ColorFar
        local tcModifier = styleThermal.TimecycleModifier or d.TimecycleModifier
        local tcStrength = (styleThermal.TimecycleStrength ~= nil and styleThermal.TimecycleStrength or d.TimecycleStrength) + 0.0

        SetSeethrough(true)
        SeethroughSetNoiseAmountMax(maxNoise)
        SeethroughSetNoiseAmountMin(minNoise)
        SeethroughSetHiLightIntensity(intensity)
        SeethroughSetHeatscale(0, heatscale)
        SeethroughSetFadeStartDistance(fadeStart)
        SeethroughSetFadeEndDistance(fadeEnd)
        SeethroughSetColorNear(colorNear.r + 0.0, colorNear.g + 0.0, colorNear.b + 0.0)
        SeethroughSetColorFar(colorFar.r + 0.0, colorFar.g + 0.0, colorFar.b + 0.0)
        SetTimecycleModifier(tcModifier)
        SetTimecycleModifierStrength(tcStrength)

        if incomingNeedsScaleform and not NV_State.scaleformHandle then
            NV_State.scaleformHandle = loadScaleform("BINOCULARS")
        end
        if not silent then notify(L('thermal_on'), 'success') end

    elseif mode == 5 then
        if not silent then notify(L('light_on'), 'success') end

    elseif mode == 0 then
        if not silent then notify(L('vision_off'), 'primary') end
    end
end

-- Draws the ambient point light for White NVG (mode 2) and Fusion (mode 3).
-- Uses DrawLightWithRange (no shadow) to illuminate the scene without shadow calculation cost.
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        if isWhiteNVGActive and NV_State.isGogglesDown and NV_State.isEquipped and cachedWhiteNVGLight then
            sleep = 0
            local c = cachedWhiteNVGLight
            local camPos = GetGameplayCamCoord()
            DrawLightWithRange(camPos.x, camPos.y, camPos.z, c.color.r, c.color.g, c.color.b, c.radius, c.intensity)
        end
        Wait(sleep)
    end
end)

-- Scans for nearby peds every POLL_INTERVAL_FUSION ms for Fusion mode (mode 3) and builds the
-- highlight list. SetEntityDrawOutline is not used here: it is known to crash the client when
-- applied to Ped entities (skinned-mesh issue, citizenfx/fivem#1425).
-- Results are capped to MaxHighlighted (nearest first) to bound per-frame draw cost.
Citizen.CreateThread(function()
    while true do
        if not isFusionActive or not NV_State.isGogglesDown or not NV_State.isEquipped then
            if next(highlightedPeds) then highlightedPeds = {} end
            Wait(POLL_INTERVAL_FUSION)
        else
            local style    = Config.Styles[NV_State.activeStyle]
            local maxDist  = getFusionSetting(style, "OutlineDistance") or 80.0
            local maxCount = getFusionSetting(style, "MaxHighlighted")  or 15

            local myPed    = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local pedPool  = GetGamePool('CPed')
            local candidates = {}

            for _, ped in ipairs(pedPool) do
                if ped ~= myPed and DoesEntityExist(ped) then
                    local dist = #(myCoords - GetEntityCoords(ped))
                    if dist <= maxDist then
                        candidates[#candidates + 1] = { ped = ped, dist = dist }
                    end
                end
            end

            table.sort(candidates, function(a, b) return a.dist < b.dist end)

            local currentPeds = {}
            for i = 1, math.min(#candidates, maxCount) do
                currentPeds[candidates[i].ped] = true
            end

            highlightedPeds = currentPeds
            Wait(POLL_INTERVAL_FUSION)
        end
    end
end)

-- Draws a glow billboard sprite over each highlighted ped every frame while Fusion is active.
-- Sprite size scales inversely with distance and fades out near OutlineDistance.
Citizen.CreateThread(function()
    while true do
        if not isFusionActive or not NV_State.isGogglesDown or not NV_State.isEquipped
            or not isPedGlowLoaded or not next(highlightedPeds) then
            Wait(200)
        else
            local style     = Config.Styles[NV_State.activeStyle]
            local c         = getFusionSetting(style, "OutlineColor")     or {r = 255, g = 140, b = 0, a = 200}
            local maxDist   = getFusionSetting(style, "OutlineDistance")  or 80.0
            local baseSize  = (getFusionSetting(style, "GlowSize")        or 0.05)  + 0.0
            local minSize   = (getFusionSetting(style, "GlowMinSize")     or 0.02)  + 0.0
            local maxSize   = (getFusionSetting(style, "GlowMaxSize")     or 0.10)  + 0.0
            local refDist   = (getFusionSetting(style, "GlowRefDistance") or 10.0)  + 0.0
            local fadeRange = (getFusionSetting(style, "GlowFadeDistance")or 15.0)  + 0.0

            local myCoords = GetEntityCoords(PlayerPedId())
            local aspect   = GetAspectRatio(false) + 0.0

            for ped, _ in pairs(highlightedPeds) do
                if DoesEntityExist(ped) then
                    local pos = GetEntityCoords(ped)
                    local ok, sx, sy = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z + PED_GLOW_HEIGHT_OFFSET)
                    if ok then
                        local dist = #(myCoords - pos)

                        local size = baseSize * (refDist / math.max(dist, 0.1))
                        if size < minSize then size = minSize end
                        if size > maxSize then size = maxSize end

                        local alpha = (c.a or 200) + 0.0
                        if dist > maxDist - fadeRange then
                            local t = (maxDist - dist) / fadeRange
                            if t < 0.0 then t = 0.0 end
                            alpha = alpha * t
                        end

                        DrawSprite(
                            PED_GLOW_TXD_NAME, "glow",
                            sx + 0.0, sy + 0.0,
                            size, size * aspect,
                            0.0,
                            c.r, c.g, c.b, math.floor(alpha)
                        )
                    end
                end
            end
            Wait(0)
        end
    end
end)
