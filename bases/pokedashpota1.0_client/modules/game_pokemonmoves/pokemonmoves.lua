-- spell bar by Pota based on draky's
local spells = {}
local spellsNumber = 12
local OPCODE_SKILLBAR = 52
local side = 'vertical'
local sbw -- window widget
local spellBarWindow -- UIWindow
local hideLevel = false -- hide spells that can not be used due to level dependence

-- Smart Combo
local COMBO_TICK = 200       -- ms entre comprobaciones
local COMBO_GAP = 800        -- ms minimos entre dos ataques
local CONFIRM_TIMEOUT = 1200 -- ms esperando a que el pokemon diga "use X!"
local SERVER_MARGIN = 1100   -- el servidor cuenta el cooldown en segundos enteros
local PENDING_RETRY = 1500   -- si el servidor no confirma el ataque, reintentar tras esto
local comboWindow
local comboSequence = {}     -- nombres de ataques en orden
local comboRunning = false   -- true mientras se esta lanzando la secuencia
local comboEvent
local comboPos = 1
local comboSkipped = {}      -- ataques que el combo no pudo lanzar en esta pasada
local comboPending           -- ataque enviado esperando confirmacion {words, slot, sentAt, tries, confirmed}
local lastServerMsg = ''     -- ultimo mensaje del servidor (para saber por que fallo un ataque)
local lastServerMsgAt = 0
local lastCast = 0
local readyAt = {}           -- [nombre en minusculas] = g_clock.millis() en que vuelve a estar listo
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
     -- el tipo OBJETIVO/AREA sale de movesdata.lua (mas fiable que lo que manda el servidor)
     local d = MOVES_DATA and MOVES_DATA[moves[i]:lower()]
     if d and inside.isTarget ~= 1 then inside.isTarget = d[1] end
     table.insert(spells, inside)
     if inside.cooldownRemaining > 0 then cdEnd[i] = now + inside.cooldownRemaining end
  end
  onMovesReceived()
  getSpells(spells)
  level = g_game.getLocalPlayer():getLevel()
  sbw:show()
end

function init()
  sbw = g_ui.displayUI('pokemonmoves')
  local savedPos = g_settings.getPoint('pokemonmoves_pos')
  if savedPos and (savedPos.x ~= 0 or savedPos.y ~= 0) then
    sbw:setPosition(savedPos)
    sbw:bindRectToParent()
  else
    sbw:move(10,50)
  end
  makeDraggable(sbw:recursiveGetChildById('mainWindow'))
  g_mouse.bindPress(sbw, function() createMenu() end, MouseRightButton)
  sbw:hide()
  connect(g_game, 'onTalk', messageSentCallback)
  connect(g_game, { onTextMessage = onServerText })
  connect(g_game, { onGameEnd = function() sbw:hide() end })
  connect(LocalPlayer, {
    onLevelChange = onLevelChange
  })
  ProtocolGame.registerExtendedOpcode(OPCODE_SKILLBAR, getOpCode)
  ProtocolGame.registerExtendedOpcode(OPCODE_POKEINFO, onPokemonInfo)
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

function onServerText(mode, text)
  lastServerMsg = text or ''
  lastServerMsgAt = g_clock.millis()
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
    if comboPending and text and comboPending.words:lower() == text:lower() then
      comboPending.confirmed = true
    end
    for i = 1, #spells do
      if spells[i].words:lower() == text:lower() then 
        readyAt[text:lower()] = g_clock.millis() + (spells[i].exhaustion or 0) + SERVER_MARGIN
        startDownDelay(i)
        break
      end
    end
  elseif msgcontains(text, "thanks") then
    sbw:hide()
  end
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_SKILLBAR)
  ProtocolGame.unregisterExtendedOpcode(OPCODE_POKEINFO)
  removeEvent(comboEvent)
  g_settings.set('pokemonmoves_pos', sbw:getPosition())
  if comboWindow then comboWindow:destroy() comboWindow = nil end
  sbw:destroy()
  disconnect(g_game, { onGameEnd = function() sbw:hide() end })
  disconnect(g_game, 'onTalk', messageSentCallback)
  disconnect(g_game, { onTextMessage = onServerText })
  disconnect(LocalPlayer, {
    onLevelChange = onLevelChange
  })
end

function createMenu()
  if isDragging or g_clock.millis() - lastDragEnd < 200 then return end
  local menu = g_ui.createWidget('PopupMenu')
  if side == 'horizontal' then
    menu:addOption('Poner vertical', function() side = 'vertical' getSpells(spells) end)
  else
    menu:addOption('Poner horizontal',function() side = 'horizontal' getSpells(spells) end)
  end
  menu:addSeparator()
  menu:addOption('Abrir Smart Combo', function() toggleComboWindow() end)
  menu:addOption('Lanzar combo', function() runCombo() end)
  menu:display()
end

function destroySpells()
  local toggle = sbw:recursiveGetChildById('comboToggle')
  if toggle then toggle:destroy() end
  for i = 1, spellsNumber do
    if sbw:recursiveGetChildById('spell'..i) == nil then break end
    sbw:recursiveGetChildById('spell'..i):destroy()
    sbw:recursiveGetChildById('progress'..i):destroy()
  end
end

function getSpells(table)
  destroySpells()
  spellBarWindow = sbw:recursiveGetChildById('mainWindow')
  local player = g_game.getLocalPlayer()
  local value = #table
  local width = 38
  local height = 38
  if not player then return end
  for i = 1, #table do
    if (table[i].lvl > player:getLevel()) and hideLevel == true then
      value = i - 1
      break
    end
    if i == #table then value = i end
    icon = g_ui.createWidget('SpellButton',spellBarWindow)
    --icon:
    icon:setId('spell'..i)
    local pathOn = "moves_icon/"..table[i].words.."_on.png"
    icon:setImageSource(pathOn)
    icon:setVisible(true) 
    icon.words = table[i].words
    icon.lvl = table[i].lvl
    icon.exhaustion = table[i].exhaustion
    icon.exhaustionNeeded = icon.exhaustion - table[i].cooldownRemaining
    icon:setTooltip(moveTooltip(i))
    if side == 'horizontal' then
      icon:setMarginTop(3)
      height = 38
      width = (i) * 32 + 2*(i)
      icon:setMarginLeft((i) * 32 + 2*(i) - 32)
    else
      icon:setMarginLeft(3)
      icon:setMarginTop((i) * 32 + 2*(i) - 32)
      width = 38
      height = (i) * 32 + 2*(i)
    end
    --progress:
    progress = g_ui.createWidget('SpellProgressSpell',spellBarWindow)
    progress:setId('progress'..i)
    progress:setVisible(true)
    progress:setPercent(100)
    progress:setMarginLeft(icon:getMarginLeft())
    progress:setMarginTop(icon:getMarginTop())
    if player:getLevel() < icon.lvl then progress:setText('L'..icon.lvl) progress:setColor('red') progress:setPercent(0) end
    if progress:getPercent() == 100 then progress:setText('') elseif icon.lvl < player:getLevel() then progress:setText(progress:getPercent()) end
    progress:setPhantom(true)
    makeDraggable(icon)
    icon.onClick = function() if not justDragged() then useSpell(i) end end
    if cdEnd[i] and cdEnd[i] > g_clock.millis() then
      startCooldown(i, cdEnd[i] - g_clock.millis())
    end
  end
  local n = #table + 1
  local toggle = g_ui.createWidget('ComboToggle', spellBarWindow)
  toggle:setId('comboToggle')
  if side == 'horizontal' then
    toggle:setMarginTop(3)
    toggle:setMarginLeft(n * 32 + 2 * n - 32)
    width = n * 32 + 2 * n
  else
    toggle:setMarginLeft(3)
    toggle:setMarginTop(n * 32 + 2 * n - 32)
    height = n * 32 + 2 * n
  end
  makeDraggable(toggle)
  toggle.onClick = function() if not justDragged() then runCombo() end end
  updateComboToggle()
  sbw:setHeight(height)
  sbw:setWidth(width)  
  spellBarWindow:setSize(sbw:getSize())
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

local function iconPath(words)
  return "moves_icon/" .. words .. "_on.png"
end

-- ---------- Informacion de los movimientos ----------

local ELEMENTS = {
  electric = {'Electrico', '#f8d030'}, fire = {'Fuego', '#f08030'}, water = {'Agua', '#6890f0'},
  grass = {'Planta', '#78c850'}, normal = {'Normal', '#c6c6a7'}, psychic = {'Psiquico', '#f85888'},
  poison = {'Veneno', '#c060c0'}, bug = {'Bicho', '#a8b820'}, ground = {'Tierra', '#e0c068'},
  rock = {'Roca', '#b8a038'}, flying = {'Volador', '#a890f0'}, fighting = {'Lucha', '#e05048'},
  ghost = {'Fantasma', '#9080c0'}, ice = {'Hielo', '#98d8d8'}, dragon = {'Dragon', '#8058f8'},
  dark = {'Siniestro', '#a08070'}, steel = {'Acero', '#b8b8d0'}, fairy = {'Hada', '#ee99ac'},
}

local CATEGORY_SHAPE = {
  areawaves = 'Ondas alrededor de tu pokemon',
  frontlinear = 'Rayo en linea recta hacia delante',
  frontarea = 'Gran area delante de tu pokemon',
  areatarget = 'Area alrededor del objetivo',
  ultimate = 'Definitivo: gran area alrededor',
  passive = 'Habilidad pasiva',
}

local CATEGORY_POWER = {
  singletargetweak = 'dano bajo', areawaves = 'dano medio', singletarget = 'dano medio',
  areatarget = 'dano medio', passive = 'dano medio', singletargetstrong = 'dano alto',
  frontarea = 'dano alto', frontlinear = 'dano muy alto', ultimate = 'dano maximo',
}

local EFFECTS = {
  poison = 'envenena', burn = 'quema', heal = 'cura',
  buff = 'mejora a tu pokemon', slow = 'ralentiza',
}

local function titleCase(s)
  return (s:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
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

function moveIsTarget(slot)
  local s = spells[slot]
  return s and s.isTarget == 1
end

function moveTypeText(slot)
  local s = spells[slot]
  if not s or s.isTarget == nil then return '?' end
  return s.isTarget == 1 and 'OBJETIVO' or 'AREA'
end

function moveCooldownText(slot)
  local s = spells[slot]
  if not s or not s.exhaustion then return '' end
  return 'CD ' .. math.floor(s.exhaustion / 1000 + 0.5) .. 's'
end

function moveElement(slot)
  return ELEMENTS[infoFor(slot).element or '']
end

-- Ej: "Golpea a tu objetivo, dano medio, alcance 1 sqm"
function moveDescription(slot)
  local s = spells[slot]
  if not s then return '' end
  local info = infoFor(slot)
  local parts = {}
  if s.isTarget == 1 then
    parts[1] = 'Golpea a tu objetivo'
  else
    parts[1] = CATEGORY_SHAPE[info.category or ''] or 'Ataque en area'
  end
  if CATEGORY_POWER[info.category or ''] then parts[#parts + 1] = CATEGORY_POWER[info.category] end
  if EFFECTS[info.effect or ''] then parts[#parts + 1] = EFFECTS[info.effect] end
  if s.range and s.range > 0 then parts[#parts + 1] = 'alcance ' .. s.range .. ' sqm' end
  return table.concat(parts, ', ')
end

function moveTooltip(slot)
  local s = spells[slot]
  if not s then return '' end
  local el = moveElement(slot)
  local line2 = moveTypeText(slot) .. '  |  ' .. moveCooldownText(slot)
  if el then line2 = line2 .. '  |  ' .. el[1] end
  return 'M' .. slot .. ' - ' .. titleCase(s.words) .. '\n' .. line2 .. '\n' .. moveDescription(slot)
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

  local now = g_clock.millis()
  readyAt = {}
  for i = 1, #spells do
    local remaining = spells[i].cooldownRemaining or 0
    if remaining > 0 then
      readyAt[spells[i].words:lower()] = now + remaining + SERVER_MARGIN
    end
  end
  comboPos = 1
  refreshComboWindow()
end

function updateComboToggle()
  local toggle = sbw and sbw:recursiveGetChildById('comboToggle')
  if toggle then
    toggle:setTooltip('Lanzar Smart Combo\nAsigna una tecla en Hotkeys (Ctrl+K) con el texto: combo')
    if comboRunning then
      toggle:setText((comboPos - 1) .. '/' .. #comboSequence)
      toggle:setBackgroundColor('#2e7d32dd')
      toggle:setBorderColor('#7CFC00')
      toggle:setColor('#ffffff')
    else
      toggle:setText('AUTO')
      toggle:setBackgroundColor('#13263fdd')
      toggle:setBorderColor('#4f7fb8')
      toggle:setColor(#comboSequence > 0 and '#ffd84a' or '#8a98ab')
    end
  end
  if comboWindow then
    local seq = comboWindow:getChildById('sequencePanel')
    for pos, child in ipairs(seq:getChildren()) do
      local current = comboRunning and pos == comboPos - 1
      child:setBorderColor(current and '#ffd84a' or '#2f4a6e')
      child:setBorderWidth(current and 2 or 1)
    end
  end
end

-- Marca en amarillo el icono del ataque que acaba de lanzar el combo
local function flashSpell(slot)
  local icon = sbw:recursiveGetChildById('spell' .. slot)
  if not icon then return end
  icon:setBorderWidth(2)
  icon:setBorderColor('#ffd84a')
  scheduleEvent(function()
    if not icon:isDestroyed() then icon:setBorderWidth(0) end
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
  comboRunning = true
  comboPos = 1
  comboSkipped = {}
  comboPending = nil
  updateComboToggle()
  comboLoop()
end

local function stopCombo()
  comboRunning = false
  comboPos = 1
  comboPending = nil
  removeEvent(comboEvent)
  comboEvent = nil
  updateComboToggle()
end

function toggleComboWindow()
  if comboWindow then
    comboWindow:destroy()
    comboWindow = nil
    return
  end
  comboWindow = g_ui.displayUI('smartcombo')
  refreshComboWindow()
end

function addToCombo(words)
  for _, w in ipairs(comboSequence) do
    if w:lower() == words:lower() then return end
  end
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

local function findPokemonCreature()
  local player = g_game.getLocalPlayer()
  if not player or not pokemonName then return nil end
  local best, bestDist
  for _, c in ipairs(g_map.getSpectators(player:getPosition(), false)) do
    if c:getName() == pokemonName and not c:isPlayer() then
      local p = c:getPosition()
      local d = math.max(math.abs(p.x - player:getPosition().x), math.abs(p.y - player:getPosition().y))
      if not bestDist or d < bestDist then best, bestDist = c, d end
    end
  end
  return best
end

local function createSlot(parent, words, number)
  local slot = g_ui.createWidget('ComboSlot', parent)
  slot:getChildById('icon'):setImageSource(iconPath(words))
  slot:getChildById('number'):setText(number and tostring(number) or '')
  return slot
end

local function comboPosition(words)
  for pos, w in ipairs(comboSequence) do
    if w:lower() == words:lower() then return pos end
  end
  return nil
end

local function createMoveRow(parent, slot)
  local s = spells[slot]
  local row = g_ui.createWidget('MoveRow', parent)
  row:getChildById('key'):setText('M' .. slot)
  row:getChildById('icon'):setImageSource(iconPath(s.words))
  row:getChildById('name'):setText(titleCase(s.words))
  row:getChildById('desc'):setText(moveDescription(slot))
  row:getChildById('cd'):setText(moveCooldownText(slot))

  local badge = row:getChildById('badge')
  badge:setText(moveTypeText(slot))
  if s.isTarget == 1 then
    badge:setBackgroundColor('#8e2b2b')
  elseif s.isTarget ~= nil then
    badge:setBackgroundColor('#1f5fa8')
  else
    badge:setBackgroundColor('#444c58')
  end

  local el = moveElement(slot)
  local element = row:getChildById('element')
  if el then
    element:setText(el[1])
    element:setColor(el[2])
  else
    element:setText('')
  end

  local pos = comboPosition(s.words)
  local inCombo = row:getChildById('inCombo')
  if pos then
    inCombo:setText('#' .. pos)
    row:setTooltip('Ya esta en el combo (posicion ' .. pos .. '). Clic en la secuencia para quitarlo.')
  else
    inCombo:setText('+')
    row:setTooltip('Clic para anadirlo al combo')
  end
  row.onClick = function() addToCombo(s.words) end
  return row
end

function refreshComboWindow()
  if not comboWindow then return end
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

  local list = comboWindow:getChildById('movesList')
  list:destroyChildren()
  for i = 1, #spells do
    createMoveRow(list, i)
  end

  local seq = comboWindow:getChildById('sequencePanel')
  seq:destroyChildren()
  for pos, words in ipairs(comboSequence) do
    local b = createSlot(seq, words, pos)
    local slot = findSlot(words)
    b:setTooltip((slot and moveTooltip(slot) or words) .. '\n\nClic para quitar del combo')
    b.onClick = function() removeFromCombo(pos) end
  end
  comboWindow:getChildById('emptyLabel'):setVisible(#comboSequence == 0)

  comboWindow:getChildById('countLabel'):setText(#comboSequence .. ' movimiento(s)')
  updateComboToggle()
end

-- Lanza los ataques de la secuencia uno tras otro.
-- Salta los que esten en cooldown y, si no estas atacando (o el objetivo esta lejos),
-- los que necesitan objetivo. Los de area se lanzan siempre.
local function canCastNow(slot)
  local spell = spells[slot]
  if spell.isTarget ~= 1 then return true end
  local target = g_game.getAttackingCreature()
  if not target then return false end
  if spell.range and spell.range > 0 then
    local poke = findPokemonCreature()
    if poke then
      local a, b = poke:getPosition(), target:getPosition()
      if a.z ~= b.z or math.max(math.abs(a.x - b.x), math.abs(a.y - b.y)) > spell.range then
        return false
      end
    end
  end
  return true
end

function comboTick()
  if not comboRunning then return end
  if not g_game.isOnline() or not sbw:isVisible() then return stopCombo() end
  local now = g_clock.millis()

  -- Esperar a que el servidor confirme el ultimo ataque ("Raichu, use X!")
  if comboPending then
    local p = comboPending
    if p.confirmed then
      comboPending = nil
    elseif now - p.sentAt < CONFIRM_TIMEOUT then
      return
    else
      local serverSaid = lastServerMsgAt >= p.sentAt and lastServerMsg ~= ''
      if not serverSaid and p.tries < 2 then
        -- el servidor no contesto nada: reintentar una vez
        p.tries = p.tries + 1
        p.sentAt = now
        g_game.talk('m' .. p.slot)
        return
      end
      local reason = serverSaid and lastServerMsg or 'el servidor no respondio'
      comboSkipped[#comboSkipped + 1] = titleCase(p.words) .. ' (' .. reason .. ')'
      g_logger.info('[SmartCombo] ' .. p.words .. ' (m' .. p.slot .. ') fallo: ' .. reason)
      readyAt[p.words:lower()] = nil
      comboPending = nil
    end
  end

  if now - lastCast < COMBO_GAP then return end

  while comboPos <= #comboSequence do
    local words = comboSequence[comboPos]
    local slot = findSlot(words)
    comboPos = comboPos + 1
    if slot then
      if now < (readyAt[words:lower()] or 0) then
        comboSkipped[#comboSkipped + 1] = titleCase(words) .. ' (recarga)'
      elseif not canCastNow(slot) then
        comboSkipped[#comboSkipped + 1] = titleCase(words) .. ' (sin objetivo)'
      else
        g_game.talk('m' .. slot)
        comboPending = { words = words, slot = slot, sentAt = now, tries = 1 }
        lastCast = now
        readyAt[words:lower()] = now + PENDING_RETRY
        flashSpell(slot)
        updateComboToggle()
        return
      end
    end
  end
  if #comboSkipped > 0 then
    local msg = 'Combo: no salio ' .. table.concat(comboSkipped, ', ')
    g_logger.info('[SmartCombo] ' .. msg)
    modules.game_textmessage.displayFailureMessage(msg)
  end
  stopCombo()
end

-- Repite comboTick cada COMBO_TICK ms mientras el combo este en marcha
function comboLoop()
  comboEvent = nil
  comboTick()
  if comboRunning then
    comboEvent = scheduleEvent(comboLoop, COMBO_TICK)
  end
end
