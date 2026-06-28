-- QB-Inventory Bridge (Server Only)
if not Bridge.IsServer then return end

local QBCore = exports['qb-core']:GetCoreObject()

function Bridge.RegisterItem(itemName, style)
    QBCore.Functions.CreateUseableItem(itemName, function(source, item)
        if not isItemUseEnabled(style) then return end
        if not Bridge.IsActive(source) then return end
        TriggerClientEvent('sk_nightvision:client:UseItem', source, style)
    end)
end

-- Trigger registration for all items
for itemName, style in pairs(Config.Items) do
    Bridge.RegisterItem(itemName, style)
end
