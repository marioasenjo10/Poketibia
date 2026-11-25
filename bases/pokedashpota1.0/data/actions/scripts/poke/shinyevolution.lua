-- Orbe de evolucion shiny (46001-46007) y objetos antiguos (46008+): ver data/lib/core/shinyevolution.lua.
-- El orbe guarda en "evoTarget" el shiny al que evoluciona; se usa con tu Pokemon fuera.
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local evoTarget = getShinyEvoTarget(item)
	if not evoTarget then
		player:sendCancelMessage("Este orbe no guarda ninguna evolucion.")
		return true
	end

	local summon = player:getSummon()
	if not summon then
		player:sendCancelMessage("Saca a tu Pokemon para evolucionarlo.")
		return true
	end
	-- se puede usar directamente o "usar con" sobre tu Pokemon
	if target and target ~= item and target.isCreature and target:isCreature() and target ~= summon then
		player:sendCancelMessage("Solo puedes evolucionar a tu propio Pokemon.")
		return true
	end

	if summon:isEvolving() then
		player:sendCancelMessage("Tu Pokemon ya esta evolucionando.")
		return true
	end

	local ball = player:getUsingBall()
	if not ball then return true end

	local dittoTime = ball:getSpecialAttribute("dittoTime")
	if dittoTime and os.time() < dittoTime then
		player:sendCancelMessage("No puedes evolucionar a tu Pokemon mientras esta transformado.")
		return true
	end

	local monsterType = MonsterType(summon:getName())
	local canEvolve = false
	if monsterType then
		for _, evolution in ipairs(monsterType:getEvolutionList()) do
			if evolution.name == evoTarget then
				canEvolve = true
				break
			end
		end
	end
	if not canEvolve then
		player:sendCancelMessage("Este orbe solo evoluciona a un Pokemon en " .. evoTarget .. ".")
		return true
	end

	local requiredLevel = getPokemonRequiredLevel(evoTarget)
	if player:getLevel() < requiredLevel then
		player:sendCancelMessage("Necesitas nivel " .. requiredLevel .. " para evolucionar a " .. evoTarget .. ".")
		return true
	end

	item:remove(1)
	doEvolveSummon(summon:getId(), evoTarget, false)
	return true
end
