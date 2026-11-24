local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_NONE)
combat:setParameter(COMBAT_PARAM_AGGRESSIVE, false)
combat:setParameter(COMBAT_PARAM_EFFECT, 745)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))

local sleepDuration = 5000
local sleepTickInterval = 250
local sleepEffectEveryTicks = 4
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

-- Mientras duerme, el salvaje no puede tener objetivo: se guardan los objetivos
-- que tenia y se le quitan, para que no ataque. Al despertar se restauran.
local function holdTarget(target, state)
	target:setTarget(nil)
	local targets = target:getTargetList()
	for i = 1, #targets do
		local current = targets[i]
		if current then
			state.saved[current:getId()] = true
			target:removeTarget(current)
		end
	end
end

local function wakeTarget(targetId, token)
	local state = sleepingTargets[targetId]
	if not state or state.token ~= token then
		return
	end
	sleepingTargets[targetId] = nil

	local target = Monster(targetId)
	if not target then
		return
	end

	-- los objetivos se devuelven antes de quitar la paralisis para que el monstruo no se quede inactivo
	local restored
	for savedId in pairs(state.saved) do
		local creature = Creature(savedId)
		if creature then
			target:addTarget(creature)
			restored = restored or creature
		end
	end
	target:removeCondition(CONDITION_PARALYZE, CONDITIONID_COMBAT, sleepConditionSubId)
	if restored then
		target:selectTarget(restored)
	end
	target:searchTarget()
end

local function sleepTick(targetId, token, tick)
	local state = sleepingTargets[targetId]
	if not state or state.token ~= token then
		return
	end

	local target = Monster(targetId)
	if not target then
		sleepingTargets[targetId] = nil
		return
	end

	holdTarget(target, state)
	if tick % sleepEffectEveryTicks == 0 then
		target:getPosition():sendMagicEffect(CONST_ME_SLEEP)
	end
	addEvent(sleepTick, sleepTickInterval, targetId, token, tick + 1)
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
	local previous = sleepingTargets[targetId]
	sleepingTargets[targetId] = {token = token, saved = previous and previous.saved or {}}
	sleepTick(targetId, token, 0)
	addEvent(wakeTarget, sleepDuration, targetId, token)
end

combat:setCallback(CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(creature, variant, isHotkey)
	return combat:execute(creature, variant)
end
