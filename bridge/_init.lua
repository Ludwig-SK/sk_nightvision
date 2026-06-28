-- sk_nightvision Unified Dynamic Bridge (Namespace: Bridge)
Bridge = {
    System = "standalone",
    Player = {},
    HasSound = false,
    IsServer = IsDuplicityVersion(),
    Ready = false -- Initialization completion flag
}

-- Loads a bridge module file dynamically using LoadResourceFile and load()
function Bridge.LoadModule(moduleName)
    local fileName = ("bridge/%s.lua"):format(moduleName)
    local fileData = LoadResourceFile(GetCurrentResourceName(), fileName)
    if not fileData then
        return false
    end

    local loader, err = load(fileData, ("@@%s/%s"):format(GetCurrentResourceName(), fileName))
    if not loader then
        print(("^1[sk_nightvision] Error loading module %s: %s^0"):format(moduleName, err))
        return false
    end

    local ok, res = pcall(loader)
    if not ok then
        print(("^1[sk_nightvision] Error executing module %s: %s^0"):format(moduleName, res))
        return false
    end

    return true
end

-- [Shared] Display a notification.
function Bridge.Notify(targetOrMsg, msgOrType)
    if not Config.EnableNotifications then return end
    
    if Bridge.IsServer then
        -- targetOrMsg = source, msgOrType = message
    else
        -- targetOrMsg = message
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(targetOrMsg)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

-- [Client Only] Permission check for gear usage.
function Bridge.CanUse()
    if not Config.RestrictByJob or Bridge.System == "standalone" then return true end

    -- =====================================================================
    -- [FIX③] Playerデータ未取得時のフォールバック
    -- Bridge.Ready == true でも job が nil のままのケース（ログイン直後など）に
    -- 対応するため、フレームワークから再取得を試みる。
    -- =====================================================================
    if not Bridge.Player or not Bridge.Player.job then
        if Bridge.System == "qb" then
            local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and core then Bridge.Player = core.Functions.GetPlayerData() end
        elseif Bridge.System == "qbx" then
            local ok, data = pcall(function() return exports.qbx_core:GetPlayerData() end)
            if ok then Bridge.Player = data end
        elseif Bridge.System == "esx" then
            local ok, esx = pcall(function() return exports['es_extended']:getSharedObject() end)
            if ok and esx then Bridge.Player = esx.GetPlayerData() end
        end
        -- 再取得後もなければ拒否
        if not Bridge.Player or not Bridge.Player.job then return false end
    end

    local styleData = Config.Styles[NV_State.activeStyle]
    local permittedJobs = styleData and styleData.PermittedJobs
    if not permittedJobs then return true end

    local jobName  = Bridge.Player.job.name
    local g = Bridge.Player.job.grade
    local jobGrade = 0
    
    if type(Bridge.Player.job.gradeLevel) == "number" then
        jobGrade = Bridge.Player.job.gradeLevel
    elseif g ~= nil then
        if type(g) == "number" then jobGrade = g
        elseif type(g) == "table" then
            if type(g.level) == "number" then jobGrade = g.level
            elseif type(g.grade) == "number" then jobGrade = g.grade end
        end
    end

    if type(jobName) ~= "string" then return false end
    if permittedJobs[jobName] == nil then return false end
    if jobGrade < permittedJobs[jobName] then return false end
    return true
end

-- [Server Only] Registers an item as usable.
function Bridge.RegisterItem(itemName, style)
    -- Placeholder for standalone
end

-- [Server Only] Validates a player source.
function Bridge.IsActive(source)
    return source and source > 0 and GetPlayerName(source) ~= nil
end
Bridge.IsValidPlayer = Bridge.IsActive

-- Initialization Thread
Citizen.CreateThread(function()
    -- =====================================================================
    -- [FIX②] Wait(0) を追加
    -- shared_scripts は同一フレームで評価されるが、bridge/_init.lua は
    -- 他の shared_scripts より先にロードされる（fxmanifest上の定義順）ため、
    -- 1フレーム待つことで Config / NV_State 等の依存グローバルが
    -- 確実に初期化された状態でフレームワーク検出を行う。
    -- =====================================================================
    Wait(0)

    local hasOxInventory = GetResourceState('ox_inventory') == 'started'
    local hasQB          = GetResourceState('qb-core')     == 'started'
    local hasQBX         = GetResourceState('qbx_core')    == 'started'
    local hasESX         = GetResourceState('es_extended') == 'started'
    local hasND          = GetResourceState('ND_Core')     == 'started'

    -- Framework Detection & Loading
    if hasQBX then
        Bridge.System = "qbx"
        Bridge.LoadModule("qbx_core")
    elseif hasQB then
        Bridge.System = "qb"
        Bridge.LoadModule("qb-core")
        if Bridge.IsServer and not hasOxInventory then Bridge.LoadModule("qb-inventory") end
    elseif hasESX then
        Bridge.System = "esx"
        Bridge.LoadModule("es_extended")
        if Bridge.IsServer and not hasOxInventory then Bridge.LoadModule("esx_inventory") end
--    elseif hasND then
--        Bridge.System = "nd"
--        Bridge.LoadModule("nd-core")
    end

    -- Special handling for ox_inventory (can coexist with others)
    if Bridge.IsServer and hasOxInventory then
        Bridge.LoadModule("ox_inventory")
    end

    if not Bridge.IsServer then
        Bridge.HasSound = Config.UseXSound and GetResourceState('xsound') == 'started'
    end

    Bridge.Ready = true
end)
