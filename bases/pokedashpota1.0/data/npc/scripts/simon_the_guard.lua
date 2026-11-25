-- Simon, guardia de la Calle Victoria (al oeste de Ciudad Verde). Deja pasar a quien tenga las
-- 8 medallas de Kanto. Ya no hay limite diario: el intento semanal es el de la Liga (portero).
local victoryRoad = Position(537, 1095, 7)

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

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
	if msgcontains(msg, 'pasar') or msgcontains(msg, 'si') or msgcontains(msg, 'yes') or msgcontains(msg, 'entrar') then
		local missing = missingBadges(player)
		if #missing > 0 then
			npcHandler:say("Solo dejo pasar a quien tiene las 8 medallas de Kanto. Te faltan " .. #missing .. ": " ..
				table.concat(missing, ", ") .. ".", cid)
		else
			npcHandler:say("Adelante, y buena suerte. Al final de la Calle Victoria esta la Meseta Anil.", cid)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:teleportTo(victoryRoad)
			victoryRoad:sendMagicEffect(CONST_ME_TELEPORT)
		end
		npcHandler:releaseFocus(cid)
	elseif msgcontains(msg, 'no') or msgcontains(msg, 'adios') or msgcontains(msg, 'bye') then
		npcHandler:say("Vuelve cuando tengas las 8 medallas.", cid)
		npcHandler:releaseFocus(cid)
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
