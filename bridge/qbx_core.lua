-- QBX-Core Bridge Implementation
if Bridge.IsServer then
    function Bridge.Notify(source, message, type)
        exports.qbx_core:Notify(source, message, type or 'primary')
    end
else
    Bridge.Player = exports.qbx_core:GetPlayerData()

    function Bridge.Notify(message, type)
        exports.qbx_core:Notify(message, type or 'primary')
    end

    local function setupJobHandler()
        local serverId = GetPlayerServerId(PlayerId())
        if serverId == 0 then return end
        AddStateBagChangeHandler('job', ('player:%d'):format(serverId), function(_, _, value)
            Bridge.Player.job = value
            if NV_State and NV_State.isEquipped and not Bridge.CanUse() then
                toggleEquipment(nil, true)
                Bridge.Notify(L('no_permission'), "error")
            end
        end)
    end

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Bridge.Player = exports.qbx_core:GetPlayerData()
        setupJobHandler()
    end)

    if LocalPlayer.state.isLoggedIn then setupJobHandler() end

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        Bridge.Player.job = job
        if NV_State and NV_State.isEquipped and not Bridge.CanUse() then
            toggleEquipment(nil, true)
            Bridge.Notify(L('no_permission'), "error")
        end
    end)
end
