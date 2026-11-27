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
taskMarkers = {}     -- marcas de las tareas activas, siempre en el mapa (game_tasks llama a setTaskMarkers)
OPCODE_MAP_POIS = 74 -- Centros Pokemon y tiendas (servidor: lib/core/mappois.lua)
mapPois = {}
OPCODE_NEXT_GYM = 75 -- siguiente gimnasio del jugador (servidor: lib/core/progression.lua)
gymMarker = nil
floorLabel = nil     -- cartel con el piso que se esta viendo en el mapa grande
POI_MIN_SCALE = 1    -- con el mapa mas alejado no se ven (serian puntitos encima de todo)
STAIRS_FILE = '/game_minimap/stairs.txt' -- escaleras del mapa (tools/stairs.py)
STAIRS_MIN_SCALE = 1      -- minimapa pequeno
STAIRS_FULL_MIN_SCALE = 2 -- mapa grande: en la vista general no salen, hay que acercar
STAIRS_SPACING = 14       -- pixeles: con varias del mismo tipo mas juntas que esto, sale una
STAIRS_CELL = 64
stairMarkers = {}    -- solo las que caben en lo que se esta viendo
local stairIndex = nil
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
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_NEXT_GYM)
  ProtocolGame.registerExtendedOpcode(OPCODE_NEXT_GYM, onNextGymOpcode)

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
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_NEXT_GYM)
  clearMapPois()
  clearStairMarkers()
  clearGymMarker()
  clearPokedexFlags()
  clearTownLabels()
  clearWorldChunks()
  floorLabel = nil -- se destruye con el minimapa

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
  clearStairMarkers()
  clearGymMarker()
  clearTaskMarkers()
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
      -- las ciudades cuyo centro no esta en el piso 0 llevan el piso junto al nombre
      local level = 7 - tonumber(z)
      local shownName = name
      if level ~= 0 then
        shownName = name .. ' (piso ' .. (level > 0 and '+' or '') .. level .. ')'
      end
      local label = createTownLabel(shownName, discovered)
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

-- ===== Siguiente gimnasio: icono dorado con estrella, se ve con cualquier zoom =====
-- Se ve en el piso del lider y tambien en la superficie (piso 7): los gimnasios suelen estar en un piso alto.

function clearGymMarker()
  if gymMarker and not gymMarker:isDestroyed() then
    gymMarker:destroy()
  end
  gymMarker = nil
end

function onNextGymOpcode(protocol, opcode, buffer)
  clearGymMarker()
  local x, y, z, leader, city, medal, kind = (buffer or ''):match('^(%d+):(%d+):(%d+):([^:]*):([^:]*):([^:]*):([^:]*)$')
  if not x or not minimapWidget then return end
  gymMarker = g_ui.createWidget('UIWidget')
  gymMarker:setSize({ width = 26, height = 26 })
  gymMarker:setImageSource('/images/map/gym_next')
  -- la Liga llega sin tipo: "Siguiente reto: Liga Pokemon (Meseta Anil)"
  local isGym = kind ~= ''
  gymMarker.baseTooltip = (isGym and 'Siguiente gimnasio: ' or 'Siguiente reto: ') .. leader .. ' (' .. city .. ')\n' ..
    medal .. (isGym and (' - Pok\233mon de tipo ' .. kind) or '')
  gymMarker:setTooltip(gymMarker.baseTooltip)
  local arrow = g_ui.createWidget('UIWidget', gymMarker)
  arrow:setSize({ width = 14, height = 14 })
  arrow:addAnchor(AnchorTop, 'parent', AnchorTop)
  arrow:addAnchor(AnchorRight, 'parent', AnchorRight)
  arrow:setBackgroundColor('#14161bdd')
  arrow:setPhantom(true)
  arrow:hide()
  gymMarker.arrow = arrow
  gymMarker:setFocusable(false)
  gymMarker.pos = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
  minimapWidget:addChild(gymMarker)
  minimapWidget:centerInPosition(gymMarker, gymMarker.pos)
  updateOverlayFloors()
end

-- muestra cada marca/ciudad solo en su piso (el mapa no las oculta solo)
function updateOverlayFloors()
  if not minimapWidget then return end
  local camera = minimapWidget:getCameraPosition()
  if not camera then return end
  local z = camera.z
  local zoom = minimapWidget:getZoom()
  for _, label in ipairs(townLabels) do
    if label.pos then
      local zoomOk = (not label.minZoom or label.minZoom >= zoom) and (label.maxZoom or 0) <= zoom
      -- en el piso 0 salen todas, aunque esten en otro piso: asi se sabe donde queda cada una
      local show = zoomOk and (label.pos.z == z or z == 7)
      label:setVisible(show)
      if show and label:getParent() == minimapWidget then
        minimapWidget:centerInPosition(label, { x = label.pos.x, y = label.pos.y, z = z })
      end
    end
  end
  local poiScale = minimapWidget:getScale() >= POI_MIN_SCALE
  for _, poi in ipairs(mapPois) do
    poi:setVisible(poiScale and poi.pos.z == z)
  end
  if gymMarker and not gymMarker:isDestroyed() then
    gymMarker:setVisible(true)
    local floors = z - gymMarker.pos.z -- positivo: el gimnasio esta mas arriba
    if floors == 0 then
      gymMarker.arrow:hide()
      gymMarker:setTooltip(gymMarker.baseTooltip)
    else
      gymMarker.arrow:setImageSource(floors > 0 and '/images/map/up' or '/images/map/down')
      gymMarker.arrow:show()
      local level = 7 - gymMarker.pos.z
      gymMarker:setTooltip(gymMarker.baseTooltip .. '\nEsta en el piso ' .. (level > 0 and '+' or '') .. level ..
        (floors > 0 and ' (sube)' or ' (baja)'))
    end
    -- el minimapa solo coloca bien lo que esta en el piso que se mira
    minimapWidget:centerInPosition(gymMarker, { x = gymMarker.pos.x, y = gymMarker.pos.y, z = z })
  end
  for _, list in ipairs({ pokedexFlags, taskMarkers }) do
    for _, marker in ipairs(list) do
      if not marker:isDestroyed() and marker.pos then
        updateMarkerFloor(marker, z)
      end
    end
  end
  updateWorldChunks()
  updateStairMarkers()
  if updateFloorLabelHook then updateFloorLabelHook(z) end
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

-- ===== Escaleras: flecha de subir o bajar en el piso que se esta viendo =====

local function loadStairs()
  stairIndex = {}
  local ok, contents = pcall(g_resources.readFileContents, STAIRS_FILE)
  if not ok or not contents then return end
  for z, x, y, kind in contents:gmatch('(%d+) (%d+) (%d+) ([ud])') do
    z, x, y = tonumber(z), tonumber(x), tonumber(y)
    local key = z .. '_' .. math.floor(x / STAIRS_CELL) .. '_' .. math.floor(y / STAIRS_CELL)
    stairIndex[key] = stairIndex[key] or {}
    table.insert(stairIndex[key], { x = x, y = y, z = z, up = kind == 'u' })
  end
end

function clearStairMarkers()
  for _, marker in pairs(stairMarkers) do
    if not marker:isDestroyed() then
      marker:destroy()
    end
  end
  stairMarkers = {}
end

-- mas pequenas cuanto mas alejado esta el mapa
local function stairSize(scale)
  if scale >= 4 then return 13 end
  if scale >= 2 then return 11 end
  return 9
end

-- una imagen por tamano (tools/stair_icons.py): reescalada, la flecha quedaba descentrada
local function resizeStairMarker(marker, pixels)
  if marker.pixels ~= pixels then
    marker.pixels = pixels
    marker:setSize({ width = pixels, height = pixels })
    marker:setImageSource('/images/map/stair_' .. marker.kind .. '_' .. pixels)
    minimapWidget:centerInPosition(marker, marker.pos)
  end
end

local function createStairMarker(stair)
  local marker = g_ui.createWidget('UIWidget')
  marker.kind = stair.up and 'up' or 'down'
  marker:setFocusable(false)
  marker:setTooltip(stair.up and 'Escalera: sube de piso' or 'Escalera: baja de piso')
  marker.pos = { x = stair.x, y = stair.y, z = stair.z }
  -- encima del mapa suavizado y debajo de las demas marcas
  minimapWidget:insertChild(worldChunkCount + 1, marker)
  minimapWidget:centerInPosition(marker, marker.pos)
  return marker
end

-- el mapa tiene miles de escaleras: solo se crean las que se ven
function updateStairMarkers()
  local scale = minimapWidget:getScale()
  local cam = minimapWidget:getCameraPosition()
  local minScale = fullmapView and STAIRS_FULL_MIN_SCALE or STAIRS_MIN_SCALE
  if not cam or scale < minScale then
    clearStairMarkers()
    return
  end
  if not stairIndex then
    loadStairs()
  end
  local size = minimapWidget:getSize()
  local halfW, halfH = size.width / 2 / scale + 1, size.height / 2 / scale + 1
  local wanted = {}
  -- rejilla fija sobre el mapa (no sobre la pantalla): asi no parpadean al moverse
  local spacing = math.max(1, math.ceil(STAIRS_SPACING / scale))
  local taken = {}
  for cx = math.floor((cam.x - halfW) / STAIRS_CELL), math.floor((cam.x + halfW) / STAIRS_CELL) do
    for cy = math.floor((cam.y - halfH) / STAIRS_CELL), math.floor((cam.y + halfH) / STAIRS_CELL) do
      for _, stair in ipairs(stairIndex[cam.z .. '_' .. cx .. '_' .. cy] or {}) do
        local spot = math.floor(stair.x / spacing) .. '_' .. math.floor(stair.y / spacing) .. (stair.up and 'u' or 'd')
        if not taken[spot] then
          taken[spot] = true
          if math.abs(stair.x - cam.x) <= halfW and math.abs(stair.y - cam.y) <= halfH then
            wanted[stair] = true
          end
        end
      end
    end
  end
  for stair, marker in pairs(stairMarkers) do
    if not wanted[stair] then
      marker:destroy()
      stairMarkers[stair] = nil
    end
  end
  local pixels = stairSize(scale)
  for stair in pairs(wanted) do
    if not stairMarkers[stair] then
      stairMarkers[stair] = createStairMarker(stair)
    end
    resizeStairMarker(stairMarkers[stair], pixels)
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

-- marca redonda con la pokeball (o el pokemon). Si esta en un piso alto (un gimnasio con escaleras)
-- se ve tambien en la superficie con una flecha: hay que subir (o bajar) ahi.
local function createPokeMarker(p, title, icon, onSurface)
  local marker = g_ui.createWidget('UIWidget')
  marker:setSize({ width = 30, height = 30 })
  marker:setImageSource('/game_pokedex/images/marker')
  marker.baseTooltip = p.text or title
  marker:setTooltip(marker.baseTooltip)
  local image = g_ui.createWidget('UIWidget', marker)
  image:setSize({ width = 24, height = 24 })
  image:centerIn('parent')
  image:setImageSource(icon or '/game_pokedex/images/pokeball_big')
  image:setPhantom(true)
  local arrow = g_ui.createWidget('UIWidget', marker)
  arrow:setSize({ width = 14, height = 14 })
  arrow:addAnchor(AnchorTop, 'parent', AnchorTop)
  arrow:addAnchor(AnchorRight, 'parent', AnchorRight)
  arrow:setBackgroundColor('#14161bdd')
  arrow:setPhantom(true)
  arrow:hide()
  marker.arrow = arrow
  marker.onSurface = onSurface
  marker.pos = { x = p.x, y = p.y, z = p.z }
  minimapWidget:addChild(marker)
  minimapWidget:centerInPosition(marker, marker.pos)
  return marker
end

local function floorName(z)
  if z < 7 then return 'piso +' .. (7 - z) end
  if z > 7 then return 'piso -' .. (z - 7) end
  return 'piso 0'
end

-- cartel del mapa grande: en que piso se esta mirando y en cuales sale el Pokemon buscado
local function updateFloorLabel(z)
  if floorLabel and floorLabel:isDestroyed() then floorLabel = nil end
  if not fullmapView then
    if floorLabel then floorLabel:hide() end
    return
  end
  if not floorLabel then
    floorLabel = g_ui.createWidget('UIWidget', minimapWidget)
    floorLabel:setFont('poppins-semibold-11px')
    floorLabel:setColor('#ffffff')
    floorLabel:setBackgroundColor('#14161bdd')
    floorLabel:setTextAlign(AlignCenter)
    floorLabel:setPhantom(true)
    floorLabel:setFocusable(false)
    floorLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
    floorLabel:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    floorLabel:setMarginTop(10)
  end
  local lines = { 'Viendo: ' .. floorName(z) .. (z == 7 and ' (superficie)' or '') .. '   |   Ctrl + rueda: cambiar de piso' }
  local floors, seen, title = {}, {}, nil
  for _, marker in ipairs(pokedexFlags) do
    if not marker:isDestroyed() and marker.pos then
      title = marker.title
      if not seen[marker.pos.z] then
        seen[marker.pos.z] = true
        table.insert(floors, marker.pos.z)
      end
    end
  end
  if title then
    -- primero el piso 0, despues los mas cercanos a el
    table.sort(floors, function(a, b)
      local da, db = math.abs(a - 7), math.abs(b - 7)
      if da ~= db then return da < db end
      return a < b
    end)
    local names = {}
    for _, floor in ipairs(floors) do
      table.insert(names, floorName(floor))
    end
    table.insert(lines, title .. ' sale en: ' .. table.concat(names, ', '))
  end
  floorLabel:setText(table.concat(lines, '\n'))
  local size = floorLabel:getTextSize()
  floorLabel:setSize({ width = size.width + 20, height = size.height + 10 })
  floorLabel:show()
  floorLabel:raise()
end

function updateMarkerFloor(marker, z)
  -- se coloca en el piso que se mira (si no, el minimapa no sabe donde ponerla)
  minimapWidget:centerInPosition(marker, { x = marker.pos.x, y = marker.pos.y, z = z })
  -- un objetivo en un piso alto (o subterraneo) se ve desde la superficie y desde cualquier
  -- otro piso alto (o subterraneo), con la flecha de subir o bajar
  local sameSide = (marker.pos.z < SURFACE_FLOOR and z < SURFACE_FLOOR) or
    (marker.pos.z > SURFACE_FLOOR and z > SURFACE_FLOOR)
  if marker.pos.z == z then
    marker:setVisible(true)
    marker.arrow:hide()
    marker:setTooltip(marker.baseTooltip)
  elseif marker.onSurface and (z == SURFACE_FLOOR or sameSide) then
    marker:setVisible(true)
    local up = marker.pos.z < z
    marker.arrow:setImageSource(up and '/images/map/up' or '/images/map/down')
    marker.arrow:show()
    marker:setTooltip(marker.baseTooltip .. '\n(' .. (up and 'sube' or 'baja') .. ' al ' .. floorName(marker.pos.z) .. ')')
  else
    marker:setVisible(false)
  end
end

updateFloorLabelHook = updateFloorLabel

function clearTaskMarkers()
  for _, marker in ipairs(taskMarkers) do
    if not marker:isDestroyed() then
      marker:destroy()
    end
  end
  taskMarkers = {}
end

-- marcas de las tareas activas en el mapa normal (sin abrir la tarea): list = { {points, title, icon}, ... }
function setTaskMarkers(list)
  clearTaskMarkers()
  if not minimapWidget then return end
  for _, entry in ipairs(list or {}) do
    for _, p in ipairs(entry.points or {}) do
      table.insert(taskMarkers, createPokeMarker(p, entry.title, p.icon or entry.icon, true))
    end
  end
  updateOverlayFloors()
end

-- preferSurface (pokedex): si sale en el piso 0, el mapa se abre ahi aunque haya otra zona mas cerca
function showPositions(positions, title, icon, preferSurface)
  if #positions == 0 then return end
  if not fullmapView then
    toggleFullMap()
  end
  clearPokedexFlags()
  for _, p in ipairs(positions) do
    -- los pisos altos y los subterraneos salen tambien en la superficie, con flecha
    local marker = createPokeMarker(p, title, p.icon or icon, true)
    if preferSurface then marker.title = title end
    table.insert(pokedexFlags, marker)
  end
  -- se centra en la zona mas cercana al jugador; cada piso de diferencia cuenta como 15 casillas
  -- (antes se preferia siempre la superficie y la zona de Mt. Moon, en un piso alto, nunca salia)
  local candidates = positions
  if preferSurface then
    local surface = {}
    for _, p in ipairs(positions) do
      if p.z == SURFACE_FLOOR then table.insert(surface, p) end
    end
    if #surface > 0 then candidates = surface end
  end
  local best = candidates[1]
  local player = g_game.getLocalPlayer()
  local me = player and player:getPosition()
  if me then
    local bestScore
    for _, p in ipairs(candidates) do
      local score = math.max(math.abs(p.x - me.x), math.abs(p.y - me.y)) + math.abs(p.z - me.z) * 15
      if not bestScore or score < bestScore then
        best, bestScore = p, score
      end
    end
  end
  -- en otro piso (el gimnasio de Surge, la cueva de Haunter): se ensena la superficie con la
  -- flecha de subir o bajar
  minimapWidget:setCameraPosition({ x = best.x, y = best.y, z = SURFACE_FLOOR })
  updateOverlayFloors()
end
