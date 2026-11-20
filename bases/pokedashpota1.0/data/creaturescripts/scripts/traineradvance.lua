-- Estilo Poke Alliance: al subir de nivel el entrenador, su pokemon se hace mas fuerte al momento
function onAdvance(player, skill, oldLevel, newLevel)
	if skill ~= SKILL_LEVEL or not hasSummons(player) then
		return true
	end
	local summon = player:getSummon()
	if summon and summon:isPokemon() then
		summon:setMaxHealth(summon:getTotalHealth())
		summon:changeSpeed(-summon:getSpeed() + summon:getTotalSpeed())
		summon:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	return true
end
