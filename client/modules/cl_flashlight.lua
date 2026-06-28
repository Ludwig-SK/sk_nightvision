-- Flashlight Sync and Rendering
activeLights = {} -- Full light registry (serverId -> info)
nearbyLights = {} -- Subset of activeLights within drawing range
boneRotCache = {}
local BONE_ROT_TTL = 50 -- ms (increased from 32ms)
local BONE_HEAD = 0x4B5

-- Flashlight Sync & Rendering
local function rotationToDirection(rot)
    local x, z = math.rad(rot.x), math.rad(rot.z)
    local cosX = math.cos(x)
    return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

function getLightDirectionCached(ped, serverId)
    local now = GetGameTimer()
    if ped == PlayerPedId() then
        local boneIndex = GetPedBoneIndex(ped, BONE_HEAD)
        local boneRot = (boneIndex ~= -1) and GetEntityBoneRotation(ped, boneIndex, 2) or GetEntityRotation(ped, 2)
        return rotationToDirection(vector3(GetGameplayCamRot(2).x, boneRot.y, boneRot.z))
    end
    local cache = boneRotCache[serverId]
    if not cache or (now - cache.t) > BONE_ROT_TTL then
        local boneIndex = GetPedBoneIndex(ped, BONE_HEAD)
        local rot = (boneIndex ~= -1) and GetEntityBoneRotation(ped, boneIndex, 2) or GetEntityRotation(ped, 2)
        cache = { rot = rot, t = now }
        boneRotCache[serverId] = cache
    end
    return rotationToDirection(cache.rot)
end

-- ステートバッグ経由で受け取った lightData を正規化する。
-- LocalPlayer.state:set() でシリアライズされると以下の型崩れが起きる:
--   vector3 → テーブル {x, y, z}
--   float   → 整数 (DrawSpotLightWithShadow はfloatを要求するため描画失敗の原因になる)
--   color   → テーブル {r, g, b} (構造は維持されるが念のため再構築)
-- + 0.0 を使って全数値フィールドを明示的にfloatへ変換する。
local function normalizeLightData(value)
    if not value then return nil end
    local off = value.offset or {}
    local col = value.color  or {}
    return {
        offset     = vector3(off.x + 0.0, off.y + 0.0, off.z + 0.0),
        color      = { r = col.r or 255, g = col.g or 255, b = col.b or 255 },
        distance   = (value.distance   or 60.0)  + 0.0,
        brightness = (value.brightness or 15.0)  + 0.0,
        hardness   = (value.hardness   or 0.8)   + 0.0,
        radius     = (value.radius     or 45.0)  + 0.0,
        falloff    = (value.falloff    or 1.0)   + 0.0,
    }
end

AddStateBagChangeHandler("helmetLight", nil, function(bagName, key, value)
    local plyId = GetPlayerFromStateBagName(bagName)
    if plyId == 0 then return end
    local serverId = GetPlayerServerId(plyId)
    if value then
        activeLights[serverId] = { plyId = plyId, data = normalizeLightData(value) }
    else
        activeLights[serverId] = nil
        nearbyLights[serverId] = nil
    end
end)

-- Low-frequency Distance Check Thread
Citizen.CreateThread(function()
    while true do
        if not next(activeLights) then Wait(500)
        else
            local myPos = GetEntityCoords(PlayerPedId())
            local nextNearby = {}
            for serverId, info in pairs(activeLights) do
                if NetworkIsPlayerActive(info.plyId) then
                    local ped = GetPlayerPed(info.plyId)
                    if ped ~= 0 and DoesEntityExist(ped) and #(myPos - GetEntityCoords(ped)) <= 60.0 then
                        nextNearby[serverId] = info
                    end
                end
            end
            -- Clean up old rotation cache
            for serverId in pairs(boneRotCache) do
                if not nextNearby[serverId] then
                    boneRotCache[serverId] = nil
                end
            end
            nearbyLights = nextNearby
            Wait(100)
        end
    end
end)

-- Flashlight Draw Thread
Citizen.CreateThread(function()
    while true do
        if not next(nearbyLights) then Wait(500)
        else
            local count = 0
            local limit = Config.MaxVisibleLights or 0

            for serverId, info in pairs(nearbyLights) do
                if limit > 0 and count >= limit then break end

                local playerIdx = GetPlayerFromServerId(serverId)
                if playerIdx ~= -1 then
                    local targetPed = GetPlayerPed(playerIdx)
                    if targetPed ~= 0 and DoesEntityExist(targetPed) then
                        local lightData = info.data
                        local lPos = GetPedBoneCoords(targetPed, BONE_HEAD, lightData.offset.x, lightData.offset.y, lightData.offset.z)
                        local dir = getLightDirectionCached(targetPed, serverId)
                        DrawSpotLightWithShadow(
                            lPos.x, lPos.y, lPos.z,
                            dir.x, dir.y, dir.z,
                            lightData.color.r, lightData.color.g, lightData.color.b,
                            lightData.distance, lightData.brightness,
                            lightData.hardness, lightData.radius, lightData.falloff
                        )
                        count = count + 1
                    end
                end
            end
            Wait(0)
        end
    end
end)
