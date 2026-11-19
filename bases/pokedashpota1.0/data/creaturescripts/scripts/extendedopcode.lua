local OPCODE_LANGUAGE = 1
local OPCODE_SKILLBAR = 52

function onExtendedOpcode(player, opcode, buffer)
	if opcode == OPCODE_LANGUAGE then
		-- otclient language
		if buffer == 'en' or buffer == 'pt' then
			-- example, setting player language, because otclient is multi-language...
			-- player:setStorageValue(SOME_STORAGE_ID, SOME_VALUE)
		end
	elseif opcode == OPCODE_SKILLBAR then
		-- Smart Combo: el cliente manda el numero del ataque (1..12)
		local i = tonumber(buffer)
		if i and i >= 1 and i <= #moveWords and i == math.floor(i) then
			doSummonMove(player, i)
		end
	elseif opcode == OPCODE_POKEDEX then
		onPokedexOpcode(player, buffer)
	end
end
