-- Palancas de quests de grupo (Moltres, Annihilator): los jugadores se ponen en las baldosas y uno
-- tira de la palanca. Antes hacian falta exactamente 4; ahora vale con minPlayers (huecos libres).
-- cfg = {quest = "moltres", minPlayers = 1, from = {posiciones}, to = {posiciones}, on = id, off = id}
function useQuestLever(player, item, cfg)
	if item.itemid == cfg.off then
		item:transform(cfg.on)
		return true
	end
	local quest = quests[cfg.quest]
	local group = {}
	for index, position in ipairs(cfg.from) do
		local tile = Tile(position)
		local creature = tile and tile:getTopCreature()
		if creature and creature:isPlayer() then
			if creature:getLevel() < quest.level then
				player:sendTextMessage(MESSAGE_INFO_DESCR, creature:getName() .. " necesita nivel " .. quest.level .. ".")
				return true
			end
			group[#group + 1] = {player = creature, index = index}
		end
	end
	if #group < cfg.minPlayers then
		player:sendTextMessage(MESSAGE_INFO_DESCR, cfg.minPlayers == 1 and "Ponte en una de las baldosas antes de tirar de la palanca." or
			("Hacen falta al menos " .. cfg.minPlayers .. " jugadores en las baldosas (como mucho " .. #cfg.from .. ")."))
		return true
	end
	for _, member in ipairs(group) do
		Position(cfg.from[member.index]):sendMagicEffect(CONST_ME_POFF)
		member.player:teleportTo(cfg.to[member.index], false)
		member.player:getPosition():sendMagicEffect(CONST_ME_ENERGYAREA)
	end
	item:transform(cfg.off)
	return true
end
