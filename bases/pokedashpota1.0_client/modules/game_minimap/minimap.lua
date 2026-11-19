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

function onTownsOpcode(protocol, opcode, buffer)
  clearTownLabels()
  for entry in buffer:gmatch('[^;]+') do
    local name, x, y, z = entry:match('^(.-):(%d+):(%d+):(%d+)$')
    if name and name ~= '' then
      local label = g_ui.createWidget('Label')
      label:setFont('verdana-11px-rounded')
      label:setText(name)
      label:setColor('#ffffff')
      label:setBackgroundColor('#000000aa')
      label:setTextAutoResize(true)
      label:setPhantom(true)
      minimapWidget:addAlternativeWidget(label, { x = tonumber(x), y = tonumber(y) - 4, z = tonumber(z) }, -100)
      table.insert(townLabels, label)
      if fullmapView then
        minimapWidget:insertChild(1, label)
        minimapWidget:centerInPosition(label, label.pos)
      end
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

-- positions = { {x=, y=, z=, text=}, ... }; centra el mapa en la primera
function showPositions(positions, title)
  if #positions == 0 then return end
  if not fullmapView then
    toggleFullMap()
  end
  clearPokedexFlags()
  for _, p in ipairs(positions) do
    local pos = { x = p.x, y = p.y, z = p.z }
    if not minimapWidget:getFlag(pos) then
      minimapWidget:addFlag(pos, 9, p.text or title, true)
      local flag = minimapWidget:getFlag(pos)
      if flag then
        table.insert(pokedexFlags, flag)
      end
    end
  end
  local first = positions[1]
  minimapWidget:setCameraPosition({ x = first.x, y = first.y, z = first.z })
end
