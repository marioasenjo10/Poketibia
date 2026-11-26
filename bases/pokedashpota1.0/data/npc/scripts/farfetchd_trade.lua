-- Intercambio de Ciudad Carmin (como en los juegos): tu Spearow por su Farfetch'd, una sola vez.
-- El Farfetch'd puede volar (flyable en su archivo). Esta en el Centro Pokemon de Ciudad Carmin.
local TRADE_STORAGE = 96050 -- 1 = ya hecho
local WANTED = "Spearow"
local GIVEN = "Farfetch'd"

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

-- la Pokeball de un Spearow del jugador (cinturon o mochila); usingOne = true si el unico esta fuera
local function findSpearow(player)
	local usingOne = false
	for _, ball in ipairs(player:getPokeballs()) do
		local name = ball:getSpecialAttribute("pokeName")
		if name and name:lower() == WANTED:lower() then
			local inUse = ball:getSpecialAttribute("isBeingUsed")
			if inUse and inUse == 1 then
				usingOne = true
			else
				return ball, usingOne
			end
		end
	end
	return nil, usingOne
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)
	if not player then
		return false
	end

	if player:getStorageValue(TRADE_STORAGE) == 1 then
		selfSay("Gracias otra vez por el Spearow! Cuida bien de mi Farfetch'd: vuela de maravilla.", cid)
		npcHandler:releaseFocus(cid)
		return true
	end

	if msgcontains(msg, 'cambias') or msgcontains(msg, 'cambio') or msgcontains(msg, 'trade') or msgcontains(msg, 'farfetch') then
		selfSay("Mi Farfetch'd es un gran Pokemon y puede llevarte volando (dile 'order' sobre ti). Solo lo cambio una vez, por un Spearow. Trato hecho? {si} / {no}", cid)
		npcHandler.topic[cid] = 1
	elseif npcHandler.topic[cid] == 1 and (msgcontains(msg, 'si') or msgcontains(msg, 'yes') or msgcontains(msg, 'sim')) then
		npcHandler.topic[cid] = 0
		local ball, usingOne = findSpearow(player)
		if not ball then
			if usingOne then
				selfSay("Guarda primero a tu Spearow en su Pokeball y vuelve a decirme {cambias}.", cid)
			else
				selfSay("No llevas ningun Spearow. Hay muchos por los caminos de Kanto: captura uno y vuelve.", cid)
			end
			return true
		end
		if not ball:remove() then
			selfSay("Vaya, algo ha fallado. Intentalo otra vez.", cid)
			return true
		end
		player:setStorageValue(TRADE_STORAGE, 1)
		doAddPokeball(player:getId(), GIVEN, 0, "pokeball", false, 0)
		player:refreshPokemonBar({}, {})
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		selfSay("Trato hecho! Aqui tienes a mi Farfetch'd. Puede llevarte volando por todo Kanto. Cuidalo mucho!", cid)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Has cambiado tu Spearow por el Farfetch'd de Ramon. Puede volar!")
		npcHandler:releaseFocus(cid)
	elseif npcHandler.topic[cid] == 1 and (msgcontains(msg, 'no') or msgcontains(msg, 'nao')) then
		npcHandler.topic[cid] = 0
		selfSay("Que pena... Si cambias de idea, aqui estare.", cid)
	elseif msgcontains(msg, 'bye') or msgcontains(msg, 'adios') then
		selfSay("Buen viento!", cid)
		npcHandler:releaseFocus(cid)
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
