-- Lorelei, del Alto Mando (tipo Hielo) de la Liga Pokemon (combate 1 de 5). Script generado con la misma plantilla
-- para todo el Alto Mando y el campeon: solo cambian el equipo, los textos y a donde se pasa al ganar.
-- level: nivel de fuerza | hp: multiplicador de vida | damage: multiplicador de dano.
-- El ultimo (el "as") es shiny: +25% a todas sus estadisticas (shinyStatMultiplier).
local exitPosition = Position(264, 1074, 7)   -- fuera de la Liga, junto al portero
local nextPosition = Position(239, 1071, 7) -- sala de Bruno
local isChampion = false
local pokemons =
{
	[1] = {name = "Dewgong", level = 92, hp = 3, damage = 1.6},
	[2] = {name = "Cloyster", level = 92, hp = 3, damage = 1.6},
	[3] = {name = "Slowbro", level = 93, hp = 3, damage = 1.6},
	[4] = {name = "Jynx", level = 93, hp = 3, damage = 1.6},
	[5] = {name = "Shiny Lapras", level = 94, hp = 3.5, damage = 1.7},
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

-- teletransporte a la sala siguiente (si la casilla exacta esta ocupada, prueba las de al lado)
local function teleportNear(player, position)
	for offset = 0, 4 do
		for _, dx in ipairs(offset == 0 and {0} or {-offset, offset}) do
			local pos = Position(position.x + dx, position.y, position.z)
			local tile = Tile(pos)
			if tile and tile:getGround() and tile:queryAdd(player) == RETURNVALUE_NOERROR then
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				player:teleportTo(pos)
				pos:sendMagicEffect(CONST_ME_TELEPORT)
				return true
			end
		end
	end
	player:teleportTo(position, true)
	return false
end

local function leaveLeague(player)
	player:setOutLeague()
	teleportNear(player, exitPosition)
end

local function creatureGreetCallback(cid, message)
	if message == nil then
		return true
	end
	if npcHandler:hasFocus() then
		selfSay("Espera tu turno, " .. Player(cid):getName() .. "!")
		return false
	end
	return true
end

local function sendToExit(cid)
	local player = Player(cid)
	selfSay("Mas suerte la proxima vez, " .. player:getName() .. ". Tendras que empezar la Liga desde el principio.", cid)
	npcHandler:releaseFocus(cid)
	leaveLeague(player)
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)
	if not player then
		return false
	end
	if msgcontains(msg, 'rendir') or msgcontains(msg, 'desistir') or msgcontains(msg, 'salir') or msgcontains(msg, 'leave') then
		selfSay('Vuelve cuando estes preparado.', cid)
		npcHandler:releaseFocus(cid)
		leaveLeague(player)
	elseif msgcontains(msg, 'bye') or msgcontains(msg, 'adios') or msgcontains(msg, 'no') then
		selfSay('Te espero. Recuerda que siempre puedes {rendirte} y salir de la Liga.', cid)
		npcHandler:releaseFocus(cid)
	elseif msgcontains(msg, 'yes') or msgcontains(msg, 'si') then
		if not player:isOnLeague() then
			selfSay('No estas participando en la Liga. Habla con el portero de la entrada.', cid)
			npcHandler:releaseFocus(cid)
		elseif isChampion and player:getStorageValue(quests.indigoLeague.prizes[1].uid) > 0 then
			selfSay('Ya eres el campeon. No hay nada que demostrar.', cid)
			npcHandler:releaseFocus(cid)
			leaveLeague(player)
		else
			selfSay('Nadie me gana con los Pokemon de Hielo. Tus Pokemon quedaran congelados!', cid)
			npcHandler.topic[cid] = 1
			npcHandler:setMaxIdleTime(600)
			player:setDuelWithNpc()
		end
	end
	return true
end

local function creatureOnReleaseFocusCallback(cid)
	local npc = Npc()
	if hasSummons(npc) then
		local monster = npc:getSummons()[1]
		monster:getPosition():sendMagicEffect(balls.pokeball.effectRelease)
		if gymSummonDamage then
			gymSummonDamage[monster:getId()] = nil
		end
		monster:remove()
	end
	local player = Player(cid)
	if player then
		player:unsetDuelWithNpc()
	end
	return true
end

local function creatureOnDisapearCallback(cid)
	local player = Player(cid)
	if not player then
		npcHandler:updateFocus()
		return true
	end
	if npcHandler:isFocused(cid) then
		if getDistanceTo(cid) >= 0 and getDistanceTo(cid) <= 8 then
			return false
		end
		sendToExit(cid)
	end
	return true
end

local function onVictory(player, cid)
	if isChampion then
		selfSay('Las cosas no tenian que acabar asi... Eres mejor de lo que pensaba. Adelante, Bruno te espera.', cid)
		player:giveQuestPrize(quests.indigoLeague.prizes[1].uid)
		if progressionOnBadge then
			progressionOnBadge(player, "indigoLeague")
		end
		Game.broadcastMessage(player:getName() .. " ha derrotado al Alto Mando y es el nuevo Campeon de la Liga Pokemon!", MESSAGE_EVENT_ADVANCE)
		leaveLeague(player)
	else
		selfSay('Las cosas no tenian que acabar asi... Eres mejor de lo que pensaba. Adelante, Bruno te espera.', cid)
		teleportNear(player, nextPosition)
	end
	npcHandler:releaseFocus(cid)
end

local function creatureOnThinkCallback()
	if npcHandler:hasFocus() then
		local npc = Npc()
		local npcPosition = npc:getPosition()
		local spectators = Game.getSpectators(npcPosition, false, true)
		for i = 1, #spectators do
			local player = spectators[i]
			local cid = player:getId()
			if npcHandler:isFocused(cid) and npcHandler.topic[cid] == 1 then
				local duelStatus = player:getDuelWithNpcStatus()
				local monster = npc:getSummons()[1]
				if not monster then
					if pokemons[duelStatus] then
						selfSay(pokemons[duelStatus].name .. ", te elijo a ti!")
						npcPosition:getNextPosition(npc:getDirection())
						monster = Game.createMonster(pokemons[duelStatus].name, npcPosition, false, true, pokemons[duelStatus].level, 0)
						npcPosition:sendMagicEffect(balls.pokeball.effectRelease)
						monster:setMaster(npc)
						local health = math.floor(monster:getTotalHealth() * (pokemons[duelStatus].hp or 3))
						monster:setMaxHealth(health)
						monster:setHealth(health)
						if gymSummonDamage then
							gymSummonDamage[monster:getId()] = pokemons[duelStatus].damage or 1.0
						end
						monster:changeSpeed(-monster:getSpeed() + monster:getTotalSpeed())
						player:increaseDuelWithNpcStatus()
					else
						onVictory(player, cid)
						return true
					end
				end
				if hasSummons(player) and hasSummons(npc) then
					monster:selectTarget(player:getSummons()[1])
				end
				local pokeballs = player:getPokeballs()
				local pokemonsAlive = 0
				for i = 1, #pokeballs do
					local ball = pokeballs[i]
					if ball:getSpecialAttribute("pokeHealth") > 0 then
						pokemonsAlive = pokemonsAlive + 1
					end
				end
				if pokemonsAlive == 0 then
					sendToExit(cid)
				end
			end
		end
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_ONTHINK, creatureOnThinkCallback)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, creatureOnReleaseFocusCallback)
npcHandler:setCallback(CALLBACK_CREATURE_DISAPPEAR, creatureOnDisapearCallback)
npcHandler:setCallback(CALLBACK_GREET, creatureGreetCallback)
npcHandler:addModule(FocusModule:new())
