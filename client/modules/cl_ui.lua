-- UI Logic (Vignette)
local VIGNETTE_TXD_NAME = "sk_nv_vignette_shared"
vignetteTexture = nil
isVignetteLoaded = false
cachedVignetteWidth = 1.0

local _lastAspectRatio = 0.0

vignetteCache = {
    color = { r = 0, g = 0, b = 0, a = 255 },
}

-- Creates the shared runtime TXD and texture slot used by all sprite-mode styles.
-- Called unconditionally at resource start because individual styles may use sprite mode
-- even when Config.UI.VignetteMode is set to "scaleform".
function initVignetteSlot()
    local txd = CreateRuntimeTxd(VIGNETTE_TXD_NAME)
    vignetteTexture = CreateRuntimeTexture(txd, "vignette", 2048, 1024)
end

-- Updates the cached vignette draw width to match the current screen aspect ratio.
function refreshVignetteAspectRatio()
    local aspect = GetAspectRatio(false)
    if math.abs(aspect - _lastAspectRatio) < 0.001 then return end
    _lastAspectRatio = aspect
    cachedVignetteWidth = (aspect > 0) and (2.0 / aspect) or 1.0
end

-- Updates the cached sprite color for the given style.
function updateVignetteCache(styleName)
    local styleData = Config.Styles[styleName]
    vignetteCache.color = (styleData and styleData.SpriteColor) or Config.UI.SpriteColor
end

-- Returns the effective vignette mode for a style: styleData.VignetteMode -> Config.UI.VignetteMode.
local function resolveVignetteMode(styleData)
    if styleData and styleData.VignetteMode then
        return styleData.VignetteMode
    end
    return Config.UI.VignetteMode
end

-- Loads the vignette PNG for the given style into the shared texture slot.
-- Only runs when the resolved mode is "sprite".
-- If SetRuntimeTextureImage returns false, retries asynchronously for up to 2 seconds.
function loadVignetteForStyle(styleName)
    local styleData = Config.Styles[styleName]
    local mode = resolveVignetteMode(styleData)

    if mode ~= "sprite" then
        isVignetteLoaded = false
        updateVignetteCache(styleName)
        return
    end

    if not vignetteTexture or not styleData then
        isVignetteLoaded = false
        updateVignetteCache(styleName)
        return
    end

    -- Check that at least one vision mode that shows a vignette is enabled.
    local m = styleData.EnableModes
    local hasVisionMode = m and (
        m.NVG ~= false or m.WhiteNVG ~= false or
        m.Fusion ~= false or m.Thermal ~= false
    )
    if not hasVisionMode then
        isVignetteLoaded = false
        updateVignetteCache(styleName)
        return
    end

    local filePath = styleData.VignetteFile or Config.UI.VignetteFile
    if not filePath then
        isVignetteLoaded = false
        updateVignetteCache(styleName)
        return
    end

    isVignetteLoaded = SetRuntimeTextureImage(vignetteTexture, filePath)
    if not isVignetteLoaded then
        print("^3[sk_nightvision] Vignette not immediately ready, retrying: " .. filePath .. "^0")
        Citizen.CreateThread(function()
            local attempts = 0
            while not isVignetteLoaded and attempts < 20 do
                Wait(100)
                isVignetteLoaded = SetRuntimeTextureImage(vignetteTexture, filePath)
                attempts = attempts + 1
            end
            if isVignetteLoaded then
                print("^2[sk_nightvision] Vignette loaded after retry: " .. filePath .. "^0")
            else
                print("^1[sk_nightvision] Warning: Failed to load vignette: " .. filePath .. "^0")
            end
        end)
    end

    updateVignetteCache(styleName)
end

-- Draws the vignette overlay while a vision mode is active.
-- Modes 1-4 (NVG, WhiteNVG, Fusion, Thermal) show the overlay.
-- Sprite mode uses the loaded PNG; falls back to scaleform if the image is not loaded.
-- Scaleform mode always uses the BINOCULARS movie.
-- When ForceFirstPerson is true the overlay is only drawn in first-person view.
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local mode = NV_State.currentVisionMode
        local isVisionActive = (mode >= 1 and mode <= 4)
        local styleData = Config.Styles[NV_State.activeStyle]
        local isVignetteAllowed = styleData and styleData.EnableVignette ~= false
        local isCameraOk = (not Config.ForceFirstPerson) or (GetFollowPedCamViewMode() == 4)

        if NV_State.isGogglesDown and NV_State.isEquipped and Config.UI.EnableVignette
            and isVisionActive and isCameraOk and isVignetteAllowed then

            local vigMode = resolveVignetteMode(styleData)

            -- Render the vignette behind the native HUD (minimap, status icons, etc).
            -- Reset to the default order afterward so other resources' draws are unaffected.
            SetScriptGfxDrawOrder(Config.UI.GfxDrawOrder)

            if vigMode == "scaleform" then
                if not NV_State.scaleformHandle then
                    NV_State.scaleformHandle = loadScaleform("BINOCULARS")
                end
                if NV_State.scaleformHandle then
                    sleep = 0
                    DrawScaleformMovieFullscreen(NV_State.scaleformHandle, 255, 255, 255, 255, 0)
                end

            elseif vigMode == "sprite" then
                local color = vignetteCache.color
                if isVignetteLoaded then
                    sleep = 0
                    DrawSprite(
                        VIGNETTE_TXD_NAME, "vignette",
                        0.5, 0.5,
                        cachedVignetteWidth, 1.0,
                        0.0,
                        color.r, color.g, color.b, color.a
                    )
                else
                    -- Image not yet loaded; fall back to scaleform.
                    if not NV_State.scaleformHandle then
                        NV_State.scaleformHandle = loadScaleform("BINOCULARS")
                    end
                    if NV_State.scaleformHandle then
                        sleep = 0
                        DrawScaleformMovieFullscreen(NV_State.scaleformHandle, 255, 255, 255, 255, 0)
                    end
                end
            end

            SetScriptGfxDrawOrder(4) -- GFX_ORDER_AFTER_HUD (default)
        end
        Wait(sleep)
    end
end)
