-- Main Orchestration Logic

-- Vision mode numbers (cycle order):
--   0: OFF
--   1: NVG (green phosphor)
--   2: White NVG (white phosphor)
--   3: Fusion (white phosphor + ped glow highlight)
--   4: Thermal
--   5: Light
NV_State = {
    currentVisionMode = 0,
    activeStyle       = "helmet",
    isGogglesDown     = false,
    isEquipped        = false,
    isAnimating       = false,
    equippedPropId    = -1,
    originalCameraMode = nil,
    scaleformHandle   = nil
}

local CONTROL_IDS = {
    ["INPUT_CONTEXT"]            = 51,
    ["INPUT_REPLAY_START_STOP"]  = 289,
}
local VEHICLE_CLASS_BIKE     = 8
local VEHICLE_CLASS_MILITARY = 13
local ANIM_WATCHDOG_TIMEOUT  = 6000
local VIEW_MODE_FIRST_PERSON = 4
local POLL_INTERVAL_GEAR     = 100

-- Sets isAnimating and starts a watchdog thread to force-clear the flag on timeout.
-- A token is used so that only the watchdog belonging to the most recent beginAnimation
-- call can clear the flag, preventing stale watchdogs from releasing a newer lock.
local animToken = 0
local function beginAnimation()
    animToken = animToken + 1
    local currentToken = animToken
    NV_State.isAnimating = true
    Citizen.CreateThread(function()
        Wait(ANIM_WATCHDOG_TIMEOUT)
        if animToken == currentToken and NV_State.isAnimating then
            print("^3[sk_nightvision] WARNING: isAnimating watchdog timeout, forcing unlock^0")
            NV_State.isAnimating = false
        end
    end)
end

-- Equips or unequips gear. forceOff bypasses permission checks and animation locks.
function toggleEquipment(style, forceOff)
    if NV_State.isAnimating and not forceOff then return end
    if not forceOff and not Bridge.CanUse() then
        notify(L('no_permission'), 'error')
        return
    end
    if forceOff and not NV_State.isEquipped then return end

    beginAnimation()
    Citizen.CreateThread(function()
        local ok, err = pcall(function()
            local ped = PlayerPedId()
            if NV_State.isEquipped then
                local currentStyle   = NV_State.activeStyle
                local requestedStyle = style or currentStyle
                if requestedStyle == currentStyle then
                    doUnequip(ped, forceOff)
                    if not forceOff then notify(L('unequipped'), "primary") end
                else
                    doUnequip(ped, forceOff)
                    Wait(200)
                    doEquip(ped, requestedStyle)
                    notify(L('equipped'), "success")
                end
            else
                doEquip(ped, style or "helmet")
                notify(L('equipped'), "success")
            end
        end)
        if not ok then print("[sk_nightvision] toggleEquipment error: " .. tostring(err)) end
        NV_State.isAnimating = false
    end)
end

-- Raises or lowers the visor. forceState overrides toggle; suppressVision skips vision activation.
function flipGoggles(forceState, suppressVision, bypassPermission)
    if NV_State.isAnimating or not NV_State.isEquipped or not hasVisor() then return end
    if not bypassPermission and not canUseGoggles() then
        notify(L('no_permission'), 'error')
        return
    end

    beginAnimation()
    Citizen.CreateThread(function()
        local ok, err = pcall(function()
            local style      = Config.Styles[NV_State.activeStyle]
            local targetDown = (forceState ~= nil) and forceState or not NV_State.isGogglesDown
            playSound("toggle", style)

            if style and style.EnableToggleAnimation and getAnimSetting(style, 'EnableVisorAnim') then
                if targetDown then
                    local function onVisorDownCallback()
                        NV_State.isGogglesDown = true
                        syncPropModel(true)
                        if suppressVision then
                            clearVisionEffects()
                            LocalPlayer.state:set("helmetLight", false, true)
                        else
                            toggleVisionState(true)
                        end
                    end
                    playAnimWithCallback(getAnimSetting(style, 'VisorDownDict'), getAnimSetting(style, 'VisorDownAnim'), getAnimSetting(style, 'DurationMS'), onVisorDownCallback, getAnimSetting(style, 'VisorDownCallbackDelay'))
                else
                    local function onVisorUpCallback()
                        NV_State.currentVisionMode = 0
                        restoreCameraMode()
                        clearVisionEffects()
                        LocalPlayer.state:set("helmetLight", false, true)
                    end
                    playAnimWithCallback(getAnimSetting(style, 'VisorUpDict'), getAnimSetting(style, 'VisorUpAnim'), getAnimSetting(style, 'DurationMS'), onVisorUpCallback, getAnimSetting(style, 'VisorUpCallbackDelay'))
                    NV_State.isGogglesDown = false
                    syncPropModel(false)
                end
            else
                NV_State.isGogglesDown = targetDown
                if not NV_State.isGogglesDown then NV_State.currentVisionMode = 0; restoreCameraMode() end
                syncPropModel(NV_State.isGogglesDown)
                if suppressVision then
                    clearVisionEffects()
                    LocalPlayer.state:set("helmetLight", false, true)
                else
                    toggleVisionState(NV_State.isGogglesDown)
                end
            end
        end)
        if not ok then print("[sk_nightvision] flipGoggles error: " .. tostring(err)) end
        NV_State.isAnimating = false
    end)
end

-- Advances to the next enabled vision mode for the active style.
function cycleVision()
    if NV_State.isAnimating or not NV_State.isEquipped or (hasVisor() and not NV_State.isGogglesDown) then return end
    if not canUseGoggles() then
        notify(L('no_permission'), 'error')
        return
    end

    local style       = Config.Styles[NV_State.activeStyle]
    local enableModes = style and style.EnableModes or {}
    local enabledModes = {}
    if enableModes.NVG      ~= false then enabledModes[#enabledModes + 1] = 1 end
    if enableModes.WhiteNVG ~= false then enabledModes[#enabledModes + 1] = 2 end
    if enableModes.Fusion   ~= false then enabledModes[#enabledModes + 1] = 3 end
    if enableModes.Thermal  ~= false then enabledModes[#enabledModes + 1] = 4 end
    if style and style.Flashlight and enableModes.Light ~= false then enabledModes[#enabledModes + 1] = 5 end

    if #enabledModes == 0 then return end

    local currentPos = nil
    for i, m in ipairs(enabledModes) do
        if m == NV_State.currentVisionMode then currentPos = i; break end
    end

    local nextIndex = (currentPos == nil) and enabledModes[1] or ((currentPos >= #enabledModes) and 0 or enabledModes[currentPos + 1])
    NV_State.currentVisionMode = nextIndex

    playSound("switch", style)
    syncPropModel(true)

    if Config.ForceFirstPerson then
        -- Modes 1-4 (NVG, WhiteNVG, Fusion, Thermal) enforce first-person view.
        if NV_State.currentVisionMode >= 1 and NV_State.currentVisionMode <= 4 then
            if NV_State.originalCameraMode == nil then NV_State.originalCameraMode = GetFollowPedCamViewMode() end
            SetFollowPedCamViewMode(VIEW_MODE_FIRST_PERSON)
        else
            if NV_State.originalCameraMode ~= nil then restoreCameraMode() end
        end
    end

    applyVisionEffect(NV_State.currentVisionMode, false, false)

    if NV_State.currentVisionMode == 5 then
        LocalPlayer.state:set("helmetLight", style.Flashlight, true)
    else
        LocalPlayer.state:set("helmetLight", false, true)
    end
end

-- Receives item use events from server-side inventory bridges.
RegisterNetEvent('sk_nightvision:client:UseItem', function(style)
    local styleData = Config.Styles[style]
    if not styleData then
        print(("[sk_nightvision] UseItem: unknown style '%s'"):format(tostring(style)))
        return
    end
    if not styleData.EnableItemUse then
        notify(L('item_disabled'), 'error')
        return
    end
    toggleEquipment(style)
end)

RegisterNetEvent('sk_nightvision:client:ToggleGoggles', function()
    local styleData = Config.Styles[NV_State.activeStyle]
    if NV_State.isEquipped and styleData and styleData.EnableCommands then flipGoggles() end
end)

RegisterNetEvent('sk_nightvision:client:CycleVision', function()
    local styleData = Config.Styles[NV_State.activeStyle]
    if NV_State.isEquipped and styleData and styleData.EnableCommands then cycleVision() end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    -- Always initialize texture slots regardless of Config.UI.VignetteMode,
    -- because individual styles may override the mode to "sprite".
    initVignetteSlot()
    refreshVignetteAspectRatio()
    initPedGlowSlot()
    loadPedGlowTexture()
    Citizen.CreateThread(function()
        preloadAnimDicts()
    end)
end)

RegisterCommand("toggle_nvg", function()
    TriggerServerEvent('sk_nightvision:server:RequestToggle')
end)
RegisterCommand("cycle_nvg", function()
    TriggerServerEvent('sk_nightvision:server:RequestCycle')
end)
RegisterKeyMapping("toggle_nvg", L('key_toggle_desc'), "keyboard", Config.ControlKeys.ToggleGoggles)
RegisterKeyMapping("cycle_nvg", L('key_cycle_desc'), "keyboard", Config.ControlKeys.CycleVisionModes)

-- Enforces first-person view every frame while a vision mode that requires it is active.
Citizen.CreateThread(function()
    while true do
        if NV_State.isEquipped and Config.ForceFirstPerson and NV_State.isGogglesDown
            and not NV_State.isAnimating
            and NV_State.currentVisionMode >= 1 and NV_State.currentVisionMode <= 4 then
            if GetFollowPedCamViewMode() ~= VIEW_MODE_FIRST_PERSON then
                SetFollowPedCamViewMode(VIEW_MODE_FIRST_PERSON)
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- Monitors gear integrity, vehicle entry, death, and underwater state.
Citizen.CreateThread(function()
    while true do
        if not NV_State.isEquipped then
            Wait(500)
        else
            local ped          = PlayerPedId()
            local shouldContinue = false
            local style        = Config.Styles[NV_State.activeStyle]

            -- Detect external prop/component removal (e.g. outfit change).
            if style and NV_State.equippedPropId ~= -1 then
                local currentId
                if style.SlotType == "component" then
                    currentId = GetPedDrawableVariation(ped, style.Slot)
                    if currentId == 0 and NV_State.equippedPropId ~= 0 then
                        toggleEquipment(nil, true); notify(L('removed_invalid'), "error"); shouldContinue = true
                    end
                else
                    currentId = GetPedPropIndex(ped, style.Slot)
                    if currentId ~= NV_State.equippedPropId then
                        toggleEquipment(nil, true); notify(L('removed_invalid'), "error"); shouldContinue = true
                    end
                end
            end

            if not shouldContinue and Config.AutoUnequipInVehicle then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 then
                    local class = GetVehicleClass(vehicle)
                    if class ~= VEHICLE_CLASS_BIKE and class ~= VEHICLE_CLASS_MILITARY then
                        toggleEquipment(nil, true); notify(L('removed_vehicle'), "primary"); shouldContinue = true
                    end
                end
            end
            if not shouldContinue and IsPedDeadOrDying(ped, true) then
                toggleEquipment(nil, true); notify(L('removed_death'), "error"); shouldContinue = true
            end
            if not shouldContinue and NV_State.isGogglesDown and not NV_State.isAnimating and IsPedSwimmingUnderWater(ped) then
                notify(L('underwater_disabled'), 'error'); flipGoggles(false, true, true)
            end

            refreshVignetteAspectRatio()

            Wait(POLL_INTERVAL_GEAR)
        end
    end
end)

-- Polls gamepad buttons for visor toggle and mode cycle.
Citizen.CreateThread(function()
    while true do
        if NV_State.isEquipped and not IsInputDisabled(0) then
            local padToggleId = Config.ControlKeys.PadToggle and CONTROL_IDS[Config.ControlKeys.PadToggle]
            local padCycleId  = Config.ControlKeys.PadCycle  and CONTROL_IDS[Config.ControlKeys.PadCycle]
            if padToggleId and IsControlJustPressed(0, padToggleId) then
                TriggerServerEvent('sk_nightvision:server:RequestToggle')
            elseif padCycleId and IsControlJustPressed(0, padCycleId) then
                TriggerServerEvent('sk_nightvision:server:RequestCycle')
            end
            Wait(0)
        else
            Wait(200)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    if NV_State.isEquipped then
        local styleData = Config.Styles[NV_State.activeStyle]
        clearEquippedModel(ped, styleData)
        clearVisionEffects()
        LocalPlayer.state:set("helmetLight", false, true)
        restoreConflicts(ped)
    end
    restoreCameraMode()
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' and args[1] == PlayerPedId()
        and NV_State.isGogglesDown and NV_State.isEquipped then
        local snapshotMode = NV_State.currentVisionMode
        Citizen.CreateThread(function()
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
            SetTimecycleModifierStrength(2.0)
            Wait(300)
            if NV_State.isGogglesDown and NV_State.isEquipped and NV_State.currentVisionMode == snapshotMode then
                applyVisionEffect(NV_State.currentVisionMode, true)
            end
        end)
    end
end)
