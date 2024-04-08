fx_version 'cerulean'
game 'gta5'

description 'ps-hud'
version '2.1.1'

ox_lib 'locale'

shared_scripts {
	'@ox_lib/init.lua',
    	'@qbx_core/modules/lib.lua',
	'locales/en.lua',
	'locales/*.lua',
	'config.lua',
	'uiconfig.lua'
}

client_script 'client.lua'
server_script 'server.lua'
lua54 'yes'
use_fxv2_oal 'yes'

ui_page 'html/index.html'

files {
	'html/*',
}
