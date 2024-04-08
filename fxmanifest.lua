fx_version 'cerulean'
game 'gta5'

description 'ps-hud-qbx'
version '0.0.1'

ox_lib 'locale'

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/modules/lib.lua',
	'locales/en.lua',
	'locales/*.lua',
	'config.lua',
	'uiconfig.lua'
}

client_scripts {
	'@qbx_core/modules/playerdata.lua',
	'client.lua',
}

server_script 'server.lua'

ui_page 'html/index.html'

files {
	'html/*',
}

lua54 'yes'
use_fxv2_oal 'yes'
