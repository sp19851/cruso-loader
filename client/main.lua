local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local pedSpawned = false
local Peds = {}
local currentPoint = nil
local Blips = {}
local Props = {}

-----Functions----
--[[local function DisplayHelpTextThisFrame(helpText)
    BeginTextCommandDisplayHelp("CELL_EMAIL_BCON")
    local s = helpText
    for i = 1, string.len(helpText) do 
        AddTextComponentSubstringPlayerName(s[i]);
    end
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function DrawTxt(x, y, width, height, scale, text, r, g, b, a, _)
    SetTextFont(1)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x - width / 2, y - height / 2 + 0.005)
end]]

local function Draw3DText(coords, str)
    local onScreen, worldX, worldY = World3dToScreen2d(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoord()
    local scale = 200 / (GetGameplayCamFov() * #(camCoords - coords))
    if onScreen then
        SetTextScale(1.0, 0.5 * scale)
        SetTextFont(4)
        SetTextColour(255, 255, 255, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextProportional(1)
        SetTextOutline()
        SetTextCentre(1)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(str)
        EndTextCommandDisplayText(worldX, worldY)
    end
end

local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end
local function loadAnimDict(animDict)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
end

local function blipCreate(pos, name, sprite, color, scale)
    local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(blip, sprite);
    SetBlipColour(blip, color);
    SetBlipScale(blip, scale);
    SetBlipDisplay(blip, 4);
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING");
    AddTextComponentSubstringPlayerName(name);
    EndTextCommandSetBlipName(blip);
    return blip;
end

local function createPed(data)
    if pedSpawned then return end
    loadModel(data.pedModel)
    local ped = CreatePed(0, GetHashKey(data.pedModel), data.pedPosition.x, data.pedPosition.y, data.pedPosition.z-1, data.pedPosition.w, false, false)
    Peds[#Peds+1] = ped
    PlaceObjectOnGroundProperly(ped)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if (data.pedScenario ~= nil)  then TaskStartScenarioInPlace(ped, data.pedScenario, -1, true) end
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                label = data.targetLabel,
                icon = data.targetIcon,
                action = function()
                    GetJob()
                end,
                canInteract = function()
                    local hours = GetClockHours()
                    if (not currentPoint and hours>= data.timeStart and  hours <= data.timeEnd) then return true else 
                        --QBCore.Functions.Notify("В данное время у меня нет для тебя работенки", "error", 7500)
                        return false 
                    end
                end,
            },
            {
                label = data.targetLabelDone,
                action = function()
                    GetIncome()
                end,
                canInteract = function()
                    if (currentPoint) then return true else 
                        return false 
                    end
                end,
            },
        },
        distance = 2.0
    })
     
end

local function Reset(full)
    if full then 
        if pedSpawned then 
            for _, v in pairs(Peds) do
                DeletePed(v)
            end
            pedSpawned = false
        end
    end
    for i, v in pairs(Blips) do
        if (i ~= "main" or full) then 
            RemoveBlip(v)
        end
    end
    for _, v in pairs(Props) do
        DeleteObject(v)
    end
    Peds = {}
    Blips = {}

    currentPoint = nil
    exports['qb-core']:HideText()
end

local function createRouteBlip(coords)
    local blip = AddBlipForCoord(coords)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)
    Blips["routeBlip"] = blip
end

local function RemoveRouteBlip()
    if (Blips["routeBlip"]) then
        RemoveBlip(Blips["routeBlip"])
        Blips["routeBlip"] = nil
    end
end

--[[local function createPutBlip()
    if (#Blips > 0 and Blips["routeBlip"] ~= nil) then
        RemoveBlip(Blips["routeBlip"])
        Blips["routeBlip"] = nil
    end
    local blip = AddBlipForCoord(currentPoint.positionTake)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)
    Blips["routePut"] = blip
end]]

function GetJob()
    local point = Config.Points[math.random(1, #Config.Points)]
    while (currentPoint ~= null and point.positionTake == currentPoint.positionTake ) do
        point = Config.Points[math.random(1, #Config.Points)]
        Citizen.Wait(500)
    end
    currentPoint = {
        positionTake = point.positionTake,
        positionPut = point.positionPut,
        count = point.count,
        counter = 0,
        done = false,
        isProp = false,
        isTake = false
    }
    createRouteBlip(currentPoint.positionTake)
    QBCore.Functions.Notify("Вы приняты. Следуйте к месту работы", "primary", 7500)
end
function GetIncome()
    if (currentPoint.done) then
        TriggerServerEvent("cruso-loader:server:Pay", Config.Init.inCome)
    else
        QBCore.Functions.Notify("Вы не выполнили условия, расчета не получите", "error", 7500)
    end
    Reset(false);
end


local function PlayAnimationWithProp(ped, animDict, animName, prop)
    if (IsEntityPlayingAnim(ped, animDict, anim, 50)) then
        ClearPedTasks(ped);
    end
    RequestAnimDict(animDict);
    while (not HasAnimDictLoaded(animDict)) do 
        Citizen.Wait(100)
    end
    --TaskPlayAnim(ped, animDict, anim, 1, 1, -1, 50, 0, false, false, false);
    TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
end

local function TakeProp()
    local modelHash = Config.Anim.prop
    loadModel(modelHash)
    local pos = GetEntityCoords(PlayerPedId(), true)
    local prop = CreateObject(GetHashKey(modelHash), pos.x, pos.y, pos.z, 1, 1, 0)
    Props[#Props] = prop;
    PlayAnimationWithProp(PlayerPedId(), Config.Anim.animDict, Config.Anim.anim, modelHash);
    AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), Config.Anim.bone), Config.Anim.propPosition.x, Config.Anim.propPosition.y, Config.Anim.propPosition.z, 0, 0, 0, true, true, false, true, 1, true);
    SetModelAsNoLongerNeeded(modelHash)
    return prop
end

local function RemoveProp()
    for _, v in pairs(Props) do
        DeleteObject(v)
    end
    StopAnimTask(ped, animDict, anim, -4);
    Props = {}
end

--Events--
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    PlayerData = QBCore.Functions.GetPlayerData()
    Wait(3000)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Reset(true)
    PlayerData = {}
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Reset(true)
end)

-----Threads----
--Init--
Citizen.CreateThread(function()
    local blip = blipCreate(Config.Init.pedPosition, Config.Init.blip.name, Config.Init.blip.srpite, Config.Init.blip.color, Config.Init.blip.scale)
    Blips["main"] = blip
    createPed(Config.Init)
    pedSpawned = true 
end) 


--Loading process control--
Citizen.CreateThread(function()
    while true do
        local sleep = 0
        if (currentPoint ~= nil) then
            if (not currentPoint.isProp and not currentPoint.done) then
                
                local pos = vector3(currentPoint.positionTake.x, currentPoint.positionTake.y, currentPoint.positionTake.z)
                local dist = #(pos - GetEntityCoords(PlayerPedId()))
                if (dist <= Config.Marker.dist) then
                    DrawMarker(1, pos.x, pos.y, pos.z - 0.98, 0, 0, 0, 0, 0, 0, Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z, 
                        Config.Marker.r, Config.Marker.g, Config.Marker.b, 255, false, true, 2, false, false, false, false)
                    if (dist <= 1) then
                        Draw3DText(pos, "[E] - взять груз")
                        if (IsControlJustReleased(0, 38)) then
                            QBCore.Functions.Progressbar('take_prop', "Берем груз", 3500, false, false, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = 'amb@prop_human_atm@male@enter',
                                anim = 'enter',
                            }, {}, {}, 
                            function()
                                currentPoint.needNotif = true
                                TakeProp()
                                RemoveRouteBlip()
                                createRouteBlip(currentPoint.positionPut)
                                currentPoint.isProp = true
                                
                            end)
                            Citizen.Wait(5000)
                        end
                    end
                end
            elseif (currentPoint.isProp and not currentPoint.done) then
                
                local pos = vector3(currentPoint.positionPut.x, currentPoint.positionPut.y, currentPoint.positionPut.z)
                local dist = #(pos - GetEntityCoords(PlayerPedId()))
                if (dist <= Config.Marker.dist) then
                    DrawMarker(1, pos.x, pos.y, pos.z - 0.98, 0, 0, 0, 0, 0, 0, Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z, 
                     Config.Marker.r, Config.Marker.g, Config.Marker.b, 255, false, true, 2, false, false, false, false)
                    if (dist <= 2 ) then
                        Draw3DText(pos, "[E] - положить груз")
                        if (IsControlJustReleased(0, 38)) then
                            RemoveProp()
                            QBCore.Functions.Progressbar('take_prop', "Кладем груз", 3500, false, false, {
                                    disableMovement = true,
                                    disableCarMovement = true,
                                    disableMouse = false,
                                    disableCombat = true,
                                }, {
                                    animDict = 'amb@prop_human_atm@male@enter',
                                    anim = 'enter',
                                }, {}, {}, 
                                function()
                                    currentPoint.isProp = false
                                    currentPoint.counter = currentPoint.counter + 1
                                    if (currentPoint.counter >= currentPoint.count) then
                                        currentPoint.done = true
                                        QBCore.Functions.Notify("Работа сделана. Вернитесь к менеджеру за расчетом", "success", 7500)
                                    else
                                        RemoveRouteBlip()
                                        createRouteBlip(currentPoint.positionTake)
                                    end
                            end)
                            Citizen.Wait(5000)
                        end
                    end
                end
            end
            sleep = 0
        end
        Citizen.Wait(sleep)
    end
end)

--Notif control--
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if (currentPoint) then
            if (currentPoint.needNotif) then
                exports['qb-core']:DrawText(currentPoint.counter.." из " ..currentPoint.count.." ходок", 'right')
            end
            sleep = 0
        end
        Citizen.Wait(sleep)
    end
end)