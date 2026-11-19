-- Pokedex estilo PKA: ventana propia en el cliente (modulo game_pokedex) por el opcode 62.
-- Cliente -> servidor: "list" (lista de la dex) o "info:<numero>" (ficha de un pokemon).
-- Servidor -> cliente:
--   L|vistos|total|num[:nombre];num[:nombre];...            (sin nombre = no registrado)
--   I|num|nombre|looktype|tipo1|tipo2|stats|ataques|evoluciones|habilidades|botin|localizaciones|capturas|extra
-- Ademas, al entrar se mandan las ciudades por el opcode 63 (nombres en el mapa grande): nombre:x:y:z;...

OPCODE_POKEDEX = 62
OPCODE_TOWNS = 63

local LOCATION_RADIUS = 40   -- spawns a menos de esta distancia cuentan como la misma zona
local MAX_LOCATIONS = 15

local function clean(s)
	return (tostring(s or ""):gsub("[|;:]", " "))
end

local function readFile(path)
	local f = io.open(path, "rb")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

-- ===================== Botin (leido del XML de cada monstruo) =====================

local monsterFiles
local lootCache = {}

local function getMonsterFile(name)
	if not monsterFiles then
		monsterFiles = {}
		local content = readFile("data/monster/monsters.xml") or ""
		for tag in content:gmatch("<monster%s[^>]*>") do
			local mName = tag:match('name="([^"]+)"')
			local file = tag:match('file="([^"]+)"')
			if mName and file then
				monsterFiles[mName:lower()] = file
			end
		end
	end
	return monsterFiles[name:lower()]
end

local function formatChance(pct)
	if pct >= 100 then return "100" end
	if pct >= 10 then return string.format("%d", math.floor(pct + 0.5)) end
	if pct >= 1 then return string.format("%.1f", pct) end
	if pct >= 0.01 then return string.format("%.2f", pct) end
	return "<0.01"
end

local function getPokedexLoot(name)
	local key = name:lower()
	if lootCache[key] then
		return lootCache[key]
	end
	local list = {}
	local file = getMonsterFile(name)
	local content = file and readFile("data/monster/" .. file)
	local lootBlock = content and content:match("<loot>(.-)</loot>")
	local rate = configManager.getNumber(configKeys.RATE_LOOT) or 1
	if lootBlock then
		for attrs in lootBlock:gmatch("<item%s([^>]*)>") do
			local id = tonumber(attrs:match('id="(%d+)"'))
			local itemName = attrs:match('name="([^"]+)"')
			local itemType = ItemType(id or itemName or 0)
			if itemType and itemType:getId() ~= 0 then
				local chance = tonumber(attrs:match('chance="(%d+)"')) or 100000
				local countMax = tonumber(attrs:match('countmax="(%d+)"')) or 1
				table.insert(list, {
					clientId = itemType:getClientId(),
					name = itemType:getName(),
					count = countMax > 1 and ("1-" .. countMax) or "1",
					chance = chance * rate / 1000,
				})
			end
		end
	end
	local shinyEvo = shinyEvoByTarget and shinyEvoByTarget[name]
	if shinyEvo then
		local itemType = ItemType(shinyEvo.id)
		if itemType:getId() ~= 0 then
			table.insert(list, {
				clientId = itemType:getClientId(),
				name = itemType:getName(),
				count = "1",
				chance = shinyEvoTierChance[shinyEvo.tier] or 0,
			})
		end
	end
	table.sort(list, function(a, b) return a.chance > b.chance end)
	local parts = {}
	for i = 1, #list do
		local loot = list[i]
		parts[#parts + 1] = loot.clientId .. ":" .. clean(loot.name) .. ":" .. loot.count .. ":" .. formatChance(loot.chance)
	end
	lootCache[key] = table.concat(parts, ";")
	return lootCache[key]
end

-- ===================== Localizacion (leida de los spawns del mapa) =====================

local spawnPoints

local function loadSpawns()
	spawnPoints = {}
	local content = readFile("data/world/map-spawn.xml")
	if not content then
		print("WARNING! Pokedex: no se encontro data/world/map-spawn.xml")
		return
	end
	local cx, cy, cz = 0, 0, 7
	for tag, attrs in content:gmatch("<(%a+)%s([^>]*)>") do
		if tag == "spawn" then
			cx = tonumber(attrs:match('centerx="(%-?%d+)"')) or 0
			cy = tonumber(attrs:match('centery="(%-?%d+)"')) or 0
			cz = tonumber(attrs:match('centerz="(%-?%d+)"')) or 7
		elseif tag == "monster" then
			local mName = attrs:match('name="([^"]+)"')
			if mName then
				local key = mName:lower()
				spawnPoints[key] = spawnPoints[key] or {}
				table.insert(spawnPoints[key], {
					x = cx + (tonumber(attrs:match('x="(%-?%d+)"')) or 0),
					y = cy + (tonumber(attrs:match('y="(%-?%d+)"')) or 0),
					z = cz,
				})
			end
		end
	end
end

local function nearestTown(pos)
	local best, bestDist = "", nil
	for _, town in ipairs(Game.getTowns()) do
		local temple = town:getTemplePosition()
		local dist = math.max(math.abs(temple.x - pos.x), math.abs(temple.y - pos.y))
		if not bestDist or dist < bestDist then
			best, bestDist = town:getName(), dist
		end
	end
	return best
end

local function getPokedexLocations(name)
	if not spawnPoints then
		loadSpawns()
	end
	local points = spawnPoints[name:lower()]
	local fromBase = false
	if not points and name:sub(1, 6) == "Shiny " then
		-- los shiny salen al azar en lugar de su forma normal
		points = spawnPoints[name:sub(7):lower()]
		fromBase = points ~= nil
	end
	if not points then
		return "", false
	end
	local zones = {}
	for _, p in ipairs(points) do
		local zone
		for _, z in ipairs(zones) do
			if z.z == p.z and math.abs(z.x - p.x) <= LOCATION_RADIUS and math.abs(z.y - p.y) <= LOCATION_RADIUS then
				zone = z
				break
			end
		end
		if not zone then
			zone = {x = p.x, y = p.y, z = p.z, sumX = 0, sumY = 0, count = 0}
			table.insert(zones, zone)
		end
		zone.sumX = zone.sumX + p.x
		zone.sumY = zone.sumY + p.y
		zone.count = zone.count + 1
	end
	table.sort(zones, function(a, b) return a.count > b.count end)
	local parts = {}
	for i = 1, math.min(#zones, MAX_LOCATIONS) do
		local zone = zones[i]
		local pos = {x = math.floor(zone.sumX / zone.count + 0.5), y = math.floor(zone.sumY / zone.count + 0.5), z = zone.z}
		parts[#parts + 1] = pos.x .. ":" .. pos.y .. ":" .. pos.z .. ":" .. zone.count .. ":" .. clean(nearestTown(pos))
	end
	return table.concat(parts, ";"), fromBase
end

-- ===================== Mensajes =====================

local function dexNumbers()
	local numbers = {}
	for number in pairs(monstersTable or {}) do
		numbers[#numbers + 1] = number
	end
	table.sort(numbers)
	return numbers
end

function Player.hasDexEntry(self, number)
	return self:getStorageValue(baseStorageDex + number) ~= -1
end

function Player.sendPokedexList(self)
	local parts = {}
	local seen, total = 0, 0
	for _, number in ipairs(dexNumbers()) do
		local registered = self:hasDexEntry(number)
		local isShiny = number > 2000 and number <= 3000
		if not isShiny or registered then
			if not isShiny then
				total = total + 1
			end
			if registered then
				if not isShiny then
					seen = seen + 1
				end
				parts[#parts + 1] = number .. ":" .. clean(monstersTable[number])
			else
				parts[#parts + 1] = tostring(number)
			end
		end
	end
	self:sendExtendedOpcode(OPCODE_POKEDEX, "L|" .. seen .. "|" .. total .. "|" .. table.concat(parts, ";"))
end

function Player.sendPokedexInfo(self, number)
	local name = monstersTable and monstersTable[number]
	if not name then
		return false
	end
	if not self:hasDexEntry(number) and not self:getGroup():getAccess() then
		self:sendCancelMessage("You have not registered this pokemon in your pokedex yet.")
		return false
	end
	local monsterType = MonsterType(name)
	if not monsterType then
		return false
	end

	local stats = {
		monsterType:getMaxHealth(), monsterType:getMeleeDamage(), monsterType:getMoveMagicAttackBase(),
		monsterType:getMoveMagicDefenseBase(), monsterType:getDefense(), monsterType:getBaseSpeed(),
		monsterType:getMinLevel(), monsterType:getMaxLevel(), monsterType:getExperience(), monsterType:catchChance(),
	}

	local moves = {}
	for _, move in ipairs(monsterType:getMoveList()) do
		local info = getMoveInfo(move.name)
		moves[#moves + 1] = clean(move.name) .. ":" .. math.floor((move.speed or 0) / 1000) .. ":" .. clean(info.element)
			.. ":" .. clean(info.category) .. ":" .. clean(info.effect) .. ":" .. (moveNeedsTarget(move) and 1 or 0)
	end

	local evolutions = {}
	local added = {}
	for _, evolution in ipairs(monsterType:getEvolutionList()) do
		if evolution.name and evolution.name ~= "" then
			-- los shiny evolucionan con el objeto que suelta su evolucion (no con piedras)
			local shinyEvo = shinyEvoByTarget and shinyEvoByTarget[evolution.name]
			if shinyEvo then
				if not added[evolution.name] then
					added[evolution.name] = true
					evolutions[#evolutions + 1] = clean(evolution.name) .. ":" .. (evolution.level or 0) .. ":" .. (evolution.chance or 0)
						.. ":" .. clean(ItemType(shinyEvo.id):getName()) .. ":1"
				end
			else
				evolutions[#evolutions + 1] = clean(evolution.name) .. ":" .. (evolution.level or 0) .. ":" .. (evolution.chance or 0)
					.. ":" .. clean(evolution.itemName) .. ":" .. (evolution.count or 0)
			end
		end
	end

	local race, race2 = monsterType:getRaceName(), monsterType:getRace2Name()
	local abilities = {}
	if monsterType:isFlyable() > 0 then abilities[#abilities + 1] = "Fly" end
	if monsterType:isRideable() > 0 then abilities[#abilities + 1] = "Ride" end
	if monsterType:isSurfable() > 0 then abilities[#abilities + 1] = "Surf" end
	if monsterType:canTeleport() > 0 then abilities[#abilities + 1] = "Teleport" end
	if race == "rock" or race2 == "rock" or race == "fighting" or race2 == "fighting" then abilities[#abilities + 1] = "Rock Smash" end
	if race == "grass" or race2 == "grass" then abilities[#abilities + 1] = "Cut" end
	if race == "ground" or race2 == "ground" then abilities[#abilities + 1] = "Dig" end
	if name == "Ditto" or name == "Shiny Ditto" then abilities[#abilities + 1] = "Transform" end

	local locations, fromBase = getPokedexLocations(name)
	local dexNumber = monsterType:getNumber()
	local tries = math.max(0, self:getStorageValue(baseStorageTries + dexNumber))
	local catches = math.max(0, self:getStorageValue(baseStorageCatches + dexNumber))
	local extra = (monsterType:isLegendary() and 1 or 0) .. ":" .. (fromBase and 1 or 0)

	local message = table.concat({
		"I", number, clean(name), monsterType:getOutfit().lookType, clean(race), clean(race2 ~= "none" and race2 or ""),
		table.concat(stats, ","), table.concat(moves, ";"), table.concat(evolutions, ";"), table.concat(abilities, ","),
		getPokedexLoot(name), locations, tries .. ":" .. catches, extra,
	}, "|")
	self:sendExtendedOpcode(OPCODE_POKEDEX, message)
	return true
end

function Player.sendTownList(self)
	local parts = {}
	for _, town in ipairs(Game.getTowns()) do
		local pos = town:getTemplePosition()
		parts[#parts + 1] = clean(town:getName()) .. ":" .. pos.x .. ":" .. pos.y .. ":" .. pos.z
	end
	self:sendExtendedOpcode(OPCODE_TOWNS, table.concat(parts, ";"))
end

-- Peticiones del cliente (desde creaturescripts/scripts/extendedopcode.lua)
local lastRequest = {}

function onPokedexOpcode(player, buffer)
	local now = os.mtime and os.mtime() or os.time() * 1000
	local last = lastRequest[player:getId()] or 0
	if now - last < 150 then
		return
	end
	lastRequest[player:getId()] = now
	if buffer == "list" then
		player:sendPokedexList()
		return
	end
	local number = tonumber(buffer:match("^info:(%d+)$"))
	if number then
		player:sendPokedexInfo(number)
	end
end
