-- Pokedex del OTClient: "pokedexview list" abre la lista, "pokedexview 25" pide la ficha del 25
function onSay(player, words, param)
	onPokedexOpcode(player, param)
	return false
end
