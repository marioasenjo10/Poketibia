local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_NONE)
combat:setParameter(COMBAT_PARAM_AGGRESSIVE, false)
combat:setParameter(COMBAT_PARAM_EFFECT, 745)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))

local sleepDuration = 5000
local sleepingTargets = {}
local sleepConditionSubId = 65055

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
		target:removeCondition(CONDITION_PARALYZE, CONDITIONID_COMBAT, sleepConditionSubId)
		target:searchTarget()
	end
end

function onTargetCreature(creature, target)
	if not isPilotCaster(creature) or not isSleepTarget(target) then
		return
	end

	local paralysis = Condition(CONDITION_PARALYZE)
	if not paralysis then
		return
	end
	paralysis:setParameter(CONDITION_PARAM_TICKS, sleepDuration)
	paralysis:setParameter(CONDITION_PARAM_SPEED, -math.max(target:getSpeed(), 1))
	paralysis:setParameter(CONDITION_PARAM_SUBID, sleepConditionSubId)
	target:addCondition(paralysis)
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
