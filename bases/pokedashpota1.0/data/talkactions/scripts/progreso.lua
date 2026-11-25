-- Pruebas de la progresion nueva (solo GM):
--   /progreso estado      -> tarea activa y tope de nivel
--   /progreso saltar      -> completa la tarea activa (da su recompensa)
--   /progreso reiniciar   -> vuelve a empezar la intro (no quita Pokemon ni objetos)
--   /progreso ir misty    -> salta a esa tarea (anteriores hechas, medallas previas puestas)
--   /progreso tareas      -> lista de ids de tareas
--   /progreso nivel 30    -> sube al nivel indicado (respeta el tope de la historia; no baja)
-- Tambien lo pueden usar las cuentas de prueba de TEST_ACCOUNTS, aunque no sean GM.
-- cuentas de prueba (servidor local) que pueden usar el comando sin ser GM
local TEST_ACCOUNTS = {claudetest1 = true}

local function isTestAccount(player)
	local resultId = db.storeQuery("SELECT `name` FROM `accounts` WHERE `id` = " .. player:getAccountId())
	if not resultId then
		return false
	end
	local name = result.getDataString(resultId, "name")
	result.free(resultId)
	return TEST_ACCOUNTS[name:lower()] == true
end

function onSay(player, words, param)
	if not player:getGroup():getAccess() and not isTestAccount(player) then
		return true
	end
	param = (param or ""):lower()
	local jumpId = param:match("^ir%s+(%S+)$")
	if jumpId then
		if progressionJumpTo(player, jumpId) then
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Progresion: ahora en la tarea " .. jumpId .. ". Si cambia el tope de nivel, ajusta el nivel con /setlevel.")
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "No existe la tarea '" .. jumpId .. "'. Di /progreso tareas para ver la lista.")
		end
	elseif param:match("^nivel%s+(%d+)$") then
		local level = math.min(tonumber(param:match("^nivel%s+(%d+)$")), 200)
		local missing = getNeededExp(level) - player:getExperience()
		if missing > 0 then
			player:addExperience(missing, false)
		end
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Nivel actual: " .. player:getLevel() ..
			(player:getLevel() < level and " (lo limita el tope de nivel de la historia)" or ""))
	elseif param == "tareas" then
		player:showTextDialog(2263, "Tareas de la historia (para /progreso ir <id>):

" .. table.concat(progressionTaskIds(), "
"))
	elseif param == "reiniciar" then
		progressionSetupNewPlayer(player)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Progresion reiniciada.")
	elseif param == "saltar" then
		local index, task = progressionGetActiveTask(player)
		if not index then
			player:sendTextMessage(MESSAGE_INFO_DESCR, "No hay tarea activa.")
		else
			player:setStorageValue(PROGRESSION_TASK_PROGRESS + index, task.count or 1)
			if task.kind == "talk" then
				player:setStorageValue(PROGRESSION_STARTER_STORAGE, 1)
			end
			progressionForceComplete(player, index)
		end
	else
		local index, task = progressionGetActiveTask(player)
		local cap = progressionGetLevelCap(player)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Progresion: " .. (player:isOnProgression() and "si" or "no") ..
			" | tarea: " .. (task and (index .. " " .. task.id) or "ninguna") ..
			" | tope: " .. (cap and cap.maxLevel or "sin tope"))
	end
	return false
end
