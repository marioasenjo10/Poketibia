-- Cinturon pokemon: contenedor de 6 casillas en la casilla del pecho (servidor: pokemonBelt),
-- donde solo entran pokeballs. El boton de la barra de arriba lo abre y lo cierra.

local BELT_NAME = 'trainer belt' -- nombre del objeto en items.xml
local BELT_ICON = '/images/topmenu/belt'
local BELT_CELL = 50 -- 3 columnas caben en el ancho de la ventana (3*50 + 2*4)
local BELT_SPACING = 4
local BELT_TITLE = 'Trainer Belt'

local beltButton

function isPokemonBelt(container)
  return container and container:getName():lower() == BELT_NAME
end

local function findOpenBelt()
  for _, container in pairs(g_game.getContainers()) do
    if isPokemonBelt(container) then
      return container
    end
  end
  return nil
end

function toggleBelt()
  if not g_game.isOnline() then return end
  local open = findOpenBelt()
  if open then
    g_game.close(open)
    return
  end
  local player = g_game.getLocalPlayer()
  local item = player and player:getInventoryItem(InventorySlotBody)
  if not item then
    modules.game_textmessage.displayFailureMessage('No llevas el Trainer Belt.')
    return
  end
  g_game.open(item)
end

-- lo llama containers.lua al abrir una mochila: titulo e icono propios para el cinturon
function decoratePokemonBelt(container, containerWindow)
  if not isPokemonBelt(container) then return end
  containerWindow:setText(BELT_TITLE)
  containerWindow:getChildById('containerItemWidget'):hide()
  containerWindow:setIcon(BELT_ICON)
  -- 6 casillas en 3x2, grandes: se ve bien cada pokemon
  local layout = container.itemsPanel:getLayout()
  layout:setCellSize({ width = BELT_CELL, height = BELT_CELL })
  layout:setCellSpacing(BELT_SPACING)
  layout:setNumColumns(3)
  local height = 2 * BELT_CELL + BELT_SPACING + 4
  containerWindow:setContentMinimumHeight(height)
  containerWindow:setContentMaximumHeight(height)
  containerWindow:setContentHeight(height)
  if beltButton then beltButton:setOn(true) end
end

function onPokemonBeltClose(container)
  if isPokemonBelt(container) and beltButton then
    beltButton:setOn(false)
  end
end

function initPokemonBelt()
  beltButton = modules.client_topmenu.addRightGameToggleButton('pokemonBeltButton', BELT_TITLE, BELT_ICON, toggleBelt)
  beltButton:setOn(findOpenBelt() ~= nil)
end

function terminatePokemonBelt()
  if beltButton then
    beltButton:destroy()
    beltButton = nil
  end
end
