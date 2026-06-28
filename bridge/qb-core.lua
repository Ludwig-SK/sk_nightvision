-- QB-Core Bridge Implementation
local QBCore = exports['qb-core']:GetCoreObject()

if Bridge.IsServer then
    -- Server Side
    function Bridge.Notify(source, message, type)
        TriggerClientEvent('QBCore:Notify', source, message, type or 'primary')
    end
else
    -- Client Side
    Bridge.Player = QBCore.Functions.GetPlayerData()

    function Bridge.Notify(message, type)
        QBCore.Functions.Notify(message, type or 'primary')
    end

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Bridge.Player = QBCore.Functions.GetPlayerData()
    end)

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        Bridge.Player.job = job
        if NV_State and NV_State.isEquipped and not Bridge.CanUse() then
            toggleEquipment(nil, true)
            Bridge.Notify(L('no_permission'), "error")
        end
    end)
end
