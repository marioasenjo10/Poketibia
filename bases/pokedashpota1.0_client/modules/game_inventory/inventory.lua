InventorySlotStyles = {
  [InventorySlotHead] = "HeadSlot",
  [InventorySlotNeck] = "NeckSlot",
  [InventorySlotBack] = "BackSlot",
  [InventorySlotBody] = "BodySlot",
  [InventorySlotRight] = "RightSlot",
  [InventorySlotLeft] = "LeftSlot",
  [InventorySlotLeg] = "LegSlot",
  [InventorySlotFeet] = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo] = "AmmoSlot",
  [InventorySlotExt2] = "OrderSlot",
  [InventorySlotExt3] = "InfoSlot",
  [InventorySlotPurse] = "PurseSlot"
}

inventoryWindow = nil
inventoryPanel = nil
inventoryButton = nil
purseButton = nil

-- barra de abajo: icono de cada casilla y tecla por defecto (pokedex E y order Q ya las pone game_hotkeys)
local barSlots = {
  { id = 'slot12', icon = 'pokedex' },
  { id = 'slot11', icon = 'order' },
  { id = 'slot9', icon = 'rope', node = 'rope_hotkey', key = 'R' },
  { id = 'slot2', icon = 'rod', node = 'rod_hotkey', key = 'Z' },
  { id = 'slot8', icon = 'badges', node = 'badges_hotkey', key = 'B' },
}

local function shortKey(k)
  return (k:gsub('Shift%+', 'S+'):gsub('Ctrl%+', 'C+'):gsub('Alt%+', 'A+'))
end

-- tecla asignada en Hotkeys (Ctrl+K) a este objeto
local function hotkeyForItem(itemId)
  local hk = modules.game_hotkeys
  local list = hk and hk.currentHotkeys
  if not list then return nil end
  local best
  for _, child in ipairs(list:getChildren()) do
    if child.keyCombo and child.itemId == itemId and (not best or #child.keyCombo < #best) then
      best = child.keyCombo
    end
  end
  return best and shortKey(best)
end

local function updateBarCell(slot)
  local icon = slot:getChildById('icon')
  local image = 'cell'
  if slot.barPressed then
    image = 'cell_pressed'
  elseif slot:isHovered() then
    image = 'cell_hover'
  end
  icon:setImageSource('/images/bottombar/' .. image)
  local size = (slot:isHovered() and not slot.barPressed) and 40 or 36
  icon:getChildById('img'):setSize({ width = size, height = size })
end

local function useBarItem(item)
  if item:isContainer() then
    g_game.open(item)
  elseif item:isMultiUse() then
    modules.game_interface.startUseWith(item)
  else
    g_game.use(item)
  end
end

-- clic izquierdo usa el objeto (el derecho y los modificadores siguen como siempre)
local function setupBarSlot(slot, icon)
  slot:getChildById('icon'):getChildById('img'):setImageSource('/images/bottombar/' .. icon)
  slot.onHoverChange = function(self, hovered)
    UIItem.onHoverChange(self, hovered)
    if not hovered then self.barPressed = false end
    updateBarCell(self)
  end
  slot.onMousePress = function(self, mousePos, mouseButton)
    self.barDragged = false
    self.barPressed = mouseButton == MouseLeftButton
    updateBarCell(self)
  end
  slot.onDragEnter = function(self, mousePos)
    self.barDragged = true
    return UIItem.onDragEnter(self, mousePos)
  end
  slot.onMouseRelease = function(self, mousePos, mouseButton)
    local dragged = self.barDragged
    self.barDragged = false
    self.barPressed = false
    updateBarCell(self)
    if mouseButton == MouseLeftButton and not dragged and g_keyboard.getModifiers() == KeyboardNoModifier then
      local item = self:getItem()
      if item and self:containsPoint(mousePos) then
        useBarItem(item)
        return true
      end
    end
    return UIItem.onMouseRelease(self, mousePos, mouseButton)
  end
end

-- pone las teclas de la barra; la primera vez anade R/Z/B en Hotkeys para rope, rod y badges
function refreshBarKeys()
  if not inventoryPanel then return end
  local hk = modules.game_hotkeys
  for _, info in ipairs(barSlots) do
    local slot = inventoryPanel:recursiveGetChildById(info.id)
    local item = slot and slot:getItem()
    if item and info.node and hk and hk.hotkeysManagerLoaded and g_game.isOnline() then
      hk.addDefaultItemHotkey(info.node, info.key, item:getId(), not item:isMultiUse())
    end
    if slot then
      local key = item and hotkeyForItem(item:getId())
      local label = slot:getChildById('key')
      label:setText(key or '')
      label:setVisible(key ~= nil)
    end
  end
end

function init()
  connect(LocalPlayer, {
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange
  })
  connect(g_game, { onGameStart = refresh })

  g_keyboard.bindKeyDown('Ctrl+I', toggle)

  inventoryButton = modules.client_topmenu.addRightGameToggleButton('inventoryButton', tr('Inventory') .. ' (Ctrl+I)', '/images/topmenu/inventory', toggle)
  inventoryButton:setOn(false)

  inventoryWindow = g_ui.loadUI('inventory', modules.game_interface.getMapPanel())
  inventoryPanel = inventoryWindow
  inventoryWindow:show()
  for _, info in ipairs(barSlots) do
    local slot = inventoryPanel:recursiveGetChildById(info.id)
    if slot then setupBarSlot(slot, info.icon) end
  end

  refresh()
end

function terminate()
  disconnect(LocalPlayer, {
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange
  })
  disconnect(g_game, { onGameStart = refresh })

  g_keyboard.unbindKeyDown('Ctrl+I')

  inventoryWindow:destroy()
  inventoryButton:destroy()
end

function toggleAdventurerStyle(hasBlessing)
  for slot = InventorySlotFirst, InventorySlotLast do
    local itemWidget = inventoryPanel:recursiveGetChildById('slot' .. slot)
    if itemWidget then
      itemWidget:setOn(hasBlessing)
    end
  end
end

function refresh()
  local player = g_game.getLocalPlayer()
  for i = InventorySlotFirst, InventorySlotLast do
    if g_game.isOnline() then
      onInventoryChange(player, i, player:getInventoryItem(i))
    else
      onInventoryChange(player, i, nil)
    end
    toggleAdventurerStyle(player and Bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)
  end

--  purseButton:setVisible(g_game.getFeature(GamePurseSlot))
end

function toggle()
  local player = g_game.getLocalPlayer()
  if not player then return end

  local backpack = player:getInventoryItem(InventorySlotBack)
  if not backpack then
    backpack = g_game.findPlayerItem(1988, -1)
  end

  if backpack then
    g_game.open(backpack)
  else
    modules.game_textmessage.displayStatusMessage(tr('La mochila por defecto se creara al volver a entrar'))
  end
end

function onMiniWindowClose()
  inventoryButton:setOn(false)
end

-- hooked events
function onInventoryChange(player, slot, item, oldItem)
  if slot > InventorySlotLast then return end

  if slot == InventorySlotPurse then
    if g_game.getFeature(GamePurseSlot) then
--      purseButton:setEnabled(item and true or false)
    end
    return
  end

  local itemWidget = inventoryPanel:recursiveGetChildById('slot' .. slot)
  if not itemWidget then return end

  -- casillas de la barra de abajo: la casilla tapa el objeto; sin objeto, el icono se atenua
  local icon = itemWidget:getChildById('icon')
  if icon then
    itemWidget:setItem(item)
    icon:getChildById('img'):setOpacity(item and 1 or 0.35)
    refreshBarKeys()
    return
  end

  if item then
    itemWidget:setStyle('InventoryItem')
    itemWidget:setItem(item)
  else
    itemWidget:setStyle(InventorySlotStyles[slot])
    itemWidget:setItem(nil)
  end
end

function onBlessingsChange(player, blessings, oldBlessings)
  local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
  if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
    toggleAdventurerStyle(hasAdventurerBlessing)
  end
end
