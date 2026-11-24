local time = 10000
local damageMultiplier = damageMultiplierMoves.singletargetweak
local missileEffect = 74
local areaEffect = 422
local defenseType = COMBAT_PHYSICALDAMAGE
local combat = COMBAT_POISONDAMAGE

local combatEvent = Combat()
combatEvent:setParameter(COMBAT_PARAM_EFFECT, areaEffect)

function onCastSpell(creature, variant)
	local target = creature:getTarget()
	if not target then return true end
	local creaturePosition = creature:getPosition()
	local targetPosition = target:getPosition()
	if target:isPlayer() and hasSummons(target) then return true end

	local damage = damageMultiplier * creature:getTotalMeleeAttack()
	doSendDistanceShoot(creaturePosition, targetPosition, missileEffect)
	doTargetCombatHealth(creature.uid, target, combat, -damage, -damage, areaEffect, defenseType)


	if math.random(1, 100) <= 30 then
        	-- el dano se reparte entre los ticks (uno cada 2 s), no el golpe entero en cada tick
        	local condition = Condition(CONDITION_POISON)
        	condition:setParameter(CONDITION_PARAM_PERIODICDAMAGE, -math.max(1, math.floor(damage / (time / 2000))))
        	condition:setParameter(CONDITION_PARAM_TICKS, time)
        
        	target:addCondition(condition)
        
        	if not combatEvent:execute(creature, variant) then
        		return false
        	end
	end

	return true
end
