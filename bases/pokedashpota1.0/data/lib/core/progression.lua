-- Progresion del inicio del juego (estilo serie Pokemon):
--   * el jugador nuevo aparece en Pueblo Paleta, sin Pokemon, junto al Profesor Oak
--   * Oak le deja elegir entre Bulbasaur, Charmander, Squirtle y Pikachu (ventanas con botones)
--   * tareas de historia encadenadas (panel "Tareas" del cliente, opcode 90)
--   * tope de nivel hasta ganar la medalla del gimnasio que toca
-- Solo afecta a personajes creados con este sistema (storage PROGRESSION_STORAGE = 1):
-- los personajes que ya existian siguen igual.

progressionNewStartEnabled = true
progressionIntroScene = true -- intro con ilustraciones en el cliente (game_intro); false = ventanas modales

PROGRESSION_STORAGE = 96000        -- 1 = personaje con la progresion nueva
PROGRESSION_STARTER_STORAGE = 96001 -- 1 = ya tiene su Pokemon inicial
PROGRESSION_CAPMSG_STORAGE = 96002  -- os.time() del ultimo aviso de tope de nivel
PROGRESSION_TASK_STATE = 96100     -- + indice de tarea: 1 activa, 2 completada
PROGRESSION_TASK_PROGRESS = 96300  -- + indice de tarea: progreso (capturas...)

OPCODE_TASKS = 90
OPCODE_INTRO = 91 -- escena de Oak en el cliente (modules/game_intro)

-- Posicion del Profesor Oak (map-spawn.xml) y ciudad inicial
progressionOakPosition = Position(720, 1193, 7)
progressionStartTown = "pallet"

-- Pokemon iniciales: nombre, tipo y descripcion corta para la ventana de eleccion
progressionStarters = {
	{name = "Bulbasaur", types = "Planta/Veneno", text = "Resistente y facil de llevar. Buena opcion contra Brock."},
	{name = "Charmander", types = "Fuego", text = "Mucho dano, pero contra los Pokemon de Roca lo pasara mal."},
	{name = "Squirtle", types = "Agua", text = "Defensa alta y equilibrado. El mas comodo contra Brock."},
	{name = "Pikachu", types = "Electrico", text = "Rapido y valiente. La electricidad no afecta a los de tipo Tierra."},
}
progressionStarterItems = {
	{id = 26662, count = 100}, -- poke balls
	{id = 27642, count = 20},  -- pociones
}

-- Tope de nivel: hasta tener la medalla no se pasa de maxLevel
progressionLevelCaps = {
	{badge = "boulderBadge", maxLevel = 20, medal = "Medalla Roca", leader = "Brock", city = "Ciudad Plateada"},
}

-- Tareas de historia, en orden. kind: talk | reach | catch | defeat | badge
--   catch: species = {nombres} o types = {tipos}; count = cuantas capturas
--   defeat: species = {nombres} (sin species vale cualquier salvaje); count = cuantas derrotas
--   reach: town = parte del nombre de la ciudad (minusculas)
--   badge: badge = clave en quests (newfunctions.lua)
-- reward: exp, money (banco) e items {id, count}
progressionTasks = {
	{
		id = "oak_lab", kind = "talk", giver = "Profesor Oak",
		title = "El laboratorio del Profesor Oak",
		text = "Habla con el Profesor Oak en su laboratorio de Pueblo Paleta. Tiene algo importante para ti.",
		rewardText = "Tu primer Pokemon, 100 Poke Balls y 20 pociones",
	},
	{
		id = "julie_meet", kind = "talk", npc = "Julie", giver = "Profesor Oak",
		title = "Conoce a Julie",
		text = "Julie, del club de capturadores, esta en el Centro Pokemon de Pueblo Paleta. Ella te ensenara a capturar Pokemon. Ve a hablar con ella (di hi).",
		reward = {exp = 500},
	},
	{
		id = "julie_rattata", kind = "catch", species = {"Rattata"}, count = 2, giver = "Julie, del club de capturadores",
		title = "Primeras capturas",
		text = "Debilita a un Rattata y lanzale una Poke Ball. Captura 2. Corretean por la hierba de las afueras de Pueblo Paleta.",
		reward = {exp = 4000, money = 600, items = {{id = 26659, count = 80}}},
	},
	{
		id = "julie_bellsprout", kind = "catch", species = {"Bellsprout"}, count = 2, giver = "Julie, del club de capturadores",
		title = "Captura plantas",
		text = "Captura 2 Bellsprout. Crecen en la hierba alrededor de Pueblo Paleta y en la Ruta 2.",
		reward = {exp = 5000, money = 900, items = {{id = 26688, count = 30}, {id = 27634, count = 1}}},
		onComplete = function(player)
			-- el NPC Julie pasa directamente a sus tareas diarias
			if player:getStorageValue(storageCatchQuest) < 2 then
				player:setStorageValue(storageCatchQuest, 2)
			end
		end,
	},
	{
		id = "go_viridian", kind = "reach", town = "viridian", giver = "Profesor Oak",
		title = "Rumbo a Ciudad Verde",
		text = "Ya sabes capturar. Sal de Pueblo Paleta por la Ruta 1, hacia el norte, hasta llegar a Ciudad Verde.",
		reward = {exp = 5000, money = 500},
	},
	{
		-- desactivada: justo despues de capturar 2 Bellsprout pedia otro Pokemon de tipo Planta/Agua...
		-- Se deja en la lista (con disabled) para no mover los indices de las tareas guardadas.
		id = "oak_counter", disabled = true, kind = "catch", types = {"water", "grass", "fighting", "ground"}, count = 1, giver = "Profesor Oak",
		title = "Preparate para Brock",
		text = "Brock, el Lider de Ciudad Plateada, usa Pokemon de tipo Roca. Captura un Pokemon de tipo Agua, Planta, Lucha o Tierra (Bellsprout, Oddish, Mankey, Sandshrew...).",
		reward = {exp = 5000, money = 500},
	},
	{
		id = "forest_defeat", kind = "defeat", count = 25, giver = "Guardabosques del Bosque Verde",
		title = "Limpia el Bosque Verde",
		text = "Los Pokemon salvajes del Bosque Verde estan muy alterados. Derrota a 25 en la Ruta 2 o en el bosque, camino de Ciudad Plateada.",
		reward = {exp = 10000, money = 800, items = {{id = 27642, count = 10}}},
	},
	{
		id = "go_pewter", kind = "reach", town = "pewter", giver = "Profesor Oak",
		title = "Ciudad Plateada",
		text = "Sigue hacia el norte por la Ruta 2 y el Bosque Verde hasta Ciudad Plateada.",
		reward = {exp = 8000, money = 1000},
	},
	{
		id = "pewter_geodude", kind = "defeat", species = {"Geodude"}, count = 15, giver = "Brock, Lider de Gimnasio",
		title = "Entrenamiento de roca",
		text = "Antes de retarme, demuestra que sabes luchar contra el tipo Roca: derrota 15 Geodude en los alrededores de Ciudad Plateada.",
		reward = {exp = 14000, money = 1000},
	},
	{
		id = "brock", kind = "badge", badge = "boulderBadge", giver = "Brock, Lider de Gimnasio",
		title = "La Medalla Roca",
		text = "Desafia a Brock en el Gimnasio de Ciudad Plateada. Sus Pokemon son Geodude y Onix. Recomendado: nivel 18-20 y un Pokemon de tipo Agua, Planta o Lucha.",
		reward = {exp = 0, money = 3000},
		rewardText = "Medalla Roca y sin tope de nivel 20",
	},
}

-- dano extra de los Pokemon de gimnasio (id de la criatura -> multiplicador)
gymSummonDamage = gymSummonDamage or {}

local function clean(text)
	return (tostring(text or ""):gsub("[|\n\r]", " "))
end

local function formatNumber(n)
	local s = tostring(math.floor(n))
	local result = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (result:gsub("^%.", ""))
end

local function speciesName(name)
	name = tostring(name or ""):lower()
	if name:sub(1, 6) == "shiny " then
		name = name:sub(7)
	end
	return name
end

function Player.isOnProgression(self)
	return self:getStorageValue(PROGRESSION_STORAGE) == 1
end

local function taskState(player, index)
	return player:getStorageValue(PROGRESSION_TASK_STATE + index)
end

local function taskProgress(player, index)
	return math.max(0, player:getStorageValue(PROGRESSION_TASK_PROGRESS + index))
end

function progressionGetActiveTask(player)
	for index, task in ipairs(progressionTasks) do
		if taskState(player, index) == 1 then
			return index, task
		end
	end
	return nil
end

local function rewardText(task)
	if task.rewardText then
		return task.rewardText
	end
	local parts = {}
	local reward = task.reward or {}
	if reward.exp and reward.exp > 0 then
		parts[#parts + 1] = formatNumber(reward.exp) .. " exp"
	end
	if reward.money and reward.money > 0 then
		parts[#parts + 1] = formatNumber(reward.money) .. " $"
	end
	for _, item in ipairs(reward.items or {}) do
		local itemType = ItemType(item.id)
		local name = itemType and itemType:getName() or ("item " .. item.id)
		parts[#parts + 1] = item.count .. "x " .. name
	end
	return table.concat(parts, ", ")
end

local function findTown(key)
	key = key:lower()
	for _, town in ipairs(Game.getTowns()) do
		if town:getName():lower():find(key, 1, true) then
			return town
		end
	end
	return nil
end

-- ===================== Envio al cliente =====================
-- Formato: primera linea "cap|nivel|texto" (nivel 0 = sin tope), despues una tarea por linea:
-- indice|estado(1 activa, 2 hecha)|tipo|quien|titulo|texto|progreso|total|recompensa
function Player.sendTasks(self)
	if not self:isOnProgression() then
		return
	end
	-- si la tarea activa se ha desactivado, se salta a la siguiente (sin recompensa)
	local activeIndex, activeTask = progressionGetActiveTask(self)
	if activeIndex and activeTask.disabled then
		self:setStorageValue(PROGRESSION_TASK_STATE + activeIndex, 2)
		progressionActivateNext(self, activeIndex)
		return
	end
	local lines = {}
	local cap = progressionGetLevelCap(self)
	if cap then
		lines[1] = "cap|" .. cap.maxLevel .. "|" .. clean("Nivel maximo " .. cap.maxLevel .. " hasta conseguir la " .. cap.medal)
	else
		lines[1] = "cap|0|"
	end
	for index, task in ipairs(progressionTasks) do
		local state = taskState(self, index)
		if (state == 1 or state == 2) and not task.disabled then
			local total = task.count or 1
			local progress = state == 2 and total or taskProgress(self, index)
			lines[#lines + 1] = table.concat({index, state, task.kind, clean(task.giver), clean(task.title),
				clean(task.text), progress, total, clean(rewardText(task))}, "|")
		end
	end
	self:sendExtendedOpcode(OPCODE_TASKS, table.concat(lines, "\n"))
end

-- ===================== Estados =====================
local checkTaskDone

local function activateTask(player, index)
	local task = progressionTasks[index]
	if not task then
		return
	end
	player:setStorageValue(PROGRESSION_TASK_STATE + index, 1)
	player:setStorageValue(PROGRESSION_TASK_PROGRESS + index, 0)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nueva tarea: " .. task.title)
	if not checkTaskDone(player, index) then
		player:sendTasks()
	end
end

local function completeTask(player, index)
	local task = progressionTasks[index]
	if not task or taskState(player, index) ~= 1 then
		return
	end
	player:setStorageValue(PROGRESSION_TASK_STATE + index, 2)
	local reward = task.reward or {}
	if reward.money and reward.money > 0 then
		player:addMoney(reward.money)
	end
	for _, item in ipairs(reward.items or {}) do
		player:addItem(item.id, item.count)
	end
	if reward.exp and reward.exp > 0 then
		player:addExperience(reward.exp, true)
	end
	if task.onComplete then
		task.onComplete(player)
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Tarea completada: " .. task.title .. "! Recompensa: " .. rewardText(task))
	player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
	progressionActivateNext(player, index)
end

-- activa la siguiente tarea que no este desactivada
function progressionActivateNext(player, index)
	local nextIndex = index + 1
	while progressionTasks[nextIndex] and progressionTasks[nextIndex].disabled do
		player:setStorageValue(PROGRESSION_TASK_STATE + nextIndex, 2)
		nextIndex = nextIndex + 1
	end
	if progressionTasks[nextIndex] then
		activateTask(player, nextIndex)
	else
		player:sendTasks()
	end
end

-- true si la tarea con ese id ya esta hecha (o el jugador no sigue la historia)
function progressionIsTaskDone(player, id)
	if not player:isOnProgression() then
		return true
	end
	for index, task in ipairs(progressionTasks) do
		if task.id == id then
			return taskState(player, index) == 2
		end
	end
	return true
end

function progressionForceComplete(player, index)
	completeTask(player, index)
end

-- comprueba si una tarea activa ya esta cumplida (al activarla puede estarlo)
checkTaskDone = function(player, index)
	local task = progressionTasks[index]
	if not task or taskState(player, index) ~= 1 then
		return false
	end
	local done = false
	if task.kind == "reach" then
		local town = findTown(task.town)
		done = town and player:hasDiscoveredTown(town:getId()) or false
	elseif task.kind == "badge" then
		local quest = quests[task.badge]
		done = quest and player:getStorageValue(quest.prizes[1].uid) > 0 or false
	elseif task.kind == "catch" or task.kind == "defeat" then
		done = taskProgress(player, index) >= (task.count or 1)
	end
	if done then
		completeTask(player, index)
	end
	return done
end

function progressionStart(player)
	player:setStorageValue(PROGRESSION_STORAGE, 1)
	for index = 1, #progressionTasks do
		player:setStorageValue(PROGRESSION_TASK_STATE + index, -1)
		player:setStorageValue(PROGRESSION_TASK_PROGRESS + index, -1)
	end
	player:setStorageValue(PROGRESSION_STARTER_STORAGE, -1)
	activateTask(player, 1)
end

-- ===================== Eventos del juego =====================
function progressionOnCatch(player, name)
	if not player:isOnProgression() then
		return
	end
	local index, task = progressionGetActiveTask(player)
	if not index or task.kind ~= "catch" then
		return
	end
	local species = speciesName(name)
	local matches = false
	if task.species then
		for _, wanted in ipairs(task.species) do
			if wanted:lower() == species then
				matches = true
				break
			end
		end
	end
	if not matches and task.types then
		local monsterType = MonsterType(name)
		if monsterType then
			local race1, race2 = monsterType:getRaceName(), monsterType:getRace2Name()
			for _, wanted in ipairs(task.types) do
				if race1 == wanted or race2 == wanted then
					matches = true
					break
				end
			end
		end
	end
	if not matches then
		return
	end
	local progress = taskProgress(player, index) + 1
	player:setStorageValue(PROGRESSION_TASK_PROGRESS + index, progress)
	local total = task.count or 1
	if progress < total then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, task.title .. ": " .. progress .. "/" .. total)
		player:sendTasks()
	else
		checkTaskDone(player, index)
	end
end

function progressionOnCatchById(playerId, name)
	local player = Player(playerId)
	if player then
		progressionOnCatch(player, name)
	end
end

-- un salvaje derrotado por el jugador o por su Pokemon (creaturescripts/scripts/corpselevel.lua)
function progressionOnDefeat(player, name)
	if not player:isOnProgression() then
		return
	end
	local index, task = progressionGetActiveTask(player)
	if not index or task.kind ~= "defeat" then
		return
	end
	if task.species then
		local species = speciesName(name)
		local matches = false
		for _, wanted in ipairs(task.species) do
			if wanted:lower() == species then
				matches = true
				break
			end
		end
		if not matches then
			return
		end
	end
	local progress = taskProgress(player, index) + 1
	player:setStorageValue(PROGRESSION_TASK_PROGRESS + index, progress)
	local total = task.count or 1
	if progress < total then
		if progress % 5 == 0 or total - progress <= 3 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, task.title .. ": " .. progress .. "/" .. total)
		end
		player:sendTasks()
	else
		checkTaskDone(player, index)
	end
end

-- Julie (npc/scripts/catcher.lua) al saludar: devuelve true si se encarga ella de la conversacion
local MODAL_JULIE = 6110
function progressionOnJulieGreet(player)
	if not player:isOnProgression() then
		return false
	end
	local index, task = progressionGetActiveTask(player)
	if not index then
		return false
	end
	local message
	if task.id == "julie_meet" then
		completeTask(player, index)
		message = "Hola! Asi que tu eres el nuevo entrenador del Profesor Oak. Yo soy Julie, del club de capturadores.\n\n" ..
			"Capturar es facil: debilita a un Pokemon salvaje y, cuando caiga, lanza una Poke Ball sobre el. " ..
			"Cuanto mejor sea la Poke Ball, mas facil sera.\n\n" ..
			"Empieza por algo sencillo: captura 2 Rattata.\n\n" ..
			"Truco: abre tu Pokedex (tecla E o el boton de la barra de abajo), busca Rattata y pulsa la lupa. " ..
			"Te marcara en el mapa donde aparece. Al sur de Pueblo Paleta hay muchos!"
	elseif task.id == "julie_rattata" or task.id == "julie_bellsprout" then
		local where = task.id == "julie_rattata" and "Los Rattata abundan al sur de Pueblo Paleta." or
			"Los Bellsprout crecen al norte de Pueblo Paleta, camino de la Ruta 1."
		message = "Como vas? Te faltan " .. ((task.count or 1) - taskProgress(player, index)) .. " " ..
			task.species[1] .. ". Recuerda: debilitalo y lanza la Poke Ball sobre el.\n\n" .. where ..
			" Si no lo encuentras, abre la Pokedex, busca " .. task.species[1] .. " y pulsa la lupa para verlo en el mapa."
	else
		return false
	end
	local window = ModalWindow(MODAL_JULIE, "Julie", message)
	window:addButton(1, "Entendido")
	window:setDefaultEnterButton(1)
	window:setDefaultEscapeButton(1)
	window:sendToPlayer(player)
	return true
end

function progressionOnTownDiscovered(player)
	if not player:isOnProgression() then
		return
	end
	local index, task = progressionGetActiveTask(player)
	if index and task.kind == "reach" then
		checkTaskDone(player, index)
	end
end

function progressionOnBadge(player, badgeKey)
	if not player:isOnProgression() then
		return
	end
	local index, task = progressionGetActiveTask(player)
	if index and task.kind == "badge" and task.badge == badgeKey then
		checkTaskDone(player, index)
	else
		player:sendTasks() -- el tope de nivel ha cambiado
	end
end

-- ===================== Tope de nivel =====================
function progressionGetLevelCap(player)
	if not player:isOnProgression() then
		return nil
	end
	for _, cap in ipairs(progressionLevelCaps) do
		local quest = quests[cap.badge]
		if quest and player:getStorageValue(quest.prizes[1].uid) <= 0 then
			return cap
		end
	end
	return nil
end

function progressionCapExperience(player, exp)
	if not exp or exp <= 0 then
		return exp
	end
	local cap = progressionGetLevelCap(player)
	if not cap then
		return exp
	end
	local room = (getNeededExp(cap.maxLevel + 1) - 1) - player:getExperience()
	if exp >= room then
		local now = os.time()
		if now - player:getStorageValue(PROGRESSION_CAPMSG_STORAGE) >= 300 then
			player:setStorageValue(PROGRESSION_CAPMSG_STORAGE, now)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Has llegado al nivel " .. cap.maxLevel ..
				", el maximo sin la " .. cap.medal .. ". Derrota a " .. cap.leader .. " en " .. cap.city .. " para seguir subiendo.")
		end
		return math.max(0, room)
	end
	return exp
end

-- ===================== Jugador nuevo e intro con Oak =====================
local function findFreeTileNear(player, center, maxRadius)
	for radius = 1, maxRadius do
		for dx = -radius, radius do
			for dy = -radius, radius do
				if math.max(math.abs(dx), math.abs(dy)) == radius then
					local pos = Position(center.x + dx, center.y + dy, center.z)
					local tile = Tile(pos)
					if tile and tile:getGround() and tile:queryAdd(player) == RETURNVALUE_NOERROR then
						return pos
					end
				end
			end
		end
	end
	return nil
end

function progressionSetupNewPlayer(player)
	progressionStart(player)
	local town = findTown(progressionStartTown)
	if town then
		player:setTown(town)
	end
	local destination = findFreeTileNear(player, progressionOakPosition, 3) or (town and town:getTemplePosition())
	if destination then
		player:teleportTo(destination)
		destination:sendMagicEffect(CONST_ME_TELEPORT)
	end
	addEvent(function(playerId)
		local p = Player(playerId)
		if p and progressionNeedsStarter(p) then
			progressionShowOakIntro(p)
		end
	end, 3000, player:getId())
end

function progressionNeedsStarter(player)
	return player:isOnProgression() and player:getStorageValue(PROGRESSION_STARTER_STORAGE) ~= 1
end

-- ventanas: 6101 bienvenida, 6102 la aventura, 6103 eleccion, 6104 confirmacion, 6105 despedida
local MODAL_WELCOME, MODAL_ADVENTURE, MODAL_CHOOSE, MODAL_CONFIRM, MODAL_FAREWELL = 6101, 6102, 6103, 6104, 6105
local BUTTON_OK, BUTTON_CANCEL = 1, 2
local pendingStarter = {}

local function sendModal(player, id, message, buttons, choices)
	local window = ModalWindow(id, "Profesor Oak", message)
	for _, button in ipairs(buttons) do
		window:addButton(button[1], button[2])
	end
	for _, choice in ipairs(choices or {}) do
		window:addChoice(choice[1], choice[2])
	end
	window:setDefaultEnterButton(buttons[1][1])
	window:setDefaultEscapeButton(buttons[#buttons][1])
	window:sendToPlayer(player)
end

-- escena de la intro en el cliente (game_intro): textos e iniciales los manda el servidor
-- formato: show|textoBienvenida|textoAventura|nombre;tipos;texto|nombre;tipos;texto...
local INTRO_WELCOME = "Hola! Bienvenido al mundo de los Pokemon. Me llamo Oak, pero todos me llaman el Profesor Pokemon.\n\n" ..
	"Este mundo esta lleno de criaturas llamadas Pokemon. Algunos las tienen de companeras, otros combaten con ellas... y yo me dedico a estudiarlas."
local INTRO_ADVENTURE = "Hoy empieza tu aventura. Tu objetivo: recorrer Kanto ciudad a ciudad, vencer a los Lideres de Gimnasio y ganar sus medallas.\n\n" ..
	"Pero no puedes ir solo: la hierba alta esta llena de Pokemon salvajes. Tengo cuatro Pokemon conmigo. Elige a tu companero."

function progressionShowOakIntro(player)
	if progressionIntroScene then
		local parts = {"show", INTRO_WELCOME, INTRO_ADVENTURE}
		for _, starter in ipairs(progressionStarters) do
			parts[#parts + 1] = starter.name .. ";" .. starter.types .. ";" .. starter.text
		end
		player:sendExtendedOpcode(OPCODE_INTRO, table.concat(parts, "|"))
		return
	end
	sendModal(player, MODAL_WELCOME,
		"Hola! Bienvenido al mundo de los Pokemon.\nMe llamo Oak, pero todos me llaman el Profesor Pokemon.\n\n" ..
		"Este mundo esta lleno de criaturas llamadas Pokemon.\nAlgunos las tienen de companeras, otros combaten con ellas...\ny yo me dedico a estudiarlas.",
		{{BUTTON_OK, "Continuar"}})
end

local function showAdventure(player)
	sendModal(player, MODAL_ADVENTURE,
		"Hoy empieza tu aventura. Tu objetivo: recorrer Kanto\nciudad a ciudad, vencer a los Lideres de Gimnasio\ny ganar sus medallas.\n\n" ..
		"Pero no puedes ir solo: la hierba alta esta llena\nde Pokemon salvajes. Tengo cuatro Pokemon conmigo.\nElige a tu companero.",
		{{BUTTON_OK, "Elegir Pokemon"}})
end

local function showChoose(player)
	local choices = {}
	for i, starter in ipairs(progressionStarters) do
		choices[#choices + 1] = {i, starter.name .. "  -  " .. starter.types}
	end
	sendModal(player, MODAL_CHOOSE, "Cual sera tu primer Pokemon?\nSeleccionalo y pulsa Elegir.",
		{{BUTTON_OK, "Elegir"}, {BUTTON_CANCEL, "Mas tarde"}}, choices)
end

local function showConfirm(player, index)
	local starter = progressionStarters[index]
	pendingStarter[player:getId()] = index
	sendModal(player, MODAL_CONFIRM, "Asi que eliges a " .. starter.name .. ", de tipo " .. starter.types .. ".\n" ..
		starter.text .. "\n\nSeguro que quieres a " .. starter.name .. "?",
		{{BUTTON_OK, "Si, lo quiero"}, {BUTTON_CANCEL, "Mejor otro"}})
end

local giveStarter

-- respuestas de la escena del cliente: "progressionintro elegir <n>" y "progressionintro aspecto"
function progressionIntroCommand(player, param)
	local command, arg = (param or ""):match("^(%S+)%s*(%S*)")
	if command == "elegir" then
		local index = tonumber(arg)
		if index and progressionStarters[index] and progressionNeedsStarter(player) then
			giveStarter(player, index)
		end
	elseif command == "aspecto" then
		player:sendOutfitWindow()
	elseif command == "abrir" and progressionNeedsStarter(player) then
		progressionShowOakIntro(player)
	end
end

giveStarter = function(player, index)
	local starter = progressionStarters[index]
	if not starter or not progressionNeedsStarter(player) then
		return false
	end
	local name = starter.name
	local monsterType = MonsterType(name)
	if not monsterType then
		print("WARNING! Progression: starter " .. name .. " no existe.")
		return false
	end
	local maxHealth = math.floor(monsterType:getMaxHealth() * statusGainFormula(player:getLevel(), 0, 0, 0) * getPokemonShinyStatMultiplier(name))
	if not player:getSlotItem(CONST_SLOT_BACKPACK) then
		player:addItem(1988, 1, false, CONST_SLOT_BACKPACK)
	end
	player:checkPokemonBelt()
	local container = player:getPokemonBelt() or player:getSlotItem(CONST_SLOT_BACKPACK)
	local ball = container and container:addItem(26661, 1)
	if not ball then
		print("WARNING! Player " .. player:getName() .. " without initial pokeball.")
		return false
	end
	ball:setSpecialAttribute("pokeName", name)
	ball:setSpecialAttribute("pokeBoost", 0)
	ball:setSpecialAttribute("pokeMaxHealth", maxHealth)
	ball:setSpecialAttribute("pokeHealth", maxHealth)
	ball:setSpecialAttribute("pokeLove", 0)
	for _, item in ipairs(progressionStarterItems) do
		player:addItem(item.id, item.count)
	end
	player:setStorageValue(PROGRESSION_STARTER_STORAGE, 1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	if player.refreshPokemonBar then
		player:refreshPokemonBar({}, {})
	end
	-- la primera tarea (hablar con Oak) queda hecha
	if taskState(player, 1) == 1 then
		completeTask(player, 1)
	end
	local farewell = name .. " parece muy contento de ir contigo!\n\n" ..
		"Te doy tambien Poke Balls y pociones. Antes de salir a la hierba, ve a ver a Julie al Centro Pokemon de Pueblo Paleta: " ..
		"ella te ensenara a capturar.\n\nTus objetivos estan en el panel de Tareas (barra superior). Ah, y una ultima cosa: como te ves?"
	if progressionIntroScene then
		player:sendExtendedOpcode(OPCODE_INTRO, "done|" .. name .. "|" .. farewell)
		return true
	end
	sendModal(player, MODAL_FAREWELL, name .. " parece muy contento de ir contigo!\n\n" ..
		"Te doy tambien Poke Balls y pociones. Para capturar\nun Pokemon salvaje, debilitalo y lanzale una Poke Ball.\n\n" ..
		"Tus objetivos estan en el panel de Tareas (barra superior).\nPrimera parada: Ciudad Verde, al norte por la Ruta 1.\n\n" ..
		"Ah, una ultima cosa: como te ves? Elige tu aspecto.",
		{{BUTTON_OK, "Elegir aspecto"}})
	return true
end

function progressionOnModalWindow(player, modalWindowId, buttonId, choiceId)
	if modalWindowId < MODAL_WELCOME or modalWindowId > MODAL_FAREWELL then
		return false
	end
	if modalWindowId == MODAL_FAREWELL then
		-- al acabar la intro, el jugador elige su aspecto (antes salia a la vez que Oak)
		player:sendOutfitWindow()
		return true
	end
	if not progressionNeedsStarter(player) then
		return true
	end
	if modalWindowId == MODAL_WELCOME then
		showAdventure(player)
	elseif modalWindowId == MODAL_ADVENTURE then
		showChoose(player)
	elseif modalWindowId == MODAL_CHOOSE then
		if buttonId == BUTTON_OK and progressionStarters[choiceId] then
			showConfirm(player, choiceId)
		elseif buttonId == BUTTON_OK then
			showChoose(player)
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Habla con el Profesor Oak (di hi) cuando quieras elegir tu Pokemon.")
		end
	elseif modalWindowId == MODAL_CONFIRM then
		local index = pendingStarter[player:getId()]
		pendingStarter[player:getId()] = nil
		if buttonId == BUTTON_OK and index then
			giveStarter(player, index)
		else
			showChoose(player)
		end
	end
	return true
end
