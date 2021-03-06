local GUI = {}
local PlayerData = {}
local lastVehicle = nil
local lastOpen = false
GUI.Time = 0
local vehiclePlate = {}
local arrayWeight = Config.localWeight
local CloseToVehicle = false
local entityWorld = nil
local globalplate = nil
local lastChecked = 0

RegisterNetEvent("DP_Inventory_glovebox:setOwnedVehicle")
AddEventHandler("DP_Inventory_glovebox:setOwnedVehicle", function(vehicle)
	vehiclePlate = vehicle
end)

function getItemyWeight(item)
	local itemWeight = 1
	local weight = 0
	if item ~= nil then
		itemWeight = Config.DefaultWeight
		if arrayWeight[item] ~= nil then
		itemWeight = arrayWeight[item]
		end
	end
	return itemWeight
end

function VehicleInFront()
	local pos = GetEntityCoords(GetPlayerPed(-1))
	local entityWorld = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 0.1, 0.0)
	local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, result = GetRaycastResult(rayHandle)
	return result
end

function openGlovebox()
	local playerPed = GetPlayerPed(-1)
	local coords = GetEntityCoords(playerPed)
	local vehicle = VehicleInFront()
	globalplate = GetVehicleNumberPlateText(vehicle)

	if IsPedInAnyVehicle(playerPed) then
		myVeh = false
		local thisVeh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
		PlayerData = ESX.GetPlayerData()

		for i = 1, #vehiclePlate do
			local vPlate = all_trim(vehiclePlate[i].plate)
			local vFront = all_trim(GetVehicleNumberPlateText(thisVeh))
			if vPlate == vFront then
				myVeh = true
			elseif lastChecked < GetGameTimer() - 60000 then
				TriggerServerEvent("DP_Inventory_glovebox:getOwnedVehicle")
				lastChecked = GetGameTimer()
				Wait(2000)
				for i = 1, #vehiclePlate do
					local vPlate = all_trim(vehiclePlate[i].plate)
					local vFront = all_trim(GetVehicleNumberPlateText(thisVeh))
					if vPlate == vFront then
						myVeh = true
					end
				end
			end
		end

		if not Config.CheckOwnership or (Config.AllowPolice and PlayerData.job.name == Config.InventoryJob.Police) or (Config.AllowNightclub and PlayerData.job.name == Config.InventoryJob.Nightclub) or (Config.AllowMafia and PlayerData.job.name == Config.InventoryJob.Mafia) or (Config.CheckOwnership and myVeh) then
			if globalplate ~= nil or globalplate ~= "" or globalplate ~= " " then
				CloseToVehicle = true
				local vehFront = GetVehiclePedIsIn(GetPlayerPed(-1), false)
				local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
				local closecar = GetVehiclePedIsIn(GetPlayerPed(-1), false)

				if vehFront > 0 and closecar ~= nil then
					lastVehicle = vehFront
					local model = GetDisplayNameFromVehicleModel(GetEntityModel(closecar))
					local class = GetVehicleClass(vehFront)
					ESX.UI.Menu.CloseAll()
					if globalplate ~= nil or globalplate ~= "" or globalplate ~= " " then
						CloseToVehicle = true
						exports['mythic_progbar']:Progress({
							name = "openGlovebox",
							duration = 2000,
							label = _U('openglovebox'),
							useWhileDead = false,
							canCancel = true,
							controlDisables = {},
							animation = false,
							prop = {},
						}, function(status)
							if not status then
								OpenCoffresInventoryMenu(GetVehicleNumberPlateText(vehFront), Config.GloveboxSize[class], myVeh)
								if Config.CameraAnimationGlovebox == true then
									DeleteSkinCam()
									loadCamera(0, 3)
								end
							end
						end)
					end
				else
					exports['mythic_notify']:SendAlert('error', _U('no_veh_nearby'))
				end
				lastOpen = true
				GUI.Time = GetGameTimer()
			end
		else
			exports['mythic_notify']:SendAlert('success', _U('nacho_veh'))
		end
	end
end

-- Key controls
Citizen.CreateThread(
function()
	while true do
		Wait(0)
		if IsControlJustReleased(0, Config.OpenKeyGlovebox) and (GetGameTimer() - GUI.Time) > 1000 then
			openGlovebox()
			GUI.Time = GetGameTimer()
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Wait(0)
		local pos = GetEntityCoords(GetPlayerPed(-1))
		if CloseToVehicle then
			local vehicle = GetClosestVehicle(pos["x"], pos["y"], pos["z"], 2.0, 0, 70)
			if DoesEntityExist(vehicle) then
				CloseToVehicle = true
			else
				CloseToVehicle = false
				lastOpen = false
				ESX.UI.Menu.CloseAll()
				SetVehicleDoorShut(lastVehicle, 5, false)
			end
		end
	end
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(xPlayer)
	PlayerData = xPlayer
	TriggerServerEvent("DP_Inventory_glovebox:getOwnedVehicle")
	lastChecked = GetGameTimer()
end)

function OpenCoffresInventoryMenu(plate, max, myVeh)
	ESX.TriggerServerCallback("DP_Inventory_glovebox:getInventoryV", function(inventory)
	text = _U("glovebox_info", plate, (inventory.weight / 100), (max / 100))
	data = {plate = plate, max = max, myVeh = myVeh, text = text}
	TriggerEvent("DP_Inventory:openGloveboxInventory", data, inventory.blackMoney, inventory.cashMoney, inventory.items, inventory.weapons)
	end, plate)
end

function all_trim(s)
	if s then
		return s:match "^%s*(.*)":match "(.-)%s*$"
	else
		return "noTagProvided"
	end
end

function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end
