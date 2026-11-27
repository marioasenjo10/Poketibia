-- PC del cliente (modules/game_pc): "pkdpc mons 1 recent", "pkdpc swap 3 0"...
-- La logica esta en lib/core/pokepc.lua. No sale en el chat.
function onSay(player, words, param)
	onPokePcRequest(player, param)
	return false
end
