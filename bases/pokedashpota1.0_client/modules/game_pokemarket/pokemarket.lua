-- Mercado global entre jugadores (servidor: data/lib/core/pokemarket.lua).
-- El cliente pide con la talkaction "pokemarket ..." (los opcodes cliente->servidor no llegan) y el
-- servidor contesta por el opcode 77: primera linea "tipo|cabecera...", despues una fila por linea.
-- OJO: g_game.talk solo funciona dentro de un click o una tecla, por eso todo se pide desde botones.

local OPCODE_MARKET = 77

local CATEGORIES = {
  {id = 'todo', text = 'Todo'},
  {id = 'pokemon', text = 'Pok\233mon'},
  {id = 'balls', text = 'Pok\233 Balls'},
  {id = 'stones', text = 'Piedras'},
  {id = 'potions', text = 'Pociones'},
  {id = 'otros', text = 'Otros'},
}

-- columnas de cada pestana: {titulo, x, ancho, alineacion}
local COLUMNS = {
  buy = {{'#', 8, 30}, {'Objeto', 40, 40}, {'Nombre', 84, 170}, {'Vendedor', 258, 110}, {'Cant.', 372, 50, 'center'},
    {'Precio', 426, 100, 'right'}, {'Quedan', 536, 70, 'right'}},
  sell = {{'Objeto', 40, 40}, {'Nombre', 84, 170}, {'Cant.', 258, 50, 'center'}, {'Tipo', 312, 80}},
  mine = {{'Objeto', 40, 40}, {'Nombre', 84, 170}, {'Cant.', 258, 50, 'center'}, {'Precio', 312, 100, 'right'},
    {'Caduca en', 420, 80, 'right'}},
  locker = {{'Objeto', 40, 40}, {'Nombre', 84, 200}, {'Cant.', 288, 40, 'center'}, {'Motivo', 334, 170},
    {'Fecha', 508, 80, 'right'}},
}

local CATEGORY_NAMES = {pokemon = 'Pok\233mon', balls = 'Pok\233 Ball', stones = 'Piedra', potions = 'Poci\243n', otros = 'Otro'}

window = nil
marketButton = nil

local tab = 'buy'
local category = 'todo'
local page, pages = 1, 1
local search = ''
local rowsData = {}
local selected = nil
local taxRate = 0.05
local lockerCount = 0

local function child(id)
  return window:recursiveGetChildById(id)
end

local function request(text)
  if g_game.isOnline() then
    g_game.talk('pokemarket ' .. text)
  end
end

local function split(text, sep)
  local parts = {}
  for part in (text .. sep):gmatch('(.-)' .. sep:gsub('%p', '%%%0')) do
    parts[#parts + 1] = part
  end
  return parts
end

local function money(n)
  local s = tostring(math.floor(tonumber(n) or 0))
  local formatted = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
  return '$' .. formatted:gsub('^%.', '')
end

local function pokemonIcon(name)
  if not name or name == '' then return nil end
  local path = '/game_pokemonbar/bar_icon/' .. name:lower() .. '.png'
  if g_resources.fileExists(path) then return path end
  return nil
end

local function setStatus(text, ok)
  local label = child('statusLabel')
  label:setText(text or '')
  label:setColor(ok == nil and '#8b95a5' or (ok and '#43a047' or '#e53935'))
end

local function setBalance(amount)
  if amount then
    child('balanceLabel'):setText('Banco: ' .. money(amount))
  end
end

local function setLockerCount(n)
  lockerCount = tonumber(n) or lockerCount
  child('tabLocker'):setText(lockerCount > 0 and ('Recibidos (' .. lockerCount .. ')') or 'Recibidos')
end

-- ===================== Tabla =====================
local function alignOf(name)
  if name == 'center' then return AlignCenter end
  if name == 'right' then return AlignRight end
  return AlignLeft
end

local function buildHeader()
  local header = child('header')
  header:destroyChildren()
  for _, col in ipairs(COLUMNS[tab]) do
    local label = g_ui.createWidget('MarketHeaderLabel', header)
    label:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    label:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    label:setMarginLeft(col[2])
    label:setWidth(col[3])
    label:setTextAlign(alignOf(col[4]))
    label:setText(col[1])
  end
end

local function selectRow(row, data)
  for _, other in ipairs(child('rowList'):getChildren()) do
    other:setOn(false)
  end
  row:setOn(true)
  selected = data
  if tab == 'sell' then
    modules.game_pokemarket.showSellItem(data)
  elseif tab == 'buy' then
    child('countEdit'):setText(data.category == 'pokemon' and '1' or tostring(data.count))
  end
end

-- cells: textos en el orden de COLUMNS[tab] (la columna 'Objeto' se salta: es el icono)
local function addRow(data, cells, clientId, iconName)
  local row = g_ui.createWidget('MarketRow', child('rowList'))
  local columns = COLUMNS[tab]
  local cellIndex = 1
  for _, col in ipairs(columns) do
    if col[1] ~= 'Objeto' then
      local label = g_ui.createWidget('MarketCell', row)
      label:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      label:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
      label:setMarginLeft(col[2])
      label:setWidth(col[3])
      label:setTextAlign(alignOf(col[4]))
      label:setText(cells[cellIndex] or '')
      cellIndex = cellIndex + 1
    end
  end
  local icon = pokemonIcon(iconName)
  if icon then
    row:getChildById('pokemon'):setImageSource(icon)
    row:getChildById('pokemon'):show()
    row:getChildById('item'):hide()
  elseif clientId and clientId > 0 then
    row:getChildById('item'):setItemId(clientId)
  else
    row:getChildById('item'):hide()
  end
  row.onClick = function() selectRow(row, data) end
  return row
end

local function clearRows(emptyText)
  child('rowList'):destroyChildren()
  selected = nil
  rowsData = {}
  local empty = child('emptyLabel')
  empty:setText(emptyText or '')
  empty:setVisible(false)
end

local function showEmpty(show)
  child('emptyLabel'):setVisible(show)
end

-- ===================== Disposicion de cada pestana =====================
local function layoutTab()
  for id, name in pairs({tabBuy = 'buy', tabSell = 'sell', tabMine = 'mine', tabLocker = 'locker'}) do
    child(id):setOn(tab == name)
  end
  local isBuy, isSell = tab == 'buy', tab == 'sell'
  child('categoryPanel'):setVisible(isBuy)
  child('searchEdit'):setVisible(isBuy)
  child('searchHint'):setVisible(isBuy and child('searchEdit'):getText() == '')
  child('searchButton'):setVisible(isBuy)
  for _, id in ipairs({'firstButton', 'prevButton', 'pageLabel', 'nextButton', 'lastButton', 'countEdit', 'countLabel'}) do
    child(id):setVisible(isBuy)
  end
  child('sellForm'):setVisible(isSell)
  child('actionButton'):setVisible(not isSell)
  child('secondButton'):setVisible(tab == 'locker')
  local formSpace = isSell and (250 + 8) or 0
  child('header'):setMarginRight(14 + formSpace)
  child('rowScroll'):setMarginRight(14 + formSpace)
  child('footer'):setMarginRight(14 + formSpace)
  if tab == 'buy' then
    child('actionButton'):setText('Comprar')
  elseif tab == 'mine' then
    child('actionButton'):setText('Cancelar oferta')
  elseif tab == 'locker' then
    child('actionButton'):setText('Recoger todo')
    child('secondButton'):setText('Recoger')
  end
  buildHeader()
end

function selectTab(name)
  tab = name
  layoutTab()
  clearRows()
  setStatus('Cargando...')
  if name == 'buy' then
    request('list ' .. category .. ' ' .. page .. (search ~= '' and (' ' .. search) or ''))
  elseif name == 'sell' then
    showSellItem(nil)
    request('inv')
  elseif name == 'mine' then
    request('mine')
  elseif name == 'locker' then
    request('locker')
  end
end

local function buildCategories()
  local panel = child('categoryPanel')
  panel:destroyChildren()
  for _, cat in ipairs(CATEGORIES) do
    local button = g_ui.createWidget('MarketCategory', panel)
    button:setText(cat.text)
    button:setOn(cat.id == category)
    button.onClick = function()
      category = cat.id
      page = 1
      for _, other in ipairs(panel:getChildren()) do other:setOn(other == button) end
      request('list ' .. category .. ' 1' .. (search ~= '' and (' ' .. search) or ''))
    end
  end
end

function doSearch()
  search = child('searchEdit'):getText():gsub('[|\n]', ''):sub(1, 30)
  page = 1
  request('list ' .. category .. ' 1' .. (search ~= '' and (' ' .. search) or ''))
end

function gotoPage(where)
  local target = page
  if where == 'first' then target = 1
  elseif where == 'prev' then target = math.max(1, page - 1)
  elseif where == 'next' then target = math.min(pages, page + 1)
  elseif where == 'last' then target = pages end
  if target ~= page then
    request('list ' .. category .. ' ' .. target .. (search ~= '' and (' ' .. search) or ''))
  end
end

function doAction()
  if tab == 'buy' then
    if not selected then return setStatus('Elige una oferta de la lista.', false) end
    local count = tonumber(child('countEdit'):getText()) or 1
    request('buy ' .. selected.id .. ' ' .. math.max(1, math.floor(count)) .. ' ' .. category .. ' ' .. page ..
      (search ~= '' and (' ' .. search) or ''))
  elseif tab == 'mine' then
    if not selected then return setStatus('Elige una de tus ofertas.', false) end
    request('cancel ' .. selected.id)
  elseif tab == 'locker' then
    request('take all')
  end
end

function doSecondAction()
  if tab == 'locker' then
    if not selected then return setStatus('Elige algo de la lista.', false) end
    request('take ' .. selected.id)
  end
end

-- ===================== Vender =====================
function showSellItem(data)
  local itemWidget, pokeWidget = child('sellItem'), child('sellPokemon')
  if not data then
    itemWidget:setItemId(0)
    pokeWidget:hide()
    itemWidget:show()
    child('sellName'):setText('Elige algo de la lista')
    child('sellCount'):setText('1')
    child('sellPrice'):setText('')
    child('sellButton'):setEnabled(false)
    updateSellInfo()
    return
  end
  local icon = pokemonIcon(data.icon)
  if icon then
    pokeWidget:setImageSource(icon)
    pokeWidget:show()
    itemWidget:hide()
  else
    itemWidget:setItemId(data.clientId)
    itemWidget:show()
    pokeWidget:hide()
  end
  child('sellName'):setText(data.name)
  child('sellCount'):setText(tostring(data.count))
  child('sellCount'):setEnabled(data.category ~= 'pokemon' and data.count > 1)
  child('sellButton'):setEnabled(true)
  updateSellInfo()
end

function updateSellInfo()
  if not window then return end
  local info = child('sellInfo')
  if not selected or tab ~= 'sell' then
    info:setText('La comisi\243n del mercado es del ' .. math.floor(taxRate * 100 + 0.5) .. '%. Lo que no se venda en 7 d\237as vuelve a Recibidos.')
    return
  end
  local count = math.max(1, math.min(selected.count, math.floor(tonumber(child('sellCount'):getText()) or 1)))
  local price = math.floor(tonumber(child('sellPrice'):getText()) or 0)
  if price <= 0 then
    info:setText('Escribe el precio por unidad.\nComisi\243n: ' .. math.floor(taxRate * 100 + 0.5) .. '%.')
    return
  end
  local total = price * count
  info:setText('Total: ' .. money(total) .. '\nComisi\243n (' .. math.floor(taxRate * 100 + 0.5) .. '%): ' ..
    money(total - math.floor(total * (1 - taxRate))) .. '\nRecibir\225s: ' .. money(math.floor(total * (1 - taxRate))))
end

function doSell()
  if not selected then return setStatus('Elige algo de la lista.', false) end
  local count = math.floor(tonumber(child('sellCount'):getText()) or 0)
  local price = math.floor(tonumber(child('sellPrice'):getText()) or 0)
  if count < 1 or count > selected.count then return setStatus('Cantidad no v\225lida (m\225ximo ' .. selected.count .. ').', false) end
  if price < 1 then return setStatus('Escribe un precio.', false) end
  request('sell ' .. selected.index .. ' ' .. count .. ' ' .. price)
end

-- ===================== Mensajes del servidor =====================
local function onList(header, lines)
  -- list|categoria|pagina|paginas|total|banco|recibidos|busqueda
  category, page, pages = header[2], tonumber(header[3]) or 1, tonumber(header[4]) or 1
  setBalance(header[6])
  setLockerCount(header[7])
  if tab ~= 'buy' then
    tab = 'buy'
    layoutTab()
  end
  clearRows(category == 'todo' and search == '' and 'Todav\237a no hay nada a la venta.' or 'No hay ofertas con ese filtro.')
  for i, line in ipairs(lines) do
    local f = split(line, '|')
    local data = {id = tonumber(f[1]), clientId = tonumber(f[2]), name = f[3], seller = f[4], count = tonumber(f[5]) or 1,
      price = tonumber(f[6]) or 0, category = f[8], icon = f[9], mine = f[10] == '1'}
    local number = (page - 1) * 10 + i
    local row = addRow(data, {'#' .. number, data.name, data.mine and (data.seller .. ' (t\250)') or data.seller,
      tostring(data.count), money(data.price), f[7]}, data.clientId, data.icon)
    if data.mine then row:setOpacity(0.75) end
  end
  showEmpty(#lines == 0)
  child('pageLabel'):setText(page .. '/' .. pages)
  child('firstButton'):setEnabled(page > 1)
  child('prevButton'):setEnabled(page > 1)
  child('nextButton'):setEnabled(page < pages)
  child('lastButton'):setEnabled(page < pages)
  for _, button in ipairs(child('categoryPanel'):getChildren()) do
    button:setOn(button:getText() == (function() for _, c in ipairs(CATEGORIES) do if c.id == category then return c.text end end end)())
  end
  setStatus((tonumber(header[5]) or 0) .. ' ofertas')
end

local function onInventory(header, lines)
  setBalance(header[2])
  taxRate = tonumber(header[3]) or taxRate
  if tab ~= 'sell' then
    tab = 'sell'
    layoutTab()
  end
  clearRows('No tienes nada que se pueda vender en la mochila.')
  showSellItem(nil)
  for _, line in ipairs(lines) do
    local f = split(line, '|')
    local data = {index = tonumber(f[1]), clientId = tonumber(f[2]), name = f[3], count = tonumber(f[4]) or 1, category = f[5], icon = f[6]}
    addRow(data, {data.name, tostring(data.count), CATEGORY_NAMES[data.category] or ''}, data.clientId, data.icon)
  end
  showEmpty(#lines == 0)
  setStatus('Elige qu\233 vender. Los Pok\233mon que tienes fuera no salen en la lista.')
end

local function onOwnOffers(header, lines)
  if tab ~= 'mine' then
    tab = 'mine'
    layoutTab()
  end
  clearRows('No tienes nada a la venta.')
  for _, line in ipairs(lines) do
    local f = split(line, '|')
    local data = {id = tonumber(f[1]), clientId = tonumber(f[2]), name = f[3], count = tonumber(f[4]) or 1, icon = f[7]}
    addRow(data, {data.name, tostring(data.count), money(f[5]), f[6]}, data.clientId, data.icon)
  end
  showEmpty(#lines == 0)
  setStatus((header[2] or 0) .. ' de ' .. (header[3] or 20) .. ' ofertas')
end

local function onLocker(header, lines)
  if tab ~= 'locker' then
    tab = 'locker'
    layoutTab()
  end
  setLockerCount(header[2])
  clearRows('No tienes nada por recoger.')
  for _, line in ipairs(lines) do
    local f = split(line, '|')
    local data = {id = tonumber(f[1]), clientId = tonumber(f[2]), name = f[3], count = tonumber(f[4]) or 0}
    local isNote = data.clientId == 0
    local row = addRow(data, {data.name, isNote and '' or tostring(data.count), f[5], f[6]}, data.clientId,
      not isNote and f[3]:match('^(.-) %+%d+$') or (not isNote and f[3]) or nil)
    if isNote then
      row:getChildren()[3]:setColor('#f2c14e')
    end
  end
  showEmpty(#lines == 0)
  setStatus(#lines > 0 and 'Recoge lo comprado, lo cancelado y lo caducado. Los avisos de ventas se borran al recogerlos.' or '')
end

function onMarketOpcode(protocol, opcode, buffer)
  local lines = split(buffer or '', '\n')
  local header = split(table.remove(lines, 1) or '', '|')
  local kind = header[1]
  if kind == 'away' then
    if modules.game_textmessage and modules.game_textmessage.displayFailureMessage then
      modules.game_textmessage.displayFailureMessage(header[2] or '')
    end
    return
  end
  if not window:isVisible() and kind ~= 'msg' then
    show()
  end
  if kind == 'list' then onList(header, lines)
  elseif kind == 'inv' then onInventory(header, lines)
  elseif kind == 'mine' then onOwnOffers(header, lines)
  elseif kind == 'locker' then onLocker(header, lines)
  elseif kind == 'msg' then setStatus(header[3] or '', header[2] == '1')
  end
end

-- ===================== Ventana =====================
function show()
  window:show()
  window:raise()
  window:focus()
  if marketButton then marketButton:setOn(true) end
end

function hide()
  window:hide()
  if marketButton then marketButton:setOn(false) end
end

function toggle()
  if window:isVisible() then
    hide()
  else
    tab = 'buy'
    request('open ' .. category .. ' 1')
  end
end

function onGameEnd()
  hide()
end

function init()
  window = g_ui.displayUI('pokemarket')
  window:hide()
  buildCategories()
  layoutTab()
  marketButton = modules.client_topmenu.addRightGameToggleButton('marketButton', 'Mercado',
    '/images/topmenu/market', toggle)
  marketButton:setOn(false)
  local edit = child('searchEdit')
  edit.onTextChange = function(widget, text)
    child('searchHint'):setVisible(text == '' and tab == 'buy')
  end
  edit.onKeyPress = function(widget, keyCode)
    if keyCode == KeyEnter then
      doSearch()
      return true
    end
    return false
  end
  ProtocolGame.registerExtendedOpcode(OPCODE_MARKET, onMarketOpcode)
  connect(g_game, { onGameEnd = onGameEnd })
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_MARKET)
  disconnect(g_game, { onGameEnd = onGameEnd })
  if marketButton then marketButton:destroy() marketButton = nil end
  window:destroy()
end
