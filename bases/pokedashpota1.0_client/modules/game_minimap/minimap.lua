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
townLabels = {}
pokedexFlags = {}

function init()
  minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton', 
    tr('Minimap') .. ' (Ctrl+M)', '/images/topbuttons/minimap', toggle)
  minimapButton:setOn(true)

  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getRightPanel())
  minimapWindow:setContentMinimumHeight(64)

  minimapWidget = minimapWindow:recursiveGetChildById('minimap')

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0,1) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0,-1) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+M', toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+M', toggleFullMap)
  g_keyboard.bindKeyDown('Ctrl+Tab', toggleFullMap)
  g_keyboard.bindKeyDown('Escape', closeFullMap, gameRootPanel)
  ProtocolGame.registerExtendedOpcode(OPCODE_TOWNS, onTownsOpcode)

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
  g_keyboard.unbindKeyDown('Ctrl+M')
  g_keyboard.unbindKeyDown('Ctrl+Shift+M')
  g_keyboard.unbindKeyDown('Ctrl+Tab')
  g_keyboard.unbindKeyDown('Escape', gameRootPanel)
  ProtocolGame.unregisterExtendedOpcode(OPCODE_TOWNS)
  clearPokedexFlags()
  clearTownLabels()

  minimapWindow:destroy()
  minimapButton:destroy()
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

  local zoom = oldZoom or 0
  local pos = oldPos or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  oldPos = minimapWidget:getCameraPosition()
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

local TOWN_FONT = 'poppins-semibold-13px'
local TOWN_COLOR = '#ffffff'
local TOWN_COLOR_HIDDEN = '#9aa3b2'
local TOWN_COLOR_HOVER = '#ffd84a'

local function townText(parent, text, color, offsetX, offsetY)
  local label = g_ui.createWidget('UIWidget', parent)
  label:fill('parent')
  label:setFont(TOWN_FONT)
  label:setText(text)
  label:setColor(color)
  label:setTextAlign(AlignLeftCenter)
  label:setTextOffset({ x = offsetX, y = offsetY })
  label:setPhantom(true)
  return label
end

-- chincheta + nombre con sombra (sin caja), blanco si la has descubierto y apagado si no
local function createTownLabel(name, discovered)
  local widget = g_ui.createWidget('UIWidget')
  widget:setFocusable(false)
  local pin = g_ui.createWidget('UIWidget', widget)
  pin:setSize({ width = 16, height = 22 })
  pin:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  pin:addAnchor(AnchorTop, 'parent', AnchorTop)
  pin:setImageSource(discovered and '/game_pokedex/images/pin' or '/game_pokedex/images/pin_off')
  pin:setPhantom(true)
  townText(widget, name, '#000000c0', 20, 1)
  local text = townText(widget, name, discovered and TOWN_COLOR or TOWN_COLOR_HIDDEN, 19, 0)
  widget:setSize({ width = 19 + text:getTextSize().width + 3, height = 22 })
  if not discovered then
    widget:setOpacity(0.8)
  end
  widget.onHoverChange = function(_, hovered)
    text:setColor(hovered and TOWN_COLOR_HOVER or (discovered and TOWN_COLOR or TOWN_COLOR_HIDDEN))
  end
  return widget
end

function onTownsOpcode(protocol, opcode, buffer)
  clearTownLabels()
  for entry in buffer:gmatch('[^;]+') do
    local name, x, y, z, flag = entry:match('^(.-):(%d+):(%d+):(%d+):?(%d*)$')
    if name and name ~= '' then
      local discovered = flag ~= '0'
      local label = createTownLabel(name, discovered)
      if discovered then
        label:setTooltip(name .. '\nClic: teletransportarse (necesitas un pokemon con Teleport, como Abra o Alakazam)')
      else
        label:setTooltip(name .. '\nAun no has descubierto esta ciudad')
      end
      label.onClick = function(widget) askTeleport(name, widget, discovered) end
      minimapWidget:addAlternativeWidget(label, { x = tonumber(x), y = tonumber(y) - 4, z = tonumber(z) }, -100)
      table.insert(townLabels, label)
      if fullmapView then
        minimapWidget:insertChild(1, label)
        minimapWidget:centerInPosition(label, label.pos)
      end
    end
  end
  updateOverlayFloors()
end

function askTeleport(townName, widget, discovered)
  if discovered == false then
    modules.game_textmessage.displayFailureMessage('Aun no has descubierto ' .. townName .. '. Ve primero para poder teletransportarte.')
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
  for _, marker in ipairs(pokedexFlags) do
    if not marker:isDestroyed() and marker.pos then
      marker:setVisible(marker.pos.z == z)
    end
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
-- centra el mapa en la zona mas cercana al jugador (mejor en su mismo piso)
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
  local best = positions[1]
  local player = g_game.getLocalPlayer()
  local me = player and player:getPosition()
  if me then
    local bestScore
    for _, p in ipairs(positions) do
      local score = math.max(math.abs(p.x - me.x), math.abs(p.y - me.y)) + math.abs(p.z - me.z) * 300
      if not bestScore or score < bestScore then
        best, bestScore = p, score
      end
    end
  end
  minimapWidget:setCameraPosition({ x = best.x, y = best.y, z = best.z })
  updateOverlayFloors()
end
