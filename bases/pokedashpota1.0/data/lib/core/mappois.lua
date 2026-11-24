-- Puntos de interes del mapa (cliente: game_minimap): Centros Pokemon y tiendas.
-- Se leen una vez de las posiciones de los NPC en el archivo de spawns del mapa y se mandan al
-- entrar (opcode 74): "tipo:x:y:z;..." con tipo c = Centro Pokemon, s = tienda.

local OPCODE_MAP_POIS = 74
local SPAWN_FILE = "data/world/map-spawn.xml"

-- nombre del NPC (en minusculas) -> tipo de icono
local POI_NPCS = {
	["nurse"] = "c", -- la enfermera que cura
	["mark"] = "s",  -- el tendero (pokeballs, pociones...)
}

local mapPoisData = nil

local function loadMapPois()
	local file = io.open(SPAWN_FILE, "r")
	if not file then
		print("WARNING! Map POIs: cannot open " .. SPAWN_FILE)
		return ""
	end
	local parts = {}
	local cx, cy = 0, 0
	for line in file:lines() do
		local sx, sy = line:match('<spawn%s+centerx="(%d+)"%s+centery="(%d+)"')
		if sx then
			cx, cy = tonumber(sx), tonumber(sy)
		end
		local name, x, y, z = line:match('<npc%s+name="([^"]+)"%s+x="(%-?%d+)"%s+y="(%-?%d+)"%s+z="(%d+)"')
		if name then
			local kind = POI_NPCS[name:lower()]
			if kind then
				parts[#parts + 1] = kind .. ":" .. (cx + tonumber(x)) .. ":" .. (cy + tonumber(y)) .. ":" .. z
			end
		end
	end
	file:close()
	return table.concat(parts, ";")
end

function Player.sendMapPois(self)
	if not mapPoisData then
		mapPoisData = loadMapPois()
	end
	self:sendExtendedOpcode(OPCODE_MAP_POIS, mapPoisData)
end
