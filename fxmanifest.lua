fx_version 'cerulean'
game 'gta5'

author 'LudwigSK'
description 'Advanced Nightvision with Multi-Style Support'
version '1.0.0'

shared_scripts {
    'locales/en.lua',
    'locales/*.lua',
    'shared/config.lua',
    'shared/items.lua',
    'bridge/_init.lua' -- Only the orchestrator is pre-loaded
}

client_scripts {
    'client/modules/cl_utils.lua',
    'client/modules/cl_vision.lua',
    'client/modules/cl_ui.lua',
    'client/modules/cl_gear.lua',
    'client/modules/cl_flashlight.lua',
    'client/cl_main.lua'
}

server_scripts {
    'server/sv_main.lua'
}

files {
    'html/sounds/*.mp3',
    'assets/*.png',
    'bridge/*.lua' -- All bridge modules must be available for LoadResourceFile
}

lua54 'yes'
