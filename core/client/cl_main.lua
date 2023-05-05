---------------------------
    -- ESX Component --
---------------------------
ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end

    ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

local tattooData = {}
local tattooListData
local tattooHashOverlay
local tattooHashCollection
---------------------------
    -- Variables --
---------------------------
Data = {
    Player = {
        Tattoo = {
            sittingScenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER",
            layingOnBack = "WORLD_HUMAN_SUNBATHE_BACK",
            layingOnStomach = "WORLD_HUMAN_SUNBATHE",
            tatgunDict = "random@shop_tattoo",
            tatgunAnim = "artist_artist_finishes_up_his_tattoo",
            receivingTattoo = false,
            receivedTattoo = false,
            currentLayingScenario = nil,
        },
    },
}
---------------------------
    -- Exports --
---------------------------
exports.srp_tracking:Player({
    options = {
        {
            event = 'tattoos:onSendPlayerToTattooChair',
            label = 'Seat the player',
            icon = 'fas fa-chair',
            job = 'tattoo',
            num = 1,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and Player(GetPlayerId(entity)).state.isReadyForTattoo 
                and not Player(GetPlayerId(entity)).state.isOnTattooChair 
                and not Player(GetPlayerId(entity)).state.isOnTattooBed
            end
        },
        {
            event = 'tattoos:onSendPlayerToTattooBed',
            label = 'Lay the player down',
            icon = 'fas fa-pen',
            job = 'tattoo',
            num = 2,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and Player(GetPlayerId(entity)).state.isReadyForTattoo 
                and not Player(GetPlayerId(entity)).state.isOnTattooChair 
                and not Player(GetPlayerId(entity)).state.isOnTattooBed
            end,
            params = {laying = true}
        },
        {
            event = 'tattoos:onSendPlayerTattooBedScenario',
            label = 'Lay on back',
            icon = 'fas fa-pen',
            job = 'tattoo',
            num = 3,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and not Player(GetPlayerId(entity)).state.isOnTattooChair 
                and Player(GetPlayerId(entity)).state.isOnTattooBed
                and not IsPedUsingScenario(entity, Data.Player.Tattoo.layingOnBack)
            end,
            params = {laying = true, scenario = Data.Player.Tattoo.layingOnBack}
        },
        {
            event = 'tattoos:onSendPlayerTattooBedScenario',
            label = 'Lay on stomach',
            icon = 'fas fa-pen',
            job = 'tattoo',
            num = 4,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and not Player(GetPlayerId(entity)).state.isOnTattooChair 
                and Player(GetPlayerId(entity)).state.isOnTattooBed
                and not IsPedUsingScenario(entity, Data.Player.Tattoo.layingOnStomach)
            end,
            params = {laying = true, scenario = Data.Player.Tattoo.layingOnStomach}
        },
        {
            event = 'tattoos:openPlayerTattooMenu',
            label = 'Give Tattoo',
            icon = 'fas fa-pen',
            job = 'tattoo',
            num = 5,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and Player(GetPlayerId(entity)).state.isOnTattooChair
                or Player(GetPlayerId(entity)).state.isUsingScenarioOnTattooBed
            end
        },
        {
            event = 'tattoos:onRemoveClothing',
            label = 'Remove Clothing',
            icon = 'fas fa-tshirt',
            job = 'tattoo',
            num = 6,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and not Player(GetPlayerId(entity)).state.isReadyForTattoo
                and not Player(GetPlayerId(entity)).state.isOnTattooChair 
                and not Player(GetPlayerId(entity)).state.isOnTattooBed
            end
        },
        {
            event = 'tattoos:onResetClothing',
            label = 'Reset Clothing',
            icon = 'fas fa-tshirt',
            job = 'tattoo',
            num = 7,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and not Player(GetPlayerId(entity)).state.isOnTattooChair 
                and not Player(GetPlayerId(entity)).state.isOnTattooBed
            end
        },
        {
            event = 'tattoos:clearTattoos',
            label = 'Clear Tattoos',
            icon = 'fas fa-pen',
            job = 'tattoo',
            num = 8,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and not Player(GetPlayerId(entity)).state.isOnTattooChair 
                and not Player(GetPlayerId(entity)).state.isOnTattooBed
            end
        },
        {
            event = 'tattoos:showTats',
            label = 'Remove Tattoo',
            icon = 'fas fa-pen',
            job = 'tattoo',
            num = 9,
            canInteract = function(entity)
                return GetEntityHealth(entity) ~= 0 and isDesignatedInterior(entity) 
                and not Player(GetPlayerId(entity)).state.isOnTattooChair 
                and not Player(GetPlayerId(entity)).state.isOnTattooBed
            end
        },
    },
    distance = 2
})
---------------------------
    -- Event Handlers --
---------------------------
AddEventHandler('skinchanger:modelLoaded', function()
    ESX.TriggerServerCallback("tattoos:getPlayerTattooData", function(tattoo_callback_data)
        if tattoo_callback_data then
            local playerPed = PlayerPedId()
            ClearPedDecorations(playerPed)
            for i = 1, #tattoo_callback_data do
                AddPedDecorationFromHashes(playerPed, tattoo_callback_data[i].collection, tattoo_callback_data[i].overlay)
            end
        end
        tattooData = tattoo_callback_data
    end)
end)

RegisterNetEvent('tattoos:giveTattoo')
AddEventHandler('tattoos:giveTattoo', function(tattooCollection, tattooOverlay, tattooName)
    AddPedDecorationFromHashes(PlayerPedId(), tattooCollection, tattooOverlay)
    ESX.TriggerServerCallback("tattoos:addTattoosDB", function(tattoo_callback)
        if tattoo_callback then
            table.insert(tattooData, {collection = tattooCollection, overlay = tattooOverlay, name = tattooName})
        end
    end, GetPlayerServerId(PlayerId()), tattooData, {collection = tattooCollection, overlay = tattooOverlay, name = tattooName})
end)

RegisterNetEvent('tattoos:givingTattoo')
AddEventHandler('tattoos:givingTattoo', function()
    local ped = PlayerPedId()
    prop = CreateObject(GetHashKey(Config.TattooGun), GetEntityCoords(ped) + GetEntityForwardVector(ped) * 0.5, true, true, true)
    Utils.loadAnimDict(Data.Player.Tattoo.tatgunDict)
    Utils.PlayAnim(ped, Data.Player.Tattoo.tatgunDict, Data.Player.Tattoo.tatgunAnim, 1.0, -1.0, 11000, 49, 0.0, 0, 0, 0)
    AttachEntity(prop, false)
    exports['progress']:StartSync({
        title = "Usage",
        text = "Applying tattoo",
        duration = 11000,
        controlDisables = {disableMovement = false, disableCarMovement = true, disableCombat = true},
    })
    DeleteObject(prop)
end)

RegisterNetEvent('tattoos:chairPlayerAnim')
AddEventHandler('tattoos:chairPlayerAnim', function(chairData, laying, scenario)
    local ped = PlayerPedId()
    local chairSetup = chairData.chairSetup
    local bedSetup = chairData.bedSetup
    Data.Player.Tattoo.receivingTattoo = true
    Data.Player.Tattoo.currentLayingScenario = scenario
    ClearPedTasksImmediately(ped)
    if not laying and Data.Player.Tattoo.receivingTattoo then
        LocalPlayer.state:set("isOnTattooChair", true, true)
        TaskStartScenarioAtPosition(ped, Data.Player.Tattoo.sittingScenario, chairSetup.x, chairSetup.y, chairSetup.z, chairSetup.w, 0, true, false)
        while LocalPlayer.state.isOnTattooChair do 
            Wait(0)
            if IsControlJustReleased(0, 73) then
                Data.Player.Tattoo.receivingTattoo = false
                LocalPlayer.state:set("isOnTattooChair", false, true)
                Data.Player.Tattoo.currentLayingScenario = nil
            end
        end
    else
        SetEntityCoords(ped, bedSetup.x, bedSetup.y, bedSetup.z)
        SetEntityHeading(ped, bedSetup.w)
        LocalPlayer.state:set("isOnTattooBed", true, true)
        if Data.Player.Tattoo.receivingTattoo and LocalPlayer.state.isOnTattooBed and Data.Player.Tattoo.currentLayingScenario ~= nil then
            TaskStartScenarioAtPosition(ped, Data.Player.Tattoo.currentLayingScenario, bedSetup.x, bedSetup.y, bedSetup.z, bedSetup.w, 0, true, true)
            LocalPlayer.state:set("isUsingScenarioOnTattooBed", true, true)
            while LocalPlayer.state.isOnTattooBed do 
                Wait(0)
                if IsControlJustReleased(0, 73) then
                    Data.Player.Tattoo.receivingTattoo = false
                    LocalPlayer.state:set("isOnTattooBed", false, true)
                    LocalPlayer.state:set("isUsingScenarioOnTattooBed", false, true)
                    Data.Player.Tattoo.currentLayingScenario = nil
                end
            end
        end
    end
end)

RegisterNetEvent('tattoos:removeClothing')
AddEventHandler('tattoos:removeClothing', function(targetId)
    local entity = GetPlayerPed(GetPlayerFromServerId(targetId))
    LocalPlayer.state:set("isReadyForTattoo", true, true)
    if GetEntityType(entity) == 1 then
        if IsPedAPlayer(entity) then 
            if GetEntityModel(entity) == GetHashKey('mp_m_freemode_01') then
                TriggerEvent('skinchanger:loadSkin', {
                    sex = 0,
                    tshirt_1 = 15,
                    tshirt_2 = 0,
                    torso_1 = 15,
                    torso_2 = 15,
                    pants_1 = 14,
                    pants_2 = 0,
                    arms = 15,
                    shoes = 34,
                    glasses_1 = 0,
                    helmet_1 = -1,
                    decals_1 = -1,
                    chain_1 = -1,
                    bproof_1 = -1,
                })
            else
                TriggerEvent('skinchanger:loadSkin', {
                    sex = 1,
                    tshirt_1 = 15,
                    tshirt_2 = 0,
                    torso_1 = 15,
                    torso_2 = 15,
                    pants_1 = 15,
                    pants_2 = 0,
                    arms = 15,
                    shoes = 35,
                    glasses_1 = 0,
                    helmet_1 = -1,
                    decals_1 = -1,
                    chain_1 = -1,
                    bproof_1 = -1,
                })
            end 
        end
    end
end)

RegisterNetEvent('tattoos:resetClothing')
AddEventHandler('tattoos:resetClothing', function(targetId)
    local ped = GetPlayerPed(GetPlayerFromServerId(targetId))
    LocalPlayer.state:set("isReadyForTattoo", false, true)
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(playerSkin)
        TriggerEvent('skinchanger:loadSkin', playerSkin)
    end)
    ClearPedDecorations(ped)
    for i = 1, #tattooData do
        AddPedDecorationFromHashes(ped, tattooData[i].collection, tattooData[i].overlay)
    end
end)

RegisterNetEvent('tattoos:resetTattoos')
AddEventHandler('tattoos:resetTattoos', function()
    ClearPedDecorations(PlayerPedId())
    tattooData = {}
end)

RegisterNetEvent('tattoos:updateTattoos')
AddEventHandler('tattoos:updateTattoos', function(tattoo)
    ClearPedDecorations(PlayerPedId())
    tattooData = tattoo
    for i = 1, #tattooData do
        AddPedDecorationFromHashes(ped, tattooData[i].collection, tattooData[i].overlay)
    end
end)

AddEventHandler('tattoos:openTattooCategoryMenu', function(tattooCategoryLists, entity)
    local categories = {}
    for i = 1, #Config.TattooList do
        tattooListData = Config.TattooList[i]
        if tattooListData.Zone == tattooCategoryLists then
            local tattooName = GetLabelText(tattooListData.Name)
            tattooHashCollection = tattooListData.Collection

            if GetEntityModel(entity) == GetHashKey("mp_m_freemode_01") then
                if tattooListData.HashNameMale ~= '' then
                    tattooHashOverlay = tattooListData.HashNameMale
                end
            else
                if tattooListData.HashNameFemale ~= '' then
                    tattooHashOverlay = tattooListData.HashNameFemale
                end
            end
            
            categories[#categories + 1] = {
                id = i,
                header = "",
                context = ("Tattoo Name | %s"):format(tattooName),
                server = false,
                event = "tattoos:openTattooMenu",
                args = {GetPlayerId(entity), tattooHashCollection, tattooHashOverlay, tattooName, entity}
            }
        end
    end
    TriggerEvent('nh-context:createMenu',  categories)
end)

AddEventHandler('tattoos:openTattooMenu', function(targetId, tattooCollection, tattooOverlay, tattooName, entity)
    TriggerServerEvent('tattoos:showTattoos', targetId, tattooCollection, tattooOverlay, tattooName)
    tattooHashCollection = nil
    tattooHashOverlay = nil
    Wait(11000)
    openTattooCategoryMenu(Config.TattooCategories, entity)
end)

AddEventHandler("tattoos:onSendPlayerToTattooChair", function(chairData)
    local entity = chairData.entity
    if ESX.PlayerData.job.name == "tattoo" then
        if GetEntityType(entity) == 1 then 
            if IsPedAPlayer(entity) then 
                local chairSetup, bedSetup, index = isDesignatedInteriorCoords(entity)
                local designatedCoordData = {
                    index = index,
                    chairSetup = chairSetup,
                }
                TriggerServerEvent('tattoos:sendPlayerChairData', GetPlayerId(entity), designatedCoordData, false, nil)
            end
        end
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)

AddEventHandler("tattoos:onSendPlayerToTattooBed", function(bedData)
    local entity = bedData.entity
    if ESX.PlayerData.job.name == "tattoo" then
        if GetEntityType(entity) == 1 then 
            if IsPedAPlayer(entity) then 
                local chairSetup, bedSetup, index = isDesignatedInteriorCoords(entity)
                local designatedCoordData = {
                    index = index,
                    bedSetup = bedSetup,
                }
                TriggerServerEvent('tattoos:sendPlayerChairData', GetPlayerId(entity), designatedCoordData, bedData.params.laying, nil)
            end
        end
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)

AddEventHandler("tattoos:onSendPlayerTattooBedScenario", function(bedData)
    local entity = bedData.entity
    if ESX.PlayerData.job.name == "tattoo" then
        if GetEntityType(entity) == 1 then 
            if IsPedAPlayer(entity) then 
                local chairSetup, bedSetup, index = isDesignatedInteriorCoords(entity)
                local designatedCoordData = {
                    index = index,
                    bedSetup = bedSetup,
                }
                TriggerServerEvent('tattoos:sendPlayerChairData', GetPlayerId(entity), designatedCoordData, bedData.params.laying, bedData.params.scenario)
            end
        end
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)

AddEventHandler("tattoos:openPlayerTattooMenu", function(tattooMenuData)
    local entity = tattooMenuData.entity
    if ESX.PlayerData.job.name == "tattoo" then
        if GetEntityType(entity) == 1 then 
            if IsPedAPlayer(entity) then 
                openTattooCategoryMenu(Config.TattooCategories, entity)
            end
        end
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)

AddEventHandler('tattoos:onRemoveClothing', function(entityData)
    local entity = entityData.entity
    if ESX.PlayerData.job.name == "tattoo" then
        if GetEntityType(entity) == 1 then 
            if IsPedAPlayer(entity) then 
                TriggerServerEvent('tattoos:requestGetNaked', GetPlayerId(entity))
            end
        end
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)

AddEventHandler('tattoos:onResetClothing', function(entityData)
    local entity = entityData.entity
    if ESX.PlayerData.job.name == "tattoo" then
        if GetEntityType(entity) == 1 then 
            if IsPedAPlayer(entity) then 
                TriggerServerEvent('tattoos:requestResetClothing', GetPlayerId(entity))
            end
        end
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)

AddEventHandler('tattoos:clearTattoos', function(entityData)
    local entity = entityData.entity
    if ESX.PlayerData.job.name == "tattoo" then 
        if GetEntityType(entity) == 1 then 
            if IsPedAPlayer(entity) then 
                TriggerServerEvent('tattoos:requestResetTattoos', GetPlayerId(entity))
            end
        end
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)

AddEventHandler('tattoos:showTats', function(entityData)
    local entity = entityData.entity
    if ESX.PlayerData.job.name == "tattoo" then 
        if GetEntityType(entity) == 1 then 
            if IsPedAPlayer(entity) then 
                ESX.TriggerServerCallback('tattoos:getTargetPlayerTattooData', function(playerTats)
                    if #playerTats > 0 then
                        checkPlayerTats(playerTats, entity)
                    else
                        SetNuiFocus(false, false)
                        exports['mythic_notify']:SendAlert("error", "Player has no tattoos")
                    end
                end, GetPlayerId(entity))
            end
        end
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)

AddEventHandler('tattoos:requestTattooRemoval', function(tatData, playerTattoos, index, target)
    if ESX.PlayerData.job.name == "tattoo" then
        local playerTattooData = playerTattoos
        for i = index, #playerTattooData do
            if playerTattooData[index].overlay == tatData.overlay then
                table.remove(playerTattooData, i)
            end
        end
        TriggerServerEvent('tattoos:requestRemoveTattoo', GetPlayerId(target), playerTattooData)
    else
        exports['mythic_notify']:SendAlert('error', 'You must be a tattoo artist employee to do this.')
    end
end)
---------------------------
    -- Threads --
---------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        ESX.TriggerServerCallback("tattoos:getPlayerTattooData", function(tattoo_callback_data)
            if tattoo_callback_data then
                local playerPed = PlayerPedId()
                ClearPedDecorations(playerPed)
                for i = 1, #tattoo_callback_data do
                    AddPedDecorationFromHashes(playerPed, tattoo_callback_data[i].collection, tattoo_callback_data[i].overlay)
                end
            end
            tattooData = tattoo_callback_data
        end)
    end
end)
---------------------------
    -- Functions --
---------------------------
openTattooCategoryMenu = function(tattooCategories, entity)
    local categories = {}
    for i = 1, #tattooCategories do
        local tattooCategoryData = tattooCategories[i]
        categories[#categories + 1] = {
            id = i,
            header = "<strong>Tattoo Categories</strong>",
            context = tattooCategoryData[2],
            server = false,
            event = "tattoos:openTattooCategoryMenu",
            args = {tattooCategoryData[1], entity}
        }
    end
    TriggerEvent('nh-context:createMenu',  categories)
end

checkPlayerTats = function(playerTattoos, entity)
    local categories = {}
    for i = 1, #playerTattoos do
        local tattooCategoryData = playerTattoos[i]
        categories[#categories + 1] = {
            id = i,
            header = "<strong>Player tattoos</strong>",
            context = ("Tattoo name: %s"):format(tattooCategoryData.name),
            server = false,
            event = "tattoos:requestTattooRemoval",
            args = {tattooCategoryData, playerTattoos, i, entity}
        }
    end
    TriggerEvent('nh-context:createMenu',  categories)
end

isDesignatedInterior = function(entity)
    if entity == 0 then return end
    for i = 1, #Config.TattooParlors do
        local tattooShops = Config.TattooParlors[i]
        local interiorId = GetInteriorAtCoords(tattooShops.bedSetup)
        if GetInteriorFromEntity(entity) == interiorId and i then
            return true
        end
    end
    return false
end

isDesignatedInteriorCoords = function(entity)
    if entity == 0 then return end
    for i = 1, #Config.TattooParlors do
        local tattooShops = Config.TattooParlors[i]
        local interiorId = GetInteriorAtCoords(tattooShops.bedSetup)
        if GetInteriorFromEntity(entity) == interiorId and i then
            return tattooShops.chairSetup, tattooShops.bedSetup, i
        end
    end
    return false
end

GetPlayerId = function(entity)
    return GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
end

AttachEntity = function(entity, isPed)
    if isPed then
        AttachEntityToEntity(PlayerPedId(), entity, GetPedBoneIndex(PlayerPedId(), 28422), 0.0, -0.1, 1.15, 0.0, 0, 180.0, false, false, true, false, 2, true)
    else
        AttachEntityToEntity(entity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.001, -0.007, 0.0, 0.0, 0.0, false, false, true, false, 2, true)
    end
end

ClearScenarioObject = function()
    ped = PlayerPedId()
    pedCoords = GetEntityCoords(ped)
    thisEntity = GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, 20.0, GetHashKey("v_ilev_ta_tatgun"), false, false, false)
    if DoesEntityExist(thisEntity) then
        ClearPedTasks(ped)
        ClearAreaOfObjects(pedCoords, 20.0, 0)
    end
end

AddEventHandler("onClientResourceStart", function(resource)
    if GetCurrentResourceName() == "tattoos" then
        ClearScenarioObject()
        LocalPlayer.state:set("isOnTattooBed", false, true)
        LocalPlayer.state:set("isOnTattooChair", false, true)
        LocalPlayer.state:set("isUsingScenarioOnTattooBed", false, true)
        LocalPlayer.state:set("isReadyForTattoo", false, true)
    end
end)
---------------------------
    -- debug / cmd shit --
---------------------------
if Config.Debug then 
    RegisterCommand('tattoomenu', function()
        closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
        local target = GetPlayerServerId(closestPlayer)
        local targetPed = GetPlayerPed(GetPlayerFromServerId(PlayerId()))
        openTattooCategoryMenu(Config.TattooCategories, targetPed)
    end)

    RegisterCommand('checktats', function()
        ESX.TriggerServerCallback("tattoos:getPlayerTattooData", function(tattoo_callback_data)
            if tattoo_callback_data then
                local targetPed = GetPlayerPed(GetPlayerFromServerId(PlayerId()))
                checkPlayerTats(tattoo_callback_data, targetPed)
            end
            tattooData = tattoo_callback_data
        end)
    end)

    RegisterCommand('tattoogun', function()
        local ped = PlayerPedId()
        prop = CreateObject(GetHashKey(Config.TattooGun), GetEntityCoords(ped) + GetEntityForwardVector(ped) * 0.5, true, true, true)
        Utils.loadAnimDict(Data.Player.Tattoo.tatgunDict)
        Utils.PlayAnim(ped, Data.Player.Tattoo.tatgunDict, Data.Player.Tattoo.tatgunAnim, 1.0, -1.0, 11000, 49, 0.0, 0, 0, 0)
        AttachEntity(prop, false)
        Wait(11000)
        DeleteObject(prop)
    end)
end