local conditionsToClear = {
	CONDITION_POISON,
	CONDITION_PARALYZE,
	CONDITION_SLEEP,
	CONDITION_DRUNK
}

function onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	for _, condition in ipairs(conditionsToClear) do
		creature:removeCondition(condition)
	end

    local player = creature:getMaster()
    if player then
	local item = player:getUsingBall()
	if item then
        	item:setSpecialAttribute("pokeHealth", 0)
       		player:sendCancelMessage("Your pokemon has died.")
		creature:unregisterEvent("MonsterDeath")
		player:say("Thanks, " .. creature:getName() .. "!", TALKTYPE_MONSTER_SAY)
		item:setSpecialAttribute("isBeingUsed", 0)
	end
    end
    return true
end
