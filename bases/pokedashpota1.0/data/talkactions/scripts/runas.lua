-- !runas: fabricar, fusionar y quitar runas (lib/core/runes.lua)
function onSay(player, words, param)
	player:sendRuneWindow()
	return false
end
