-- Vida, resistencia y nivel del entrenador alrededor de la barra de objetos (diseno "orbes"):
-- anillo de vida a la izquierda, anillo de nivel/experiencia a la derecha y la resistencia
-- como linea fina encima (solo si no esta llena). Sustituyen a las ventanas "Entrenador" y "Vida" del panel derecho.
-- El boton "Estado del entrenador" de arriba lo muestra u oculta.

local MAX_STAMINA = 42 * 60 -- minutos
local ORB = 84             -- tamano de cada anillo en /images/statusbar/ring (10 por fila)

local healthOrb, levelOrb, staminaLine
local visible = true -- se puede ocultar con el boton "Estado del entrenador" de arriba
local staminaFull = true -- con la stamina llena la linea no se ve (no aporta nada)

local function healthColor(percent)
  if percent > 50 then
    return '#3fbf5a'
  elseif percent > 20 then
    return '#e0ad35'
  end
  return '#e0483f'
end

-- elige el anillo del porcentaje (recorte de la hoja) y lo tine
local function setRing(orb, percent, color)
  percent = math.max(0, math.min(100, math.floor(percent)))
  local ring = orb:getChildById('ring')
  ring:setImageClip({ x = (percent % 10) * ORB, y = math.floor(percent / 10) * ORB, width = ORB, height = ORB })
  ring:setImageColor(color)
end

function onHealthChange(player, health, maxHealth)
  local percent = maxHealth > 0 and math.floor(health * 100 / maxHealth) or 0
  setRing(healthOrb, percent, healthColor(percent))
  healthOrb:getChildById('value'):setText(percent .. '%')
  healthOrb:getChildById('sub'):setText(tostring(health))
  healthOrb:setTooltip('Vida: ' .. health .. ' / ' .. maxHealth)
end

function onStaminaChange(player, stamina)
  staminaFull = stamina >= MAX_STAMINA
  staminaLine:setVisible(visible and g_game.isOnline() and not staminaFull)
  staminaLine:getChildById('staminaBar'):setPercent(math.min(100, math.floor(stamina * 100 / MAX_STAMINA)))
  staminaLine:getChildById('staminaValue'):setText(string.format('%d:%02d', math.floor(stamina / 60), stamina % 60))
end

function onLevelChange(player, level, percent)
  setRing(levelOrb, percent, '#e0a93a')
  levelOrb:getChildById('value'):setText('NV ' .. level)
  levelOrb:getChildById('sub'):setText(percent .. '%')
end

function onExperienceChange(player, experience)
  levelOrb:setTooltip('Experiencia: ' .. experience)
end

local function setAllVisible(show)
  healthOrb:setVisible(show)
  levelOrb:setVisible(show)
  staminaLine:setVisible(show and not staminaFull)
end

local function refresh()
  local player = g_game.getLocalPlayer()
  if not player then return end
  onHealthChange(player, player:getHealth(), player:getMaxHealth())
  onStaminaChange(player, player:getStamina())
  onLevelChange(player, player:getLevel(), player:getLevelPercent())
  onExperienceChange(player, player:getExperience())
  setAllVisible(visible)
end

-- lo llama el boton "Estado del entrenador" (game_skills); devuelve si queda visible
function toggleVisible()
  visible = not visible
  g_settings.set('statusbar_hidden', not visible)
  if g_game.isOnline() then
    setAllVisible(visible)
  end
  return visible
end

local function syncButton()
  local button = modules.game_skills and modules.game_skills.skillsButton
  if button then
    button:setOn(visible)
  end
end

local function onGameEnd()
  setAllVisible(false)
end

-- Una sola vez: cerrar la ventana "Vida" del panel derecho, que repite lo que ya sale aqui.
-- Se puede volver a abrir con su boton de arriba. ("Entrenador" la cierra siempre game_skills.)
local function closeOldWindows()
  if g_settings.getBoolean('statusbar_oldWindowsClosed') then return end
  local healthInfo = modules.game_healthinfo and modules.game_healthinfo.healthInfoWindow
  if healthInfo then healthInfo:close() end
  g_settings.set('statusbar_oldWindowsClosed', true)
end

function init()
  g_ui.importStyle('statusbar')
  -- en el mismo panel que la barra de objetos, para poder anclarlos a ella
  local mapPanel = modules.game_interface.getMapPanel()

  healthOrb = g_ui.createWidget('StatusOrb', mapPanel)
  healthOrb:setId('healthOrb')
  healthOrb:addAnchor(AnchorRight, 'inventoryWindow', AnchorLeft)
  healthOrb:addAnchor(AnchorBottom, 'inventoryWindow', AnchorBottom)
  healthOrb:setMarginRight(10)
  healthOrb:getChildById('icon'):setImageSource('/images/statusbar/heart_big')

  levelOrb = g_ui.createWidget('StatusOrb', mapPanel)
  levelOrb:setId('levelOrb')
  levelOrb:addAnchor(AnchorLeft, 'inventoryWindow', AnchorRight)
  levelOrb:addAnchor(AnchorBottom, 'inventoryWindow', AnchorBottom)
  levelOrb:setMarginLeft(10)
  levelOrb:getChildById('icon'):setImageSource('/images/statusbar/star_big')

  staminaLine = g_ui.createWidget('StaminaLine', mapPanel)
  staminaLine:setId('staminaLine')
  staminaLine:addAnchor(AnchorLeft, 'inventoryWindow', AnchorLeft)
  staminaLine:addAnchor(AnchorRight, 'inventoryWindow', AnchorRight)
  staminaLine:addAnchor(AnchorBottom, 'inventoryWindow', AnchorTop)
  staminaLine:setMarginLeft(10)
  staminaLine:setMarginRight(10)
  staminaLine:setMarginBottom(4)

  setAllVisible(false)
  visible = not g_settings.getBoolean('statusbar_hidden')
  connect(LocalPlayer, {
    onHealthChange = onHealthChange,
    onStaminaChange = onStaminaChange,
    onLevelChange = onLevelChange,
    onExperienceChange = onExperienceChange,
  })
  connect(g_game, { onGameStart = refresh, onGameEnd = onGameEnd })
  closeOldWindows()
  syncButton()
  if g_game.isOnline() then
    refresh()
  end
end

function terminate()
  disconnect(LocalPlayer, {
    onHealthChange = onHealthChange,
    onStaminaChange = onStaminaChange,
    onLevelChange = onLevelChange,
    onExperienceChange = onExperienceChange,
  })
  disconnect(g_game, { onGameStart = refresh, onGameEnd = onGameEnd })
  healthOrb:destroy()
  levelOrb:destroy()
  staminaLine:destroy()
end
