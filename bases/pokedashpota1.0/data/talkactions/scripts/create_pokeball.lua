function onSay(player, words, param)
if not player:getGroup():getAccess() then
return true
end

if player:getAccountType() < ACCOUNT_TYPE_GOD then
return false
end

local split = param:split(",")
local name = (split[1] or ""):match("^%s*(.-)%s*$")
if name == "" or not MonsterType(name) then
player:sendCancelMessage("Pokemon not found.")
return false
end

name = firstToUpper(name)
local level = tonumber(split[2]) or 1
local boost = tonumber(split[3]) or 0

doAddPokeball(player:getId(), name, level, boost, getBallKey(balls.ultraball.usedOn), false, 0)
player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
return true
end
