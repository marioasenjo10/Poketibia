-- Pruebas de la progresion nueva (solo GM):
--   /progreso estado      -> tarea activa y tope de nivel
--   /progreso saltar      -> completa la tarea activa (da su recompensa)
--   /progreso reiniciar   -> vuelve a empezar la intro (no quita Pokemon ni objetos)
function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end
	param = (param or ""):lower()
	if param == "reiniciar" then
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
