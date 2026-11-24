-- Creaturescript "think" del jugador: cada segundo manda los iconos de las pokeballs y las
-- cantidades de objetos si han cambiado (las funciones estan en lib/core/pokeballicons.lua).
function onThink(creature, interval)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	player:sendPokeballIcons()
	player:sendItemCounts()
	return true
end
