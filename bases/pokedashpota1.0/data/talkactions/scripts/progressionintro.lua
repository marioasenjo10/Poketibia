-- Escena de la intro del cliente (modules/game_intro): "progressionintro elegir 2", "progressionintro aspecto"
function onSay(player, words, param)
	if progressionIntroCommand then
		progressionIntroCommand(player, param)
	end
	return false
end
