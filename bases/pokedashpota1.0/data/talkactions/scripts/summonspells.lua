function onSay(player, words, param)
	for i = 1, #moveWords do
		if words == moveWords[i] then
			doSummonMove(player, i)
			break
		end
	end
	return false
end
