-- Suelo de aire al volar. Antes solo habia suelo invisible (flyFloor) bajo los pies, asi que el
-- cliente no podia adelantar el paso (pre-walk) y esperaba al servidor en cada casilla: medio
-- segundo parado entre paso y paso. Ahora se mantiene un cuadrado de FLY_RING_RADIUS casillas
-- alrededor del jugador que vuela (5x5) y se quita lo que queda atras.
-- Quien no vuela no puede pisarlo (movements/scripts/flyfloor.lua).
FLY_RING_RADIUS = 2
flyRing = flyRing or {} -- [playerId] = { ["x:y:z"] = Position }

local function posKey(p)
	return p.x .. ":" .. p.y .. ":" .. p.z
end

local function removeFlyFloorAt(pos)
	local tile = Tile(pos)
	if not tile or tile:getCreatureCount() > 0 then return end
	local item = tile:getItemById(flyFloor)
	if item then item:remove() end
end

function updateFlyRing(player, center)
	local id = player:getId()
	local old = flyRing[id] or {}
	local new = {}
	for dx = -FLY_RING_RADIUS, FLY_RING_RADIUS do
		for dy = -FLY_RING_RADIUS, FLY_RING_RADIUS do
			local p = Position(center.x + dx, center.y + dy, center.z)
			local key = posKey(p)
			if old[key] then
				new[key] = old[key]
				old[key] = nil
			else
				local tile = Tile(p)
				if not tile or not tile:getGround() then
					p:createFlyFloor()
					new[key] = p
				end
			end
		end
	end
	for _, p in pairs(old) do
		removeFlyFloorAt(p)
	end
	flyRing[id] = new
end

-- quita el suelo de alrededor (no el de debajo del jugador: hay una criatura encima)
function clearFlyRing(player)
	local id = player:getId()
	for _, p in pairs(flyRing[id] or {}) do
		removeFlyFloorAt(p)
	end
	flyRing[id] = nil
end

local baseFlyUp = Player.flyUp
function Player:flyUp()
	local ok = baseFlyUp(self)
	if ok then updateFlyRing(self, self:getPosition()) end
	return ok
end

local baseFlyDown = Player.flyDown
function Player:flyDown()
	local ok = baseFlyDown(self)
	if ok then updateFlyRing(self, self:getPosition()) end
	return ok
end

local baseDeactivateFly = Player.deactivateFly
function Player:deactivateFly()
	clearFlyRing(self)
	local ok = baseDeactivateFly(self)
	if not ok and self:isOnFly() then
		updateFlyRing(self, self:getPosition())
	end
	return ok
end
