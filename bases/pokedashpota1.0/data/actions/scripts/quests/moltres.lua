-- Quest de Moltres (al norte de Ciudad Celeste): de 1 a 4 jugadores (lib/core/questlever.lua)
local cfg = {
	quest = "moltres", minPlayers = 1, on = 1946, off = 1945,
	from = {Position(1130, 743, 7), Position(1129, 743, 7), Position(1128, 743, 7), Position(1127, 743, 7)},
	to = {Position(1129, 745, 8), Position(1128, 745, 8), Position(1127, 745, 8), Position(1126, 745, 8)},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return useQuestLever(player, item, cfg)
end
