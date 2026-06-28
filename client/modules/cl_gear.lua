-- Gear and Model Management

local savedConflicts    = nil
local cachedGender      = nil
local cachedPedForGender = nil

local PROP_NONE      = -1
local COMPONENT_NONE =  0

-- Returns "Male" or "Female" for the local player, cached per ped handle.
function getGender()
    local ped = PlayerPedId()
    if ped ~= cachedPedForGender then
        cachedPedForGender = ped
        cachedGender = IsPedModel(ped, `mp_f_freemode_01`) and "Female" or "Male"
    end
    return cachedGender
end

-- Returns true if the gear is equipped and the player has permission.
function canUseGoggles()
    if not Bridge.Ready then return false end
    if not NV_State.isEquipped then return false end
    local styleData = Config.Styles[NV_State.activeStyle]
    if not styleData then return false end
    return Bridge.CanUse()
end

-- Returns true if the current style supports visor toggle.
function hasVisor()
    local styleData = Config.Styles[NV_State.activeStyle]
    return styleData and styleData.EnableVisor ~= false
end

-- Returns an animation setting value for the given style, falling back to Config.AnimationSettings.
function getAnimSetting(style, key)
    if style and style.AnimationSettings and style.AnimationSettings[key] ~= nil then
        return style.AnimationSettings[key]
    end
    return Config.AnimationSettings[key]
end

-- Clears the currently equipped prop or component from the ped.
function clearEquippedModel(ped, styleData)
    if not styleData then return end
    local slot = styleData.Slot
    if not slot then return end
    if styleData.SlotType == "component" then
        SetPedComponentVariation(ped, slot, COMPONENT_NONE, 0, 0)
    else
        ClearPedProp(ped, slot)
    end
end

-- Saves the current values of conflicting props/components and clears them.
function saveAndClearConflicts(ped, styleData)
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
                savedConflicts.components[slot] = {
                    drawable = (drawable >= 0) and drawable or -1,
                    tex      = tex
                }
            end
            SetPedComponentVariation(ped, slot, COMPONENT_NONE, 0, 0)
        end
    end
end

-- Restores props/components saved by saveAndClearConflicts.
function restoreConflicts(ped)
    if not savedConflicts then return end
    for slot, data in pairs(savedConflicts.props) do
        if data.id ~= -1 then SetPedPropIndex(ped, slot, data.id, data.tex, true)
        else ClearPedProp(ped, slot) end
    end
    for slot, data in pairs(savedConflicts.components) do
        if data.drawable ~= -1 then SetPedComponentVariation(ped, slot, data.drawable, data.tex, 0)
        else SetPedComponentVariation(ped, slot, COMPONENT_NONE, 0, 0) end
    end
    savedConflicts = nil
end

-- Synchronizes the prop or component model to match the current visor state.
function syncPropModel(isDown)
    if not NV_State.isEquipped then return end
    local ped    = PlayerPedId()
    local gender = getGender()
    local style  = Config.Styles[NV_State.activeStyle]
    if not style or not style[gender] then return end

    local id, texture
    if isDown then
        id      = style[gender].DownModel
        texture = style[gender].DownTexture or 0
    else
        local upModel = style[gender].UpModel
        if upModel and upModel ~= -1 then
            id      = upModel
            texture = style[gender].UpTexture or 0
        else
            id      = style[gender].DownModel
            texture = style[gender].UpTexture or (style[gender].DownTexture or 0)
        end
    end

    if style.SlotType == "component" then
        local slot = style.Slot
        if not slot then return end
        if id and id ~= -1 then
            SetPedComponentVariation(ped, slot, id, texture, 0)
            NV_State.equippedPropId = id
        else
            SetPedComponentVariation(ped, slot, COMPONENT_NONE, 0, 0)
            NV_State.equippedPropId = PROP_NONE
        end
    else
        local slot = style.Slot
        if id and id ~= -1 then
            SetPedPropIndex(ped, slot, id, texture, true)
            NV_State.equippedPropId = id
        else
            ClearPedProp(ped, slot)
            NV_State.equippedPropId = PROP_NONE
        end
    end
end

-- Applies or clears vision effects based on the visor state.
function toggleVisionState(isDown)
    if not isDown then
        applyVisionEffect(0)
        LocalPlayer.state:set("helmetLight", false, true)
    else
        applyVisionEffect(NV_State.currentVisionMode, true, false)
    end
end

-- Restores the saved camera mode when leaving a vision mode that enforced first-person.
function restoreCameraMode()
    if Config.ForceFirstPerson and NV_State.originalCameraMode then
        SetFollowPedCamViewMode(NV_State.originalCameraMode)
        NV_State.originalCameraMode = nil
    end
end

-- Handles the unequipment sequence, with or without animation.
function doUnequip(ped, forceOff)
    NV_State.isGogglesDown = false
    restoreCameraMode()

    if forceOff then
        ClearPedTasksImmediately(ped)
        local styleData = Config.Styles[NV_State.activeStyle]
        clearEquippedModel(ped, styleData)
        restoreConflicts(ped)
        NV_State.isEquipped        = false
        NV_State.currentVisionMode = 0
        clearVisionEffects()
        LocalPlayer.state:set("helmetLight", false, true)
        NV_State.equippedPropId = PROP_NONE
        return
    end

    local styleData = Config.Styles[NV_State.activeStyle]
    local function onUnequipCallback()
        NV_State.currentVisionMode = 0
        clearVisionEffects()
        LocalPlayer.state:set("helmetLight", false, true)
    end

    if getAnimSetting(styleData, 'EnableUnequipAnim') then
        playAnimWithCallback(
            getAnimSetting(styleData, 'UnequipDict'),
            getAnimSetting(styleData, 'UnequipAnim'),
            getAnimSetting(styleData, 'UnequipDuration'),
            onUnequipCallback,
            getAnimSetting(styleData, 'UnequipCallbackDelay')
        )
    else
        onUnequipCallback()
    end

    clearEquippedModel(ped, styleData)
    restoreConflicts(ped)
    NV_State.isEquipped     = false
    NV_State.equippedPropId = PROP_NONE
end

-- Handles the equipment sequence, with or without animation.
function doEquip(ped, styleName)
    NV_State.activeStyle = styleName
    local styleData = Config.Styles[NV_State.activeStyle]
    if not styleData then return end

    loadVignetteForStyle(styleName)
    saveAndClearConflicts(ped, styleData)

    local function onEquipCallback()
        NV_State.isEquipped        = true
        NV_State.isGogglesDown     = false
        NV_State.currentVisionMode = 0
        syncPropModel(false)
        toggleVisionState(false)
    end

    if getAnimSetting(styleData, 'EnableEquipAnim') then
        playAnimWithCallback(
            getAnimSetting(styleData, 'EquipDict'),
            getAnimSetting(styleData, 'EquipAnim'),
            getAnimSetting(styleData, 'EquipDuration'),
            onEquipCallback,
            getAnimSetting(styleData, 'EquipCallbackDelay')
        )
    else
        onEquipCallback()
    end
end
