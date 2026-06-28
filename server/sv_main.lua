-- server/sv_main.lua
-- Shared server-side helper functions.

-- Returns whether item use is enabled for the given style.
function isItemUseEnabled(style)
    local styleData = Config.Styles[style]
    return styleData and styleData.EnableItemUse
end

-- Validates that the source is an active, connected player.
function isValidPlayer(source)
    return Bridge.IsValidPlayer(source)
end

-- Request toggle from client
RegisterNetEvent('sk_nightvision:server:RequestToggle', function()
    local src = source
    if not Bridge.IsActive(src) then return end
    
    -- In a production environment, you might want to perform an additional
    -- job check here on the server side using Bridge.HasPermission(src).
    
    TriggerClientEvent('sk_nightvision:client:ToggleGoggles', src)
end)

-- Request cycle from client
RegisterNetEvent('sk_nightvision:server:RequestCycle', function()
    local src = source
    if not Bridge.IsActive(src) then return end
    
    TriggerClientEvent('sk_nightvision:client:CycleVision', src)
end)
