local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_NONE)
combat:setParameter(COMBAT_PARAM_AGGRESSIVE, false)
combat:setParameter(COMBAT_PARAM_EFFECT, 745)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))

local sleepDuration = 5000
local sleepingTargets = {}

local pilotSpecies = {
	["venusaur"] = true,
	["vileplume"] = true,
	["butterfree"] = true,
	["roserade"] = true,
	["jumpluff"] = true
}

local function isPilotCaster(creature)
	return creature and creature:isPokemon() and pilotSpecies[creature:getName():lower()] == true
end

local function isSleepTarget(target)
	return target and target:isMonster() and not target:isPokemon()
end

local function wakeTarget(targetId, expiresAt)
	local target = Monster(targetId)
	if target and sleepingTargets[targetId] == expiresAt then
		sleepingTargets[targetId] = nil
		target:removeCondition(CONDITION_ROOT)
		target:searchTarget()
	end
end

function onTargetCreature(creature, target)
	if not isPilotCaster(creature) or not isSleepTarget(target) then
		return
	end

	local root = Condition(CONDITION_ROOT)
	root:setParameter(CONDITION_PARAM_TICKS, sleepDuration)
	target:addCondition(root)
	local expiresAt = os.time() + 5
	local targetId = target:getId()
	sleepingTargets[targetId] = expiresAt
	target:setTarget(nil)
	local targets = target:getTargetList()
	for i = 1, #targets do
		local currentTarget = targets[i]
		if currentTarget then
			target:removeTarget(currentTarget)
		end
	end
	addEvent(wakeTarget, sleepDuration, targetId, expiresAt)
end

combat:setCallback(CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(creature, variant, isHotkey)
	return combat:execute(creature, variant)
end
