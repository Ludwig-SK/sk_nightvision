fx_version 'cerulean'
game 'gta5'

author 'LudwigSK'
description 'Advanced Nightvision with Multi-Style Support'
version '1.0.0'

shared_scripts {
    'locales/en.lua',
    'locales/*.lua',
    'config.lua'
}

client_script 'client.lua'

server_script 'server.lua'

files {
    'html/sounds/*.mp3'
}

lua54 'yes'
