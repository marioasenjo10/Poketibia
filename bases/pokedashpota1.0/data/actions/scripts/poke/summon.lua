-- Usar una Pokeball (desde el cinturon, la mochila o un atajo):
--  * si es la del Pokemon que tienes fuera, lo guarda;
--  * si tienes otro fuera, lo cambia por este (igual que la Pokebar);
--  * si no tienes ninguno fuera, lo saca.
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:isSummonBlocked() then return true end

	local ballKey = getBallKey(item:getId())

	if item:getTopParent() ~= player then
		if item:getSpecialAttribute("isBeingUsed") == 1 then --corrects the bug of players using balls that were not holding
			item:transform(balls[ballKey].usedOn)
			item:setSpecialAttribute("isBeingUsed", 0)
		end
		return true
	end

	if hasSummons(player) then
		local usingBall = player:getUsingBall()
		if not usingBall then return true end
		if usingBall == item then
			doRemoveSummon(player:getId(), balls[ballKey].effectRelease, false, true, balls[ballKey].missile)
			item:transform(balls[ballKey].usedOn)
			return true
		end
		-- cambio directo: guarda el que esta fuera y saca este
		if not player:canReleaseSummon(item:getSummonName(), item:getSummonOwner()) then
			return true
		end
		local usingBallKey = getBallKey(usingBall:getId())
		doRemoveSummon(player:getId(), balls[usingBallKey].effectRelease, false, true, balls[usingBallKey].missile)
		usingBall:transform(balls[usingBallKey].usedOn)
	elseif not player:canReleaseSummon(item:getSummonName(), item:getSummonOwner()) then
		return true
	end

	item:transform(balls[ballKey].usedOff)
	item:setSpecialAttribute("isBeingUsed", 1)
	doReleaseSummon(player:getId(), player:getPosition(), balls[ballKey].effectRelease, true, balls[ballKey].missile)
	return true
end
