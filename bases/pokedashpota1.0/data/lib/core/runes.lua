-- Runas: el equivalente a los held items de PokeAlliance. Se aplican a una Pokeball (hasta 3, de
-- tipos distintos) y dan un bonus al Pokemon que lleva dentro segun su tier.
--
-- * Objetos: se usan runas de Tibia que el juego no usaba (desregistradas en spells.xml y
--   renombradas en items.xml). El tier va en el atributo especial "runeTier".
-- * Fabricar (!runas): 1 runa en blanco + 10 fragmentos -> runa de tier I de tipo al azar.
--   Fusionar: 3 runas del mismo tipo y tier -> 1 del tier siguiente.
-- * Aplicar: usar la runa sobre la Pokeball. Quitar: !runas (la runa vuelve a la mochila).
-- * Materiales: solo de las quests semanales y la Liga (lib/core/weeklyquests.lua).
-- * Efectos: ataque/defensa/critico en creaturescripts/scripts/monsterhealthchange.lua, vida al
--   sacar el Pokemon (doReleaseSummon) y experiencia en events/scripts/player.lua.

RUNE_FRAGMENT_ID = 2150   -- fragmento runico (apilable)
RUNE_BLANK_ID = 2260      -- runa en blanco (la "herramienta" para inscribir una runa)
RUNE_MAX_PER_BALL = 3
RUNE_CRAFT_FRAGMENTS = 10
RUNE_FUSE_COUNT = 3

-- bonus por tier (I..VII). "percent": % sobre la estadistica; crit: puntos de probabilidad
runeTiers = {3, 6, 9, 12, 15, 18, 21}
runeCritTiers = {1, 2, 3, 4, 5, 6, 7}
runeTypes = {
	atk = {id = 2304, name = "Runa de Ataque", text = "de dano"},
	def = {id = 2293, name = "Runa de Defensa", text = "de defensa"},
	hp = {id = 2265, name = "Runa de Vida", text = "de vida maxima"},
	exp = {id = 2295, name = "Runa de Experiencia", text = "de experiencia al cazar con el fuera"},
	crit = {id = 2268, name = "Runa Critica", text = "de probabilidad de golpe critico", crit = true},
}
runeTypeOrder = {"atk", "def", "hp", "exp", "crit"}
local ROMAN = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}

local runeTypeById = {}
for key, rune in pairs(runeTypes) do
	runeTypeById[rune.id] = key
end

function getRuneTypeByItemId(itemId)
	return runeTypeById[itemId]
end

function runeBonus(typeKey, tier)
	local list = runeTypes[typeKey] and runeTypes[typeKey].crit and runeCritTiers or runeTiers
	return list[math.max(1, math.min(#list, tier or 1))] or 0
end

function runeLabel(typeKey, tier)
	local rune = runeTypes[typeKey]
	if not rune then
		return "?"
	end
	return rune.name .. " " .. (ROMAN[tier] or tier)
end

function runeEffectText(typeKey, tier)
	local rune = runeTypes[typeKey]
	local bonus = runeBonus(typeKey, tier)
	return "+" .. bonus .. (rune.crit and " puntos " or "% ") .. rune.text
end

-- ===================== Runas de una Pokeball =====================
function getBallRunes(ball)
	local runes = ball:getSpecialAttribute("runes")
	if type(runes) ~= "table" then
		return {}
	end
	return runes
end

local function setBallRunes(ball, runes)
	local count = 0
	for _ in pairs(runes) do count = count + 1 end
	ball:setSpecialAttribute("runes", count > 0 and runes or {})
end

function describeBallRunes(ball)
	local parts = {}
	local runes = getBallRunes(ball)
	for _, key in ipairs(runeTypeOrder) do
		if runes[key] then
			parts[#parts + 1] = runeLabel(key, runes[key]) .. " (" .. runeEffectText(key, runes[key]) .. ")"
		end
	end
	return parts
end

-- bonus de las runas para el Pokemon que esta fuera: se guarda al sacarlo (doReleaseSummon)
pokeRuneCache = pokeRuneCache or {}

function cacheSummonRunes(summon, ball)
	pokeRuneCache[summon:getId()] = getBallRunes(ball)
end

-- fraccion de bonus de un tipo para un Pokemon fuera (0 si no tiene); crit devuelve puntos
function getSummonRuneBonus(summon, typeKey)
	if not summon then
		return 0
	end
	local runes = pokeRuneCache[summon:getId()]
	if not runes then
		local master = summon:getMaster()
		local ball = master and master:isPlayer() and master:getUsingBall()
		runes = ball and getBallRunes(ball) or {}
		pokeRuneCache[summon:getId()] = runes
	end
	local tier = runes[typeKey]
	if not tier then
		return 0
	end
	local bonus = runeBonus(typeKey, tier)
	return runeTypes[typeKey].crit and bonus or bonus / 100
end

-- ===================== Crear runas =====================
function createRune(player, typeKey, tier)
	local rune = runeTypes[typeKey]
	if not rune then
		return nil
	end
	local item = player:addItem(rune.id, 1, false)
	if not item then
		return nil
	end
	item:setSpecialAttribute("runeTier", tier)
	return item
end

-- runas sueltas del jugador: {typeKey.."_"..tier = {items}}
local function collectRunes(player)
	local groups = {}
	local function walk(container, depth)
		if depth > 10 then return end
		for slot = 0, container:getSize() - 1 do
			local item = container:getItem(slot)
			if item then
				if item:isContainer() then
					walk(item, depth + 1)
				else
					local key = runeTypeById[item:getId()]
					if key then
						local tier = tonumber(item:getSpecialAttribute("runeTier")) or 1
						local group = key .. "_" .. tier
						groups[group] = groups[group] or {key = key, tier = tier, items = {}, count = 0}
						table.insert(groups[group].items, item)
						groups[group].count = groups[group].count + math.max(1, item:getCount())
					end
				end
			end
		end
	end
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if backpack and backpack:isContainer() then
		walk(backpack, 0)
	end
	return groups
end

local function craftRune(player)
	if player:getItemCount(RUNE_BLANK_ID) < 1 or player:getItemCount(RUNE_FRAGMENT_ID) < RUNE_CRAFT_FRAGMENTS then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Necesitas 1 runa en blanco y " .. RUNE_CRAFT_FRAGMENTS ..
			" fragmentos runicos. Los dan las quests semanales y la Liga.")
		return false
	end
	local typeKey = runeTypeOrder[math.random(1, #runeTypeOrder)]
	player:removeItem(RUNE_BLANK_ID, 1)
	player:removeItem(RUNE_FRAGMENT_ID, RUNE_CRAFT_FRAGMENTS)
	if not createRune(player, typeKey, 1) then
		player:addItem(RUNE_BLANK_ID, 1)
		player:addItem(RUNE_FRAGMENT_ID, RUNE_CRAFT_FRAGMENTS)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "No tienes sitio en la mochila.")
		return false
	end
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Has inscrito una " .. runeLabel(typeKey, 1) .. ": " .. runeEffectText(typeKey, 1) .. ".")
	return true
end

local function fuseRunes(player, typeKey, tier)
	if tier >= #runeTiers then
		return false
	end
	local group = collectRunes(player)[typeKey .. "_" .. tier]
	if not group or group.count < RUNE_FUSE_COUNT then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Necesitas " .. RUNE_FUSE_COUNT .. " " .. runeLabel(typeKey, tier) .. " para fusionarlas.")
		return false
	end
	-- por si las runas se apilan: se quitan unidades, no objetos
	local left = RUNE_FUSE_COUNT
	for _, item in ipairs(group.items) do
		if left <= 0 then break end
		local take = math.min(left, math.max(1, item:getCount()))
		item:remove(take)
		left = left - take
	end
	createRune(player, typeKey, tier + 1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Has fusionado " .. RUNE_FUSE_COUNT .. " runas en una " .. runeLabel(typeKey, tier + 1) ..
		": " .. runeEffectText(typeKey, tier + 1) .. ".")
	return true
end

-- ===================== Aplicar una runa a una Pokeball =====================
function applyRuneToBall(player, rune, ball)
	local typeKey = runeTypeById[rune:getId()]
	if not typeKey then
		return false
	end
	if not ball or not ball:isItem() or not ball:isPokeball() or not ball:getSpecialAttribute("pokeName") then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Usa la runa sobre una Pokeball con un Pokemon dentro.")
		return false
	end
	local tier = tonumber(rune:getSpecialAttribute("runeTier")) or 1
	local runes = getBallRunes(ball)
	local count = 0
	for _ in pairs(runes) do count = count + 1 end
	local old = runes[typeKey]
	if old and old >= tier then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Esa Pokeball ya tiene una " .. runeLabel(typeKey, old) .. ".")
		return false
	end
	if not old and count >= RUNE_MAX_PER_BALL then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Esa Pokeball ya tiene " .. RUNE_MAX_PER_BALL .. " runas. Quita una con !runas.")
		return false
	end
	runes[typeKey] = tier
	setBallRunes(ball, runes)
	rune:remove(1)
	if old then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "La " .. runeLabel(typeKey, old) .. " se ha deshecho al poner la nueva.")
	end
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, ball:getSpecialAttribute("pokeName") .. " lleva ahora una " ..
		runeLabel(typeKey, tier) .. ": " .. runeEffectText(typeKey, tier) .. ".")
	if ball:getSpecialAttribute("isBeingUsed") == 1 then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Guarda y vuelve a sacar a tu Pokemon para que la runa haga efecto.")
	end
	return true
end

-- ===================== Ventana !runas =====================
local MODAL_RUNES, MODAL_FUSE, MODAL_REMOVE_BALL, MODAL_REMOVE_RUNE = 6130, 6131, 6132, 6133
local pendingRemove = {}

local function ballsWithRunes(player)
	local list = {}
	for _, ball in ipairs(player:getPokeballs() or {}) do
		if next(getBallRunes(ball)) then
			list[#list + 1] = ball
		end
	end
	return list
end

function Player.sendRuneWindow(self)
	local groups = collectRunes(self)
	local lines = {}
	for _, key in ipairs(runeTypeOrder) do
		for tier = 1, #runeTiers do
			local group = groups[key .. "_" .. tier]
			if group then
				lines[#lines + 1] = group.count .. "x " .. runeLabel(key, tier)
			end
		end
	end
	local text = "Runa en blanco: " .. self:getItemCount(RUNE_BLANK_ID) .. "   Fragmentos runicos: " .. self:getItemCount(RUNE_FRAGMENT_ID) ..
		"\n\nFabricar: 1 runa en blanco + " .. RUNE_CRAFT_FRAGMENTS .. " fragmentos = 1 runa de tier I al azar." ..
		"\nFusionar: " .. RUNE_FUSE_COUNT .. " runas iguales = 1 del tier siguiente (hasta el VII)." ..
		"\nAplicar: usa la runa sobre una Pokeball (maximo " .. RUNE_MAX_PER_BALL .. ", de tipos distintos)." ..
		"\n\nTus runas: " .. (#lines > 0 and table.concat(lines, ", ") or "ninguna")
	local window = ModalWindow(MODAL_RUNES, "Runas", text)
	window:addButton(1, "Fabricar")
	window:addButton(2, "Fusionar")
	window:addButton(3, "Quitar")
	window:addButton(4, "Cerrar")
	window:setDefaultEnterButton(1)
	window:setDefaultEscapeButton(4)
	window:sendToPlayer(self)
end

local function sendFuseWindow(player)
	local groups = collectRunes(player)
	local window = ModalWindow(MODAL_FUSE, "Fusionar runas", "Elige que runas fusionar (" .. RUNE_FUSE_COUNT .. " iguales = 1 del tier siguiente).")
	local any = false
	for index, key in ipairs(runeTypeOrder) do
		for tier = 1, #runeTiers - 1 do
			local group = groups[key .. "_" .. tier]
			if group and group.count >= RUNE_FUSE_COUNT then
				window:addChoice(index * 100 + tier, group.count .. "x " .. runeLabel(key, tier) .. " -> " .. runeLabel(key, tier + 1))
				any = true
			end
		end
	end
	if not any then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "No tienes " .. RUNE_FUSE_COUNT .. " runas iguales para fusionar.")
		return
	end
	window:addButton(1, "Fusionar")
	window:addButton(2, "Volver")
	window:setDefaultEnterButton(1)
	window:setDefaultEscapeButton(2)
	window:sendToPlayer(player)
end

local function sendRemoveBallWindow(player)
	local balls = ballsWithRunes(player)
	if #balls == 0 then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Ninguna de tus Pokeballs tiene runas.")
		return
	end
	local window = ModalWindow(MODAL_REMOVE_BALL, "Quitar runa", "Elige la Pokeball. La runa vuelve a tu mochila.")
	for index, ball in ipairs(balls) do
		window:addChoice(index, ball:getSpecialAttribute("pokeName") .. ": " .. table.concat(describeBallRunes(ball), ", "))
	end
	-- solo se guarda el indice y el nombre: al contestar se vuelve a buscar la Pokeball
	local names = {}
	for index, ball in ipairs(balls) do
		names[index] = ball:getSpecialAttribute("pokeName")
	end
	pendingRemove[player:getId()] = {names = names}
	window:addButton(1, "Elegir")
	window:addButton(2, "Volver")
	window:setDefaultEnterButton(1)
	window:setDefaultEscapeButton(2)
	window:sendToPlayer(player)
end

local function pendingBall(player)
	local pending = pendingRemove[player:getId()]
	if not pending or not pending.index then
		return nil
	end
	local ball = ballsWithRunes(player)[pending.index]
	if ball and ball:getSpecialAttribute("pokeName") == pending.names[pending.index] then
		return ball
	end
	return nil
end

local function sendRemoveRuneWindow(player, ball)
	local window = ModalWindow(MODAL_REMOVE_RUNE, "Quitar runa", "Que runa quitas de " .. ball:getSpecialAttribute("pokeName") .. "?")
	local runes = getBallRunes(ball)
	for index, key in ipairs(runeTypeOrder) do
		if runes[key] then
			window:addChoice(index, runeLabel(key, runes[key]))
		end
	end
	window:addButton(1, "Quitar")
	window:addButton(2, "Volver")
	window:setDefaultEnterButton(1)
	window:setDefaultEscapeButton(2)
	window:sendToPlayer(player)
end

-- respuestas de las ventanas (creaturescripts: RuneModal, evento ModalWindow)
function onRuneModalAnswer(player, modalWindowId, buttonId, choiceId)
	if modalWindowId == MODAL_RUNES then
		if buttonId == 1 then
			craftRune(player)
			player:sendRuneWindow()
		elseif buttonId == 2 then
			sendFuseWindow(player)
		elseif buttonId == 3 then
			sendRemoveBallWindow(player)
		end
		return true
	elseif modalWindowId == MODAL_FUSE then
		if buttonId == 1 and choiceId and choiceId > 0 then
			fuseRunes(player, runeTypeOrder[math.floor(choiceId / 100)], choiceId % 100)
		end
		player:sendRuneWindow()
		return true
	elseif modalWindowId == MODAL_REMOVE_BALL then
		local pending = pendingRemove[player:getId()]
		if buttonId == 1 and pending and pending.names[choiceId] then
			pending.index = choiceId
			local ball = pendingBall(player)
			if ball then
				sendRemoveRuneWindow(player, ball)
			else
				player:sendTextMessage(MESSAGE_INFO_DESCR, "Esa Pokeball ya no esta donde estaba.")
				player:sendRuneWindow()
			end
		else
			player:sendRuneWindow()
		end
		return true
	elseif modalWindowId == MODAL_REMOVE_RUNE then
		local key = runeTypeOrder[choiceId or 0]
		local ball = buttonId == 1 and key and pendingBall(player)
		if ball then
			local runes = getBallRunes(ball)
			if runes[key] then
				if createRune(player, key, runes[key]) then
					local tier = runes[key]
					runes[key] = nil
					setBallRunes(ball, runes)
					player:sendTextMessage(MESSAGE_INFO_DESCR, "Has quitado la " .. runeLabel(key, tier) .. ". Esta en tu mochila.")
				else
					player:sendTextMessage(MESSAGE_INFO_DESCR, "No tienes sitio en la mochila.")
				end
			end
		end
		pendingRemove[player:getId()] = nil
		player:sendRuneWindow()
		return true
	end
	return false
end
