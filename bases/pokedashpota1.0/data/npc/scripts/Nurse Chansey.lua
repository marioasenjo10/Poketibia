local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

-- Enfermera Joy: con "hi" ya cura la Chansey de al lado; con click derecho cura ella.
local function creatureGreetCallback(cid, message)
	if message == NPC_CLICK_WORD then
		local player = Player(cid)
		if player then
			npcHealPlayer(player)
		end
	end
	return false
end

npcHandler:setCallback(CALLBACK_GREET, creatureGreetCallback)
npcHandler:addModule(FocusModule:new())
