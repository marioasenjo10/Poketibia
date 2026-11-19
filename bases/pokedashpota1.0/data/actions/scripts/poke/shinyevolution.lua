-- Objeto de evolucion shiny (items 46001+, ver data/lib/core/shinyevolution.lua)
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local entry = shinyEvoItems[item:getId()]
	if not entry then
		return false
	end

	local summon = player:getSummon()
	if not summon then
		player:sendCancelMessage("Sorry, not possible. You need a summon to evolve.")
		return true
	end
	-- se puede usar directamente o "usar con" sobre tu pokemon
	if target and target ~= item and target.isCreature and target:isCreature() and target ~= summon then
		player:sendCancelMessage("Sorry, not possible. You can only evolve your own summon.")
		return true
	end

	if summon:isEvolving() then
		player:sendCancelMessage("Sorry, not possible. Your summon is already evolving.")
		return true
	end

	local ball = player:getUsingBall()
	if not ball then return true end

	local dittoTime = ball:getSpecialAttribute("dittoTime")
	if dittoTime and os.time() < dittoTime then
		player:sendCancelMessage("Sorry, not possible. You can not evolve your Pokemon while transformed.")
		return true
	end

	local monsterType = MonsterType(summon:getName())
	local canEvolve = false
	if monsterType then
		for _, evolution in ipairs(monsterType:getEvolutionList()) do
			if evolution.name == entry.target then
				canEvolve = true
				break
			end
		end
	end
	if not canEvolve then
		player:sendCancelMessage("Sorry, not possible. This item only evolves a pokemon into " .. entry.target .. ".")
		return true
	end

	item:remove(1)
	doEvolveSummon(summon:getId(), entry.target, false)
	return true
end
