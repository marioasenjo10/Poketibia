local storage = quests.volcanoBadge.prizes[1].uid
-- revancha amistosa: si ya tienes la medalla se puede volver a luchar, sin premio
local rematch = {}
-- Septimo gimnasio (medalla Volcan). Pensado para un entrenador de nivel ~80:
-- con un Pokemon de tipo Agua, Tierra o Roca se gana justo.
-- level: nivel de fuerza (misma curva que el entrenador) | hp: multiplicador de vida
-- damage: multiplicador de dano. Valores calculados con el simulador de combate.
local pokemons =
{
	[1] = {name = "Ninetales", level = 76, hp = 3, damage = 1.5},
	[2] = {name = "Rapidash", level = 78, hp = 3.5, damage = 1.6},
	[3] = {name = "Arcanine", level = 80, hp = 4, damage = 1.8},
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

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

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end	
	if msgcontains(msg, 'bye') or msgcontains(msg, 'adios') or msgcontains(msg, 'no') or msgcontains(msg, 'nao') then
		selfSay('Vuelve cuando estes preparado.', cid)
		npcHandler:releaseFocus(cid)
	elseif msgcontains(msg, 'revancha') then
		local player = Player(cid)
		if player and player:getStorageValue(storage) > 0 then
			selfSay('Revancha amistosa, sin premio. Veamos si sigues en forma!', cid)
			rematch[cid] = true
			npcHandler.topic[cid] = 1
			npcHandler:setMaxIdleTime(600)
			player:setDuelWithNpc()
		elseif player then
			selfSay('Primero tienes que ganarme de verdad. Quieres desafiarme? {si}', cid)
		end
	elseif msgcontains(msg, 'yes') or msgcontains(msg, 'si') or msgcontains(msg, 'sim') then
		local player = Player(cid)
		if player then
			-- se puede retar sin la tarea previa: al ganar se completa sola (progressionOnBadge)
			if player:getStorageValue(storage) <= 0 then
				selfSay('Ja! Vamos a calentar este combate!', cid)
				npcHandler.topic[cid] = 1
				npcHandler:setMaxIdleTime(600)
				player:setDuelWithNpc()
			else
				selfSay('Ya me derrotaste. Dicen que el gimnasio de Ciudad Verde por fin ha abierto. Su Lider es muy misterioso... Si quieres, una {revancha} amistosa, sin premio.', cid)
			end
		end
	end
	return true
end

local function creatureOnReleaseFocusCallback(cid)
	rematch[cid] = nil
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
		selfSay("Mas suerte la proxima vez, " .. player:getName() .. "!", cid)
		npcHandler:releaseFocus(cid)
	end
	return true
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
						local health = math.floor(monster:getTotalHealth() * (pokemons[duelStatus].hp or 10))
						monster:setMaxHealth(health)
						monster:setHealth(health)
						if gymSummonDamage then
							gymSummonDamage[monster:getId()] = pokemons[duelStatus].damage or 1.0
						end
						monster:changeSpeed(-monster:getSpeed() + monster:getTotalSpeed())
						player:increaseDuelWithNpcStatus()
					else
						if rematch[cid] then
							selfSay('Buen combate, ' .. player:getName() .. '. Sigues siendo muy fuerte.', cid)
							rematch[cid] = nil
						else
							selfSay('Increible, ' .. player:getName() .. "! Tus Pokemon han dejado a los mios en cenizas. Llevate la Medalla Volcan!", cid)
							player:giveQuestPrize(storage)
							if progressionOnBadge then
								progressionOnBadge(player, "volcanoBadge")
							end
						end
						npcHandler:releaseFocus(cid)
					end
				end
				if hasSummons(player) and hasSummons(npc) then
					monster:selectTarget(player:getSummons()[1])
				end
				local pokeballs = player:getPokeballs()
				local pokemonsAlive = 0
				for i=1, #pokeballs do
					local ball = pokeballs[i]					
					if ball:getSpecialAttribute("pokeHealth") > 0 then
						pokemonsAlive = pokemonsAlive + 1
					end
				end
				if pokemonsAlive == 0 then
					selfSay("Mas suerte la proxima vez, " .. player:getName() .. "! Prueba con un Pokemon de tipo Agua, Tierra o Roca.", cid)
					npcHandler:releaseFocus(cid)				
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
