-- Portero de la Liga Pokemon (Meseta Anil). Pide las 8 medallas de Kanto y el nivel de la quest
-- indigoLeague (lib/core/newfunctions.lua), y deja intentarlo una vez cada leagueCooldownHours.
-- Dentro: 25 pociones y 5 revivir por intento (Player:canUsePotionOnLeague / canUseReviveOnLeague).
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local leagueCooldownHours = 20
local leagueEntrance = Position(254, 1071, 7) -- sala de Lorelei

local function missingBadges(player)
	local missing = {}
	for _, gym in ipairs(progressionGyms or {}) do
		local quest = quests[gym.badge]
		if gym.badge ~= "indigoLeague" and quest and player:getStorageValue(quest.prizes[1].uid) <= 0 then
			missing[#missing + 1] = gym.medal
		end
	end
	return missing
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)
	if not player then
		return false
	end

	if (msgcontains(msg, "si") or msgcontains(msg, "yes") or msgcontains(msg, "liga")) and npcHandler.topic[cid] == 0 then
		if player:getStorageValue(quests.indigoLeague.prizes[1].uid) > 0 then
			npcHandler:say("Ya eres el Campeon de la Liga! Tu nombre esta en el Salon de la Fama.", cid)
			npcHandler:releaseFocus(cid)
			return true
		end
		local missing = missingBadges(player)
		if #missing > 0 then
			npcHandler:say("Para entrar en la Liga necesitas las 8 medallas de Kanto. Te faltan " .. #missing ..
				": " .. table.concat(missing, ", ") .. ".", cid)
			npcHandler:releaseFocus(cid)
		elseif player:getLevel() < quests.indigoLeague.level then
			npcHandler:say("Tienes las 8 medallas, pero el Alto Mando es muy duro: necesitas al menos nivel " ..
				quests.indigoLeague.level .. ". Entrena en la Calle Victoria.", cid)
			npcHandler:releaseFocus(cid)
		else
			npcHandler:say("Seguro que estas preparado? Lucharas contra los cuatro del Alto Mando y el campeon, uno tras otro, " ..
				"con solo 25 pociones y 5 revivir. Si pierdes, tendras que esperar " .. leagueCooldownHours ..
				" horas para volver a intentarlo. {si} / {no}", cid)
			npcHandler.topic[cid] = 1
		end
	elseif (msgcontains(msg, "si") or msgcontains(msg, "yes")) and npcHandler.topic[cid] == 1 then
		local last = math.max(0, player:getStorageValue(storageLeagueTime))
		local remaining = leagueCooldownHours * 3600 - (os.time() - last)
		if remaining <= 0 then
			npcHandler:say("Buena suerte, " .. player:getName() .. "!", cid)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:teleportTo(leagueEntrance)
			leagueEntrance:sendMagicEffect(CONST_ME_TELEPORT)
			player:setOnLeague()
		else
			local hours = math.floor(remaining / 3600)
			local minutes = math.ceil((remaining % 3600) / 60)
			npcHandler:say("Aun tienes que descansar. Vuelve dentro de " .. hours .. " h y " .. minutes .. " min.", cid)
		end
		npcHandler:releaseFocus(cid)
	elseif msgcontains(msg, "no") then
		npcHandler:say("Vuelve cuando estes decidido.", cid)
		npcHandler:releaseFocus(cid)
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Hola, |PLAYERNAME|. Bienvenido a la Meseta Anil. Puedo llevarte a la {liga} Pokemon: el Alto Mando y el campeon te esperan. Quieres intentarlo?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Vuelve cuando estes decidido.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Vuelve cuando estes decidido.")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
