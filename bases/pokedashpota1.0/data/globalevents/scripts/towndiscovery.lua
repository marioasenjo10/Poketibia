-- Marca como descubierta la ciudad cuando el jugador llega cerca de su templo
-- (data/lib/core/pokedex.lua: Player.checkTownDiscovery)
function onThink(interval)
	for _, player in ipairs(Game.getPlayers()) do
		player:checkTownDiscovery()
	end
	return true
end
