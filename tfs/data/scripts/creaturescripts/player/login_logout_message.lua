local loginMessage = CreatureEvent("loginMessage")

function loginMessage.onLogin(player)
	local client = player:getClient()
	print(player:getName() .. " has logged in. (client " .. client.version .. ", os " .. client.os .. ")")
	return true
end

loginMessage:register()

local logoutMessage = CreatureEvent("logoutMessage")

function logoutMessage.onLogout(player)
	print(player:getName() .. " has logged out.")
	return true
end

logoutMessage:register()
