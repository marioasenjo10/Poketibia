-- Casillas de objetos 1-9 y 0 en la barra de abajo (estilo PKA).
-- Cada casilla ES el atajo de su tecla (game_hotkeys): lo que se arrastra a la casilla 1 queda
-- como atajo de la tecla 1 y al reves. La tecla la gestiona game_hotkeys; aqui solo se dibuja.
--   arrastrar un objeto de la mochila: asignarlo
--   clic izquierdo: usarlo (igual que pulsar la tecla)
--   clic derecho: elegir como se usa (en tu pokemon / con mira / usar) o quitarlo
-- Debajo sale cuantos quedan en la mochila.

local HOT_ITEMS = 10
local KEYS = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' }
local E = '\233' -- e con tilde (cp1252)

local cells = {}
local countEvent
local OPCODE_ITEM_COUNTS = 73
local serverCounts = nil -- [idCliente] = cantidad total (mochilas cerradas incluidas), opcode 73

local function hotkeys()
  local hk = modules.game_hotkeys
  if hk and hk.hotkeysManagerLoaded and hk.getHotkey then
    return hk
  end
  return nil
end

local function hotkeyFor(i)
  local hk = hotkeys()
  return hk and hk.getHotkey(KEYS[i])
end

-- cuantos objetos con ese id lleva el jugador: el total que manda el servidor (cuenta las
-- mochilas cerradas); si aun no ha llegado, lo que se ve en el equipo y las mochilas abiertas
local function countItems(itemId)
  if serverCounts then
    return serverCounts[itemId] or 0
  end
  local player = g_game.getLocalPlayer()
  if not player then return 0 end
  local total = 0
  for slot = InventorySlotFirst, InventorySlotLast do
    local item = player:getInventoryItem(slot)
    if item and item:getId() == itemId then
      total = total + math.max(1, item:getCount())
    end
  end
  for _, container in pairs(g_game.getContainers()) do
    for _, item in ipairs(container:getItems()) do
      if item:getId() == itemId then
        total = total + math.max(1, item:getCount())
      end
    end
  end
  return total
end

local function useTypeText(useType)
  local hk = modules.game_hotkeys
  if useType == hk.HOTKEY_MANAGER_USEONPOKEMON then return 'en tu Pok' .. E .. 'mon' end
  if useType == hk.HOTKEY_MANAGER_USEWITH then return 'con punto de mira' end
  if useType == hk.HOTKEY_MANAGER_USEONSELF then return 'en ti' end
  if useType == hk.HOTKEY_MANAGER_USEONTARGET then return 'en el objetivo' end
  return 'usar'
end

local function updateCell(i)
  local cell = cells[i]
  if not cell then return end
  local widget = cell:getChildById('item')
  local countLabel = cell:recursiveGetChildById('count')
  local label = hotkeyFor(i)
  if not label or not label.itemId then
    widget:setItem(nil)
    widget:setOpacity(1.0)
    countLabel:setText('')
    if label and label.value and label.value ~= '' then
      widget:setTooltip('Tecla ' .. KEYS[i] .. ': ' .. label.value)
    else
      widget:setTooltip('Arrastra aqu' .. '\237' .. ' un objeto')
    end
    return
  end
  widget:setItemId(label.itemId)
  local count = countItems(label.itemId)
  countLabel:setText(count > 0 and ('x' .. count) or '0')
  countLabel:setColor(count > 0 and '#ffffff' or '#ff7070')
  widget:setOpacity(count > 0 and 1.0 or 0.45)
  widget:setTooltip('Tecla ' .. KEYS[i] .. ' (' .. useTypeText(label.useType) .. ')\nClic derecho: opciones')
end

function updateItemBar()
  for i = 1, HOT_ITEMS do
    updateCell(i)
  end
end

local function countTick()
  updateItemBar()
  countEvent = scheduleEvent(countTick, 1000)
end

local function setSlot(i, settings)
  local hk = hotkeys()
  if not hk then return end
  if settings then
    hk.setHotkey(KEYS[i], settings)
  else
    hk.removeHotkeyKey(KEYS[i])
  end
  hk.save()
  updateCell(i)
end

local function useSlot(i)
  local hk = hotkeys()
  if hk then
    hk.doKeyCombo(KEYS[i], true)
  end
  scheduleEvent(updateItemBar, 300)
end

local function openMenu(i)
  local label = hotkeyFor(i)
  if not label or not label.itemId then return end
  local hk = modules.game_hotkeys
  local itemId = label.itemId
  local menu = g_ui.createWidget('PopupMenu')
  menu:addOption('Usar en tu Pok' .. E .. 'mon', function()
    setSlot(i, { autoSend = false, itemId = itemId, useType = hk.HOTKEY_MANAGER_USEONPOKEMON })
  end)
  menu:addOption('Con punto de mira', function()
    setSlot(i, { autoSend = false, itemId = itemId, useType = hk.HOTKEY_MANAGER_USEWITH })
  end)
  menu:addOption('Usar directamente', function()
    setSlot(i, { autoSend = false, itemId = itemId, useType = hk.HOTKEY_MANAGER_USE })
  end)
  menu:addSeparator()
  menu:addOption('Quitar', function() setSlot(i, nil) end)
  menu:display()
end

local function setupCell(i, cell)
  local widget = cell:getChildById('item')
  widget:getChildById('key'):setText(KEYS[i])

  widget.onDrop = function(self, dragged, mousePos)
    if not dragged or not dragged.currentDragThing then return false end
    local thing = dragged.currentDragThing
    if not thing:isItem() then return false end
    local hk = modules.game_hotkeys
    -- por defecto: los de "usar con" con mira (pokeballs...), el resto se usan sin mas.
    -- Para pociones: clic derecho > "Usar en tu Pokemon".
    local useType = thing:isMultiUse() and hk.HOTKEY_MANAGER_USEWITH or hk.HOTKEY_MANAGER_USE
    setSlot(i, { autoSend = false, itemId = thing:getId(), useType = useType })
    return true
  end
  widget.onMouseRelease = function(self, mousePos, mouseButton)
    if not self:containsPoint(mousePos) then return false end
    if mouseButton == MouseRightButton then
      openMenu(i)
      return true
    elseif mouseButton == MouseLeftButton then
      useSlot(i)
      return true
    end
    return false
  end
end

-- una vez por personaje: lo que se guardo en la primera version de las casillas
-- (g_settings 'itembar') pasa a los atajos si esa tecla estaba libre
local function migrateOldSlots()
  local hk = hotkeys()
  if not hk then return end
  local node = g_settings.getNode('itembar')
  if not node then return end
  local key = ((G.host or '') .. '_' .. g_game.getCharacterName()):gsub('[^%w]', '_')
  local list = node[key]
  if not list then return end
  -- marcar como hecho antes de guardar (guardar vuelve a llamar a onHotkeysChanged)
  node[key] = nil
  g_settings.setNode('itembar', node)
  for i = 1, HOT_ITEMS do
    local id = tonumber(list[tostring(i)]) or 0
    if id > 0 and not hk.getHotkey(KEYS[i]) then
      local item = Item.create(id)
      hk.setHotkey(KEYS[i], { autoSend = false, itemId = id,
        useType = item:isMultiUse() and hk.HOTKEY_MANAGER_USEWITH or hk.HOTKEY_MANAGER_USE })
    end
  end
  hk.save()
end

-- lo llama game_hotkeys (via refreshBarKeys) cada vez que carga o guarda los atajos
function onHotkeysChanged()
  if g_game.isOnline() then
    migrateOldSlots()
  end
  updateItemBar()
end

local function onItemCounts(protocol, opcode, buffer)
  serverCounts = {}
  for id, count in string.gmatch(buffer, '(%d+):(%d+)') do
    serverCounts[tonumber(id)] = tonumber(count)
  end
  updateItemBar()
end

local function onGameStart()
  updateItemBar()
  if countEvent then removeEvent(countEvent) end
  countEvent = scheduleEvent(countTick, 1000)
end

local function onGameEnd()
  serverCounts = nil
  if countEvent then
    removeEvent(countEvent)
    countEvent = nil
  end
end

function initItemBar()
  for i = 1, HOT_ITEMS do
    local cell = inventoryWindow:recursiveGetChildById('hotItem' .. i)
    if cell then
      cells[i] = cell
      setupCell(i, cell)
    end
  end
  connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_ITEM_COUNTS)
  ProtocolGame.registerExtendedOpcode(OPCODE_ITEM_COUNTS, onItemCounts)
  if g_game.isOnline() then
    onGameStart()
  end
end

function terminateItemBar()
  disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_ITEM_COUNTS)
  onGameEnd()
end
