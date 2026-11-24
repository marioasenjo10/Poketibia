local criticalProbability = 1
local blockedProbability = 1
-- Tabla de tipos (como en Pokemon): para cada tipo ATACANTE, contra que tipos defensores es
-- eficaz (strong), poco eficaz (weak) o no hace nada (immune). Con doble tipo se multiplica
-- por cada tipo del defensor (Agua contra Geodude, Roca/Tierra = x1.5 x1.5).
-- "earth" es el COMBAT_EARTHDAMAGE que el servidor usa para el veneno.
typeStrongMultiplier = 1.5
typeWeakMultiplier = 1 / 1.5
typeImmuneMultiplier = 0.0
-- dano de condiciones (sin atacante): fraccion del dano en bruto que se aplica en cada tick
conditionDamageFactor = 0.25
local racesStrength =
	{
		["normal"] = {strong = {}, weak = {"rock", "steel"}, immune = {"ghost"}},
		["fire"] = {strong = {"grass", "ice", "bug", "steel"}, weak = {"fire", "water", "rock", "dragon"}, immune = {}},
		["water"] = {strong = {"fire", "ground", "rock"}, weak = {"water", "grass", "dragon"}, immune = {}},
		["electric"] = {strong = {"water", "flying"}, weak = {"electric", "grass", "dragon"}, immune = {"ground"}},
		["grass"] = {strong = {"water", "ground", "rock"}, weak = {"fire", "grass", "poison", "flying", "bug", "dragon", "steel"}, immune = {}},
		["ice"] = {strong = {"grass", "ground", "flying", "dragon"}, weak = {"fire", "water", "ice", "steel"}, immune = {}},
		["fighting"] = {strong = {"normal", "ice", "rock", "dark", "steel"}, weak = {"poison", "flying", "psychic", "bug", "fairy"}, immune = {"ghost"}},
		["poison"] = {strong = {"grass", "fairy"}, weak = {"poison", "ground", "rock", "ghost"}, immune = {"steel"}},
		["ground"] = {strong = {"fire", "electric", "poison", "rock", "steel"}, weak = {"grass", "bug"}, immune = {"flying"}},
		["flying"] = {strong = {"grass", "fighting", "bug"}, weak = {"electric", "rock", "steel"}, immune = {}},
		["psychic"] = {strong = {"fighting", "poison"}, weak = {"psychic", "steel"}, immune = {"dark"}},
		["bug"] = {strong = {"grass", "psychic", "dark"}, weak = {"fire", "fighting", "poison", "flying", "ghost", "steel", "fairy"}, immune = {}},
		["rock"] = {strong = {"fire", "ice", "flying", "bug"}, weak = {"fighting", "ground", "steel"}, immune = {}},
		["ghost"] = {strong = {"psychic", "ghost"}, weak = {"dark"}, immune = {"normal"}},
		["dragon"] = {strong = {"dragon"}, weak = {"steel"}, immune = {"fairy"}},
		["dark"] = {strong = {"psychic", "ghost"}, weak = {"fighting", "dark", "fairy"}, immune = {}},
		["steel"] = {strong = {"ice", "rock", "fairy"}, weak = {"fire", "water", "electric", "steel"}, immune = {}},
		["fairy"] = {strong = {"fighting", "dragon", "dark"}, weak = {"fire", "poison", "steel"}, immune = {}},
	}
racesStrength["earth"] = racesStrength["poison"]

-- multiplicador de eficacia de un tipo de ataque contra los dos tipos del defensor
function getTypeEffectiveness(attackerRace, defenderRace, defenderRace2)
	local entry = racesStrength[attackerRace]
	if not entry then
		return 1.0
	end
	local multiplier = 1.0
	for _, race in ipairs({defenderRace, defenderRace2}) do
		if race and race ~= "none" then
			if isInArray(entry.immune, race) then
				return typeImmuneMultiplier
			end
			if isInArray(entry.strong, race) then
				multiplier = multiplier * typeStrongMultiplier
			end
			if isInArray(entry.weak, race) then
				multiplier = multiplier * typeWeakMultiplier
			end
		end
	end
	return multiplier
end

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType)

	if not attacker then
		-- dano de condiciones (veneno, leech seed, quemaduras...): llega sin atacante y se salta
		-- toda la formula de arriba, asi que se escala aqui para que no sea mas fuerte que un golpe
		if primaryType ~= COMBAT_HEALING and primaryDamage ~= 0 then
			primaryDamage = math.max(1, math.floor(math.abs(primaryDamage) * conditionDamageFactor)) * (primaryDamage < 0 and -1 or 1)
		end
		if secondaryType ~= COMBAT_HEALING and secondaryDamage ~= 0 then
			secondaryDamage = math.max(1, math.floor(math.abs(secondaryDamage) * conditionDamageFactor)) * (secondaryDamage < 0 and -1 or 1)
		end
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	if creature:isPlayer() and attacker:isMonster() and not attacker:getMaster() and #creature:getSummons() > 0 then
		return 0, primaryType, 0, secondaryType
	end
	if creature:isPlayer() or attacker:isPlayer() then
		local shinyMultiplier = attacker:isMonster() and getPokemonShinyStatMultiplier(attacker:getName()) or 1.0
		if primaryDamage then primaryDamage = math.floor(primaryDamage * shinyMultiplier * 0.08) end
		if secondaryDamage then secondaryDamage = math.floor(secondaryDamage * shinyMultiplier) end
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	local primaryTypeName = getCombatName(primaryType)
	local secondaryTypeName = getCombatName(secondaryType)

	local localDamageMultiplier = 1.0

	local masterLevel
	local summonLevel
	local summonBoost
	local summonLove

	if attacker:getMaster() and attacker:getMaster():isNpc() then
		masterLevel = 0
		summonLevel = attacker:getLevel()
		summonBoost = 0
		summonLove = 0
	else
		-- Los salvajes usan stats base de especie; solo los pokemon de jugador escalan por entrenador.
		masterLevel = attacker:isPokemon() and attacker:getMasterLevel() or 0
		summonLevel = attacker:getPowerLevel()
		summonBoost = attacker:getBoost()
		summonLove = attacker:getLove()
	end

	local formulaDamage = damageFormula(masterLevel, summonLevel, summonBoost, summonLove)
	if attacker:isPokemon() or attacker:getName():sub(1, 6):lower() == "shiny " then
		formulaDamage = formulaDamage * getPokemonShinyStatMultiplier(attacker:getName())
	end
	localDamageMultiplier = localDamageMultiplier * formulaDamage

	if secondaryTypeName == "physical" then
		local defenseDamping = (1-creature:getTotalDefense()/600)
		if defenseDamping <= 0.5 then 
			defenseDamping = 0.5
		elseif defenseDamping >= 1 then
			defenseDamping = 1
		end
		localDamageMultiplier = localDamageMultiplier * defenseDamping
	else
		if primaryTypeName ~= "physical" and creature:getTotalMagicDefense() > 0 then	
			local defenseDamping = (1-creature:getTotalMagicDefense()/600)
			if defenseDamping <= 0.5 then 
				defenseDamping = 0.5
			elseif defenseDamping >= 1 then
				defenseDamping = 1
			end
			localDamageMultiplier = localDamageMultiplier * defenseDamping
		end
	end

	local defenderMonsterType = MonsterType(creature:getName())
	local defenderRace = defenderMonsterType:getRaceName()
	local defenderRace2 = defenderMonsterType:getRace2Name()

	local effectiveness = getTypeEffectiveness(primaryTypeName, defenderRace, defenderRace2)
	if effectiveness <= 0 then
		Game.sendAnimatedText(creature:getPosition(), "INMUNE", TEXTCOLOR_LIGHTGREY)
		return 0, primaryType, 0, secondaryType
	end
	localDamageMultiplier = localDamageMultiplier * effectiveness

	-- equipos de gimnasio/NPC: dano extra configurado en el script del lider
	if gymSummonDamage and gymSummonDamage[attacker:getId()] then
		localDamageMultiplier = localDamageMultiplier * gymSummonDamage[attacker:getId()]
	end

	if math.random(1, 100) <= criticalProbability then
		localDamageMultiplier = localDamageMultiplier * 1.5
		Game.sendAnimatedText(creature:getPosition(), "CRITICAL", TEXTCOLOR_RED)
	else
		if math.random(1, 100) <= blockedProbability then
			localDamageMultiplier = 0.0
			Game.sendAnimatedText(creature:getPosition(), "BLOCKED", TEXTCOLOR_LIGHTGREY)
		end
	end

	if attacker:isPokemon() and creature:isPokemon() then --duel between players
		localDamageMultiplier = localDamageMultiplier / 7.0
	end

	if not attacker:isPokemon() and creature:isPokemon() then --wild pokemon damage
		localDamageMultiplier = localDamageMultiplier / 3.0
	end

	localDamageMultiplier = localDamageMultiplier * (0.3 + math.random(1, 20) * 0.01)

	if primaryDamage then primaryDamage = math.floor(primaryDamage * localDamageMultiplier) end
	if secondaryDamage then secondaryDamage = math.floor(secondaryDamage * localDamageMultiplier) end

	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
