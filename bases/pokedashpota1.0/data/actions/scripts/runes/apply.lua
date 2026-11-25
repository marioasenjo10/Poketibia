-- Usar una runa (lib/core/runes.lua) sobre una Pokeball: se le aplica al Pokemon de dentro.
-- Usada sin objetivo, abre la ventana de !runas.
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if type(target) == "userdata" and target.isItem and target:isItem() and target ~= item then
		applyRuneToBall(player, item, target)
	else
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Usa la runa sobre una Pokeball con un Pokemon dentro.")
		player:sendRuneWindow()
	end
	return true
end
