fx_version 'cerulean'
game 'gta5'

author 'Pin Cobra'
description 'Khóa tất cả phương tiện NPC với danh sách loại trừ, bỏ qua xe người chơi'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

shared_scripts {
    '@es_extended/imports.lua', -- Nếu dùng ESX
    'config.lua'
}

dependencies {
    'es_extended', -- Nếu dùng ESX
    'oxmysql'      -- Để truy vấn bảng owned_vehicles
}