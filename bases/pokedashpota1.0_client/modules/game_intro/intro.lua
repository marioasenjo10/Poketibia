-- Escena inicial del Profesor Oak (sustituye a las ventanas modales de la intro).
-- El servidor manda por el opcode 91 (data/lib/core/progression.lua):
--   show|textoBienvenida|textoAventura|nombre;tipos;texto|nombre;tipos;texto...
--   done|nombre|textoDespedida
-- y el cliente contesta con el comando oculto "progressionintro elegir <n>" / "progressionintro aspecto".
-- Las ilustraciones son las de la Pokedex (/game_pokedex/artwork/<nombre>.png).

local OPCODE_INTRO = 91

local TYPE_COLORS = {
  Planta = '#43a047', Veneno = '#8e24aa', Fuego = '#e53935', Agua = '#1e88e5',
  Electrico = '#f9a825', Normal = '#8d8d8d', Volador = '#5c9ded', Bicho = '#7cb342',
  Roca = '#a1887f', Tierra = '#c49a52', Lucha = '#c62828', Psiquico = '#ec407a',
}

overlay = nil

local welcomeText, adventureText = '', ''
local starters = {}
local selected = nil
local page = nil
local doneName, doneText = nil, nil
local enterAction = nil

local function child(id)
  return overlay:recursiveGetChildById(id)
end

local function split(text, sep)
  local parts = {}
  for part in (text .. sep):gmatch('(.-)' .. sep:gsub('%p', '%%%0')) do
    parts[#parts + 1] = part
  end
  return parts
end

local function artworkFor(name)
  if not name or name == '' then return nil end
  local path = '/game_pokedex/artwork/' .. name:lower() .. '.png'
  if g_resources.fileExists(path) then return path end
  return nil
end

local function setArt(widget, name)
  local path = artworkFor(name)
  if path then
    widget:setImageSource(path)
    widget:show()
  else
    widget:hide()
  end
end

local function addTypeChips(parent, types)
  parent:destroyChildren()
  for _, t in ipairs(split(types or '', '/')) do
    local chip = g_ui.createWidget('IntroTypeChip', parent)
    chip:setText(t)
    chip:setWidth(chip:getTextSize().width + 18)
    chip:setImageColor(TYPE_COLORS[t] or '#3a3f47')
  end
end

local function setButtons(primaryText, primaryAction, secondaryText, secondaryAction)
  local primary = child('primaryButton')
  local secondary = child('secondaryButton')
  primary:setText(primaryText)
  primary.onClick = primaryAction
  primary:setEnabled(primaryAction ~= nil)
  if secondaryText then
    secondary:setText(secondaryText)
    secondary.onClick = secondaryAction
    secondary:show()
  else
    secondary:hide()
  end
  enterAction = primaryAction
end

local showPage

local function buildTeaser()
  local teaser = child('teaser')
  teaser:destroyChildren()
  for _, starter in ipairs(starters) do
    local art = g_ui.createWidget('UIWidget', teaser)
    art:setSize({ width = 140, height = 140 })
    art:setImageSmooth(true)
    art:setPhantom(true)
    setArt(art, starter.name)
  end
end

local function selectCard(index)
  selected = index
  for i, card in ipairs(child('cards'):getChildren()) do
    if i == index then
      card:setBorderColor('#f2c14e')
      card:setBackgroundColor('#2a2f3a')
    else
      card:setBorderColor('#2c3039')
      card:setBackgroundColor('#1b1e24')
    end
  end
  setButtons('Elegir a ' .. starters[index].name, function() showPage('confirm') end)
end

local function buildCards()
  local cards = child('cards')
  cards:destroyChildren()
  for i, starter in ipairs(starters) do
    local card = g_ui.createWidget('StarterCard', cards)
    setArt(card:getChildById('art'), starter.name)
    card:getChildById('name'):setText(starter.name)
    addTypeChips(card:getChildById('chips'), starter.types)
    card:getChildById('text'):setText(starter.text)
    card.onClick = function() selectCard(i) end
    card.onDoubleClick = function() selectCard(i) showPage('confirm') end
  end
end

showPage = function(name)
  page = name
  local teaser, cards, bigArt, message = child('teaser'), child('cards'), child('bigArt'), child('message')
  teaser:hide() cards:hide() bigArt:hide() message:show()
  message:setHeight(120)

  if name == 'welcome' then
    child('stepLabel'):setText('1 / 3')
    teaser:show()
    message:setText(welcomeText)
    setButtons('Continuar', function() showPage('adventure') end)
  elseif name == 'adventure' then
    child('stepLabel'):setText('2 / 3')
    teaser:show()
    message:setText(adventureText)
    setButtons('Elegir Pokemon', function() showPage('choose') end, 'Volver', function() showPage('welcome') end)
  elseif name == 'choose' then
    child('stepLabel'):setText('3 / 3')
    cards:show()
    message:setHeight(40)
    message:setText('Cual sera tu primer Pokemon? Haz clic en una tarjeta para elegirlo.')
    if selected then
      selectCard(selected)
    else
      setButtons('Elige un Pokemon', nil)
    end
  elseif name == 'confirm' then
    local starter = starters[selected]
    if not starter then return showPage('choose') end
    bigArt:show()
    setArt(bigArt, starter.name)
    message:setHeight(90)
    message:setText('Asi que eliges a ' .. starter.name .. ', de tipo ' .. starter.types .. '.\n' .. starter.text ..
      '\n\nSeguro que quieres a ' .. starter.name .. '?')
    setButtons('Si, lo quiero', function()
      setButtons('...', nil)
      g_game.talk('progressionintro elegir ' .. selected)
    end, 'Mejor otro', function() showPage('choose') end)
  elseif name == 'done' then
    child('stepLabel'):setText('')
    bigArt:show()
    setArt(bigArt, doneName)
    message:setHeight(120)
    message:setText(doneText or '')
    setButtons('Elegir mi aspecto', function()
      g_game.talk('progressionintro aspecto')
      hide()
    end)
  end
end

local function open()
  if not overlay then return end
  overlay:show()
  overlay:raise()
  overlay:focus()
end

function hide()
  if overlay then overlay:hide() end
end

function onIntroOpcode(protocol, opcode, buffer)
  local parts = split(buffer or '', '|')
  if parts[1] == 'show' then
    welcomeText, adventureText = parts[2] or '', parts[3] or ''
    starters = {}
    for i = 4, #parts do
      local f = split(parts[i], ';')
      starters[#starters + 1] = { name = f[1], types = f[2] or '', text = f[3] or '' }
    end
    selected = nil
    buildTeaser()
    buildCards()
    open()
    showPage('welcome')
  elseif parts[1] == 'done' then
    doneName, doneText = parts[2], parts[3]
    open()
    showPage('done')
  end
end

function init()
  overlay = g_ui.displayUI('intro')
  overlay:hide()
  -- Enter = boton principal; Escape cierra (se vuelve a abrir hablando con el Profesor Oak)
  overlay.onKeyDown = function(widget, keyCode, keyboardModifiers)
    if keyCode == KeyEscape then
      if page ~= 'done' then hide() end
      return true
    elseif keyCode == KeyEnter or keyCode == KeyReturn then
      if enterAction then enterAction() end
      return true
    end
    return false
  end
  ProtocolGame.registerExtendedOpcode(OPCODE_INTRO, onIntroOpcode)
  connect(g_game, { onGameEnd = hide })
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_INTRO)
  disconnect(g_game, { onGameEnd = hide })
  if overlay then overlay:destroy() overlay = nil end
end
