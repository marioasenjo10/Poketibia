-- PC de Pokemon y objetos. Cliente: modules/game_pc.
--
-- Sustituye a la vista de depot de Tibia. Todo se guarda en el inbox del jugador, que ya no se ve:
-- es el mismo en todas las ciudades, no tiene limite del motor y el servidor ya lo guarda en la base
-- de datos (player_inboxitems). Los objetos se mueven tal cual (boost, vida, runas, recargas...).
-- Lo que hubiera en los depots antiguos se pasa al inbox la primera vez que se abre el PC.
--
-- Cliente -> servidor: talkaction "pkdpc ..." (solo funciona desde un clic o una tecla)
--   mons <pagina> <orden> [busqueda]   items <pagina> <categoria> [busqueda]
--   swap <uidEquipo|0> <uidPc|0>       put <fila> <cantidad>   take <fila> <cantidad>   close
-- Servidor -> cliente: opcode 78, primera linea "tipo|cabecera...", despues una fila por linea.

OPCODE_PC = 78

pokePc = {
	maxItems = 6000,   -- tope tecnico de cosas guardadas por jugador
	monsPage = 20,
	itemsPage = 48,
	bagRows = 48,
	reach = 2,         -- distancia maxima al PC
}

local STORAGE_NEXT_UID = 98001
local categories = {todo = true, balls = true, potions = true, stones = true, runas = true, orbes = true, otros = true}
local sorts = {recent = true, name = true, dex = true, boost = true}

local sessions = {} -- [guid] = {pos, mons = {...}, items = {...}, bagRows, pcRows}

local function clean(text)
	return (tostring(text or ""):gsub("[|;\n\r]", " "))
end

local function specialOf(item)
	if item:hasAttribute(ITEM_ATTRIBUTE_SPECIAL) then
		return item:getAttribute(ITEM_ATTRIBUTE_SPECIAL) or ""
	end
	return ""
end

local function countOf(item)
	return ItemType(item:getId()):isStackable() and math.max(1, item:getCount()) or 1
end

local function pokemonName(item)
	if not item:isPokeball() then
		return nil
	end
	local name = item:getSpecialAttribute("pokeName")
	return name and name ~= "" and name or nil
end

local function children(container)
	local list = {}
	for slot = 0, container:getSize() - 1 do
		local item = container:getItem(slot)
		if item then
			list[#list + 1] = item
		end
	end
	return list
end

local function holdsPokemon(container, depth)
	for _, item in ipairs(children(container)) do
		if pokemonName(item) or (item:isContainer() and depth < 10 and holdsPokemon(item, depth + 1)) then
			return true
		end
	end
	return false
end

-- ===================== Almacen =====================
-- registro del traspaso y de los movimientos que fallen (para revisar fallos): data/logs/pc.log
local function pcLog(text)
	print("[PC] " .. text)
	local file = io.open("data/logs/pc.log", "a")
	if file then
		file:write(os.date("%d/%m %H:%M:%S") .. " " .. text .. "\n")
		file:close()
	end
end

-- Mueve un objeto entero a un contenedor y devuelve el objeto en su nuevo sitio (o nil).
-- En este ejecutable item:moveTo(contenedor) devuelve nil con el inbox y el depot, asi que se hace
-- una copia, se comprueba que es identica, se mete en el destino y solo entonces se borra el original.
-- Si algo falla, el original se queda donde estaba.
local function moveInto(item, destination)
	local copy = item:clone()
	if not copy then
		pcLog("no se pudo copiar el objeto " .. item:getId())
		return nil
	end
	if copy:getId() ~= item:getId() or countOf(copy) ~= countOf(item) or specialOf(copy) ~= specialOf(item)
		or copy:getSpecialAttribute("pokeName") ~= item:getSpecialAttribute("pokeName")
		or (item:isContainer() and copy:getSize() ~= item:getSize()) then
		pcLog("la copia del objeto " .. item:getId() .. " no es identica: no se mueve")
		return nil
	end
	local result = destination:addItemEx(copy, INDEX_WHEREEVER, FLAG_NOLIMIT)
	if result ~= RETURNVALUE_NOERROR then
		pcLog("no cabe el objeto " .. item:getId() .. " en el destino (resultado " .. tostring(result) .. ")")
		return nil
	end
	if not item:remove() then
		copy:remove()
		pcLog("no se pudo quitar el original " .. item:getId() .. ": se deshace la copia")
		return nil
	end
	return copy
end

-- saca al primer nivel del PC todo lo que haya dentro de mochilas guardadas (si no, no se veria)
local function flatten(store, container, depth)
	if depth > 10 then
		return
	end
	for _, item in ipairs(children(container)) do
		if item:isContainer() then
			flatten(store, item, depth + 1)
		end
		moveInto(item, store)
	end
end

-- pasa los depots antiguos (uno por ciudad) al almacen unico
local function migrate(player, store)
	local moved, failed = 0, 0
	-- el motor carga los depots 0-99. Se piden creandolos si no existen: vacios no se guardan
	for depotId = 0, 99 do
		local chest = player:getDepotChest(depotId, true)
		if chest then
			local items = children(chest)
			if #items > 0 then
				pcLog(player:getName() .. ": depot " .. depotId .. " tiene " .. #items .. " cosas")
			end
			for i = #items, 1, -1 do
				if moveInto(items[i], store) then
					moved = moved + 1
				else
					failed = failed + 1
				end
			end
		end
	end
	for _, item in ipairs(children(store)) do
		if item:isContainer() and item:getSize() > 0 then
			flatten(store, item, 0)
		end
	end
	pcLog(player:getName() .. ": " .. moved .. " pasadas del depot, " .. failed .. " fallidas, almacen con " ..
		store:getSize() .. " cosas")
	return moved
end

local function storage(player)
	return player:getInbox()
end

-- identificador propio de cada Pokeball, para que el cliente pueda senalarla
local function newUid(player)
	local uid = math.max(0, player:getStorageValue(STORAGE_NEXT_UID)) + 1
	player:setStorageValue(STORAGE_NEXT_UID, uid)
	return uid
end

local function uidOf(player, ball, seen)
	local uid = tonumber(ball:getSpecialAttribute("pcUid")) or 0
	if uid <= 0 or seen[uid] then
		uid = newUid(player)
		ball:setSpecialAttribute("pcUid", uid)
	end
	seen[uid] = true
	return uid
end

-- equipo (lo que lleva encima) y Pokemon del PC, cada uno con su uid
local function collectMons(player)
	local seen, team, stored = {}, {}, {}
	for _, ball in ipairs(player:getPokeballs()) do
		if pokemonName(ball) then
			team[#team + 1] = {ball = ball, uid = uidOf(player, ball, seen)}
		end
	end
	for _, item in ipairs(children(storage(player))) do
		if pokemonName(item) then
			stored[#stored + 1] = {ball = item, uid = uidOf(player, item, seen)}
		end
	end
	return team, stored
end

local function isOut(ball)
	if ball:getSpecialAttribute("isBeingUsed") == 1 then
		return true
	end
	local key = getBallKey(ball:getId())
	return key and balls[key] and ball:getId() == balls[key].usedOff or false
end

local typeNames = {venon = "poison"}

local function monInfo(entry)
	local ball = entry.ball
	local name = pokemonName(ball)
	local monsterType = MonsterType(name)
	local health = tonumber(ball:getSpecialAttribute("pokeHealth")) or 0
	local maxHealth = tonumber(ball:getSpecialAttribute("pokeMaxHealth")) or 0
	local percent = 100
	if health <= 0 then
		percent = 0
	elseif maxHealth > 0 then
		percent = math.max(1, math.min(100, math.floor(health * 100 / maxHealth)))
	end
	local types, moves, dex, look = {}, {}, 0, 0
	if monsterType then
		look = monsterType:getOutfit().lookType
		for _, race in ipairs({monsterType:getRaceName(), monsterType:getRace2Name()}) do
			if race and race ~= "none" then
				types[#types + 1] = typeNames[race] or race
			end
		end
		for i, move in ipairs(monsterType:getMoveList()) do
			if i > #moveWords then break end
			moves[#moves + 1] = clean(move.name)
		end
		dex = tonumber(monsterType:dexEntry()) or 0
	end
	return {uid = entry.uid, name = name, boost = tonumber(ball:getSpecialAttribute("pokeBoost")) or 0,
		hp = percent, out = isOut(ball), dex = dex, types = types, moves = moves, look = look,
		at = tonumber(ball:getSpecialAttribute("pcAt")) or 0}
end

local function monLine(kind, m)
	return table.concat({kind, m.uid, clean(m.name), m.boost, m.hp, m.out and 1 or 0, m.dex,
		table.concat(m.types, ";"), table.concat(m.moves, ";"), m.look}, "|")
end

-- spare: huecos que siempre tiene que haber libres al final (para soltar un Pokemon y guardarlo)
local function paginate(list, page, size, spare)
	local pages = math.max(1, math.ceil((#list + (spare or 0)) / size))
	page = math.min(math.max(1, page or 1), pages)
	local out = {}
	for i = (page - 1) * size + 1, math.min(#list, page * size) do
		out[#out + 1] = list[i]
	end
	return out, page, pages
end

local function send(player, lines)
	player:sendExtendedOpcode(OPCODE_PC, table.concat(lines, "\n"))
end

local function sendMessage(player, text, ok)
	send(player, {"msg|" .. (ok and 1 or 0) .. "|" .. clean(text)})
end

-- ===================== Pestana Pokemon =====================
local function sendMons(player, session)
	local team, stored = collectMons(player)
	local view = session.mons
	local list = {}
	local search = view.search:lower()
	for _, entry in ipairs(stored) do
		local info = monInfo(entry)
		local text = (info.name .. " " .. table.concat(info.types, " ")):lower()
		if search == "" or text:find(search, 1, true) then
			list[#list + 1] = info
		end
	end
	table.sort(list, function(a, b)
		if view.sort == "name" and a.name ~= b.name then return a.name < b.name end
		if view.sort == "dex" and a.dex ~= b.dex then return a.dex < b.dex end
		if view.sort == "boost" and a.boost ~= b.boost then return a.boost > b.boost end
		if view.sort == "recent" and a.at ~= b.at then return a.at > b.at end
		if a.name ~= b.name then return a.name < b.name end
		if a.boost ~= b.boost then return a.boost > b.boost end
		return a.uid > b.uid
	end)
	local shown, page, pages = paginate(list, view.page, pokePc.monsPage, 1)
	view.page = page
	local lines = {table.concat({"mons", page, pages, #stored, view.sort, clean(view.search)}, "|")}
	for _, entry in ipairs(team) do
		lines[#lines + 1] = monLine("T", monInfo(entry))
	end
	for _, info in ipairs(shown) do
		lines[#lines + 1] = monLine("P", info)
	end
	send(player, lines)
end

-- ===================== Pestana Objetos =====================
local emptyBallIds

local function categoryOf(itemId, lower)
	if not emptyBallIds then
		emptyBallIds = {}
		for _, ball in pairs(balls) do
			emptyBallIds[ball.emptyId] = true
		end
	end
	if emptyBallIds[itemId] then
		return "balls"
	elseif shinyOrbByItemId and shinyOrbByItemId[itemId] then
		return "orbes"
	elseif (getRuneTypeByItemId and getRuneTypeByItemId(itemId)) or itemId == RUNE_BLANK_ID or itemId == RUNE_FRAGMENT_ID then
		return "runas"
	elseif lower:find("stone", 1, true) then
		return "stones"
	elseif lower:find("potion", 1, true) or lower:find("revive", 1, true) or lower:find("elixir", 1, true) then
		return "potions"
	end
	return "otros"
end

local function itemName(item)
	local name = ItemType(item:getId()):getName():gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end)
	local target = shinyOrbByItemId and shinyOrbByItemId[item:getId()] and item:getSpecialAttribute("evoTarget")
	if target then
		name = name .. " (" .. target .. ")"
	end
	return name
end

-- agrupa objetos iguales (mismo id y atributos) en una sola fila con la cantidad total
local function groupItems(items)
	local rows, byKey = {}, {}
	for _, item in ipairs(items) do
		if not pokemonName(item) then
			local special = specialOf(item)
			local key = item:getId() .. "\0" .. special
			local row = byKey[key]
			-- lo que no se apila va en filas sueltas
			if not row or not ItemType(item:getId()):isStackable() or special ~= "" then
				row = {id = item:getId(), special = special, count = 0, name = itemName(item)}
				row.category = categoryOf(row.id, row.name:lower())
				rows[#rows + 1] = row
				byKey[key] = row
			end
			row.count = row.count + countOf(item)
		end
	end
	return rows
end

local function bagItems(player)
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if backpack and backpack:isContainer() then
		return children(backpack), backpack
	end
	return {}, nil
end

local function itemLine(kind, index, row)
	return table.concat({kind, index, ItemType(row.id):getClientId(), clean(row.name), row.count}, "|")
end

local function sendItems(player, session)
	local view = session.items
	local bag = groupItems((bagItems(player)))
	local all = groupItems(children(storage(player)))
	local search = view.search:lower()
	local list = {}
	for _, row in ipairs(all) do
		if (view.category == "todo" or row.category == view.category) and (search == "" or row.name:lower():find(search, 1, true)) then
			list[#list + 1] = row
		end
	end
	table.sort(list, function(a, b)
		if a.category ~= b.category then return a.category < b.category end
		if a.name ~= b.name then return a.name < b.name end
		return a.count > b.count
	end)
	local shown, page, pages = paginate(list, view.page, pokePc.itemsPage)
	view.page = page
	local lines = {table.concat({"items", page, pages, #all, view.category, clean(view.search), math.max(0, #bag - pokePc.bagRows)}, "|")}
	session.bagRows, session.pcRows = {}, {}
	for i = 1, math.min(#bag, pokePc.bagRows) do
		session.bagRows[i] = bag[i]
		lines[#lines + 1] = itemLine("B", i, bag[i])
	end
	for i, row in ipairs(shown) do
		session.pcRows[i] = row
		lines[#lines + 1] = itemLine("P", i, row)
	end
	send(player, lines)
end

-- ===================== Reglas =====================
local function blockedReason(player, session)
	if not session then
		return "Abre el PC otra vez."
	end
	local pos = player:getPosition()
	if pos.z ~= session.pos.z or math.abs(pos.x - session.pos.x) > pokePc.reach or math.abs(pos.y - session.pos.y) > pokePc.reach then
		return "Te has alejado del PC."
	end
	if player:isDuelingWithNpc() then
		return "No puedes usar el PC durante un combate."
	end
	if player:isOnLeague() then
		return "No puedes usar el PC durante la Liga."
	end
	return nil
end

local function findByUid(list, uid)
	for _, entry in ipairs(list) do
		if entry.uid == uid then
			return entry
		end
	end
	return nil
end

-- la recarga lenta de un Pokemon guardado sigue igual dentro del PC: solo se marca si no lo estaba
local function keepSlowCooldown(ball)
	if (tonumber(ball:getSpecialAttribute("cdPausedAt")) or 0) <= 0 then
		pauseMoveCooldowns(ball)
	end
end

-- guarda teamUid, saca pcUid, o las dos cosas a la vez (intercambio). 0 = nada por ese lado
local function swap(player, teamUid, pcUid)
	local team, stored = collectMons(player)
	local out = teamUid > 0 and findByUid(team, teamUid) or nil
	local inc = pcUid > 0 and findByUid(stored, pcUid) or nil
	if (teamUid > 0 and not out) or (pcUid > 0 and not inc) or (not out and not inc) then
		return false, "Ese Pokemon ya no esta ahi."
	end
	if out and isOut(out.ball) then
		return false, pokemonName(out.ball) .. " esta fuera. Guardalo antes de moverlo."
	end
	if out and not inc and #team <= 1 then
		return false, "Tienes que llevar al menos un Pokemon en el equipo."
	end
	if inc and not out and #team >= maxFilledBalls then
		return false, "El equipo esta lleno: suelta el Pokemon encima del que quieras cambiar."
	end
	if out and not inc and #stored >= pokePc.maxItems then
		return false, "El PC esta lleno."
	end

	local incName = inc and pokemonName(inc.ball)
	local outName = out and pokemonName(out.ball)
	local belt = player:getPokemonBelt()
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	local function room(container)
		return container and container:getEmptySlots() > 0
	end
	if inc and not out and not room(belt) and not room(backpack) then
		return false, "No tienes sitio para llevarlo."
	end
	local stored
	if out then
		keepSlowCooldown(out.ball)
		out.ball:setSpecialAttribute("pcAt", os.time())
		stored = moveInto(out.ball, storage(player))
		if not stored then
			return false, "No se ha podido guardar."
		end
	end
	if inc then
		local destination = room(belt) and belt or (room(backpack) and backpack or nil)
		if not destination or not moveInto(inc.ball, destination) then
			if stored then
				moveInto(stored, room(belt) and belt or backpack)
			end
			player:refreshPokemonBar({}, {})
			return false, "No se ha podido sacar del PC."
		end
	end
	player:refreshPokemonBar({}, {})
	if inc and out then
		return true, "Intercambiados: entra " .. incName .. " y " .. outName .. " va al PC."
	elseif inc then
		return true, incName .. " se une al equipo."
	end
	return true, outName .. " guardado en el PC."
end

-- mueve hasta "amount" unidades de los objetos que forman una fila hacia destination
local function transfer(source, destination, row, amount, spaceLeft)
	local moved = 0
	for _, item in ipairs(source) do
		if moved >= amount then break end
		if item:getId() == row.id and specialOf(item) == row.special and not pokemonName(item) then
			if item:isContainer() and (item:getSize() > 0 or holdsPokemon(item, 0)) then
				return moved, "Vacia esa mochila antes de moverla."
			end
			if spaceLeft and spaceLeft() <= 0 then
				return moved, "No te cabe mas en la mochila."
			end
			local have = countOf(item)
			local take = math.min(have, amount - moved)
			if take < have and row.special == "" then
				if not destination:addItem(row.id, take, INDEX_WHEREEVER, FLAG_NOLIMIT) then
					return moved, "No se ha podido mover."
				end
				item:remove(take)
			else
				take = have
				if not moveInto(item, destination) then
					return moved, "No se ha podido mover."
				end
			end
			moved = moved + take
		end
	end
	return moved, nil
end

local function moveItems(player, session, deposit, index, amount)
	local row = (deposit and session.bagRows or session.pcRows or {})
	row = row and row[index]
	if not row then
		return false, "Esa fila ha cambiado. Vuelve a intentarlo."
	end
	amount = math.floor(amount or 0)
	if amount < 1 then
		return false, "Cantidad no valida."
	end
	local items, backpack = bagItems(player)
	if not backpack then
		return false, "No llevas mochila."
	end
	local moved, problem
	if deposit then
		-- (este ejecutable no tiene ItemType:isPickupable; lo que va en la mochila ya se puede coger)
		if not ItemType(row.id):isMovable() then
			return false, "Eso no se puede guardar."
		end
		if storage(player):getSize() >= pokePc.maxItems then
			return false, "El PC esta lleno."
		end
		moved, problem = transfer(items, storage(player), row, amount)
	else
		moved, problem = transfer(children(storage(player)), backpack, row, amount, function() return backpack:getEmptySlots() end)
	end
	if moved <= 0 then
		return false, problem or "No queda ninguno."
	end
	local text = moved .. " x " .. row.name .. (deposit and " al PC." or " a la mochila.")
	return true, problem and (text .. " " .. problem) or text
end

-- ===================== Abrir y peticiones =====================
function Player.openPokePc(self, position)
	if self:isDuelingWithNpc() or self:isOnLeague() then
		self:sendCancelMessage("No puedes usar el PC durante un combate.")
		return
	end
	if not self:isUsingOtClient() then
		return
	end
	migrate(self, storage(self))
	local session = {
		pos = {x = position.x, y = position.y, z = position.z},
		mons = {page = 1, sort = "recent", search = ""},
		items = {page = 1, category = "todo", search = ""},
	}
	sessions[self:getGuid()] = session
	send(self, {"open"})
	sendMons(self, session)
	sendItems(self, session)
end

local handleRequest

-- si algo falla por dentro, se apunta en data/logs/pc.log y el jugador ve un aviso (antes: silencio)
function onPokePcRequest(player, param)
	local ok, problem = pcall(handleRequest, player, param)
	if not ok then
		pcLog(player:getName() .. ": error en \"" .. tostring(param) .. "\": " .. tostring(problem))
		sendMessage(player, "Algo ha fallado en el PC. Queda apuntado en el registro.")
	end
end

function handleRequest(player, param)
	local words = {}
	for word in (param or ""):gmatch("%S+") do
		words[#words + 1] = word
	end
	local action = (words[1] or ""):lower()
	if action == "close" then
		sessions[player:getGuid()] = nil
		return
	end
	local session = sessions[player:getGuid()]
	local reason = blockedReason(player, session)
	if reason then
		sessions[player:getGuid()] = nil
		send(player, {"close|" .. clean(reason)})
		return
	end
	if action == "mons" then
		session.mons.page = tonumber(words[2]) or 1
		session.mons.sort = sorts[words[3]] and words[3] or "recent"
		session.mons.search = table.concat(words, " ", 4):sub(1, 30)
		sendMons(player, session)
	elseif action == "items" then
		session.items.page = tonumber(words[2]) or 1
		session.items.category = categories[words[3]] and words[3] or "todo"
		session.items.search = table.concat(words, " ", 4):sub(1, 30)
		sendItems(player, session)
	elseif action == "swap" then
		local ok, text = swap(player, tonumber(words[2]) or 0, tonumber(words[3]) or 0)
		sendMons(player, session)
		sendMessage(player, text, ok)
	elseif action == "put" or action == "take" then
		local ok, text = moveItems(player, session, action == "put", tonumber(words[2]) or 0, tonumber(words[3]) or 0)
		sendItems(player, session)
		sendMessage(player, text, ok)
	end
end
