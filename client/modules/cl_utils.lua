-- Utility functions and helpers
Locales = Locales or {}

-- Pre-merged locale table for O(1) resolution
local _resolvedLocale = {}

-- Merges the configured language and English fallback into a flat table.
local function resolveLocales()
    -- Start with English fallback
    for k, v in pairs(Locales['en'] or {}) do
        _resolvedLocale[k] = v
    end
    -- Overwrite with configured language if different from English
    if Config.Language ~= 'en' then
        for k, v in pairs(Locales[Config.Language] or {}) do
            _resolvedLocale[k] = v
        end
    end
end

-- Call merge at module load
resolveLocales()

-- Track active sound IDs to prevent zombie entries in xsound
local _activeSounds = {}

-- Returns the locale string for the given key.
function L(key)
    return _resolvedLocale[key] or key
end

-- Displays a notification using the Bridge method.
function notify(message, type)
    if not Config.EnableNotifications then return end
    Bridge.Notify(message, type)
end

-- Plays the specified animation and calls an optional callback mid-animation.
function playAnimWithCallback(dict, anim, duration, callback, callbackDelayMs)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local deadline = GetGameTimer() + 500
        while not HasAnimDictLoaded(dict) do
            if GetGameTimer() > deadline then
                print("^1[sk_nightvision] AnimDict '" .. tostring(dict) .. "' failed to load.^0")
                if callback then callback() end
                return false
            end
            Wait(10)
        end
    end

    local callbackCalled = false
    local function wrappedCallback()
        if callback and not callbackCalled then
            callbackCalled = true
            callback()
        end
    end

    local ped = PlayerPedId()
    local ok, err = pcall(function()
        TaskPlayAnim(ped, dict, anim, 2.0, 1.0, duration, 49, 0, false, false, false)
        if callback and callbackDelayMs ~= nil then
            local delay = math.max(0, math.min(callbackDelayMs, duration))
            Wait(delay)
            wrappedCallback()
            Wait(duration - delay)
        else
            Wait(duration)
            wrappedCallback()
        end
    end)
    StopAnimTask(ped, dict, anim, 1.0)
    if not ok then
        print("[sk_nightvision] playAnimWithCallback error: " .. tostring(err))
        wrappedCallback()
    end
    return ok
end

-- Plays a 3D positional sound via xsound.
function playSound(soundType, style)
    if not Config.EnableSounds then return end

    local enableKey = (soundType == "toggle") and "EnableToggleSound" or "EnableSwitchSound"
    if not getSoundSetting(style, enableKey) then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if Bridge.HasSound then
        local fileKey = (soundType == "toggle") and "ToggleSound" or "SwitchSound"
        local fileName = getSoundSetting(style, fileKey)
        local soundUrl = ("https://cfx-nui-%s/html/sounds/%s"):format(GetCurrentResourceName(), fileName)
        local soundId = ("nvg_%d_%d"):format(GetPlayerServerId(PlayerId()), GetGameTimer())

        exports.xsound:PlayUrlPos(soundId, soundUrl, getSoundSetting(style, "Volume"), coords, false)
        exports.xsound:Distance(soundId, getSoundSetting(style, "Distance"))

        _activeSounds[soundId] = true

        SetTimeout(3000, function()
            _activeSounds[soundId] = nil
            if Bridge.HasSound then
                exports.xsound:Destroy(soundId)
            end
        end)
    end
end

-- Loads the specified scaleform movie.
function loadScaleform(name)
    local handle = RequestScaleformMovie(name)
    local timeout = GetGameTimer() + 5000
    while not HasScaleformMovieLoaded(handle) do
        if GetGameTimer() > timeout then
            print("^1[sk_nightvision] Warning: Scaleform " .. tostring(name) .. " failed to load.^0")
            return nil
        end
        Wait(0)
    end
    return handle
end

-- Preloads all required animation dictionaries.
function preloadAnimDicts()
    local dicts = {}
    local function collect(d) if d then dicts[d] = true end end
    collect(Config.AnimationSettings.VisorDownDict)
    collect(Config.AnimationSettings.VisorUpDict)
    collect(Config.AnimationSettings.EquipDict)
    collect(Config.AnimationSettings.UnequipDict)
    for _, style in pairs(Config.Styles) do
        if style.AnimationSettings then
            collect(style.AnimationSettings.VisorDownDict)
            collect(style.AnimationSettings.VisorUpDict)
            collect(style.AnimationSettings.EquipDict)
            collect(style.AnimationSettings.UnequipDict)
        end
    end
    for dict in pairs(dicts) do
        RequestAnimDict(dict)
    end
    local deadline = GetGameTimer() + 5000
    local remaining = true
    while remaining and GetGameTimer() < deadline do
        remaining = false
        for dict in pairs(dicts) do
            if not HasAnimDictLoaded(dict) then
                remaining = true
                break -- break: one unloaded dict is enough to know we must wait again
            end
        end
        if remaining then Wait(10) end
    end
end

-- Helper to get sound settings with fallback
function getSoundSetting(style, key)
    if style and style.SoundSettings and style.SoundSettings[key] ~= nil then
        return style.SoundSettings[key]
    end
    return Config.XSoundSettings[key]
end

-- Clean up residual sound entries on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if not Bridge.HasSound then return end
    for soundId, _ in pairs(_activeSounds) do
        exports.xsound:Destroy(soundId)
    end
    _activeSounds = {}
end)
