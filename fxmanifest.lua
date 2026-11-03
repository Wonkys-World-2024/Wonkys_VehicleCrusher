fx_version 'cerulean'
game 'gta5'
version '2.0.8'
description 'Wonky vehicle recycling crusher'
shared_scripts { '@ox_lib/init.lua', 'config.lua', 'shared.lua' }
client_scripts { 'damage_client.lua', 'client.lua', 'forklift_client.lua', 'press_client.lua', 'yard_client.lua', 'forklift_garage_client.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua', 'forklift_server.lua', 'yard_server.lua', 'forklift_garage_server.lua' }
ui_page 'web/index.html'
files { 'web/index.html', 'web/crusher.wav', 'web/warning.wav' }
dependencies { 'qbx_core', 'ox_lib', 'ox_target', 'ox_inventory', 'oxmysql', '/onesync' }

files { 'stream/wonky_crusher_parts.ytyp' }
data_file 'DLC_ITYP_REQUEST' 'stream/wonky_crusher_parts.ytyp'

files { 'stream/bzzz_scrap_items.ytyp' }
data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_scrap_items.ytyp'
