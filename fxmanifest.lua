fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Cruso'
description 'Primary work as a loader'
version '0.0.1'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}
dependency {
    'ox_lib'
}
