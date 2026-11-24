-- Estilo Poke Alliance: al subir de nivel el entrenador, su pokemon se hace mas fuerte al momento
function onAdvance(player, skill, oldLevel, newLevel)
	if skill ~= SKILL_LEVEL or not hasSummons(player) then
		return true
	end
	local summon = player:getSummon()
	if summon and summon:isPokemon() then
		summon:setMaxHealth(summon:getTotalHealth())
		-- al subir de nivel el Pokemon activo se cura del todo (ayuda mucho al principio)
		summon:addHealth(summon:getMaxHealth() - summon:getHealth())
		local ball = player:getUsingBall()
		if ball and ball:isPokeball() then
			ball:setSpecialAttribute("pokeHealth", summon:getHealth())
			ball:setSpecialAttribute("pokeMaxHealth", summon:getMaxHealth())
		end
		player:refreshPokemonBar({}, {})
		summon:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	return true
end
