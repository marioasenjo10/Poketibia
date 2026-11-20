-- usar una moneda la ingresa en el banco (ya no hay monedas en el juego)
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local amount = item:getCount() * (COIN_VALUES[item:getId()] or 0)
	if amount <= 0 then
		return false
	end
	item:remove()
	player:addMoney(amount)
	player:sendTextMessage(MESSAGE_INFO_DESCR, "Se han ingresado $" .. amount .. " en tu banco.")
	return true
end
