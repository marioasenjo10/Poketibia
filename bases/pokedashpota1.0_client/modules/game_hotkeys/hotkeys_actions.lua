-- Ventana de atajos por acciones (estilo PKA): cada accion (ataque 1, sacar pokemon 2,
-- pokedex...) con dos teclas. Clic en una tecla y pulsar la nueva; clic derecho la borra.
-- Por debajo usa los mismos atajos de hotkeys_manager (tecla -> texto u objeto), asi que
-- todo lo que ya estaba configurado se conserva. Las teclas 1-0 son las casillas de objetos
-- de la barra de abajo (game_inventory/itembar.lua), que usan estas mismas funciones.
-- Los atajos que no encajan en ninguna accion salen en "Otros".

local actionsWindow
local captureAction, captureSlot

local E = '\233' -- e con tilde (cp1252)
local O = '\243' -- o con tilde

local function inventoryItemId(slotId)
  local inv = modules.game_inventory and modules.game_inventory.inventoryPanel
  local slot = inv and inv:recursiveGetChildById(slotId)
  local item = slot and slot:getItem()
  if item then
    return item:getId(), item:isMultiUse()
  end
  return nil
end

local function buildActions()
  local sections = {}

  local moves = { title = 'Ataques del Pok' .. E .. 'mon', actions = {} }
  for i = 1, 12 do
    moves.actions[#moves.actions + 1] = { name = 'Ataque ' .. i, value = 'm' .. i }
  end
  moves.actions[#moves.actions + 1] = { name = 'Smart Combo', value = 'combo' }
  sections[#sections + 1] = moves

  local team = { title = 'Equipo', actions = {} }
  for i = 1, 6 do
    team.actions[#team.actions + 1] = { name = 'Sacar Pok' .. E .. 'mon ' .. i, value = '!p ' .. i }
  end
  sections[#sections + 1] = team

  sections[#sections + 1] = { title = 'Volar', actions = {
    { name = 'Subir un piso', value = '!up' },
    { name = 'Bajar un piso', value = '!down' },
  } }

  local items = { title = 'Objetos', actions = {
    { name = 'Pok' .. E .. 'dex', itemId = POKEDEX_CLIENT_ID, useType = HOTKEY_MANAGER_USEWITH },
    { name = 'Orden', itemId = ORDER_CLIENT_ID, useType = HOTKEY_MANAGER_USEWITH },
  } }
  for _, info in ipairs({ { 'slot9', 'Cuerda' }, { 'slot2', 'Ca\241a' }, { 'slot8', 'Medallas' } }) do
    local id, multiUse = inventoryItemId(info[1])
    if id then
      items.actions[#items.actions + 1] = { name = info[2], itemId = id,
        useType = multiUse and HOTKEY_MANAGER_USEWITH or HOTKEY_MANAGER_USE }
    end
  end
  sections[#sections + 1] = items

  return sections
end

local function matches(label, action)
  if action.itemId then
    return label.itemId == action.itemId
  end
  return label.itemId == nil and label.value ~= nil and label.value:lower():trim() == action.value
end

-- teclas de una accion, las mas cortas primero (F1 antes que Shift+F1)
local function keysFor(action)
  local keys = {}
  -- casilla de abajo (teclas 1-0): una sola tecla fija
  if action.slotKey then
    if getHotkey(action.slotKey) then keys[1] = action.slotKey end
    return keys
  end
  for _, label in ipairs(currentHotkeys:getChildren()) do
    if label.keyCombo and matches(label, action) then
      keys[#keys + 1] = label.keyCombo
    end
  end
  table.sort(keys, function(a, b)
    if #a ~= #b then return #a < #b end
    return a < b
  end)
  return keys
end

-- ===== API para otros modulos (casillas de objetos) =====

function getHotkey(keyCombo)
  return currentHotkeys and currentHotkeys:getChildById(keyCombo)
end

function removeHotkeyKey(keyCombo)
  local label = getHotkey(keyCombo)
  if not label then return end
  currentHotkeyLabel = label
  removeHotkey()
end

-- settings = {autoSend, value} para texto o {itemId, useType} para objeto
function setHotkey(keyCombo, settings)
  local label = getHotkey(keyCombo)
  if label then
    label.autoSend = settings.autoSend
    label.itemId = settings.itemId
    label.subType = nil
    label.useType = settings.useType
    label.value = settings.value
    updateHotkeyLabel(label)
  else
    addKeyCombo(keyCombo, settings)
  end
end

local function removeKey(keyCombo)
  removeHotkeyKey(keyCombo)
end

local function setKey(keyCombo, action)
  if action.itemId then
    setHotkey(keyCombo, { autoSend = false, itemId = action.itemId, useType = action.useType })
  else
    setHotkey(keyCombo, { autoSend = true, value = action.value })
  end
end

-- teclas de las casillas de objetos (no salen en "Otros")
local ITEM_SLOT_KEYS = { ['1'] = true, ['2'] = true, ['3'] = true, ['4'] = true, ['5'] = true,
  ['6'] = true, ['7'] = true, ['8'] = true, ['9'] = true, ['0'] = true }

local function describe(label)
  if label.itemId then
    if label.useType == HOTKEY_MANAGER_USEONPOKEMON then return 'Objeto (en tu Pok' .. E .. 'mon)' end
    if label.useType == HOTKEY_MANAGER_USEWITH then return 'Objeto (con mira)' end
    if label.useType == HOTKEY_MANAGER_USEONSELF then return 'Objeto (en ti)' end
    if label.useType == HOTKEY_MANAGER_USEONTARGET then return 'Objeto (en el objetivo)' end
    return 'Objeto'
  end
  return 'Texto: ' .. (label.value or '')
end

local function shortKey(k)
  return k
end

local refreshActions

local function onKeyCellClick(action, slot, mouseButton)
  local keys = keysFor(action)
  if mouseButton == MouseRightButton then
    if keys[slot] then
      removeKey(keys[slot])
      save()
      refreshActions()
    end
    return
  end
  -- las casillas 1-0 se rellenan arrastrando un objeto a la barra de abajo
  if action.slotKey then return end
  captureAction, captureSlot = action, slot
  local capture = actionsWindow:getChildById('capture')
  capture:getChildById('captureText'):setText('Pulsa la tecla para "' .. action.name .. '"\n\n(Esc para cancelar)')
  capture:show()
  capture:raise()
  capture:focus()
  capture:grabKeyboard()
end

local function stopCapture()
  local capture = actionsWindow:getChildById('capture')
  capture:ungrabKeyboard()
  capture:hide()
  captureAction, captureSlot = nil, nil
end

local function onCaptureKey(widget, keyCode, keyboardModifiers)
  if keyCode == KeyEscape then
    stopCapture()
    return true
  end
  -- solo un modificador: esperar a la tecla de verdad
  if keyCode == KeyShift or keyCode == KeyCtrl or keyCode == KeyAlt or keyCode == KeyMeta then
    return true
  end
  local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
  local action, slot = captureAction, captureSlot
  stopCapture()
  if not action or not keyCombo or keyCombo == '' then return true end

  local keys = keysFor(action)
  local old = keys[slot]
  if old ~= keyCombo then
    if old then removeKey(old) end
    -- si la tecla era de otra accion, pasa a esta
    setKey(keyCombo, action)
    save()
  end
  refreshActions()
  return true
end

refreshActions = function()
  if not actionsWindow then return end
  local list = actionsWindow:getChildById('actionsList')
  list:destroyChildren()
  local sections = buildActions()
  -- atajos que no son de ninguna accion ni de las casillas 1-0
  local others = { title = 'Otros', actions = {} }
  for _, label in ipairs(currentHotkeys:getChildren()) do
    local key = label.keyCombo
    if key and not ITEM_SLOT_KEYS[key] and (label.itemId or (label.value and label.value ~= '')) then
      local used = false
      for _, section in ipairs(sections) do
        for _, action in ipairs(section.actions) do
          if matches(label, action) then used = true end
        end
      end
      if not used then
        others.actions[#others.actions + 1] = { name = describe(label), itemId = label.itemId,
          useType = label.useType, value = label.value and label.value:lower():trim(), fixedKey = key }
      end
    end
  end
  if #others.actions > 0 then
    sections[#sections + 1] = others
  end
  -- casillas de la barra de abajo: se ven y se borran con clic derecho
  local slots = { title = 'Casillas de abajo (1-0)', actions = {} }
  for _, key in ipairs({ '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' }) do
    local label = getHotkey(key)
    if label and (label.itemId or (label.value and label.value ~= '')) then
      slots.actions[#slots.actions + 1] = { name = 'Casilla ' .. key .. ': ' .. describe(label), slotKey = key }
    end
  end
  if #slots.actions > 0 then
    sections[#sections + 1] = slots
  end
  for _, section in ipairs(sections) do
    local header = g_ui.createWidget('ActionSection', list)
    header:setText(section.title)
    for _, action in ipairs(section.actions) do
      local row = g_ui.createWidget('ActionRow', list)
      row:getChildById('name'):setText(action.name)
      local keys = keysFor(action)
      for slot = 1, 2 do
        local cell = row:getChildById('key' .. slot)
        cell:setText(keys[slot] and shortKey(keys[slot]) or '')
        cell.onMouseRelease = function(self, mousePos, mouseButton)
          if self:containsPoint(mousePos) then
            onKeyCellClick(action, slot, mouseButton)
          end
          return true
        end
      end
    end
  end
end

function showActions()
  if not g_game.isOnline() then return end
  if not actionsWindow then
    actionsWindow = g_ui.displayUI('hotkeys_actions')
    actionsWindow:getChildById('capture').onKeyDown = onCaptureKey
    -- la X y Esc cierran (asignado aqui: desde el .otui no llegaba el clic)
    local closeButton = actionsWindow:getChildById('closeButton')
    closeButton.onClick = function() hideActions() end
    closeButton.onMouseRelease = function(self, mousePos, mouseButton)
      if mouseButton == MouseLeftButton and self:containsPoint(mousePos) then
        hideActions()
      end
      return true
    end
    actionsWindow.onEscape = function() hideActions() end
    g_keyboard.bindKeyPress('Escape', function()
      if not captureAction then hideActions() end
    end, actionsWindow)
    actionsWindow:getChildById('footer'):getChildById('hint'):setText(
      'Clic: cambiar tecla  -  Clic derecho: borrarla  -  Teclas 1-0: casillas de abajo')
  end
  refreshActions()
  actionsWindow:show()
  actionsWindow:raise()
  actionsWindow:focus()
end

function hideActions()
  if not actionsWindow then return end
  if captureAction then stopCapture() end
  actionsWindow:hide()
end

function toggleActions()
  if actionsWindow and actionsWindow:isVisible() then
    hideActions()
  else
    showActions()
  end
end


function terminateActions()
  if actionsWindow then
    actionsWindow:destroy()
    actionsWindow = nil
  end
end
