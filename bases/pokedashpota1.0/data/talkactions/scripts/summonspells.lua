function onSay(player, words, param)
	local summon = player:getSummon()
	if not summon then
		player:sendCancelMessage("Sorry, not possible. You need a summon to conjure spells.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local tile = Tile(player:getPosition())
	if tile:hasFlag(TILESTATE_PROTECTIONZONE) then
		player:sendCancelMessage("Sorry, not possible in protection zone.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local summonName = summon:getName()
	local monsterType = MonsterType(summonName)
	local move = monsterType:getMoveList()
	local target = summon:getTarget()
	
	for i = 1, #moveWords do
		if words == moveWords[i] then			
			if move[i] then
				local needsTarget = moveNeedsTarget(move[i])
				local range = tonumber(move[i].range) or 0
				if needsTarget and not target then
					player:sendCancelMessage("Sorry, not possible. You need a target.")
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					break
				end
				if target and needsTarget and range > 0 and getDistanceBetween(summon:getPosition(), target:getPosition()) > range then
					player:sendCancelMessage("Sorry, not possible. You are too far.")
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					break
				end
				if getCreatureCondition(summon, CONDITION_SLEEP) then
					player:sendCancelMessage("Sorry, not possible. Your pokemon is sleeping.")
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					break
				end
				local exhausted = player:checkMoveExhaustion(i, move[i].speed / 1000)
				if not exhausted then
					local moveName = move[i].name
					doCreatureCastSpell(summon, moveName)
					player:say(summonName .. ", use " .. moveName .. "!", TALKTYPE_MONSTER_SAY)
				end
			else
				player:sendCancelMessage("Sorry, not possible.")
				player:getPosition():sendMagicEffect(CONST_ME_POFF)
				break
			end
		end
	end
	return false
end
