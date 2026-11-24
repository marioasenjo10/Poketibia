function onMove(creature, toPosition, fromPosition)
	local player = Player(creature:getId())
	if not hasSummons(player) then
		return true
	end

	local summon = player:getSummon()
	if summon:getSpeed() == 0 then
		summon:changeSpeed(summon:getTotalSpeed())
	end

	local toTile = Tile(toPosition)
	local summonTile = Tile(summon:getPosition())
	local masterInRestrictedArea = toTile and (toTile:getHouse() or toTile:hasFlag(TILESTATE_PROTECTIONZONE))
	local summonInRestrictedArea = summonTile and (summonTile:getHouse() or summonTile:hasFlag(TILESTATE_PROTECTIONZONE))
	if masterInRestrictedArea or summonInRestrictedArea then
		local summonPosition = summon:getPosition()
		if summonPosition.x ~= fromPosition.x or summonPosition.y ~= fromPosition.y or summonPosition.z ~= fromPosition.z then
			local destinationTile = Tile(fromPosition)
			if destinationTile and destinationTile:getCreatureCount() == 0 then
				summon:teleportTo(fromPosition, false)
			end
		end
	end

	return true
end
