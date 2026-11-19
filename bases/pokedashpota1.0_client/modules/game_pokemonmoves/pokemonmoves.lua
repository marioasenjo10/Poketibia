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
local COMBO_GAP = 700        -- ms minimos entre dos ataques
local SERVER_MARGIN = 1100   -- el servidor cuenta el cooldown en segundos enteros
local PENDING_RETRY = 1500   -- si el servidor no confirma el ataque, reintentar tras esto
local comboWindow
local comboSequence = {}     -- nombres de ataques en orden
local comboActive = false
local comboEvent
local comboPos = 1
local lastCast = 0
local readyAt = {}           -- [nombre en minusculas] = g_clock.millis() en que vuelve a estar listo
local comboKey
local pokemonName

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
  local cooldowns = {}
  local cooldownRemaining = {}
  spells = {}
  for match in string.gmatch(buffer, "([^,]+),%s*") do
    if tonumber(match) == nil then
      moves[#moves + 1] = match
    else
      if #cooldowns < #moves then
        cooldowns[#cooldowns + 1] = tonumber(match)
      else
        cooldownRemaining[#cooldownRemaining + 1] = tonumber(match)        
      end
    end
  end
  for i = 1, #moves do
     local inside = {id = i, words = moves[i], lvl = 1, exhaustion = cooldowns[i], cooldownRemaining = cooldownRemaining[i]}
     table.insert(spells, inside)
  end
  onMovesReceived()
  getSpells(spells)
  level = g_game.getLocalPlayer():getLevel()
  sbw:show()
end

function init()
  sbw = g_ui.displayUI('pokemonmoves')
  sbw:move(10,50)
  g_mouse.bindPress(sbw, function() createMenu() end, MouseRightButton)
  sbw:hide()
  connect(g_game, 'onTalk', messageSentCallback)
  connect(g_game, { onGameEnd = function() sbw:hide() end })
  connect(LocalPlayer, {
    onLevelChange = onLevelChange
  })
  ProtocolGame.registerExtendedOpcode(OPCODE_SKILLBAR, getOpCode)
  comboEvent = cycleEvent(comboTick, COMBO_TICK)
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
  removeEvent(comboEvent)
  if comboWindow then comboWindow:destroy() comboWindow = nil end
  sbw:destroy()
  disconnect(g_game, { onGameEnd = function() sbw:hide() end })
  disconnect(g_game, 'onTalk', messageSentCallback)
  disconnect(LocalPlayer, {
    onLevelChange = onLevelChange
  })
end

function createMenu()
  local menu = g_ui.createWidget('PopupMenu')
  if side == 'horizontal' then
    menu:addOption('Poner vertical', function() side = 'vertical' getSpells(spells) end)
  else
    menu:addOption('Poner horizontal',function() side = 'horizontal' getSpells(spells) end)
  end
  menu:addSeparator()
  menu:addOption('Abrir Smart Combo', function() toggleComboWindow() end)
  menu:addOption(comboActive and 'Desactivar auto combo' or 'Activar auto combo', function() toggleCombo() end)
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
    icon:setTooltip(table[i].words)
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
    icon.onClick = function() useSpell(i) end
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
  toggle.onClick = function() toggleCombo() end
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
  local progress = sbw:recursiveGetChildById('progress'..i)
  progress:setPercent(0)
  progress:setText('0%')
  progress:setColor('red')
  spell.exhaustionNeeded = 0
  scheduleEvent(function() spellTimeleft(i) end,100) 
end

function spellTimeleft(i)
  local spell = sbw:recursiveGetChildById('spell'..i)
  if not spell then return end
  local progress = sbw:recursiveGetChildById('progress'..i)
  spell.exhaustionNeeded = spell.exhaustionNeeded + 100
  if spell.exhaustionNeeded < spell.exhaustion then
    progress:setPercent(math.floor(((spell.exhaustionNeeded) * 100)/spell.exhaustion))
    progress:setText(progress:getPercent())
    progress:setColor('red')
  else
    progress:setPercent(100)
    progress:setText('')
    spell.exhaustionNeeded = 0    
    return true
  end
  scheduleEvent(function() spellTimeleft(i) end,100) 
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
    if comboActive then
      toggle:setBackgroundColor('#2e7d32cc')
      toggle:setColor('#ffffff')
      toggle:setTooltip('Auto combo ACTIVADO (clic para desactivar)')
    else
      toggle:setBackgroundColor('#00000099')
      toggle:setColor('#bbbbbb')
      toggle:setTooltip('Auto combo desactivado (clic para activar)')
    end
  end
  if comboWindow then
    comboWindow:getChildById('toggleButton'):setText(comboActive and 'Desactivar auto combo' or 'Activar auto combo')
  end
end

function toggleCombo()
  if not comboActive and #comboSequence == 0 then
    modules.game_textmessage.displayFailureMessage('Configura primero el Smart Combo (clic derecho en la barra).')
    return
  end
  comboActive = not comboActive
  comboPos = 1
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
  if comboPos > #comboSequence then comboPos = 1 end
  if #comboSequence == 0 and comboActive then
    comboActive = false
    updateComboToggle()
  end
  saveCombo()
  refreshComboWindow()
end

function clearCombo()
  comboSequence = {}
  comboPos = 1
  if comboActive then
    comboActive = false
    updateComboToggle()
  end
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

function refreshComboWindow()
  if not comboWindow then return end
  comboWindow:getChildById('pokemonLabel'):setText(pokemonName or 'Pokemon actual')
  local creature = findPokemonCreature()
  local portrait = comboWindow:getChildById('portrait')
  if creature then
    portrait:setCreature(creature)
    portrait:show()
  else
    portrait:hide()
  end

  local avail = comboWindow:getChildById('availablePanel')
  avail:destroyChildren()
  for i = 1, #spells do
    local words = spells[i].words
    local b = createSlot(avail, words)
    b:setTooltip(words .. ' (clic para agregar)')
    b.onClick = function() addToCombo(words) end
  end

  local seq = comboWindow:getChildById('sequencePanel')
  seq:destroyChildren()
  for pos, words in ipairs(comboSequence) do
    local b = createSlot(seq, words, pos)
    b:setTooltip(pos .. '. ' .. words .. ' (clic para quitar)')
    b.onClick = function() removeFromCombo(pos) end
  end

  comboWindow:getChildById('countLabel'):setText(#comboSequence .. ' movimiento(s)')
  updateComboToggle()
end

-- Bucle del auto combo: lanza el siguiente ataque listo de la secuencia
function comboTick()
  if not comboActive or #comboSequence == 0 then return end
  if not g_game.isOnline() or not sbw:isVisible() then return end
  if not g_game.isAttacking() then return end
  local now = g_clock.millis()
  if now - lastCast < COMBO_GAP then return end

  local n = #comboSequence
  for k = 0, n - 1 do
    local pos = (comboPos - 1 + k) % n + 1
    local words = comboSequence[pos]
    local slot = findSlot(words)
    if slot and now >= (readyAt[words:lower()] or 0) then
      g_game.talk('m' .. slot)
      lastCast = now
      readyAt[words:lower()] = now + PENDING_RETRY
      comboPos = pos % n + 1
      return
    end
  end
end
