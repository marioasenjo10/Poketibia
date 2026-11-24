-- Panel de Tareas (sustituye al quest log) y seguimiento de la tarea activa sobre el mapa.
-- El servidor manda todas las tareas por el opcode 90 (data/lib/core/progression.lua):
--   primera linea: cap|nivel|texto (nivel 0 = sin tope)
--   resto: indice|estado(1 activa, 2 hecha)|tipo|quien|titulo|texto|progreso|total|recompensa
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

-- ===================== Seguimiento sobre el mapa =====================
local createTracker

local function updateTracker()
  if not tracker then createTracker() end
  if not tracker then return end
  local active
  for _, task in ipairs(tasks) do
    if task.state == 1 then
      active = task
      break
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
  tracker.onClick = function() show() end
  tracker:hide()
end

-- ===================== Ventana =====================
local function render()
  local list = child('taskList')
  list:destroyChildren()

  -- activas primero, despues las hechas (la ultima hecha arriba)
  local ordered = {}
  for _, task in ipairs(tasks) do
    if task.state == 1 then ordered[#ordered + 1] = task end
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
    status:setText(done and 'Completada' or 'En curso')
    status:setColor(done and '#43a047' or '#f2c14e')
    card:getChildById('title'):setText(task.title)
    card:getChildById('title'):setColor(done and '#8b95a5' or '#ffffff')
    card:getChildById('text'):setText(task.text)
    card:getChildById('reward'):setText(task.reward ~= '' and ('Recompensa: ' .. task.reward) or '')
    card:getChildById('progressLabel'):setText(task.progress .. '/' .. task.total)
    card:setBorderColor(done and '#2c3039' or kind.color)
    card:setOpacity(done and 0.7 or 1.0)
    -- el ancho de la barra se conoce despues del layout
    local bar = card:getChildById('progress')
    local current, total = task.progress, task.total
    scheduleEvent(function() if not bar:isDestroyed() then setProgress(bar, current, total) end end, 1)
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
      }
    end
  end
  if tasksButton then tasksButton:show() end
  if window:isVisible() then render() end
  updateTracker()
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

function onGameEnd()
  hide()
  tasks = {}
  capInfo = nil
  if tracker then tracker:hide() end
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
  connect(g_game, { onGameEnd = onGameEnd })
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_TASKS)
  disconnect(g_game, { onGameEnd = onGameEnd })
  if tracker then tracker:destroy() tracker = nil end
  window:destroy()
  tasksButton:destroy()
end
