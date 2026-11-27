-- Usar un PC abre la ventana nueva (lib/core/pokepc.lua) en vez del depot de Tibia.
-- Devolver true hace que el motor no abra su vista.
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:openPokePc(item:getPosition())
	return true
end
