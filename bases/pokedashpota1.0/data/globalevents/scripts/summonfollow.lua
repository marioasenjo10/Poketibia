local MAX_DISTANCE = 6

local function isOutOfRange(masterPosition, summonPosition)
	return masterPosition.z ~= summonPosition.z
		or math.abs(masterPosition.x - summonPosition.x) > MAX_DISTANCE
		or math.abs(masterPosition.y - summonPosition.y) > MAX_DISTANCE
end

local function isInSameRestrictedArea(masterTile, summonTile)
	local masterHouse = masterTile:getHouse()
	local summonHouse = summonTile:getHouse()
	if masterHouse or summonHouse then
		return masterHouse == summonHouse
	end
	return masterTile:hasFlag(TILESTATE_PROTECTIONZONE)
		== summonTile:hasFlag(TILESTATE_PROTECTIONZONE)
end

function onThink(interval)
	for _, player in ipairs(Game.getPlayers()) do
		local masterPosition = player:getPosition()
		local masterTile = Tile(masterPosition)

		if masterTile then
			for _, summon in ipairs(player:getSummons()) do
				local summonPosition = summon:getPosition()
				local summonTile = Tile(summonPosition)
				if isOutOfRange(masterPosition, summonPosition)
					or summonTile and not isInSameRestrictedArea(masterTile, summonTile) then
					local destination = player:getClosestFreePosition(masterPosition, 1, false, true)
					if (destination.x ~= 0 or destination.y ~= 0)
						and summon:teleportTo(destination, false) then
						destination:sendMagicEffect(CONST_ME_TELEPORT)
					end
				end
			end
		end
	end

	return true
end
