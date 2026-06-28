-- ESX Usable Item Bridge (Server Only)
if not Bridge.IsServer then return end

local ESX = exports['es_extended']:getSharedObject()

function Bridge.RegisterItem(itemName, style)
    ESX.RegisterUsableItem(itemName, function(source)
        if not isItemUseEnabled(style) then return end
        if not Bridge.IsActive(source) then return end
        TriggerClientEvent('sk_nightvision:client:UseItem', source, style)
    end)
end

-- Trigger registration for all items defined in items.lua
for itemName, style in pairs(Config.Items) do
    Bridge.RegisterItem(itemName, style)
end
