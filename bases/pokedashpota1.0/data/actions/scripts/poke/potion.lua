local potions = {
	[27642] = {name = "Small Potion", level = 0, heal = 10},
	[27643] = {name = "Great Potion", level = 20, heal = 20},
	[27641] = {name = "Ultra Potion", level = 50, heal = 30},
	[27647] = {name = "Hyper Potion", level = 80, heal = 40},
	[27646] = {name = "Ultimate Potion", level = 100, heal = 50}
}

local healingTicks = 5
local healingInterval = 2000
local ballHealingToken = 0

local function findHealingBall(container, token)
	for slot = 0, container:getSize() - 1 do
		local item = container:getItem(slot)
		if item then
			if item:isPokeball() and item:getSpecialAttribute("potionHealingToken") == token then
				return item
			end
			if item:isContainer() then
				local ball = findHealingBall(item, token)
				if ball then
					return ball
				end
			end
		end
	end
	return nil
end

local function getPlayerHealingBall(player, token)
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if backpack then
		local ball = findHealingBall(backpack, token)
		if ball then
			return ball
		end
	end

	local ball = player:getSlotItem(CONST_SLOT_AMMO)
	if ball and ball:isPokeball() and ball:getSpecialAttribute("potionHealingToken") == token then
		return ball
	end
	return nil
end

local function clearBallHealing(ball)
	ball:setSpecialAttribute("potionHealingToken", 0)
	ball:setSpecialAttribute("potionHealingTicks", 0)
	ball:setSpecialAttribute("potionHealingAmount", 0)
	ball:setSpecialAttribute("potionHealingExpires", 0)
end

local function getBallMaxHealth(player, ball)
	local name = ball:getSpecialAttribute("pokeName")
	if not name then
		return 0
	end

	local monsterType = MonsterType(name)
	if not monsterType then
		return 0
	end
	local baseHealth = monsterType:getMaxHealth()
	local boost = ball:getSpecialAttribute("pokeBoost") or 0
	local love = ball:getSpecialAttribute("pokeLove") or 0
	if baseHealth <= 0 then
		return 0
	end
	return math.floor(baseHealth * statusGainFormula(player:getLevel(), 0, boost, love))
end

local function applyBallHealingTick(playerId, token)
	local player = Player(playerId)
	if not player then
		return
	end

	local ball = getPlayerHealingBall(player, token)
	if not ball or ball:getSpecialAttribute("potionHealingToken") ~= token then
		return
	end

	local ticks = ball:getSpecialAttribute("potionHealingTicks") or 0
	local amount = ball:getSpecialAttribute("potionHealingAmount") or 0
	local health = ball:getSpecialAttribute("pokeHealth") or 0
	local maxHealth = getBallMaxHealth(player, ball)
	if ticks <= 0 or health <= 0 or maxHealth <= health then
		clearBallHealing(ball)
		return
	end

	ball:setSpecialAttribute("pokeHealth", math.min(health + amount, maxHealth))
	ticks = ticks - 1
	ball:setSpecialAttribute("potionHealingTicks", ticks)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)

	if ticks == 0 or ball:getSpecialAttribute("pokeHealth") >= maxHealth then
		clearBallHealing(ball)
		return
	end

	ball:setSpecialAttribute("potionHealingExpires", os.time() + math.ceil(ticks * healingInterval / 1000) + 2)
	addEvent(applyBallHealingTick, healingInterval, playerId, token)
end

local function isLeaguePotionAllowed(player)
	return not player:isOnLeague() or player:canUsePotionOnLeague()
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local potion = potions[item:getId()]
	if not potion or not target or type(target) ~= "userdata" then
		return true
	end

	if player:getLevel() < potion.level then
		player:sendCancelMessage("You need trainer level " .. potion.level .. " to use the " .. potion.name .. ".")
		return true
	end

	if not isLeaguePotionAllowed(player) then
		player:sendCancelMessage("Sorry, you can not use potion anymore.")
		return true
	end
	if player:isDuelingWithNpc() then
		player:sendCancelMessage("Sorry, not possible while in duels.")
		return true
	end

	local healPerTick = potion.heal + math.floor(player:getLevel() / 5)
	if target:isCreature() then
		if not target:isPokemon() then
			player:sendCancelMessage("Pokémon potions can only be used on a Pokémon.")
			return true
		end

		local master = target:getMaster()
		if master ~= player then
			player:sendCancelMessage("You can only heal your own Pokémon.")
			return true
		end
		if target:getHealth() <= 0 then
			player:sendCancelMessage("Use a revive on a fainted Pokémon first.")
			return true
		end
		if target:getHealth() >= target:getMaxHealth() then
			player:sendCancelMessage("Your Pokémon is already at full health.")
			return true
		end
		if target:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT) then
			player:sendCancelMessage("Your Pokémon is already recovering health.")
			return true
		end

		local condition = Condition(CONDITION_REGENERATION)
		condition:setParameter(CONDITION_PARAM_TICKS, healingTicks * healingInterval)
		condition:setParameter(CONDITION_PARAM_HEALTHGAIN, healPerTick)
		condition:setParameter(CONDITION_PARAM_HEALTHTICKS, healingInterval)
		if not target:addCondition(condition) then
			return true
		end
		target:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	elseif target:isItem() and target:isPokeball() then
		if target:getTopParent() ~= player then
			player:sendCancelMessage("The Poké Ball must be in your inventory.")
			return true
		end
		if not target:getSpecialAttribute("pokeName") then
			player:sendCancelMessage("This Poké Ball does not contain a Pokémon.")
			return true
		end
		if target:getSpecialAttribute("isBeingUsed") == 1 then
			player:sendCancelMessage("Use the potion on your summoned Pokémon.")
			return true
		end

		local health = target:getSpecialAttribute("pokeHealth") or 0
		local maxHealth = getBallMaxHealth(player, target)
		if maxHealth <= 0 then
			player:sendCancelMessage("This Poké Ball does not contain a valid Pokémon.")
			return true
		end
		if health <= 0 then
			player:sendCancelMessage("Use a revive on a fainted Pokémon first.")
			return true
		end
		if maxHealth <= health then
			player:sendCancelMessage("The Pokémon in this Poké Ball is already at full health.")
			return true
		end

		local ticks = target:getSpecialAttribute("potionHealingTicks") or 0
		local expires = target:getSpecialAttribute("potionHealingExpires") or 0
		if ticks > 0 and expires > os.time() then
			player:sendCancelMessage("The Pokémon in this Poké Ball is already recovering health.")
			return true
		end
		clearBallHealing(target)

		ballHealingToken = ballHealingToken + 1
		local token = tostring(player:getGuid()) .. ":" .. tostring(os.time()) .. ":" .. tostring(ballHealingToken)
		target:setSpecialAttribute("potionHealingToken", token)
		target:setSpecialAttribute("potionHealingTicks", healingTicks)
		target:setSpecialAttribute("potionHealingAmount", healPerTick)
		target:setSpecialAttribute("potionHealingExpires", os.time() + math.ceil(healingTicks * healingInterval / 1000) + 2)
		addEvent(applyBallHealingTick, healingInterval, player:getId(), token)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:sendCancelMessage("Use this potion on a summoned Pokémon or its Poké Ball.")
		return true
	end

	item:remove(1)
	return true
end
