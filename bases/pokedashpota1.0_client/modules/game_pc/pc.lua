-- PC de Pokemon y objetos (servidor: data/lib/core/pokepc.lua).
-- Se abre al usar un PC. El cliente pide con la talkaction "pkdpc ..." y el servidor contesta por
-- el opcode 78: primera linea "tipo|cabecera...", despues una fila por linea.
-- OJO: g_game.talk solo funciona dentro de un click o una tecla: todo se pide desde el propio
-- gesto (clic, doble clic, soltar al arrastrar o una opcion del menu).

local OPCODE_PC = 78
local TEAM_SIZE = 6
local MONS_PAGE = 20
local ITEMS_PAGE = 48
local BAG_SIZE = 48
local MAX_REACH = 2

local SORTS = {{'recent', 'Recientes'}, {'name', 'Nombre'}, {'dex', 'N\250mero'}, {'boost', 'Boost'}}
local CATEGORIES = {{'todo', 'Todo'}, {'balls', 'Balls'}, {'potions', 'Curaci\243n'}, {'stones', 'Piedras'},
  {'runas', 'Runas'}, {'orbes', 'Orbes'}, {'otros', 'Otros'}}
local TYPE_NAMES = {water = 'Agua', fire = 'Fuego', grass = 'Planta', poison = 'Veneno', flying = 'Volador',
  rock = 'Roca', ground = 'Tierra', normal = 'Normal', psychic = 'Ps\237quico', ghost = 'Fantasma',
  fighting = 'Lucha', electric = 'El\233ctrico', ice = 'Hielo', bug = 'Bicho', dragon = 'Drag\243n',
  dark = 'Siniestro', steel = 'Acero', fairy = 'Hada'}
local TYPE_COLORS = {water = '#2f7fd6', fire = '#d2542c', grass = '#3c8f3f', poison = '#8b4aa8',
  flying = '#6f7fd0', rock = '#8f7a3a', ground = '#9a6b34', normal = '#6f7280', psychic = '#c23f78',
  ghost = '#5a4b8f', fighting = '#a8402f', electric = '#a67c00', ice = '#2c8c9a', bug = '#66801f',
  dragon = '#5a3fc0', dark = '#4a3f3a', steel = '#5f7d8c', fairy = '#b8578f'}
local HELP_MONS = 'Arrastra para sacar, guardar o intercambiar. Tambi\233n con doble clic.'
local HELP_ITEMS = 'Arrastra entre la mochila y el PC. Tambi\233n con doble clic.'

window = nil

local tab = 'mons'
local mons = {team = {}, box = {}, page = 1, pages = 1, sort = 'recent'}
local items = {bag = {}, box = {}, page = 1, pages = 1, category = 'todo'}
local search = {mons = '', items = ''}
local dragged = nil
local ghost = nil
local pending = nil
local openedAt = nil
local detailUid = nil

local function child(id)
  return window:recursiveGetChildById(id)
end

local function request(text)
  if g_game.isOnline() then
    g_game.talk('pkdpc ' .. text)
  end
end

local function split(text, sep)
  local parts = {}
  for part in (text .. sep):gmatch('(.-)' .. sep:gsub('%p', '%%%0')) do
    parts[#parts + 1] = part
  end
  return parts
end

local function pokemonIcon(name)
  local path = '/game_pokemonbar/bar_icon/' .. name:lower() .. '.png'
  if g_resources.fileExists(path) then return path end
  return '/game_pokedex/images/pokeball_big'
end

local function setStatus(text, ok)
  local label = child('statusLabel')
  label:setText(text or '')
  if ok == nil then
    label:setColor('#8b95a5')
  else
    label:setColor(ok and '#6fdc8c' or '#ff7b72')
  end
end

local function requestMons(page)
  request('mons ' .. (page or mons.page) .. ' ' .. mons.sort .. (search.mons ~= '' and (' ' .. search.mons) or ''))
end

local function requestItems(page)
  request('items ' .. (page or items.page) .. ' ' .. items.category .. (search.items ~= '' and (' ' .. search.items) or ''))
end

-- ===================== Arrastrar =====================
local function destroyGhost()
  if ghost then
    ghost:destroy()
    ghost = nil
  end
end

local function makeDraggable(widget, info)
  widget:setDraggable(true)
  widget.onDragEnter = function(self, mousePos)
    dragged = info
    destroyGhost()
    if info.look then
      ghost = g_ui.createWidget('UICreature', rootWidget)
      ghost:setOutfit({type = info.look})
    else
      ghost = g_ui.createWidget('UIItem', rootWidget)
      ghost:setVirtual(true)
      ghost:setItemId(info.clientId)
    end
    ghost:setSize(info.look and {width = 64, height = 64} or {width = 40, height = 40})
    ghost:setPhantom(true)
    ghost:setOpacity(0.85)
    ghost:setPosition({x = mousePos.x - 20, y = mousePos.y - 20})
    g_mouse.pushCursor('target')
    return true
  end
  widget.onDragMove = function(self, mousePos)
    if ghost then
      ghost:setPosition({x = mousePos.x - 20, y = mousePos.y - 20})
    end
    return true
  end
  widget.onDragLeave = function()
    destroyGhost()
    g_mouse.popCursor('target')
    return true
  end
end

-- ===================== Pokemon =====================
local function swapMons(teamUid, boxUid)
  request('swap ' .. teamUid .. ' ' .. boxUid)
end

-- target: {area = 'team'|'box', uid = numero o 0}
local function dropMon(target)
  local source = dragged
  dragged = nil
  if not source or (source.area ~= 'team' and source.area ~= 'box') then
    return
  end
  if source.area == target.area then
    return
  end
  if source.area == 'team' then
    swapMons(source.uid, target.uid)
  else
    swapMons(target.uid, source.uid)
  end
end

local function quickMon(area, uid)
  if area == 'team' then
    swapMons(uid, 0)
  elseif #mons.team >= TEAM_SIZE then
    setStatus('El equipo est\225 lleno: arr\225stralo encima del que quieras cambiar.', false)
  else
    swapMons(0, uid)
  end
end

local function capitalize(name)
  return (name:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
end

-- ficha de la derecha: dibujo, tipos con su color, datos en dos columnas y ataques
local function showDetail(mon)
  local panel = child('detail')
  local art = panel:getChildById('art')
  local types, rows, moves = panel:getChildById('types'), panel:getChildById('rows'), panel:getChildById('moves')
  types:destroyChildren()
  rows:destroyChildren()
  moves:destroyChildren()
  panel:getChildById('movesTitle'):setVisible(mon ~= nil)
  if not mon then
    detailUid = nil
    art:setImageSource('')
    panel:getChildById('name'):setText('')
    return
  end
  detailUid = mon.uid
  -- en grande se usa el dibujo de 128x128 de la Pokedex: el retrato pequeno se pixela
  local big = '/game_pokedex/artwork/' .. mon.name:lower() .. '.png'
  art:setImageSource(g_resources.fileExists(big) and big or pokemonIcon(mon.name))
  panel:getChildById('name'):setText(mon.name)
  for _, t in ipairs(mon.types) do
    local chip = g_ui.createWidget('PcTypeChip', types)
    chip:setText(TYPE_NAMES[t] or t)
    chip:setImageColor(TYPE_COLORS[t] or '#6f7280')
  end
  types:setWidth(math.max(1, #mon.types) * 72 - 6)
  for _, data in ipairs({{'Pok\233dex', '#' .. mon.dex}, {'Boost', '+' .. mon.boost}, {'Vida', mon.hp .. '%'}}) do
    local row = g_ui.createWidget('PcInfoRow', rows)
    row:getChildById('key'):setText(data[1])
    row:getChildById('value'):setText(data[2])
  end
  for _, move in ipairs(mon.moves) do
    g_ui.createWidget('PcMove', moves):setText(capitalize(move))
  end
end

local function bindMon(widget, area, mon)
  local uid = mon and mon.uid or 0
  widget.onDrop = function()
    dropMon({area = area, uid = uid})
    return true
  end
  if not mon then return end
  makeDraggable(widget, {area = area, uid = uid, look = mon.look})
  widget.onHoverChange = function(self, hovered)
    if hovered then showDetail(mon) end
  end
  widget.onDoubleClick = function()
    quickMon(area, uid)
    return true
  end
  widget.onMouseRelease = function(self, mousePos, button)
    if button == MouseRightButton then
      local menu = g_ui.createWidget('PopupMenu')
      menu:setGameMenu(true)
      menu:addOption(area == 'team' and 'Guardar en el PC' or 'Llevar en el equipo', function() quickMon(area, uid) end)
      menu:display(mousePos)
      return true
    end
    return false
  end
end

local function renderMons()
  local teamList = child('teamList')
  teamList:destroyChildren()
  child('teamTitle'):setText('TU EQUIPO ' .. #mons.team .. '/' .. TEAM_SIZE)
  for i = 1, TEAM_SIZE do
    local mon = mons.team[i]
    local slot = g_ui.createWidget('PcTeamSlot', teamList)
    if mon then
      slot:getChildById('art'):setOutfit({type = mon.look})
      slot:getChildById('name'):setText(mon.name .. (mon.boost > 0 and ('  +' .. mon.boost) or ''))
      slot:getChildById('bar'):setWidth(math.floor(130 * mon.hp / 100))
      slot:getChildById('bar'):setBackgroundColor(mon.hp > 50 and '#43c463' or '#e0a526')
      slot:getChildById('sub'):setText(mon.out and 'Fuera ahora' or (mon.hp == 0 and 'Debilitado' or ('Vida ' .. mon.hp .. '%')))
      if mon.out then
        slot:setBackgroundColor('#33222a')
        slot:setBorderColor('#e0484f')
      end
      if mon.hp == 0 then slot:getChildById('art'):setOpacity(0.4) end
    else
      slot:getChildById('art'):hide()
      slot:getChildById('name'):setText('Hueco libre')
      slot:getChildById('sub'):setText('Suelta aqu\237 un Pok\233mon')
      slot:getChildById('barBack'):hide()
      slot:getChildById('bar'):hide()
      slot:setOpacity(0.7)
    end
    bindMon(slot, 'team', mon)
  end

  local grid = child('monGrid')
  grid:destroyChildren()
  for i = 1, MONS_PAGE do
    local mon = mons.box[i]
    local cell = g_ui.createWidget('PcMonCell', grid)
    if mon then
      cell:getChildById('art'):setOutfit({type = mon.look})
      cell:getChildById('name'):setText(mon.name)
      cell:getChildById('boost'):setText(mon.boost > 0 and ('+' .. mon.boost) or '')
      if mon.hp == 0 then cell:getChildById('art'):setOpacity(0.4) end
    else
      cell:getChildById('art'):hide()
      cell:setOpacity(0.45)
    end
    bindMon(cell, 'box', mon)
  end
  grid.onDrop = function()
    dropMon({area = 'box', uid = 0})
    return true
  end
  local zone = child('storeZone')
  zone:setText('Soltar para guardar')
  zone.onDrop = grid.onDrop

  child('monPageLabel'):setText('P\225gina ' .. mons.page .. ' / ' .. mons.pages)
  child('monPrev'):setEnabled(mons.page > 1)
  child('monNext'):setEnabled(mons.page < mons.pages)

  local current
  for _, list in ipairs({mons.team, mons.box}) do
    for _, mon in ipairs(list) do
      if mon.uid == detailUid then current = mon end
    end
  end
  showDetail(current or mons.box[1] or mons.team[1])
end

-- ===================== Objetos =====================
function cancelAsk()
  pending = nil
  child('askPanel'):hide()
end

function confirmAsk()
  local move = pending
  if not move then return cancelAsk() end
  local amount = math.floor(tonumber(child('askEdit'):getText()) or 0)
  if amount < 1 or amount > move.count then
    setStatus('Escribe un n\250mero entre 1 y ' .. move.count .. '.', false)
    return
  end
  cancelAsk()
  request((move.area == 'bag' and 'put ' or 'take ') .. move.index .. ' ' .. amount)
end

local function askMove(row)
  if row.count <= 1 then
    request((row.area == 'bag' and 'put ' or 'take ') .. row.index .. ' 1')
    return
  end
  pending = row
  child('askText'):setText('\191Cu\225ntos quieres ' .. (row.area == 'bag' and 'guardar' or 'sacar') .. '?\n' .. row.name)
  local edit = child('askEdit')
  edit:setText(tostring(row.count))
  child('askPanel'):show()
  child('askPanel'):raise()
  edit:focus()
  edit:setCursorPos(#tostring(row.count))
end

local function dropItem(area)
  local source = dragged
  dragged = nil
  if not source or (source.area ~= 'bag' and source.area ~= 'store') or source.area == area then
    return
  end
  askMove(source.row)
end

local function fillItemGrid(grid, list, size, area)
  grid:destroyChildren()
  for i = 1, size do
    local row = list[i]
    local cell = g_ui.createWidget('PcItemCell', grid)
    cell.onDrop = function()
      dropItem(area)
      return true
    end
    if row then
      cell:getChildById('item'):setItemId(row.clientId)
      cell:getChildById('count'):setText(row.count > 1 and tostring(row.count) or '')
      cell:setTooltip(row.name .. (row.count > 1 and (' x' .. row.count) or ''))
      local move = {area = row.area, index = row.index, count = row.count, name = row.name}
      makeDraggable(cell, {area = area, row = move, clientId = row.clientId})
      cell.onDoubleClick = function()
        askMove(move)
        return true
      end
    else
      cell:getChildById('item'):hide()
      cell:setOpacity(0.45)
    end
  end
  grid.onDrop = function()
    dropItem(area)
    return true
  end
end

local function renderItems()
  fillItemGrid(child('bagGrid'), items.bag, BAG_SIZE, 'bag')
  fillItemGrid(child('itemGrid'), items.box, ITEMS_PAGE, 'store')
  child('bagTitle'):setText('TU MOCHILA' .. ((items.hidden or 0) > 0 and ('  (hay ' .. items.hidden .. ' m\225s que no caben aqu\237)') or ''))
  child('itemPageLabel'):setText('P\225gina ' .. items.page .. ' / ' .. items.pages)
  child('itemPrev'):setEnabled(items.page > 1)
  child('itemNext'):setEnabled(items.page < items.pages)
end

-- ===================== Barras de arriba =====================
local function buildChips(bar, list, isOn, pick)
  bar:destroyChildren()
  for _, entry in ipairs(list) do
    local chip = g_ui.createWidget('PcChip', bar)
    chip:setText(entry[2])
    chip:setWidth(chip:getTextSize().width + 18)
    chip:setOn(isOn(entry[1]))
    chip.onClick = function() pick(entry[1]) end
  end
end

local function buildBars()
  buildChips(child('sortBar'), SORTS, function(id) return mons.sort == id end, function(id)
    mons.sort = id
    buildBars()
    requestMons(1)
  end)
  buildChips(child('categoryBar'), CATEGORIES, function(id) return items.category == id end, function(id)
    items.category = id
    buildBars()
    requestItems(1)
  end)
end

function selectTab(name)
  tab = name
  cancelAsk()
  child('tabMons'):setOn(name == 'mons')
  child('tabItems'):setOn(name == 'items')
  child('monsPage'):setVisible(name == 'mons')
  child('itemsPage'):setVisible(name == 'items')
  child('searchEdit'):setText(search[name])
  setStatus(name == 'mons' and HELP_MONS or HELP_ITEMS)
end

function doSearch()
  search[tab] = child('searchEdit'):getText():gsub('[|;\n]', ''):sub(1, 30)
  if tab == 'mons' then requestMons(1) else requestItems(1) end
end

function gotoPage(step)
  if tab == 'mons' then
    requestMons(math.max(1, math.min(mons.pages, mons.page + step)))
  else
    requestItems(math.max(1, math.min(items.pages, items.page + step)))
  end
end

-- ===================== Ventana =====================
local function hide()
  cancelAsk()
  destroyGhost()
  openedAt = nil
  window:hide()
end

function close()
  if window:isVisible() then
    request('close')
  end
  hide()
end

local function show()
  local player = g_game.getLocalPlayer()
  openedAt = player and player:getPosition()
  mons = {team = {}, box = {}, page = 1, pages = 1, sort = 'recent'}
  items = {bag = {}, box = {}, page = 1, pages = 1, category = 'todo'}
  search = {mons = '', items = ''}
  detailUid = nil
  buildBars()
  selectTab('mons')
  window:show()
  window:raise()
  window:focus()
end

local function parseMon(f)
  return {uid = tonumber(f[2]) or 0, name = f[3] or '?', boost = tonumber(f[4]) or 0, hp = tonumber(f[5]) or 0,
    out = f[6] == '1', dex = tonumber(f[7]) or 0,
    types = f[8] and f[8] ~= '' and split(f[8], ';') or {}, moves = f[9] and f[9] ~= '' and split(f[9], ';') or {},
    look = tonumber(f[10]) or 0}
end

function onPcOpcode(protocol, opcode, buffer)
  local lines = split(buffer or '', '\n')
  local header = split(table.remove(lines, 1) or '', '|')
  local kind = header[1]
  if kind == 'open' then
    show()
  elseif kind == 'close' then
    hide()
    if modules.game_textmessage and modules.game_textmessage.displayFailureMessage then
      modules.game_textmessage.displayFailureMessage(header[2] or '')
    end
  elseif kind == 'msg' then
    setStatus(header[3] or '', header[2] == '1')
  elseif kind == 'mons' then
    mons.page, mons.pages = tonumber(header[2]) or 1, tonumber(header[3]) or 1
    mons.team, mons.box = {}, {}
    for _, line in ipairs(lines) do
      local f = split(line, '|')
      local list = f[1] == 'T' and mons.team or mons.box
      list[#list + 1] = parseMon(f)
    end
    child('tabMons'):setText('Pok\233mon (' .. (header[4] or 0) .. ')')
    child('boxTitle'):setText('EN EL PC')
    renderMons()
  elseif kind == 'items' then
    items.page, items.pages = tonumber(header[2]) or 1, tonumber(header[3]) or 1
    items.hidden = tonumber(header[7]) or 0
    items.bag, items.box = {}, {}
    for _, line in ipairs(lines) do
      local f = split(line, '|')
      local isBag = f[1] == 'B'
      local row = {area = isBag and 'bag' or 'store', index = tonumber(f[2]) or 0, clientId = tonumber(f[3]) or 0,
        name = f[4] or '', count = tonumber(f[5]) or 1}
      local list = isBag and items.bag or items.box
      list[#list + 1] = row
    end
    child('tabItems'):setText('Objetos (' .. (header[4] or 0) .. ')')
    renderItems()
  end
end

local function onPositionChange(player, newPos)
  if window and window:isVisible() and openedAt and newPos then
    if newPos.z ~= openedAt.z or math.abs(newPos.x - openedAt.x) > MAX_REACH or math.abs(newPos.y - openedAt.y) > MAX_REACH then
      hide()
    end
  end
end

function init()
  window = g_ui.displayUI('pc')
  window:hide()
  local edit = child('searchEdit')
  edit.onKeyPress = function(widget, keyCode)
    if keyCode == KeyEnter then
      doSearch()
      return true
    end
    return false
  end
  local ask = child('askEdit')
  ask.onKeyPress = function(widget, keyCode)
    if keyCode == KeyEnter then
      confirmAsk()
      return true
    end
    return false
  end
  ProtocolGame.registerExtendedOpcode(OPCODE_PC, onPcOpcode)
  connect(LocalPlayer, {onPositionChange = onPositionChange})
  connect(g_game, {onGameEnd = hide})
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_PC)
  disconnect(LocalPlayer, {onPositionChange = onPositionChange})
  disconnect(g_game, {onGameEnd = hide})
  destroyGhost()
  window:destroy()
end
