-- Ventanas del Profesor Oak (intro y eleccion del Pokemon inicial): data/lib/core/progression.lua
function onModalWindow(player, modalWindowId, buttonId, choiceId)
	-- ventanas de !runas (lib/core/runes.lua)
	if onRuneModalAnswer and onRuneModalAnswer(player, modalWindowId, buttonId, choiceId) then
		return true
	end
	if progressionOnModalWindow then
		progressionOnModalWindow(player, modalWindowId, buttonId, choiceId)
	end
	return true
end
