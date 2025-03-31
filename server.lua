ESX = exports['es_extended']:getSharedObject()

ESX.RegisterServerCallback('npc_vehicle_lock:isOwnedVehicle', function(source, cb, plate)
    exports.oxmysql:scalar("SELECT owner FROM owned_vehicles WHERE plate = ?", {plate}, function(owner)
        if owner then
            cb(true) -- Xe có chủ sở hữu
        else
            cb(false) -- Xe không có chủ (NPC)
        end
    end)
end)