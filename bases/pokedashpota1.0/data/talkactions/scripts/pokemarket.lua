-- Mercado del cliente (modules/game_pokemarket): "pokemarket open", "pokemarket buy 12 1 todo 1"...
-- La logica esta en lib/core/pokemarket.lua. No sale en el chat.
function onSay(player, words, param)
	onPokeMarketRequest(player, param)
	return false
end
