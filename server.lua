local framework = nil

-- Returns whether item use is enabled for the given style.
local function isItemUseEnabled(style)
    local styleData = Config.Styles[style]
    return styleData and styleData.EnableItemUse
end

-- Framework detection and item use event registration.
Citizen.CreateThread(function()
    if GetResourceState('ox_inventory') == 'started' then
        -- Uses ox_inventory's usedItem event.
        -- The second argument is the item name as a string (not a table).
        AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId, metadata)
            if not name then return end
            local style = Config.Items[name]
            if not style then return end
            if not isItemUseEnabled(style) then return end
            if not playerId or playerId <= 0 or not GetPlayerName(playerId) then return end
            TriggerClientEvent('sk_nightvision:client:UseItem', playerId, style)
        end)
        return
    end

    if GetResourceState('qb-core') == 'started' then
        framework = "qb"
        local QBCore = exports['qb-core']:GetCoreObject()
        for itemName, style in pairs(Config.Items) do
            QBCore.Functions.CreateUseableItem(itemName, function(source, item)
                if not isItemUseEnabled(style) then return end
                if not source or source <= 0 or not GetPlayerName(source) then return end
                TriggerClientEvent('sk_nightvision:client:UseItem', source, style)
            end)
        end
    elseif GetResourceState('es_extended') == 'started' then
        framework = "esx"
        local ESX = exports['es_extended']:getSharedObject()
        for itemName, style in pairs(Config.Items) do
            ESX.RegisterUsableItem(itemName, function(source)
                if not isItemUseEnabled(style) then return end
                if not source or source <= 0 or not GetPlayerName(source) then return end
                TriggerClientEvent('sk_nightvision:client:UseItem', source, style)
            end)
        end
    elseif GetResourceState('qbx_core') == 'started' then
        framework = "qbx"
        for itemName, style in pairs(Config.Items) do
            exports.qbx_core:CreateUseableItem(itemName, function(source, item)
                if not isItemUseEnabled(style) then return end
                if not source or source <= 0 or not GetPlayerName(source) then return end
                TriggerClientEvent('sk_nightvision:client:UseItem', source, style)
            end)
        end
    end
end)
