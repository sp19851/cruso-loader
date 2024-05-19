local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('cruso-loader:server:Pay')
AddEventHandler('cruso-loader:server:Pay', function(inCome)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney('cash', inCome, 'cruso-loader')
end)

