local MAX_DISTANCE = 6

local function isOutOfRange(masterPosition, summonPosition)
	return masterPosition.z ~= summonPosition.z
		or math.abs(masterPosition.x - summonPosition.x) > MAX_DISTANCE
		or math.abs(masterPosition.y - summonPosition.y) > MAX_DISTANCE
end

function onThink(interval)
	for _, player in ipairs(Game.getPlayers()) do
		local masterPosition = player:getPosition()
		local masterTile = Tile(masterPosition)

		if masterTile and not masterTile:getHouse() and not masterTile:hasFlag(TILESTATE_PROTECTIONZONE) then
			for _, summon in ipairs(player:getSummons()) do
				local summonPosition = summon:getPosition()
				if isOutOfRange(masterPosition, summonPosition) then
					local destination = player:getClosestFreePosition(masterPosition, 1, false)
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
