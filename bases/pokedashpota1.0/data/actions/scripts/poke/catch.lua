local initialLevel = 1
local initialBoost = 0
local multiplierExpFirstNormal = 800
local multiplierExpNormal = 200
local multiplierExpFirstShiny = 3000
local multiplierExpShiny = 1000

local function doPlayerSendEffect(cid, effect)
	local player = Player(cid)
	if player then
		player:getPosition():sendMagicEffect(effect)
	end
	return true
end

local function doPlayerAddExperience(cid, exp)
	local player = Player(cid)
	if player then
		player:addExperience(exp, true)
	end
	return true
end

local shinyCatchTierCache = {}
local function getCatchTier(name)
	if shinyCatchTierCache[name] ~= nil then
		return shinyCatchTierCache[name] or nil
	end

	local file = io.open("data/pokemon-tiers-review.csv", "rb")
	if not file then
		return nil
	end

	local target = name:lower()
	for line in file:lines() do
		local rowName, tier = line:match('^"?([^,"]+)"?,([^,]+),')
		if rowName and rowName:lower() == target then
			file:close()
			tier = tier:gsub('^"', ""):gsub('"$', "")
			local first = tier:sub(1, 1)
			if first == "\239" or first == "\187" or first == "\191" then
				tier = tier:gsub("^\239\187\191", "")
			end
			shinyCatchTierCache[name] = tier
			return tier
		end
	end
	file:close()
	shinyCatchTierCache[name] = false
	return nil
end

local function isReservedCustomPokemon(name)
	local customPrefixes = {
		"ancient ", "corsair ", "cultist ", "crystal ", "dark ", "decorated ", "devil ",
		"elder ", "elite ", "executioner ", "frankstein ", "ghost ", "grinch ", "hag ",
		"hauting ", "mummy ", "panic ", "pirate ", "pumpkin ", "raven ", "reindeer ",
		"santa ", "skull ", "snowman ", "super ", "undead ", "vampire ", "werewolf ",
		"wicked ", "witch ", "xmas "
	}
	local lowerName = name:lower():gsub("^shiny%s+", "")
	for _, prefix in ipairs(customPrefixes) do
		if lowerName:sub(1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local uncatchableLegendarySpecies = {
	articuno = true, zapdos = true, moltres = true, mewtwo = true, mew = true,
	raikou = true, entei = true, suicune = true, lugia = true, ["ho-oh"] = true,
	celebi = true, regirock = true, regice = true, registeel = true, latias = true,
	latios = true, kyogre = true, groudon = true, rayquaza = true, jirachi = true,
	deoxys = true, uxie = true, mesprit = true, azelf = true, dialga = true,
	palkia = true, heatran = true, regigigas = true, giratina = true, cresselia = true,
	phione = true, manaphy = true, darkrai = true, shaymin = true, arceus = true
}

local function isUncatchableLegendary(name)
	local species = name:lower():gsub("^shiny%s+", "")
	return uncatchableLegendarySpecies[species] == true
end

local shinyCatchPitySlopeCache = {}
local function getProgressiveShinyCatchChance(player, monsterType, ballMultiplier, isCatcher)
	local tier = getCatchTier(monsterType:getName())
	local tierSettings = tier and shinyCatchPityTiers[tier]
	if not tierSettings then
		return nil
	end

	local speciesNumber = monsterType:getNumber()
	local pityStorage = baseStorageShinyCatchPity + speciesNumber
	local failedAttempts = math.max(0, player:getStorageValue(pityStorage))
	local nextAttempt = failedAttempts + 1
	local slope = shinyCatchPitySlopeCache[tier]
	if not slope then
		local low, high = 0, 1
		for _ = 1, 24 do
			local candidate = (low + high) / 2
			local survival = 1
			for attempt = 1, tierSettings.attempts do
				survival = survival * (1 - math.min(1, candidate * attempt))
			end
			if 1 - survival < tierSettings.chance then
				low = candidate
			else
				high = candidate
			end
		end
		slope = (low + high) / 2
		shinyCatchPitySlopeCache[tier] = slope
	end
	local chance = math.min(1, slope * nextAttempt) * (ballMultiplier / 1.4)
	if isCatcher then
		chance = chance * catcherCatchBuff
	end
	return chance, pityStorage, failedAttempts
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local tile = Tile(toPosition)
	if not tile or not tile:getTopDownItem() or not ItemType(tile:getTopDownItem():getId()):isCorpse() then
		return false
	end
	local targetCorpse = tile:getTopDownItem()

	local owner = targetCorpse:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER)
	if owner ~= 0 and owner ~= player:getId() then
		player:sendCancelMessage("Sorry, not possible. You are not the owner.")
		return true
	end
	
	local ballKey = getBallKey(item:getId())
	local playerPos = getPlayerPosition(player)
	local d = getDistanceBetween(playerPos, toPosition)
	local delay = d * 80
	local delayMessage = delay + 2800
	local name = targetCorpse:getName()
	if name == "dead human" then		
		playerPos:sendMagicEffect(CONST_ME_POFF)
		return false
	end
	if name == "dead enlightened of the cult" then
		name = "enlightened of the cult"
	elseif name == "slain undead dragon" then
		name = "undead dragon"
	else
		name = string.gsub(name, "the ", "")
		name = string.gsub(name, "remains of ferumbras", "Ferumbras")
		name = string.gsub(name, "remains of", "")
		name = string.gsub(name, " a ", "")
		name = string.gsub(name, " an ", "")
		name = string.gsub(name, "slain ", "")
		name = string.gsub(name, "fainted ", "")
		name = string.gsub(name, "defeated ", "")
--		name = string.gsub(name, "dead ", "")
	end

	local monsterType = MonsterType(name)
	if not monsterType then
		print("WARNING! Monster " .. name .. " with bug on catch!")
		player:sendCancelMessage("Sorry, not possible. This problem was reported.")
		return true
	end
	local isShiny = name:sub(1, 6):lower() == "shiny "
	local isCatcher = player:getVocation():getName() == "Catcher"
	local chance, pityStorage, failedAttempts
	local usesProbabilityRoll = false
	if isReservedCustomPokemon(name) or isUncatchableLegendary(name) then
		playerPos:sendMagicEffect(CONST_ME_POFF)
		player:sendCancelMessage("This Pokemon is not available for capture yet.")
		return true
	end
	local tier = getCatchTier(name)
	if isShiny then
		chance, pityStorage, failedAttempts = getProgressiveShinyCatchChance(player, monsterType, balls[ballKey].chanceMultiplier, isCatcher)
		if not chance then
			playerPos:sendMagicEffect(CONST_ME_POFF)
			player:sendCancelMessage("This shiny Pokemon does not have a configured catch tier yet.")
			return true
		end
		usesProbabilityRoll = true
	else
		local tierRate = tier and normalCatchTierRates[tier]
		if tierRate then
			chance = tierRate * (balls[ballKey].chanceMultiplier / 1.4)
			if isCatcher then
				chance = chance * catcherCatchBuff
			end
			usesProbabilityRoll = true
		elseif tier then
			playerPos:sendMagicEffect(CONST_ME_POFF)
			player:sendCancelMessage("This Pokemon's catch tier does not have a configured rate yet.")
			return true
		elseif monsterType:dexEntry() > 0 then
			playerPos:sendMagicEffect(CONST_ME_POFF)
			player:sendCancelMessage("This Pokemon is not assigned a catch tier yet.")
			return true
		end
	end
	if chance == nil then
		chance = monsterType:catchChance() * balls[ballKey].chanceMultiplier
		if isCatcher then
			chance = chance * catcherCatchBuff
		end
	end
	if chance <= 0 then
		playerPos:sendMagicEffect(CONST_ME_POFF)
		player:sendCancelMessage("Sorry, it is impossible to catch this monster.")
		return true
	end
	local monsterNumber = monsterType:getNumber()
	local storageCatch = baseStorageCatches + monsterNumber
	local storageTry = baseStorageTries + monsterNumber
	doSendDistanceShoot(playerPos, toPosition, balls[ballKey].missile)
	item:remove(1)
	targetCorpse:remove()
	if player:getStorageValue(storageTry) < 0 then
		player:setStorageValue(storageTry, 1)
	else
		player:setStorageValue(storageTry, player:getStorageValue(storageTry) + 1)
	end
	local caught
	if usesProbabilityRoll then
		caught = math.random() < chance
	else
		caught = math.random(1, 300) <= chance
	end
	if caught then -- caught
		if pityStorage then
			player:setStorageValue(pityStorage, 0)
		end
		-- check how many pokeballs the player has
		if player:getSlotItem(CONST_SLOT_BACKPACK) and player:getSlotItem(CONST_SLOT_BACKPACK):getEmptySlots() >= 1 and player:getFreeCapacity() >= 1 then -- add to backpack
			addEvent(doAddPokeball, delayMessage, player:getId(), name, initialBoost, ballKey, false, delayMessage)
		else -- send to cp
			local addPokeball = doAddPokeball(player:getId(), name, initialBoost, ballKey, true, delayMessage + 4000)
			if not addPokeball then
				print("ERROR! Player " .. player:getName() .. " lost pokemon " .. name .. "! addPokeball false")
			end
			addEvent(doPlayerSendTextMessage, delayMessage + 2000, player:getId(), MESSAGE_EVENT_ADVANCE, "Since you are at maximum capacity, your ball was sent to CP.")
		end
		
		local playerLevel = player:getLevel()
		local maxExp = getNeededExp(playerLevel + 2) - getNeededExp(playerLevel)
		local maxExpShiny = getNeededExp(playerLevel + 5) - getNeededExp(playerLevel)

		local givenExp = monsterType:getExperience() * configManager.getNumber(configKeys.RATE_EXPERIENCE)
		if msgcontains(name, 'Shiny') and player:getStorageValue(storageCatch) == -1 then
			givenExp = givenExp * multiplierExpFirstShiny
			if givenExp > maxExpShiny then
				givenExp = maxExpShiny 
			end
			addEvent(doPlayerSendTextMessage, delayMessage + 1000, player:getId(), MESSAGE_EVENT_ADVANCE, "You got a bonus exp for your first catch of " .. name .. "!")
		elseif msgcontains(name, 'Shiny') and player:getStorageValue(storageCatch) > 0 then
			givenExp = givenExp * multiplierExpShiny
			if givenExp > maxExpShiny then
				givenExp = maxExpShiny 
			end
			addEvent(doPlayerSendTextMessage, delayMessage + 1000, player:getId(), MESSAGE_EVENT_ADVANCE, "You got a bonus exp for catching a shiny!")
		elseif not msgcontains(name, 'Shiny') and player:getStorageValue(storageCatch) == -1 then
			givenExp = givenExp * multiplierExpFirstNormal
			if givenExp > maxExp then
				givenExp = maxExp
			end
			addEvent(doPlayerSendTextMessage, delayMessage + 1000, player:getId(), MESSAGE_EVENT_ADVANCE, "You got a bonus exp for your first catch of " .. name .. "!")
		else
			givenExp = givenExp * multiplierExpNormal
			if givenExp > maxExp then
				givenExp = maxExp
			end

		end

		if player:getStorageValue(storageCatch) == -1 then
			player:setStorageValue(storageCatch, 1)
		else
			player:setStorageValue(storageCatch, player:getStorageValue(storageCatch) + 1)
		end

		addEvent(doPlayerAddExperience, delayMessage, player:getId(), givenExp)
		addEvent(doSendMagicEffect, delay, toPosition, balls[ballKey].effectSucceed)
		addEvent(doPlayerSendTextMessage, delayMessage, player:getId(), MESSAGE_EVENT_ADVANCE, "Congratulations! You have caught a " .. name .. "!")
		addEvent(doPlayerSendEffect, delayMessage, player:getId(), 297)
	else -- missed
		if pityStorage then
			player:setStorageValue(pityStorage, failedAttempts + 1)
		end
		addEvent(doSendMagicEffect, delay, toPosition, balls[ballKey].effectFail)
		addEvent(doPlayerSendEffect, delayMessage, player:getId(), 286)
		return true
	end	

	return true
end
