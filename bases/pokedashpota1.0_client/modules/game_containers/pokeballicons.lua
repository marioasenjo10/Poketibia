-- Iconos de pokemon en las pokeballs de las mochilas (estilo PKA): encima de cada pokeball
-- se dibuja la ilustracion de su pokemon y la pokeball pequena en la esquina.
-- El cliente no sabe que pokemon lleva cada ball; lo manda el servidor (opcode 72,
-- creaturescripts/scripts/pokeballicons.lua) cuando cambia algo en las mochilas abiertas:
--   "idContenedor:casilla:idObjeto:nombre:debilitado;..."

local OPCODE_BALL_ICONS = 72
local ICON_ID = 'pokeIcon'

local entries = {} -- [cid] = { [casilla] = {itemId, name, fainted} }
-- lo ultimo que se supo de cada mochila por su nombre (p. ej. "trainer belt"): al volver a
-- abrirla se pinta al momento, sin esperar al servidor (que mira las mochilas cada segundo)
local lastByName = {}

local function iconPath(name)
  local lower = name:lower()
  local artwork = '/game_pokedex/artwork/' .. lower .. '.png'
  if g_resources.fileExists(artwork) then return artwork end
  local icon = '/game_pokemonbar/bar_icon/' .. lower .. '.png'
  if g_resources.fileExists(icon) then return icon end
  return nil
end

local function clearIcon(itemWidget)
  local icon = itemWidget:getChildById(ICON_ID)
  if icon then icon:destroy() end
end

local function setIcon(itemWidget, entry)
  clearIcon(itemWidget)
  local path = iconPath(entry.name)
  if not path then return end
  local icon = g_ui.createWidget('PokeballIcon', itemWidget)
  icon:setId(ICON_ID)
  icon:getChildById('pokemon'):setImageSource(path)
  icon:getChildById('ball'):setItemId(entry.itemId)
  if entry.fainted then
    icon:getChildById('pokemon'):setImageColor('#ffffff55')
  end
  itemWidget:setTooltip(entry.name .. (entry.fainted and ' (debilitado)' or ''))
end

-- vuelve a pintar los iconos de una mochila abierta
function refreshPokeballIcons(container)
  if not container or not container.itemsPanel then return end
  local list = entries[container:getId()]
  if not list then
    list = lastByName[container:getName():lower()] or {}
  end
  local first = container:getFirstIndex()
  for _, itemWidget in ipairs(container.itemsPanel:getChildren()) do
    local slot = tonumber((itemWidget:getId() or ''):match('^item(%d+)$'))
    if slot then
      local entry = list[slot + first]
      local item = itemWidget:getItem()
      if entry and item and item:getId() == entry.itemId then
        setIcon(itemWidget, entry)
      else
        clearIcon(itemWidget)
        if itemWidget:getTooltip() and itemWidget.pokeTooltip then
          itemWidget:setTooltip(nil)
        end
      end
      itemWidget.pokeTooltip = entry ~= nil
    end
  end
end

-- al cerrar una mochila se olvida lo de su id (el siguiente contenedor puede reutilizarlo);
-- lo recordado por nombre se queda para volver a abrirla al instante
function forgetPokeballIcons(container)
  entries[container:getId()] = nil
end

local function refreshAll()
  for _, container in pairs(g_game.getContainers()) do
    refreshPokeballIcons(container)
  end
end

local function onBallIcons(protocol, opcode, buffer)
  entries = {}
  for part in string.gmatch(buffer, '([^;]+)') do
    local cid, slot, itemId, name, fainted = part:match('^(%d+):(%d+):(%d+):([^:]+):(%d)$')
    if cid then
      cid = tonumber(cid)
      entries[cid] = entries[cid] or {}
      entries[cid][tonumber(slot)] = { itemId = tonumber(itemId), name = name, fainted = fainted == '1' }
    end
  end
  -- recordar por nombre lo de cada mochila abierta (tambien las que se han quedado sin pokeballs)
  for _, container in pairs(g_game.getContainers()) do
    lastByName[container:getName():lower()] = entries[container:getId()] or {}
  end
  refreshAll()
end

function initPokeballIcons()
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_BALL_ICONS)
  ProtocolGame.registerExtendedOpcode(OPCODE_BALL_ICONS, onBallIcons)
end

function terminatePokeballIcons()
  pcall(ProtocolGame.unregisterExtendedOpcode, OPCODE_BALL_ICONS)
  entries = {}
end
