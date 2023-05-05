fx_version 'adamant'
game 'gta5'

client_script 'core/client/*.lua'
server_script {'@mysql-async/lib/MYSQL.lua', 'core/server/*.lua'}
shared_scripts {'@es_extended/imports.lua','_cfgs/*.lua'}