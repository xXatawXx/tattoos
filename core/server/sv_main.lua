---------------------------
    -- ESX Component --
---------------------------
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
---------------------------
    -- Variables --
---------------------------

---------------------------
    -- Event Handlers --
---------------------------
RegisterServerEvent('tattoos:showTattoos')
AddEventHandler('tattoos:showTattoos', function(plyId, tattooCollection, tattooOverlay, tattooName)
    TriggerClientEvent('tattoos:givingTattoo', source)
    TriggerClientEvent('tattoos:giveTattoo', plyId, tattooCollection, tattooOverlay, tattooName)
end)
---------------------------
    -- Callbacks  --
---------------------------
ESX.RegisterServerCallback('tattoos:getPlayerTattooData', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        MySQL.Async.fetchAll("SELECT `tattoos` FROM `users` WHERE `identifier` = @identifier", {
            ["@identifier"] = xPlayer.identifier
        }, function(tattooResults)
            if tattooResults[1].tattoos then
                cb(json.decode(tattooResults[1].tattoos))
            else
                cb()
            end
        end)
    else
        cb()
    end
end)

ESX.RegisterServerCallback('tattoos:getTargetPlayerTattooData', function(source, cb, targetId)
    local src = source
    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        MySQL.Async.fetchAll("SELECT `tattoos` FROM `users` WHERE `identifier` = @identifier", {
            ["@identifier"] = xTarget.identifier
        }, function(tattooResults)
            if tattooResults[1].tattoos then
                cb(json.decode(tattooResults[1].tattoos))
            else
                cb()
            end
        end)
    else
        cb()
    end
end)

ESX.RegisterServerCallback('tattoos:addTattoosDB', function(source, cb, plyId, tattooTable, insertTattooTable)
    local xTarget = ESX.GetPlayerFromId(plyId)
    if xTarget then
        table.insert(tattooTable, insertTattooTable)
        MySQL.Async.execute("UPDATE `users` SET `tattoos` = @tattoos WHERE `identifier` = @identifier", {
            ["@tattoos"] = json.encode(tattooTable),
            ["identifier"] = xTarget.identifier
        })
        cb(true)
    end
end)

RegisterServerEvent('tattoos:sendPlayerChairData')
AddEventHandler('tattoos:sendPlayerChairData', function(targetId, chairData, laying, scenario)
    TriggerClientEvent('tattoos:chairPlayerAnim', targetId, chairData, laying, scenario)
end)

RegisterServerEvent('tattoos:requestGetNaked')
AddEventHandler('tattoos:requestGetNaked', function(targetId)
    TriggerClientEvent('tattoos:removeClothing', targetId)
end)

RegisterServerEvent('tattoos:requestResetClothing')
AddEventHandler('tattoos:requestResetClothing', function(targetId)
    TriggerClientEvent('tattoos:resetClothing', targetId)
end)

RegisterServerEvent('tattoos:requestRemoveTattoo')
AddEventHandler('tattoos:requestRemoveTattoo', function(targetId, tattoo)
    local xTarget = ESX.GetPlayerFromId(targetId)
    MySQL.Async.execute("UPDATE `users` SET `tattoos` = @tattoos WHERE `identifier` = @identifier", {
        ["@tattoos"] = json.encode(tattoo),
        ["identifier"] = xTarget.identifier
    })
    TriggerClientEvent('tattoos:updateTattoos', targetId, tattoo)
end)

RegisterServerEvent('tattoos:requestResetTattoos')
AddEventHandler('tattoos:requestResetTattoos', function(targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    MySQL.Async.execute("UPDATE `users` SET `tattoos` = @tattoos WHERE `identifier` = @identifier", {
        ["@tattoos"] = json.encode({}),
        ["identifier"] = xTarget.identifier
    })
    TriggerClientEvent('tattoos:resetTattoos', targetId)
end)