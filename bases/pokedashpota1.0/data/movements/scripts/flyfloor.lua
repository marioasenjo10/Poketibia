-- Suelo de aire (flyFloor, lib/core/flyfloor.lua): solo lo pisa quien va volando.
-- Un jugador a pie o un salvaje que llegue desde un tejado o un monte vuelve a donde estaba.
function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player and player:isOnFly() then
		return true
	end
	if fromPosition and fromPosition.x ~= 0 and fromPosition.x ~= 65535 then
		creature:teleportTo(fromPosition, true)
	end
	return true
end
