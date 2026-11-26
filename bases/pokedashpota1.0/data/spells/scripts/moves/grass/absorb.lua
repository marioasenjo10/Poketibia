local damageMultiplier = damageMultiplierMoves.singletargetweak
local effect = 342
local healingEffect = 504
local missileEffect = 122
local combat = COMBAT_GRASSDAMAGE

function onCastSpell(creature, variant)
	local target = creature:getTarget()
	if not target then return true end

	local damage = damageMultiplier * creature:getTotalMagicAttack()
	local creaturePosition = creature:getPosition()
	local targetPosition = target:getPosition()

	doSendDistanceShoot(targetPosition, creaturePosition, missileEffect)
	doTargetCombatHealth(creature.uid, target, combat, -damage, -damage, effect)
	doTargetCombatHealth(0, creature, COMBAT_HEALING, damage * 0.5, damage * 0.5, healingEffect) -- cura la mitad (antes anulaba casi un Ember)

	return true
end

