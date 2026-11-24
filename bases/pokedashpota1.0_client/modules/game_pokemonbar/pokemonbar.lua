-- Pokebar: el equipo con la vida de cada pokemon y sus ataques listos (7/7, 9/10...).
-- Pokemon activo (en "Estado de combate"): retrato, nombre, vida en directo y ataques listos.
--
-- Opcode 53 (servidor -> cliente): ",Nombre,%vida,fuera(0/1),nAtaques,cd1;cd2;...," por pokemon,
--   cdN = segundos de cooldown que le quedan al ataque N ("-" si no tiene ataques).
-- Opcode 60 (lo recibe game_pokemonmoves y llama a onActiveInfo): pokemon que acaba de salir,
--   con el id de su criatura (la vida se lee de la criatura en directo).
-- Opcode 70: el pokemon activo se ha guardado o ha muerto.

local OPCODE_POKEBAR = 53
local OPCODE_ACTIVE_GONE = 70
local ROW_HEIGHT = 56 -- capsula de 52 + 4 de separacion
local ICONS = '/game_pokemonbar/bar_icon/'

local pokebarWindow
local pokebarButton
local pokebarHidden = false -- oculta con el boton de arriba (se recuerda)
local pokes = {}       -- {name, health, used, total, cdEnd = {ms...}}
local active = nil    -- {name, look, id, maxHealth, health}
local tickEvent

-- ilustracion de la pokedex (game_pokedex/artwork, 128x128); si no hay, el icono pequeno
local function iconFor(name)
  local artwork = '/game_pokedex/artwork/' .. name:lower() .. '.png'
  if g_resources.fileExists(artwork) then
    return artwork
  end
  local path = ICONS .. name:lower() .. '.png'
  if g_resources.fileExists(path) then
    return path
  end
  return nil
end

local function healthColor(percent)
  if percent > 50 then
    return '#2f9e44'
  elseif percent > 20 then
    return '#c99a2e'
  end
  return '#c2413a'
end

local function setHealth(bar, percent, text)
  bar:setPercent(percent)
  bar:setBackgroundColor(healthColor(percent))
  bar:setText(text or (percent .. '%'))
end

local function setMoves(bar, label, ready, total)
  if total <= 0 then
    bar:setPercent(0)
    label:setText('-')
    return
  end
  bar:setPercent(math.floor(ready * 100 / total))
  label:setText(ready .. '/' .. total)
end

local function savePosition(window, key)
  g_settings.set(key, window:getPosition())
end

local function restorePosition(window, key, default)
  local pos = g_settings.getPoint(key)
  if pos and (pos.x ~= 0 or pos.y ~= 0) then
    window:setPosition(pos)
  else
    window:setPosition(default)
  end
  window:bindRectToParent()
end

-- fila del pokemon que esta fuera: la que el servidor marca como usada; si no marca ninguna
-- (p. ej. la lista llego antes de sacarlo), la primera con el nombre del pokemon activo
local function activeIndex()
  for i, poke in ipairs(pokes) do
    if poke.used then return i end
  end
  if active and active.name then
    for i, poke in ipairs(pokes) do
      if poke.name:lower() == active.name:lower() then return i end
    end
  end
  return nil
end

-- ataques listos de un pokemon de la Pokebar: el que esta fuera se mira en la barra de ataques
local function movesReady(poke, isActive)
  if isActive and active and modules.game_pokemonmoves and modules.game_pokemonmoves.getMovesReady then
    local ready, total = modules.game_pokemonmoves.getMovesReady()
    if total > 0 then
      return ready, total
    end
  end
  local now = g_clock.millis()
  local ready = 0
  for i = 1, poke.total do
    if (poke.cdEnd[i] or 0) <= now then
      ready = ready + 1
    end
  end
  return ready, poke.total
end

-- ===================== Pokebar =====================

local compact = false -- modo compacto: solo retratos con una barrita de vida
local locked = false  -- posicion bloqueada (no se arrastra)

local E = '\233' -- e con tilde (cp1252)

local function hpText(poke, isActive, health)
  if isActive and active and active.maxHealth > 0 then
    return math.floor(active.maxHealth * health / 100 + 0.5) .. ' / ' .. active.maxHealth
  end
  if poke.maxHp > 0 then
    return math.min(poke.hp, poke.maxHp) .. ' / ' .. poke.maxHp
  end
  return health .. '%'
end

-- recuadro al pasar el raton: nombre +boost, vida exacta y cooldown de cada ataque
local function tooltipFor(poke, isActive, health)
  local lines = {}
  local title = poke.name
  if poke.boost > 0 then title = title .. '  +' .. poke.boost end
  lines[#lines + 1] = title
  if health <= 0 then
    lines[#lines + 1] = 'Debilitado'
  else
    lines[#lines + 1] = 'Vida: ' .. hpText(poke, isActive, health)
  end
  local moves = {}
  local now = g_clock.millis()
  if isActive and modules.game_pokemonmoves and modules.game_pokemonmoves.getMoveCooldowns then
    for _, move in ipairs(modules.game_pokemonmoves.getMoveCooldowns()) do
      moves[#moves + 1] = { name = move.name, remaining = move.remaining }
    end
  end
  if #moves == 0 then
    for m, name in ipairs(poke.moves) do
      moves[#moves + 1] = { name = name, remaining = math.max(0, (poke.cdEnd[m] or 0) - now) }
    end
  end
  if #moves > 0 then
    lines[#lines + 1] = ''
    for _, move in ipairs(moves) do
      local state = move.remaining > 0 and (math.ceil(move.remaining / 1000) .. 's') or 'listo'
      lines[#lines + 1] = move.name .. ':  ' .. state
    end
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = 'Clic: sacar  -  Clic derecho: opciones'
  return table.concat(lines, '\n')
end

local function updateRows()
  if not pokebarWindow then return end
  local rows = pokebarWindow:getChildById('rows')
  local current = active and activeIndex()
  for i, poke in ipairs(pokes) do
    local row = rows:getChildByIndex(i)
    if row then
      local isActive = i == current
      local health = poke.health
      if isActive and active.health then
        health = active.health
      end
      local fainted = health <= 0
      local bar = row:getChildById('health')
      setHealth(bar, health)
      setHealth(row:getChildById('miniHealth'), health, '')
      if fainted then
        bar:setText('Debilitado')
      end
      local ready, total = movesReady(poke, isActive)
      setMoves(row:getChildById('moves'), row:getChildById('movesText'), ready, total)
      -- debilitado: retrato apagado
      row:getChildById('portrait'):setImageColor(fainted and '#ffffff4a' or '#ffffff')
      row:getChildById('outBadge'):setVisible(isActive)
      row:setOn(isActive)
      row:setTooltip(tooltipFor(poke, isActive, health))
    end
  end
end

local function openRowMenu(i)
  local poke = pokes[i]
  if not poke then return end
  local menu = g_ui.createWidget('PopupMenu')
  menu:addOption('Sacar', function() g_game.talk('!p ' .. i) end)
  if poke.dex > 0 and modules.game_pokedex then
    menu:addOption('Ver en la Pok' .. E .. 'dex', function()
      modules.game_pokedex.show()
      modules.game_pokedex.requestInfo(poke.dex)
    end)
  end
  menu:display()
end

-- muestra lo de cada modo en una fila
local function layoutRow(row)
  row:setWidth(compact and 56 or 228)
  for _, id in ipairs({ 'healthTrack', 'health', 'movesText', 'movesTrack', 'moves' }) do
    row:getChildById(id):setVisible(not compact)
  end
  row:getChildById('miniTrack'):setVisible(compact)
  row:getChildById('miniHealth'):setVisible(compact)
end

function applyLayout()
  pokebarWindow:setWidth(compact and 68 or 240)
  pokebarWindow:getChildById('title'):setVisible(not compact)
  local layoutButton = pokebarWindow:getChildById('layoutButton')
  layoutButton:setImageSource('/images/statusbar/' .. (compact and 'expand' or 'compact'))
  layoutButton:setTooltip(compact and 'Modo normal' or 'Modo compacto')
  local lockButton = pokebarWindow:getChildById('lockButton')
  lockButton:setImageSource('/images/statusbar/' .. (locked and 'lock' or 'unlock'))
  lockButton:setTooltip(locked and 'Desbloquear posici\243n' or 'Bloquear posici\243n')
  for _, row in ipairs(pokebarWindow:getChildById('rows'):getChildren()) do
    layoutRow(row)
  end
end

local function buildRows()
  local rows = pokebarWindow:getChildById('rows')
  rows:destroyChildren()
  for i, poke in ipairs(pokes) do
    local row = g_ui.createWidget('PokeRow', rows)
    row:setId('poke' .. i)
    local icon = iconFor(poke.name)
    if icon then
      row:getChildById('portrait'):setImageSource(icon)
    end
    row:getChildById('slotBadge'):setText(tostring(i))
    row:getChildById('shinyBadge'):setVisible(poke.name:lower():find('^shiny ') ~= nil)
    row.onClick = function()
      g_game.talk('!p ' .. i)
    end
    row.onMouseRelease = function(self, mousePos, mouseButton)
      if mouseButton == MouseRightButton and self:containsPoint(mousePos) then
        openRowMenu(i)
        return true
      end
      return false
    end
    layoutRow(row)
  end
  pokebarWindow:setHeight(32 + #pokes * ROW_HEIGHT)
  updateRows()
end

-- opcode 53: 10 campos por pokemon (ver refreshPokemonBar en el servidor)
local FIELDS = 10

function onPokebar(protocol, opcode, buffer)
  local fields = {}
  for field in string.gmatch(buffer, '([^,]+)') do
    fields[#fields + 1] = field
  end
  local now = g_clock.millis()
  pokes = {}
  local i = 1
  while i <= #fields do
    local poke = {
      name = fields[i],
      health = tonumber(fields[i + 1]) or 100,
      used = fields[i + 2] == '1',
      total = tonumber(fields[i + 3]) or 0,
      cdEnd = {},
      boost = tonumber(fields[i + 5]) or 0,
      hp = tonumber(fields[i + 6]) or 0,
      maxHp = tonumber(fields[i + 7]) or 0,
      dex = tonumber(fields[i + 8]) or 0,
      moves = {},
    }
    local cds = fields[i + 4] or '-'
    if cds ~= '-' then
      local n = 0
      for cd in string.gmatch(cds, '([^;]+)') do
        n = n + 1
        local seconds = tonumber(cd) or 0
        if seconds > 0 then
          poke.cdEnd[n] = now + seconds * 1000
        end
      end
    end
    local names = fields[i + 9] or '-'
    if names ~= '-' then
      for name in string.gmatch(names, '([^;]+)') do
        poke.moves[#poke.moves + 1] = name
      end
    end
    pokes[#pokes + 1] = poke
    i = i + FIELDS
  end
  buildRows()
  pokebarWindow:setVisible(#pokes > 0 and not pokebarHidden)
end

-- boton de la barra de arriba: mostrar u ocultar la Pokebar (se recuerda)
function togglePokebar()
  pokebarHidden = not pokebarHidden
  g_settings.set('pokebar_hidden', pokebarHidden)
  pokebarWindow:setVisible(#pokes > 0 and not pokebarHidden)
  if pokebarWindow:isVisible() then pokebarWindow:raise() end
  if pokebarButton then pokebarButton:setOn(not pokebarHidden) end
end

function togglePokebarCompact()
  compact = not compact
  g_settings.set('pokebar_compact', compact)
  applyLayout()
end

function togglePokebarLock()
  locked = not locked
  g_settings.set('pokebar_locked', locked)
  applyLayout()
end

-- ===================== Pokemon activo =====================

-- La seccion del pokemon activo esta en la ventana "Estado de combate" (game_combatcontrols)
local function activePanel()
  local window = modules.game_combatcontrols and modules.game_combatcontrols.combatControlsWindow
  return window and window:recursiveGetChildById('activePokemon')
end

local function updateActive()
  local panel = activePanel()
  if not panel or not active then return end
  local creature = active.id > 0 and g_map.getCreatureById(active.id)
  if creature then
    active.health = creature:getHealthPercent()
  end
  local health = active.health or 100
  local text = health .. '%'
  if active.maxHealth > 0 then
    text = math.floor(active.maxHealth * health / 100 + 0.5) .. ' / ' .. active.maxHealth
  end
  setHealth(panel:getChildById('health'), health, text)

  local ready, total = 0, 0
  if modules.game_pokemonmoves and modules.game_pokemonmoves.getMovesReady then
    ready, total = modules.game_pokemonmoves.getMovesReady()
  end
  setMoves(panel:getChildById('moves'), panel:getChildById('movesText'), ready, total)
end

-- sin pokemon fuera: la seccion queda apagada con un aviso
-- muestra los datos del pokemon o solo el aviso "Sin Pokemon fuera" (sin recuadros vacios)
-- y ajusta el alto de la ventana a lo que se ve
local ACTIVE_PARTS = { 'portraitBox', 'portrait', 'creature', 'name', 'healthTrack', 'health',
  'movesText', 'movesTrack', 'moves' }
local function showActiveParts(show)
  local panel = activePanel()
  if not panel then return end
  for _, id in ipairs(ACTIVE_PARTS) do
    local widget = panel:getChildById(id)
    if widget then widget:setVisible(show) end
  end
  local empty = panel:getChildById('emptyText')
  if empty then empty:setVisible(not show) end
  local window = modules.game_combatcontrols and modules.game_combatcontrols.combatControlsWindow
  if window and not window:isOn() then -- $on = minimizada
    window:setHeight(show and 132 or 96)
  end
end

local function showNoActive()
  showActiveParts(false)
end

-- lo llama game_pokemonmoves al recibir el opcode 60
function onActiveInfo(name, look, creatureId, maxHealth)
  if not name then return end
  active = { name = name, look = look or 0, id = creatureId or 0, maxHealth = maxHealth or 0, health = 100 }
  local panel = activePanel()
  if panel then
    panel:getChildById('name'):setText(name)
    local portrait = panel:getChildById('portrait')
    local creature = panel:getChildById('creature')
    local icon = iconFor(name)
    if icon then
      portrait:setImageSource(icon)
      portrait:show()
      creature:hide()
    elseif active.look > 0 then
      creature:setOutfit({ type = active.look })
      creature:show()
      portrait:hide()
    end
    showActiveParts(true)
    -- el retrato que no toca sigue oculto
    if icon then creature:hide() else portrait:hide() end
  end
  updateActive()
  updateRows()
end

-- criatura del pokemon que esta fuera (la usan las casillas de objetos para las pociones)
function getActiveCreature()
  if not active or active.id <= 0 then return nil end
  return g_map.getCreatureById(active.id)
end

function onActiveGone(protocol, opcode, buffer)
  active = nil
  showNoActive()
  updateRows()
end

local function onCreatureHealthPercentChange(creature, percent)
  if active and creature:getId() == active.id then
    active.health = percent
    updateActive()
    updateRows()
  end
end

-- Busca en pantalla la invocacion propia (el servidor marca al pokemon del jugador como
-- "summon own"). Asi el panel funciona aunque no haya llegado el opcode 60 (p. ej. si el
-- pokemon ya estaba fuera al abrir el cliente). El cliente no deja pedirselo al servidor
-- fuera de un clic o una tecla (anti-bot).
local function findOwnSummon()
  local player = g_game.getLocalPlayer()
  if not player then return nil end
  local ok, spectators = pcall(g_map.getSpectators, player:getPosition(), false)
  if not ok or not spectators then return nil end
  for _, creature in ipairs(spectators) do
    local okType, creatureType = pcall(function() return creature:getType() end)
    if okType and creatureType == CreatureTypeSummonOwn then
      return creature
    end
  end
  return nil
end

local summonTypeWorks = false -- se ha visto alguna vez una invocacion propia

local function detectActive()
  local summon = findOwnSummon()
  if summon then
    summonTypeWorks = true
    if not active or active.id ~= summon:getId() then
      local outfit = summon:getOutfit()
      -- vida maxima desconocida (0): se muestra en %
      onActiveInfo(summon:getName(), outfit and outfit.type or 0, summon:getId(), 0)
    end
  elseif active and summonTypeWorks then
    -- ya no esta en pantalla (guardado, muerto o lejos)
    onActiveGone()
  end
end

local function tick()
  detectActive()
  updateActive()
  updateRows()
  tickEvent = scheduleEvent(tick, 500)
end


-- ===================== Modulo =====================

local function onGameStart()
  if tickEvent then removeEvent(tickEvent) end
  tickEvent = scheduleEvent(tick, 500)
  if not active then
    showNoActive()
  end
end

local function onGameEnd()
  if tickEvent then
    removeEvent(tickEvent)
    tickEvent = nil
  end
  active = nil
  pokes = {}
  pokebarWindow:hide()
  showNoActive()
end

function init()
  g_ui.importStyle('pokemonbar')
  local root = g_ui.getRootWidget()

  pokebarWindow = g_ui.createWidget('PokebarWindow', root)
  pokebarWindow:getChildById('title'):setText('Pok\233bar')
  restorePosition(pokebarWindow, 'pokebar_pos', { x = 10, y = 110 }) -- arriba a la izquierda, sin tapar el centro del mapa
  pokebarWindow.onDragLeave = function() savePosition(pokebarWindow, 'pokebar_pos') end
  pokebarWindow.onDragEnter = function(self, mousePos)
    if locked then return false end
    return UIWindow.onDragEnter(self, mousePos)
  end
  compact = g_settings.getBoolean('pokebar_compact')
  locked = g_settings.getBoolean('pokebar_locked')
  pokebarWindow:getChildById('layoutButton').onClick = togglePokebarCompact
  pokebarWindow:getChildById('lockButton').onClick = togglePokebarLock
  applyLayout()
  pokebarWindow:hide()
  pokebarHidden = g_settings.getBoolean('pokebar_hidden')
  pokebarButton = modules.client_topmenu.addRightGameToggleButton('pokebarButton', 'Pok\233bar',
    '/images/topmenu/pokebar', togglePokebar)
  pokebarButton:setOn(not pokebarHidden)

  connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
  connect(Creature, { onHealthPercentChange = onCreatureHealthPercentChange })
  -- por si una recarga anterior los dejo registrados
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_POKEBAR)
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_ACTIVE_GONE)
  ProtocolGame.registerExtendedOpcode(OPCODE_POKEBAR, onPokebar)
  ProtocolGame.registerExtendedOpcode(OPCODE_ACTIVE_GONE, onActiveGone)
  if g_game.isOnline() then
    onGameStart()
  end
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_POKEBAR)
  ProtocolGame.unregisterExtendedOpcode(OPCODE_ACTIVE_GONE)
  disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
  disconnect(Creature, { onHealthPercentChange = onCreatureHealthPercentChange })
  if tickEvent then
    removeEvent(tickEvent)
    tickEvent = nil
  end
  pokebarWindow:destroy()
  if pokebarButton then
    pokebarButton:destroy()
    pokebarButton = nil
  end
end
