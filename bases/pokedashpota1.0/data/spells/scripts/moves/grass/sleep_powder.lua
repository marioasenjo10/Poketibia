local combat = Combat()
combat:setParameter(COMBAT_PARAM_EFFECT, 745)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))

local sleepKey = 65055
local sleepDuration = 5000

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
	if target and target:getStorageValue(sleepKey) == expiresAt then
		target:setStorageValue(sleepKey, 0)
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
	target:setStorageValue(sleepKey, expiresAt)
	target:setTarget(nil)
	for i = target:getTargetCount() - 1, 0, -1 do
		local currentTarget = target:getTargetList()[i]
		if currentTarget then
			target:removeTarget(currentTarget)
		end
	end
	addEvent(wakeTarget, sleepDuration, target:getId(), expiresAt)
end

combat:setCallback(CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(creature, variant, isHotkey)
	return combat:execute(creature, variant)
end
