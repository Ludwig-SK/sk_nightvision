-- ESX Bridge Implementation
if Bridge.IsServer then
    -- Server Side
    function Bridge.Notify(source, message, type)
        local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(source)
        if xPlayer then xPlayer.showNotification(message) end
    end
else
    -- Client Side
    local ESX = exports['es_extended']:getSharedObject()
    Bridge.Player = ESX.GetPlayerData()

    function Bridge.Notify(message, type)
        ESX.ShowNotification(message)
    end

    RegisterNetEvent('esx:playerLoaded', function(data)
        Bridge.Player = data
    end)

    RegisterNetEvent('esx:setJob', function(job)
        Bridge.Player.job = job
        if NV_State and NV_State.isEquipped and not Bridge.CanUse() then
            toggleEquipment(nil, true)
            Bridge.Notify(L('no_permission'), "error")
        end
    end)
end
