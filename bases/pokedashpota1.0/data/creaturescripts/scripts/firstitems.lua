local firstItems = {8922}
local name = "Pikachu"
--local portraitId = 27141

function onLogin(player)
	-- ventanas del Profesor Oak (eleccion de inicial)
	player:registerEvent("ProgressionModal")
	if player:getLastLoginSaved() == 0 and progressionNewStartEnabled then
		-- inicio nuevo: Pueblo Paleta, sin Pokemon; Oak le da el inicial (data/lib/core/progression.lua)
		for i = 1, #firstItems do
			player:addItem(firstItems[i], 1)
		end
		player:addSlotItems()
		if not player:getSlotItem(CONST_SLOT_BACKPACK) then
			player:addItem(1988, 1, false, CONST_SLOT_BACKPACK)
		end
		player:checkPokemonBelt()
		progressionSetupNewPlayer(player)
	elseif player:getLastLoginSaved() == 0 then
		for i = 1, #firstItems do
			player:addItem(firstItems[i], 1)
		end
		-- Check slots	
		player:addSlotItems()
--		player:addItem(player:getSex() == 0 and 2651 or 2650, 1)
--		player:addItem(1987, 1):addItem(2674, 1)
		local monsterType = MonsterType(name)
		local baseHealth = monsterType:getMaxHealth()
		local maxHealth = math.floor(baseHealth * statusGainFormula(player:getLevel(), 0, 0, 0) * getPokemonShinyStatMultiplier(name))
		if not player:getSlotItem(CONST_SLOT_BACKPACK) then
			player:addItem(1988, 1, false, CONST_SLOT_BACKPACK)
		end
		local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
		-- el pokemon inicial va al cinturon pokemon
		player:checkPokemonBelt()
		local addPokeball = (player:getPokemonBelt() or backpack):addItem(26661, 1)
--		player:addItem(27141, 1, false, 1, CONST_SLOT_HEAD)
		if addPokeball then
			addPokeball:setSpecialAttribute("pokeName", name)
			addPokeball:setSpecialAttribute("pokeBoost", 0)
			addPokeball:setSpecialAttribute("pokeMaxHealth", maxHealth)
			addPokeball:setSpecialAttribute("pokeHealth", maxHealth)
			addPokeball:setSpecialAttribute("pokeLove", 0)
		else
			print("WARNING! Player " .. player:getName() .. " without initial pokeball.")
		end
		player:addItem(26662, 100)
		player:addItem(27642, 20)
	end
	-- mochila PKA permanente
	if not player:getSlotItem(CONST_SLOT_BACKPACK) then
		player:addItem(1988, 1, false, CONST_SLOT_BACKPACK)
	end
	-- la bici va en su casilla de la barra de abajo (piernas), no en la mochila
	if not player:getSlotItem(CONST_SLOT_LEGS) and player:getItemCount(27634) > 0 and player:removeItem(27634, 1) then
		player:addItem(27634, 1)
	end
	-- panel de tareas: al entrar y otra vez al segundo (por si el cliente aun no estaba listo)
	if player:isOnProgression() then
		player:sendTasks()
		addEvent(function(playerId)
			local p = Player(playerId)
			if p then
				p:sendTasks()
				if progressionNeedsStarter(p) and p:getLastLoginSaved() > 0 then
					p:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Todavia no tienes Pokemon. Habla con el Profesor Oak en Pueblo Paleta (di hi).")
				end
			end
		end, 1500, player:getId())
	end
	return true
end
