local framework = nil
local ESX = nil
local playerData = {}
local jobStateBagHandler = nil
local visionModeIndex = 0 -- 0: OFF, 1: NVG, 2: Thermal, 3: Light
local activeStyle = "helmet"
local isGogglesDown = false
local isScoping = false
local isEquipped = false
local isAnimating = false
local equippedPropId = -1
local originalCameraMode = nil

local scaleformHandle = nil
local activeLights = {} -- Flashlight draw table. Holds light data for nearby players and the local player registered via StateBag.

-- Saved table of conflicting props/components cleared on equip.
-- Structure: { props = { [slot] = {id, tex} }, components = { [slot] = {drawable, tex} } }
local savedConflicts = nil

local BONE_HEAD = 0x4B5
local CONTROL_IDS = {
    ["INPUT_CONTEXT"] = 51,
    ["INPUT_REPLAY_START_STOP"] = 289,
}

-- Returns the locale string for the given key. Falls back to English if the configured language lacks the key, then returns the key itself if English is also missing.
local function L(key)
    if Locales[Config.Language] and Locales[Config.Language][key] then
        return Locales[Config.Language][key]
    end
    if Locales['en'] and Locales['en'][key] then
        return Locales['en'][key]
    end
    return key
end

-- Displays a notification using the appropriate framework method.
local function notify(message, type)
    if not Config.EnableNotifications then return end
    if framework == "qb" then
        exports['qb-core']:GetCoreObject().Functions.Notify(message, type)
    elseif framework == "qbx" then
        exports.qbx_core:Notify(message, type)
    elseif framework == "esx" and ESX then
        ESX.ShowNotification(message)
    else
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

-- Returns a sound setting value for the given style.
-- Prefers the style's own SoundSettings; falls back to the global Config.XSoundSettings for any missing key.
-- style: style data table from Config.Styles / key: key to retrieve
local function getSoundSetting(style, key)
    if style and style.SoundSettings and style.SoundSettings[key] ~= nil then
        return style.SoundSettings[key]
    end
    return Config.XSoundSettings[key]
end

-- Plays a 3D positional sound via xsound, audible to the local player and nearby players.
-- soundType: "toggle" (visor up/down) or "switch" (mode cycle)
-- style: style data table from Config.Styles (used to look up sound settings)
local function playSound(soundType, style)
    if not Config.EnableSounds then return end

    local enableKey = (soundType == "toggle") and "EnableToggleSound" or "EnableSwitchSound"
    if not getSoundSetting(style, enableKey) then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if Config.UseXSound and GetResourceState('xsound') == 'started' then
        local fileKey = (soundType == "toggle") and "ToggleSound" or "SwitchSound"
        local fileName = getSoundSetting(style, fileKey)
        local soundUrl = ("https://cfx-nui-%s/html/sounds/%s"):format(GetCurrentResourceName(), fileName)
        local soundId = "nvg_" .. GetPlayerServerId(PlayerId()) .. "_" .. GetGameTimer()
        exports.xsound:PlayUrlPos(soundId, soundUrl, getSoundSetting(style, "Volume"), coords, false)
        exports.xsound:Distance(soundId, getSoundSetting(style, "Distance"))

        SetTimeout(3000, function()
            if GetResourceState('xsound') == 'started' then
                exports.xsound:Destroy(soundId)
            end
        end)
    end
end

-- Loads the specified scaleform movie and returns its handle. Returns nil on timeout.
local function loadScaleform(name)
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

-- Clears all active vision effects and releases the scaleform handle.
local function clearVisionEffects()
    ClearTimecycleModifier()
    SetNightvision(false)
    SetSeethrough(false)
    SeethroughReset()
    if scaleformHandle then
        SetScaleformMovieAsNoLongerNeeded(scaleformHandle)
        scaleformHandle = nil
    end
end

-- Applies the vision effect for the specified mode.
-- mode: 0=OFF, 1=NVG, 2=Thermal, 3=Flashlight
-- silent: if true, suppresses the notification
local function applyVisionEffect(mode, silent)
    clearVisionEffects()

    if mode == 1 then
        SetNightvision(true)
        SetTimecycleModifier("NightVision")
        SetTimecycleModifierStrength(1.0)
        if Config.UI.EnableVignette then
            scaleformHandle = loadScaleform("BINOCULARS")
        end
        if not silent then notify(L('nvg_on'), 'success') end

    elseif mode == 2 then
        SetSeethrough(true)
        SeethroughSetNoiseAmountMax(Config.Thermal.MaxNoise)
        SeethroughSetNoiseAmountMin(Config.Thermal.MinNoise)
        SeethroughSetHiLightIntensity(Config.Thermal.Intensity)
        SeethroughSetHeatscale(0, Config.Thermal.Heatscale)
        SeethroughSetFadeStartDistance(Config.Thermal.FadeDistance)
        SetTimecycleModifier("ThermalVision")
        SetTimecycleModifierStrength(1.0)
        if Config.UI.EnableVignette then
            scaleformHandle = loadScaleform("BINOCULARS")
        end
        if not silent then notify(L('thermal_on'), 'success') end

    elseif mode == 3 then
        if not silent then notify(L('light_on'), 'success') end

    elseif mode == 0 then
        if not silent then notify(L('vision_off'), 'primary') end
    end
end

-- Returns true if the player meets the job/grade requirement defined in the current style's PermittedJobs.
-- Styles without a PermittedJobs table allow all players.
local function hasJobPermission()
    if not Config.RestrictByJob or framework == "standalone" then return true end
    if not playerData or not playerData.job then return false end

    local styleData = Config.Styles[activeStyle]
    local permittedJobs = styleData and styleData.PermittedJobs
    if not permittedJobs then return true end

    local jobName = playerData.job.name
    local jobGrade = playerData.job.grade and (playerData.job.grade.level or playerData.job.grade) or 0

    if permittedJobs[jobName] == nil or jobGrade < permittedJobs[jobName] then
        return false
    end
    return true
end

-- Returns true if the gear is equipped and the player has job permission.
local function canUseGoggles()
    if not isEquipped then return false end
    local styleData = Config.Styles[activeStyle]
    if not styleData then return false end
    return hasJobPermission()
end

-- Returns true if the current style supports visor toggle.
local function hasVisor()
    local styleData = Config.Styles[activeStyle]
    return styleData and styleData.EnableVisor ~= false
end

-- Returns an animation setting value for the given style.
-- Prefers the style's own AnimationSettings; falls back to the global Config.AnimationSettings for any missing key.
-- style: style data table from Config.Styles / key: key to retrieve
local function getAnimSetting(style, key)
    if style and style.AnimationSettings and style.AnimationSettings[key] ~= nil then
        return style.AnimationSettings[key]
    end
    return Config.AnimationSettings[key]
end

-- Plays the specified animation synchronously and waits for it to finish.
-- dict: animation dictionary name / anim: animation clip name / duration: playback time in milliseconds
local function playAnim(dict, anim, duration)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then return false end
        Wait(10)
    end
    local ped = PlayerPedId()
    local ok, err = pcall(function()
        TaskPlayAnim(ped, dict, anim, 2.0, 1.0, duration, 49, 0, false, false, false)
        Wait(duration)
        StopAnimTask(ped, dict, anim, 1.0)
    end)
    if not ok then print("Error in playAnim: " .. tostring(err)) end
    return ok
end

-- Clears the currently equipped prop or component from the ped.
local function clearEquippedModel(ped, styleData)
    if not styleData then return end
    if styleData.SlotType == "component" then
        local slot = styleData.Slot
        if slot then SetPedComponentVariation(ped, slot, 0, 0, 0) end
    else
        local slot = styleData.Slot
        if slot then ClearPedProp(ped, slot) end
    end
end

-- Saves the current values of conflicting props/components into savedConflicts, then clears them.
-- Already-saved slots are not overwritten, preserving the original state across style switches.
local function saveAndClearConflicts(ped, styleData)
    if not savedConflicts then
        savedConflicts = { props = {}, components = {} }
    end

    if styleData.ConflictingProps then
        for _, slot in ipairs(styleData.ConflictingProps) do
            if not savedConflicts.props[slot] then
                local id  = GetPedPropIndex(ped, slot)
                local tex = GetPedPropTextureIndex(ped, slot)
                savedConflicts.props[slot] = { id = id, tex = tex }
            end
            ClearPedProp(ped, slot)
        end
    end

    if styleData.ConflictingComponents then
        for _, slot in ipairs(styleData.ConflictingComponents) do
            if not savedConflicts.components[slot] then
                local drawable = GetPedDrawableVariation(ped, slot)
                local tex      = GetPedTextureVariation(ped, slot)
                savedConflicts.components[slot] = { drawable = drawable, tex = tex }
            end
            SetPedComponentVariation(ped, slot, 0, 0, 0)
        end
    end
end

-- Restores props/components saved in savedConflicts and clears the table. No animation is played.
local function restoreConflicts(ped)
    if not savedConflicts then return end

    for slot, data in pairs(savedConflicts.props) do
        if data.id ~= -1 then
            SetPedPropIndex(ped, slot, data.id, data.tex, true)
        else
            ClearPedProp(ped, slot)
        end
    end

    for slot, data in pairs(savedConflicts.components) do
        SetPedComponentVariation(ped, slot, data.drawable, data.tex, 0)
    end

    savedConflicts = nil
end

-- Synchronizes the prop or component model to match the current visor state.
-- isDown: if true, applies the visor-down model
local function syncPropModel(isDown)
    if not isEquipped then return end
    local ped = PlayerPedId()
    local gender = nil
    if IsPedModel(ped, `mp_m_freemode_01`) then
        gender = "Male"
    elseif IsPedModel(ped, `mp_f_freemode_01`) then
        gender = "Female"
    end

    if not gender then return end

    local style = Config.Styles[activeStyle]
    if not style or not style[gender] then return end

    local id
    if isDown then
        id = style[gender].DownModel
    else
        id = style[gender].UpModel or style[gender].DownModel
    end

    if style.SlotType == "component" then
        local slot = style.Slot
        if not slot then return end
        if id and id ~= -1 then
            local texture = style[gender].DownTexture or 0
            if not isDown then texture = style[gender].UpTexture or 0 end
            SetPedComponentVariation(ped, slot, id, texture, 0)
            equippedPropId = id
        else
            SetPedComponentVariation(ped, slot, 0, 0, 0)
            equippedPropId = -1
        end
    else
        local slot = style.Slot
        if id and id ~= -1 then
            local texture
            if isDown then
                texture = style[gender].DownTexture or 0
            else
                texture = style[gender].UpTexture or 0
            end
            SetPedPropIndex(ped, slot, id, texture, true)
            equippedPropId = id
        else
            ClearPedProp(ped, slot)
            equippedPropId = -1
        end
    end
end

-- Applies or clears vision effects based on the visor state.
-- isDown: if true, applies the active vision mode; if false, turns all effects off
local function toggleVisionState(isDown)
    if not isDown then
        applyVisionEffect(0)
        LocalPlayer.state:set("helmetLight", false, true)
    elseif not Config.RequireScopeForVision then
        applyVisionEffect(visionModeIndex, true)
    end
end

-- Restores the saved camera mode if ForceFirstPerson is enabled.
local function restoreCameraMode()
    if Config.ForceFirstPerson and originalCameraMode then
        SetFollowPedCamViewMode(originalCameraMode)
        originalCameraMode = nil
    end
end

-- Handles equipping and unequipping the gear.
-- style: style name to equip (nil keeps the current activeStyle)
-- forceOff: if true, unequips immediately without animation (used for forced removal on death, vehicle entry, etc.)
local function toggleEquipment(style, forceOff)
    if isAnimating and not forceOff then return end

    if not forceOff and not hasJobPermission() then
        notify(L('no_permission'), 'error')
        return
    end

    if forceOff and not isEquipped then return end

    isAnimating = true

    Citizen.CreateThread(function()
        local ok, err = pcall(function()
            local ped = PlayerPedId()

            if isEquipped then
                isGogglesDown = false
                restoreCameraMode()

                if forceOff then ClearPedTasksImmediately(ped) end

                local styleData = Config.Styles[activeStyle]
                if getAnimSetting(styleData, 'EnableUnequipAnim') then
                    local animOk = playAnim(
                        getAnimSetting(styleData, 'UnequipDict'),
                        getAnimSetting(styleData, 'UnequipAnim'),
                        getAnimSetting(styleData, 'UnequipDuration')
                    )
                    if not animOk then print("[sk_nightvision] Unequip animation failed to load.") end
                end

                clearEquippedModel(ped, styleData)

                isEquipped = false; visionModeIndex = 0
                clearVisionEffects()
                LocalPlayer.state:set("helmetLight", false, true); equippedPropId = -1

                if not forceOff then
                    notify(L('unequipped'), "primary")

                    local requestedStyle = style or "helmet"
                    if requestedStyle ~= activeStyle and Config.Styles[requestedStyle] then
                        -- When switching to a different style, carry over savedConflicts and
                        -- only save slots not yet recorded before equipping the new style.
                        Wait(200)
                        activeStyle = requestedStyle
                        local newStyleData = Config.Styles[activeStyle]

                        saveAndClearConflicts(ped, newStyleData)

                        if getAnimSetting(newStyleData, 'EnableEquipAnim') then
                            local animOk = playAnim(
                                getAnimSetting(newStyleData, 'EquipDict'),
                                getAnimSetting(newStyleData, 'EquipAnim'),
                                getAnimSetting(newStyleData, 'EquipDuration')
                            )
                            if not animOk then print("[sk_nightvision] Equip animation failed to load.") end
                        end

                        isEquipped = true
                        isGogglesDown = not (Config.Styles[activeStyle] and Config.Styles[activeStyle].EnableVisor ~= false)
                        visionModeIndex = 0
                        syncPropModel(isGogglesDown)
                        notify(L('equipped'), "success")
                    else
                        restoreConflicts(ped)
                    end
                else
                    restoreConflicts(ped)
                end
            else
                activeStyle = style or "helmet"
                local styleData = Config.Styles[activeStyle]
                if not styleData then return end

                saveAndClearConflicts(ped, styleData)

                if getAnimSetting(styleData, 'EnableEquipAnim') then
                    local animOk = playAnim(
                        getAnimSetting(styleData, 'EquipDict'),
                        getAnimSetting(styleData, 'EquipAnim'),
                        getAnimSetting(styleData, 'EquipDuration')
                    )
                    if not animOk then print("[sk_nightvision] Equip animation failed to load.") end
                end

                isEquipped = true
                isGogglesDown = not (styleData.EnableVisor ~= false)
                visionModeIndex = 0
                syncPropModel(isGogglesDown)
                notify(L('equipped'), "success")
            end
        end)
        if not ok then print("[sk_nightvision] toggleEquipment error: " .. tostring(err)) end
        isAnimating = false
    end)
end

-- Handles visor up/down toggling. Only operates on styles with EnableVisor = true.
-- forceState: forces the visor to true/false; nil toggles the current state
-- silentNotify: if true, turns off vision effects silently (used for forced underwater removal, etc.)
-- bypassPermission: if true, skips the job permission check
local function flipGoggles(forceState, silentNotify, bypassPermission)
    if isAnimating then return end

    if not hasVisor() then return end

    if not bypassPermission and not canUseGoggles() then
        notify(L('no_permission'), 'error')
        return
    end

    isAnimating = true

    Citizen.CreateThread(function()
        local ok, err = pcall(function()
            local style = Config.Styles[activeStyle]

            if forceState ~= nil then
                isGogglesDown = forceState
            else
                isGogglesDown = not isGogglesDown
            end

            playSound("toggle", style)

            if style and style.EnableToggleAnimation and getAnimSetting(style, 'EnableVisorAnim') then
                if isGogglesDown then
                    local animOk = playAnim(
                        getAnimSetting(style, 'VisorDownDict'),
                        getAnimSetting(style, 'VisorDownAnim'),
                        getAnimSetting(style, 'DurationMS')
                    )
                    if not animOk then print("[sk_nightvision] VisorDown animation failed to load.") end
                else
                    local animOk = playAnim(
                        getAnimSetting(style, 'VisorUpDict'),
                        getAnimSetting(style, 'VisorUpAnim'),
                        getAnimSetting(style, 'DurationMS')
                    )
                    if not animOk then print("[sk_nightvision] VisorUp animation failed to load.") end
                end
            end

            if not isGogglesDown then
                visionModeIndex = 0
                restoreCameraMode()
            end

            syncPropModel(isGogglesDown)

            if silentNotify then
                clearVisionEffects()
                LocalPlayer.state:set("helmetLight", false, true)
            else
                toggleVisionState(isGogglesDown)
            end
        end)
        if not ok then print("[sk_nightvision] flipGoggles error: " .. tostring(err)) end
        isAnimating = false
    end)
end

-- Cycles through vision modes in order, skipping disabled ones.
-- Cycles: OFF → NVG → Thermal → Light → OFF
local function cycleVision()
    if isAnimating then return end
    if hasVisor() and not isGogglesDown then return end
    if Config.RequireScopeForVision and not isScoping then return end
    if not canUseGoggles() then
        notify(L('no_permission'), 'error')
        return
    end

    local style = Config.Styles[activeStyle]
    local enableModes = style and style.EnableModes or {}
    local hasLight = style and style.Flashlight and (enableModes.Light ~= false)
    local maxModes = hasLight and 3 or 2

    local nextIndex = visionModeIndex
    local iterations = 0
    repeat
        nextIndex = (nextIndex + 1) % (maxModes + 1)
        iterations = iterations + 1
        if iterations > maxModes + 1 then nextIndex = 0; break end
        if nextIndex == 0 then break end
        if nextIndex == 1 and enableModes.NVG ~= false then break end
        if nextIndex == 2 and enableModes.Thermal ~= false then break end
        if nextIndex == 3 and enableModes.Light ~= false then break end
    until false
    visionModeIndex = nextIndex

    playSound("switch", style)
    syncPropModel(true)

    if Config.ForceFirstPerson then
        if visionModeIndex == 1 or visionModeIndex == 2 then
            if originalCameraMode == nil then
                originalCameraMode = GetFollowPedCamViewMode()
            end
            SetFollowPedCamViewMode(4)
        else
            if originalCameraMode ~= nil then
                restoreCameraMode()
            end
        end
    end

    if not Config.RequireScopeForVision or isScoping then
        applyVisionEffect(visionModeIndex)
    end

    local myServerId = GetPlayerServerId(PlayerId())
    if visionModeIndex == 3 then
        if not Config.RequireScopeForVision or isScoping then
            LocalPlayer.state:set("helmetLight", style.Flashlight, true)
            -- StateBag changes are not received by the local player via AddStateBagChangeHandler, so register directly into activeLights.
            activeLights[myServerId] = { plyId = PlayerId(), data = style.Flashlight }
        end
    else
        LocalPlayer.state:set("helmetLight", false, true)
        activeLights[myServerId] = nil
    end
end

-- Draw thread for the vision overlay (scaleform).
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        if isGogglesDown and scaleformHandle then
            sleep = 0
            DrawScaleformMovieFullscreen(scaleformHandle, 255, 255, 255, 255, 0)
        end
        Wait(sleep)
    end
end)

-- Framework initialization and job update handler registration.
Citizen.CreateThread(function()
    if Config.Framework == "auto" then
        if GetResourceState('qb-core') == 'started' then framework = "qb"
        elseif GetResourceState('qbx_core') == 'started' then framework = "qbx"
        elseif GetResourceState('es_extended') == 'started' then framework = "esx"
        else framework = "standalone" end
    else framework = Config.Framework end

    if framework == "qb" then
        QBCore = exports['qb-core']:GetCoreObject()
        playerData = QBCore.Functions.GetPlayerData()
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBCore.Functions.GetPlayerData() end)
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
            playerData.job = job
            if isEquipped and not hasJobPermission() then
                toggleEquipment(nil, true); notify(L('no_permission'), "error")
            end
        end)
    elseif framework == "qbx" then
        playerData = exports.qbx_core:GetPlayerData()

        local function setupQBXJobHandler()
            if jobStateBagHandler then
                RemoveStateBagChangeHandler(jobStateBagHandler)
                jobStateBagHandler = nil
            end
            local serverId = GetPlayerServerId(PlayerId())
            if serverId == 0 then return end

            jobStateBagHandler = AddStateBagChangeHandler('job', ('player:%d'):format(serverId), function(_, _, value)
                playerData.job = value
                if isEquipped and not hasJobPermission() then
                    toggleEquipment(nil, true); notify(L('no_permission'), "error")
                end
            end)
        end

        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            playerData = exports.qbx_core:GetPlayerData()
            setupQBXJobHandler()
        end)

        if LocalPlayer.state.isLoggedIn then
            setupQBXJobHandler()
        end

        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
            playerData.job = job
            if isEquipped and not hasJobPermission() then
                toggleEquipment(nil, true); notify(L('no_permission'), "error")
            end
        end)
    elseif framework == "esx" then
        ESX = exports['es_extended']:getSharedObject()
        playerData = ESX.GetPlayerData()
        RegisterNetEvent('esx:playerLoaded', function(data) playerData = data end)
        RegisterNetEvent('esx:setJob', function(job)
            playerData.job = job
            if isEquipped and not hasJobPermission() then
                toggleEquipment(nil, true); notify(L('no_permission'), "error")
            end
        end)
    end
end)

-- Receives the item use event from the server and handles equip/unequip.
RegisterNetEvent('sk_nightvision:client:UseItem', function(style)
    if type(style) ~= "string" or not Config.Styles[style] then return end
    toggleEquipment(style)
end)

-- Keybind command registration.
RegisterCommand("toggle_nvg", function()
    local styleData = Config.Styles[activeStyle]
    if isEquipped and styleData and styleData.EnableCommands then
        flipGoggles()
    end
end)
RegisterCommand("cycle_nvg", function()
    local styleData = Config.Styles[activeStyle]
    if isEquipped and styleData and styleData.EnableCommands then
        cycleVision()
    end
end)

RegisterKeyMapping("toggle_nvg", L('key_toggle_desc'), "keyboard", Config.ControlKeys.ToggleGoggles)
RegisterKeyMapping("cycle_nvg", L('key_cycle_desc'), "keyboard", Config.ControlKeys.CycleVisionModes)

-- Main monitoring loop: handles input, equipment integrity checks, and auto-removal conditions.
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if isEquipped then
            sleep = 0

            local padToggleId = Config.ControlKeys.PadToggle and CONTROL_IDS[Config.ControlKeys.PadToggle] or nil
            local padCycleId = Config.ControlKeys.PadCycle and CONTROL_IDS[Config.ControlKeys.PadCycle] or nil

            if padToggleId and IsControlJustPressed(0, padToggleId) then
                flipGoggles()
            elseif padCycleId and IsControlJustPressed(0, padCycleId) then
                cycleVision()
            end

            local shouldContinue = false

            -- Check whether the equipped prop/component has been changed by an external operation.
            local style = Config.Styles[activeStyle]
            if style then
                local currentId
                if style.SlotType == "component" then
                    local slot = style.Slot
                    if slot then
                        local drawableId = GetPedDrawableVariation(ped, slot)
                        currentId = drawableId
                    end
                else
                    currentId = GetPedPropIndex(ped, style.Slot)
                end
                if equippedPropId ~= -1 and currentId ~= equippedPropId then
                    toggleEquipment(nil, true)
                    notify(L('removed_invalid'), "error")
                    shouldContinue = true
                end
            end

            -- Auto-removal on vehicle entry.
            if not shouldContinue and Config.AutoUnequipInVehicle then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 then
                    local class = GetVehicleClass(vehicle)
                    if class ~= 8 and class ~= 13 then
                        toggleEquipment(nil, true)
                        notify(L('removed_vehicle'), "primary")
                        shouldContinue = true
                    end
                end
            end

            -- Auto-removal on death.
            if not shouldContinue and IsPedDeadOrDying(ped, true) then
                toggleEquipment(nil, true)
                notify(L('removed_death'), "error")
                shouldContinue = true
            end

            -- Force visor up when the player goes underwater.
            if not shouldContinue and isGogglesDown and not isAnimating then
                if IsPedSwimmingUnderWater(ped) then
                    notify(L('underwater_disabled'), 'error')
                    flipGoggles(false, true, true)
                end
            end

            -- Keep first-person camera while ForceFirstPerson is enabled.
            if Config.ForceFirstPerson and isGogglesDown and not isAnimating
                and (visionModeIndex == 1 or visionModeIndex == 2) then
                if GetFollowPedCamViewMode() ~= 4 then
                    SetFollowPedCamViewMode(4)
                end
            end
        end

        -- Scope state monitoring when RequireScopeForVision is enabled.
        if Config.RequireScopeForVision and isGogglesDown and isEquipped then
            sleep = 0
            local _, hash = GetCurrentPedWeapon(ped, true)
            local isSniper = false
            for _, w in ipairs(Config.CompatibleScopeWeapons) do if hash == w then isSniper = true; break end end
            local scoping = isSniper and IsControlPressed(0, 25)

            if scoping and not isScoping then
                isScoping = true
                applyVisionEffect(visionModeIndex, true)
            elseif not scoping and isScoping then
                isScoping = false
                applyVisionEffect(0, true)
                LocalPlayer.state:set("helmetLight", false, true)
            end
        end

        Wait(sleep)
    end
end)

-- Cleans up gear, vision effects, and conflicting items when the resource stops.
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    if isEquipped then
        local styleData = Config.Styles[activeStyle]
        clearEquippedModel(ped, styleData)
        clearVisionEffects()
        LocalPlayer.state:set("helmetLight", false, true)
        restoreConflicts(ped)
    end
    if Config.ForceFirstPerson and originalCameraMode then
        SetFollowPedCamViewMode(originalCameraMode)
        originalCameraMode = nil
    end
end)

-- Briefly amplifies the vision effect and triggers a camera shake when the player takes damage.
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        if victim == PlayerPedId() and isGogglesDown and isEquipped then
            local snapshotMode = visionModeIndex
            Citizen.CreateThread(function()
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
                SetTimecycleModifierStrength(2.0)
                Wait(300)
                if isGogglesDown and isEquipped and visionModeIndex == snapshotMode then
                    applyVisionEffect(visionModeIndex, true)
                end
            end)
        end
    end
end)

-- Flashlight synchronization

-- Converts Euler angles (degrees) to a direction vector.
-- rot: vector3 (X=pitch, Y=roll, Z=yaw)
local function rotationToDirection(rot)
    local x = math.rad(rot.x)
    local z = math.rad(rot.z)
    local cosX = math.cos(x)
    return vector3(
        -math.sin(z) * cosX,
         math.cos(z) * cosX,
         math.sin(x)
    )
end

-- Calculates the flashlight direction for the given ped.
-- Yaw uses the head bone's Z rotation; pitch uses the gameplay camera X rotation for the local player only.
local function getLightDirection(ped)
    local boneIndex = GetPedBoneIndex(ped, BONE_HEAD)
    local boneRot = boneIndex ~= -1 and GetEntityBoneRotation(ped, boneIndex, 2) or GetEntityRotation(ped, 2)
    local myPed = PlayerPedId()
    local pitchX
    if ped == myPed then
        pitchX = GetGameplayCamRot(2).x
    else
        pitchX = boneRot.x
    end
    return rotationToDirection(vector3(pitchX, boneRot.y, boneRot.z))
end

-- Watches the helmetLight StateBag for changes and updates activeLights accordingly.
AddStateBagChangeHandler("helmetLight", nil, function(bagName, key, value, _unused, replicated)
    local plyId = GetPlayerFromStateBagName(bagName)
    if plyId == 0 then return end
    local serverId = GetPlayerServerId(plyId)
    if value then
        activeLights[serverId] = { plyId = plyId, data = value }
    else
        activeLights[serverId] = nil
    end
end)

-- Draws the flashlight for every player registered in activeLights each frame.
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local toRemove = {}
        local myPos = GetEntityCoords(PlayerPedId())

        for serverId, lightInfo in pairs(activeLights) do
            if not NetworkIsPlayerActive(lightInfo.plyId) then
                toRemove[#toRemove + 1] = serverId
                goto continue_light
            end

            local ped = GetPlayerPed(lightInfo.plyId)
            if ped ~= 0 and DoesEntityExist(ped) then
                local pedPos = GetEntityCoords(ped)
                if #(myPos - pedPos) > 60.0 then goto continue_light end

                sleep = 0
                local light = lightInfo.data
                local lPos = GetPedBoneCoords(ped, BONE_HEAD,
                    light.offset.x, light.offset.y, light.offset.z)
                local dir = getLightDirection(ped)
                DrawSpotLightWithShadow(
                    lPos.x, lPos.y, lPos.z,
                    dir.x, dir.y, dir.z,
                    light.color.r + 0, light.color.g + 0, light.color.b + 0,
                    light.distance + 0.0, light.brightness + 0.0,
                    (light.hardness or 0.0) + 0.0,
                    light.radius + 0.0,
                    (light.falloff or 1.0) + 0.0
                )
            else
                toRemove[#toRemove + 1] = serverId
            end
            ::continue_light::
        end
        for _, serverId in ipairs(toRemove) do
            activeLights[serverId] = nil
        end
        Wait(sleep)
    end
end)
