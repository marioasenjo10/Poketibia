-- Salvajes pacificos: el que reaparece a la vista de un jugador no ataca a nadie y pasea por la
-- zona hasta que le atacan. (El ejecutable esta parcheado para que reaparezcan aunque haya alguien
-- mirando: tools/patch_respawn.py.) Se marca en Monster:onSpawn; despierta en Creature:onTargetCombat
-- y en monsterhealthchange.lua.

local VIEW_X, VIEW_Y = 9, 7      -- lo que ve un jugador: si aparece ahi dentro, sale pacifico
local FORGET_X, FORGET_Y = 15, 13 -- sin nadie a esta distancia vuelve a ser un salvaje normal
local TICK = 200
local WANDER_RADIUS = 3
local WANDER_MIN_TICKS, WANDER_MAX_TICKS = 6, 18 -- un paso cada 1,2 - 3,6 s

passiveWild = passiveWild or {}

local function playersAround(position, rangeX, rangeY)
	return Game.getSpectators(position, false, true, rangeX, rangeX, rangeY, rangeY)
end

function isSeenByAnyPlayer(position)
	return #playersAround(position, VIEW_X, VIEW_Y) > 0
end

local function isFreeTile(position)
	local tile = Tile(position)
	return tile and tile:getGround() and tile:getCreatureCount() == 0
			and not tile:hasFlag(TILESTATE_BLOCKSOLID) and not tile:hasFlag(TILESTATE_BLOCKPATH)
			and not tile:hasFlag(TILESTATE_IMMOVABLEBLOCKSOLID) and not tile:hasFlag(TILESTATE_FLOORCHANGE)
			and not tile:hasFlag(TILESTATE_TELEPORT) and not tile:hasFlag(TILESTATE_PROTECTIONZONE) or false
end

-- Al quitarle todos los objetivos, el motor deja al monstruo dormido (sin pensar) y addTarget no lo
-- despierta. Solo al moverse vuelve a buscar objetivos: un paso de ida y vuelta lo reactiva.
local NEIGHBOURS = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}, {-1, -1}, {1, -1}, {1, 1}, {-1, 1}}

local function reactivate(monsterId, attackerId)
	local monster = Monster(monsterId)
	if not monster or passiveWild[monsterId] then
		return
	end
	local origin = monster:getPosition()
	for _, offset in ipairs(NEIGHBOURS) do
		local destination = Position(origin.x + offset[1], origin.y + offset[2], origin.z)
		if isFreeTile(destination) then
			monster:teleportTo(destination, true)
			monster:teleportTo(origin, true)
			break
		end
	end
	local attacker = attackerId and Creature(attackerId)
	if attacker then
		monster:addTarget(attacker)
		monster:selectTarget(attacker)
	end
end

local function wander(monster, state)
	state.wait = state.wait - 1
	if state.wait > 0 then
		return
	end
	state.wait = math.random(WANDER_MIN_TICKS, WANDER_MAX_TICKS)
	local direction = math.random(DIRECTION_NORTH, DIRECTION_WEST)
	local destination = monster:getPosition()
	destination:getNextPosition(direction)
	if math.abs(destination.x - state.home.x) <= WANDER_RADIUS and math.abs(destination.y - state.home.y) <= WANDER_RADIUS then
		if isFreeTile(destination) then
			monster:move(direction)
		end
	end
end

local function passiveTick(monsterId, state)
	if passiveWild[monsterId] ~= state then
		return
	end
	local monster = Monster(monsterId)
	if not monster then
		passiveWild[monsterId] = nil
		return
	end
	local players = playersAround(monster:getPosition(), FORGET_X, FORGET_Y)
	if #players == 0 then
		passiveWild[monsterId] = nil
		reactivate(monsterId)
		return
	end
	-- que no persiga a nadie: fuera de su lista de objetivos los jugadores y sus Pokemon
	if monster:getTarget() then
		monster:setTarget(nil)
		monster:setFollowCreature(nil)
	end
	for _, player in ipairs(players) do
		monster:removeTarget(player)
		for _, summon in ipairs(player:getSummons()) do
			monster:removeTarget(summon)
		end
	end
	wander(monster, state)
	addEvent(passiveTick, TICK, monsterId, state)
end

function makeWildPassive(monster)
	local monsterId = monster:getId()
	local state = {home = monster:getPosition(), wait = math.random(WANDER_MIN_TICKS, WANDER_MAX_TICKS)}
	passiveWild[monsterId] = state
	passiveTick(monsterId, state)
end

-- en onSpawn el monstruo aun no esta en el mapa (ni tiene id): se busca justo despues
local function markSpawned(name, position)
	local newest
	for _, creature in ipairs(Game.getSpectators(position, false, false, 1, 1, 1, 1)) do
		if creature:isMonster() and not creature:getMaster() and creature:getName() == name
				and (not newest or creature:getId() > newest:getId()) then
			newest = creature
		end
	end
	if newest then
		makeWildPassive(newest)
	end
end

function makeWildPassiveOnSpawn(name, position)
	addEvent(markSpawned, 1, name, Position(position.x, position.y, position.z))
end

local function isPlayerSide(creature)
	if not creature then
		return false
	end
	if creature:isPlayer() then
		return true
	end
	local master = creature:isMonster() and creature:getMaster()
	return master and master:isPlayer() or false
end

-- true si "attacker" es un salvaje pacifico (no puede atacar). Si es el jugador o su Pokemon quien
-- ataca a un pacifico, este despierta.
function passiveWildBlocksCombat(attacker, target)
	if attacker and passiveWild[attacker:getId()] then
		return true
	end
	if target then
		wakePassiveWild(target, attacker)
	end
	return false
end

function wakePassiveWild(creature, attacker)
	local monsterId = creature:getId()
	if not passiveWild[monsterId] or not isPlayerSide(attacker) then
		return
	end
	passiveWild[monsterId] = nil
	-- un instante despues: se llega aqui en mitad del calculo del golpe y no conviene mover al monstruo ahi
	addEvent(reactivate, 1, monsterId, attacker:getId())
end
