-- Mercado global entre jugadores (estilo PKA). Cliente: modules/game_pokemarket.
--
-- * Se abre desde el boton "Mercado" del cliente, pero solo cerca de una tienda (NPC "mark").
-- * Se venden objetos y Pokemon: una Pokeball guarda todo en ITEM_ATTRIBUTE_SPECIAL (texto), asi que
--   cada oferta guarda id del objeto + cantidad + ese texto, y al comprarla se recrea identica.
-- * Comprar cobra del banco. Al vendedor se le ingresa en el banco (conectado o no) menos la comision,
--   y le queda un aviso en "Recibidos".
-- * Lo comprado, lo cancelado y lo caducado va a "Recibidos" (la taquilla): se recoge desde la ventana.
--
-- Cliente -> servidor: talkaction "pokemarket ..." (los opcodes cliente->servidor no llegan aqui)
--   open | list <cat> <pag> [busqueda] | buy <id> <cant> <cat> <pag> [busqueda] | inv
--   sell <n> <cant> <precio> | mine | cancel <id> | locker | take <id|all>
-- Servidor -> cliente: opcode 77, primera linea "tipo|...", despues una fila por linea (campos con |).

OPCODE_MARKET = 77

pokeMarket = {
	tax = 0.05,                    -- comision que se descuenta al vendedor
	duration = 7 * 24 * 60 * 60,   -- las ofertas caducan a los 7 dias y vuelven a "Recibidos"
	maxOffers = 20,                -- ofertas a la vez por jugador
	pageSize = 10,
	maxPrice = 999999999,
	shopRadius = 8,                -- distancia maxima a un tendero para usar el mercado
	categories = {"todo", "pokemon", "balls", "stones", "potions", "otros"},
}

local SEP = "|"

local function clean(text)
	return (tostring(text or ""):gsub("[|\n\r]", " "))
end

-- ===================== Tablas de la base de datos =====================
local function ensureTables()
	if pokeMarketTablesReady then
		return
	end
	db.query([[CREATE TABLE IF NOT EXISTS `pkd_market_offers` (
		`id` INT NOT NULL AUTO_INCREMENT, `player_id` INT NOT NULL, `player_name` VARCHAR(255) NOT NULL,
		`itemid` INT NOT NULL, `count` INT NOT NULL, `special` TEXT NOT NULL, `name` VARCHAR(255) NOT NULL,
		`category` VARCHAR(16) NOT NULL, `price` BIGINT NOT NULL, `created` INT NOT NULL,
		PRIMARY KEY (`id`), KEY `category` (`category`), KEY `player_id` (`player_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8]])
	db.query([[CREATE TABLE IF NOT EXISTS `pkd_market_locker` (
		`id` INT NOT NULL AUTO_INCREMENT, `player_id` INT NOT NULL, `itemid` INT NOT NULL, `count` INT NOT NULL,
		`special` TEXT NOT NULL, `name` VARCHAR(255) NOT NULL, `reason` VARCHAR(255) NOT NULL, `created` INT NOT NULL,
		PRIMARY KEY (`id`), KEY `player_id` (`player_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8]])
	pokeMarketTablesReady = true
end

local function readAll(query, columns)
	local list = {}
	local resultId = db.storeQuery(query)
	if not resultId then
		return list
	end
	repeat
		local row = {}
		for name, kind in pairs(columns) do
			if kind == "s" then
				row[name] = result.getString(resultId, name)
			else
				row[name] = result.getNumber(resultId, name)
			end
		end
		list[#list + 1] = row
	until not result.next(resultId)
	result.free(resultId)
	return list
end

-- ===================== Tiendas (donde se puede usar) =====================
local shopPositions

local function loadShops()
	shopPositions = {}
	local file = io.open("data/world/map-spawn.xml", "r")
	if not file then
		return
	end
	local cx, cy, cz = 0, 0, 7
	for line in file:lines() do
		local sx, sy, sz = line:match('<spawn%s+centerx="(%d+)"%s+centery="(%d+)"%s+centerz="(%d+)"')
		if sx then
			cx, cy, cz = tonumber(sx), tonumber(sy), tonumber(sz)
		end
		local name, x, y = line:match('<npc%s+name="([^"]+)"%s+x="(%-?%d+)"%s+y="(%-?%d+)"')
		if name and name:lower() == "mark" then
			shopPositions[#shopPositions + 1] = {x = cx + tonumber(x), y = cy + tonumber(y), z = cz}
		end
	end
	file:close()
end

local function nearShop(player)
	if player:getGroup():getAccess() then
		return true
	end
	if not shopPositions then
		loadShops()
	end
	local pos = player:getPosition()
	for _, shop in ipairs(shopPositions) do
		if shop.z == pos.z and math.abs(shop.x - pos.x) <= pokeMarket.shopRadius and math.abs(shop.y - pos.y) <= pokeMarket.shopRadius then
			return true
		end
	end
	return false
end

-- ===================== Objetos =====================
local badgeIds

local function isBadge(itemId)
	if not badgeIds then
		badgeIds = {}
		for _, quest in pairs(quests or {}) do
			for _, prize in ipairs(quest.prizes or {}) do
				for _, badge in ipairs(prize.badges or {}) do
					if badge.add then badgeIds[badge.add] = true end
					if badge.remove then badgeIds[badge.remove] = true end
				end
			end
		end
	end
	return badgeIds[itemId] == true
end

local emptyBallIds, pokemonOutBallIds

local function loadBallIds()
	emptyBallIds, pokemonOutBallIds = {}, {}
	for _, ball in pairs(balls or {}) do
		emptyBallIds[ball.emptyId] = true
		pokemonOutBallIds[ball.usedOff] = true
	end
end

local function specialOf(item)
	if item:hasAttribute(ITEM_ATTRIBUTE_SPECIAL) then
		return item:getAttribute(ITEM_ATTRIBUTE_SPECIAL) or ""
	end
	return ""
end

local function titleCase(text)
	return (text:gsub("(%a)([%w']*)", function(first, rest) return first:upper() .. rest end))
end

-- nombre, categoria y Pokemon (para el icono) de un objeto
local function describe(itemId, special, pokeName, boost)
	if not emptyBallIds then
		loadBallIds()
	end
	if pokeName and pokeName ~= "" then
		local name = pokeName .. ((boost or 0) > 0 and (" +" .. boost) or "")
		return name, "pokemon", pokeName
	end
	local itemName = titleCase(ItemType(itemId):getName())
	local lower = itemName:lower()
	local category = "otros"
	if emptyBallIds[itemId] then
		category = "balls"
	elseif lower:find("stone", 1, true) then
		category = "stones"
	elseif lower:find("potion", 1, true) or lower:find("revive", 1, true) or lower:find("elixir", 1, true) then
		category = "potions"
	end
	return itemName, category, ""
end

local function describeItem(item)
	return describe(item:getId(), specialOf(item), item:getSpecialAttribute("pokeName"), tonumber(item:getSpecialAttribute("pokeBoost")) or 0)
end

-- objetos que se pueden vender: mochila (y lo que tenga dentro) y cinturon de Pokemon
local function sellableItems(player)
	if not emptyBallIds then
		loadBallIds()
	end
	local list = {}
	local function walk(container, depth)
		if depth > 10 then return end
		for slot = 0, container:getSize() - 1 do
			local item = container:getItem(slot)
			if item then
				if item:isContainer() then
					walk(item, depth + 1)
				else
					local itemType = ItemType(item:getId())
					local inUse = item:getSpecialAttribute("isBeingUsed") == 1 or pokemonOutBallIds[item:getId()]
					if itemType:isMovable() and itemType:isPickupable() and not isBadge(item:getId()) and not inUse
						and not COIN_VALUES[item:getId()] then
						local name, category, icon = describeItem(item)
						list[#list + 1] = {itemid = item:getId(), count = math.max(1, item:getCount()), special = specialOf(item),
							name = name, category = category, icon = icon}
					end
				end
			end
		end
	end
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if backpack and backpack:isContainer() then
		walk(backpack, 0)
	end
	local belt = player.getPokemonBelt and player:getPokemonBelt()
	if belt then
		walk(belt, 0)
	end
	return list
end

-- busca en el inventario un objeto igual (id + atributos) con al menos esa cantidad
local function findItem(player, itemId, special, count)
	local found
	local function walk(container, depth)
		if found or depth > 10 then return end
		for slot = 0, container:getSize() - 1 do
			local item = container:getItem(slot)
			if item then
				if item:isContainer() then
					walk(item, depth + 1)
				elseif item:getId() == itemId and specialOf(item) == special and math.max(1, item:getCount()) >= count
					and item:getSpecialAttribute("isBeingUsed") ~= 1 then
					found = item
					return
				end
			end
			if found then return end
		end
	end
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if backpack and backpack:isContainer() then walk(backpack, 0) end
	local belt = player.getPokemonBelt and player:getPokemonBelt()
	if belt and not found then walk(belt, 0) end
	return found
end

local function formatMoney(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return "$" .. formatted:gsub("^%.", "")
end

local function refreshPokemon(player)
	if player.refreshPokemonBar then
		pcall(player.refreshPokemonBar, player, {}, {})
	end
end

-- ===================== Envio al cliente =====================
local function send(player, kind, header, lines)
	local out = {kind .. SEP .. table.concat(header or {}, SEP)}
	for _, line in ipairs(lines or {}) do
		out[#out + 1] = table.concat(line, SEP)
	end
	player:sendExtendedOpcode(OPCODE_MARKET, table.concat(out, "\n"))
end

local function sendMessage(player, text, ok)
	send(player, "msg", {ok and 1 or 0, clean(text)})
end

local function clientId(itemId)
	return ItemType(itemId):getClientId()
end

local function timeLeft(created)
	local left = math.max(0, created + pokeMarket.duration - os.time())
	local days = math.floor(left / 86400)
	local hours = math.floor((left % 86400) / 3600)
	if days > 0 then
		return days .. "d " .. hours .. "h"
	end
	return hours .. "h " .. math.floor((left % 3600) / 60) .. "m"
end

local lastExpireCheck = 0
local function expireOffers()
	local now = os.time()
	if now - lastExpireCheck < 60 then
		return
	end
	lastExpireCheck = now
	local old = readAll("SELECT `id`, `player_id`, `itemid`, `count`, `special`, `name` FROM `pkd_market_offers` WHERE `created` < " ..
		(now - pokeMarket.duration), {id = "n", player_id = "n", itemid = "n", count = "n", special = "s", name = "s"})
	for _, offer in ipairs(old) do
		db.query("DELETE FROM `pkd_market_offers` WHERE `id` = " .. offer.id)
		db.query("INSERT INTO `pkd_market_locker` (`player_id`, `itemid`, `count`, `special`, `name`, `reason`, `created`) VALUES (" ..
			offer.player_id .. ", " .. offer.itemid .. ", " .. offer.count .. ", " .. db.escapeString(offer.special) .. ", " ..
			db.escapeString(offer.name) .. ", 'Oferta caducada', " .. now .. ")")
	end
end

local function lockerCount(player)
	local resultId = db.storeQuery("SELECT COUNT(*) AS `n` FROM `pkd_market_locker` WHERE `player_id` = " .. player:getGuid())
	local n = 0
	if resultId then
		n = result.getNumber(resultId, "n")
		result.free(resultId)
	end
	return n
end

local function validCategory(category)
	for _, c in ipairs(pokeMarket.categories) do
		if c == category then return true end
	end
	return false
end

function Player.sendMarketList(self, category, page, search)
	ensureTables()
	expireOffers()
	category = validCategory(category) and category or "todo"
	search = clean(search or ""):sub(1, 30)
	local where = {}
	if category ~= "todo" then
		where[#where + 1] = "`category` = " .. db.escapeString(category)
	end
	if search ~= "" then
		where[#where + 1] = "`name` LIKE " .. db.escapeString("%" .. search:gsub("[%%_]", "") .. "%")
	end
	local whereSql = #where > 0 and (" WHERE " .. table.concat(where, " AND ")) or ""
	local total = 0
	local resultId = db.storeQuery("SELECT COUNT(*) AS `n` FROM `pkd_market_offers`" .. whereSql)
	if resultId then
		total = result.getNumber(resultId, "n")
		result.free(resultId)
	end
	local pages = math.max(1, math.ceil(total / pokeMarket.pageSize))
	page = math.min(math.max(1, tonumber(page) or 1), pages)
	local offers = readAll("SELECT `id`, `player_id`, `player_name`, `itemid`, `count`, `special`, `name`, `category`, `price`, `created` FROM `pkd_market_offers`" ..
		whereSql .. " ORDER BY `created` DESC LIMIT " .. pokeMarket.pageSize .. " OFFSET " .. ((page - 1) * pokeMarket.pageSize),
		{id = "n", player_id = "n", player_name = "s", itemid = "n", count = "n", special = "s", name = "s", category = "s", price = "n", created = "n"})
	local lines = {}
	for _, o in ipairs(offers) do
		local icon = o.category == "pokemon" and (o.name:match("^(.-) %+%d+$") or o.name) or ""
		lines[#lines + 1] = {o.id, clientId(o.itemid), clean(o.name), clean(o.player_name), o.count, o.price,
			timeLeft(o.created), o.category, clean(icon), o.player_id == self:getGuid() and 1 or 0}
	end
	send(self, "list", {category, page, pages, total, self:getBankBalance(), lockerCount(self), clean(search)}, lines)
end

local marketSnapshots = {}

function Player.sendMarketInventory(self)
	local items = sellableItems(self)
	marketSnapshots[self:getGuid()] = items
	local lines = {}
	for index, item in ipairs(items) do
		lines[#lines + 1] = {index, clientId(item.itemid), clean(item.name), item.count, item.category, clean(item.icon)}
	end
	send(self, "inv", {self:getBankBalance(), pokeMarket.tax}, lines)
end

function Player.sendMarketOwnOffers(self)
	ensureTables()
	expireOffers()
	local offers = readAll("SELECT `id`, `itemid`, `count`, `name`, `category`, `price`, `created` FROM `pkd_market_offers` WHERE `player_id` = " ..
		self:getGuid() .. " ORDER BY `created` DESC", {id = "n", itemid = "n", count = "n", name = "s", category = "s", price = "n", created = "n"})
	local lines = {}
	for _, o in ipairs(offers) do
		local icon = o.category == "pokemon" and (o.name:match("^(.-) %+%d+$") or o.name) or ""
		lines[#lines + 1] = {o.id, clientId(o.itemid), clean(o.name), o.count, o.price, timeLeft(o.created), clean(icon)}
	end
	send(self, "mine", {#offers, pokeMarket.maxOffers}, lines)
end

function Player.sendMarketLocker(self)
	ensureTables()
	expireOffers()
	local items = readAll("SELECT `id`, `itemid`, `count`, `name`, `reason`, `created` FROM `pkd_market_locker` WHERE `player_id` = " ..
		self:getGuid() .. " ORDER BY `created` DESC LIMIT 100", {id = "n", itemid = "n", count = "n", name = "s", reason = "s", created = "n"})
	local lines = {}
	for _, l in ipairs(items) do
		lines[#lines + 1] = {l.id, l.itemid > 0 and clientId(l.itemid) or 0, clean(l.name), l.count, clean(l.reason),
			os.date("%d/%m %H:%M", l.created)}
	end
	send(self, "locker", {#items}, lines)
end

-- ===================== Acciones =====================
local function marketSell(player, index, count, price)
	local snapshot = marketSnapshots[player:getGuid()]
	local entry = snapshot and snapshot[index]
	if not entry then
		return sendMessage(player, "Ese objeto ya no esta. Vuelve a abrir la pestana Vender.")
	end
	count = math.floor(tonumber(count) or 0)
	price = math.floor(tonumber(price) or 0)
	if count < 1 or count > entry.count then
		return sendMessage(player, "Cantidad no valida (maximo " .. entry.count .. ").")
	end
	if price < 1 or price > pokeMarket.maxPrice then
		return sendMessage(player, "Precio no valido.")
	end
	local resultId = db.storeQuery("SELECT COUNT(*) AS `n` FROM `pkd_market_offers` WHERE `player_id` = " .. player:getGuid())
	local current = 0
	if resultId then
		current = result.getNumber(resultId, "n")
		result.free(resultId)
	end
	if current >= pokeMarket.maxOffers then
		return sendMessage(player, "Ya tienes " .. pokeMarket.maxOffers .. " ofertas. Cancela alguna para poner otra.")
	end
	local item = findItem(player, entry.itemid, entry.special, count)
	if not item then
		return sendMessage(player, "No encuentro ese objeto en tu mochila. Vuelve a abrir la pestana Vender.")
	end
	local isPokemon = entry.category == "pokemon"
	if not item:remove(count) then
		return sendMessage(player, "No se ha podido quitar el objeto.")
	end
	db.query("INSERT INTO `pkd_market_offers` (`player_id`, `player_name`, `itemid`, `count`, `special`, `name`, `category`, `price`, `created`) VALUES (" ..
		player:getGuid() .. ", " .. db.escapeString(player:getName()) .. ", " .. entry.itemid .. ", " .. count .. ", " ..
		db.escapeString(entry.special) .. ", " .. db.escapeString(entry.name) .. ", " .. db.escapeString(entry.category) .. ", " ..
		price .. ", " .. os.time() .. ")")
	if isPokemon then
		refreshPokemon(player)
	end
	sendMessage(player, "Has puesto a la venta " .. count .. "x " .. entry.name .. " a " .. formatMoney(price) .. " cada uno.", true)
	player:sendMarketInventory()
end

local function payOwner(sellerId, sellerName, amount, text)
	local seller = Player(sellerName)
	if seller and seller:getGuid() == sellerId then
		seller:addMoney(amount)
		seller:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Mercado] " .. text)
	else
		db.query("UPDATE `players` SET `balance` = `balance` + " .. amount .. " WHERE `id` = " .. sellerId)
	end
	db.query("INSERT INTO `pkd_market_locker` (`player_id`, `itemid`, `count`, `special`, `name`, `reason`, `created`) VALUES (" ..
		sellerId .. ", 0, 0, '', " .. db.escapeString(text) .. ", 'Venta', " .. os.time() .. ")")
end

local function marketBuy(player, offerId, count)
	ensureTables()
	local offer = readAll("SELECT `id`, `player_id`, `player_name`, `itemid`, `count`, `special`, `name`, `category`, `price` FROM `pkd_market_offers` WHERE `id` = " ..
		math.floor(tonumber(offerId) or 0), {id = "n", player_id = "n", player_name = "s", itemid = "n", count = "n", special = "s", name = "s", category = "s", price = "n"})[1]
	if not offer then
		return sendMessage(player, "Esa oferta ya no existe: alguien se ha adelantado.")
	end
	if offer.player_id == player:getGuid() then
		return sendMessage(player, "No puedes comprar tu propia oferta. Cancelala en Mis ofertas.")
	end
	count = math.floor(tonumber(count) or offer.count)
	if count < 1 or count > offer.count then
		count = offer.count
	end
	if offer.category == "pokemon" then
		count = offer.count
	end
	local total = offer.price * count
	if not player:removeMoney(total) then
		return sendMessage(player, "No tienes " .. formatMoney(total) .. " en el banco.")
	end
	if count == offer.count then
		db.query("DELETE FROM `pkd_market_offers` WHERE `id` = " .. offer.id)
	else
		db.query("UPDATE `pkd_market_offers` SET `count` = `count` - " .. count .. " WHERE `id` = " .. offer.id)
	end
	db.query("INSERT INTO `pkd_market_locker` (`player_id`, `itemid`, `count`, `special`, `name`, `reason`, `created`) VALUES (" ..
		player:getGuid() .. ", " .. offer.itemid .. ", " .. count .. ", " .. db.escapeString(offer.special) .. ", " ..
		db.escapeString(offer.name) .. ", " .. db.escapeString("Comprado a " .. offer.player_name) .. ", " .. os.time() .. ")")
	local net = math.floor(total * (1 - pokeMarket.tax))
	payOwner(offer.player_id, offer.player_name, net, "Vendido " .. count .. "x " .. offer.name .. " a " .. player:getName() ..
		": " .. formatMoney(net) .. " ingresados en tu banco")
	sendMessage(player, "Has comprado " .. count .. "x " .. offer.name .. " por " .. formatMoney(total) .. ". Lo tienes en Recibidos.", true)
end

local function marketCancel(player, offerId)
	ensureTables()
	local offer = readAll("SELECT `id`, `itemid`, `count`, `special`, `name` FROM `pkd_market_offers` WHERE `id` = " ..
		math.floor(tonumber(offerId) or 0) .. " AND `player_id` = " .. player:getGuid(),
		{id = "n", itemid = "n", count = "n", special = "s", name = "s"})[1]
	if not offer then
		return sendMessage(player, "Esa oferta ya no existe (puede que se haya vendido).")
	end
	db.query("DELETE FROM `pkd_market_offers` WHERE `id` = " .. offer.id)
	db.query("INSERT INTO `pkd_market_locker` (`player_id`, `itemid`, `count`, `special`, `name`, `reason`, `created`) VALUES (" ..
		player:getGuid() .. ", " .. offer.itemid .. ", " .. offer.count .. ", " .. db.escapeString(offer.special) .. ", " ..
		db.escapeString(offer.name) .. ", 'Oferta cancelada', " .. os.time() .. ")")
	sendMessage(player, "Oferta cancelada. " .. offer.name .. " esta en Recibidos.", true)
	player:sendMarketOwnOffers()
end

local function takeOne(player, entry)
	if entry.itemid == 0 then
		db.query("DELETE FROM `pkd_market_locker` WHERE `id` = " .. entry.id)
		return true
	end
	local item = player:addItem(entry.itemid, entry.count, false)
	if not item then
		return false
	end
	if entry.special ~= "" then
		item:setAttribute(ITEM_ATTRIBUTE_SPECIAL, entry.special)
	end
	db.query("DELETE FROM `pkd_market_locker` WHERE `id` = " .. entry.id)
	return true
end

local function marketTake(player, which)
	ensureTables()
	local filter = which == "all" and "" or (" AND `id` = " .. math.floor(tonumber(which) or 0))
	local entries = readAll("SELECT `id`, `itemid`, `count`, `special`, `name` FROM `pkd_market_locker` WHERE `player_id` = " ..
		player:getGuid() .. filter .. " ORDER BY `created` ASC LIMIT 100", {id = "n", itemid = "n", count = "n", special = "s", name = "s"})
	local taken, failed, pokemon = 0, 0, false
	for _, entry in ipairs(entries) do
		if takeOne(player, entry) then
			if entry.itemid > 0 then
				taken = taken + 1
				pokemon = pokemon or entry.special:find("pokeName", 1, true) ~= nil
			end
		else
			failed = failed + 1
		end
	end
	if pokemon then
		refreshPokemon(player)
	end
	if failed > 0 then
		sendMessage(player, "Has recogido " .. taken .. ". No te caben " .. failed .. ": haz sitio en la mochila.")
	elseif taken > 0 then
		sendMessage(player, "Has recogido " .. taken .. (taken == 1 and " objeto." or " objetos."), true)
	end
	player:sendMarketLocker()
end

-- ===================== Peticiones del cliente =====================
function onPokeMarketRequest(player, param)
	ensureTables()
	local words = {}
	for word in (param or ""):gmatch("%S+") do
		words[#words + 1] = word
	end
	local action = (words[1] or ""):lower()
	if action ~= "list" and action ~= "mine" and action ~= "locker" and not nearShop(player) then
		send(player, "away", {clean("El mercado solo se puede usar en una tienda (el icono de la bolsa en el mapa).")})
		return
	end
	if action == "open" or action == "list" then
		player:sendMarketList(words[2], words[3], table.concat(words, " ", 4))
	elseif action == "buy" then
		marketBuy(player, words[2], words[3])
		player:sendMarketList(words[4], words[5], table.concat(words, " ", 6))
	elseif action == "inv" then
		player:sendMarketInventory()
	elseif action == "sell" then
		marketSell(player, tonumber(words[2]), words[3], words[4])
	elseif action == "mine" then
		player:sendMarketOwnOffers()
	elseif action == "cancel" then
		marketCancel(player, words[2])
	elseif action == "locker" then
		player:sendMarketLocker()
	elseif action == "take" then
		marketTake(player, words[2])
	end
end
