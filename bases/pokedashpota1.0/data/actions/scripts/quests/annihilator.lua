-- Annihilator (R'lyeh): de 2 a 4 jugadores, para que se juegue con algun companero (lib/core/questlever.lua)
local cfg = {
	quest = "annihilator", minPlayers = 2, on = 9826, off = 9825,
	from = {Position(1393, 1293, 11), Position(1392, 1293, 11), Position(1391, 1293, 11), Position(1390, 1293, 11)},
	to = {Position(1410, 1294, 11), Position(1409, 1294, 11), Position(1408, 1294, 11), Position(1407, 1294, 11)},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return useQuestLever(player, item, cfg)
end
