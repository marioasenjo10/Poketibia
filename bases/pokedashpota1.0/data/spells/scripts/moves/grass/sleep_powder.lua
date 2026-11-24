local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_NONE)
combat:setParameter(COMBAT_PARAM_AGGRESSIVE, false)
combat:setParameter(COMBAT_PARAM_EFFECT, 745)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))

local sleepDuration = 5000
local sleepEffectInterval = 1000
local sleepingTargets = {}
local sleepConditionSubId = 65055
local sleepToken = 0

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

local function wakeTarget(targetId, token)
	local target = Monster(targetId)
	if sleepingTargets[targetId] == token then
		sleepingTargets[targetId] = nil
		if target then
			target:removeCondition(CONDITION_PARALYZE, CONDITIONID_COMBAT, sleepConditionSubId)
		end
	end
end

local function showSleepEffect(targetId, token)
	local target = Monster(targetId)
	if target and sleepingTargets[targetId] == token then
		target:getPosition():sendMagicEffect(CONST_ME_SLEEP)
		addEvent(showSleepEffect, sleepEffectInterval, targetId, token)
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
	local targetId = target:getId()
	sleepToken = sleepToken + 1
	local token = sleepToken
	sleepingTargets[targetId] = token
	showSleepEffect(targetId, token)
	addEvent(wakeTarget, sleepDuration, targetId, token)
end

combat:setCallback(CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(creature, variant, isHotkey)
	return combat:execute(creature, variant)
end
