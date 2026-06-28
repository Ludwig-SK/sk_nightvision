-- Ox Inventory Bridge Implementation
if not Bridge.IsServer then return end

AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId, metadata)
    if not name then return end
    local style = Config.Items[name]
    if not style then return end
    if not isItemUseEnabled(style) then return end
    if not Bridge.IsActive(playerId) then return end
    TriggerClientEvent('sk_nightvision:client:UseItem', playerId, style)
end)

function Bridge.RegisterItem(itemName, style)
    -- No action needed: ox_inventory handles this via the usedItem event above.
end
