function Creature.getClosestFreePosition(self, position, maxRadius, mustBeReachable, allowHouseAndProtectionZone)
	maxRadius = maxRadius or 1
	local originTile = allowHouseAndProtectionZone and Tile(position)
	local originHouse = originTile and originTile:getHouse()
	local originInProtectionZone = originTile and originTile:hasFlag(TILESTATE_PROTECTIONZONE)

	-- backward compatability (extended)
	if maxRadius == true then
		maxRadius = 2
	end

	local checkPosition = Position(position)
	for radius = 0, maxRadius do
		checkPosition.x = checkPosition.x - math.min(1, radius)
		checkPosition.y = checkPosition.y + math.min(1, radius)

		local total = math.max(1, radius * 8)
		for i = 1, total do
			if radius > 0 then
				local direction = math.floor((i - 1) / (radius * 2))
				checkPosition:getNextPosition(direction)
			end

			local tile = Tile(checkPosition)
			local tileHouse = tile and tile:getHouse()
			local tileInProtectionZone = tile and tile:hasFlag(TILESTATE_PROTECTIONZONE)
			local allowedArea = not tileHouse and not tileInProtectionZone
			if allowHouseAndProtectionZone then
				if originHouse then
					allowedArea = tileHouse == originHouse
				else
					allowedArea = not tileHouse and tileInProtectionZone == originInProtectionZone
				end
			end
			if tile and tile:getCreatureCount() == 0 and tile:getGround() and tile:getGround():getId() ~= flyFloor and not tile:hasProperty(CONST_PROP_IMMOVABLEBLOCKSOLID) and not tile:hasProperty(CONST_PROP_BLOCKPATH) and allowedArea and not tile:hasFlag(TILESTATE_FLOORCHANGE) and
				(not mustBeReachable or self:getPathTo(checkPosition)) then --pota
				return checkPosition
			end
		end
	end
	return Position()
end

function Creature:addSummon(monster) --pota tfs 1.3
	local summon = Monster(monster)
	if not summon then
		return false
	end

	summon:setTarget(nil)
	summon:setFollowCreature(nil)
	summon:setDropLoot(false)
--	summon:setSkillLoss(false)
	summon:setMaster(self)

	return true
end

function Creature:removeSummon(monster) --pota tfs 1.3
	local summon = Monster(monster)
	if not summon or summon:getMaster() ~= self then
		return false
	end

	summon:setTarget(nil)
	summon:setFollowCreature(nil)
	summon:setDropLoot(true)
--	summon:setSkillLoss(true)
	summon:setMaster(nil)

	return true
end

function Creature.getPlayer(self)
	return self:isPlayer() and self or nil
end

function Creature.isItem(self)
	return false
end

function Creature.isMonster(self)
	return false
end

function Creature.isNpc(self)
	return false
end

function Creature.isPlayer(self)
	return false
end

function Creature.isTile(self)
	return false
end

-- ===== Traer el Pokemon junto a su dueno cuando se queda lejos =====
-- Siempre detras del jugador segun hacia donde anda: si va a la izquierda aparece a su derecha,
-- si sube aparece abajo... Primero la casilla de la que acaba de salir (fromPosition), luego las
-- de alrededor de detras hacia delante. (getClosestFreePosition empezaba por la izquierda y lo
-- ponia delante al andar hacia la izquierda o hacia arriba.)
SUMMON_FAR_X = 6
SUMMON_FAR_Y = 4

function isSummonFar(masterPos, summonPos)
	return masterPos.z ~= summonPos.z
		or math.abs(masterPos.x - summonPos.x) > SUMMON_FAR_X
		or math.abs(masterPos.y - summonPos.y) > SUMMON_FAR_Y
end

local summonDirectionOffsets = {
	[DIRECTION_NORTH] = {0, -1}, [DIRECTION_EAST] = {1, 0}, [DIRECTION_SOUTH] = {0, 1}, [DIRECTION_WEST] = {-1, 0},
	[DIRECTION_SOUTHWEST] = {-1, 1}, [DIRECTION_SOUTHEAST] = {1, 1}, [DIRECTION_NORTHWEST] = {-1, -1}, [DIRECTION_NORTHEAST] = {1, -1},
}

local function isFreeForSummon(position, masterTile)
	local tile = Tile(position)
	if not tile or not tile:getGround() or tile:getGround():getId() == flyFloor or tile:getCreatureCount() > 0 then
		return false
	end
	if tile:hasFlag(TILESTATE_BLOCKSOLID) or tile:hasFlag(TILESTATE_BLOCKPATH)
		or tile:hasFlag(TILESTATE_IMMOVABLEBLOCKSOLID) or tile:hasFlag(TILESTATE_FLOORCHANGE)
		or tile:hasFlag(TILESTATE_TELEPORT) then
		return false
	end
	local masterHouse = masterTile and masterTile:getHouse()
	local tileHouse = tile:getHouse()
	if masterHouse or tileHouse then
		return masterHouse == tileHouse
	end
	return true
end

-- masterPos: donde esta (o acaba de llegar) el jugador; fromPos (opcional): de donde viene
function getSummonBehindPosition(player, masterPos, fromPos)
	masterPos = masterPos or player:getPosition()
	local masterTile = Tile(masterPos)
	local fx, fy
	if fromPos and fromPos.z == masterPos.z and (fromPos.x ~= masterPos.x or fromPos.y ~= masterPos.y) then
		fx = (masterPos.x > fromPos.x and 1) or (masterPos.x < fromPos.x and -1) or 0
		fy = (masterPos.y > fromPos.y and 1) or (masterPos.y < fromPos.y and -1) or 0
	else
		local offset = summonDirectionOffsets[player:getDirection()] or {0, 1}
		fx, fy = offset[1], offset[2]
	end

	local candidates = {}
	if fromPos and fromPos.z == masterPos.z and math.abs(fromPos.x - masterPos.x) <= 1 and math.abs(fromPos.y - masterPos.y) <= 1 then
		candidates[#candidates + 1] = {score = -100, pos = Position(fromPos.x, fromPos.y, fromPos.z)}
	end
	-- negativo = detras, 0 = a los lados, positivo = delante; a igualdad, mejor en recto que en diagonal
	for dx = -1, 1 do
		for dy = -1, 1 do
			if dx ~= 0 or dy ~= 0 then
				candidates[#candidates + 1] = {score = (dx * fx + dy * fy) * 4 + math.abs(dx) + math.abs(dy),
					pos = Position(masterPos.x + dx, masterPos.y + dy, masterPos.z)}
			end
		end
	end
	table.sort(candidates, function(a, b) return a.score < b.score end)
	for _, candidate in ipairs(candidates) do
		if isFreeForSummon(candidate.pos, masterTile) then
			return candidate.pos
		end
	end
	return Creature.getClosestFreePosition(player, masterPos, 2, false, true)
end

-- teletransporta el Pokemon detras del jugador; devuelve true si lo ha movido
function bringSummonBehind(player, summon, masterPos, fromPos)
	local destination = getSummonBehindPosition(player, masterPos, fromPos)
	if destination and (destination.x ~= 0 or destination.y ~= 0) and summon:teleportTo(destination, false) then
		destination:sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
	return false
end
