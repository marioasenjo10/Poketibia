-- private variables
local topMenu
local leftButtonsPanel
local rightButtonsPanel
local leftGameButtonsPanel
local rightGameButtonsPanel

-- barra limpia en partida: solo estos botones y en este orden
local gameButtonOrder = {
  'inventoryButton', 'pokedexButton', 'questLogButton', 'worldMapButton',
  'skillsButton', 'combatControlsButton', 'vipListButton', 'optionsButton', 'logoutButton',
}
local allowedGameButtons = {}
for _, id in ipairs(gameButtonOrder) do allowedGameButtons[id] = true end
-- botones que fuera de partida viven en el panel izquierdo
local leftPanelButtons = { optionsButton = true, logoutButton = true }
-- botones que nunca se muestran (el sonido se cambia en Ajustes)
local neverShownButtons = { audioButton = true }
local hiddenByMenu = {}

-- private functions
local function addButton(id, description, icon, callback, panel, toggle, front)
  local class
  if toggle then
    class = 'TopToggleButton'
  else
    class = 'TopButton'
  end

  local button = panel:getChildById(id)
  if not button then
    button = g_ui.createWidget(class)
    if front then
      panel:insertChild(1, button)
    else
      panel:addChild(button)
    end
  end
  button:setId(id)
  button:setTooltip(description)
  button:setIcon(resolvepath(icon, 3))
  button.onMouseRelease = function(widget, mousePos, mouseButton)
    if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
      callback()
      return true
    end
  end
  if neverShownButtons[id] then
    button:hide()
  elseif g_game.isOnline() and not allowedGameButtons[id] then
    button:hide()
    hiddenByMenu[button] = true
  end
  return button
end

-- public functions
function init()
  connect(g_game, { onGameStart = online,
                    onGameEnd = offline,
                    onPingBack = updatePing })
  connect(g_app, { onFps = updateFps })

  topMenu = g_ui.displayUI('topmenu')

  leftButtonsPanel = topMenu:getChildById('leftButtonsPanel')
  rightButtonsPanel = topMenu:getChildById('rightButtonsPanel')
  leftGameButtonsPanel = topMenu:getChildById('leftGameButtonsPanel')
  rightGameButtonsPanel = topMenu:getChildById('rightGameButtonsPanel')
  pingLabel = topMenu:getChildById('pingLabel')
  fpsLabel = topMenu:getChildById('fpsLabel')
  rightGameButtonsPanel.onGeometryChange = fitTopMenu

  g_keyboard.bindKeyDown('Ctrl+Shift+T', toggle)

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  disconnect(g_game, { onGameStart = online,
                       onGameEnd = offline,
                       onPingBack = updatePing })
  disconnect(g_app, { onFps = updateFps })

  topMenu:destroy()
end

-- en partida la barra no ocupa todo el ancho: es una pastilla a la derecha solo con los iconos
function fitTopMenu()
  if g_game.isOnline() and topMenu then
    topMenu:setWidth(rightGameButtonsPanel:getWidth())
  end
end

local function setCompact(compact)
  rightGameButtonsPanel:breakAnchors()
  rightGameButtonsPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
  rightGameButtonsPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  topMenu:breakAnchors()
  topMenu:addAnchor(AnchorTop, 'parent', AnchorTop)
  topMenu:addAnchor(AnchorRight, 'parent', AnchorRight)
  if compact then
    leftButtonsPanel:hide()
    leftGameButtonsPanel:hide()
    rightButtonsPanel:hide()
    rightGameButtonsPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    fitTopMenu()
  else
    leftButtonsPanel:show()
    rightButtonsPanel:show()
    rightGameButtonsPanel:addAnchor(AnchorRight, 'rightButtonsPanel', AnchorLeft)
    topMenu:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  end
end

function online()
  showGameButtons()
  setCompact(true)

  addEvent(function()
    if modules.client_options.getOption('showPing') and (g_game.getFeature(GameClientPing) or g_game.getFeature(GameExtendedClientPing)) then
      pingLabel:show()
    else
      pingLabel:hide()
    end
  end)
end

function offline()
  hideGameButtons()
  setCompact(false)
  pingLabel:hide()
end

function updateFps(fps)
  text = 'FPS: ' .. fps
  fpsLabel:setText(text)
end

function updatePing(ping)
  local text = 'Ping: '
  local color
  if ping < 0 then
    text = text .. "??"
    color = 'yellow'
  else
    text = text .. ping .. ' ms'
    if ping >= 500 then
      color = 'red'
    elseif ping >= 250 then
      color = 'yellow'
    else
      color = 'green'
    end
  end
  pingLabel:setColor(color)
  pingLabel:setText(text)
end

function setPingVisible(enable)
  pingLabel:setVisible(enable)
end

function setFpsVisible(enable)
  fpsLabel:setVisible(enable)
end

function addLeftButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, false, front)
end

function addLeftToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, true, front)
end

function addRightButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, false, front)
end

function addRightToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, true, front)
end

function addLeftGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, false, front)
end

function addLeftGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, true, front)
end

function addRightGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, false, front)
end

function addRightGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, true, front)
end

local function moveButton(button, panel, index)
  local parent = button:getParent()
  if parent then parent:removeChild(button) end
  if index then
    panel:insertChild(index, button)
  else
    panel:addChild(button)
  end
end

function showGameButtons()
  leftGameButtonsPanel:show()
  rightGameButtonsPanel:show()
  -- todos los botones elegidos juntos y en orden en el panel derecho
  for _, id in ipairs(gameButtonOrder) do
    local button = topMenu:recursiveGetChildById(id)
    if button then
      moveButton(button, rightGameButtonsPanel)
      button:show()
    end
  end
  for _, panel in ipairs({ leftButtonsPanel, rightButtonsPanel, leftGameButtonsPanel, rightGameButtonsPanel }) do
    for _, button in ipairs(panel:getChildren()) do
      if not allowedGameButtons[button:getId()] and button:isVisible() then
        button:hide()
        hiddenByMenu[button] = true
      end
    end
  end
end

function hideGameButtons()
  leftGameButtonsPanel:hide()
  rightGameButtonsPanel:hide()
  -- ajustes y salir vuelven a la izquierda para la pantalla de login
  for _, id in ipairs({ 'optionsButton', 'logoutButton' }) do
    local button = rightGameButtonsPanel:getChildById(id)
    if button and leftPanelButtons[id] then
      moveButton(button, leftButtonsPanel, 1)
    end
  end
  for button in pairs(hiddenByMenu) do
    if not button:isDestroyed() and not neverShownButtons[button:getId()] then
      button:show()
    end
  end
  hiddenByMenu = {}
end

function getButton(id)
  return topMenu:recursiveGetChildById(id)
end

function getTopMenu()
  return topMenu
end

function toggle()
  local menu = getTopMenu()
  if not menu then
    return
  end

  if menu:isVisible() then
    menu:hide()
    modules.client_background.getBackground():addAnchor(AnchorTop, 'parent', AnchorTop)
    modules.game_interface.getRootPanel():addAnchor(AnchorTop, 'parent', AnchorTop)
    modules.game_interface.getShowTopMenuButton():show()
  else
    menu:show()
    modules.client_background.getBackground():addAnchor(AnchorTop, 'topMenu', AnchorBottom)
    modules.game_interface.getRootPanel():addAnchor(AnchorTop, 'topMenu', AnchorBottom)
    modules.game_interface.getShowTopMenuButton():hide()
  end
end
