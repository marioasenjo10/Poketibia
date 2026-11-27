-- Panel de Tareas (sustituye al quest log) y seguimiento de la tarea activa sobre el mapa.
-- El servidor manda todas las tareas por el opcode 90 (data/lib/core/progression.lua):
--   primera linea: cap|nivel|texto (nivel 0 = sin tope)
--   resto: indice|estado(1 activa, 2 hecha)|tipo|quien|titulo|texto|progreso|total|recompensa|mapa|icono
--   mapa (opcional): "x:y:z:texto;..." puntos para el boton "Ver en el mapa"; icono: Pokemon del marcador
-- El cliente solo muestra: no tiene que pedir nada al servidor.

local OPCODE_TASKS = 90

local KINDS = {
  talk = {text = 'Hablar', color = '#1e88e5'},
  reach = {text = 'Viajar', color = '#8e24aa'},
  catch = {text = 'Capturar', color = '#e53935'},
  defeat = {text = 'Derrotar', color = '#6d4c41'},
  badge = {text = 'Gimnasio', color = '#f9a825'},
}

window = nil
tasksButton = nil
tracker = nil

local tasks = {}
local capInfo = nil

local function child(id)
  return window:recursiveGetChildById(id)
end

local function trackerEnabled()
  return g_settings.get('tasksTracker') ~= 'false'
end

local function setProgress(widget, current, total)
  local fill = widget:getChildById('fill')
  local percent = total > 0 and math.min(1, current / total) or 0
  local width = math.floor(widget:getWidth() * percent)
  fill:setWidth(width)
  fill:setVisible(width > 0)
end

local function setChip(chip, text, color)
  chip:setText(text)
  chip:setWidth(chip:getTextSize().width + 18)
  chip:setImageColor(color)
end

local function split(text, sep)
  local parts = {}
  for part in (text .. sep):gmatch('(.-)' .. sep:gsub('%p', '%%%0')) do
    parts[#parts + 1] = part
  end
  return parts
end

local function mapIconFor(name)
  if not name or name == '' then return nil end
  local path = '/game_pokemonbar/bar_icon/' .. name:lower() .. '.png'
  if g_resources.fileExists(path) then return path end
  return nil
end

-- cada punto puede traer su propio Pokemon al final ("x:y:z:texto:Pokemon") para el icono del marcador
local function parseMapPoints(text)
  local points = {}
  for part in (text or ''):gmatch('[^;]+') do
    local x, y, z, label = part:match('^(%-?%d+):(%-?%d+):(%-?%d+):(.*)$')
    if x then
      local name, species = label:match('^([^:]*):(.*)$')
      points[#points + 1] = {x = tonumber(x), y = tonumber(y), z = tonumber(z), text = name or label,
        icon = mapIconFor(species)}
    end
  end
  return points
end

function showTaskOnMap(task)
  local minimap = modules.game_minimap
  if not task or #task.mapPoints == 0 or not minimap or not minimap.showPositions then return end
  hide()
  minimap.showPositions(task.mapPoints, task.title, mapIconFor(task.mapIcon))
end

-- ===================== Seguimiento sobre el mapa =====================
local createTracker

local function updateTracker()
  if not tracker then createTracker() end
  if not tracker then return end
  local active
  for _, task in ipairs(tasks) do
    if task.state == 1 and (not active or (active.optional and not task.optional)) then
      active = task
    end
  end
  if not active or not trackerEnabled() or not g_game.isOnline() then
    tracker:hide()
    return
  end
  local kind = KINDS[active.kind] or KINDS.talk
  tracker:getChildById('header'):setText(kind.text .. '  -  ' .. active.giver)
  tracker:getChildById('title'):setText(active.title)
  tracker:getChildById('progressLabel'):setText(active.progress .. '/' .. active.total)
  tracker:show()
  tracker:raise()
  setProgress(tracker:getChildById('progress'), active.progress, active.total)
end

createTracker = function()
  local mapPanel = modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
  if not mapPanel then return end
  tracker = g_ui.createWidget('TaskTracker', mapPanel)
  tracker:addAnchor(AnchorTop, 'parent', AnchorTop)
  tracker:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  tracker:setMarginTop(8)
  tracker:setMarginLeft(8)
  -- el clic se queda en el recuadro: sin esto la pulsacion pasaba al mapa y el jugador andaba hasta ahi
  tracker.onMousePress = function(self, mousePos, mouseButton) return true end
  tracker.onMouseRelease = function(self, mousePos, mouseButton)
    if mouseButton == MouseLeftButton and self:containsPoint(mousePos) then
      show()
    end
    return true
  end
  tracker:setTooltip('Clic: abrir las tareas')
  tracker:hide()
end

-- ===================== Ventana =====================
-- La tarjeta crece con el texto (antes tenia altura fija y las descripciones largas se cortaban
-- y se montaban con la recompensa). Los alto se miden cuando el ancho ya se conoce.
local function fitCard(card, task)
  if card:isDestroyed() then return end
  local text, reward = card:getChildById('text'), card:getChildById('reward')
  text:setText(task.text)
  reward:setText(task.reward ~= '' and ('Recompensa: ' .. task.reward) or '')
  local textHeight = math.max(18, text:getTextSize().height + 4)
  local rewardHeight = math.max(18, reward:getTextSize().height + 2)
  text:setHeight(textHeight)
  reward:setHeight(rewardHeight)
  -- 66 de cabecera y titulo, 8 de separacion, recompensa (o boton del mapa) y 28 de la barra
  card:setHeight(66 + textHeight + 8 + math.max(rewardHeight + 6, 24) + 28)
end

local function render()
  local list = child('taskList')
  list:destroyChildren()

  -- activas primero, despues las hechas (la ultima hecha arriba)
  local ordered = {}
  for _, task in ipairs(tasks) do
    if task.state == 1 and not task.optional then ordered[#ordered + 1] = task end
  end
  for _, task in ipairs(tasks) do
    if task.state == 1 and task.optional then ordered[#ordered + 1] = task end
  end
  for i = #tasks, 1, -1 do
    if tasks[i].state == 2 then ordered[#ordered + 1] = tasks[i] end
  end

  for _, task in ipairs(ordered) do
    local card = g_ui.createWidget('TaskCard', list)
    local kind = KINDS[task.kind] or KINDS.talk
    local done = task.state == 2
    setChip(card:getChildById('kind'), kind.text, done and '#3a3f47' or kind.color)
    card:getChildById('giver'):setText(task.giver)
    local status = card:getChildById('status')
    status:setText(done and 'Completada' or (task.optional and 'Opcional' or 'En curso'))
    status:setColor(done and '#43a047' or (task.optional and '#8fa7ff' or '#f2c14e'))
    card:getChildById('title'):setText(task.title)
    card:getChildById('title'):setColor(done and '#8b95a5' or '#ffffff')
    card:getChildById('text'):setText(task.text)
    card:getChildById('reward'):setText(task.reward ~= '' and ('Recompensa: ' .. task.reward) or '')
    card:getChildById('progressLabel'):setText(task.progress .. '/' .. task.total)
    local mapButton = card:getChildById('mapButton')
    mapButton:setVisible(not done and #task.mapPoints > 0)
    mapButton.onClick = function() showTaskOnMap(task) end
    card:setBorderColor(done and '#2c3039' or kind.color)
    card:setOpacity(done and 0.7 or 1.0)
    -- el ancho de la barra se conoce despues del layout
    local bar = card:getChildById('progress')
    local current, total = task.progress, task.total
    scheduleEvent(function() if not bar:isDestroyed() then setProgress(bar, current, total) end end, 1)
    fitCard(card, task)
    scheduleEvent(function() fitCard(card, task) end, 10)
  end

  child('emptyLabel'):setVisible(#ordered == 0)

  local capChip = child('capChip')
  if capInfo and capInfo.level > 0 then
    setChip(capChip, 'Nivel max. ' .. capInfo.level, '#c62828')
    capChip:setTooltip(capInfo.text)
    capChip:show()
  else
    capChip:hide()
  end
end

function onTasksOpcode(protocol, opcode, buffer)
  tasks = {}
  capInfo = nil
  for _, line in ipairs(split(buffer or '', '\n')) do
    local f = split(line, '|')
    if f[1] == 'cap' then
      capInfo = {level = tonumber(f[2]) or 0, text = f[3] or ''}
    elseif #f >= 9 then
      tasks[#tasks + 1] = {
        index = tonumber(f[1]) or 0, state = tonumber(f[2]) or 1, kind = f[3], giver = f[4],
        title = f[5], text = f[6], progress = tonumber(f[7]) or 0, total = tonumber(f[8]) or 1, reward = f[9],
        mapPoints = parseMapPoints(f[10]), mapIcon = f[11] or '', optional = f[12] == '1',
      }
    end
  end
  if tasksButton then tasksButton:show() end
  if window:isVisible() then render() end
  updateTracker()
  -- las marcas de las tareas activas salen siempre en el mapa, sin tener que darle a "Ver en el mapa"
  local minimap = modules.game_minimap
  if minimap and minimap.setTaskMarkers then
    local list = {}
    for _, task in ipairs(tasks) do
      if task.state == 1 and #task.mapPoints > 0 then
        list[#list + 1] = { points = task.mapPoints, title = task.title, icon = mapIconFor(task.mapIcon) }
      end
    end
    minimap.setTaskMarkers(list)
  end
end

function show()
  if not g_game.isOnline() then return end
  render()
  window:show()
  window:raise()
  window:focus()
  tasksButton:setOn(true)
end

function hide()
  window:hide()
  tasksButton:setOn(false)
end

function toggle()
  if window:isVisible() then hide() else show() end
end

-- ===================== Mision completada (opcode 92) =====================
-- El servidor (progressionSendTaskDone) manda: titulo|recompensa|tipo|quien|titulo|texto|aspecto|mapa
-- de la mision hecha y la siguiente. Si llegan varias seguidas se ensenan en cola.
local OPCODE_TASK_DONE = 92
local doneWindow = nil
local doneQueue = {}
local fadeEvent = nil

local function fadeIn(widget)
  if fadeEvent then removeEvent(fadeEvent) fadeEvent = nil end
  local step = 0
  local function tick()
    step = step + 1
    widget:setOpacity(math.min(1, step / 8))
    if step < 8 then fadeEvent = scheduleEvent(tick, 25) else fadeEvent = nil end
  end
  widget:setOpacity(0)
  tick()
end

local function activeTask()
  local found
  for _, task in ipairs(tasks) do
    if task.state == 1 and (not found or (found.optional and not task.optional)) then
      found = task
    end
  end
  return found
end

local function createDoneWindow()
  doneWindow = g_ui.createWidget('TaskDoneWindow', rootWidget)
  doneWindow:hide()
  doneWindow:getChildById('continueButton').onClick = function() showNextDone() end
  doneWindow:getChildById('mapButton').onClick = function()
    doneQueue = {}
    doneWindow:hide()
    local task = activeTask()
    if task then showTaskOnMap(task) end
  end
  doneWindow.onKeyPress = function(widget, keyCode)
    if keyCode == KeyEscape or keyCode == KeyEnter then
      showNextDone()
      return true
    end
    return false
  end
end

local DONE_HEIGHT = 360

local function fitDoneWindow()
  if not doneWindow or doneWindow:isDestroyed() then return end
  local text = doneWindow:getChildById('nextText')
  if not text:isVisible() then return end
  local missing = text:getTextSize().height + 6 - text:getHeight()
  if missing > 0 then
    doneWindow:setHeight(doneWindow:getHeight() + missing)
  end
end

function showNextDone()
  local d = table.remove(doneQueue, 1)
  if not d then
    if doneWindow then doneWindow:hide() end
    return
  end
  if not doneWindow then createDoneWindow() end
  local w = doneWindow
  w:getChildById('doneHeader'):setText('\161MISI\211N COMPLETADA!')
  w:getChildById('doneTitle'):setText(d.title)
  w:getChildById('doneReward'):setText(d.reward ~= '' and ('Recompensa: ' .. d.reward) or '')
  local hasNext = d.nextTitle ~= ''
  w:getChildById('nextOptional'):hide()
  for _, id in ipairs({'separator', 'nextHeader', 'giver', 'nextKind', 'nextGiver', 'nextTitle', 'nextText'}) do
    w:getChildById(id):setVisible(hasNext)
  end
  w:getChildById('mapButton'):setVisible(hasNext and d.hasMap)
  if hasNext then
    w:getChildById('nextHeader'):setText('SIGUIENTE MISI\211N')
    local kind = KINDS[d.kind] or KINDS.talk
    setChip(w:getChildById('nextKind'), kind.text, kind.color)
    w:getChildById('nextGiver'):setText(d.giver)
    w:getChildById('nextTitle'):setText(d.nextTitle)
    w:getChildById('nextText'):setText(d.nextText)
    local optionalLabel = w:getChildById('nextOptional')
    optionalLabel:setText(d.optional ~= '' and ('Opcional - ' .. d.optional) or '')
    optionalLabel:setVisible(d.optional ~= '')
    local giver = w:getChildById('giver')
    if d.look ~= '' then
      local look = split(d.look, ',')
      giver:setOutfit({ type = tonumber(look[1]) or 0, head = tonumber(look[2]) or 0, body = tonumber(look[3]) or 0,
        legs = tonumber(look[4]) or 0, feet = tonumber(look[5]) or 0 })
    else
      giver:hide()
    end
  end
  w:getChildById('continueButton'):setText(#doneQueue > 0 and 'Siguiente' or 'Continuar')
  w:setHeight(DONE_HEIGHT)
  w:show()
  w:raise()
  w:focus()
  fadeIn(w)
  scheduleEvent(fitDoneWindow, 10)
end

function onTaskDoneOpcode(protocol, opcode, buffer)
  local f = split(buffer or '', '|')
  table.insert(doneQueue, { title = f[1] or '', reward = f[2] or '', kind = f[3] or '', giver = f[4] or '',
    nextTitle = f[5] or '', nextText = f[6] or '', look = f[7] or '', hasMap = f[8] == '1', optional = f[9] or '' })
  if not doneWindow or not doneWindow:isVisible() then
    showNextDone()
  end
end

function onGameEnd()
  hide()
  tasks = {}
  capInfo = nil
  if tracker then tracker:hide() end
  doneQueue = {}
  if doneWindow then doneWindow:hide() end
end

function init()
  window = g_ui.displayUI('tasks')
  window:hide()

  tasksButton = modules.client_topmenu.addRightGameToggleButton('tasksButton', 'Tareas',
    '/images/topmenu/questlog', toggle)
  tasksButton:setOn(false)

  local check = child('trackerCheck')
  check:setChecked(trackerEnabled())
  check.onCheckChange = function(widget, checked)
    g_settings.set('tasksTracker', checked and 'true' or 'false')
    updateTracker()
  end

  createTracker()
  ProtocolGame.registerExtendedOpcode(OPCODE_TASKS, onTasksOpcode)
  ProtocolGame.registerExtendedOpcode(OPCODE_TASK_DONE, onTaskDoneOpcode)
  connect(g_game, { onGameEnd = onGameEnd })
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_TASKS)
  ProtocolGame.unregisterExtendedOpcode(OPCODE_TASK_DONE)
  if fadeEvent then removeEvent(fadeEvent) fadeEvent = nil end
  if doneWindow then doneWindow:destroy() doneWindow = nil end
  disconnect(g_game, { onGameEnd = onGameEnd })
  if tracker then tracker:destroy() tracker = nil end
  window:destroy()
  tasksButton:destroy()
end
