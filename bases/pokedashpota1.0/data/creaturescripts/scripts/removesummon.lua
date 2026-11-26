function onMove(creature, toPosition, fromPosition)
	local player = Player(creature:getId())
	if not hasSummons(player) then
		return true
	end

	local summon = player:getSummon()
	if summon:getSpeed() == 0 then
		summon:changeSpeed(summon:getTotalSpeed())
	end

	-- se ha quedado lejos: aparece detras del jugador (en la casilla que acaba de dejar), justo
	-- despues del paso para que esa casilla ya este libre
	if isSummonFar(toPosition, summon:getPosition()) then
		local playerId, summonId = player:getId(), summon:getId()
		local from, to = Position(fromPosition), Position(toPosition)
		addEvent(function()
			local p, s = Player(playerId), Monster(summonId)
			if p and s and s:getMaster() == p and isSummonFar(p:getPosition(), s:getPosition()) then
				local now = p:getPosition()
				local stillThere = now.x == to.x and now.y == to.y and now.z == to.z
				bringSummonBehind(p, s, now, stillThere and from or nil)
			end
		end, 0)
		return true
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
