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

-- ===== Arranque rapido =====
-- El motor no calcula el camino de un Pokemon recien sacado o teletransportado hasta su siguiente
-- ciclo de pensamiento (cada ~1 s): al echar a andar se quedaba parado ese segundo. Mientras tanto
-- los pasos se dan desde aqui; en cuanto el motor lo mueve por su cuenta, se deja de intervenir.
local QUICK_FOLLOW_TICK = 50
local QUICK_FOLLOW_TIME = 2000
local QUICK_FOLLOW_MAX_STEPS = 8 -- tamanio de la busqueda de camino

local quickFollowDirections = {
	DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_SOUTH, DIRECTION_WEST,
	DIRECTION_NORTHWEST, DIRECTION_NORTHEAST, DIRECTION_SOUTHWEST, DIRECTION_SOUTHEAST,
}
local quickFollowRun = {} -- por Pokemon: solo vale el ultimo arranque

local function distanceBetween(a, b)
	return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

-- primera direccion del camino mas corto para quedar al lado del duenio, o nil
function getSummonStepTowards(startPosition, masterPosition, masterTile)
	local queue = {{position = startPosition, steps = 0}}
	local visited = {[startPosition.x .. ":" .. startPosition.y] = true}
	local head = 1
	while head <= #queue do
		local current = queue[head]
		head = head + 1
		if current.steps < QUICK_FOLLOW_MAX_STEPS then
			for _, direction in ipairs(quickFollowDirections) do
				local offset = summonDirectionOffsets[direction]
				local nextPosition = Position(current.position.x + offset[1], current.position.y + offset[2], startPosition.z)
				local key = nextPosition.x .. ":" .. nextPosition.y
				if not visited[key] then
					visited[key] = true
					if isFreeForSummon(nextPosition, masterTile) then
						local firstDirection = current.firstDirection or direction
						if distanceBetween(nextPosition, masterPosition) <= 1 then
							return firstDirection
						end
						queue[#queue + 1] = {position = nextPosition, firstDirection = firstDirection, steps = current.steps + 1}
					end
				end
			end
		end
	end
	return nil
end

-- lo que tarda un paso a esa velocidad (formula del motor, sobre suelo normal)
local function summonStepTime(speed)
	local step = math.max(1, math.floor(857.36 * math.log(speed / 2 + 261.29) - 4795.01 + 0.5))
	return math.ceil(1000 * 150 / step / QUICK_FOLLOW_TICK) * QUICK_FOLLOW_TICK
end

local function quickFollowTick(playerId, summonId, run, elapsed, wait, expected)
	local player, summon = Player(playerId), Monster(summonId)
	if not player or not summon or quickFollowRun[summonId] ~= run then
		return
	end
	local position, masterPosition = summon:getPosition(), player:getPosition()
	-- ya lo ha movido el motor (u otra cosa), esta peleando o se ha quedado lejos: fin
	if position.x ~= expected.x or position.y ~= expected.y or position.z ~= expected.z
		or summon:getTarget() or isSummonFar(masterPosition, position) or elapsed >= QUICK_FOLLOW_TIME then
		quickFollowRun[summonId] = nil
		return
	end
	if wait <= 0 and distanceBetween(position, masterPosition) > 1 then
		local direction = getSummonStepTowards(position, masterPosition, Tile(masterPosition))
		if direction then
			summon:move(direction)
			expected = summon:getPosition()
			wait = summonStepTime(summon:getSpeed())
		end
	end
	addEvent(quickFollowTick, QUICK_FOLLOW_TICK, playerId, summonId, run, elapsed + QUICK_FOLLOW_TICK,
		wait - QUICK_FOLLOW_TICK, expected)
end

function startSummonQuickFollow(player, summon)
	local summonId = summon:getId()
	local run = (quickFollowRun[summonId] or 0) + 1
	quickFollowRun[summonId] = run
	if not summon:getTarget() then
		summon:setFollowCreature(player) -- que el motor lo siga ya en su siguiente ciclo
	end
	addEvent(quickFollowTick, QUICK_FOLLOW_TICK, player:getId(), summonId, run, 0, 0, summon:getPosition())
end

-- teletransporta el Pokemon detras del jugador; devuelve true si lo ha movido
function bringSummonBehind(player, summon, masterPos, fromPos)
	local destination = getSummonBehindPosition(player, masterPos, fromPos)
	if destination and (destination.x ~= 0 or destination.y ~= 0) and summon:teleportTo(destination, false) then
		destination:sendMagicEffect(CONST_ME_TELEPORT)
		startSummonQuickFollow(player, summon)
		return true
	end
	return false
end
