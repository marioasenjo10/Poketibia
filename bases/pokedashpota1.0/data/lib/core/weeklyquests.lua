-- Quests semanales: las de cofre (y la Liga) se pueden repetir una vez por semana. El premio crece
-- con el nivel de la quest; la de nivel 100 (la Liga) es la referencia:
--   200.000 en el banco, ~1.000.000 de experiencia, 10 fragmentos runicos y 1 runa en blanco.
-- Los Pokemon de premio y los objetos especiales (cajas, bolsas) solo la primera vez. Las piedras,
-- como mucho weeklyStoneCap por cofre. Las monedas ya no se dan: va todo al banco.
-- Se usa en Player:giveQuestPrize (lib/core/newfunctions.lua) y en el campeon de la Liga (npc/scripts/blue.lua).

WEEKLY_SECONDS = 7 * 24 * 60 * 60

weeklyReward = {
	moneyPerLevel = 2000,       -- nivel 100 -> 200.000
	expLevels = 2,              -- experiencia = lo que pide subir este numero de niveles al nivel de la quest
	fragmentsPerLevel = 0.1,    -- nivel 100 -> 10 fragmentos
	blankRunes = 1,
	stoneCap = 3,
}

-- quests de cofre que NO se repiten (son parte de la historia)
weeklyQuestExclude = {ceruleanCave = true, mewDungeon = true}

local COIN_NAMES = {["gold coin"] = true, ["platinum coin"] = true, ["crystal coin"] = true}

function isWeeklyQuest(key, quest)
	if weeklyQuestExclude[key] then
		return false
	end
	-- las de cofre: uid de premio entre 10200 y 10299
	for _, prize in ipairs(quest.prizes or {}) do
		local uid = tonumber(prize.uid) or 0
		if uid < 10200 or uid > 10299 then
			return false
		end
	end
	return true
end

-- cuando se puede volver a hacer (0 = ya)
function weeklyQuestWait(player, quest)
	local last = 0
	for _, prize in ipairs(quest.prizes) do
		last = math.max(last, player:getStorageValue(prize.uid))
	end
	-- valor antiguo (1 = hecha antes de existir las semanales): se puede repetir ya
	if last <= 1 then
		return 0
	end
	return math.max(0, last + WEEKLY_SECONDS - os.time())
end

function formatWait(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	if days > 0 then
		return days .. " d y " .. hours .. " h"
	end
	return hours .. " h y " .. math.ceil((seconds % 3600) / 60) .. " min"
end

local function formatNumber(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", ""))
end

-- objetos del premio de una quest semanal: piedras limitadas, sin monedas y lo especial solo la 1a vez
function weeklyFilterItems(items, firstTime)
	local result = {}
	for _, entry in ipairs(items or {}) do
		local name = tostring(entry.item):lower()
		if not COIN_NAMES[name] then
			if name:find("stone", 1, true) then
				result[#result + 1] = {item = entry.item, count = math.min(entry.count, weeklyReward.stoneCap)}
			elseif firstTime then
				result[#result + 1] = entry
			end
		end
	end
	return result
end

function giveWeeklyReward(player, level, title)
	level = math.max(1, level)
	local money = math.floor(weeklyReward.moneyPerLevel * level)
	local exp = math.floor(getNeededExp(level + weeklyReward.expLevels) - getNeededExp(level))
	local fragments = math.max(1, math.floor(weeklyReward.fragmentsPerLevel * level + 0.5))
	local blanks = weeklyReward.blankRunes
	player:addMoney(money)
	player:addItem(RUNE_FRAGMENT_ID, fragments)
	player:addItem(RUNE_BLANK_ID, blanks)
	player:addExperience(exp, true)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Semanal] " .. title .. ": $" .. formatNumber(money) .. " al banco, " ..
		formatNumber(exp) .. " de experiencia, " .. fragments .. " fragmentos runicos y " .. blanks ..
		(blanks == 1 and " runa en blanco." or " runas en blanco.") .. " Vuelve dentro de 7 dias.")
end
