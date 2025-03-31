-- Bảng lưu trữ xe đã kiểm tra
local checkedVehicles = {}

-- Hàm kiểm tra xe đã được xử lý chưa
local function isAlreadyChecked(vehicle)
    for _, v in ipairs(checkedVehicles) do
        if v == vehicle then
            return true
        end
    end
    return false
end

-- Chủ đề chính để quản lý khóa xe NPC
Citizen.CreateThread(function()
    while true do
        local wait = 300 -- Thời gian chờ
        local plyPed = PlayerPedId()
        local vehicle = GetVehiclePedIsTryingToEnter(plyPed)

        if DoesEntityExist(vehicle) then
            local populationType = GetEntityPopulationType(vehicle)
            -- Kiểm tra xe NPC (populationType 2, 4, 5, 6)
            if populationType == 2 or populationType == 4 or populationType == 5 or populationType == 6 then
                if not isAlreadyChecked(vehicle) then
                    local vehicleModel = GetEntityModel(vehicle)
                    local modelName = GetDisplayNameFromVehicleModel(vehicleModel):lower()

                    -- Kiểm tra danh sách loại trừ
                    local isExcluded = false
                    for _, excludedModel in ipairs(Config.ExcludedVehicles) do
                        if modelName == excludedModel then
                            isExcluded = true
                            break
                        end
                    end

                    if not isExcluded then
                        ESX.TriggerServerCallback("npc_vehicle_lock:isOwnedVehicle", function(isOwned)
                            if not isOwned then
                                -- Khóa cho người chơi, giữ mở cho NPC
                                SetVehicleDoorsLocked(vehicle, 1) -- Mở cho NPC
                                SetVehicleDoorsLockedForAllPlayers(vehicle, true) -- Khóa cho người chơi
                                table.insert(checkedVehicles, vehicle)

                                -- Quản lý NPC gần xe
                                local vehicleCoords = GetEntityCoords(vehicle)
                                local nearbyPeds = GetGamePool('CPed')
                                local associatedNPC = nil
                                for _, ped in ipairs(nearbyPeds) do
                                    if not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - vehicleCoords) < 15.0 then
                                        associatedNPC = ped
                                        break
                                    end
                                end

                                -- Nếu có NPC liên quan và xe trống
                                if associatedNPC and GetPedInVehicleSeat(vehicle, -1) == 0 then
                                    ClearPedTasks(associatedNPC) -- Xóa nhiệm vụ hiện tại
                                    TaskEnterVehicle(associatedNPC, vehicle, 10000, -1, 1.0, 1, 0)
                                end
                            end
                        end, GetVehicleNumberPlateText(vehicle))
                    else
                        table.insert(checkedVehicles, vehicle) -- Xe loại trừ vẫn được đánh dấu
                    end
                end

                -- Ngăn người chơi vào xe đã khóa
                if GetVehicleDoorsLockedForPlayer(vehicle, plyPed) then
                    ClearPedTasks(plyPed)
                end
            end
        end
        Wait(wait)
    end
end)

-- Dọn xe NPC bị bỏ rơi (loại trừ xe có chủ và xe trong danh sách loại trừ)
Citizen.CreateThread(function()
    while true do
        Wait(1000) -- Kiểm tra mỗi giây
        local playerCoords = GetEntityCoords(PlayerPedId())
        local vehicles = GetGamePool('CVehicle')

        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) and GetCanVehicleBeLocked(vehicle) and GetPedInVehicleSeat(vehicle, -1) == 0 then
                local vehicleCoords = GetEntityCoords(vehicle)
                local distance = #(playerCoords - vehicleCoords)
                if distance < 50.0 then
                    local nearbyPeds = GetGamePool('CPed')
                    local hasNearbyNPC = false
                    for _, ped in ipairs(nearbyPeds) do
                        if not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - vehicleCoords) < 15.0 then
                            hasNearbyNPC = true
                            break
                        end
                    end

                    if not hasNearbyNPC then
                        local vehicleModel = GetEntityModel(vehicle)
                        local modelName = GetDisplayNameFromVehicleModel(vehicleModel):lower()

                        -- Kiểm tra danh sách loại trừ
                        local isExcluded = false
                        for _, excludedModel in ipairs(Config.ExcludedVehicles) do
                            if modelName == excludedModel then
                                isExcluded = true
                                break
                            end
                        end

                        if not isExcluded then
                            -- Kiểm tra ownership trước khi xóa
                            ESX.TriggerServerCallback("npc_vehicle_lock:isOwnedVehicle", function(isOwned)
                                if not isOwned then
                                    -- Xóa xe sau 30 giây nếu không có NPC gần, không có chủ, và không trong danh sách loại trừ
                                    Citizen.CreateThread(function()
                                        local timeout = 0
                                        while DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == 0 and timeout < 60 do
                                            Wait(500)
                                            timeout = timeout + 1
                                        end
                                        if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == 0 then
                                            DeleteEntity(vehicle)
                                        end
                                    end)
                                end
                            end, GetVehicleNumberPlateText(vehicle))
                        end
                    end
                end
            end
        end
    end
end)