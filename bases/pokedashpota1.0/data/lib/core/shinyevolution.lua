-- Evolucion de shinies estilo PKA: los shiny no evolucionan con piedras.
-- Cada shiny salvaje que es una evolucion (p. ej. Shiny Charmeleon) suelta a veces un objeto
-- que se usa para evolucionar su fase anterior (Shiny Charmander -> Shiny Charmeleon).
-- Cada objeto es un item propio (id 46001+, nombre propio en items.xml, entrada propia en items.otb).
-- Su dibujo es una copia brillante del item base ("item"), generada con tools/pokeassets.

-- Probabilidad (en %) de soltar el objeto segun el tier del shiny que muere
--   tier 3: fase intermedia (Charmeleon, Ivysaur...)
--   tier 2: fase final normal (Raichu, Arbok...)
--   tier 1: fase final fuerte (Charizard, Gyarados...): casi imposible
shinyEvoTierChance = {
	[1] = 0.001,
	[2] = 0.5,
	[3] = 7,
}

-- [id del objeto] = { target = shiny que suelta el objeto (y en el que se evoluciona), item = id del item base (dibujo), tier }
shinyEvoItems = {
	[46001] = {target = "Shiny Abomasnow", item = 27670, tier = 2}, -- seed
	[46002] = {target = "Shiny Aggron", item = 27651, tier = 2}, -- piece of steel
	[46003] = {target = "Shiny Altaria", item = 27706, tier = 2}, -- feather
	[46004] = {target = "Shiny Ambipom", item = 27687, tier = 2}, -- comb
	[46005] = {target = "Shiny Ampharos", item = 27754, tier = 1}, -- magnetic tail
	[46006] = {target = "Shiny Arbok", item = 27758, tier = 2}, -- giant snake tail
	[46007] = {target = "Shiny Arcanine", item = 27791, tier = 1}, -- giant piece of fur
	[46008] = {target = "Shiny Ariados", item = 27816, tier = 2}, -- spider legs
	[46009] = {target = "Shiny Armaldo", item = 27679, tier = 2}, -- pot of moss bug
	[46010] = {target = "Shiny Azumarill", item = 27770, tier = 1}, -- blue rat ear
	[46011] = {target = "Shiny Banette", item = 27710, tier = 2}, -- traces of ghost
	[46012] = {target = "Shiny Bastiodon", item = 27651, tier = 2}, -- piece of steel
	[46013] = {target = "Shiny Bayleef", item = 27660, tier = 3}, -- leaves
	[46014] = {target = "Shiny Beautifly", item = 27719, tier = 2}, -- straw
	[46015] = {target = "Shiny Beedrill", item = 27777, tier = 2}, -- bee sting
	[46016] = {target = "Shiny Bellossom", item = 27727, tier = 2}, -- yellow flower
	[46017] = {target = "Shiny Bibarel", item = 27668, tier = 2}, -- water gem
	[46018] = {target = "Shiny Blastoise", item = 27666, tier = 1}, -- squirtle hull
	[46019] = {target = "Shiny Blaziken", item = 27700, tier = 1}, -- future orb
	[46020] = {target = "Shiny Breloom", item = 27670, tier = 2}, -- seed
	[46021] = {target = "Shiny Bronzong", item = 27651, tier = 2}, -- piece of steel
	[46022] = {target = "Shiny Butterfree", item = 27760, tier = 2}, -- butterfly wing
	[46023] = {target = "Shiny Cacturne", item = 27784, tier = 2}, -- dark gem
	[46024] = {target = "Shiny Camerupt", item = 27685, tier = 2}, -- sandbag
	[46025] = {target = "Shiny Cascoon", item = 27679, tier = 3}, -- pot of moss bug
	[46026] = {target = "Shiny Chansey", item = 27700, tier = 1}, -- future orb
	[46027] = {target = "Shiny Charizard", item = 27690, tier = 1}, -- ala negra (bat wing)
	[46028] = {target = "Shiny Charmeleon", item = 27780, tier = 3}, -- fire tail
	[46029] = {target = "Shiny Cherrim", item = 27660, tier = 2}, -- leaves
	[46030] = {target = "Shiny Chimecho", item = 27700, tier = 2}, -- future orb
	[46031] = {target = "Shiny Claydol", item = 27700, tier = 2}, -- future orb
	[46032] = {target = "Shiny Clefable", item = 27723, tier = 1}, -- microphone
	[46033] = {target = "Shiny Clefairy", item = 27723, tier = 3}, -- microphone
	[46034] = {target = "Shiny Cloyster", item = 27819, tier = 2}, -- strange spike
	[46035] = {target = "Shiny Combusken", item = 27700, tier = 3}, -- future orb
	[46036] = {target = "Shiny Cradily", item = 27670, tier = 1}, -- seed
	[46037] = {target = "Shiny Crawdaunt", item = 27713, tier = 2}, -- crab claw
	[46038] = {target = "Shiny Crobat", item = 27766, tier = 1}, -- big bat wing
	[46039] = {target = "Shiny Croconaw", item = 27769, tier = 3}, -- red scale
	[46040] = {target = "Shiny Delcatty", item = 27694, tier = 2}, -- wool ball
	[46041] = {target = "Shiny Dewgong", item = 27749, tier = 1}, -- long seal tail
	[46042] = {target = "Shiny Dodrio", item = 27785, tier = 2}, -- dodrio feather
	[46043] = {target = "Shiny Donphan", item = 27748, tier = 1}, -- rock trunk
	[46044] = {target = "Shiny Dragonair", item = 27667, tier = 3}, -- dragon tooth
	[46045] = {target = "Shiny Dragonite", item = 27667, tier = 1}, -- dragon tooth
	[46046] = {target = "Shiny Drapion", item = 27784, tier = 2}, -- dark gem
	[46047] = {target = "Shiny Drifblim", item = 27710, tier = 1}, -- traces of ghost
	[46048] = {target = "Shiny Dugtrio", item = 27800, tier = 2}, -- piece of diglett
	[46049] = {target = "Shiny Dusclops", item = 27710, tier = 3}, -- traces of ghost
	[46050] = {target = "Shiny Dusknoir", item = 27710, tier = 2}, -- traces of ghost
	[46051] = {target = "Shiny Dustox", item = 27679, tier = 2}, -- pot of moss bug
	[46052] = {target = "Shiny Electivire", item = 27671, tier = 2}, -- screw
	[46053] = {target = "Shiny Electrode", item = 27684, tier = 2}, -- electric box
	[46054] = {target = "Shiny Empoleon", item = 27678, tier = 2}, -- water pendant
	[46055] = {target = "Shiny Espeon", item = 27700, tier = 2}, -- future orb
	[46056] = {target = "Shiny Exeggutor", item = 27660, tier = 1}, -- leaves
	[46057] = {target = "Shiny Exploud", item = 27700, tier = 1}, -- future orb
	[46058] = {target = "Shiny Fearow", item = 27811, tier = 2}, -- red wing
	[46059] = {target = "Shiny Feraligatr", item = 27769, tier = 1}, -- red scale
	[46060] = {target = "Shiny Flaaffy", item = 27814, tier = 3}, -- sheep wool
	[46061] = {target = "Shiny Flareon", item = 27700, tier = 2}, -- future orb
	[46062] = {target = "Shiny Floatzel", item = 27678, tier = 2}, -- water pendant
	[46063] = {target = "Shiny Flygon", item = 27685, tier = 1}, -- sandbag
	[46064] = {target = "Shiny Forretress", item = 27808, tier = 2}, -- piece of shell
	[46065] = {target = "Shiny Gabite", item = 27667, tier = 3}, -- dragon tooth
	[46066] = {target = "Shiny Garchomp", item = 27667, tier = 1}, -- dragon tooth
	[46067] = {target = "Shiny Gardevoir", item = 27700, tier = 2}, -- future orb
	[46068] = {target = "Shiny Gastrodon", item = 27685, tier = 1}, -- sandbag
	[46069] = {target = "Shiny Gengar", item = 27710, tier = 2}, -- traces of ghost
	[46070] = {target = "Shiny Glalie", item = 2111, tier = 1}, -- snowball
	[46071] = {target = "Shiny Gloom", item = 27743, tier = 3}, -- poisonous flower
	[46072] = {target = "Shiny Golbat", item = 27766, tier = 3}, -- big bat wing
	[46073] = {target = "Shiny Golduck", item = 27696, tier = 1}, -- psyduck mug
	[46074] = {target = "Shiny Golem", item = 27818, tier = 1}, -- strange rock
	[46075] = {target = "Shiny Granbull", item = 27801, tier = 1}, -- dog ears
	[46076] = {target = "Shiny Graveler", item = 27818, tier = 3}, -- strange rock
	[46077] = {target = "Shiny Grotle", item = 27670, tier = 3}, -- seed
	[46078] = {target = "Shiny Grovyle", item = 27670, tier = 3}, -- seed
	[46079] = {target = "Shiny Grumpig", item = 27700, tier = 1}, -- future orb
	[46080] = {target = "Shiny Gyarados", item = 27652, tier = 1}, -- gyarados tail
	[46081] = {target = "Shiny Hariyama", item = 27698, tier = 1}, -- punch machine
	[46082] = {target = "Shiny Haunter", item = 27710, tier = 3}, -- traces of ghost
	[46083] = {target = "Shiny Hippowdon", item = 27685, tier = 1}, -- sandbag
	[46084] = {target = "Shiny Hitmontop", item = 27715, tier = 2}, -- kick machine
	[46085] = {target = "Shiny Honchkrow", item = 27710, tier = 1}, -- traces of ghost
	[46086] = {target = "Shiny Houndoom", item = 27664, tier = 2}, -- strange bone
	[46087] = {target = "Shiny Huntail", item = 27668, tier = 2}, -- water gem
	[46088] = {target = "Shiny Infernape", item = 27715, tier = 2}, -- kick machine
	[46089] = {target = "Shiny Ivysaur", item = 27659, tier = 3}, -- bulb
	[46090] = {target = "Shiny Jigglypuff", item = 27723, tier = 3}, -- microphone
	[46091] = {target = "Shiny Jumpluff", item = 27727, tier = 2}, -- yellow flower
	[46092] = {target = "Shiny Jynx", item = 27676, tier = 2}, -- ice bra
	[46093] = {target = "Shiny Kabutops", item = 27657, tier = 2}, -- dome fossil
	[46094] = {target = "Shiny Kakuna", item = 27679, tier = 3}, -- pot of moss bug
	[46095] = {target = "Shiny Kingdra", item = 27813, tier = 2}, -- seahorse tail
	[46096] = {target = "Shiny Kingler", item = 27713, tier = 2}, -- crab claw
	[46097] = {target = "Shiny Kirlia", item = 27700, tier = 3}, -- future orb
	[46098] = {target = "Shiny Kricketune", item = 27679, tier = 2}, -- pot of moss bug
	[46099] = {target = "Shiny Lairon", item = 27651, tier = 3}, -- piece of steel
	[46100] = {target = "Shiny Lanturn", item = 27678, tier = 1}, -- water pendant
	[46101] = {target = "Shiny Ledian", item = 27740, tier = 2}, -- ladybug shell
	[46102] = {target = "Shiny Lickilicky", item = 27687, tier = 1}, -- comb
	[46103] = {target = "Shiny Linoone", item = 27700, tier = 1}, -- future orb
	[46104] = {target = "Shiny Lombre", item = 27670, tier = 3}, -- seed
	[46105] = {target = "Shiny Lopunny", item = 27687, tier = 2}, -- comb
	[46106] = {target = "Shiny Loudred", item = 27700, tier = 3}, -- future orb
	[46107] = {target = "Shiny Lucario", item = 27698, tier = 2}, -- punch machine
	[46108] = {target = "Shiny Ludicolo", item = 27670, tier = 1}, -- seed
	[46109] = {target = "Shiny Lumineon", item = 27678, tier = 2}, -- water pendant
	[46110] = {target = "Shiny Luxio", item = 27684, tier = 3}, -- electric box
	[46111] = {target = "Shiny Luxray", item = 27671, tier = 2}, -- screw
	[46112] = {target = "Shiny Machamp", item = 27701, tier = 1}, -- belt of champion
	[46113] = {target = "Shiny Machoke", item = 27701, tier = 3}, -- belt of champion
	[46114] = {target = "Shiny Magcargo", item = 27739, tier = 2}, -- lava shell
	[46115] = {target = "Shiny Magmar", item = 27806, tier = 3}, -- magma foot
	[46116] = {target = "Shiny Magmortar", item = 27656, tier = 2}, -- pot of lava
	[46117] = {target = "Shiny Magneton", item = 27704, tier = 3}, -- magnet
	[46118] = {target = "Shiny Magnezone", item = 27651, tier = 2}, -- piece of steel
	[46119] = {target = "Shiny Mamoswine", item = 27685, tier = 1}, -- sandbag
	[46120] = {target = "Shiny Manectric", item = 27671, tier = 2}, -- screw
	[46121] = {target = "Shiny Mantine", item = 27678, tier = 1}, -- water pendant
	[46122] = {target = "Shiny Marill", item = 27753, tier = 3}, -- blue ball tail
	[46123] = {target = "Shiny Marowak", item = 27737, tier = 2}, -- old skull
	[46124] = {target = "Shiny Marshtomp", item = 27685, tier = 3}, -- sandbag
	[46125] = {target = "Shiny Masquerain", item = 27719, tier = 2}, -- straw
	[46126] = {target = "Shiny Medicham", item = 27700, tier = 2}, -- future orb
	[46127] = {target = "Shiny Meganium", item = 27793, tier = 1}, -- great petals
	[46128] = {target = "Shiny Metagross", item = 27700, tier = 1}, -- future orb
	[46129] = {target = "Shiny Metang", item = 27700, tier = 3}, -- future orb
	[46130] = {target = "Shiny Metapod", item = 27679, tier = 3}, -- pot of moss bug
	[46131] = {target = "Shiny Mightyena", item = 27784, tier = 2}, -- dark gem
	[46132] = {target = "Shiny Milotic", item = 27668, tier = 1}, -- water gem
	[46133] = {target = "Shiny Mismagius", item = 27710, tier = 2}, -- traces of ghost
	[46134] = {target = "Shiny Monferno", item = 27715, tier = 3}, -- kick machine
	[46135] = {target = "Shiny Mothim", item = 27679, tier = 2}, -- pot of moss bug
	[46136] = {target = "Shiny Mr. Mime", item = 27700, tier = 2}, -- future orb
	[46137] = {target = "Shiny Muk", item = 27817, tier = 1}, -- sticky hand
	[46138] = {target = "Shiny Nidoking", item = 27803, tier = 1}, -- male ear
	[46139] = {target = "Shiny Nidoqueen", item = 27802, tier = 1}, -- female ear
	[46140] = {target = "Shiny Nidorina", item = 27802, tier = 3}, -- female ear
	[46141] = {target = "Shiny Nidorino", item = 27803, tier = 3}, -- male ear
	[46142] = {target = "Shiny Ninetales", item = 27688, tier = 2}, -- fox tail
	[46143] = {target = "Shiny Ninjask", item = 27719, tier = 2}, -- straw
	[46144] = {target = "Shiny Noctowl", item = 27804, tier = 1}, -- owl feather
	[46145] = {target = "Shiny Nuzleaf", item = 27784, tier = 3}, -- dark gem
	[46146] = {target = "Shiny Octillery", item = 27735, tier = 2}, -- tentacle
	[46147] = {target = "Shiny Omastar", item = 27661, tier = 2}, -- helix fossil
	[46148] = {target = "Shiny Parasect", item = 27658, tier = 2}, -- bag of pollem
	[46149] = {target = "Shiny Pelipper", item = 27706, tier = 2}, -- feather
	[46150] = {target = "Shiny Persian", item = 27693, tier = 2}, -- luck medallion
	[46151] = {target = "Shiny Pidgeot", item = 27706, tier = 1}, -- feather
	[46152] = {target = "Shiny Pidgeotto", item = 27706, tier = 3}, -- feather
	[46153] = {target = "Shiny Pikachu", item = 27734, tier = 3}, -- electric rat tail
	[46154] = {target = "Shiny Piloswine", item = 27685, tier = 3}, -- sandbag
	[46155] = {target = "Shiny Politoed", item = 27678, tier = 1}, -- water pendant
	[46156] = {target = "Shiny Poliwhirl", item = 27678, tier = 3}, -- water pendant
	[46157] = {target = "Shiny Poliwrath", item = 27678, tier = 1}, -- water pendant
	[46158] = {target = "Shiny Porygon-Z", item = 27700, tier = 2}, -- future orb
	[46159] = {target = "Shiny Primeape", item = 27689, tier = 2}, -- fur
	[46160] = {target = "Shiny Prinplup", item = 27668, tier = 3}, -- water gem
	[46161] = {target = "Shiny Probopass", item = 27651, tier = 2}, -- piece of steel
	[46162] = {target = "Shiny Pupitar", item = 27685, tier = 3}, -- sandbag
	[46163] = {target = "Shiny Purugly", item = 27687, tier = 2}, -- comb
	[46164] = {target = "Shiny Quagsire", item = 27821, tier = 1}, -- wooper horn
	[46165] = {target = "Shiny Quilava", item = 27795, tier = 3}, -- hot fur
	[46166] = {target = "Shiny Raichu", item = 27733, tier = 2}, -- strange electric tail
	[46167] = {target = "Shiny Rampardos", item = 27685, tier = 1}, -- sandbag
	[46168] = {target = "Shiny Rapidash", item = 27789, tier = 2}, -- fire horse foot
	[46169] = {target = "Shiny Raticate", item = 27682, tier = 2}, -- rat tail
	[46170] = {target = "Shiny Rhydon", item = 27686, tier = 3}, -- horn
	[46171] = {target = "Shiny Rhyperior", item = 27685, tier = 1}, -- sandbag
	[46172] = {target = "Shiny Roselia", item = 27672, tier = 3}, -- bottle of poison
	[46173] = {target = "Shiny Roserade", item = 27660, tier = 2}, -- leaves
	[46174] = {target = "Shiny Salamence", item = 27719, tier = 1}, -- straw
	[46175] = {target = "Shiny Sandslash", item = 27775, tier = 2}, -- armadillo claw
	[46176] = {target = "Shiny Sceptile", item = 27670, tier = 2}, -- seed
	[46177] = {target = "Shiny Scizor", item = 27812, tier = 2}, -- scizor claw
	[46178] = {target = "Shiny Seadra", item = 27813, tier = 3}, -- seahorse tail
	[46179] = {target = "Shiny Seaking", item = 27686, tier = 1}, -- horn
	[46180] = {target = "Shiny Sealeo", item = 27668, tier = 3}, -- water gem
	[46181] = {target = "Shiny Sharpedo", item = 27784, tier = 2}, -- dark gem
	[46182] = {target = "Shiny Shelgon", item = 27700, tier = 3}, -- future orb
	[46183] = {target = "Shiny Shiftry", item = 27784, tier = 1}, -- dark gem
	[46184] = {target = "Shiny Skiploom", item = 27727, tier = 3}, -- yellow flower
	[46185] = {target = "Shiny Skuntank", item = 27672, tier = 1}, -- bottle of poison
	[46186] = {target = "Shiny Slaking", item = 27700, tier = 1}, -- future orb
	[46187] = {target = "Shiny Slowbro", item = 27703, tier = 3}, -- slow tail
	[46188] = {target = "Shiny Slowking", item = 27729, tier = 1}, -- mystic shell hat
	[46189] = {target = "Shiny Snorlax", item = 27681, tier = 1}, -- bitten apple
	[46190] = {target = "Shiny Starmie", item = 27790, tier = 2}, -- gem star
	[46191] = {target = "Shiny Steelix", item = 27725, tier = 2}, -- steelix tail
	[46192] = {target = "Shiny Sudowoodo", item = 27700, tier = 2}, -- future orb
	[46193] = {target = "Shiny Sunflora", item = 27660, tier = 2}, -- leaves
	[46194] = {target = "Shiny Swalot", item = 27708, tier = 1}, -- gosme
	[46195] = {target = "Shiny Swampert", item = 27685, tier = 1}, -- sandbag
	[46196] = {target = "Shiny Swellow", item = 27706, tier = 2}, -- feather
	[46197] = {target = "Shiny Tangrowth", item = 27670, tier = 1}, -- seed
	[46198] = {target = "Shiny Tentacruel", item = 27778, tier = 1}, -- giant ruby
	[46199] = {target = "Shiny Togekiss", item = 27706, tier = 2}, -- feather
	[46200] = {target = "Shiny Togetic", item = 27786, tier = 3}, -- egg shell
	[46201] = {target = "Shiny Torterra", item = 27658, tier = 1}, -- bag of pollem
	[46202] = {target = "Shiny Toxicroak", item = 27672, tier = 2}, -- bottle of poison
	[46203] = {target = "Shiny Typhlosion", item = 27795, tier = 1}, -- hot fur
	[46204] = {target = "Shiny Tyranitar", item = 27685, tier = 1}, -- sandbag
	[46205] = {target = "Shiny Umbreon", item = 27784, tier = 1}, -- dark gem
	[46206] = {target = "Shiny Ursaring", item = 27776, tier = 1}, -- bear paw
	[46207] = {target = "Shiny Vaporeon", item = 27700, tier = 1}, -- future orb
	[46208] = {target = "Shiny Venomoth", item = 27773, tier = 2}, -- moth wing
	[46209] = {target = "Shiny Venusaur", item = 27659, tier = 1}, -- bulb
	[46210] = {target = "Shiny Vibrava", item = 27685, tier = 3}, -- sandbag
	[46211] = {target = "Shiny Victreebel", item = 27809, tier = 1}, -- plant tail
	[46212] = {target = "Shiny Vigoroth", item = 27700, tier = 3}, -- future orb
	[46213] = {target = "Shiny Vileplume", item = 27743, tier = 2}, -- poisonous flower
	[46214] = {target = "Shiny Wailord", item = 27668, tier = 1}, -- water gem
	[46215] = {target = "Shiny Walrein", item = 27668, tier = 1}, -- water gem
	[46216] = {target = "Shiny Wartortle", item = 27666, tier = 3}, -- squirtle hull
	[46217] = {target = "Shiny Weavile", item = 28569, tier = 2}, -- ice orb
	[46218] = {target = "Shiny Weepinbell", item = 27660, tier = 3}, -- leaves
	[46219] = {target = "Shiny Weezing", item = 27717, tier = 2}, -- venom flute
	[46220] = {target = "Shiny Whiscash", item = 27685, tier = 1}, -- sandbag
	[46221] = {target = "Shiny Wigglytuff", item = 27723, tier = 1}, -- microphone
	[46222] = {target = "Shiny Wobbuffet", item = 27700, tier = 1}, -- future orb
	[46223] = {target = "Shiny Wormadam", item = 27679, tier = 3}, -- pot of moss bug
	[46224] = {target = "Shiny Xatu", item = 27706, tier = 2}, -- feather
}

shinyEvoByTarget = {}
for id, entry in pairs(shinyEvoItems) do
	entry.id = id
	shinyEvoByTarget[entry.target] = entry
end

-- Crea el objeto de evolucion dentro del cadaver si sale la probabilidad. Devuelve el item o nil.
function doShinyEvoDrop(creature, corpse)
	local entry = shinyEvoByTarget[creature:getName()]
	if not entry or creature:getMaster() then
		return nil
	end
	local chance = shinyEvoTierChance[entry.tier] or 0
	if math.random(1, 100000) > chance * 1000 then
		return nil
	end
	return corpse:addItem(entry.id, 1)
end
