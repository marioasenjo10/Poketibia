local function getExperienceForLevel(level)
	local previousLevel = level - 1
	return math.floor((50 * previousLevel * previousLevel * previousLevel
		- 150 * previousLevel * previousLevel + 400 * previousLevel) / 3)
end

function onSay(player, words, param)
	if not player:getGroup():getAccess() or player:getAccountType() < ACCOUNT_TYPE_GOD then
		return true
	end

	local split = param:split(",")
	if not split[2] then
		player:sendCancelMessage("Use: /setlevel player name, level")
		return false
	end

	local targetName = split[1]:gsub("^%s*(.-)%s*$", "%1")
	local target = Player(targetName)
	if not target then
		player:sendCancelMessage("A player with that name is not online.")
		return false
	end

	local levelText = split[2]:gsub("^%s*(.-)%s*$", "%1")
	local level = tonumber(levelText)
	if not level or level ~= math.floor(level) or level < 1 then
		player:sendCancelMessage("Level must be a whole number greater than 0.")
		return false
	end

	if level >= target:getLevel() then
		player:sendCancelMessage("The target level must be lower than the player's current level.")
		return false
	end

	if type(target.removeExperience) ~= "function" then
		player:sendCancelMessage("Level reduction is unavailable on this server.")
		print("[SetLevel] Player:removeExperience is unavailable.")
		return false
	end

	local targetExperience = getExperienceForLevel(level)
	local experienceToRemove = target:getExperience() - targetExperience
	target:removeExperience(experienceToRemove, false)

	player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
		"Reduced " .. target:getName() .. " to level " .. level .. ".")
	return false
end
