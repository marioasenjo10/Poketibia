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
OPCODE_TASK_DONE = 92 -- ventana de "mision completada" + la siguiente (cliente: game_tasks)

-- aspecto de quien da cada mision (para la ventana): el principio del texto "giver" -> outfit del NPC
progressionGiverOutfits = {
	{prefix = "Profesor Oak", look = {1987}},
	{prefix = "Julie", look = {138, 96, 118, 81, 95}},
	{prefix = "Brock", look = {2593}},
	{prefix = "Misty", look = {2715}},
	{prefix = "Teniente Surge", look = {2602}},
	{prefix = "Erika", look = {2598}},
	{prefix = "Sabrina", look = {2601}},
	{prefix = "Koga", look = {2595}},
	{prefix = "Blaine", look = {2591}},
	{prefix = "Giovanni", look = {2600}},
}
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
	{badge = "cascadeBadge", maxLevel = 30, medal = "Medalla Cascada", leader = "Misty", city = "Ciudad Celeste"},
	{badge = "thunderBadge", maxLevel = 40, medal = "Medalla Trueno", leader = "el Teniente Surge", city = "Ciudad Carmin"},
	{badge = "rainbowBadge", maxLevel = 50, medal = "Medalla Arcoiris", leader = "Erika", city = "Ciudad Azulona"},
	{badge = "marshBadge", maxLevel = 60, medal = "Medalla Pantano", leader = "Sabrina", city = "Ciudad Azafran"},
	{badge = "soulBadge", maxLevel = 70, medal = "Medalla Alma", leader = "Koga", city = "Ciudad Fucsia"},
	{badge = "volcanoBadge", maxLevel = 80, medal = "Medalla Volcan", leader = "Blaine", city = "Isla Canela"},
	{badge = "earthBadge", maxLevel = 90, medal = "Medalla Tierra", leader = "Giovanni", city = "Ciudad Verde"},
}

-- ===================== Experiencia =====================
-- Objetivo: ~30 minutos de juego entre gimnasios (10 niveles), contando tareas, capturas y caza.
-- Herramienta para ver el reparto por tramo: python tools/combatsim/expcurve.py [derrotas_por_minuto]
--
-- Derrotas: la experiencia de un salvaje es su experiencia base x multiplicador. El multiplicador
-- crece con el nivel del entrenador para que un Pokemon "normal" (experiencia base expReferenceBase)
-- valga siempre 1/expKillsPerLevel de un nivel. Nunca baja de los stages de data/XML/stages.xml.
--   Subes demasiado rapido al probar -> sube expKillsPerLevel. Demasiado lento -> bajalo.
expKillsPerLevel = 12
expReferenceBase = 33
-- Capturas (actions/scripts/poke/catch.lua): la primera de cada especie da esta fraccion de tu nivel
-- actual x el factor de su tier (T7 x1, T6 x2 ... T1 x8, legendario x15). Las repetidas, el 20 %.
catchExpLevelFraction = 0.10

local function experienceForLevel(level)
	return getNeededExp(level + 1) - getNeededExp(level)
end

function getExperienceMultiplier(level)
	local multiplier = Game.getExperienceStage(level)
	if expKillsPerLevel and expKillsPerLevel > 0 then
		multiplier = math.max(multiplier, experienceForLevel(level) / (expKillsPerLevel * expReferenceBase))
	end
	return multiplier
end

-- experiencia de la primera captura de una especie (sin tier = x1)
function getCatchLevelExperience(level, tierFactor)
	return math.floor(experienceForLevel(level) * catchExpLevelFraction * (tierFactor or 1))
end

-- Gimnasios de Kanto en orden: el primero sin medalla sale en el mapa como "siguiente gimnasio".
-- No es el orden oficial: Sabrina va antes que Koga porque Ciudad Fucsia queda muy lejos.
-- (opcode 75, cliente game_minimap). npc = nombre del lider en map-spawn.xml.
progressionGyms = {
	{badge = "boulderBadge", npc = "Brock", leader = "Brock", city = "Ciudad Plateada", medal = "Medalla Roca", type = "Roca"},
	{badge = "cascadeBadge", npc = "Misty", leader = "Misty", city = "Ciudad Celeste", medal = "Medalla Cascada", type = "Agua"},
	{badge = "thunderBadge", npc = "Lt. Surge", leader = "Teniente Surge", city = "Ciudad Carmin", medal = "Medalla Trueno", type = "Electrico"},
	{badge = "rainbowBadge", npc = "Erika", leader = "Erika", city = "Ciudad Azulona", medal = "Medalla Arcoiris", type = "Planta"},
	{badge = "marshBadge", npc = "Sabrina", leader = "Sabrina", city = "Ciudad Azafran", medal = "Medalla Pantano", type = "Psiquico"},
	{badge = "soulBadge", npc = "Koga", leader = "Koga", city = "Ciudad Fucsia", medal = "Medalla Alma", type = "Veneno"},
	{badge = "volcanoBadge", npc = "Blaine", leader = "Blaine", city = "Isla Canela", medal = "Medalla Volcan", type = "Fuego"},
	{badge = "earthBadge", npc = "Giovanni", leader = "Giovanni", city = "Ciudad Verde", medal = "Medalla Tierra", type = "Tierra"},
	-- con las 8 medallas, la marca del mapa senala la entrada de la Liga
	{badge = "indigoLeague", npc = "League Doorman", leader = "Liga Pokemon", city = "Meseta Anil", medal = "Alto Mando y campeon", type = ""},
}

-- Tareas de historia, en orden. kind: talk | reach | catch | defeat | badge
--   catch: species = {nombres} o types = {tipos}; count = cuantas capturas
--   defeat: species = {nombres} y/o types = {tipos} (sin ninguno vale cualquier salvaje); count = cuantas derrotas
--   (en catch y defeat con types, species sirve tambien para los puntos de "Ver en el mapa")
--   reach: town = parte del nombre de la ciudad (minusculas)
--   badge: badge = clave en quests (newfunctions.lua)
-- reward: exp, money (banco) e items {id, count}
-- map (opcional): puntos para el boton "Ver en el mapa" del panel de Tareas, {{x, y, z, texto}}.
--   Sin map: catch/defeat con species usan los spawns de la Pokedex y reach la ciudad.
-- IMPORTANTE: las tareas nuevas van siempre al FINAL (el indice es la clave guardada en storage).
progressionTasks = {
	{
		id = "oak_lab", kind = "talk", giver = "Profesor Oak",
		title = "El laboratorio del Profesor Oak",
		text = "Habla con el Profesor Oak en su laboratorio de Pueblo Paleta. Tiene algo importante para ti.",
		rewardText = "Tu primer Pokemon, 100 Poke Balls y 20 pociones",
		map = {{720, 1193, 7, "Profesor Oak"}},
	},
	{
		id = "julie_meet", kind = "talk", npc = "Julie", giver = "Profesor Oak",
		title = "Conoce a Julie",
		text = "Julie, del club de capturadores, esta en el Centro Pokemon de Pueblo Paleta. Ella te ensenara a capturar Pokemon. Ve a hablar con ella (di hi).",
		reward = {exp = 500},
		map = {{690, 1190, 7, "Julie"}},
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
		id = "forest_defeat", kind = "defeat", count = 15, giver = "Guardabosques del Bosque Verde",
		title = "Limpia el Bosque Verde",
		text = "Los Pokemon salvajes del Bosque Verde estan muy alterados. Derrota a 15 en la Ruta 2 o en el bosque, camino de Ciudad Plateada.",
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
		text = "Antes de retarme, demuestra que sabes luchar contra el tipo Roca: derrota 15 Geodude en los alrededores de Ciudad Plateada. Pulsa Ver en el mapa para saber donde estan. (Si te ves fuerte, puedes retar a Brock directamente.)",
		reward = {exp = 14000, money = 1000},
	},
	{
		id = "brock", kind = "badge", badge = "boulderBadge", giver = "Brock, Lider de Gimnasio",
		title = "La Medalla Roca",
		text = "Desafia a Brock en el Gimnasio de Ciudad Plateada. Sus Pokemon son Geodude y Onix. Recomendado: nivel 18-20 y un Pokemon de tipo Agua, Planta o Lucha.",
		reward = {exp = 0, money = 3000},
		rewardText = "Medalla Roca, sin tope de nivel 20 y +5% de dano y defensa a tus Pokemon de tipo Roca",
		map = {{699, 823, 7, "Brock, Gimnasio de Ciudad Plateada"}},
	},
	-- ===== Ruta a Ciudad Celeste (Misty) =====
	{
		id = "mtmoon_clefairy", kind = "catch", species = {"Clefairy"}, count = 1, giver = "Profesor Oak",
		title = "La leyenda de Mt. Moon",
		text = "Dicen que en Mt. Moon, al este de Ciudad Plateada, viven unos Pokemon que llegaron de la luna. Captura un Clefairy. Pulsa Ver en el mapa para saber donde buscar.",
		reward = {exp = 20000, money = 1500, items = {{id = 26659, count = 40}}},
	},
	{
		id = "go_cerulean", kind = "reach", town = "cerulean", giver = "Profesor Oak",
		title = "Rumbo a Ciudad Celeste",
		text = "Cruza Mt. Moon y sigue por la Ruta 4 hacia el este hasta Ciudad Celeste. Alli te espera Misty, la Lider de Gimnasio.",
		reward = {exp = 20000, money = 1500, items = {{id = 27642, count = 15}}},
	},
	{
		id = "cerulean_psyduck", kind = "defeat", species = {"Psyduck"}, count = 15, giver = "Misty, Lider de Gimnasio",
		title = "Entrenamiento de agua",
		text = "Antes de retarme, demuestra que sabes plantar cara al tipo Agua: derrota 15 Psyduck en los alrededores de Ciudad Celeste. Pulsa Ver en el mapa para saber donde estan. (Si te ves fuerte, puedes retar a Misty directamente.)",
		reward = {exp = 30000, money = 2000},
	},
	{
		id = "misty", kind = "badge", badge = "cascadeBadge", giver = "Misty, Lider de Gimnasio",
		title = "La Medalla Cascada",
		text = "Desafia a Misty en el Gimnasio de Ciudad Celeste. Sus Pokemon son Staryu y Starmie. Recomendado: nivel 28-30 y un Pokemon de tipo Planta o Electrico.",
		reward = {exp = 0, money = 5000},
		rewardText = "Medalla Cascada, sin tope de nivel 30 y +5% de dano y defensa a tus Pokemon de tipo Agua",
		map = {{1095, 896, 7, "Misty, Gimnasio de Ciudad Celeste"}},
	},
	-- ===== Ruta a Ciudad Carmin (Teniente Surge) =====
	{
		id = "cerulean_ground", kind = "catch", species = {"Diglett", "Sandshrew"}, count = 1, giver = "Profesor Oak",
		title = "Tierra contra el rayo",
		text = "El siguiente Lider, el Teniente Surge, usa Pokemon de tipo Electrico, y a los de tipo Tierra la electricidad no les hace nada. Al este de Ciudad Celeste hay muchos Diglett y Sandshrew: captura uno. Pulsa Ver en el mapa para saber donde estan.",
		reward = {exp = 41000, money = 2000, items = {{id = 26688, count = 20}}},
	},
	{
		id = "go_vermilion", kind = "reach", town = "vermilion", giver = "Profesor Oak",
		title = "Rumbo a Ciudad Carmin",
		text = "Ve hacia el sur, pasando por Ciudad Azafran, hasta Ciudad Carmin, el gran puerto de Kanto. Alli esta el gimnasio del Teniente Surge.",
		reward = {exp = 41000, money = 2000, items = {{id = 27642, count = 15}}},
	},
	{
		id = "vermilion_electric", kind = "defeat", species = {"Voltorb", "Magnemite"}, count = 15, giver = "Teniente Surge, Lider de Gimnasio",
		title = "Entrenamiento electrico",
		text = "Antes de retarme, demuestra que no te asusta la electricidad: derrota 15 Voltorb o Magnemite, entre Ciudad Celeste y Ciudad Azafran. Pulsa Ver en el mapa para saber donde estan. (Si te ves fuerte, puedes retar al Teniente Surge directamente.)",
		reward = {exp = 55000, money = 3000},
	},
	{
		id = "surge", kind = "badge", badge = "thunderBadge", giver = "Teniente Surge, Lider de Gimnasio",
		title = "La Medalla Trueno",
		text = "Desafia al Teniente Surge en el Gimnasio de Ciudad Carmin. Sus Pokemon son Voltorb, Magnemite y Raichu. Recomendado: nivel 38-40 y un Pokemon de tipo Tierra.",
		reward = {exp = 0, money = 8000},
		rewardText = "Medalla Trueno, sin tope de nivel 40 y +5% de dano y defensa a tus Pokemon de tipo Electrico",
		map = {{1017, 1272, 5, "Teniente Surge, Gimnasio de Ciudad Carmin"}},
	},
	-- ===== Ciudad Azulona (Erika) =====
	{
		id = "celadon_counter", kind = "catch", types = {"fire", "flying", "poison", "bug"},
		species = {"Koffing", "Ekans", "Grimer"}, count = 1, giver = "Profesor Oak",
		title = "Contra las plantas",
		text = "La siguiente Lider, Erika, usa Pokemon de tipo Planta. Los de tipo Fuego, Volador, Veneno o Bicho les hacen mucho dano. Captura uno: al sureste de Ciudad Azulona hay Koffing, Ekans y Grimer, y por todo Kanto hay Pidgey y Spearow.",
		reward = {exp = 72000, money = 3000, items = {{id = 26688, count = 20}}},
	},
	{
		id = "go_celadon", kind = "reach", town = "celadon", giver = "Profesor Oak",
		title = "Rumbo a Ciudad Azulona",
		text = "Ve hacia el oeste desde Ciudad Azafran hasta Ciudad Azulona, la ciudad de los grandes almacenes. Alli esta el gimnasio de Erika.",
		reward = {exp = 72000, money = 3000, items = {{id = 27642, count = 20}}},
	},
	{
		id = "celadon_grass", kind = "defeat", types = {"grass"}, species = {"Tangela", "Oddish", "Bellsprout"}, count = 15,
		giver = "Erika, Lider de Gimnasio",
		title = "Entrenamiento de planta",
		text = "Antes de retarme, demuestra que sabes tratar con el tipo Planta: derrota 15 Pokemon de tipo Planta (Tangela, Oddish, Bellsprout...). Pulsa Ver en el mapa para saber donde estan. (Si te ves fuerte, puedes retar a Erika directamente.)",
		reward = {exp = 89000, money = 4000},
	},
	{
		id = "erika", kind = "badge", badge = "rainbowBadge", giver = "Erika, Lider de Gimnasio",
		title = "La Medalla Arcoiris",
		text = "Desafia a Erika en el Gimnasio de Ciudad Azulona. Sus Pokemon son Tangela, Weepinbell y Vileplume. Recomendado: nivel 48-50 y un Pokemon de tipo Fuego, Volador, Veneno o Bicho.",
		reward = {exp = 0, money = 12000},
		rewardText = "Medalla Arcoiris, sin tope de nivel 50 y +5% de dano y defensa a tus Pokemon de tipo Planta",
		map = {{843, 1114, 5, "Erika, Gimnasio de Ciudad Azulona"}},
	},
	-- ===== Ciudad Azafran (Sabrina) =====
	{
		id = "lavender_gastly", kind = "catch", species = {"Gastly"}, count = 1, giver = "Profesor Oak",
		title = "La Torre Pokemon",
		text = "Sabrina, la Lider de Ciudad Azafran, usa Pokemon Psiquicos y es muy fuerte. Los Pokemon de tipo Fantasma y Bicho son los que mejor le plantan cara. Ve a la Torre Pokemon de Pueblo Lavanda y captura un Gastly. Ojo: como tambien es de tipo Veneno, los ataques psiquicos le hacen mucho dano, asi que no lo dejes solo. Cuidado con los Gengar de los pisos altos!",
		reward = {exp = 160000, money = 4000, items = {{id = 26688, count = 20}}},
	},
	{
		id = "saffron_psychic", kind = "defeat", types = {"psychic"}, species = {"Exeggcute", "Slowpoke"}, count = 15,
		giver = "Sabrina, Lider de Gimnasio",
		title = "Entrenamiento psiquico",
		text = "Ya sabia que vendrias. Antes de retarme, derrota 15 Pokemon de tipo Psiquico (Exeggcute, Slowpoke, Abra...). Pulsa Ver en el mapa para saber donde estan. (Si te ves fuerte, puedes retar a Sabrina directamente.)",
		reward = {exp = 192000, money = 5000},
	},
	{
		id = "sabrina", kind = "badge", badge = "marshBadge", giver = "Sabrina, Lider de Gimnasio",
		title = "La Medalla Pantano",
		text = "Desafia a Sabrina en el Gimnasio de Ciudad Azafran. Sus Pokemon son Kadabra, Mr. Mime y Alakazam. Recomendado: nivel 58-60 y un Pokemon de tipo Fantasma o Bicho.",
		reward = {exp = 0, money = 15000},
		rewardText = "Medalla Pantano, sin tope de nivel 60 y +5% de dano y defensa a tus Pokemon de tipo Psiquico",
		map = {{1093, 1054, 7, "Sabrina, Gimnasio de Ciudad Azafran"}},
	},
	-- ===== Ciudad Fucsia (Koga) =====
	{
		id = "fuchsia_counter", kind = "catch", types = {"psychic", "ground"},
		species = {"Exeggcute", "Slowpoke", "Diglett", "Sandshrew"}, count = 1, giver = "Profesor Oak",
		title = "Contra el veneno",
		text = "El siguiente Lider, Koga, es un maestro ninja del tipo Veneno. Los Pokemon de tipo Psiquico y Tierra son los que mejor le plantan cara. Captura uno nuevo (Exeggcute, Slowpoke, Diglett, Sandshrew...).",
		reward = {exp = 157000, money = 5000, items = {{id = 26688, count = 25}}},
	},
	{
		id = "go_fuchsia", kind = "reach", town = "fuchsia", giver = "Profesor Oak",
		title = "Rumbo a Ciudad Fucsia",
		text = "Ciudad Fucsia esta en el sureste de Kanto, junto a la Zona Safari. El camino es largo: llevate pociones. Pulsa Ver en el mapa para ver donde esta.",
		reward = {exp = 157000, money = 5000, items = {{id = 27642, count = 25}}},
	},
	{
		id = "fuchsia_poison", kind = "defeat", types = {"poison"}, species = {"Koffing", "Grimer", "Ekans", "Venonat"}, count = 15,
		giver = "Koga, Lider de Gimnasio",
		title = "Entrenamiento venenoso",
		text = "Fu fu fu. Antes de retarme, demuestra que resistes el veneno: derrota 15 Pokemon de tipo Veneno (Koffing, Grimer, Ekans...). Pulsa Ver en el mapa para saber donde estan. (Si te ves fuerte, puedes retar a Koga directamente.)",
		reward = {exp = 183000, money = 6000},
	},
	{
		id = "koga", kind = "badge", badge = "soulBadge", giver = "Koga, Lider de Gimnasio",
		title = "La Medalla Alma",
		text = "Desafia a Koga en el Gimnasio de Ciudad Fucsia. Sus Pokemon son Venomoth, Muk y Weezing. Recomendado: nivel 68-70 y un Pokemon de tipo Psiquico o Tierra.",
		reward = {exp = 0, money = 18000},
		rewardText = "Medalla Alma, sin tope de nivel 70 y +5% de dano y defensa a tus Pokemon de tipo Veneno",
		map = {{1195, 1374, 7, "Koga, Gimnasio de Ciudad Fucsia"}},
	},
	-- ===== Isla Canela (Blaine) =====
	{
		id = "cinnabar_surfer", kind = "catch", species = {"Staryu", "Tentacool", "Poliwag", "Goldeen"}, count = 1,
		giver = "Profesor Oak",
		title = "Aprende a surfear",
		text = "Blaine, el Lider de Isla Canela, usa Pokemon de Fuego, y su isla solo se alcanza por mar. Captura un Pokemon de Agua que sepa surfear: Staryu, Tentacool, Poliwag o Goldeen. Puedes ver en la Pokedex que Pokemon tienen Surf.",
		reward = {exp = 212000, money = 6000, items = {{id = 26688, count = 25}}},
	},
	{
		id = "go_cinnabar", kind = "reach", town = "cinnabar", giver = "Profesor Oak",
		title = "Rumbo a Isla Canela",
		text = "Saca tu Pokemon que sabe surfear y camina hacia el agua: te subiras a el. Desde Pueblo Paleta, navega hacia el sur hasta Isla Canela.",
		reward = {exp = 212000, money = 6000, items = {{id = 27642, count = 25}}},
	},
	{
		id = "cinnabar_fire", kind = "defeat", types = {"fire"}, species = {"Growlithe", "Vulpix", "Ponyta"}, count = 15,
		giver = "Blaine, Lider de Gimnasio",
		title = "Entrenamiento de fuego",
		text = "Ja! Antes de retarme, a ver si aguantas el calor: derrota 15 Pokemon de tipo Fuego en Isla Canela (Growlithe, Vulpix, Ponyta...). Pulsa Ver en el mapa para saber donde estan. (Si te ves fuerte, puedes retar a Blaine directamente.)",
		reward = {exp = 243000, money = 7000},
	},
	{
		id = "blaine", kind = "badge", badge = "volcanoBadge", giver = "Blaine, Lider de Gimnasio",
		title = "La Medalla Volcan",
		text = "Desafia a Blaine en el Gimnasio de Isla Canela. Sus Pokemon son Ninetales, Rapidash y Arcanine. Recomendado: nivel 78-80 y un Pokemon de tipo Agua, Tierra o Roca.",
		reward = {exp = 0, money = 22000},
		rewardText = "Medalla Volcan, sin tope de nivel 80 y +5% de dano y defensa a tus Pokemon de tipo Fuego",
		map = {{790, 1371, 4, "Blaine, Gimnasio de Isla Canela"}},
	},
	-- ===== Ciudad Verde (Giovanni) =====
	{
		id = "viridian_ground", kind = "defeat", types = {"ground"}, species = {"Diglett", "Sandshrew", "Cubone", "Geodude"}, count = 15,
		giver = "Profesor Oak",
		title = "El ultimo gimnasio",
		text = "El gimnasio de Ciudad Verde por fin ha abierto. Su Lider, Giovanni, usa Pokemon de tipo Tierra. Preparate derrotando 15 Pokemon de tipo Tierra (al este de Ciudad Celeste hay muchos). Los de Agua, Planta y Hielo les hacen mucho dano. (Si te ves fuerte, puedes retar a Giovanni directamente.)",
		reward = {exp = 862000, money = 8000},
	},
	{
		id = "giovanni", kind = "badge", badge = "earthBadge", giver = "Giovanni, Lider de Gimnasio",
		title = "La Medalla Tierra",
		text = "Desafia a Giovanni en el Gimnasio de Ciudad Verde. Sus Pokemon son Rhyhorn, Nidoking y Rhydon. Recomendado: nivel 88-90 y un Pokemon de tipo Agua, Planta o Hielo.",
		reward = {exp = 0, money = 30000},
		rewardText = "Medalla Tierra, las 8 medallas de Kanto, sin tope de nivel y +5% de dano y defensa a tus Pokemon de tipo Tierra",
		map = {{743, 1074, 6, "Giovanni, Gimnasio de Ciudad Verde"}},
	},
	-- ===== Liga Pokemon (quest indigoLeague: Alto Mando + campeon) =====
	{
		id = "victory_road", kind = "defeat", species = {"Graveler", "Machoke", "Golbat", "Onix", "Rhyhorn", "Arbok"}, count = 25,
		giver = "Profesor Oak",
		title = "La Calle Victoria",
		text = "Tienes las 8 medallas! Para entrar en la Liga Pokemon necesitas nivel 100. Al oeste de Ciudad Verde, Simon el guardia te dejara pasar a la Calle Victoria: derrota 25 de sus Pokemon (Graveler, Machoke, Golbat, Onix, Rhyhorn, Arbok).",
		reward = {exp = 1082000, money = 10000, items = {{id = 27642, count = 30}}},
		map = {{538, 1094, 7, "Simon, entrada de la Calle Victoria"}, {478, 1087, 8, "Calle Victoria (subterraneo -1)"}, {430, 1117, 9, "Calle Victoria (subterraneo -2)"}},
	},
	{
		id = "league", kind = "badge", badge = "indigoLeague", giver = "Profesor Oak",
		title = "La Liga Pokemon",
		text = "Habla con el portero de la Meseta Anil y desafia al Alto Mando: Lorelei (Hielo), Bruno (Lucha), Agatha (Fantasma), Lance (Dragon) y, por ultimo, el campeon. Solo tendras 25 pociones y 5 revivir para todos los combates.",
		reward = {exp = 0, money = 50000},
		rewardText = "Trofeo de la Liga Indigo, 50 crystal coins y tu nombre en el Salon de la Fama",
		map = {{260, 1074, 7, "Portero de la Liga Pokemon"}},
	},
}

-- ===================== Bono de las medallas =====================
-- Cada medalla da a los Pokemon del jugador de ese tipo +5% de dano y +5% de aguante
-- (el dano que reciben se divide entre 1.05). Se aplica en creaturescripts/scripts/monsterhealthchange.lua.
-- Vale para todos los jugadores con la medalla, sigan o no la historia nueva.
badgeBonusPercent = 0.05
badgeBonuses = {
	{badge = "boulderBadge", type = "rock", typeName = "Roca", medal = "Medalla Roca"},
	{badge = "cascadeBadge", type = "water", typeName = "Agua", medal = "Medalla Cascada"},
	{badge = "thunderBadge", type = "electric", typeName = "Electrico", medal = "Medalla Trueno"},
	{badge = "rainbowBadge", type = "grass", typeName = "Planta", medal = "Medalla Arcoiris"},
	{badge = "soulBadge", type = "poison", typeName = "Veneno", medal = "Medalla Alma"},
	{badge = "marshBadge", type = "psychic", typeName = "Psiquico", medal = "Medalla Pantano"},
	{badge = "volcanoBadge", type = "fire", typeName = "Fuego", medal = "Medalla Volcan"},
	{badge = "earthBadge", type = "ground", typeName = "Tierra", medal = "Medalla Tierra"},
	{badge = "zephyrBadge", type = "flying", typeName = "Volador", medal = "Medalla Cefiro"},
	{badge = "hiveBadge", type = "bug", typeName = "Bicho", medal = "Medalla Colmena"},
	{badge = "plainBadge", type = "normal", typeName = "Normal", medal = "Medalla Llanura"},
	{badge = "fogBadge", type = "ghost", typeName = "Fantasma", medal = "Medalla Niebla"},
	{badge = "stormBadge", type = "fighting", typeName = "Lucha", medal = "Medalla Tormenta"},
	{badge = "mineralBadge", type = "steel", typeName = "Acero", medal = "Medalla Mineral"},
	{badge = "glacierBadge", type = "ice", typeName = "Hielo", medal = "Medalla Glaciar"},
	{badge = "risingBadge", type = "dragon", typeName = "Dragon", medal = "Medalla Dragon"},
}

local function hasBadge(player, badgeKey)
	local quest = quests and quests[badgeKey]
	return quest and player:getStorageValue(quest.prizes[1].uid) > 0 or false
end

function getBadgeBonusByKey(badgeKey)
	for _, bonus in ipairs(badgeBonuses) do
		if bonus.badge == badgeKey then
			return bonus
		end
	end
	return nil
end

-- fraccion extra (0.05 por medalla) para un Pokemon del jugador con esos tipos
function getBadgeTypeBonus(player, race1, race2)
	if not player or not player:isPlayer() then
		return 0
	end
	local total = 0
	for _, bonus in ipairs(badgeBonuses) do
		if (bonus.type == race1 or bonus.type == race2) and hasBadge(player, bonus.badge) then
			total = total + badgeBonusPercent
		end
	end
	return total
end

-- ventana con las medallas del jugador y sus bonos (talkaction !medallas)
function Player.sendBadgeBonuses(self)
	local percent = math.floor(badgeBonusPercent * 100 + 0.5)
	local lines = {}
	for _, bonus in ipairs(badgeBonuses) do
		if hasBadge(self, bonus.badge) then
			lines[#lines + 1] = "- " .. bonus.medal .. ": +" .. percent .. "% de dano y defensa a tus Pokemon de tipo " .. bonus.typeName
		end
	end
	local message
	if #lines == 0 then
		message = "Aun no tienes medallas.\n\nCada Lider de Gimnasio que derrotes te dara una medalla, y cada medalla hace " ..
			"mas fuertes a tus Pokemon de su tipo (+" .. percent .. "% de dano y defensa). La primera es la de Brock, en Ciudad Plateada."
	else
		message = "Tus medallas:\n\n" .. table.concat(lines, "\n") ..
			"\n\nLos bonos se suman: un Pokemon de dos tipos puede llevar el de dos medallas."
	end
	local window = ModalWindow(6120, "Medallas", message)
	window:addButton(1, "Cerrar")
	window:setDefaultEnterButton(1)
	window:setDefaultEscapeButton(1)
	window:sendToPlayer(self)
end

-- ventana al ganar una medalla (la llama progressionOnBadge, tambien fuera de la historia)
local function announceBadgeBonus(player, badgeKey)
	local bonus = getBadgeBonusByKey(badgeKey)
	if not bonus then
		return
	end
	local percent = math.floor(badgeBonusPercent * 100 + 0.5)
	local window = ModalWindow(6121, bonus.medal .. "!",
		"Has conseguido la " .. bonus.medal .. "!\n\n" ..
		"A partir de ahora tus Pokemon de tipo " .. bonus.typeName .. " hacen un " .. percent .. "% mas de dano " ..
		"y aguantan un " .. percent .. "% mas.\n\nDi !medallas para ver todas tus medallas y sus bonos.")
	window:addButton(1, "Genial!")
	window:setDefaultEnterButton(1)
	window:setDefaultEscapeButton(1)
	window:sendToPlayer(player)
end

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

local checkTaskDone

-- puntos del boton "Ver en el mapa": "x:y:z:texto;..." y el nombre del Pokemon para el icono
local function mapText(text)
	return (tostring(text or ""):gsub("[|:;\n\r]", " "))
end

-- con jugador, de las zonas de un Pokemon solo se mandan las mas cercanas a el (el mapa se centraba en
-- zonas lejanas de la superficie aunque hubiera una al lado en otro piso, p. ej. los Clefairy de Mt. Moon)
TASK_MAP_NEAREST_ZONES = 3

function taskMapPoints(task, player)
	local parts = {}
	local icon = ""
	if task.map then
		for _, p in ipairs(task.map) do
			parts[#parts + 1] = p[1] .. ":" .. p[2] .. ":" .. p[3] .. ":" .. mapText(p[4] or task.title)
		end
	elseif (task.kind == "catch" or task.kind == "defeat") and task.species and pokedexGetLocationString then
		local zones = {}
		for _, species in ipairs(task.species) do
			for zone in pokedexGetLocationString(species):gmatch("[^;]+") do
				local x, y, z, count, town = zone:match("^(%-?%d+):(%-?%d+):(%-?%d+):(%d+):(.*)$")
				if x then
					zones[#zones + 1] = {x = tonumber(x), y = tonumber(y), z = tonumber(z),
						text = mapText(species .. ": " .. count .. (town ~= "" and (" cerca de " .. town) or ""))}
				end
			end
		end
		if player then
			local pos = player:getPosition()
			for _, zone in ipairs(zones) do
				zone.dist = math.max(math.abs(zone.x - pos.x), math.abs(zone.y - pos.y)) + math.abs(zone.z - pos.z) * 15
			end
			table.sort(zones, function(a, b) return a.dist < b.dist end)
			while #zones > TASK_MAP_NEAREST_ZONES do
				table.remove(zones)
			end
		end
		for _, zone in ipairs(zones) do
			parts[#parts + 1] = zone.x .. ":" .. zone.y .. ":" .. zone.z .. ":" .. zone.text
		end
		icon = task.species[1]
	elseif task.kind == "reach" then
		local town = findTown(task.town)
		if town then
			local pos = town:getTemplePosition()
			parts[#parts + 1] = pos.x .. ":" .. pos.y .. ":" .. pos.z .. ":" .. mapText(town:getName())
		end
	end
	return table.concat(parts, ";"), mapText(icon)
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
	-- medalla o ciudad conseguida por otro camino (GM, antes de existir la tarea...)
	if activeIndex and (activeTask.kind == "badge" or activeTask.kind == "reach") and checkTaskDone(self, activeIndex) then
		return
	end
	-- medalla de un gimnasio posterior ya conseguida (se gano al lider antes de hacer las tareas previas,
	-- p. ej. antes de existir la regla de progressionOnBadge): se cierran las tareas hasta ese gimnasio
	if activeIndex then
		for index = activeIndex + 1, #progressionTasks do
			local task = progressionTasks[index]
			local quest = task.kind == "badge" and not task.disabled and quests[task.badge]
			if quest and self:getStorageValue(quest.prizes[1].uid) > 0 then
				progressionCompleteThroughBadge(self, index)
				return
			end
		end
	end
	-- sin tarea activa pero con tareas nuevas despues de la ultima hecha (se anaden al final)
	if not activeIndex then
		local lastDone = 0
		for index = 1, #progressionTasks do
			if taskState(self, index) == 2 then
				lastDone = index
			end
		end
		if lastDone > 0 and lastDone < #progressionTasks then
			progressionActivateNext(self, lastDone)
			return
		end
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
			local mapPoints, mapIcon = "", ""
			if state == 1 then
				mapPoints, mapIcon = taskMapPoints(task, self)
			end
			lines[#lines + 1] = table.concat({index, state, task.kind, clean(task.giver), clean(task.title),
				clean(task.text), progress, total, clean(rewardText(task)), mapPoints, mapIcon}, "|")
		end
	end
	self:sendExtendedOpcode(OPCODE_TASKS, table.concat(lines, "\n"))
end

-- ventana de mision completada: "titulo|recompensa|tipo|quien|titulo|texto|aspecto|mapa" de la siguiente
-- (los campos de la siguiente van vacios si no queda ninguna). El cliente las pone en cola.
local function giverLook(giver)
	for _, entry in ipairs(progressionGiverOutfits) do
		if tostring(giver):sub(1, #entry.prefix) == entry.prefix then
			return table.concat(entry.look, ",")
		end
	end
	return ""
end

function progressionSendTaskDone(player, task, index)
	local nextIndex = index + 1
	while progressionTasks[nextIndex] and progressionTasks[nextIndex].disabled do
		nextIndex = nextIndex + 1
	end
	local nextTask = progressionTasks[nextIndex]
	if not nextTask then
		nextIndex = nil
	end
	local fields = {clean(task.title), clean(rewardText(task))}
	if nextIndex then
		local points = taskMapPoints(nextTask, player)
		fields[#fields + 1] = nextTask.kind
		fields[#fields + 1] = clean(nextTask.giver)
		fields[#fields + 1] = clean(nextTask.title)
		fields[#fields + 1] = clean(nextTask.text)
		fields[#fields + 1] = giverLook(nextTask.giver)
		fields[#fields + 1] = points ~= "" and "1" or "0"
	else
		for _ = 1, 6 do fields[#fields + 1] = "" end
	end
	player:sendExtendedOpcode(OPCODE_TASK_DONE, table.concat(fields, "|"))
end

-- ===================== Estados =====================

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
	-- el aviso va antes de activar la siguiente: si esa se completa sola, su aviso llega despues (en orden)
	progressionSendTaskDone(player, task, index)
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

-- Pruebas (GM, /progreso ir <id>): salta a una tarea. Las anteriores quedan hechas sin recompensa
-- y se ponen las medallas de los gimnasios anteriores (solo el storage, sin el objeto medalla).
function progressionJumpTo(player, id)
	local target
	for index, task in ipairs(progressionTasks) do
		if task.id == id then
			target = index
			break
		end
	end
	if not target then
		return false
	end
	player:setStorageValue(PROGRESSION_STORAGE, 1)
	player:setStorageValue(PROGRESSION_STARTER_STORAGE, 1)
	for index, task in ipairs(progressionTasks) do
		local done = index < target
		player:setStorageValue(PROGRESSION_TASK_STATE + index, done and 2 or -1)
		player:setStorageValue(PROGRESSION_TASK_PROGRESS + index, -1)
		if task.kind == "badge" and quests[task.badge] then
			player:setStorageValue(quests[task.badge].prizes[1].uid, done and 1 or 0)
		end
	end
	activateTask(player, target)
	if player.sendNextGym then
		player:sendNextGym()
	end
	return true
end

function progressionTaskIds()
	local ids = {}
	for _, task in ipairs(progressionTasks) do
		if not task.disabled then
			ids[#ids + 1] = task.id
		end
	end
	return ids
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
	if task.species or task.types then
		local species = speciesName(name)
		local matches = false
		for _, wanted in ipairs(task.species or {}) do
			if wanted:lower() == species then
				matches = true
				break
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
	announceBadgeBonus(player, badgeKey)
	if player.sendNextGym then
		player:sendNextGym()
	end
	if not player:isOnProgression() then
		return
	end
	-- si se ha retado al lider sin terminar las tareas previas (los 15 Geodude...), ganar la medalla
	-- las da por cumplidas, con su recompensa, hasta la tarea del gimnasio incluida
	local badgeIndex
	for index, task in ipairs(progressionTasks) do
		if task.kind == "badge" and task.badge == badgeKey then
			badgeIndex = index
			break
		end
	end
	if not badgeIndex then
		player:sendTasks() -- el tope de nivel ha cambiado
		return
	end
	progressionCompleteThroughBadge(player, badgeIndex)
end

-- completa (con recompensa) las tareas pendientes hasta la del gimnasio badgeIndex incluida
function progressionCompleteThroughBadge(player, badgeIndex)
	for _ = 1, #progressionTasks do
		local index, task = progressionGetActiveTask(player)
		if not index or index > badgeIndex then
			break
		end
		if index < badgeIndex then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Con la victoria sobre el lider se da por cumplida: " .. task.title)
		end
		completeTask(player, index)
	end
	player:sendTasks()
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

-- ===================== Siguiente gimnasio en el mapa =====================
-- Opcode 75: "x:y:z:lider:ciudad:medalla:tipo" del primer gimnasio sin medalla ("" si no queda ninguno).
OPCODE_NEXT_GYM = 75
local gymPositions

local function loadGymPositions()
	gymPositions = {}
	local file = io.open("data/world/map-spawn.xml", "r")
	if not file then
		return
	end
	local wanted = {}
	for _, gym in ipairs(progressionGyms) do
		wanted[gym.npc:lower()] = true
	end
	local cx, cy, cz = 0, 0, 7
	for line in file:lines() do
		local sx, sy, sz = line:match('<spawn%s+centerx="(%d+)"%s+centery="(%d+)"%s+centerz="(%d+)"')
		if sx then
			cx, cy, cz = tonumber(sx), tonumber(sy), tonumber(sz)
		end
		local name, x, y = line:match('<npc%s+name="([^"]+)"%s+x="(%-?%d+)"%s+y="(%-?%d+)"')
		if name and wanted[name:lower()] and not gymPositions[name:lower()] then
			gymPositions[name:lower()] = Position(cx + tonumber(x), cy + tonumber(y), cz)
		end
	end
	file:close()
end

function progressionGetNextGym(player)
	for _, gym in ipairs(progressionGyms) do
		if not hasBadge(player, gym.badge) then
			return gym
		end
	end
	return nil
end

function Player.sendNextGym(self)
	if not gymPositions then
		loadGymPositions()
	end
	local gym = progressionGetNextGym(self)
	local pos = gym and gymPositions[gym.npc:lower()]
	if not pos then
		self:sendExtendedOpcode(OPCODE_NEXT_GYM, "")
		return
	end
	self:sendExtendedOpcode(OPCODE_NEXT_GYM, table.concat({pos.x, pos.y, pos.z, mapText(gym.leader),
		mapText(gym.city), mapText(gym.medal), mapText(gym.type)}, ":"))
end

