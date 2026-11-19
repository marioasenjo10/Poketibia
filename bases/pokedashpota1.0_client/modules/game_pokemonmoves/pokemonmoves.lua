-- spell bar by Pota based on draky's
local spells = {}
local spellsNumber = 12
local OPCODE_SKILLBAR = 52
local side = 'horizontal'
local locked = false
local sbw -- window widget
local spellBarWindow -- UIWindow
local hideLevel = false -- hide spells that can not be used due to level dependence

-- Smart Combo
-- El cliente bloquea g_game.talk fuera de una tecla/clic (anti-bot), asi que al pulsar
-- la tecla se manda la secuencia entera una vez ("smartcombo 1,3,2") y el servidor
-- lanza los ataques uno a uno. Al acabar responde por el opcode 61.
local COMBO_GAP = 500        -- ms entre ataques (igual que en el servidor), duracion del destello
local OPCODE_COMBO_DONE = 61
local comboWindow
local comboSequence = {}     -- nombres de ataques en orden
local comboRunning = false   -- true mientras el servidor esta lanzando la secuencia
local comboEvent             -- seguridad: parar el combo si el servidor no contesta
local comboPos = 1
local comboKey
local pokemonName
local pokemonPortrait = 0    -- id del item retrato (como el del slot de la cabeza)
local pokemonLook = 0        -- looktype del pokemon (si no hay retrato)
local moveInfo = {}          -- [slot] = {element, category, effect} enviado por el servidor
local OPCODE_POKEINFO = 60

-- Cooldowns visuales: [slot] = g_clock.millis() en que termina
local cdEnd = {}
local cdToken = {}

-- Arrastre de la barra
local DRAG_THRESHOLD = 4
local dragStart, dragOffset
local isDragging = false
local lastDragEnd = 0

-- Medidas de la barra
local SLOT = 38
local GAP = 4
local PAD = 6
local LOCK = 20

local IMG = '/game_pokemonmoves/images/'
local IMG_SLOT = IMG .. 'slot'
local IMG_SLOT_HOVER = IMG .. 'slot_hover'
local IMG_SLOT_ACTIVE = IMG .. 'slot_active'

-- Tooltip propio (nombre, tipo | cd | rol, descripcion)
local moveTip

function msgcontains(message, keyword)
  local message, keyword = message:lower(), keyword:lower()
  if message == keyword then
    return true
  end
  return message:find(keyword) and not message:find('(%w+)' .. keyword)
end

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

-- ===================== Informacion de los movimientos =====================

local ELEMENTS = {
  electric = {'Electrico', '#f8d030'}, fire = {'Fuego', '#f08030'}, water = {'Agua', '#6890f0'},
  grass = {'Planta', '#78c850'}, normal = {'Normal', '#c6c6a7'}, psychic = {'Psiquico', '#f85888'},
  poison = {'Veneno', '#c060c0'}, bug = {'Bicho', '#a8b820'}, ground = {'Tierra', '#e0c068'},
  rock = {'Roca', '#b8a038'}, flying = {'Volador', '#a890f0'}, fighting = {'Lucha', '#e05048'},
  ghost = {'Fantasma', '#9080c0'}, ice = {'Hielo', '#98d8d8'}, dragon = {'Dragon', '#8058f8'},
  dark = {'Siniestro', '#a08070'}, steel = {'Acero', '#b8b8d0'}, fairy = {'Hada', '#ee99ac'},
}

local KIND_COLOR = { OBJETIVO = '#ff6b6b', AREA = '#5aa9ff', PROPIO = '#7ee07e' }

local CATEGORY_POWER = {
  singletargetweak = 'bajo', areawaves = 'medio', singletarget = 'medio',
  areatarget = 'medio', passive = 'medio', singletargetstrong = 'alto',
  frontarea = 'alto', frontlinear = 'muy alto', ultimate = 'maximo',
}

local SHAPE_DESC = {
  areawaves = 'Causa dano en ondas alrededor de tu pokemon.',
  frontlinear = 'Lanza un rayo en linea recta hacia delante.',
  frontarea = 'Causa dano en un area grande delante de tu pokemon.',
  areatarget = 'Causa dano en area alrededor del objetivo.',
  ultimate = 'Ataque definitivo: dano enorme en area alrededor de tu pokemon.',
  passive = 'Habilidad pasiva: se activa sola durante el combate.',
}

local TARGET_DESC = {
  singletargetweak = 'Golpe rapido contra tu objetivo.',
  singletarget = 'Ataca directamente a tu objetivo.',
  singletargetstrong = 'Golpe muy potente contra tu objetivo.',
  areatarget = 'Causa dano en area alrededor del objetivo.',
}

local EFFECT_DESC = {
  poison = 'Envenena a los enemigos alcanzados.',
  burn = 'Quema a los enemigos alcanzados.',
  slow = 'Ralentiza a los enemigos alcanzados.',
  heal = 'Ademas cura a tu pokemon.',
  buff = 'Ademas mejora a tu pokemon.',
}

local function titleCase(s)
  return (s:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
end

local function iconPath(words)
  return "moves_icon/" .. words .. "_on.png"
end

-- Datos fijos del movimiento (movesdata.lua): {objetivo, elemento, categoria, efecto}
local function staticData(words)
  return MOVES_DATA and words and MOVES_DATA[words:lower()]
end

local function infoFor(slot)
  local s = spells[slot]
  local d = s and staticData(s.words)
  if d then return { element = d[2], category = d[3], effect = d[4] } end
  return moveInfo[slot] or {}
end

local function moveCooldownText(slot)
  local s = spells[slot]
  if not s or not s.exhaustion then return '?' end
  return math.floor(s.exhaustion / 1000 + 0.5) .. 's'
end

-- Devuelve tipo (OBJETIVO/AREA/PROPIO), rol (Dano/Cura/Mejora/...) y descripcion
local function moveDetails(slot)
  local s = spells[slot]
  local info = infoFor(slot)
  local cat, eff = info.category or '', info.effect or ''
  local target = s.isTarget == 1

  if cat ~= '' then
    local kind = target and 'OBJETIVO' or 'AREA'
    local role = 'Dano' .. (CATEGORY_POWER[cat] and (' ' .. CATEGORY_POWER[cat]) or '')
    local desc
    if target then
      desc = TARGET_DESC[cat] or 'Ataca a tu objetivo.'
    else
      desc = SHAPE_DESC[cat] or 'Causa dano alrededor de tu pokemon.'
    end
    if EFFECT_DESC[eff] then desc = desc .. ' ' .. EFFECT_DESC[eff] end
    if target and s.range and s.range > 0 then desc = desc .. ' Alcance: ' .. s.range .. ' sqm.' end
    return kind, role, desc
  end

  if eff == 'heal' then return 'PROPIO', 'Cura', 'Cura a tu pokemon.' end
  if eff == 'buff' then return 'PROPIO', 'Mejora', 'Mejora temporalmente a tu pokemon.' end
  if eff == 'slow' then
    if target then return 'OBJETIVO', 'Control', 'Deja aturdido o ralentizado a tu objetivo.' end
    return 'AREA', 'Control', 'Deja aturdidos o ralentizados a los enemigos cercanos.'
  end
  if target then return 'OBJETIVO', 'Especial', 'Efecto especial sobre tu objetivo.' end
  return 'PROPIO', 'Especial', 'Movimiento especial.'
end

-- ===================== Tooltip =====================

local function getTip()
  if not moveTip or moveTip:isDestroyed() then
    moveTip = g_ui.createWidget('MoveTooltip', g_ui.getRootWidget())
    moveTip:hide()
  end
  return moveTip
end

function hideMoveTip()
  if moveTip and not moveTip:isDestroyed() then moveTip:hide() end
end

local function placeTip(anchor)
  local tip = moveTip
  if not tip or tip:isDestroyed() or not tip:isVisible() or anchor:isDestroyed() then return end
  local root = g_ui.getRootWidget()
  local r = anchor:getRect()
  local w, h = tip:getWidth(), tip:getHeight()
  local x = math.max(2, math.min(r.x + math.floor((r.width - w) / 2), root:getWidth() - w - 2))
  local y = r.y - h - 6
  if y < 2 then y = math.min(r.y + r.height + 6, root:getHeight() - h - 2) end
  tip:setPosition({ x = x, y = y })
end

local function showTip(anchor, title, kind, rest, element, desc, hint)
  local tip = getTip()
  tip:getChildById('name'):setText(title)
  local info = tip:getChildById('info')
  info:setVisible(kind ~= nil)
  if kind then
    local kindLabel = info:getChildById('kind')
    kindLabel:setText(kind)
    kindLabel:setColor(KIND_COLOR[kind] or '#ffffff')
    info:getChildById('rest'):setText(rest or '')
    local el = info:getChildById('element')
    el:setText(element and element[1] or '')
    el:setColor(element and element[2] or '#ffffff')
  end
  tip:getChildById('desc'):setText(desc or '')
  tip:getChildById('desc'):setVisible(desc ~= nil and desc ~= '')
  tip:getChildById('hint'):setText(hint or '')
  tip:getChildById('hint'):setVisible(hint ~= nil and hint ~= '')
  tip:show()
  tip:raise()
  placeTip(anchor)
  -- la altura se recalcula al siguiente frame
  scheduleEvent(function() placeTip(anchor) end, 30)
end

local function showMoveTip(anchor, slot, hint)
  local s = spells[slot]
  if not s then return end
  local kind, role, desc = moveDetails(slot)
  local el = ELEMENTS[infoFor(slot).element or '']
  local rest = '  |  ' .. moveCooldownText(slot) .. '  |  ' .. role .. (el and '  |  ' or '')
  showTip(anchor, titleCase(s.words), kind, rest, el, desc, hint)
end

-- ===================== Teclas =====================

local function shortKey(k)
  return (k:gsub('Shift%+', 'S+'):gsub('Ctrl%+', 'C+'):gsub('Alt%+', 'A+'))
end

-- Tecla asignada en Hotkeys al texto indicado (m1, m2, combo...)
local function hotkeyFor(value)
  local hk = modules.game_hotkeys
  local list = hk and hk.currentHotkeys
  if not list then return nil end
  for _, child in ipairs(list:getChildren()) do
    if child.keyCombo and not child.itemId and child.value and child.value:lower():trim() == value then
      return shortKey(child.keyCombo)
    end
  end
  return nil
end

local function setKeyLabel(label, key)
  if not label then return end
  label:setText(key or '')
  label:setVisible(key ~= nil)
end

function refreshKeyLabels()
  if not sbw then return end
  for i = 1, #spells do
    setKeyLabel(sbw:recursiveGetChildById('key' .. i), hotkeyFor('m' .. i))
  end
  local toggle = sbw:recursiveGetChildById('comboToggle')
  if toggle then setKeyLabel(toggle:getChildById('key'), hotkeyFor('combo')) end
end

-- ===================== Barra =====================

function getOpCode(protocol, opcode, buffer)
  local moves = {}
  local numbers = {}
  spells = {}
  for match in string.gmatch(buffer, "([^,]+),%s*") do
    if tonumber(match) == nil then
      moves[#moves + 1] = match
    else
      numbers[#numbers + 1] = tonumber(match)
    end
  end
  -- numeros en bloques de #moves: velocidad, cooldown restante, necesita objetivo, alcance
  local n = #moves
  local now = g_clock.millis()
  cdEnd = {}
  for i = 1, n do
     local inside = {id = i, words = moves[i], lvl = 1, exhaustion = numbers[i], cooldownRemaining = numbers[n + i] or 0,
                     isTarget = numbers[2 * n + i], range = numbers[3 * n + i]}
     -- el tipo OBJETIVO/AREA sale de movesdata.lua (lee el propio script del ataque)
     local d = staticData(moves[i])
     if d then inside.isTarget = d[1] end
     table.insert(spells, inside)
     if inside.cooldownRemaining > 0 then cdEnd[i] = now + inside.cooldownRemaining end
  end
  onMovesReceived()
  getSpells(spells)
  level = g_game.getLocalPlayer():getLevel()
  sbw:show()
end

function init()
  local savedSide = g_settings.getString('pokemonmoves_side')
  if savedSide == 'vertical' or savedSide == 'horizontal' then side = savedSide end
  locked = g_settings.getBoolean('pokemonmoves_locked')
  sbw = g_ui.displayUI('pokemonmoves')
  local savedPos = g_settings.getPoint('pokemonmoves_pos')
  if savedPos and (savedPos.x ~= 0 or savedPos.y ~= 0) then
    sbw:setPosition(savedPos)
    sbw:bindRectToParent()
  else
    sbw:move(10,50)
  end
  -- el fondo (Panel) es phantom: los clics caen en la ventana raiz, que es la que se arrastra
  makeDraggable(sbw)
  g_mouse.bindPress(sbw, function() createMenu() end, MouseRightButton)
  sbw:hide()
  connect(g_game, 'onTalk', messageSentCallback)
  connect(g_game, { onGameEnd = onGameEnd })
  connect(LocalPlayer, {
    onLevelChange = onLevelChange
  })
  ProtocolGame.registerExtendedOpcode(OPCODE_SKILLBAR, getOpCode)
  ProtocolGame.registerExtendedOpcode(OPCODE_POKEINFO, onPokemonInfo)
  ProtocolGame.registerExtendedOpcode(OPCODE_COMBO_DONE, onComboDone)
end

function onGameEnd()
  sbw:hide()
  hideMoveTip()
end

-- Opcode 60: "retrato|looktype|nombre|elem:cat:efecto;elem:cat:efecto;..."
function onPokemonInfo(protocol, opcode, buffer)
  local parts = buffer:split('|')
  pokemonPortrait = tonumber(parts[1]) or 0
  pokemonLook = tonumber(parts[2]) or 0
  if parts[3] and parts[3] ~= '' then pokemonName = parts[3] end
  moveInfo = {}
  for _, s in ipairs((parts[4] or ''):split(';')) do
    local e = s:split(':')
    moveInfo[#moveInfo + 1] = { element = e[1] or '', category = e[2] or '', effect = e[3] or '' }
  end
  refreshComboWindow()
end

function onLevelChange(localPlayer, value, percent)
  getSpells(spells)
end

function messageSentCallback(name, level, mode, text, channelId, pos)
  if not g_game.isOnline() then return end
  if g_game.getLocalPlayer():getName() ~= name then return end
  if mode ~= 34 then return end
  local helpName = text:match("^(.-), I need your help!")
  if helpName then
    pokemonName = helpName
    refreshComboWindow()
    return
  end
  if msgcontains(text, "use") then
    local pokeName = text:match("^(.-), use ")
    if pokeName and pokeName ~= pokemonName then
      pokemonName = pokeName
      refreshComboWindow()
    end
    text = string.gsub(text, "use ", "")
    text = string.gsub(text, "!", "")
    text = text:split(", ")[2]
    if not text then return end
    onComboMoveUsed(text)
    for i = 1, #spells do
      if spells[i].words:lower() == text:lower() then 
        startDownDelay(i)
        break
      end
    end
  elseif msgcontains(text, "thanks") then
    sbw:hide()
    hideMoveTip()
  end
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_SKILLBAR)
  ProtocolGame.unregisterExtendedOpcode(OPCODE_POKEINFO)
  ProtocolGame.unregisterExtendedOpcode(OPCODE_COMBO_DONE)
  removeEvent(comboEvent)
  g_settings.set('pokemonmoves_pos', sbw:getPosition())
  if comboWindow then comboWindow:destroy() comboWindow = nil end
  if moveTip and not moveTip:isDestroyed() then moveTip:destroy() end
  moveTip = nil
  sbw:destroy()
  disconnect(g_game, { onGameEnd = onGameEnd })
  disconnect(g_game, 'onTalk', messageSentCallback)
  disconnect(LocalPlayer, {
    onLevelChange = onLevelChange
  })
end

local function setSide(newSide)
  side = newSide
  g_settings.set('pokemonmoves_side', side)
  getSpells(spells)
  sbw:bindRectToParent()
end

function toggleLock()
  locked = not locked
  g_settings.set('pokemonmoves_locked', locked)
  local lock = sbw:recursiveGetChildById('barLock')
  if lock then lock:setImageSource(IMG .. (locked and 'lock' or 'unlock')) end
end

function createMenu()
  if isDragging or g_clock.millis() - lastDragEnd < 200 then return end
  local menu = g_ui.createWidget('PopupMenu')
  if side == 'horizontal' then
    menu:addOption('Poner vertical', function() setSide('vertical') end)
  else
    menu:addOption('Poner horizontal', function() setSide('horizontal') end)
  end
  menu:addOption(locked and 'Desbloquear barra' or 'Bloquear barra', function() toggleLock() end)
  menu:addSeparator()
  menu:addOption('Abrir Smart Combo', function() toggleComboWindow() end)
  menu:addOption('Lanzar combo', function() runCombo() end)
  menu:display()
end

function destroySpells()
  hideMoveTip()
  local toggle = sbw:recursiveGetChildById('comboToggle')
  if toggle then toggle:destroy() end
  local lock = sbw:recursiveGetChildById('barLock')
  if lock then lock:destroy() end
  for i = 1, spellsNumber do
    local slot = sbw:recursiveGetChildById('slot' .. i)
    if slot then slot:destroy() end
  end
end

-- Posicion (x, y) del elemento numero index dentro de la barra
local function barPos(index)
  local along = PAD + (index - 1) * (SLOT + GAP)
  if side == 'horizontal' then return along, PAD end
  return PAD, along
end

function getSpells(list)
  destroySpells()
  spellBarWindow = sbw:recursiveGetChildById('mainWindow')
  local player = g_game.getLocalPlayer()
  if not player then return end
  local count = 0
  for i = 1, #list do
    if list[i].lvl > player:getLevel() and hideLevel == true then break end
    count = i
    local slot = g_ui.createWidget('SpellSlot', spellBarWindow)
    slot:setId('slot' .. i)
    local x, y = barPos(i)
    slot:setMarginLeft(x)
    slot:setMarginTop(y)

    local icon = slot:getChildById('icon')
    icon:setId('spell' .. i)
    icon:setImageSource(iconPath(list[i].words))
    icon.words = list[i].words
    icon.lvl = list[i].lvl
    icon.exhaustion = list[i].exhaustion
    icon.exhaustionNeeded = icon.exhaustion - list[i].cooldownRemaining

    local progress = slot:getChildById('progress')
    progress:setId('progress' .. i)
    progress:setPercent(100)
    progress:setText('')
    if player:getLevel() < icon.lvl then progress:setText('L' .. icon.lvl) progress:setColor('red') progress:setPercent(0) end

    slot:getChildById('key'):setId('key' .. i)

    makeDraggable(icon)
    icon.onClick = function() if not justDragged() then useSpell(i) end end
    icon.onHoverChange = function(widget, hovered)
      if not slot.flashing then slot:setImageSource(hovered and IMG_SLOT_HOVER or IMG_SLOT) end
      if hovered and not isDragging then showMoveTip(widget, i) else hideMoveTip() end
    end
    if cdEnd[i] and cdEnd[i] > g_clock.millis() then
      startCooldown(i, cdEnd[i] - g_clock.millis())
    end
  end

  -- boton AUTO (Smart Combo)
  local toggle = g_ui.createWidget('ComboToggle', spellBarWindow)
  toggle:setId('comboToggle')
  local x, y = barPos(count + 1)
  toggle:setMarginLeft(x)
  toggle:setMarginTop(y)
  makeDraggable(toggle)
  toggle.onClick = function() if not justDragged() then runCombo() end end
  toggle.onHoverChange = function(widget, hovered)
    toggle.hovered = hovered
    updateComboToggle()
    if hovered and not isDragging then
      showTip(widget, 'Smart Combo', nil, nil, nil,
        'Lanza tu secuencia de ataques. Clic derecho en la barra para configurarla.',
        'Tecla rapida: Hotkeys (Ctrl+K) con el texto combo')
    else
      hideMoveTip()
    end
  end

  -- candado (bloquea el arrastre de la barra)
  local lock = g_ui.createWidget('BarLock', spellBarWindow)
  lock:setId('barLock')
  lock:setImageSource(IMG .. (locked and 'lock' or 'unlock'))
  local lx, ly = barPos(count + 2)
  local centered = PAD + math.floor((SLOT - LOCK) / 2)
  if side == 'horizontal' then ly = centered else lx = centered end
  lock:setMarginLeft(lx)
  lock:setMarginTop(ly)
  lock.onClick = function() toggleLock() end
  lock.onHoverChange = function(widget, hovered)
    if hovered then
      showTip(widget, locked and 'Barra bloqueada' or 'Barra desbloqueada', nil, nil, nil,
        locked and 'Clic para poder moverla.' or 'Clic para que no se mueva al hacer clic.')
    else
      hideMoveTip()
    end
  end

  local along = PAD * 2 + (count + 1) * SLOT + (count + 1) * GAP + LOCK
  local across = PAD * 2 + SLOT
  if side == 'horizontal' then
    sbw:setSize({ width = along, height = across })
  else
    sbw:setSize({ width = across, height = along })
  end
  spellBarWindow:setSize(sbw:getSize())
  refreshKeyLabels()
  updateComboToggle()
end

function useSpell(i)
  local progress = sbw:recursiveGetChildById('progress'..i)
  local player = g_game.getLocalPlayer()
  if not player then return end
  if progress:getPercent() < 100 then return modules.game_textmessage.displayFailureMessage('Sorry, not possible.') end
  g_game.talk('m'..i)
end

function startDownDelay(i)
  local spell = sbw:recursiveGetChildById('spell'..i)
  if not spell then return end
  startCooldown(i, spell.exhaustion or 0)
end

-- Muestra la cuenta atras en segundos sobre el icono del ataque
function startCooldown(i, duration)
  if duration <= 0 then return end
  cdEnd[i] = g_clock.millis() + duration
  cdToken[i] = (cdToken[i] or 0) + 1
  spellTimeleft(i, cdToken[i])
end

function spellTimeleft(i, token)
  if token ~= cdToken[i] then return end
  local spell = sbw:recursiveGetChildById('spell'..i)
  local progress = sbw:recursiveGetChildById('progress'..i)
  if not spell or not progress then return end
  local remaining = (cdEnd[i] or 0) - g_clock.millis()
  if remaining > 0 then
    local total = math.max(spell.exhaustion or 0, remaining)
    progress:setPercent(math.floor((total - remaining) * 100 / total))
    progress:setText(tostring(math.ceil(remaining / 1000)))
    progress:setColor('white')
    scheduleEvent(function() spellTimeleft(i, token) end, 100)
  else
    cdEnd[i] = nil
    progress:setPercent(100)
    progress:setText('')
  end
end

-- ===================== Mover la barra =====================

function justDragged()
  return isDragging or g_clock.millis() - lastDragEnd < 200
end

function makeDraggable(widget)
  widget:setDraggable(true)
  widget.onDragEnter = function(self, mousePos)
    if locked then return false end
    dragStart = mousePos
    dragOffset = { x = mousePos.x - sbw:getX(), y = mousePos.y - sbw:getY() }
    return true
  end
  widget.onDragMove = function(self, mousePos, mouseMoved)
    if not dragStart then return true end
    if not isDragging then
      if math.abs(mousePos.x - dragStart.x) < DRAG_THRESHOLD and math.abs(mousePos.y - dragStart.y) < DRAG_THRESHOLD then
        return true
      end
      isDragging = true
      hideMoveTip()
      sbw:breakAnchors()
    end
    sbw:setPosition({ x = mousePos.x - dragOffset.x, y = mousePos.y - dragOffset.y })
    sbw:bindRectToParent()
    return true
  end
  widget.onDragLeave = function(self, droppedWidget, mousePos)
    if isDragging then
      lastDragEnd = g_clock.millis()
      g_settings.set('pokemonmoves_pos', sbw:getPosition())
    end
    isDragging = false
    dragStart = nil
    return true
  end
end

-- ===================== Smart Combo =====================

local function findSlot(words)
  for i = 1, #spells do
    if spells[i].words:lower() == words:lower() then return i end
  end
  return nil
end

local function comboPosition(words)
  for pos, w in ipairs(comboSequence) do
    if w:lower() == words:lower() then return pos end
  end
  return nil
end

local function saveCombo()
  if comboKey then
    g_settings.set(comboKey, table.concat(comboSequence, ','))
  end
end

-- Se llama cada vez que el servidor manda la lista de ataques (al sacar un pokemon)
function onMovesReceived()
  local names = {}
  for i = 1, #spells do names[#names + 1] = spells[i].words end
  comboKey = 'smartcombo_' .. (table.concat(names, '_'):gsub('[^%w]', '_'))

  comboSequence = {}
  local saved = g_settings.get(comboKey) or ''
  for _, w in ipairs(saved:split(',')) do
    if w ~= '' and findSlot(w) then comboSequence[#comboSequence + 1] = w end
  end
  comboPos = 1
  refreshComboWindow()
end

function updateComboToggle()
  local toggle = sbw and sbw:recursiveGetChildById('comboToggle')
  if toggle then
    if comboRunning then
      toggle:setText((comboPos - 1) .. '/' .. #comboSequence)
      toggle:setImageSource(IMG_SLOT_ACTIVE)
      toggle:setColor('#ffffff')
    else
      toggle:setText('AUTO')
      toggle:setImageSource(toggle.hovered and IMG_SLOT_HOVER or IMG_SLOT)
      toggle:setColor(#comboSequence > 0 and '#ffd84a' or '#8a98ab')
    end
  end
  if comboWindow then
    local seq = comboWindow:getChildById('sequencePanel')
    for pos, child in ipairs(seq:getChildren()) do
      local current = comboRunning and pos == comboPos - 1
      child:setImageSource(current and IMG_SLOT_ACTIVE or (child.hovered and IMG_SLOT_HOVER or IMG_SLOT))
    end
  end
end

-- Marca en dorado el hueco del ataque que acaba de lanzar el combo
local function flashSpell(slot)
  local widget = sbw:recursiveGetChildById('slot' .. slot)
  if not widget then return end
  widget.flashing = true
  widget:setImageSource(IMG_SLOT_ACTIVE)
  scheduleEvent(function()
    if widget:isDestroyed() then return end
    widget.flashing = false
    widget:setImageSource(IMG_SLOT)
  end, COMBO_GAP)
end

-- Lanza la secuencia entera una vez (desde la hotkey "combo", el boton de la barra o el menu)
function runCombo()
  if not g_game.isOnline() then return end
  if not sbw:isVisible() then
    modules.game_textmessage.displayFailureMessage('Saca primero a tu pokemon.')
    return
  end
  if #comboSequence == 0 then
    modules.game_textmessage.displayFailureMessage('Configura primero el Smart Combo (clic derecho en la barra).')
    return
  end
  if comboRunning then return end
  local slots = {}
  for _, w in ipairs(comboSequence) do
    local slot = findSlot(w)
    if slot then slots[#slots + 1] = slot end
  end
  if #slots == 0 then return end
  -- se manda desde la tecla/clic, asi la proteccion anti-bot no lo bloquea
  g_game.talk('smartcombo ' .. table.concat(slots, ','))
  comboRunning = true
  comboPos = 1
  removeEvent(comboEvent)
  comboEvent = scheduleEvent(function() comboEvent = nil stopCombo() end, #slots * (COMBO_GAP + 600) + 3000)
  updateComboToggle()
end

function stopCombo()
  comboRunning = false
  comboPos = 1
  removeEvent(comboEvent)
  comboEvent = nil
  updateComboToggle()
end

function toggleComboWindow()
  hideMoveTip()
  if comboWindow then
    comboWindow:destroy()
    comboWindow = nil
    return
  end
  comboWindow = g_ui.displayUI('smartcombo')
  refreshComboWindow()
end

function addToCombo(words)
  if comboPosition(words) then return end
  comboSequence[#comboSequence + 1] = words
  saveCombo()
  refreshComboWindow()
end

function removeFromCombo(pos)
  table.remove(comboSequence, pos)
  if comboRunning then stopCombo() end
  saveCombo()
  refreshComboWindow()
end

function clearCombo()
  comboSequence = {}
  if comboRunning then stopCombo() end
  saveCombo()
  refreshComboWindow()
end

-- Icono del Smart Combo con numero opcional y tooltip
local function createComboIcon(parent, slot, number, hint, onClick)
  local b = g_ui.createWidget('ComboIcon', parent)
  b:getChildById('icon'):setImageSource(iconPath(spells[slot].words))
  setKeyLabel(b:getChildById('number'), number and tostring(number) or nil)
  b.onClick = onClick
  b.onHoverChange = function(widget, hovered)
    widget.hovered = hovered
    if hovered then
      widget:setImageSource(IMG_SLOT_HOVER)
      showMoveTip(widget, slot, hint)
    else
      widget:setImageSource(IMG_SLOT)
      hideMoveTip()
      updateComboToggle()
    end
  end
  return b
end

-- Alto de una caja con iconos en rejilla (40px, separacion 6, relleno 8)
local function boxHeight(box, count)
  local inner = box:getWidth() - 16
  if inner <= 0 then inner = 380 end
  local perRow = math.max(1, math.floor((inner + 6) / 46))
  local rows = math.max(1, math.ceil(count / perRow))
  return rows * 40 + (rows - 1) * 6 + 16
end

function refreshComboWindow()
  if not comboWindow then return end
  hideMoveTip()
  comboWindow:getChildById('pokemonLabel'):setText(pokemonName or 'Saca a tu pokemon')

  local portrait = comboWindow:getChildById('portrait')
  local creature = comboWindow:getChildById('portraitCreature')
  -- misma imagen que usa la barra de pokemons (game_pokemonbar/bar_icon/<nombre>.png)
  local img = pokemonName and ('/game_pokemonbar/bar_icon/' .. pokemonName:lower() .. '.png')
  if img and g_resources.fileExists(img) then
    portrait:setImageSource(img)
    portrait:show()
    creature:hide()
  elseif pokemonLook and pokemonLook > 0 then
    creature:setOutfit({ type = pokemonLook })
    creature:show()
    portrait:hide()
  else
    portrait:hide()
    creature:hide()
  end

  local movesBox = comboWindow:getChildById('movesBox')
  movesBox:destroyChildren()
  for i = 1, #spells do
    local words = spells[i].words
    local pos = comboPosition(words)
    local b
    if pos then
      b = createComboIcon(movesBox, i, pos, 'En el combo (#' .. pos .. '). Clic para quitarlo.',
        function() removeFromCombo(pos) end)
      b:getChildById('icon'):setOpacity(0.35)
    else
      b = createComboIcon(movesBox, i, nil, 'Clic para anadirlo al combo.',
        function() addToCombo(words) end)
    end
  end

  local seq = comboWindow:getChildById('sequencePanel')
  seq:destroyChildren()
  for pos, words in ipairs(comboSequence) do
    local slot = findSlot(words)
    if slot then
      createComboIcon(seq, slot, pos, 'Paso ' .. pos .. ' del combo. Clic para quitarlo.',
        function() removeFromCombo(pos) end)
    end
  end
  comboWindow:getChildById('emptyLabel'):setVisible(#comboSequence == 0)
  comboWindow:getChildById('countLabel'):setText(#comboSequence .. ' / ' .. #spells)

  local comboHotkey = hotkeyFor('combo')
  comboWindow:getChildById('hintLabel'):setText(comboHotkey and ('Tecla del combo: ' .. comboHotkey)
    or 'Hotkey (Ctrl+K) con el texto: combo')

  -- ajustar alturas a la cantidad de iconos
  local h1 = boxHeight(movesBox, #spells)
  local h2 = boxHeight(seq, #comboSequence)
  movesBox:setHeight(h1)
  seq:setHeight(h2)
  comboWindow:setHeight(258 + h1 + h2)
  updateComboToggle()
end

-- El servidor confirma cada ataque con "Pokemon, use X!": avanzar el contador y destacar el icono
function onComboMoveUsed(words)
  if not comboRunning then return end
  local pos = comboPosition(words)
  if pos then comboPos = pos + 1 end
  local slot = findSlot(words)
  if slot then flashSpell(slot) end
  updateComboToggle()
end

-- Opcode 61: "lanzados|slot:motivo,slot:motivo"
function onComboDone(protocol, opcode, buffer)
  local parts = buffer:split('|')
  local skipped = {}
  for _, entry in ipairs((parts[2] or ''):split(',')) do
    local slot, reason = entry:match('^(%d+):(.*)$')
    slot = tonumber(slot)
    if slot and spells[slot] then
      skipped[#skipped + 1] = titleCase(spells[slot].words) .. ' (' .. reason .. ')'
    end
  end
  if #skipped > 0 then
    modules.game_textmessage.displayFailureMessage('Combo: no salio ' .. table.concat(skipped, ', '))
  end
  stopCombo()
end
