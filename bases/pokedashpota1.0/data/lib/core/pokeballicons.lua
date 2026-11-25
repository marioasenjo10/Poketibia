-- Iconos de pokemon en las pokeballs (cliente: game_containers/pokeballicons.lua).
-- Lo llama cada segundo el creaturescript PokeballIcons (think) y, al mover un objeto,
-- Player:onItemMoved (para que el dibujo no tarde en ponerse en su sitio). Cada segundo mira las mochilas que el jugador tiene abiertas y, si algo cambio desde el
-- ultimo envio, manda el opcode 72 con una entrada por pokeball:
--   "idContenedor:casilla:idObjetoCliente:nombre:debilitado(0/1);..."
-- (el id de contenedor es el mismo que usa el cliente para sus ventanas de mochila)
--
-- Tambien manda (opcode 73) cuantos objetos de cada tipo lleva el jugador en total, contando
-- mochilas cerradas: "idObjetoCliente:cantidad;..." para las casillas 1-0 de la barra de abajo.

local OPCODE_BALL_ICONS = 72
local OPCODE_ITEM_COUNTS = 73
local MAX_CONTAINERS = 16

pokeballIconsSent = pokeballIconsSent or {}
itemCountsSent = itemCountsSent or {}

local function addCount(counts, item)
	local clientId = ItemType(item:getId()):getClientId()
	counts[clientId] = (counts[clientId] or 0) + math.max(1, item:getCount())
end

-- recorre un contenedor y los que tenga dentro (este servidor no tiene container:getItems)
local function countContainer(counts, container, depth)
	if depth > 10 then return end
	for slot = 0, container:getSize() - 1 do
		local item = container:getItem(slot)
		if item then
			addCount(counts, item)
			if item:isContainer() then
				countContainer(counts, item, depth + 1)
			end
		end
	end
end

function Player.sendItemCounts(player)
	local counts = {}
	for slot = 1, 10 do -- casillas del equipo (cabeza ... municion)
		local item = player:getSlotItem(slot)
		if item then
			addCount(counts, item)
			if item:isContainer() then
				countContainer(counts, item, 1)
			end
		end
	end
	local ids = {}
	for clientId in pairs(counts) do
		ids[#ids + 1] = clientId
	end
	table.sort(ids)
	local parts = {}
	for _, clientId in ipairs(ids) do
		parts[#parts + 1] = clientId .. ":" .. counts[clientId]
	end
	local data = table.concat(parts, ";")
	local id = player:getId()
	if itemCountsSent[id] ~= data then
		itemCountsSent[id] = data
		player:sendExtendedOpcode(OPCODE_ITEM_COUNTS, data)
	end
end

function Player.sendPokeballIcons(player)
	local parts = {}
	for cid = 0, MAX_CONTAINERS - 1 do
		local container = player:getContainerById(cid)
		if container then
			for slot = 0, container:getSize() - 1 do
				local item = container:getItem(slot)
				if item and item:isPokeball() then
					local name = item:getSpecialAttribute("pokeName")
					if name then
						local health = tonumber(item:getSpecialAttribute("pokeHealth")) or 0
						-- id de cliente: el cliente compara con el objeto que tiene en esa casilla
						local clientId = ItemType(item:getId()):getClientId()
						parts[#parts + 1] = cid .. ":" .. slot .. ":" .. clientId .. ":" .. name .. ":" .. (health <= 0 and 1 or 0)
					end
				elseif item and shinyOrbByItemId and shinyOrbByItemId[item:getId()] then
					-- orbe de evolucion shiny: el cliente dibuja el holograma de su destino (ultimo campo = 2)
					local evoTarget = item:getSpecialAttribute("evoTarget")
					if evoTarget then
						parts[#parts + 1] = cid .. ":" .. slot .. ":" .. ItemType(item:getId()):getClientId() .. ":" .. evoTarget .. ":2"
					end
				end
			end
		end
	end

	local data = table.concat(parts, ";")
	local id = player:getId()
	if pokeballIconsSent[id] ~= data then
		pokeballIconsSent[id] = data
		player:sendExtendedOpcode(OPCODE_BALL_ICONS, data)
	end
end
