-- !medallas: ventana con las medallas del jugador y el bono que da cada una (lib/core/progression.lua)
function onSay(player, words, param)
	player:sendBadgeBonuses()
	return false
end
