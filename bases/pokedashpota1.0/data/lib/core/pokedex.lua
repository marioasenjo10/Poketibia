-- Pokedex estilo PKA: ventana propia en el cliente (modulo game_pokedex) por el opcode 62.
-- Cliente -> servidor: "list" (lista de la dex) o "info:<numero>" (ficha de un pokemon).
-- Servidor -> cliente:
--   L|capturados|total|num:nombre:flags;...   (flags: 1 registrado, 2 capturado, 4 shiny capturado)
--   I|num|nombre|looktype|tipo1|tipo2|stats|ataques|evoluciones|habilidades|botin|localizaciones|capturas|extra
--   E|texto del error
-- Los mensajes largos se trocean (el servidor no manda textos de mas de 8192 bytes):
-- "+" delante = trozo intermedio, "=" delante = ultimo trozo.
-- Ademas, al entrar se mandan las ciudades por el opcode 63 (nombres en el mapa grande): nombre:x:y:z;...

OPCODE_POKEDEX = 62
OPCODE_TOWNS = 63

local LOCATION_RADIUS = 24   -- spawns a menos de esta distancia cuentan como la misma zona
local MAX_LOCATIONS = 40
local CHUNK_SIZE = 4000

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

-- ===================== Piedra de evolucion de los shiny =====================
-- Un shiny salvaje suelta a menudo la piedra de evolucion que lleva en su botin (fire stone,
-- heart stone...), segun su etapa (mirada en la especie normal):
--   inicial (Rattata, Weedle, Charmander) 30 % | intermedia (Charmeleon, Kakuna) 60 % | final (Charizard, Raticate) 80 %
-- (El objeto shiny especial para evolucionar shinys es otra cosa: shinyevolution.lua)
shinyStoneChanceByStage = {base = 30, middle = 60, final = 80}
evolutionStoneNames = {["leaf stone"] = true, ["water stone"] = true, ["venom stone"] = true,
	["thunder stone"] = true, ["rock stone"] = true, ["punch stone"] = true, ["fire stone"] = true,
	["ice stone"] = true, ["cocoon stone"] = true, ["crystal stone"] = true, ["darkness stone"] = true,
	["earth stone"] = true, ["enigma stone"] = true, ["heart stone"] = true, ["metal coat"] = true,
	["sun stone"] = true, ["feather stone"] = true, ["king's rock stone"] = true, ["dragon stone"] = true}
local shinyStoneCache = {}

-- devuelve nombre de la piedra y % de que la suelte (nil si no es shiny o no lleva piedra)
function getShinyStoneDrop(name)
	if not name or name:sub(1, 6):lower() ~= "shiny " then
		return nil
	end
	local key = name:lower()
	if shinyStoneCache[key] == nil then
		shinyStoneCache[key] = false
		local file = getMonsterFile(name)
		local content = file and readFile("data/monster/" .. file)
		local lootBlock = content and content:match("<loot>(.-)</loot>")
		if lootBlock then
			for attrs in lootBlock:gmatch("<item%s([^>]*)>") do
				local itemName = attrs:match('name="([^"]+)"')
				if itemName and evolutionStoneNames[itemName:lower()] then
					local stage = getPokemonEvoStage(name:sub(7))
					shinyStoneCache[key] = {stone = itemName:lower(), chance = shinyStoneChanceByStage[stage] or 0}
					break
				end
			end
		end
	end
	local entry = shinyStoneCache[key]
	if not entry then
		return nil
	end
	return entry.stone, entry.chance
end

local function formatChance(pct)
	if pct >= 100 then return "100" end
	if pct >= 10 then return string.format("%d", math.floor(pct + 0.5)) end
	if pct >= 1 then return string.format("%.1f", pct) end
	if pct >= 0.01 then return string.format("%.2f", pct) end
	return "<0.01"
end

local function clientIdOf(itemType)
	local ok, id = pcall(function() return itemType:getClientId() end)
	return ok and tonumber(id) or 0
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
				local shinyStone, shinyStoneChance = getShinyStoneDrop(name)
				if shinyStone and itemType:getName():lower() == shinyStone then
					chance = shinyStoneChance * 1000 / rate
				end
				local countMax = tonumber(attrs:match('countmax="(%d+)"')) or 1
				table.insert(list, {
					clientId = clientIdOf(itemType),
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
				clientId = clientIdOf(itemType),
				name = itemType:getName(),
				count = "1",
				chance = tonumber(shinyEvoTierChance and shinyEvoTierChance[shinyEvo.tier]) or 0,
			})
		end
	end
	table.sort(list, function(a, b) return a.chance > b.chance end)
	local parts = {}
	for i = 1, #list do
		local loot = list[i]
		parts[#parts + 1] = loot.clientId .. ":" .. clean(loot.name) .. ":" .. loot.count .. ":" .. formatChance(loot.chance)
			.. ":" .. string.format("%.4f", math.min(100, loot.chance))
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
	if not points and name:sub(1, 6) == "Shiny " then
		-- los shiny salen al azar en lugar de su forma normal: no se ensena donde
		return "", spawnPoints[name:sub(7):lower()] ~= nil, 0
	end
	local fromBase = false
	if not points then
		return "", false, 0
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
	return table.concat(parts, ";"), fromBase, #points
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

-- manda un mensaje largo en trozos (el cliente los junta)
local function sendDexMessage(player, message)
	local len = #message
	if len <= CHUNK_SIZE then
		player:sendExtendedOpcode(OPCODE_POKEDEX, message)
		return
	end
	local pos = 1
	while pos <= len do
		local piece = message:sub(pos, pos + CHUNK_SIZE - 1)
		pos = pos + CHUNK_SIZE
		player:sendExtendedOpcode(OPCODE_POKEDEX, (pos <= len and "+" or "=") .. piece)
	end
end

-- ejecuta fn protegida: si falla, el jugador ve el error (y sale en la consola del servidor)
local function runSafe(player, what, fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		local err = tostring(result)
		print("[Pokedex] Error en " .. what .. ": " .. err)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "[Pokedex] Error en " .. what .. ": " .. err)
		player:sendExtendedOpcode(OPCODE_POKEDEX, "E|" .. clean(err):sub(1, 500))
		return false
	end
	return result
end

local function isShinyName(name)
	return name:sub(1, 6):lower() == "shiny "
end

-- numero con el que se guardan intentos/capturas (el mismo que usa catch.lua)
local speciesNumbers = {}
local function getSpeciesNumber(number)
	if speciesNumbers[number] == nil then
		local name = monstersTable[number]
		local monsterType = name and MonsterType(name)
		speciesNumbers[number] = monsterType and monsterType:getNumber() or false
	end
	return speciesNumbers[number]
end

local function getCatches(player, number)
	local species = getSpeciesNumber(number)
	if not species then
		return 0
	end
	return math.max(0, player:getStorageValue(baseStorageCatches + species))
end

-- cuantos entrenadores lo han capturado (BD + jugadores conectados), cache de 60 s
local ownersCache = {}
local function countOwners(species)
	local cached = ownersCache[species]
	if cached and os.time() - cached.time < 60 then
		return cached.count
	end
	local key = math.floor(baseStorageCatches + species)
	local owners = {}
	local resultId = db.storeQuery("SELECT `player_id` FROM `player_storage` WHERE `key` = " .. key .. " AND `value` > 0")
	if resultId then
		repeat
			owners[result.getDataInt(resultId, "player_id")] = true
		until not result.next(resultId)
		result.free(resultId)
	end
	-- los conectados pueden tener capturas aun sin guardar en la BD
	for _, online in ipairs(Game.getPlayers()) do
		owners[online:getGuid()] = online:getStorageValue(key) > 0 or nil
	end
	local count = 0
	for _ in pairs(owners) do
		count = count + 1
	end
	ownersCache[species] = {time = os.time(), count = count}
	return count
end

-- ===================== Cadena evolutiva =====================

local evoParent

local function buildEvoParents()
	evoParent = {}
	for _, name in pairs(monstersTable or {}) do
		local monsterType = MonsterType(name)
		if monsterType then
			for _, evolution in ipairs(monsterType:getEvolutionList()) do
				if evolution.name and evolution.name ~= "" then
					local key = evolution.name:lower()
					local old = evoParent[key]
					-- mejor un padre del mismo tipo (shiny con shiny, normal con normal)
					if not old or (isShinyName(old.name) ~= isShinyName(evolution.name) and isShinyName(name) == isShinyName(evolution.name)) then
						evoParent[key] = {name = name}
					end
				end
			end
		end
	end
end

-- etapa de evolucion de una especie normal: "base" (no viene de nada), "middle" o "final" (no evoluciona mas)
function getPokemonEvoStage(species)
	if not monstersTable then
		buildDex()
	end
	if not evoParent then
		buildEvoParents()
	end
	local monsterType = MonsterType(species)
	local evolves = false
	for _, evolution in ipairs(monsterType and monsterType:getEvolutionList() or {}) do
		if evolution.name and evolution.name ~= "" and not isShinyName(evolution.name) then
			evolves = true
			break
		end
	end
	if not evolves then
		return "final"
	end
	return evoParent[species:lower()] and "middle" or "base"
end


local function getEvolutionChain(name)
	if not evoParent then
		buildEvoParents()
	end
	local shiny = isShinyName(name)
	local root, guard = name, 0
	while evoParent[root:lower()] and guard < 6 do
		root = evoParent[root:lower()].name
		guard = guard + 1
	end
	local out, visited = {}, {}
	local function add(stageName, depth, level, item, count, itemClientId)
		local key = stageName:lower()
		if visited[key] or #out >= 16 then
			return
		end
		visited[key] = true
		local monsterType = MonsterType(stageName)
		if not monsterType then
			return
		end
		local okName, displayName = pcall(monsterType.getName, monsterType)
		if not okName or not displayName or displayName == "" then
			displayName = stageName
		end
		out[#out + 1] = clean(displayName) .. ":" .. monsterType:getOutfit().lookType .. ":" .. (level or 0) .. ":"
			.. clean(item) .. ":" .. (count or 0) .. ":" .. monsterType:dexEntry() .. ":" .. depth .. ":" .. (itemClientId or 0)
		for _, evolution in ipairs(monsterType:getEvolutionList()) do
			if evolution.name and evolution.name ~= "" and isShinyName(evolution.name) == shiny then
				local itemName, itemCount = evolution.itemName, evolution.count
				local itemType = nil
				-- los shiny evolucionan con el objeto que suelta su evolucion (no con piedras)
				local shinyEvo = shinyEvoByTarget and shinyEvoByTarget[evolution.name]
				if shinyEvo then
					itemType = ItemType(shinyEvo.id)
					itemName, itemCount = itemType:getName(), 1
				elseif itemName and itemName ~= "" then
					local ok, byName = pcall(ItemType, itemName)
					if ok and byName and byName:getId() ~= 0 then
						itemType = byName
					end
				end
				-- id de cliente para que la pokedex dibuje el objeto (piedra, etc.)
				add(evolution.name, depth + 1, 0, itemName, itemCount, itemType and clientIdOf(itemType) or 0)
			end
		end
	end
	add(root, 0, 0, "", 0, 0)
	return table.concat(out, ";")
end

-- ===================== Nivel requerido (estilo PKA) =====================

local requiredLevelCache = {}

-- preevolucion que cuenta como etapa (misma "shinyness" y que no sea un bebe)
local function stageParent(species, speciesShiny)
	local parent = evoParent[species:lower()]
	if parent and isShinyName(parent.name) == speciesShiny and not babyPokemon[parent.name:lower():gsub("^shiny ", "")] then
		return parent.name
	end
	return nil
end

-- nivel de entrenador para usar el pokemon: el de pokemonRequiredLevels si esta;
-- si no, por etapa: base 0, etapa media 40, final de linea de 2 etapas 50, final 80 (shiny +20)
function getPokemonRequiredLevel(name)
	if not name or name == "" then
		return 0
	end
	local key = name:lower()
	if requiredLevelCache[key] then
		return requiredLevelCache[key]
	end
	if not monstersTable then
		buildDex()
	end
	if not evoParent then
		buildEvoParents()
	end
	local shiny = isShinyName(name)
	-- la etapa se mira en la especie normal (no todos los shiny tienen su cadena completa)
	local species = shiny and name:sub(7) or name
	if not MonsterType(species) then
		species = name
	end
	local monsterType = MonsterType(species)
	local level = pokemonStageLevels.final
	local override = pokemonRequiredLevels and pokemonRequiredLevels[species:lower():gsub("^shiny ", "")]
	if override then
		level = override
	elseif monsterType then
		local speciesShiny = isShinyName(species)
		local evolves = false
		for _, evolution in ipairs(monsterType:getEvolutionList()) do
			if evolution.name and evolution.name ~= "" and isShinyName(evolution.name) == speciesShiny then
				evolves = true
				break
			end
		end
		local parent = stageParent(species, speciesShiny)
		if evolves then
			level = parent and pokemonStageLevels.middle or pokemonStageLevels.base
		elseif parent and not stageParent(parent, speciesShiny) then
			level = pokemonStageLevels.twoStageFinal
		end
	end
	if shiny then
		level = level + shinyExtraLevel
	end
	requiredLevelCache[key] = level
	return level
end

-- ===================== Lista =====================

local function buildPokedexList(player)
	local parts = {}
	local caught, total = 0, 0
	for _, number in ipairs(dexNumbers()) do
		if number <= 2000 or number > 3000 then
			total = total + 1
			local flags = 0
			if player:hasDexEntry(number) then
				flags = flags + 1
			end
			if getCatches(player, number) > 0 then
				flags = flags + 2
				caught = caught + 1
			end
			if number <= 1000 and monstersTable[number + 2000] and getCatches(player, number + 2000) > 0 then
				flags = flags + 4
			end
			parts[#parts + 1] = number .. ":" .. clean(monstersTable[number]) .. ":" .. flags
		end
	end
	return "L|" .. caught .. "|" .. total .. "|" .. table.concat(parts, ";")
end

function Player.sendPokedexList(self)
	local message = runSafe(self, "la lista", buildPokedexList, self)
	if message then
		sendDexMessage(self, message)
	end
end

local function buildPokedexInfo(player, number)
	local name = monstersTable and monstersTable[number]
	if not name then
		return nil
	end
	local monsterType = MonsterType(name)
	if not monsterType then
		return nil
	end

	-- 7 y 8: nivel de entrenador necesario para usarlo (los pokemon no tienen nivel)
	local requiredLevel = getPokemonRequiredLevel(name)
	local stats = {
		monsterType:getMaxHealth(), monsterType:getMeleeDamage(), monsterType:getMoveMagicAttackBase(),
		monsterType:getMoveMagicDefenseBase(), monsterType:getDefense(), monsterType:getBaseSpeed(),
		requiredLevel, requiredLevel, monsterType:getExperience(), monsterType:catchChance(),
	}
	for i = 1, 10 do
		stats[i] = math.floor(tonumber(stats[i]) or 0)
	end

	local moves = {}
	for _, move in ipairs(monsterType:getMoveList()) do
		local info = getMoveInfo(move.name)
		moves[#moves + 1] = clean(move.name) .. ":" .. math.floor((tonumber(move.speed) or 0) / 1000) .. ":" .. clean(info.element)
			.. ":" .. clean(info.category) .. ":" .. clean(info.effect) .. ":" .. (moveNeedsTarget(move) and 1 or 0)
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

	local locations, fromBase, worldCount = getPokedexLocations(name)
	local dexNumber = monsterType:getNumber()
	local tries = math.max(0, player:getStorageValue(baseStorageTries + dexNumber))
	local catches = math.max(0, player:getStorageValue(baseStorageCatches + dexNumber))
	local shinyNumber = (number <= 1000 and monstersTable[number + 2000]) and (number + 2000) or 0
	local baseNumber = (number > 2000 and number <= 3000 and monstersTable[number - 2000]) and (number - 2000) or 0
	local extra = (monsterType:isLegendary() and 1 or 0) .. ":" .. (fromBase and 1 or 0) .. ":" .. shinyNumber .. ":" .. worldCount
		.. ":" .. (player:hasDexEntry(number) and 1 or 0) .. ":" .. baseNumber .. ":" .. countOwners(dexNumber)

	return table.concat({
		"I", number, clean(name), monsterType:getOutfit().lookType, clean(race), clean(race2 ~= "none" and race2 or ""),
		table.concat(stats, ","), table.concat(moves, ";"), getEvolutionChain(name), table.concat(abilities, ","),
		getPokedexLoot(name), locations, tries .. ":" .. catches, extra,
	}, "|")
end

local lastDexView = {}

function Player.sendPokedexInfo(self, number)
	local message = runSafe(self, "la ficha " .. tostring(number), buildPokedexInfo, self, number)
	if not message then
		return false
	end
	lastDexView[self:getGuid()] = number
	sendDexMessage(self, message)
	return true
end

-- abre la pokedex completa: la lista y la ficha indicada (o la ultima que se vio)
function Player.openPokedex(self, number)
	self:sendPokedexList()
	number = number or lastDexView[self:getGuid()]
	if not number or not monstersTable[number] then
		number = dexNumbers()[1]
	end
	if number then
		self:sendPokedexInfo(number)
	end
end

-- Ciudades descubiertas: solo te puedes teletransportar a las que ya has visitado
TOWN_DISCOVERED_STORAGE = 72000 -- + id de la ciudad
local TOWN_DISCOVER_RANGE = 35
local townCache

local function townsWithTemple()
	if not townCache then
		townCache = {}
		for _, town in ipairs(Game.getTowns()) do
			townCache[#townCache + 1] = { id = town:getId(), name = town:getName(), pos = town:getTemplePosition() }
		end
	end
	return townCache
end

function Player.hasDiscoveredTown(self, townId)
	local home = self:getTown()
	if home and home:getId() == townId then
		return true
	end
	return self:getStorageValue(TOWN_DISCOVERED_STORAGE + townId) == 1
end

-- se llama cada pocos segundos (globalevents/scripts/towndiscovery.lua) y al entrar
function Player.checkTownDiscovery(self)
	local pos = self:getPosition()
	for _, t in ipairs(townsWithTemple()) do
		if math.abs(t.pos.z - pos.z) <= 1 and math.abs(t.pos.x - pos.x) <= TOWN_DISCOVER_RANGE
				and math.abs(t.pos.y - pos.y) <= TOWN_DISCOVER_RANGE
				and self:getStorageValue(TOWN_DISCOVERED_STORAGE + t.id) ~= 1 then
			self:setStorageValue(TOWN_DISCOVERED_STORAGE + t.id, 1)
			self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Has descubierto " .. t.name .. ". Ya puedes teletransportarte aqui desde el mapa.")
			self:sendTownList()
			if progressionOnTownDiscovered then
				progressionOnTownDiscovered(self)
			end
		end
	end
end

function Player.sendTownList(self)
	local parts = {}
	for _, town in ipairs(Game.getTowns()) do
		local pos = town:getTemplePosition()
		local discovered = self:hasDiscoveredTown(town:getId()) and 1 or 0
		parts[#parts + 1] = clean(town:getName()) .. ":" .. pos.x .. ":" .. pos.y .. ":" .. pos.z .. ":" .. discovered
	end
	self:sendExtendedOpcode(OPCODE_TOWNS, table.concat(parts, ";"))
end

-- Peticiones del cliente: talkaction "pokedexview list" / "pokedexview 25"
-- (los opcodes cliente->servidor no llegan en este servidor)
local lastRequest = {}

function onPokedexOpcode(player, buffer)
	buffer = (buffer or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if buffer == "list" then
		local now = os.mtime and os.mtime() or os.clock() * 1000
		local last = lastRequest[player:getId()] or 0
		if now - last < 300 then
			return
		end
		lastRequest[player:getId()] = now
		player:openPokedex()
		return
	end
	local number = tonumber(buffer:match("^info:(%d+)$") or buffer:match("^(%d+)$"))
	if number then
		player:sendPokedexInfo(number)
	end
end
