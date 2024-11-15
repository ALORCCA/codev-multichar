Framework = Config.Framework == "esx" and exports['es_extended']:getSharedObject() or exports['qb-core']:GetCoreObject()

RegisterServerEvent("codev-multichar:playerConnected", function ()
    local src = source
    local random = math.random(10, 999999)
    local license = GetPlayerLicense(src)
    local response2 = {}

    if Config.Framework == "qb" then
        local data = GetUserPlayers(src)

        if data and next(data) then
            TriggerClientEvent("codev-multichar:playerConnected", src, data.charData, data.purchasedSlots)
        else
            TriggerClientEvent("codev-multichar:playerConnected", src, {}, 0)
        end
    end

    TriggerClientEvent("codev-multichar:getOldBucket", src, 0)
    SetPlayerRoutingBucket(src, math.random(random, 999999999999))
end)

RegisterServerCallback("codev-multichar:server:getSkin", function(_, cb, identifier)
    if Config.Framework == "qb" then
        local result = MysqlQuery("SELECT * FROM playerskins WHERE citizenid = '"..identifier.."' AND active = 1")
        
        if result[1] ~= nil then
            cb(result[1].model, result[1].skin)
        else
            cb(nil)
        end
    else
        local result = MysqlQuery("SELECT * FROM skin WHERE identifier = '"..identifier.."'")
        
        if result[1] ~= nil then
            cb(result[1])
        else
            cb(nil)
        end
    end
end)

RegisterServerCallback("codev-multichar:server:deleteCharacter", function(src, cb, identifier)
    if Config.Framework == "qb" then
        MysqlQuery("DELETE FROM players WHERE citizenid = '"..identifier.."'")

        Wait(100)

        local data = GetUserPlayers(src)
        cb(data)
    end
end)

RegisterServerCallback("codev-multichar:codeUsed", function(src, cb, code)
    local result = MysqlQuery("SELECT * FROM codev_multichar_codes WHERE code = '"..code.."'")

    if result[1] ~= nil then
        if result[1].used == 1 then
            cb(false)
        else
            TriggerClientEvent("codev-multichar:refreshSlots", src)
            MysqlQuery("UPDATE codev_multichar_codes SET used = 1 WHERE code = '"..code.."'")
            Wait(100)
            MysqlQuery("INSERT INTO codev_multichar (identifier, uses) VALUES('"..GetPlayerLicense(src).."', 1) ON DUPLICATE KEY UPDATE uses = uses + 1")
            cb(true)
        end
    else
        cb(false)
    end
end)

RegisterNetEvent('codev-multichar:qb:createCharacter', function(data, oldBucket)
    local src = source
    local newData = {}
    newData.cid = data.cid
    newData.charinfo = data
    newData.charinfo.gender = newData.charinfo.gender == "m" and 0 or 1

    if Framework.Player.Login(src, false, newData) then
        if Config.UseQbApartments and GetResourceState('qb-apartments') == 'started' then
            local randbucket = (GetPlayerPed(src) .. math.random(1,999))
            SetPlayerRoutingBucket(src, randbucket)
            Framework.Commands.Refresh(src)
            LoadHouseData(src)
            TriggerClientEvent('apartments:client:setupSpawnUI', src, newData)
            GiveStarterItems(src)
        else
            Framework.Commands.Refresh(src)
            SetPlayerRoutingBucket(src, oldBucket)
            LoadHouseData(src)
            GiveStarterItems(src)
            Config.OnLoad(src, newData, Config.SpawnCoords, true)
        end
    end
end)

RegisterNetEvent('codev-multichar:qb:loadUserData', function(cData)
    local src = source

    if Framework.Player.Login(src, cData.citizenid) then
        Framework.Commands.Refresh(src)
        LoadHouseData(src)
        Config.OnLoad(src, cData, json.decode(cData.position), false)
    end
end)

RegisterNetEvent('codev-multichar:server:sendOldBucket', function(bucket)
    local src = source
    SetPlayerRoutingBucket(src, bucket)
end)

RegisterCommand('madepurchasefromtebex', function(source, args)
    print("Made purchase from TEBEX", args[1])

    local src = source
    local inProgress = false

    if src == 0 then
        local tbxid = args[1]
        
        while inProgress do
            Wait(1000)
        end

        inProgress = true

        local result = MysqlQuery("SELECT * FROM codev_multichar_codes WHERE code = '"..tbxid.."'")

        if result[1] == nil then
            MysqlQuery("INSERT INTO codev_multichar_codes (code) VALUES ('"..tbxid.."')")
        end

        inProgress = false  
    end
end, false)