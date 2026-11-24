-- Ventanas del Profesor Oak (intro y eleccion del Pokemon inicial): data/lib/core/progression.lua
function onModalWindow(player, modalWindowId, buttonId, choiceId)
	if progressionOnModalWindow then
		progressionOnModalWindow(player, modalWindowId, buttonId, choiceId)
	end
	return true
end
