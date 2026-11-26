-- Pokedex estilo PKA: lista con todos los pokemon (pokeball en los capturados) y ficha con
-- cabecera por tipo, boton shiny, lupa (mapa grande con marcas), y pestanas
-- Info (evoluciones, habilidades, estadisticas, efectividad), Ataques y Botin.
-- Los datos los manda el servidor por el opcode 62 (data/lib/core/pokedex.lua).

local OPCODE_POKEDEX = 62

local window
local dexButton
local rows = {}          -- [numero] = fila de la lista
local listLoaded = false
local current            -- ficha mostrada
local lastNumber         -- ultima ficha pedida (para volver a abrirla)
local currentTab = 'info'
local pending = ''       -- trozos de un mensaje largo
local focusFromCode = false

local TYPES = {
  normal = {'Normal', '#9a9a7a'}, fire = {'Fuego', '#ee7a2a'}, water = {'Agua', '#4f86e8'},
  grass = {'Planta', '#5bb043'}, electric = {'Electrico', '#e0b400'}, ice = {'Hielo', '#5fc8c8'},
  fighting = {'Lucha', '#c03a30'}, poison = {'Veneno', '#a24aa2'}, ground = {'Tierra', '#c8a048'},
  flying = {'Volador', '#8a74e0'}, psychic = {'Psiquico', '#ec4f7c'}, bug = {'Bicho', '#94a820'},
  rock = {'Roca', '#ae9636'}, ghost = {'Fantasma', '#6d5aa0'}, dragon = {'Dragon', '#6440e8'},
  dark = {'Siniestro', '#705848'}, steel = {'Acero', '#9a9ab8'}, fairy = {'Hada', '#e080a0'},
}
local TYPE_ORDER = { 'normal', 'fire', 'water', 'grass', 'electric', 'ice', 'fighting', 'poison', 'ground',
  'flying', 'psychic', 'bug', 'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy' }

-- copia de la tabla del servidor (creaturescripts/scripts/monsterhealthchange.lua):
-- atacante fuerte contra alguno de los tipos -> x1.5, debil -> /1.5 (las dos cosas -> x1)
local STRONG = {
  fire = {'grass', 'ice', 'bug', 'steel'}, grass = {'water', 'ground', 'rock'}, normal = {},
  water = {'fire', 'ground', 'rock'}, flying = {'grass', 'fighting', 'bug'}, poison = {'grass', 'fairy'},
  electric = {'water', 'flying'}, ground = {'fire', 'electric', 'poison', 'rock', 'steel'},
  psychic = {'fighting', 'poison'}, rock = {'fire', 'ice', 'flying', 'bug'}, ice = {'grass', 'ground', 'flying', 'dragon'},
  bug = {'grass', 'psychic', 'dark'}, dragon = {'dragon'}, ghost = {'psychic', 'ghost'}, dark = {'psychic', 'ghost'},
  steel = {'ice', 'rock', 'fairy'}, fairy = {'fighting', 'dragon', 'dark'}, fighting = {'normal', 'ice', 'rock', 'dark', 'steel'},
}
local WEAK = {
  fire = {'water', 'ground', 'rock'}, grass = {'fire', 'ice', 'poison', 'flying', 'bug'}, normal = {'fighting'},
  water = {'electric', 'grass'}, flying = {'electric', 'ice', 'rock'}, poison = {'ground', 'psychic'},
  electric = {'ground'}, ground = {'water', 'grass', 'ice'}, psychic = {'bug', 'ghost', 'dark'},
  rock = {'water', 'grass', 'fighting', 'ground', 'steel'}, ice = {'fire', 'fighting', 'rock', 'steel'},
  bug = {'fire', 'flying', 'rock'}, dragon = {'ice', 'dragon', 'fairy'}, ghost = {'ghost', 'dark'},
  dark = {'fighting', 'bug', 'fairy'}, steel = {'fire', 'fighting', 'ground'}, fairy = {'poison', 'steel'},
  fighting = {'flying', 'psychic', 'fairy'},
}

local CATEGORY_TEXT = {
  singletargetweak = 'Golpe al objetivo (dano bajo)', singletarget = 'Golpe al objetivo',
  singletargetstrong = 'Golpe al objetivo (dano alto)', areatarget = 'Area alrededor del objetivo',
  areawaves = 'Area alrededor del pokemon', frontarea = 'Area delante del pokemon',
  frontlinear = 'Rayo en linea recta', ultimate = 'Ataque definitivo (gran area)', passive = 'Pasiva',
}
local AREA_CATEGORIES = { areatarget = true, areawaves = true, frontarea = true, frontlinear = true, ultimate = true }
local EFFECT_TEXT = { poison = 'envenena', burn = 'quema', slow = 'ralentiza', heal = 'cura', buff = 'mejora al pokemon' }

local function split(s, sep)
  local out = {}
  if not s or s == '' then return out end
  local start = 1
  while true do
    local i = s:find(sep, start, true)
    if not i then
      table.insert(out, s:sub(start))
      return out
    end
    table.insert(out, s:sub(start, i - 1))
    start = i + #sep
  end
end

local function titleCase(s)
  return (s:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
end

local function dexLabel(number)
  if number > 3000 then return string.format('E%03d', number - 3000) end
  if number > 2000 then return string.format('#%03d', number - 2000) end
  return string.format('#%03d', number)
end

local function floorText(z)
  if z == 7 then return 'piso 0' end
  if z < 7 then return 'piso +' .. (7 - z) end
  return 'piso -' .. (z - 7)
end

-- "0, -1, +1": pisos en los que sale, el 0 primero
local function floorSummary(locations)
  local floors, seen = {}, {}
  for _, loc in ipairs(locations) do
    if not seen[loc.z] then
      seen[loc.z] = true
      table.insert(floors, loc.z)
    end
  end
  table.sort(floors, function(a, b)
    local da, db = math.abs(a - 7), math.abs(b - 7)
    if da ~= db then return da < db end
    return a < b
  end)
  local names = {}
  for _, z in ipairs(floors) do
    table.insert(names, (floorText(z):gsub('^piso ', '')))
  end
  return table.concat(names, ', ')
end

local function contains(list, value)
  for _, v in ipairs(list or {}) do
    if v == value then return true end
  end
  return false
end

local function iconFor(name)
  local path = '/game_pokemonbar/bar_icon/' .. name:lower() .. '.png'
  if g_resources.fileExists(path) then return path end
  return nil
end

-- retrato grande generado en casa (comandos-casa.ps1, bloque [11])
local function portraitFor(look)
  if not look or look <= 0 then return nil end
  local path = '/game_pokedex/portraits/' .. look .. '.png'
  if g_resources.fileExists(path) then return path end
  return nil
end

-- ilustracion plana descargada en casa (comandos-casa.ps1, bloque [15])
local function artworkFor(name)
  if not name or name == '' then return nil end
  local path = '/game_pokedex/artwork/' .. name:lower() .. '.png'
  if g_resources.fileExists(path) then return path end
  return nil
end

-- muestra la ilustracion plana si existe; despues el retrato del juego; si no existe ninguno, el outfit
local function setPortrait(image, creature, look, name)
  local portrait = artworkFor(name)
  if not portrait then portrait = portraitFor(look) end
  if portrait then
    image:setImageSource(portrait)
    image:show()
    creature:hide()
  elseif look and look > 0 then
    image:hide()
    creature:setOutfit({ type = look })
    creature:show()
  else
    image:hide()
    creature:hide()
  end
end

-- los opcodes cliente->servidor no llegan: se pide con una talkaction que no sale en el chat.
-- OJO: g_game.talk solo funciona dentro de un click/tecla (no desde timers ni mensajes del servidor)
local function sendRequest(text)
  if g_game.isOnline() then
    g_game.talk('pokedexview ' .. text)
  end
end

local function child(id)
  return window:recursiveGetChildById(id)
end

local function setChip(chip, text, color)
  if not text or text == '' then
    chip:hide()
    return
  end
  chip:setText(text)
  chip:setWidth(chip:getTextSize().width + 18)
  chip:setImageColor(color or '#3a3f47')
  chip:show()
end

local function showError(text)
  g_logger.error('[Pokedex] ' .. text)
  local label = child('emptyLabel')
  label:setText('Error en la pokedex: ' .. text)
  label:setColor('#ff7070')
  label:show()
end

-- ===================== Ventana =====================

function init()
  window = g_ui.displayUI('pokedex')
  window:hide()

  dexButton = modules.client_topmenu.addRightGameToggleButton('pokedexButton', 'Pokedex (E)',
    '/images/topmenu/pokedex', toggle)
  dexButton:setOn(false)

  child('searchEdit').onTextChange = function(widget, text) filterList(text) end

  local list = child('dexList')
  list.onChildFocusChange = function(widget, focused)
    if focused and focused.number and not focusFromCode then
      requestInfo(focused.number)
    end
  end
  g_keyboard.bindKeyPress('Down', function() list:focusNextChild(KeyboardFocusReason) end, window)
  g_keyboard.bindKeyPress('Up', function() list:focusPreviousChild(KeyboardFocusReason) end, window)

  -- sin Ctrl+D (choca con andar en WASD): g_keyboard.bindKeyDown('Ctrl+D', toggle)
  ProtocolGame.registerExtendedOpcode(OPCODE_POKEDEX, onPokedexOpcode)
  connect(g_game, { onGameEnd = onGameEnd })
  clearInfo()
end

function terminate()
  -- sin Ctrl+D (choca con andar en WASD): g_keyboard.unbindKeyDown('Ctrl+D')
  ProtocolGame.unregisterExtendedOpcode(OPCODE_POKEDEX)
  disconnect(g_game, { onGameEnd = onGameEnd })
  window:destroy()
  dexButton:destroy()
end

function onGameEnd()
  hide()
  child('dexList'):destroyChildren()
  rows = {}
  listLoaded = false
  pending = ''
  lastNumber = nil
  clearInfo()
end

local function openWindow()
  if not window:isVisible() then
    window:show()
    window:raise()
    window:focus()
    dexButton:setOn(true)
  end
end

function show()
  if not g_game.isOnline() then return end
  openWindow()
  sendRequest('list')
end

function hide()
  window:hide()
  dexButton:setOn(false)
end

function toggle()
  if window:isVisible() then hide() else show() end
end

function requestInfo(number)
  if not number then return end
  lastNumber = number
  sendRequest(tostring(number))
end

function onPokedexOpcode(protocol, opcode, buffer)
  local mark = buffer:sub(1, 1)
  if mark == '+' then
    pending = pending .. buffer:sub(2)
    return
  elseif mark == '=' then
    buffer = pending .. buffer:sub(2)
    pending = ''
  else
    pending = ''
  end

  local kind = buffer:sub(1, 1)
  local ok, err = true, nil
  if kind == 'L' then
    openWindow()
    ok, err = pcall(loadList, buffer)
  elseif kind == 'I' then
    openWindow()
    ok, err = pcall(loadInfo, buffer)
  elseif kind == 'E' then
    openWindow()
    showError(buffer:sub(3))
  end
  if not ok then
    showError(tostring(err))
  end
end

-- ===================== Lista =====================

local function updateRow(row, name, flags)
  row.name = name
  row.caught = math.floor(flags / 2) % 2 == 1
  row.registered = flags % 2 == 1
  local shinyCaught = math.floor(flags / 4) % 2 == 1
  row:getChildById('number'):setText(dexLabel(row.number))
  row:getChildById('name'):setText(name)
  row:getChildById('name'):setColor(row.caught and '#ffffff' or (row.registered and '#c9d4e3' or '#7d8ba0'))
  row:getChildById('ball'):setVisible(row.caught)
  row:getChildById('dot'):setImageColor(shinyCaught and '#ffcc40' or (row.registered and '#7ee07e' or '#4a3c3e'))
  local tip = row.caught and 'Capturado' or (row.registered and 'Registrado en la pokedex' or 'Sin registrar')
  if shinyCaught then tip = tip .. ' (y su version shiny)' end
  row:setTooltip(tip)
end

function loadList(buffer)
  local parts = split(buffer, '|')
  local caught, total = tonumber(parts[2]) or 0, tonumber(parts[3]) or 0
  child('caughtLabel'):setText(caught .. ' / ' .. total .. ' capturados')
  local back = child('progressBack')
  child('progressFill'):setWidth(total > 0 and math.floor(back:getWidth() * caught / total) or 0)

  local list = child('dexList')
  local layout = list:getLayout()
  layout:disableUpdates()
  for _, entry in ipairs(split(parts[4], ';')) do
    local fields = split(entry, ':')
    local number = tonumber(fields[1])
    if number then
      local row = rows[number]
      if not row then
        row = g_ui.createWidget('DexListRow', list)
        row.number = number
        rows[number] = row
      end
      updateRow(row, fields[2] or '?', tonumber(fields[3]) or 0)
    end
  end
  layout:enableUpdates()
  layout:update()
  listLoaded = true
  filterList(child('searchEdit'):getText())
  if current then
    focusRow(current.number)
  end
end

function focusRow(number)
  if number > 2000 and number <= 3000 then number = number - 2000 end
  local row = rows[number]
  if not row then return end
  local list = child('dexList')
  if list:getFocusedChild() ~= row then
    focusFromCode = true
    list:focusChild(row, ActiveFocusReason)
    focusFromCode = false
  end
  list:ensureChildVisible(row)
end

function filterList(text)
  text = (text or ''):lower()
  child('searchHint'):setVisible(text == '')
  local number = tonumber(text)
  for n, row in pairs(rows) do
    local visible = text == '' or row.name:lower():find(text, 1, true) ~= nil
      or (number ~= nil and (n == number or n - 3000 == number))
    row:setVisible(visible)
  end
end

-- ===================== Ficha =====================

local PANELS = { info = 'infoPanel', moves = 'movesPanel', loot = 'lootPanel' }
local SCROLLS = { info = 'infoScrollBar', moves = 'movesScrollBar', loot = 'lootScrollBar' }
local TABS = { info = 'tabInfo', moves = 'tabMoves', loot = 'tabLoot' }

function clearInfo()
  current = nil
  child('headerCard'):hide()
  for tab, panel in pairs(PANELS) do
    child(TABS[tab]):hide()
    child(panel):hide()
    child(SCROLLS[tab]):hide()
  end
  local label = child('emptyLabel')
  label:setText('Elige un pokemon de la lista o usa la pokedex (tecla E) sobre un pokemon.')
  label:setColor('#6c7a8d')
  label:show()
end

local function parseInfo(buffer)
  local p = split(buffer, '|')
  local info = {
    number = tonumber(p[2]) or 0, name = p[3] or '', look = tonumber(p[4]) or 0,
    race = (p[5] or ''):lower(), race2 = (p[6] or ''):lower(), stats = split(p[7], ','),
    moves = {}, chain = {}, abilities = split(p[10], ','), loot = {}, locations = {},
  }
  for _, m in ipairs(split(p[8], ';')) do
    local f = split(m, ':')
    table.insert(info.moves, { name = f[1] or '?', cooldown = tonumber(f[2]) or 0, element = (f[3] or ''):lower(),
      category = f[4] or '', effect = f[5] or '', target = f[6] == '1' })
  end
  for _, e in ipairs(split(p[9], ';')) do
    local f = split(e, ':')
    table.insert(info.chain, { name = f[1] or '?', look = tonumber(f[2]) or 0, level = tonumber(f[3]) or 0,
      item = f[4] or '', count = tonumber(f[5]) or 0, number = tonumber(f[6]) or 0, depth = tonumber(f[7]) or 0,
      itemId = tonumber(f[8]) or 0 })
  end
  for _, l in ipairs(split(p[11], ';')) do
    local f = split(l, ':')
    table.insert(info.loot, { clientId = tonumber(f[1]) or 0, name = f[2] or '', count = f[3] or '1',
      chanceText = f[4] or '?', chance = tonumber(f[5]) or tonumber(f[4]) or 0 })
  end
  for _, l in ipairs(split(p[12], ';')) do
    local f = split(l, ':')
    table.insert(info.locations, { x = tonumber(f[1]) or 0, y = tonumber(f[2]) or 0, z = tonumber(f[3]) or 7,
      count = tonumber(f[4]) or 0, town = f[5] or '' })
  end
  local catches = split(p[13], ':')
  info.tries, info.catches = tonumber(catches[1]) or 0, tonumber(catches[2]) or 0
  local extra = split(p[14], ':')
  info.legendary = extra[1] == '1'
  info.fromBase = extra[2] == '1'
  info.shinyNumber = tonumber(extra[3]) or 0
  info.worldCount = tonumber(extra[4]) or 0
  info.registered = extra[5] == '1'
  info.baseNumber = tonumber(extra[6]) or 0
  info.owners = tonumber(extra[7]) or 0
  info.tier = extra[8] or ''
  info.isShiny = info.number > 2000 and info.number <= 3000
  return info
end

function loadInfo(buffer)
  local info = parseInfo(buffer)
  current = info
  lastNumber = info.number

  child('emptyLabel'):hide()
  child('headerCard'):show()
  -- cada seccion por separado: si una falla, las demas se siguen viendo
  local errors = {}
  for _, builder in ipairs({ buildHeader, buildInfoPanel, buildMovesPanel, buildLootPanel }) do
    local ok, err = pcall(builder, info)
    if not ok then table.insert(errors, tostring(err)) end
  end
  child('tabMoves'):setText('Ataques (' .. #info.moves .. ')')
  child('tabLoot'):setText('Botin (' .. #info.loot .. ')')
  for _, tab in pairs(TABS) do child(tab):show() end
  if not PANELS[currentTab] then currentTab = 'info' end
  showTab(currentTab)
  focusRow(info.number)
  for _, err in ipairs(errors) do
    g_logger.error('[Pokedex] ' .. err)
  end
end

TIER_NAMES = {
  t7 = 'Newbie (G)', t6 = 'Basic (F)', t5 = 'Rookie (E)', t4 = 'Junior (D)', t3 = 'Regular (C)',
  t2 = 'Pro (B)', t1 = 'Ace (A)', ['super rare'] = 'Veteran (S)', ['ultra rare'] = 'Elite (S+)',
  legendary = 'Master (SS)', mythic = 'Champion (SSS)',
}
TIER_COLORS = {
  mythic = '#c0392b', legendary = '#b8860b', ['ultra rare'] = '#2f6fd6', ['super rare'] = '#8e44ad',
  t1 = '#8a96a3', t2 = '#2e9e57',
}

function buildHeader(info)
  local typeInfo = TYPES[info.race] or { titleCase(info.race), '#3d8fe0' }
  local color = typeInfo[2]
  child('gradient'):setImageColor(color)

  setPortrait(child('headerImage'), child('headerCreature'), info.look, info.name)
  child('nameLabel'):setText(info.name)
  child('bigNumber'):setText(dexLabel(info.number))
  setChip(child('type1'), typeInfo[1], color)
  local type2 = TYPES[info.race2]
  setChip(child('type2'), type2 and type2[1] or (info.race2 ~= '' and titleCase(info.race2) or nil), type2 and type2[2])

  local req = tonumber(info.stats[7]) or 0
  local levelText = req > 0 and ('NIVEL ' .. req) or 'TODO NIVEL'
  setChip(child('levelChip'), levelText, '#3a3f47')
  child('levelChip'):setTooltip('Nivel de entrenador necesario para usarlo')
  -- tier (rareza) del Pokemon: los mismos colores que los orbes de evolucion shiny
  local tierColor = TIER_COLORS[info.tier:lower()] or '#8c5a2b'
  -- nombres propios: por dentro (servidor y tabla de tiers) siguen siendo T1-T7, Super Rare, etc.
  local tierName = TIER_NAMES[info.tier:lower()] or info.tier
  setChip(child('tierChip'), info.tier ~= '' and ('Tier ' .. tierName) or nil, tierColor)
  child('tierChip'):setTooltip('Tier: lo bueno y raro que es. De menor a mayor: Newbie (G), Basic (F), Rookie (E), ' ..
    'Junior (D),\nRegular (C), Pro (B), Ace (A), Veteran (S), Elite (S+), Master (SS), Champion (SSS)')
  if info.legendary then
    setChip(child('specialChip'), 'LEGENDARIO', '#b8860b')
  elseif info.isShiny then
    setChip(child('specialChip'), 'SHINY', '#c9a000')
  else
    setChip(child('specialChip'), nil)
  end

  local world
  if info.owners == 1 then
    world = 'Capturado por 1 entrenador'
  else
    world = 'Capturado por ' .. info.owners .. ' entrenadores'
  end
  if info.isShiny then
    if not info.fromBase then
      world = world .. '   |   No aparece salvaje'
    end
  elseif info.worldCount <= 0 then
    world = world .. '   |   No aparece salvaje'
  end
  if not info.isShiny and #info.locations > 0 then
    world = world .. '   |   Pisos: ' .. floorSummary(info.locations)
  end
  child('worldLabel'):setText(world)

  local catchChance = tonumber(info.stats[10]) or 0
  local catchText = (info.registered and 'Registrado' or 'Sin registrar') .. '   |   Capturados: ' .. info.catches .. '   |   Intentos: ' .. info.tries
  if catchChance <= 0 then
    catchText = catchText .. '   |   No se puede capturar'
  end
  child('catchLabel'):setText(catchText)

  local shinyButton = child('shinyButton')
  shinyButton:setOn(info.isShiny)
  if info.isShiny then
    shinyButton:setEnabled(true)
    shinyButton:setOpacity(1)
    shinyButton:setTooltip('Ver la version normal')
  elseif info.shinyNumber > 0 then
    shinyButton:setEnabled(true)
    shinyButton:setOpacity(1)
    shinyButton:setTooltip('Ver la version shiny')
  else
    shinyButton:setEnabled(false)
    shinyButton:setOpacity(0.35)
    shinyButton:setTooltip('No tiene version shiny')
  end
  child('mapButton'):setOpacity(#info.locations > 0 and 1 or 0.35)
end

function toggleShiny()
  if not current then return end
  if current.isShiny then
    requestInfo(current.baseNumber > 0 and current.baseNumber or current.number - 2000)
  elseif current.shinyNumber > 0 then
    requestInfo(current.shinyNumber)
  end
end

function showTab(tab)
  if not current then return end
  currentTab = tab
  for name, id in pairs(TABS) do
    child(id):setOn(name == tab)
  end
  for name, panel in pairs(PANELS) do
    child(panel):setVisible(name == tab)
    child(SCROLLS[name]):setVisible(name == tab)
  end
end

local function addSection(panel, text)
  local label = g_ui.createWidget('DexSection', panel)
  label:setText(text)
end

local function addText(panel, text, color)
  local label = g_ui.createWidget('DexText', panel)
  label:setText(text)
  if color then label:setColor(color) end
  return label
end

local function gridHeight(count, perRow, cell, spacing)
  local lines = math.max(1, math.ceil(count / perRow))
  return lines * cell + (lines - 1) * spacing
end

local function addChips(panel, chips)
  local flow = g_ui.createWidget('DexFlow', panel)
  for _, c in ipairs(chips) do
    local chip = g_ui.createWidget('DexChip', flow)
    chip:setText(c[1])
    chip:setImageColor(c[2] or '#3a3f47')
  end
  flow:setHeight(gridHeight(#chips, 6, 20, 6))
  return flow
end

-- multiplicador del dano que recibe este pokemon de un ataque del tipo attacker
local function damageTaken(attacker, race, race2)
  local strong = contains(STRONG[attacker], race) or (race2 ~= '' and contains(STRONG[attacker], race2))
  local weak = contains(WEAK[attacker], race) or (race2 ~= '' and contains(WEAK[attacker], race2))
  if strong and not weak then return 1.5 end
  if weak and not strong then return 0.67 end
  return 1
end

-- alto de una caja (DexBox): relleno (10 arriba y abajo) + titulo + contenido, con 6 px entre hijos
local BOX_SPACING = 6
local BOX_PADDING = 20
local function fitBox(box)
  local height = BOX_PADDING
  for i, widget in ipairs(box:getChildren()) do
    height = height + widget:getHeight() + (i > 1 and BOX_SPACING or 0)
  end
  box:setHeight(height)
  return height
end

local function newBox(panel, title)
  local box = g_ui.createWidget('DexBox', panel)
  box:getChildById('title'):setText(title)
  return box
end

local function addNote(parent, text)
  local label = g_ui.createWidget('DexNote', parent)
  label:setText(text)
  return label
end

function buildInfoPanel(info)
  local panel = child('infoPanel')
  panel:destroyChildren()

  -- evoluciones (izquierda) y objetos para evolucionar (derecha)
  local row = g_ui.createWidget('DexEvoRow', panel)
  local evoBox = row:getChildById('evoBox')
  local itemBox = row:getChildById('itemBox')
  evoBox:getChildById('title'):setText('EVOLUCIONES')
  itemBox:getChildById('title'):setText('OBJETO DE EVOLUCION')

  local items = {}
  if #info.chain <= 1 then
    addNote(evoBox, 'Este pokemon no tiene evoluciones.')
  else
    local grid = g_ui.createWidget('DexEvoGrid', evoBox)
    for i, stage in ipairs(info.chain) do
      local cell = g_ui.createWidget('DexEvoCell', grid)
      cell:getChildById('arrow'):setVisible(i > 1)
      local card = cell:getChildById('card')
      card:setOn(stage.name:lower() == info.name:lower())
      setPortrait(card:getChildById('image'), card:getChildById('creature'), stage.look, stage.name)
      card:getChildById('name'):setText(stage.name)
      local levelText = 'Base'
      if stage.depth > 0 then
        levelText = stage.level > 0 and ('Nv ' .. stage.level) or ''
        if stage.item ~= '' then
          levelText = levelText ~= '' and (levelText .. ' o objeto') or titleCase(stage.item)
          table.insert(items, { stage = stage.name, item = titleCase(stage.item), count = math.max(1, stage.count),
            itemId = stage.itemId })
          if stage.itemId > 0 then
            local icon = card:getChildById('itemIcon')
            icon:setItemId(stage.itemId)
            icon:show()
          end
        end
      end
      card:getChildById('level'):setText(levelText)
      local tip = { stage.name }
      if stage.depth > 0 and stage.level > 0 then table.insert(tip, 'Evoluciona al nivel ' .. stage.level) end
      if stage.item ~= '' then table.insert(tip, 'Usando ' .. math.max(1, stage.count) .. 'x ' .. titleCase(stage.item)) end
      card:setTooltip(table.concat(tip, '\n'))
      if stage.number > 0 then
        card.onClick = function() requestInfo(stage.number) end
      end
    end
    grid:setHeight(gridHeight(#info.chain, 3, 116, 4))
  end

  if #items == 0 then
    addNote(itemBox, #info.chain <= 1 and '-' or 'No necesita objetos.')
  else
    for _, it in ipairs(items) do
      local itemRow = g_ui.createWidget('DexEvoItemRow', itemBox)
      if it.itemId > 0 then itemRow:getChildById('item'):setItemId(it.itemId) end
      itemRow:getChildById('name'):setText(it.item)
      itemRow:getChildById('count'):setText('x' .. it.count)
      itemRow:getChildById('stage'):setText('Para ' .. it.stage)
      itemRow:setTooltip(it.count .. 'x ' .. it.item .. '\nEvoluciona a ' .. it.stage)
    end
  end
  local rowHeight = math.max(fitBox(evoBox), fitBox(itemBox))
  evoBox:setHeight(rowHeight)
  itemBox:setHeight(rowHeight)
  row:setHeight(rowHeight)

  -- habilidades de campo
  local abilityBox = newBox(panel, 'HABILIDADES DE CAMPO')
  if #info.abilities == 0 then
    addNote(abilityBox, 'Ninguna.')
  else
    local chips = {}
    for _, a in ipairs(info.abilities) do table.insert(chips, { a, '#2f5d8a' }) end
    addChips(abilityBox, chips)
  end
  fitBox(abilityBox)

  -- efectividad
  local effBox = newBox(panel, 'EFECTIVIDAD - DANO RECIBIDO')
  local groups = { [1.5] = {}, [1] = {}, [0.67] = {} }
  for _, t in ipairs(TYPE_ORDER) do
    table.insert(groups[damageTaken(t, info.race, info.race2)], t)
  end
  local labels = {
    { 1.5, 'EFICAZ  1.5x', '#ff6b5b' }, { 1, 'NEUTRO  1x', '#c9d4e3' }, { 0.67, 'POCO EFICAZ  0.67x', '#7ee07e' },
  }
  for _, g in ipairs(labels) do
    local list = groups[g[1]]
    if #list > 0 then
      local effRow = g_ui.createWidget('DexEffRow', effBox)
      local label = effRow:getChildById('label')
      label:setText(g[2])
      label:setColor(g[3])
      local chipsWidget = effRow:getChildById('chips')
      for _, t in ipairs(list) do
        local chip = g_ui.createWidget('DexChip', chipsWidget)
        chip:setText(TYPES[t][1])
        chip:setImageColor(TYPES[t][2])
      end
      local height = gridHeight(#list, 6, 20, 6)
      chipsWidget:setHeight(height)
      effRow:setHeight(height + 22)
    end
  end
  fitBox(effBox)
end

function buildMovesPanel(info)
  local panel = child('movesPanel')
  panel:destroyChildren()
  addSection(panel, 'MOVESET')
  if #info.moves == 0 then
    addText(panel, 'Este pokemon no tiene ataques.', '#a8a8a8')
    return
  end
  for i, move in ipairs(info.moves) do
    local row = g_ui.createWidget('DexMoveRow', panel)
    local path = '/game_pokemonmoves/moves_icon/' .. move.name:lower() .. '_on.png'
    if g_resources.fileExists(path) then
      row:getChildById('slot'):getChildById('icon'):setImageSource(path)
    end
    row:getChildById('cooldown'):setText(' ' .. move.cooldown .. 's ')
    row:getChildById('name'):setText('m' .. i .. '  ' .. titleCase(move.name))

    local area = AREA_CATEGORIES[move.category] and not move.target
    if move.category == 'passive' then
      setChip(row:getChildById('kind'), 'PASIVA', '#5a6b85')
    elseif area then
      setChip(row:getChildById('kind'), 'AREA', '#d97a1f')
    else
      setChip(row:getChildById('kind'), 'OBJETIVO', '#2f6fd6')
    end

    local element = TYPES[move.element]
    setChip(row:getChildById('element'), element and element[1] or (move.element ~= '' and titleCase(move.element) or nil),
      element and element[2] or '#5a6b85')

    local desc = CATEGORY_TEXT[move.category] or (move.target and 'Necesita un objetivo' or 'Ataque')
    if EFFECT_TEXT[move.effect] then desc = desc .. ', ' .. EFFECT_TEXT[move.effect] end
    desc = desc .. '. Espera ' .. move.cooldown .. ' s.'
    row:getChildById('description'):setText(desc)
    row:setTooltip(titleCase(move.name) .. '\n' .. desc)
  end
end

local function rarity(chance)
  if chance >= 50 then return 'Comun', '#7ee07e' end
  if chance >= 15 then return 'Normal', '#b5e07e' end
  if chance >= 5 then return 'Poco comun', '#ffd84a' end
  if chance >= 1 then return 'Raro', '#ff9a40' end
  return 'Muy raro', '#ff5b5b'
end

function buildLootPanel(info)
  local panel = child('lootPanel')
  panel:destroyChildren()
  addSection(panel, 'BOTIN')
  if #info.loot == 0 then
    addText(panel, 'Este pokemon no suelta objetos.', '#a8a8a8')
    return
  end
  addText(panel, 'Probabilidad de que salga cada objeto al derrotarlo (con el rate del servidor).', '#a8a8a8')
  local grid = g_ui.createWidget('DexLootGrid', panel)
  for _, loot in ipairs(info.loot) do
    local card = g_ui.createWidget('DexLootCard', grid)
    if loot.clientId > 0 then
      card:getChildById('item'):setItemId(loot.clientId)
    end
    card:getChildById('name'):setText(titleCase(loot.name))
    card:getChildById('count'):setText('Cantidad: ' .. loot.count)
    local text, color = rarity(loot.chance)
    local chance = card:getChildById('chance')
    chance:setText(loot.chanceText .. '%')
    chance:setColor(color)
    local rarityLabel = card:getChildById('rarity')
    rarityLabel:setText(text)
    rarityLabel:setColor(color)
    local bar = card:getChildById('barBack'):getChildById('bar')
    -- barra en escala logaritmica para que se vean tambien las probabilidades pequenas
    local fraction = loot.chance >= 100 and 1 or math.max(0, math.log10(math.max(loot.chance, 0.001)) + 3) / 5
    bar:setWidth(math.max(2, math.floor(230 * math.min(1, fraction))))
    bar:setBackgroundColor(color)
    card:setTooltip(titleCase(loot.name) .. ': ' .. loot.chanceText .. '% (' .. text .. ')')
  end
  grid:setHeight(gridHeight(#info.loot, 2, 58, 8))
end

local function locationPositions(info)
  local all = {}
  for _, loc in ipairs(info.locations) do
    table.insert(all, { x = loc.x, y = loc.y, z = loc.z,
      text = info.name .. ': ' .. loc.count .. (loc.town ~= '' and (' cerca de ' .. loc.town) or '') .. ' (' .. floorText(loc.z) .. ')' })
  end
  return all
end

function showOnMap(positions)
  local minimap = modules.game_minimap
  if not minimap or not minimap.showPositions or not current or #positions == 0 then return end
  hide()
  minimap.showPositions(positions, current.name, iconFor(current.name) or portraitFor(current.look), true)
end

function showAllOnMap()
  if not current then return end
  if current.isShiny then
    if modules.game_textmessage and modules.game_textmessage.displayFailureMessage then
      modules.game_textmessage.displayFailureMessage('No se puede ver la localizacion de los shiny: aparecen al azar donde sale su forma normal.')
    end
    return
  end
  if #current.locations == 0 then
    if modules.game_textmessage and modules.game_textmessage.displayFailureMessage then
      modules.game_textmessage.displayFailureMessage(current.name .. ' no aparece en estado salvaje.')
    end
    return
  end
  showOnMap(locationPositions(current))
end

