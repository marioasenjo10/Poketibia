local MAX_DISTANCE = 6
local PZ_FOLLOW_MAX_STEPS = 8

local followDirections = {
	{direction = DIRECTION_NORTH, dx = 0, dy = -1},
	{direction = DIRECTION_EAST, dx = 1, dy = 0},
	{direction = DIRECTION_SOUTH, dx = 0, dy = 1},
	{direction = DIRECTION_WEST, dx = -1, dy = 0},
	{direction = DIRECTION_NORTHWEST, dx = -1, dy = -1},
	{direction = DIRECTION_NORTHEAST, dx = 1, dy = -1},
	{direction = DIRECTION_SOUTHWEST, dx = -1, dy = 1},
	{direction = DIRECTION_SOUTHEAST, dx = 1, dy = 1}
}

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

local function canWalkSummonTo(tile, masterTile)
	if not tile or not tile:getGround() or tile:getCreatureCount() > 0 then
		return false
	end
	if tile:hasFlag(TILESTATE_BLOCKSOLID)
		or tile:hasFlag(TILESTATE_BLOCKPATH)
		or tile:hasFlag(TILESTATE_IMMOVABLEBLOCKSOLID)
		or tile:hasFlag(TILESTATE_FLOORCHANGE)
		or tile:hasFlag(TILESTATE_TELEPORT) then
		return false
	end
	if tile:hasFlag(TILESTATE_PROTECTIONZONE) ~= masterTile:hasFlag(TILESTATE_PROTECTIONZONE) then
		return false
	end

	local masterHouse = masterTile:getHouse()
	local tileHouse = tile:getHouse()
	if masterHouse or tileHouse then
		return masterHouse == tileHouse
	end
	return true
end

local function walkSummonInsideProtectionZone(summon, masterPosition, masterTile)
	local startPosition = summon:getPosition()
	if math.max(math.abs(startPosition.x - masterPosition.x), math.abs(startPosition.y - masterPosition.y)) <= 1 then
		return false
	end
	local startKey = startPosition.x .. ":" .. startPosition.y
	local queue = {{position = startPosition, firstDirection = nil, steps = 0}}
	local visited = {[startKey] = true}
	local head = 1

	while head <= #queue do
		local current = queue[head]
		head = head + 1
		if current.steps < PZ_FOLLOW_MAX_STEPS then
			for _, step in ipairs(followDirections) do
				local nextPosition = Position(current.position.x + step.dx, current.position.y + step.dy, startPosition.z)
				local key = nextPosition.x .. ":" .. nextPosition.y
				if not visited[key] then
					visited[key] = true
					local tile = Tile(nextPosition)
					if canWalkSummonTo(tile, masterTile) then
						local firstDirection = current.firstDirection or step.direction
						local distance = math.max(math.abs(nextPosition.x - masterPosition.x), math.abs(nextPosition.y - masterPosition.y))
						if distance <= 1 then
							summon:move(firstDirection)
							return true
						end
						table.insert(queue, {position = nextPosition, firstDirection = firstDirection, steps = current.steps + 1})
					end
				end
			end
		end
	end
	return false
end

function onThink(interval)
	for _, player in ipairs(Game.getPlayers()) do
		local masterPosition = player:getPosition()
		local masterTile = Tile(masterPosition)

		if masterTile then
			for _, summon in ipairs(player:getSummons()) do
				local summonPosition = summon:getPosition()
				local summonTile = Tile(summonPosition)
				local masterInProtectionZone = masterTile:hasFlag(TILESTATE_PROTECTIONZONE)
				local summonInProtectionZone = summonTile and summonTile:hasFlag(TILESTATE_PROTECTIONZONE)
				if masterInProtectionZone and summonInProtectionZone
					and not isOutOfRange(masterPosition, summonPosition)
					and isInSameRestrictedArea(masterTile, summonTile) then
					walkSummonInsideProtectionZone(summon, masterPosition, masterTile)
				elseif masterInProtectionZone and isOutOfRange(masterPosition, summonPosition) then
					local destination = player:getClosestFreePosition(masterPosition, 1, false, true)
					if (destination.x ~= 0 or destination.y ~= 0)
						and summon:teleportTo(destination, false) then
						destination:sendMagicEffect(CONST_ME_TELEPORT)
					end
				elseif isOutOfRange(masterPosition, summonPosition)
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
