Framework = Config.Framework == "esx" and exports['es_extended']:getSharedObject() or exports['qb-core']:GetCoreObject()

function PlayAnim(animation, ped)
    RequestAnimDict(animation.Dict)

    while not HasAnimDictLoaded(animation.Dict) do
        Wait(1)
    end

    TaskPlayAnim(ped, animation.Dict, animation.Name, 8.0, 8.0, -1, 1, 0, false, false, false)
end

function TriggerServerCallback(...)
    if Config.Framework == "qb" then
        Framework.Functions.TriggerCallback(...)
    else
        Framework.TriggerServerCallback(...)
    end
end