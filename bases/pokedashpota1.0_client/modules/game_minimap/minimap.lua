minimapWidget = nil
minimapButton = nil
minimapWindow = nil
otmm = true
preloaded = false
fullmapView = false
oldZoom = nil
oldPos = nil

OPCODE_TOWNS = 63
WORLD_MAP_FILE = '/game_minimap/world.otmm'  -- mapa entero generado en casa (comandos-casa.ps1)
WORLD_CHUNKS_DIR = '/game_minimap/world/'    -- mapa grande suavizado en trozos (tools/pokeassets/Minimap.cs)
WORLD_CHUNKS_MIN_SCALE = 2                   -- con menos zoom no se notan los cuadraditos
townLabels = {}
pokedexFlags = {}
OPCODE_MAP_POIS = 74 -- Centros Pokemon y tiendas (servidor: lib/core/mappois.lua)
mapPois = {}
POI_MIN_SCALE = 1    -- con el mapa mas alejado no se ven (serian puntitos encima de todo)
worldChunks = {}
worldChunkCount = 0
local worldIndex = nil
local worldChunkSize = 255

function init()
  minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton', 
    tr('Minimap'), '/images/topbuttons/minimap', toggle)
  minimapButton:setOn(true)
  worldMapButton = modules.client_topmenu.addRightGameButton('worldMapButton', 'Mapa (Ctrl+Tab)',
    '/images/topmenu/map', toggleFullMap)

  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getRightPanel())
  minimapWindow:setContentMinimumHeight(64)

  minimapWidget = minimapWindow:recursiveGetChildById('minimap')
  minimapWidget:setClipping(true)

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0,1) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0,-1) end, gameRootPanel)
  -- sin Ctrl+M (choca con andar en WASD): g_keyboard.bindKeyDown('Ctrl+M', toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+M', toggleFullMap)
  g_keyboard.bindKeyDown('Ctrl+Tab', toggleFullMap)
  g_keyboard.bindKeyDown('Escape', closeFullMap, gameRootPanel)
  ProtocolGame.registerExtendedOpcode(OPCODE_TOWNS, onTownsOpcode)
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_MAP_POIS)
  ProtocolGame.registerExtendedOpcode(OPCODE_MAP_POIS, onMapPoisOpcode)

  minimapWindow:setup()

  -- marcas de la pokedex y ciudades: solo se ven en su piso
  minimapWidget.onCameraPositionChange = function(widget, cameraPos, oldPos)
    UIMinimap.onCameraPositionChange(widget, cameraPos, oldPos)
    updateOverlayFloors()
  end
  minimapWidget.onZoomChange = function(widget, zoom)
    UIMinimap.onZoomChange(widget, zoom)
    updateOverlayFloors()
  end

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  connect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  if g_game.isOnline() then
    saveMap()
  end

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyPress('Alt+Left', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Right', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Up', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Down', gameRootPanel)
  -- sin Ctrl+M (choca con andar en WASD): g_keyboard.unbindKeyDown('Ctrl+M')
  g_keyboard.unbindKeyDown('Ctrl+Shift+M')
  g_keyboard.unbindKeyDown('Ctrl+Tab')
  g_keyboard.unbindKeyDown('Escape', gameRootPanel)
  ProtocolGame.unregisterExtendedOpcode(OPCODE_TOWNS)
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_MAP_POIS)
  clearMapPois()
  clearPokedexFlags()
  clearTownLabels()
  clearWorldChunks()

  minimapWindow:destroy()
  minimapButton:destroy()
  worldMapButton:destroy()
end

function toggle()
  if minimapButton:isOn() then
    minimapWindow:close()
    minimapButton:setOn(false)
  else
    minimapWindow:open()
    minimapButton:setOn(true)
  end
end

function onMiniWindowClose()
  minimapButton:setOn(false)
end

function preload()
  loadMap(false)
  preloaded = true
end

function online()
  loadMap(not preloaded)
  updateCameraPosition()
end

function offline()
  clearMapPois()
  if fullmapView then
    toggleFullMap()
  end
  clearPokedexFlags()
  saveMap()
end

function loadMap(clean)
  local clientVersion = g_game.getClientVersion()

  if clean then
    g_minimap.clean()
  end

  if otmm then
    local minimapFile = '/minimap.otmm'
    if g_resources.fileExists(minimapFile) then
      g_minimap.loadOtmm(minimapFile)
    end
    -- despues el mapa entero, para que se vean todas las ciudades aunque no hayas ido
    if g_resources.fileExists(WORLD_MAP_FILE) then
      g_minimap.loadOtmm(WORLD_MAP_FILE)
    end
  else
    local minimapFile = '/minimap_' .. clientVersion .. '.otcm'
    if g_resources.fileExists(minimapFile) then
      g_map.loadOtcm(minimapFile)
    end
  end
  minimapWidget:load()
end

function saveMap()
  local clientVersion = g_game.getClientVersion()
  if otmm then
    local minimapFile = '/minimap.otmm'
    g_minimap.saveOtmm(minimapFile)
  else
    local minimapFile = '/minimap_' .. clientVersion .. '.otcm'
    g_map.saveOtcm(minimapFile)
  end
  minimapWidget:save()
end

function updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end
  if not minimapWidget:isDragging() then
    if not fullmapView then
      minimapWidget:setCameraPosition(player:getPosition())
    end
    minimapWidget:setCrossPosition(player:getPosition())
  end
end

function toggleFullMap()
  if not fullmapView then
    fullmapView = true
    minimapWindow:hide()
    minimapWidget:setParent(modules.game_interface.getRootPanel())
    minimapWidget:fill('parent')
    minimapWidget:setAlternativeWidgetsVisible(true)
  else
    fullmapView = false
    minimapWidget:setParent(minimapWindow:getChildById('contentsPanel'))
    minimapWidget:fill('parent')
    minimapWindow:show()
    minimapWidget:setAlternativeWidgetsVisible(false)
  end

  -- al abrir o cerrar el mapa grande, siempre centrado en el jugador y en su planta
  local zoom = oldZoom or 0
  local player = g_game.getLocalPlayer()
  local pos = player and player:getPosition() or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  minimapWidget:setZoom(zoom)
  minimapWidget:setCameraPosition(pos)

  if not fullmapView then
    clearPokedexFlags()
  end
  updateOverlayFloors()
end

function closeFullMap()
  if fullmapView then
    toggleFullMap()
  end
end

-- ===== Nombres de las ciudades en el mapa grande (el servidor los manda al entrar) =====

function clearTownLabels()
  for _, label in ipairs(townLabels) do
    table.removevalue(minimapWidget.alternatives, label)
    label:destroy()
  end
  townLabels = {}
end

local TOWN_FONT = 'poppins-semibold-11px'
local TOWN_COLOR = '#ffffff'
local TOWN_COLOR_HIDDEN = '#aeb6c2'
local TOWN_COLOR_HOVER = '#ffd84a'

-- nombre de ciudad en una pastilla oscura (legible sobre cualquier zona del mapa):
-- descubierta = pokeball y texto blanco; sin descubrir = candado y texto gris claro
-- La pastilla va en la parte de arriba de un contenedor transparente mas alto: el contenedor
-- se centra en la ciudad, asi la pastilla queda por encima y no tapa tu posicion.
local TOWN_LIFT = 20 -- pixeles que sube la pastilla respecto al punto de la ciudad
local function createTownLabel(name, discovered)
  local holder = g_ui.createWidget('UIWidget')
  holder:setFocusable(false)
  holder:setPhantom(true)

  local widget = g_ui.createWidget('UIWidget', holder)
  widget:setFocusable(false)
  widget:setImageSource('/images/map/town_pill')
  widget:setImageBorder(12)
  widget:addAnchor(AnchorTop, 'parent', AnchorTop)
  widget:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
  holder.pill = widget

  local icon = g_ui.createWidget('UIWidget', widget)
  icon:setSize({ width = 14, height = 14 })
  icon:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  icon:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  icon:setMarginLeft(7)
  icon:setImageSource(discovered and '/images/statusbar/ownmon_on' or '/images/statusbar/lock')
  if not discovered then icon:setImageColor('#aeb6c2') end
  icon:setPhantom(true)

  local text = g_ui.createWidget('UIWidget', widget)
  text:setFont(TOWN_FONT)
  text:setText(name)
  text:setColor(discovered and TOWN_COLOR or TOWN_COLOR_HIDDEN)
  text:setTextAlign(AlignLeftCenter)
  text:setTextOffset({ x = 0, y = 1 })
  text:setPhantom(true)
  local textWidth = text:getTextSize().width
  text:setSize({ width = textWidth + 2, height = 24 })
  text:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  text:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  text:setMarginLeft(26)

  widget:setSize({ width = 26 + textWidth + 11, height = 24 })
  holder:setSize({ width = 26 + textWidth + 11, height = 24 + TOWN_LIFT * 2 })
  widget.onHoverChange = function(_, hovered)
    widget:setImageSource(hovered and '/images/map/town_pill_hover' or '/images/map/town_pill')
    text:setColor(hovered and TOWN_COLOR_HOVER or (discovered and TOWN_COLOR or TOWN_COLOR_HIDDEN))
  end
  return holder
end

function onTownsOpcode(protocol, opcode, buffer)
  clearTownLabels()
  for entry in buffer:gmatch('[^;]+') do
    local name, x, y, z, flag = entry:match('^(.-):(%d+):(%d+):(%d+):?(%d*)$')
    if name and name ~= '' then
      local discovered = flag ~= '0'
      local label = createTownLabel(name, discovered)
      -- ayuda y clic en la pastilla (el contenedor deja pasar el raton)
      if discovered then
        label.pill:setTooltip(name .. '\nClic: teletransportarse (necesitas un pokemon con Teleport, como Abra o Alakazam)')
      else
        label.pill:setTooltip(name .. '\nAun no has descubierto esta ciudad.\nHabla con la enfermera Joy de ' .. name .. ' para desbloquear el teletransporte.')
      end
      label.pill.onClick = function(widget) askTeleport(name, widget, discovered) end
      minimapWidget:addAlternativeWidget(label, { x = tonumber(x), y = tonumber(y), z = tonumber(z) }, -100)
      table.insert(townLabels, label)
      if fullmapView then
        minimapWidget:insertChild(worldChunkCount + 1, label)
        minimapWidget:centerInPosition(label, label.pos)
      end
    end
  end
  updateOverlayFloors()
end

function askTeleport(townName, widget, discovered)
  if discovered == false then
    modules.game_textmessage.displayFailureMessage('Aun no has descubierto ' .. townName .. '. Habla con su enfermera Joy para poder teletransportarte.')
    return
  end
  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)
  menu:addOption('Teletransportarse a ' .. townName, function()
    g_game.talk('!teleport ' .. townName)
    closeFullMap()
  end)
  menu:display(g_window.getMousePosition())
end

-- ===== Iconos de Centro Pokemon y tienda (minimapa y mapa grande) =====
-- Van como hijos del minimapa, igual que las marcas del jugador: el propio minimapa los
-- mueve al desplazarse, tanto en la ventana como en el mapa grande.

local POI_INFO = {
  c = { icon = '/images/map/poi_center', name = 'Centro Pok\233mon' },
  s = { icon = '/images/map/poi_shop', name = 'Tienda' },
}

function clearMapPois()
  for _, poi in ipairs(mapPois) do
    poi:destroy()
  end
  mapPois = {}
end

function onMapPoisOpcode(protocol, opcode, buffer)
  clearMapPois()
  for entry in buffer:gmatch('[^;]+') do
    local kind, x, y, z = entry:match('^(%a):(%d+):(%d+):(%d+)$')
    local info = kind and POI_INFO[kind]
    if info then
      local poi = g_ui.createWidget('UIWidget')
      poi:setSize({ width = 16, height = 16 })
      poi:setImageSource(info.icon)
      poi:setTooltip(info.name)
      poi:setFocusable(false)
      poi.pos = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
      minimapWidget:insertChild(worldChunkCount + 1, poi)
      minimapWidget:centerInPosition(poi, poi.pos)
      table.insert(mapPois, poi)
    end
  end
  updateOverlayFloors()
end

-- muestra cada marca/ciudad solo en su piso (el mapa no las oculta solo)
function updateOverlayFloors()
  if not minimapWidget then return end
  local z = minimapWidget:getCameraPosition().z
  local zoom = minimapWidget:getZoom()
  for _, label in ipairs(townLabels) do
    if label.pos then
      local zoomOk = (not label.minZoom or label.minZoom >= zoom) and (label.maxZoom or 0) <= zoom
      label:setVisible(zoomOk and label.pos.z == z)
    end
  end
  local poiScale = minimapWidget:getScale() >= POI_MIN_SCALE
  for _, poi in ipairs(mapPois) do
    poi:setVisible(poiScale and poi.pos.z == z)
  end
  for _, marker in ipairs(pokedexFlags) do
    if not marker:isDestroyed() and marker.pos then
      marker:setVisible(marker.pos.z == z)
    end
  end
  updateWorldChunks()
end

-- ===== Mapa grande suavizado (estilo PKA): imagenes encima del minimapa de cuadraditos =====

local function loadWorldIndex()
  worldIndex = {}
  local ok, contents = pcall(g_resources.readFileContents, WORLD_CHUNKS_DIR .. 'index.txt')
  if not ok or not contents then return end
  for line in contents:gmatch('[^\r\n]+') do
    local size = line:match('^size (%d+)')
    if size then
      worldChunkSize = tonumber(size)
    else
      local z, x0, y0 = line:match('^(%d+) (%d+) (%d+)')
      if z then
        worldIndex[z .. '_' .. x0 .. '_' .. y0] = { z = tonumber(z), x = tonumber(x0), y = tonumber(y0) }
      end
    end
  end
end

function clearWorldChunks()
  local had = worldChunkCount > 0
  for _, chunk in pairs(worldChunks) do
    chunk:destroy()
  end
  worldChunks = {}
  worldChunkCount = 0
  if had then
    g_textures.clearCache() -- las imagenes son grandes: no dejarlas en memoria
  end
end

-- crea solo los trozos que se ven en pantalla (piso actual) y quita los demas
function updateWorldChunks()
  local scale = minimapWidget:getScale()
  if not fullmapView or scale < WORLD_CHUNKS_MIN_SCALE then
    clearWorldChunks()
    return
  end
  if not worldIndex then
    loadWorldIndex()
  end
  local cam = minimapWidget:getCameraPosition()
  local size = minimapWidget:getSize()
  local n = worldChunkSize
  local halfW, halfH = size.width / 2 / scale + 1, size.height / 2 / scale + 1
  local cx0, cx1 = math.floor((cam.x - halfW) / n), math.floor((cam.x + halfW) / n)
  local cy0, cy1 = math.floor((cam.y - halfH) / n), math.floor((cam.y + halfH) / n)
  local wanted = {}
  for cx = cx0, cx1 do
    for cy = cy0, cy1 do
      local key = cam.z .. '_' .. (cx * n) .. '_' .. (cy * n)
      if worldIndex[key] then
        wanted[key] = worldIndex[key]
      end
    end
  end
  for key, chunk in pairs(worldChunks) do
    if not wanted[key] then
      chunk:destroy()
      worldChunks[key] = nil
      worldChunkCount = worldChunkCount - 1
    end
  end
  local pixels = math.ceil(n * scale)
  for key, info in pairs(wanted) do
    local chunk = worldChunks[key]
    if not chunk then
      chunk = g_ui.createWidget('UIWidget')
      chunk:setPhantom(true)
      chunk:setFocusable(false)
      chunk:setImageSource(WORLD_CHUNKS_DIR .. key)
      chunk.pos = { x = info.x + math.floor(n / 2), y = info.y + math.floor(n / 2), z = info.z }
      minimapWidget:insertChild(1, chunk)
      worldChunks[key] = chunk
      worldChunkCount = worldChunkCount + 1
    end
    if chunk:getWidth() ~= pixels then
      chunk:setSize({ width = pixels, height = pixels })
      minimapWidget:centerInPosition(chunk, chunk.pos)
    elseif not chunk.centered then
      minimapWidget:centerInPosition(chunk, chunk.pos)
    end
    chunk.centered = true
  end
end

-- ===== Zonas de la pokedex en el mapa grande =====

function clearPokedexFlags()
  for _, flag in ipairs(pokedexFlags) do
    if not flag:isDestroyed() then
      flag:destroy()
    end
  end
  pokedexFlags = {}
end

-- positions = { {x=, y=, z=, text=}, ... }; icon = imagen del pokemon (o nil)
-- centra el mapa en la zona mas cercana al jugador, mejor en el piso 0 (superficie: se ven las ciudades)
local SURFACE_FLOOR = 7

function showPositions(positions, title, icon)
  if #positions == 0 then return end
  if not fullmapView then
    toggleFullMap()
  end
  clearPokedexFlags()
  for _, p in ipairs(positions) do
    local marker = g_ui.createWidget('UIWidget')
    marker:setSize({ width = 30, height = 30 })
    marker:setImageSource('/game_pokedex/images/marker')
    marker:setTooltip(p.text or title)
    local image = g_ui.createWidget('UIWidget', marker)
    image:setSize({ width = 24, height = 24 })
    image:centerIn('parent')
    image:setImageSource(icon or '/game_pokedex/images/pokeball_big')
    image:setPhantom(true)
    marker.pos = { x = p.x, y = p.y, z = p.z }
    minimapWidget:addChild(marker)
    minimapWidget:centerInPosition(marker, marker.pos)
    table.insert(pokedexFlags, marker)
  end
  local candidates = {}
  for _, p in ipairs(positions) do
    if p.z == SURFACE_FLOOR then
      table.insert(candidates, p)
    end
  end
  if #candidates == 0 then
    candidates = positions
  end
  local best = candidates[1]
  local player = g_game.getLocalPlayer()
  local me = player and player:getPosition()
  if me then
    local bestScore
    for _, p in ipairs(candidates) do
      local score = math.max(math.abs(p.x - me.x), math.abs(p.y - me.y)) + math.abs(p.z - me.z) * 300
      if not bestScore or score < bestScore then
        best, bestScore = p, score
      end
    end
  end
  minimapWidget:setCameraPosition({ x = best.x, y = best.y, z = best.z })
  updateOverlayFloors()
end
