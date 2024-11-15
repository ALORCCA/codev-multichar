local SelectedScene = {}
local Players = {}
local Peds = {}
local oldBucket = nil
local Cam = nil
local Spawned = false
local timeOut = 4000
local uiLoaded = false
local Selected = false
local SelectedPlayerCoords = nil
local Hovered = false
local Creating = false
local CreatedPed = nil
local Deleted = false
local MySlots = 0

CreateThread(function()
    while not uiLoaded do
        Wait(10)
    end

    Wait(5000) -- Wait 5 seconds to make sure the player is fully loaded
    DisplayRadar(false) -- Hide the radar

    DoScreenFadeIn(200) -- Fade in the screen for development purposes
    Wait(200)
    
    while true do
        Wait(10)

        if NetworkIsSessionStarted() then -- Make sure the player is fully loaded
            TriggerServerEvent('codev-multichar:playerConnected')
            SendNUIMessage({ action = "open" })
            return
        end
    end
end)

RegisterNetEvent("codev-multichar:refreshSlots", function ()
    Deleted = true
    MySlots = MySlots + 1
end)

RegisterNetEvent('codev-multichar:playerConnected', function(charData, purchasedSlots)
    SetNuiFocus(true, true)

    local random = math.random(1, #Scenes)
    SelectedScene = Scenes[random]

    while SelectedScene == nil do
        Wait(1)
        SelectedScene = Scenes[math.random(1, #Scenes)]
    end

    DoScreenFadeOut(200)
    Wait(200)

    MySlots = purchasedSlots or 0

    SendNUIMessage({
        action = "sendData",
        charData = charData or {},
        slots = Config.Slots,
        payedSlots = Config.PayedSlots,
        purchasedSlots = MySlots
    })
end)

RegisterNetEvent('codev-multichar:getOldBucket', function(bucket)
    oldBucket = bucket
end)

RegisterNetEvent('codev-multichar:qb:spawnLastLocation', function(coords, firstSpawn)
    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(500)

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    
    DestroyCam(Cam, true)
    Cam = nil
    SetNuiFocus(false, false)
    DisplayRadar(true)
    RenderScriptCams(false, false, 0, false, false)

    Spawned = true
    timeOut = 20000
    Selected = false
    SelectedPlayerCoords = nil
    Hovered = false
    Creating = false
    CreatedPed = nil

    for k, v in pairs(Peds) do
        DeletePed(v.ped)
    end

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')

    if firstSpawn and not Config.UseQbApartments then
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        TriggerEvent('qb-weathersync:client:EnableSync')
        Config.ClothingMenuExport()
    end

    TriggerServerEvent("codev-multichar:server:sendOldBucket", 0)

    Wait(500)
    DoScreenFadeIn(500)
end)

RegisterNuiCallback("playIdleAnimation", function (data, cb)

    if Cam ~= nil then
        DoScreenFadeOut(500)
        DestroyCam(Cam, true)
        RenderScriptCams(false, false, 0, false, false)
    end

    Wait(500)
    Players = data
    
    if next(Peds) then
        for k, v in pairs(Peds) do
            DeletePed(v.ped)
        end
    end

    local camId = 1
    local selectedCamera = SelectedScene.Camera[camId]
    local tempId = 1
    local maxPlayers = #Players

    while selectedCamera[1].x == nil do
        Wait(1)
        SelectedScene = Scenes[math.random(1, #Scenes)]
        selectedCamera = SelectedScene.Camera[camId]
    end

    Wait(500)

    for k, v in pairs(Players) do
        Wait(300)
        local ped = nil
        
        local license = Config.Framework == "qb" and v.citizenid or v.identifier

        if tempId <= maxPlayers then
            local charPos = SelectedScene.Characters[tempId]
            tempId = tempId + 1

            TriggerServerCallback('codev-multichar:server:getSkin', function(model, data)
                model = model ~= nil and tonumber(model) or false

                if model ~= nil then
                    CreateThread(function()
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(0)
                        end
                        ped = CreatePed(2, model, charPos.Coords.x, charPos.Coords.y, charPos.Coords.z - 1, charPos.Coords.w, false, true)
                        SetPedComponentVariation(ped, 0, 0, 0, 2)
                        FreezeEntityPosition(ped, false)
                        SetEntityInvincible(ped, true)
                        PlaceObjectOnGroundProperly(ped)
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        data = json.decode(data)
                        Config.ClothingExport(data, ped)

                        PlayAnim(charPos.Animation, ped)
                        table.insert(Peds, {ped = ped, license = license})
                    end)
                else
                    CreateThread(function()
                        local randommodels = {
                            "mp_m_freemode_01",
                        }
                        model = joaat(randommodels[math.random(1, #randommodels)])
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(0)
                        end
                        ped = CreatePed(2, model, charPos.Coords.x, charPos.Coords.y, charPos.Coords.z - 1, charPos.Coords.w, false, true)
                        SetPedComponentVariation(ped, 0, 0, 0, 2)
                        FreezeEntityPosition(ped, false)
                        SetEntityInvincible(ped, true)
                        PlaceObjectOnGroundProperly(ped)
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        
                        PlayAnim(charPos.Animation, ped)
                        table.insert(Peds, {ped = ped, license = license})
                    end)
                end

                cb("ok")
            end, license)
        end
    end
    
    local pped = PlayerPedId()

    while pped == nil or pped == -1 or pped == 0 do
        Wait(1)
        pped = PlayerPedId()
    end

    SetEntityHeading(pped, selectedCamera[1].w)
    SetGameplayCamRelativeHeading(0.0)

    SetEntityCoords(pped, selectedCamera[1].x, selectedCamera[1].y, selectedCamera[1].z , false, false, false, false)
    Wait(20)
    local offsetCoords = GetOffsetFromEntityInWorldCoords(pped, 0.0, 2.0, -2.0)
    Wait(20)
    SetEntityCoords(pped, offsetCoords.x, offsetCoords.y, offsetCoords.z, false, false, false, false)
    SetEntityInvincible(pped, true)
    FreezeEntityPosition(pped, true)
    SetEntityVisible(pped, false, false)

    Wait(500)

    Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    PointCamAtCoord(Cam, selectedCamera[3].x, selectedCamera[3].y, selectedCamera[3].z)
    SetCamActive(Cam, true)
    SetCamFov(Cam, 45.0)
    SetCamCoord(Cam, selectedCamera[2].x, selectedCamera[2].y, selectedCamera[2].z)
    RenderScriptCams(true, true, 50000, true, false)
    cb("ok")

    DoScreenFadeIn(1000)
    Wait(1000)
    
    while true do
        Wait(1)

        if Spawned or Deleted then
            Deleted = false
            return
        end

        if not Creating and not Spawned then
            timeOut = timeOut - 1

            if timeOut <= 0 then
                camId = camId + 1
                selectedCamera = SelectedScene.Camera[camId]
                DoScreenFadeOut(1000)
                Wait(1000)
                
                if selectedCamera == nil then
                    camId = 1
                    selectedCamera = SelectedScene.Camera[camId]
                end
    
                DestroyCam(Cam, true)
                RenderScriptCams(false, false, 0, false, false)
    
                SetEntityHeading(pped, selectedCamera[1].w)
                SetGameplayCamRelativeHeading(0.0)
    
                SetEntityCoords(pped, selectedCamera[1].x, selectedCamera[1].y, selectedCamera[1].z, false, false, false, false)
                Wait(20)
                local offsetCoords = GetOffsetFromEntityInWorldCoords(pped, 0.0, 2.0, -2.0)
                Wait(20)
                SetEntityCoords(pped, offsetCoords.x, offsetCoords.y, offsetCoords.z, false, false, false, false)
    
                Wait(10)
    
                Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                PointCamAtCoord(Cam, selectedCamera[3].x, selectedCamera[3].y, selectedCamera[3].z)
                SetCamActive(Cam, true)
                SetCamFov(Cam, 45.0)
                SetCamCoord(Cam, selectedCamera[2].x, selectedCamera[2].y, selectedCamera[2].z)
                RenderScriptCams(true, true, 50000, true, true)
                
                Wait(1000)
                DoScreenFadeIn(1000)
                timeOut = 4000
                Selected = false
            end
        end
    end
end)

RegisterNuiCallback("playerSelected", function (license)
    local pedCoords = nil
    local selectedCoord = nil

    for k, v in pairs(Peds) do
        if v.license == license then
            Selected = true
            timeOut = 4000
            selectedCoord = GetOffsetFromEntityInWorldCoords(v.ped, 0.0, 3.0, 0.5)
            pedCoords = GetEntityCoords(v.ped)
        end
    end

    while not selectedCoord or not pedCoords do
        Wait(1)
    end

    DoScreenFadeOut(500)
    Wait(500)
    DestroyCam(Cam, true)

    Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    PointCamAtCoord(Cam, pedCoords.x, pedCoords.y, pedCoords.z)
    SetCamActive(Cam, true)
    SetCamFov(Cam, 45.0)
    SetCamCoord(Cam, selectedCoord.x, selectedCoord.y, selectedCoord.z)
    RenderScriptCams(true, false, 1, true, true)

    DoScreenFadeIn(500)
end)

RegisterNUICallback('selectCharacter', function(license)
    Spawned = true
    DoScreenFadeOut(500)
    Wait(500)
    DestroyCam(Cam, true)
    Cam = nil
    local cData = nil

    for _, a in pairs(Players) do
        if Config.Framework == "qb" then
            if a.citizenid == license then
                cData = a
            end
        else
            if a.identifier == license then
                cData = a
            end
        end
    end

    if Config.Framework == "qb" then
        TriggerServerEvent('codev-multichar:qb:loadUserData', cData)
    else
        TriggerServerEvent('codev-multichar:esx:loadUserData', cData)
    end

    for k, v in pairs(Peds) do
        DeletePed(v.ped)
    end
end)

RegisterNuiCallback("playHoverAnimation", function (license)
    if not Selected then
        for k, v in pairs(Peds) do
            if v.license == license then
                Hovered = true
                SelectedPlayerCoords = GetEntityCoords(v.ped)
            end
        end
    end
end)

RegisterNuiCallback("hoverOut", function ()
    Hovered = false
    SelectedPlayerCoords = nil
end)

RegisterNuiCallback("deleteChar", function (license, cb)
    Deleted = true
    timeOut = 4000

    TriggerServerCallback('codev-multichar:server:deleteCharacter', function (response)
        print(response.purchasedSlots)
        MySlots = response.purchasedSlots or 0

        cb({
            charData = response.charData or {},
            slots = Config.Slots,
            payedSlots = Config.PayedSlots,
            purchasedSlots = MySlots
        })
    end, license)
end)

RegisterNuiCallback("playCreateAnimation", function (data)
    timeOut = 4000
    Selected = false
    Creating = true
    
    Wait(100)
    DoScreenFadeOut(500)
    Wait(500)
    DestroyCam(Cam, true)
    Cam = nil
    
    local hash = GetHashKey("mp_m_freemode_01")

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end

    CreatedPed = CreatePed(2, hash, SelectedScene.CreationCoord.x, SelectedScene.CreationCoord.y, SelectedScene.CreationCoord.z - 1, SelectedScene.CreationCoord.w, false, true)
    FreezeEntityPosition(CreatedPed, true)
    SetEntityInvincible(CreatedPed, true)
    local pedOffset = GetOffsetFromEntityInWorldCoords(CreatedPed, -0.2, 1.5, 0.5)

    Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    PointCamAtCoord(Cam, SelectedScene.CreationCoord.x + -0.2, SelectedScene.CreationCoord.y, SelectedScene.CreationCoord.z + 0.5)
    SetCamActive(Cam, true)
    SetCamFov(Cam, 45.0)
    SetCamCoord(Cam, pedOffset.x, pedOffset.y, pedOffset.z)
    RenderScriptCams(true, false, 1, true, true)

    Wait(500)
    DoScreenFadeIn(500)
end)

RegisterNuiCallback("loaded", function (data)
    uiLoaded = true
end)

RegisterNuiCallback("stopCreateAnim", function ()
    timeOut = 0
    Creating = false
    Wait(1000)
    DeletePed(CreatedPed)
end)

RegisterNuiCallback("notify", function (msg)
    Config.Notify(msg)
end)

RegisterNuiCallback("genderUpdate", function (gender)
    DeleteEntity(CreatedPed)

    local hash = gender == "m" and "mp_m_freemode_01" or "mp_f_freemode_01"

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end

    CreatedPed = CreatePed(2, GetHashKey(hash), SelectedScene.CreationCoord.x, SelectedScene.CreationCoord.y, SelectedScene.CreationCoord.z - 1, SelectedScene.CreationCoord.w, false, true)
    FreezeEntityPosition(CreatedPed, true)
    SetEntityInvincible(CreatedPed, true)
end)

RegisterNuiCallback("createCharacter", function (data, cb)
    if Config.Framework == "qb" then
        TriggerServerEvent('codev-multichar:qb:createCharacter', data, oldBucket)
    else
        TriggerServerEvent('codev-multichar:esx:createCharacter', data, oldBucket)
    end
    
    DestroyCam(Cam, true)
    Cam = nil
    SetNuiFocus(false, false)
    DisplayRadar(true)
    RenderScriptCams(false, false, 0, false, false)

    Spawned = true
    timeOut = 20000
    Selected = false
    SelectedPlayerCoords = nil
    Hovered = false
    Creating = false
    CreatedPed = nil

    for k, v in pairs(Peds) do
        DeletePed(v.ped)
    end

    cb("ok")
end)

RegisterNuiCallback("submitCode", function (code, cb)
    TriggerServerCallback("codev-multichar:codeUsed", function (response)
        if response then
            cb({
                charData = Players,
                slots = Config.Slots,
                payedSlots = Config.PayedSlots,
                tebexLink = Config.TebexLink,
                purchasedSlots = MySlots
            })
        else
            cb(nil)
        end
    end, code)
end)

CreateThread(function ()
    while true do
        Wait(1)
        if Hovered then
            DrawMarker(2, SelectedPlayerCoords.x, SelectedPlayerCoords.y, SelectedPlayerCoords.z + 1.0, 0, 0, 0, 0, 180.0, 0, 0.3, 0.5, 0.5, 255, 255, 255, 255, false, false, false, true)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DeletePed(CreatedPed)

        for k, v in pairs(Peds) do
            DeletePed(v.ped)
        end
    end
end)