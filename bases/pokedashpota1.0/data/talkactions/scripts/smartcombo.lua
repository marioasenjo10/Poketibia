-- Smart Combo: "smartcombo 1,3,2" lanza esos ataques en orden (ver doSmartCombo en newfunctions.lua)
function onSay(player, words, param)
	doSmartCombo(player, param)
	return false
end
