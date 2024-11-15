Config = {
    Framework = "qb", -- qb - esx
    Locale = "en",
    Slots = 1,
    PayedSlots =    1,
    UseQbApartments = true,
    TebexLink = "https://atiysu.tebex.io/category/2281274",
    SpawnCoords = vector3(-784.0, 338.01, 211.0), -- if you dont want to use qb-apartments
    
    ClothingMenuExport = function ()
        return TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    end,
    
    ClothingExport = function (clothingData, ped)
        return TriggerEvent('qb-clothing:client:loadPlayerClothing', clothingData, ped)
    end,

    OnLoad = function (source, playerData, lastCoords, firstSpawn)
        return TriggerClientEvent('codev-multichar:qb:spawnLastLocation', source, lastCoords, firstSpawn)
    end,

    Notify = function (msg)
        if Config.Framework == "qb" then
            Framework.Functions.Notify(msg, "error", 5000)
        else
            Framework.ShowNotification(msg)
        end
    end
}