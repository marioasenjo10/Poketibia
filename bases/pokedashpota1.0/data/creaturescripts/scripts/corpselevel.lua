function onDeath(creature, corpse, killer, mostDamage, unjustified, mostDamage_unjustified)
	if type(corpse) ~= "userdata" then
		return true
	end
	-- tareas de "derrotar" (progression.lua): cuenta para el jugador o el duenio del Pokemon que lo mato
	if progressionOnDefeat and creature and killer and not isSummon(creature) then
		local trainer = killer:isPlayer() and killer or killer:getMaster()
		if trainer and trainer:isPlayer() then
			progressionOnDefeat(Player(trainer:getId()), creature:getName(), creature:getPosition())
		end
	end
	if corpse and creature and MonsterType(creature:getName()):getCorpseId() ~= 0 and not isSummon(creature) then
		local level = creature:getLevel()
		if level then
			corpse:setSpecialAttribute("corpseLevel", level)
		else
			print("WARNING! Creature " .. creature:getName() .. " not possible to set corpse level!")
		end
	end
	return true
end
