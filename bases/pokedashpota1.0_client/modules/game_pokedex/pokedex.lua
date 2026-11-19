-- Pokedex estilo PKA: lista de pokemon, ficha con estadisticas, ataques, evoluciones,
-- botin (con probabilidad) y localizacion (zonas del mapa, se pueden ver en el mapa grande).
-- Los datos los manda el servidor por el opcode 62 (data/lib/core/pokedex.lua).

local OPCODE_POKEDEX = 62

local window
local dexButton
local rows = {}          -- [numero] = widget de la lista
local listLoaded = false
local current            -- ficha mostrada
local currentTab = 'info'
local requestEvent

local TYPES = {
  electric = {'Electrico', '#c9a400'}, fire = {'Fuego', '#e0661e'}, water = {'Agua', '#4a74e0'},
  grass = {'Planta', '#4fa83a'}, normal = {'Normal', '#8f8f70'}, psychic = {'Psiquico', '#e0406e'},
  poison = {'Veneno', '#9a3f9a'}, bug = {'Bicho', '#8a9a10'}, ground = {'Tierra', '#b8963a'},
  rock = {'Roca', '#9a8428'}, flying = {'Volador', '#7d68d0'}, fighting = {'Lucha', '#b83028'},
  ghost = {'Fantasma', '#655494'}, ice = {'Hielo', '#5cb8b8'}, dragon = {'Dragon', '#5a38d8'},
  dark = {'Siniestro', '#6b5444'}, steel = {'Acero', '#8a8aa8'}, fairy = {'Hada', '#d0708a'},
}

local CATEGORY_TEXT = {
  singletargetweak = 'Objetivo (dano bajo)', singletarget = 'Objetivo', singletargetstrong = 'Objetivo (dano alto)',
  areatarget = 'Area en el objetivo', areawaves = 'Area alrededor', frontarea = 'Area delante',
  frontlinear = 'Rayo en linea', ultimate = 'Definitivo', passive = 'Pasiva',
}

local EFFECT_TEXT = { poison = 'Envenena', burn = 'Quema', slow = 'Ralentiza', heal = 'Cura', buff = 'Mejora' }

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
  if number > 2000 then return string.format('S%03d', number - 2000) end
  return string.format('#%03d', number)
end

local function floorText(z)
  if z == 7 then return 'superficie' end
  if z < 7 then return 'piso +' .. (7 - z) end
  return 'subterraneo -' .. (z - 7)
end

local function sendRequest(text)
  local protocol = g_game.getProtocolGame()
  if protocol then
    protocol:sendExtendedOpcode(OPCODE_POKEDEX, text)
  end
end

-- ===================== Ventana =====================

function init()
  window = g_ui.displayUI('pokedex')
  window:hide()

  dexButton = modules.client_topmenu.addRightGameToggleButton('pokedexButton', 'Pokedex (Ctrl+D)',
    '/images/topbuttons/spelllist', toggle)
  dexButton:setOn(false)

  local searchEdit = window:getChildById('searchEdit')
  searchEdit.onTextChange = function(widget, text) filterList(text) end

  window:getChildById('dexList').onChildFocusChange = function(list, focused)
    if focused and focused.number and focused.registered then
      requestInfo(focused.number)
    end
  end

  g_keyboard.bindKeyDown('Ctrl+D', toggle)
  ProtocolGame.registerExtendedOpcode(OPCODE_POKEDEX, onPokedexOpcode)
  connect(g_game, { onGameEnd = onGameEnd })
  clearInfo()
end

function terminate()
  g_keyboard.unbindKeyDown('Ctrl+D')
  ProtocolGame.unregisterExtendedOpcode(OPCODE_POKEDEX)
  disconnect(g_game, { onGameEnd = onGameEnd })
  if requestEvent then removeEvent(requestEvent) end
  window:destroy()
  dexButton:destroy()
end

function onGameEnd()
  hide()
  window:getChildById('dexList'):destroyChildren()
  rows = {}
  listLoaded = false
  clearInfo()
end

function show()
  if not g_game.isOnline() then return end
  window:show()
  window:raise()
  window:focus()
  dexButton:setOn(true)
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
  if requestEvent then removeEvent(requestEvent) end
  requestEvent = scheduleEvent(function()
    requestEvent = nil
    sendRequest('info:' .. number)
  end, 120)
end

function onPokedexOpcode(protocol, opcode, buffer)
  local kind = buffer:sub(1, 1)
  if kind == 'L' then
    loadList(buffer)
    if not window:isVisible() then
      window:show()
      window:raise()
      dexButton:setOn(true)
    end
  elseif kind == 'I' then
    loadInfo(buffer)
    if not window:isVisible() then
      window:show()
      window:raise()
      dexButton:setOn(true)
      if not listLoaded then sendRequest('list') end
    end
  end
end

-- ===================== Lista =====================

function loadList(buffer)
  local parts = split(buffer, '|')
  local seen, total = tonumber(parts[2]) or 0, tonumber(parts[3]) or 0
  window:getChildById('seenLabel'):setText('Registrados: ' .. seen .. ' / ' .. total)

  local list = window:getChildById('dexList')
  local focusedNumber = list:getFocusedChild() and list:getFocusedChild().number
  list:destroyChildren()
  rows = {}
  for _, entry in ipairs(split(parts[4], ';')) do
    local fields = split(entry, ':')
    local number = tonumber(fields[1])
    if number then
      local name = fields[2]
      local row = g_ui.createWidget('PokedexRow', list)
      row.number = number
      row.registered = name ~= nil and name ~= ''
      row.name = row.registered and name or ''
      row:setText(dexLabel(number) .. '  ' .. (row.registered and name or '???'))
      row:setOn(not row.registered)
      if not row.registered then
        row:setTooltip('Todavia no lo has registrado. Usa la pokedex sobre uno salvaje.')
      end
      rows[number] = row
    end
  end
  listLoaded = true
  filterList(window:getChildById('searchEdit'):getText())
  local target = current and rows[current.number] or (focusedNumber and rows[focusedNumber])
  if target then
    list:focusChild(target, ActiveFocusReason)
    list:ensureChildVisible(target)
  end
end

function filterList(text)
  text = (text or ''):lower()
  window:getChildById('searchHint'):setVisible(text == '')
  local number = tonumber(text)
  for n, row in pairs(rows) do
    local visible = text == '' or (row.registered and row.name:lower():find(text, 1, true) ~= nil)
      or (number ~= nil and (n == number or n - 2000 == number))
    row:setVisible(visible)
  end
end

-- ===================== Ficha =====================

function clearInfo()
  current = nil
  window:getChildById('creature'):hide()
  window:getChildById('nameLabel'):setText('')
  window:getChildById('numberLabel'):setText('')
  window:getChildById('type1'):hide()
  window:getChildById('type2'):hide()
  window:getChildById('catchLabel'):setText('')
  window:getChildById('emptyLabel'):show()
  for _, id in ipairs({'tabInfo', 'tabLoot', 'tabLocation', 'infoPanel', 'infoScrollBar', 'lootPanel',
                       'lootScrollBar', 'locationPanel', 'locationScrollBar'}) do
    window:getChildById(id):hide()
  end
end

local function setTypeBadge(badge, race)
  local info = TYPES[(race or ''):lower()]
  if not info then
    badge:hide()
    return
  end
  badge:setText(info[1])
  badge:setBackgroundColor(info[2])
  badge:show()
end

function loadInfo(buffer)
  local p = split(buffer, '|')
  local info = {
    number = tonumber(p[2]) or 0, name = p[3] or '', look = tonumber(p[4]) or 0,
    race = p[5], race2 = p[6], stats = split(p[7], ','), moves = {}, evolutions = {},
    abilities = split(p[10], ','), loot = {}, locations = {},
  }
  for _, m in ipairs(split(p[8], ';')) do
    local f = split(m, ':')
    table.insert(info.moves, { name = f[1], cooldown = tonumber(f[2]) or 0, element = f[3], category = f[4], effect = f[5], target = f[6] == '1' })
  end
  for _, e in ipairs(split(p[9], ';')) do
    local f = split(e, ':')
    table.insert(info.evolutions, { name = f[1], level = tonumber(f[2]) or 0, chance = tonumber(f[3]) or 0, item = f[4], count = tonumber(f[5]) or 0 })
  end
  for _, l in ipairs(split(p[11], ';')) do
    local f = split(l, ':')
    table.insert(info.loot, { clientId = tonumber(f[1]) or 0, name = f[2] or '', count = f[3] or '1', chance = f[4] or '?' })
  end
  for _, l in ipairs(split(p[12], ';')) do
    local f = split(l, ':')
    table.insert(info.locations, { x = tonumber(f[1]) or 0, y = tonumber(f[2]) or 0, z = tonumber(f[3]) or 7, count = tonumber(f[4]) or 0, town = f[5] or '' })
  end
  local catches = split(p[13], ':')
  info.tries, info.catches = tonumber(catches[1]) or 0, tonumber(catches[2]) or 0
  local extra = split(p[14], ':')
  info.legendary, info.fromBase = extra[1] == '1', extra[2] == '1'
  current = info

  window:getChildById('emptyLabel'):hide()
  local creature = window:getChildById('creature')
  if info.look > 0 then
    creature:setOutfit({ type = info.look })
    creature:show()
  else
    creature:hide()
  end
  window:getChildById('nameLabel'):setText(info.name)
  window:getChildById('numberLabel'):setText(dexLabel(info.number) .. (info.legendary and '   LEGENDARIO' or ''))
  setTypeBadge(window:getChildById('type1'), info.race)
  setTypeBadge(window:getChildById('type2'), info.race2)
  local catchChance = tonumber(info.stats[10]) or 0
  local catchText = 'Capturados: ' .. info.catches .. '   Intentos: ' .. info.tries
  if catchChance > 0 then
    catchText = catchText .. '   Captura con pokeball: ' .. string.format('%.1f', math.min(100, catchChance * 100 / 300)) .. '%'
  else
    catchText = catchText .. '   No se puede capturar'
  end
  window:getChildById('catchLabel'):setText(catchText)

  window:getChildById('tabInfo'):show()
  window:getChildById('tabLoot'):show()
  window:getChildById('tabLocation'):show()
  window:getChildById('tabLoot'):setText('Botin (' .. #info.loot .. ')')
  window:getChildById('tabLocation'):setText('Localizacion (' .. #info.locations .. ')')
  buildInfoPanel(info)
  buildLootPanel(info)
  buildLocationPanel(info)
  showTab(currentTab)

  local row = rows[info.number]
  if row then
    local list = window:getChildById('dexList')
    if list:getFocusedChild() ~= row then
      list:focusChild(row, ActiveFocusReason)
    end
    list:ensureChildVisible(row)
  end
end

function showTab(tab)
  if not current then return end
  currentTab = tab
  window:getChildById('tabInfo'):setOn(tab == 'info')
  window:getChildById('tabLoot'):setOn(tab == 'loot')
  window:getChildById('tabLocation'):setOn(tab == 'location')
  window:getChildById('infoPanel'):setVisible(tab == 'info')
  window:getChildById('infoScrollBar'):setVisible(tab == 'info')
  window:getChildById('lootPanel'):setVisible(tab == 'loot')
  window:getChildById('lootScrollBar'):setVisible(tab == 'loot')
  window:getChildById('locationPanel'):setVisible(tab == 'location')
  window:getChildById('locationScrollBar'):setVisible(tab == 'location')
end

local function addSection(panel, text)
  local label = g_ui.createWidget('PokedexSection', panel)
  label:setText(text)
end

local function addText(panel, text, color)
  local label = g_ui.createWidget('PokedexText', panel)
  label:setText(text)
  if color then label:setColor(color) end
end

local function addStat(panel, name, value)
  local stat = g_ui.createWidget('PokedexStat', panel)
  stat:getChildById('name'):setText(name)
  stat:getChildById('value'):setText(value)
end

function buildInfoPanel(info)
  local panel = window:getChildById('infoPanel')
  panel:destroyChildren()
  local s = info.stats

  addSection(panel, 'Estadisticas base')
  addStat(panel, 'Vida', s[1] or '?')
  addStat(panel, 'Ataque', s[2] or '?')
  addStat(panel, 'Ataque especial', s[3] or '?')
  addStat(panel, 'Defensa especial', s[4] or '?')
  addStat(panel, 'Defensa', s[5] or '?')
  addStat(panel, 'Velocidad', s[6] or '?')
  addStat(panel, 'Nivel salvaje', (s[7] or '?') .. ' - ' .. (s[8] or '?'))
  addStat(panel, 'Experiencia', s[9] or '?')

  addSection(panel, 'Habilidades')
  addText(panel, #info.abilities > 0 and table.concat(info.abilities, ', ') or 'Ninguna')

  addSection(panel, 'Evoluciones')
  if #info.evolutions == 0 then
    addText(panel, 'No evoluciona.')
  end
  for _, e in ipairs(info.evolutions) do
    local text = e.name .. ': al nivel ' .. e.level
    if e.chance > 0 and e.chance < 100 then text = text .. ' (' .. e.chance .. '% de probabilidad)' end
    if e.item and e.item ~= '' then
      text = text .. ' o usando ' .. (e.count > 1 and (e.count .. ' ') or '') .. e.item
    end
    addText(panel, text)
  end

  addSection(panel, 'Ataques (' .. #info.moves .. ')')
  if #info.moves == 0 then
    addText(panel, 'Sin ataques.')
    return
  end
  local grid = g_ui.createWidget('PokedexMoves', panel)
  local perRow = math.max(1, math.floor((panel:getWidth() + 4) / 40))
  if perRow < 4 then perRow = 10 end
  local rowCount = math.ceil(#info.moves / perRow)
  grid:setHeight(rowCount * 40 - 4)
  for i, move in ipairs(info.moves) do
    local slot = g_ui.createWidget('PokedexMoveIcon', grid)
    local path = '/game_pokemonmoves/moves_icon/' .. move.name:lower() .. '_on.png'
    if g_resources.fileExists(path) then
      slot:getChildById('icon'):setImageSource(path)
    end
    local lines = { 'm' .. i .. ' - ' .. titleCase(move.name), 'Espera: ' .. move.cooldown .. 's' }
    local element = TYPES[move.element or '']
    if element then table.insert(lines, 'Tipo: ' .. element[1]) end
    if CATEGORY_TEXT[move.category or ''] then
      table.insert(lines, 'Forma: ' .. CATEGORY_TEXT[move.category])
    elseif move.target then
      table.insert(lines, 'Forma: Objetivo')
    end
    if EFFECT_TEXT[move.effect or ''] then table.insert(lines, 'Efecto: ' .. EFFECT_TEXT[move.effect]) end
    slot:setTooltip(table.concat(lines, '\n'))
  end
end

function buildLootPanel(info)
  local panel = window:getChildById('lootPanel')
  panel:destroyChildren()
  if #info.loot == 0 then
    addText(panel, 'Este pokemon no suelta objetos.')
    return
  end
  addText(panel, 'Probabilidad de que salga cada objeto al derrotarlo.', '#9fb3cc')
  for _, loot in ipairs(info.loot) do
    local row = g_ui.createWidget('PokedexLootRow', panel)
    if loot.clientId > 0 then
      row:getChildById('item'):setItemId(loot.clientId)
    end
    row:getChildById('name'):setText(titleCase(loot.name))
    row:getChildById('count'):setText('Cantidad: ' .. loot.count)
    row:getChildById('chance'):setText(loot.chance .. '%')
  end
end

function buildLocationPanel(info)
  local panel = window:getChildById('locationPanel')
  panel:destroyChildren()
  if #info.locations == 0 then
    addText(panel, 'No aparece en estado salvaje (evolucion, evento, misiones...).')
    return
  end
  if info.fromBase then
    addText(panel, 'Los shiny aparecen al azar en lugar de su forma normal, en estas zonas:', '#ffd84a')
  end

  local all = {}
  for _, loc in ipairs(info.locations) do
    table.insert(all, { x = loc.x, y = loc.y, z = loc.z, text = info.name .. (loc.town ~= '' and (' (cerca de ' .. loc.town .. ')') or '') })
  end
  local allButton = g_ui.createWidget('PokedexTab', panel)
  allButton:setText('Ver todas en el mapa')
  allButton.onClick = function() showOnMap(all, info.name) end

  for i, loc in ipairs(info.locations) do
    local row = g_ui.createWidget('PokedexLocationRow', panel)
    row:getChildById('town'):setText(loc.town ~= '' and ('Cerca de ' .. loc.town) or 'Zona ' .. i)
    row:getChildById('detail'):setText(loc.count .. ' en la zona  -  ' .. loc.x .. ', ' .. loc.y .. '  (' .. floorText(loc.z) .. ')')
    row:getChildById('showButton').onClick = function() showOnMap({ all[i] }, info.name) end
  end
end

function showOnMap(positions, title)
  local minimap = modules.game_minimap
  if not minimap or not minimap.showPositions then return end
  hide()
  minimap.showPositions(positions, title)
end
