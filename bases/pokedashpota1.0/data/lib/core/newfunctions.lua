filledPokeball = 2325 -- lixo
maxFilledBalls = 6 -- lixo
firstPortrait = 27117 -- lixo
stonesId = { -- lixo
{"Water", 2267},
{"Fire", 1}
}
--legendaryPokemons = {"Zapdos", "Articuno", "Moltres", "Mew", "Mewtwo", "Raikou", "Entei", "Suicune", "Ho-oh", "Lugia", "Celebi", "Regirock", "Regice", "Registeel", "Latias", "Latios", "Kyogre", "Groudon", "Rayquaza", "Shiny Zapdos", "Shiny Articuno", "Shiny Moltres", "Shiny Mew", "Shiny Mewtwo", "Shiny Raikou", "Shiny Entei", "Shiny Suicune", "Shiny Ho-oh", "Shiny Lugia", "Shiny Celebi", "Shiny Regirock", "Shiny Regice", "Shiny Registeel", "Shiny Latias", "Shiny Latios", "Shiny Kyogre", "Shiny Groudon", "Shiny Rayquaza"}

maxBoost = 50
fullPokeHealth = 999999999 -- vida "llena": se recorta a la vida maxima al sacar el pokemon
summonMaxLevel = 200 -- maximum level of pokes
maxVitamins = 10
shinyChance = 2
flyFloor = 460 
moveWords = {"m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9", "m10", "m11", "m12"}
legendaryIndex = {144, 145, 146, 150, 151, 243, 244, 245, 249, 250, 251, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386}
arenaLastPlayerId = 0

damageMultiplierMoves = {areawaves = 2.75, singletargetweak = 2.0, singletarget = 3.5, singletargetstrong = 4.0, areatarget = 3.0, frontlinear = 5.0, frontarea = 4.0, passive = 3.0, ultimate = 6.0}
summonLevelDamageBuff = 0.008 -- buff por nivel configurado de pokemon de NPC
summonBoostDamageBuff = 0.008 -- buff due to summon's boost
summonLoveDamageBuff = 0.0002 -- buff due to summon's love
shinyStatMultiplier = 1.25 -- shiny pokemon have 25% stronger stats than their own base stats
-- Estilo Poke Alliance: los pokemon no tienen nivel (no ganan exp ni suben de nivel,
-- evolucionan con piedras). La fuerza de un pokemon de jugador (dano, vida, defensa,
-- velocidad) depende del nivel del entrenador + boost.
trainerLevelDamageBuff = 0.008 -- (ya no se usa: ver trainerLevelCurve)
-- Curva de fuerza por nivel. La usan los pokemon de jugador (nivel del entrenador) y los
-- equipos de NPC/gimnasio (nivel configurado). Los salvajes (nivel 0) se quedan en 1.0.
-- Sube rapido hasta el nivel 30 (que subir se note y a nivel 25-30 un Caterpie caiga de un
-- golpe) y despues mas despacio. El dano escala con el cuadrado (el ataque y onHealthChange
-- aplican la formula), la vida y la defensa de forma lineal.
--   nivel:  1 -> 1.36 | 10 -> 1.90 | 20 -> 2.50 | 30 -> 3.10 | 50 -> 3.40 | 80 -> 3.85
trainerCurveBase = 1.3
trainerCurveEarly = 0.06 -- por nivel hasta trainerCurveEarlyCap
trainerCurveEarlyCap = 30
trainerCurveLate = 0.015 -- por nivel a partir de trainerCurveEarlyCap
-- Nivel de entrenador necesario para usar un pokemon segun su etapa evolutiva
-- (los que no evolucionan, como Snorlax o Heracross, cuentan como etapa final).
-- Los salvajes usan este mismo valor como nivel de fuerza: un Charizard salvaje
-- pega como el Charizard de un entrenador nivel 80.
-- twoStageFinal: final de una linea de solo 2 etapas (Raichu, Slowbro, Rapidash...).
pokemonStageLevels = {base = 0, middle = 40, twoStageFinal = 50, final = 80}
-- Nivel particular por pokemon (nombre en minusculas, sin "shiny "). Tiene prioridad
-- sobre pokemonStageLevels; el shiny sigue sumando shinyExtraLevel. Sirve para cualquier
-- etapa, no solo las intermedias.
pokemonRequiredLevels = {
	-- capullos
	metapod = 10, kakuna = 10, silcoon = 10, cascoon = 10,
	-- etapas intermedias comunes
	pidgeotto = 20, staravia = 20, skiploom = 20,
	-- salen al principio pero son fuertes: no se pueden usar hasta el nivel 20
	gloom = 20, onix = 20, graveler = 20,
	flaaffy = 25, weepinbell = 25, nidorina = 25, nidorino = 25,
	golbat = 30, poliwhirl = 30, kirlia = 30, roselia = 30, lombre = 30, nuzleaf = 30,
	loudred = 30, luxio = 30, wormadam = 30,
	machoke = 35, kadabra = 35, haunter = 35, seadra = 35, vigoroth = 35, sealeo = 35,
	magneton = 40, chansey = 40, piloswine = 40, lairon = 40, vibrava = 40,
	slowbro = 45, dusclops = 45,
	rhydon = 50, porygon2 = 50,
	-- iniciales
	ivysaur = 35, charmeleon = 35, wartortle = 25, bayleef = 35, quilava = 35, croconaw = 35,
	grovyle = 35, combusken = 35, marshtomp = 35, grotle = 35, monferno = 35, prinplup = 35,
	-- finales de linea de 2 etapas (por defecto twoStageFinal)
	raticate = 20, furret = 20,
	ledian = 25, kricketune = 25, sunflora = 25, bibarel = 25, seaking = 25, lumineon = 25, cherrim = 25,
	raichu = 30, dodrio = 30, ariados = 30, persian = 30, fearow = 30, noctowl = 30, parasect = 30,
	venomoth = 30, dugtrio = 30, sandslash = 30, arbok = 30, electrode = 30, kingler = 30,
	wigglytuff = 30, clefable = 30, azumarill = 30, quagsire = 30,
	-- finales de linea de 3 etapas (por defecto final)
	butterfree = 25, beedrill = 25, beautifly = 40, dustox = 40, mothim = 40, jumpluff = 40,
	pidgeot = 50, bellossom = 50,
	vileplume = 55, victreebel = 55, shiftry = 55,
	staraptor = 60, ampharos = 60, luxray = 60, nidoking = 60, nidoqueen = 60, politoed = 60,
	poliwrath = 60, crobat = 60, roserade = 60, ludicolo = 60, exploud = 60, slowking = 60,
	walrein = 65, blissey = 65,
	venusaur = 70, charizard = 70, blastoise = 70, meganium = 70, typhlosion = 70, feraligatr = 70,
	sceptile = 70, blaziken = 70, swampert = 70, torterra = 70, infernape = 70, empoleon = 70,
	alakazam = 70, gengar = 70, machamp = 70, golem = 70, magnezone = 70, gardevoir = 70,
	dusknoir = 70, kingdra = 70, flygon = 70, aggron = 70, mamoswine = 70, rhyperior = 70,
	["porygon-z"] = 70, slaking = 70,
	dragonite = 80, tyranitar = 80, salamence = 80, metagross = 80, garchomp = 80,
	-- pseudo-legendarios (etapa media)
	dragonair = 55, pupitar = 55, shelgon = 55, metang = 55, gabite = 55,
}
shinyExtraLevel = 20
-- Pokemon salvajes: nivel de fuerza = nivel requerido de su especie (por wildPowerFactor).
-- Las formas base (nivel 0) se quedan con sus stats de especie; un Golem salvaje (70)
-- tiene la vida y el dano del Golem de un entrenador de nivel 70.
wildPowerFromSpecies = true
wildPowerFactor = 1.0
-- fuerza del salvaje distinta del nivel para usarlo (si no esta, se usa el nivel requerido).
-- Ejemplo: wildPowerLevels = {graveler = 15}
wildPowerLevels = {}
wildBaseHealthFactor = 0.75 -- vida de las formas base salvajes (nivel 0)
-- bebes que no cuentan como etapa (Pikachu sigue siendo base aunque exista Pichu)
babyPokemon = {pichu = true, cleffa = true, igglybuff = true, togepi = true, tyrogue = true,
	smoochum = true, elekid = true, magby = true, azurill = true, wynaut = true}
vitaminStatusBuff = 1.2
hunterDamageBuff = 1.1
blockerHealthBuff = 1.25
catcherCatchBuff = 1.1
explorerExperienceBuff = 1.15
healerHealBuff = 2.0

storageDelay = 1000
storageDelayBag = 1001
baseStorageTries = 61000
baseStorageCatches = 64000
baseStorageDex = 67000
baseStorageMove = 45000
baseStorageShinyCatchPity = 5000000 -- failed catch count per shiny species

-- Target cumulative catch chance without buffs, using the local Ultra Ball
-- (chanceMultiplier 1.4) as the reference. The per-attempt chance increases
-- linearly with consecutive failed attempts against that exact shiny form.
shinyCatchPityTiers = {
	T1 = {attempts = 450, chance = 0.50},
	T2 = {attempts = 200, chance = 0.60},
	T3 = {attempts = 150, chance = 0.60},
	T4 = {attempts = 120, chance = 0.60},
	T5 = {attempts = 100, chance = 0.60},
	T6 = {attempts = 70, chance = 0.60},
	T7 = {attempts = 50, chance = 0.60},
	["Super Rare"] = {attempts = 900, chance = 0.50},
	["Ultra Rare"] = {attempts = 1800, chance = 0.50},
	Legendary = {attempts = 3600, chance = 0.50}
}

-- Fixed catch chance for normal Pokemon by PKA tier, calibrated to local Ultra Ball x1.4.
normalCatchTierRates = {
	T1 = 0.0001, -- 0.01% per ball
	T2 = 0.001, -- 0.1% per ball
	T3 = 0.01, -- 1% per ball
	T4 = 0.05, -- 5% per ball
	T5 = 0.20, -- 20% per ball
	T6 = 0.50, -- 50% per ball
	T7 = 0.75 -- 75% per ball
}

storageRide = 5000
storageFly = 5001
storageSurf = 5002
storageEvolving = 5003
storageTutorial = 5004
storageDelayTeleport = 5005
storageBike = 5006
storageDelayDesbugar = 5007
storageDive = 5008
storageAutoLoot = 5009
storageBagEvent = 5010
storageArenaEvent = 5011
storageSoccerEvent = 5012
storageEvent = 5013
storageTokens = 5014
storageLastLegendaryKilled = 5015
storageDuelNpc = 5016
storageDuelNpcStatus = 5017
storageTeleportTc = 5018
storageEvolutionAncient = 5019
storageArenaPvpEvent = 5020
storageLogoutSpeed = 5021

storageCatchQuest = 91000
storageCatchQuestDay = 91001
storageCatchQuestNumber = 91002
storageCatchQuestStartCatch = 91003
storageCatchQuestTime = 91004
storageCatchQuestDifficulty = 91005

storageLeague = 91006
storageLeagueDone = 91007
storageLeagueTime = 91008
storageLeaguePotion = 91009
storageLeagueRevive = 910010

storageVictoryRoadTime = 91011

storageRedRequestPre = 91012

storageCatchQuestPoke = 91013

storageItemQuest = 91014
storageItemQuestDay = 91015
storageItemQuestNumber = 91016
storageItemQuestItem = 91017
storageItemQuestTime = 91018
storageItemQuestDifficulty = 91019

slotItems = {38680, 38682, 2263, 2270, 26820}
badgesPortraits = {26614, 26609, 26615, 26612, 26613, 26616, 26610, 26611, 38689, 38683, 38685, 38690, 38684, 38688, 38686, 38687}
badgeContainer = 38680
-- Cinturon pokemon: contenedor de 6 casillas en la casilla del pecho, solo para pokeballs.
-- El equipo (Pokebar, !p 1..6) empieza por el. Cliente: boton del cinturon en la barra de arriba.
pokemonBelt = 5927
pokemonBeltSlot = CONST_SLOT_ARMOR

waterIds = {493, 4608, 4609, 4610, 4611, 4612, 4613, 4614, 4615, 4616, 4617, 4618, 4619, 4620, 4621, 4622, 4623, 4624, 4625, 7236, 10499, 15401, 15402, 4820, 4821, 4822, 4823, 4824, 4825, 4664, 4665, 4666}

balls = {
pokeball = {emptyId = 26662, usedOn = 26661, usedOff = 26672, effectFail = 734, effectSucceed = 735, missile = 55, effectRelease = 308, chanceMultiplier = 1.0},
greatball = {emptyId = 26660, usedOn = 26663, usedOff = 26675, effectFail = 738, effectSucceed = 739, missile = 57, effectRelease = 309, chanceMultiplier = 1.2},
superball = {emptyId = 26659, usedOn = 26669, usedOff = 26674, effectFail = 736, effectSucceed = 737, missile = 56, effectRelease = 879, chanceMultiplier = 1.3},
ultraball = {emptyId = 26688, usedOn = 26670, usedOff = 26681, effectFail = 740, effectSucceed = 741, missile = 58, effectRelease = 311, chanceMultiplier = 1.4},
premierball = {emptyId = 26683, usedOn = 26666, usedOff = 26678, effectFail = 321, effectSucceed = 322, missile = 129, effectRelease = 310, chanceMultiplier = 1.5},
safariball = {emptyId = 26685, usedOn = 26667, usedOff = 26679, effectFail = 323, effectSucceed = 324, missile = 128, effectRelease = 315, chanceMultiplier = 1.0},
lamp = {emptyId = 2272, usedOn = 2325, usedOff = 23255, effectFail = 734, effectSucceed = 735, missile = 55, effectRelease = 308, chanceMultiplier = 1.0}
}

quests = 
{

catches = {
		prizes = {
			[1] = {
				uid = storageCatchQuest,
				items = {
				},
				pokes = {					
				},
				badges = {
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

itemTask = {
		prizes = {
			[1] = {
				uid = storageItemQuest,
				items = {
				},
				pokes = {					
				},
				badges = {
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

indigoLeague = {
		prizes = {
			[1] = {
				uid = storageLeagueDone,
				items = {
					[1] = {item = "indigo league trophy", count = 1}, 
					[2] = {item = "crystal coin", count = 50}, 
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 100, -- nivel para entrar en la Liga (antes 125; la historia llega a 90 con Giovanni)
		teleportCP = 0
	},



boulderBadge = {
		prizes = {
			[1] = {
				uid = 92000,
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 26614, add = 26608}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

cascadeBadge = {
		prizes = {
			[1] = {
				uid = 92001,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 26609, add = 26607}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

thunderBadge = {
		prizes = {
			[1] = {
				uid = 92002,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 26615, add = 26603}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

rainbowBadge = {
		prizes = {
			[1] = {
				uid = 92003,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 26612, add = 26602}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

soulBadge = {
		prizes = {
			[1] = {
				uid = 92004,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 26613, add = 26605}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

marshBadge = {
		prizes = {
			[1] = {
				uid = 92005,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 26616, add = 26606}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

volcanoBadge = {
		prizes = {
			[1] = {
				uid = 92006,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 26610, add = 26601}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

earthBadge = {
		prizes = {
			[1] = {
				uid = 92007,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 26611, add = 26604}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

zephyrBadge = {
		prizes = {
			[1] = {
				uid = 92008,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 38689, add = 38695}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},
hiveBadge = {
		prizes = {
			[1] = {
				uid = 92009,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 38683, add = 38694}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

plainBadge = {
		prizes = {
			[1] = {
				uid = 92010,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 38685, add = 38691}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

fogBadge = {
		prizes = {
			[1] = {
				uid = 92011,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 38690, add = 38693}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

stormBadge = {
		prizes = {
			[1] = {
				uid = 92012,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 38684, add = 38697}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

mineralBadge = {
		prizes = {
			[1] = {
				uid = 92013,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 38688, add = 38698}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

glacierBadge = {
		prizes = {
			[1] = {
				uid = 92014,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 38686, add = 38692}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

risingBadge = {
		prizes = {
			[1] = {
				uid = 92015,				
				items = {
				},
				pokes = {
				},
				badges = {
					[1] = {remove = 38687, add = 38696}, 
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

oakRequest = {
		prizes = {
			[1] = {
				uid = 92016,
				items = {
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 150, 
		teleportCP = 0
	},

thePokemaster = {
		prizes = {
			[1] = {
				uid = 92017,
				items = {
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 175, 
		teleportCP = 0
	},

redRequest = {
		prizes = {
			[1] = {
				uid = 92018,
				items = {
					[1] = {item = "unique ancient stone", count = 1},
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 175, 
		teleportCP = 0
	},

cathemAll = {
		prizes = {
			[1] = {
				uid = 92019,
				items = {
					[1] = {item = "ancient hieroglyph", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},

elderManQuest = {
		prizes = {
			[1] = {
				uid = 92020,
				items = {
					[1] = {item = "unique ancient stone", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 1, 
		teleportCP = 0
	},


lugia = {
		prizes = {
			[1] = {
				uid = 10200,
				items = {
					[1] = {item = "enigma stone", count = 100}, 
					[2] = {item = "water stone", count = 100}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 50, 
		teleportCP = 0
	},

moltres = {
		prizes = {
			[1] = {
				uid = 10201,
				items = {
					[1] = {item = "fire stone", count = 300}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 65, 
		teleportCP = 1
	},

articuno = {
		prizes = {
			[1] = {
				uid = 10202,
				items = {
					[1] = {item = "crystal coin", count = 2}, 
					[2] = {item = "ice stone", count = 100}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 55, 
		teleportCP = 1
	},

zapdos = {
		prizes = {
			[1] = {
				uid = 10203,
				items = {
					[1] = {item = "crystal coin", count = 4},
					[2] = {item = "thunder stone", count = 150}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 60, 
		teleportCP = 0
	},

poison = {
		prizes = {
			[1] = {
				uid = 10204,
				items = {
					[1] = {item = "platinum coin", count = 50}, 
					[2] = {item = "venom stone", count = 8}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 28, -- Ciudad Celeste (tramo 20-30) 
		teleportCP = 0
	},

punch = {
		prizes = {
			[1] = {
				uid = 10205,
				items = {
					[1] = {item = "platinum coin", count = 20}, 
					[2] = {item = "punch stone", count = 8}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 15, 
		teleportCP = 0
	},

--fight = {
--		prizes = {
--			[1] = {
--				uid = 10206,
--				items = {
--					[1] = {item = "punch stone", count = 2}, 
--					[2] = {item = "platinum coin", count = 10}
--				},
--				pokes = {
--					[1] = {name = "Machamp", level = 15, boost = 1}
--				},
--				badges = {
--				}
--			},
--			[2] = {
--				uid = 10207,
--				items = {
--					[1] = {item = "punch stone", count = 2}, 
--					[2] = {item = "platinum coin", count = 10}
--				},
--				pokes = {
--					[1] = {name = "Hitmonchan", level = 15, boost = 1}
--				},
--				badges = {
--				}
--			},
--			[3] = {
--				uid = 10208,
--				items = {
--					[1] = {item = "punch stone", count = 2}, 
--					[2] = {item = "platinum coin", count = 10}
--				},
--				pokes = {
--					[1] = {name = "Hitmonlee", level = 15, boost = 1}
--				},
--				badges = {
--				}
--			}
--		},
--		level = 10, 
--		teleportCP = 0
--	},

darkness = {
		prizes = {
			[1] = {
				uid = 10209,
				items = {
					[1] = {item = "darkness stone", count = 4}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 15, 
		teleportCP = 0
	},

rock = {
		prizes = {
			[1] = {
				uid = 10210,
				items = {
					[1] = {item = "rock stone", count = 4}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 22, -- entre Plateada y Celeste (tramo 20-30) 
		teleportCP = 0
	},

enigma = {
		prizes = {
			[1] = {
				uid = 10211,
				items = {
					[1] = {item = "enigma stone", count = 8},
					[2] = {item = "platinum coin", count = 50}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 25, 
		teleportCP = 0
	},

rock2 = {
		prizes = {
			[1] = {
				uid = 10212,
				items = {
					[1] = {item = "rock stone", count = 8},
					[2] = {item = "platinum coin", count = 30}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 18, -- junto a Ciudad Plateada: antes de Brock (tope 20) 
		teleportCP = 0
	},

thundershiny = {
		prizes = {
			[1] = {
				uid = 10213,
				items = {
				},
				pokes = {
					[1] = {name = "Shiny Electabuzz", level = 35, boost = 5}
				},
				badges = {
				}
			},
			[2] = {
				uid = 10214,
				items = {
				},
				pokes = {
					[1] = {name = "Shiny Jolteon", level = 35, boost = 5}
				},
				badges = {
				}
			}
		},
		level = 90, 
		teleportCP = 0
	},

shiningbox = {
		prizes = {
			[1] = {
				uid = 10215,
				items = {
					[1] = {item = "box 5", count = 1},
					[2] = {item = "crystal coin", count = 100}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 200, 
		teleportCP = 0
	},

fire = {
		prizes = {
			[1] = {
				uid = 10216,
				items = {
					[1] = {item = "fire stone", count = 70}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 50, 
		teleportCP = 0
	},

subterranea = {
		prizes = {
			[1] = {
				uid = 10217,
				items = {
					[1] = {item = "crystal coin", count = 1},
					[2] = {item = "water stone", count = 5}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 35, -- Ciudad Azafran (tramo 30-40) 
		teleportCP = 0
	},

earth = {
		prizes = {
			[1] = {
				uid = 10218,
				items = {
					[1] = {item = "platinum coin", count = 50},
					[2] = {item = "earth stone", count = 2}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 32, -- al noreste de Celeste (tramo 30-40) 
		teleportCP = 0
	},

firenostrus = {
		prizes = {
			[1] = {
				uid = 10219,
				items = {
					[1] = {item = "fire stone", count = 50}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 75, -- cerca de Isla Canela (tramo 70-80) 
		teleportCP = 0
	},

rock3 = {
		prizes = {
			[1] = {
				uid = 10220,
				items = {
					[1] = {item = "rock stone", count = 5},
					[2] = {item = "platinum coin", count = 50}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 50, -- Pueblo Lavanda (tramo 50-60, con Sabrina) 
		teleportCP = 0
	},

annihilator = {
		prizes = {
			[1] = {
				uid = 10221,
				items = {
					[1] = {item = "crystal coin", count = 5}
				},
				pokes = {
					[1] = {name = "Shiny Porygon", level = 35, boost = 10}					
				},
				badges = {
				}
			},
			[2] = {
				uid = 10222,
				items = {
					[1] = {item = "crystal coin", count = 5}
				},
				pokes = {
					[1] = {name = "Shiny Hypno", level = 35, boost = 10}	
				},
				badges = {
				}
			},
			[3] = {
				uid = 10223,
				items = {
					[1] = {item = "crystal coin", count = 5}
				},
				pokes = {
					[1] = {name = "Shiny Alakazam", level = 35, boost = 10}	
				},
				badges = {
				}
			}
		},
		level = 100, 
		teleportCP = 0
	},

darkness2 = {
		prizes = {
			[1] = {
				uid = 10224,
				items = {
					[1] = {item = "darkness stone", count = 4},
					[2] = {item = "crystal coin", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 20, 
		teleportCP = 0
	},

enigma2 = {
		prizes = {
			[1] = {
				uid = 10225,
				items = {
					[1] = {item = "enigma stone", count = 80},
					[2] = {item = "crystal coin", count = 5}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 60, 
		teleportCP = 0
	},

shinymoltres = {
		prizes = {
			[1] = {
				uid = 10226,
				items = {
					[1] = {item = "fire stone", count = 200},
					[2] = {item = "crystal coin", count = 5}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 95, 
		teleportCP = 0
	},

outlandleaf = {
		prizes = {
			[1] = {
				uid = 10227,
				items = {
					[1] = {item = "leaf stone", count = 30},
					[2] = {item = "crystal coin", count = 2}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 38, 
		teleportCP = 0
	},

outlandcelebi = {
		prizes = {
			[1] = {
				uid = 10228,
				items = {
					[1] = {item = "leaf stone", count = 80},
					[2] = {item = "crystal coin", count = 4}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 65, 
		teleportCP = 0
	},

outlandaquatica = {
		prizes = {
			[1] = {
				uid = 10229,
				items = {
					[1] = {item = "water stone", count = 70},
					[2] = {item = "crystal coin", count = 3}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 70, 
		teleportCP = 0
	},

outlandpsiquica = {
		prizes = {
			[1] = {
				uid = 10230,
				items = {
					[1] = {item = "enigma stone", count = 80},
					[2] = {item = "crystal coin", count = 2}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 55, 
		teleportCP = 0
	},

outlandsteel = {
		prizes = {
			[1] = {
				uid = 10231,
				items = {
					[1] = {item = "metal coat", count = 30},
					[2] = {item = "crystal coin", count = 5}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 65, 
		teleportCP = 0
	},

outlandfire = {
		prizes = {
			[1] = {
				uid = 10232,
				items = {
					[1] = {item = "fire stone", count = 80},
					[2] = {item = "crystal coin", count = 2}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 50, 
		teleportCP = 0
	},

outlandregirock = {
		prizes = {
			[1] = {
				uid = 10233,
				items = {
					[1] = {item = "rock stone", count = 100},
					[2] = {item = "crystal coin", count = 5}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 80, 
		teleportCP = 0
	},

outlandfight = {
		prizes = {
			[1] = {
				uid = 10234,
				items = {
					[1] = {item = "punch stone", count = 20},
					[2] = {item = "crystal coin", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 20, 
		teleportCP = 0
	},

outlandpoison = {
		prizes = {
			[1] = {
				uid = 10235,
				items = {
					[1] = {item = "venom stone", count = 20},
					[2] = {item = "crystal coin", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 15, 
		teleportCP = 0
	},

outlandarticuno = {
		prizes = {
			[1] = {
				uid = 10236,
				items = {
					[1] = {item = "ice stone", count = 80},
					[2] = {item = "crystal coin", count = 3}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 60, 
		teleportCP = 0
	},

outlandheart = {
		prizes = {
			[1] = {
				uid = 10237,
				items = {
					[1] = {item = "heart stone", count = 10},
					[2] = {item = "platinum coin", count = 50}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 25, 
		teleportCP = 0
	},

outlandnature = {
		prizes = {
			[1] = {
				uid = 10238,
				items = {
					[1] = {item = "leaf stone", count = 80}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 45, 
		teleportCP = 0
	},

outlandice = {
		prizes = {
			[1] = {
				uid = 10239,
				items = {
					[1] = {item = "ice stone", count = 25}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 30, 
		teleportCP = 0
	},

outlandzapdos = {
		prizes = {
			[1] = {
				uid = 10240,
				items = {
					[1] = {item = "crystal coin", count = 4},
					[2] = {item = "thunder stone", count = 40}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 65, 
		teleportCP = 0
	},

mtmoon = {
		prizes = {
			[1] = {
				uid = 10241,
				items = {
					[1] = {item = "crystal coin", count = 1},
					[2] = {item = "heart stone", count = 30}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 25, -- Mt. Moon se cruza en el tramo 20-30 
		teleportCP = 0
	},

lavendermaze = {
		prizes = {
			[1] = {
				uid = 10242,
				items = {
					[1] = {item = "crystal coin", count = 1},
					[2] = {item = "darkness stone", count = 30}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 55, -- Pueblo Lavanda (tramo 50-60) 
		teleportCP = 0
	},

outlandShinyCelebi = {
		prizes = {
			[1] = {
				uid = 10243,
				items = {
					[1] = {item = "crystal coin", count = 3},
					[2] = {item = "leaf stone", count = 100}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 65, 
		teleportCP = 0
	},

mewDungeon = {
		prizes = {
			[1] = {
				uid = 10244,
				items = {
					[1] = {item = "crystal coin", count = 10},
					[2] = {item = "mew bag", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 175, 
		teleportCP = 0
	},

ceruleanCave = {
		prizes = {
			[1] = {
				uid = 10245,
				items = {
					[1] = {item = "crystal coin", count = 10},
					[2] = {item = "crystal stone", count = 100},
					[3] = {item = "mewtwo bag", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			},
			[2] = {
				uid = 10246,
				items = {
					[1] = {item = "crystal coin", count = 10},
					[2] = {item = "darkness stone", count = 100},
					[3] = {item = "mewtwo bag", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			},
			[3] = {
				uid = 10247,
				items = {
					[1] = {item = "crystal coin", count = 10},
					[2] = {item = "heart stone", count = 100},
					[3] = {item = "mewtwo bag", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 150, 
		teleportCP = 0
	},

coldPortal = {
		prizes = {
			[1] = {
				uid = 10248,
				items = {
					[1] = {item = "crystal coin", count = 100},
					[2] = {item = "ice stone", count = 100}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 100, 
		teleportCP = 1
	},

azaleaQuest = {
		prizes = {
			[1] = {
				uid = 10249,
				items = {
					[1] = {item = "crystal coin", count = 10}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 30, 
		teleportCP = 0
	},

latiosLabyrinth = {
		prizes = {
			[1] = {
				uid = 10250,
				items = {
					[1] = {item = "crystal coin", count = 50},
					[2] = {item = "empty premierball", count = 50}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 80, 
		teleportCP = 1
	},

terrorQuest = {
		prizes = {
			[1] = {
				uid = 10251,
				items = {
					[1] = {item = "crystal coin", count = 130},
					[2] = {item = "empty premierball", count = 70},
					[3] = {item = "box 4", count = 1}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 150, 
		teleportCP = 1
	},

secretSaffron = {
		prizes = {
			[1] = {
				uid = 10252,
				items = {
					[1] = {item = "empty ultraball", count = 50},
					[2] = {item = "revive", count = 20}
				},
				pokes = {
				},
				badges = {
				}
			}
		},
		level = 35, -- Ciudad Azafran (antes nivel 1) 
		teleportCP = 1
	},

}

function buildDex()
	monstersTable = {}
	local monstersName = getMonstersName()
	for i = 1, #monstersName do
		local monsterNumber = MonsterType(monstersName[i]):dexEntry()
		if monsterNumber > 0 then
			monstersTable[monsterNumber] = monstersName[i]
		end
	end
	print("WARNING! Pokedex successfully built.")
end

function getBlessingsCost(level)
	if level <= 30 then
		return 2000
	elseif level >= 120 then
		return 20000
	else
		return (level - 20) * 200
	end
end

function getPvpBlessingCost(level)
	if level <= 30 then
		return 2000
	elseif level >= 270 then
		return 50000
	else
		return (level - 20) * 200
	end
end

function getTibianTime()
	local worldTime = getWorldTime()
	local hours = math.floor(worldTime / 60)

	local minutes = worldTime % 60
	if minutes < 10 then
		minutes = '0' .. minutes
	end
	return hours .. ':' .. minutes
end

function getNeededExp(level) return (50 * (level * level * level - 6 * level * level + 17 * level - 12) / 3) end

function getPokemonShinyStatMultiplier(name)
	return type(name) == "string" and name:sub(1, 6):lower() == "shiny " and shinyStatMultiplier or 1.0
end

local function getShinyStatMultiplier(monster)
	return getPokemonShinyStatMultiplier(monster:getName())
end

function trainerLevelCurve(level)
	level = tonumber(level) or 0
	if level <= 0 then
		return 1.0
	end
	local early = math.min(level, trainerCurveEarlyCap)
	local late = math.max(level - trainerCurveEarlyCap, 0)
	return trainerCurveBase + early * trainerCurveEarly + late * trainerCurveLate
end

function statusGainFormula(playerLevel, summonLevel, summonBoost, pokeLove)
	-- pokemon de jugador (playerLevel > 0): su fuerza depende del nivel del entrenador
	if playerLevel and playerLevel > 0 then
		return (trainerLevelCurve(playerLevel) + (summonBoost or 0) * summonBoostDamageBuff + (pokeLove or 0) * summonLoveDamageBuff)
	end
	-- Pokemon salvajes usan stats base de especie (nivel 0 -> 1.0); summonLevel solo aplica a equipos NPC.
	return (trainerLevelCurve(summonLevel) + (summonBoost or 0) * summonBoostDamageBuff + (pokeLove or 0) * summonLoveDamageBuff)
end

function damageFormula(playerLevel, summonLevel, summonBoost, pokeLove)
	return statusGainFormula(playerLevel, summonLevel, summonBoost, pokeLove)
end

function defenseFormula(playerLevel, summonLevel, summonBoost, pokeLove)
	return (1.0 / 600.0 * statusGainFormula(playerLevel, summonLevel, summonBoost, pokeLove))
end

function getBallKey(uid)
	for key, value in pairs(balls) do
		if uid == value.emptyId or uid == value.usedOn or uid == value.usedOff then
			return key
		end
	end
	return "pokeball"
end

function Monster.getTotalHealth(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then
		local shinyMultiplier = getShinyStatMultiplier(self)
		local total = math.floor(monsterType:getMaxHealth() * statusGainFormula(self:getMaster():getLevel(), self:getLevel(), self:getBoost(), self:getLove()) * shinyMultiplier)
		if self:getMaster():getVocation():getName() == "Blocker" then
			total = total + math.floor(total * (blockerHealthBuff - 1.0))
		end
		local vitamins = self:getUsedVitaminsNumber("hp")
		if vitamins > 0 then
			total = total + math.floor(monsterType:getMaxHealth() * vitamins / maxVitamins * vitaminStatusBuff * shinyMultiplier)
		end
		return total
	elseif self:isMonster() then
		local total = math.floor(monsterType:getMaxHealth() * statusGainFormula(0, self:getPowerLevel(), 0, 0) * getShinyStatMultiplier(self))
		-- formas base salvajes (nivel de fuerza 0): un poco menos de vida, para que los
		-- primeros niveles no se hagan pesados
		if wildBaseHealthFactor and not self:getMaster() and monsterType:dexEntry() > 0 and self:getPowerLevel() == 0 then
			total = math.floor(total * wildBaseHealthFactor)
		end
		return total
	end
	return 0
end

function Monster.getTotalHealthVocationContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then
		if self:getMaster():getVocation():getName() == "Blocker" then
			return math.floor(monsterType:getMaxHealth() * statusGainFormula(self:getMaster():getLevel(), self:getLevel(), self:getBoost(), self:getLove()) * (blockerHealthBuff - 1.0))
		end
	end
	return 0
end

function Monster.getTotalHealthPlayerContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		return math.floor(monsterType:getMaxHealth() * (statusGainFormula(self:getMaster():getLevel(), 0, 0, 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalHealthSummonLevelContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isMonster() and not self:isPokemon() then
		return math.floor(monsterType:getMaxHealth() * (statusGainFormula(0, self:getPowerLevel(), 0, 0) - statusGainFormula(0, 0, 0, 0)))
	end	
	return 0
end

function Monster.getTotalHealthSummonBoostContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		return math.floor(monsterType:getMaxHealth() * (statusGainFormula(0, 0, self:getBoost(), 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalHealthSummonVitaminContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		local vitamins = self:getUsedVitaminsNumber("hp")
		if vitamins > 0 then
			return math.floor(monsterType:getMaxHealth() * vitamins / maxVitamins * vitaminStatusBuff * getShinyStatMultiplier(self))
		end
	end
	return 0
end

function MonsterType.getMeleeDamage(self)
	local minMelee = 0
	local maxMelee = 0
	for i = 1, #self:getAttackList() do
		if self:getAttackList()[i].isMelee == 1 then	
			minMelee = minMelee - self:getAttackList()[i].minCombatValue		
			maxMelee = maxMelee - self:getAttackList()[i].maxCombatValue			
		end
	end
	local aveMelee = (minMelee + maxMelee) / 2
	return math.floor(aveMelee)
end

function Monster.getTotalMeleeAttack(self)
	local monsterType = MonsterType(self:getName())
	local minMelee = 0
	local maxMelee = 0
	for i = 1, #monsterType:getAttackList() do
		if monsterType:getAttackList()[i].isMelee == 1 then	
			minMelee = minMelee - monsterType:getAttackList()[i].minCombatValue		
			maxMelee = maxMelee - monsterType:getAttackList()[i].maxCombatValue			
		end
	end
	local aveMelee = (minMelee + maxMelee) / 2
	if self:isPokemon() then 
		local shinyMultiplier = getShinyStatMultiplier(self)
		local total = math.floor(aveMelee * statusGainFormula(self:getMaster():getLevel(), self:getLevel(), self:getBoost(), self:getLove()) * shinyMultiplier)
		if self:getMaster():getVocation():getName() == "Hunter" then
			total = total + math.floor(total * (hunterDamageBuff - 1.0))
		end
		local vitamins = self:getUsedVitaminsNumber("attack")
		if vitamins > 0 then
			total = total + math.floor(aveMelee * vitamins / maxVitamins * vitaminStatusBuff * shinyMultiplier)
		end
		return total
	elseif self:isMonster() then
		return math.floor(aveMelee * statusGainFormula(0, self:getPowerLevel(), 0, 0) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalMeleeAttackPlayerContribution(self)
	local monsterType = MonsterType(self:getName())
	local minMelee = 0
	local maxMelee = 0
	for i = 1, #monsterType:getAttackList() do
		if monsterType:getAttackList()[i].isMelee == 1 then	
			minMelee = minMelee - monsterType:getAttackList()[i].minCombatValue		
			maxMelee = maxMelee - monsterType:getAttackList()[i].maxCombatValue			
		end
	end
	local aveMelee = (minMelee + maxMelee) / 2
	if self:isPokemon() then 
		return math.floor(aveMelee * (statusGainFormula(self:getMaster():getLevel(), 0, 0, 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalMeleeAttackSummonLevelContribution(self)
	local monsterType = MonsterType(self:getName())
	local minMelee = 0
	local maxMelee = 0
	for i = 1, #monsterType:getAttackList() do
		if monsterType:getAttackList()[i].isMelee == 1 then	
			minMelee = minMelee - monsterType:getAttackList()[i].minCombatValue		
			maxMelee = maxMelee - monsterType:getAttackList()[i].maxCombatValue			
		end
	end
	local aveMelee = (minMelee + maxMelee) / 2
	if self:isMonster() and not self:isPokemon() then
		return math.floor(aveMelee * (statusGainFormula(0, self:getPowerLevel(), 0, 0) - statusGainFormula(0, 0, 0, 0)))
	end
	return 0
end

function Monster.getTotalMeleeAttackSummonBoostContribution(self)
	local monsterType = MonsterType(self:getName())
	local minMelee = 0
	local maxMelee = 0
	for i = 1, #monsterType:getAttackList() do
		if monsterType:getAttackList()[i].isMelee == 1 then	
			minMelee = minMelee - monsterType:getAttackList()[i].minCombatValue		
			maxMelee = maxMelee - monsterType:getAttackList()[i].maxCombatValue			
		end
	end
	local aveMelee = (minMelee + maxMelee) / 2
	if self:isPokemon() then 
		return math.floor(aveMelee * (statusGainFormula(0, 0, self:getBoost(), 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalMeleeAttackVocationContribution(self)
	local monsterType = MonsterType(self:getName())
	local minMelee = 0
	local maxMelee = 0
	for i = 1, #monsterType:getAttackList() do
		if monsterType:getAttackList()[i].isMelee == 1 then	
			minMelee = minMelee - monsterType:getAttackList()[i].minCombatValue		
			maxMelee = maxMelee - monsterType:getAttackList()[i].maxCombatValue			
		end
	end
	local aveMelee = (minMelee + maxMelee) / 2
	if self:isPokemon() then 
		if self:getMaster():getVocation():getName() == "Hunter" then
			return math.floor(aveMelee * statusGainFormula(self:getMaster():getLevel(), self:getLevel(), self:getBoost(), self:getLove()) * (hunterDamageBuff - 1.0) * getShinyStatMultiplier(self))
		end
	end
	return 0
end

function Monster.getTotalMeleeAttackVitaminContribution(self)
	local monsterType = MonsterType(self:getName())
	local minMelee = 0
	local maxMelee = 0
	for i = 1, #monsterType:getAttackList() do
		if monsterType:getAttackList()[i].isMelee == 1 then	
			minMelee = minMelee - monsterType:getAttackList()[i].minCombatValue		
			maxMelee = maxMelee - monsterType:getAttackList()[i].maxCombatValue			
		end
	end
	local aveMelee = (minMelee + maxMelee) / 2
	if self:isPokemon() then
		local vitamins = self:getUsedVitaminsNumber("attack")
		if vitamins > 0 then
			return math.floor(aveMelee * vitamins / maxVitamins * vitaminStatusBuff * getShinyStatMultiplier(self))
		end
	end
	return 0
end

function Monster.getTotalMagicAttack(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then
		local shinyMultiplier = getShinyStatMultiplier(self)
		local total = math.floor(monsterType:getMoveMagicAttackBase() * statusGainFormula(self:getMaster():getLevel(), self:getLevel(), self:getBoost(), self:getLove()) * shinyMultiplier)
		if self:getMaster():getVocation():getName() == "Hunter" then
			total = total + math.floor(total * (hunterDamageBuff - 1.0))
		end
		local vitamins = self:getUsedVitaminsNumber("magicAttack")
		if vitamins > 0 then
			total = total + math.floor(monsterType:getMoveMagicAttackBase() * vitamins / maxVitamins * vitaminStatusBuff * shinyMultiplier)
		end
		return total
	elseif self:isMonster() then
		return math.floor(monsterType:getMoveMagicAttackBase() * statusGainFormula(0, self:getPowerLevel(), 0, 0) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalMagicAttackVocationContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then
		if self:getMaster():getVocation():getName() == "Hunter" then
			return math.floor(monsterType:getMoveMagicAttackBase() * statusGainFormula(self:getMaster():getLevel(), self:getLevel(), self:getBoost(), self:getLove()) * (hunterDamageBuff - 1.0) * getShinyStatMultiplier(self))
		end
	end
	return 0
end

function Monster.getTotalMagicAttackPlayerContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		return math.floor(monsterType:getMoveMagicAttackBase() * (statusGainFormula(self:getMaster():getLevel(), 0, 0, 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalMagicAttackSummonLevelContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isMonster() and not self:isPokemon() then
		return math.floor(monsterType:getMoveMagicAttackBase() * (statusGainFormula(0, self:getPowerLevel(), 0, 0) - statusGainFormula(0, 0, 0, 0)))
	end
	return 0
end

function Monster.getTotalMagicAttackSummonBoostContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		return math.floor(monsterType:getMoveMagicAttackBase() * (statusGainFormula(0, 0, self:getBoost(), 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalMagicAttackVitaminContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		local vitamins = self:getUsedVitaminsNumber("magicAttack")
		if vitamins > 0 then
			return math.floor(monsterType:getMoveMagicAttackBase() * vitamins / maxVitamins * vitaminStatusBuff * getShinyStatMultiplier(self))
		end
	end
	return 0
end

function Monster.getTotalDefense(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then
		local shinyMultiplier = getShinyStatMultiplier(self)
		local total = math.floor(monsterType:getDefense() * statusGainFormula(self:getMaster():getLevel(), self:getLevel(), self:getBoost(), self:getLove()) * shinyMultiplier)
		local vitamins = self:getUsedVitaminsNumber("defense")
		if vitamins > 0 then
			total = total + math.floor(monsterType:getDefense() * vitamins / maxVitamins * vitaminStatusBuff * shinyMultiplier)
		end
		return total
	elseif self:isMonster() then
		return math.floor(monsterType:getDefense() * statusGainFormula(0, self:getPowerLevel(), 0, 0) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalDefensePlayerContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		return math.floor(monsterType:getDefense() * (statusGainFormula(self:getMaster():getLevel(), 0, 0, 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalDefenseSummonLevelContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isMonster() and not self:isPokemon() then
		return math.floor(monsterType:getDefense() * (statusGainFormula(0, self:getPowerLevel(), 0, 0) - statusGainFormula(0, 0, 0, 0)))
	end
	return 0
end

function Monster.getTotalDefenseSummonBoostContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		return math.floor(monsterType:getDefense() * (statusGainFormula(0, 0, self:getBoost(), 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalDefenseVitaminContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		local vitamins = self:getUsedVitaminsNumber("defense")
		if vitamins > 0 then
			return math.floor(monsterType:getDefense() * vitamins / maxVitamins * vitaminStatusBuff * getShinyStatMultiplier(self))
		end
	end
	return 0
end


function Monster.getTotalMagicDefense(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		local shinyMultiplier = getShinyStatMultiplier(self)
		local total = math.floor(monsterType:getMoveMagicDefenseBase() * statusGainFormula(self:getMaster():getLevel(), self:getLevel(), self:getBoost(), self:getLove()) * shinyMultiplier)
		local vitamins = self:getUsedVitaminsNumber("magicDefense")
		if vitamins > 0 then
			total = total + math.floor(monsterType:getMoveMagicDefenseBase() * vitamins / maxVitamins * vitaminStatusBuff * shinyMultiplier)
		end
		return total
	elseif self:isMonster() then
		return math.floor(monsterType:getMoveMagicDefenseBase() * statusGainFormula(0, self:getPowerLevel(), 0, 0) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalMagicDefensePlayerContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		return math.floor(monsterType:getMoveMagicDefenseBase() * (statusGainFormula(self:getMaster():getLevel(), 0, 0, 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end

function Monster.getTotalMagicDefenseSummonLevelContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isMonster() and not self:isPokemon() then
		return math.floor(monsterType:getMoveMagicDefenseBase() * (statusGainFormula(0, self:getPowerLevel(), 0, 0) - statusGainFormula(0, 0, 0, 0)))
	end
	return 0
end

function Monster.getTotalMagicDefenseSummonBoostContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		return math.floor(monsterType:getMoveMagicDefenseBase() * (statusGainFormula(0, 0, self:getBoost(), 0) - statusGainFormula(0, 0, 0, 0)) * getShinyStatMultiplier(self))
	end
	return 0
end



function Monster.getTotalMagicDefenseVitaminContribution(self)
	local monsterType = MonsterType(self:getName())
	if self:isPokemon() then 
		local vitamins = self:getUsedVitaminsNumber("magicDefense")
		if vitamins > 0 then
			return math.floor(monsterType:getMoveMagicDefenseBase() * vitamins / maxVitamins * vitaminStatusBuff * getShinyStatMultiplier(self))
		end
	end
	return 0
end











function Monster.getTotalSpeed(self)
	local monsterType = MonsterType(self:getName())
	return monsterType and math.floor(monsterType:getBaseSpeed() * getShinyStatMultiplier(self)) or 220
end

function Monster.getTotalSpeedPlayerContribution(self)
	return 0
end

function Monster.getTotalSpeedSummonLevelContribution(self)
	return 0
end

function Monster.getTotalSpeedSummonBoostContribution(self)
	return 0
end

function Monster.getTotalSpeedVitaminContribution(self)
	return 0
end

function Creature.isPokemon(self)
	local master = self:getMaster()
	if master and master:isPlayer() then return true end
	return false
end

function Monster.getMonsterNumber(self)
	return MonsterType(self:getName()):dexEntry()

--	local name = self:getName()
--	local output = 0
--	for _,v in pairs(monsterNumber) do
--		if name == v[1] then
--			output = v[2]
--			break
--		end
--	end 
--	return output
end

function MonsterType.getNumber(self)
	return self:dexEntry()
--	local name = self:getName()
--	local output = 0
--	for _,v in pairs(monsterNumber) do
--		if name == v[1] then
--			output = v[2]
--			break
--		end
--	end 
--	return output
end

function hasSummons(cid)
	local summons = cid:getSummons()
	if #summons > 0 then
		return true
	end
	return false
end

--function MonsterType.getMeleeMaxDamage(self)
--	for i = 1, #self:getAttackList() do
--		if self:getAttackList()[i].isMelee == 1 then
--			
--			return -self:getAttackList()[i].maxCombatValue
--		end
--	end
--	return 0
--end

--function MonsterType.getMeleeMinDamage(self)
--	for i = 1, #self:getAttackList() do
--		if self:getAttackList()[i].isMelee == 1 then
--			return -self:getAttackList()[i].minCombatValue
--		end
--	end
--	return 0
--end

--function MonsterType.getMagicMaxDamage(self)
--	local damage = 0
--	for i = 1, #self:getAttackList() do
--		if self:getAttackList()[i].isMelee == 0 then
--			damage = damage - self:getAttackList()[i].maxCombatValue 
--		end
--	end
--	return damage
--end

--function MonsterType.getMagicMinDamage(self)
--	local damage = 0
--	for i = 1, #self:getAttackList() do
--		if self:getAttackList()[i].isMelee == 0 then
--			damage = damage - self:getAttackList()[i].minCombatValue 
--		end
--	end
--	return damage
--end

function Player.checkExhaustion(self, storage, delay)
	if os.time() > self:getStorageValue(storage) then
		self:setStorageValue(storage, os.time() + delay)
	else
		self:sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED)
		self:getPosition():sendMagicEffect(CONST_ME_POFF)
		return true		
	end
	return false
end

function Player.checkMoveExhaustion(self, storage, delay)
--	local item = self:getSlotItem(CONST_SLOT_AMMO)
	local item = self:getUsingBall()
	if item then
		local move = "cd" .. tostring(storage)
		local moveCooldown = item:getSpecialAttribute(move) or 0
		if os.time() > moveCooldown then
			item:setSpecialAttribute(move, os.time() + delay)
		else
			self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You must wait " .. math.floor(item:getSpecialAttribute(move) + 1 - os.time()) .. " seconds to use this move again")
			self:getPosition():sendMagicEffect(CONST_ME_POFF)
			return true		
		end
	end
	return false
end

function Player.getSummonNameFromBall(self)
--	local item = self:getSlotItem(CONST_SLOT_AMMO)
	local item = self:getUsingBall()
	if item then
		local pokeName = item:getSpecialAttribute("pokeName")
		if pokeName ~= nil then			
			return pokeName
		end
	end
	return "unamed"
end

function Player.getSummonBoostFromBall(self)
--	local item = self:getSlotItem(CONST_SLOT_AMMO)
	local item = self:getUsingBall()
	if item then
		local pokeBoost = item:getSpecialAttribute("pokeBoost")
		if pokeBoost ~= nil then			
			return pokeBoost
		end
	end
	return 0
end

function Player.getUsingBall(self)
	local pokeballs = self:getPokeballs()
--	local pokeballs = self:getSpecialStorage("pokes") --stability problems
	if not pokeballs then
		print("WARNING! UsingBall not found player " .. self:getName())
		return nil
	end
	for i = 1, #pokeballs do

		local ball = pokeballs[i]
		if not ball then return end
		local isBallBeingUsed = ball:getSpecialAttribute("isBeingUsed")
		if isBallBeingUsed and isBallBeingUsed == 1 then
			return ball
		end
	end
--	local item = self:getSlotItem(CONST_SLOT_AMMO)
--	if item then
--		return item
--	end
end

function MonsterType.getRaceName(self)
	local raceNumber = self:getRace()
	if raceNumber == 1 then return "venon" end
	if raceNumber == 2 then return "blood" end
	if raceNumber == 3 then return "undead" end
	if raceNumber == 4 then return "fire" end
	if raceNumber == 5 then return "energy" end
	if raceNumber == 6 then return "grass" end
	if raceNumber == 7 then return "normal" end
	if raceNumber == 8 then return "water" end
	if raceNumber == 9 then return "flying" end
	if raceNumber == 10 then return "poison" end
	if raceNumber == 11 then return "electric" end
	if raceNumber == 12 then return "ground" end
	if raceNumber == 13 then return "psychic" end
	if raceNumber == 14 then return "rock" end
	if raceNumber == 15 then return "ice" end
	if raceNumber == 16 then return "bug" end
	if raceNumber == 17 then return "dragon" end
	if raceNumber == 18 then return "ghost" end
	if raceNumber == 19 then return "dark" end
	if raceNumber == 20 then return "steel" end
	if raceNumber == 21 then return "fairy" end
	if raceNumber == 22 then return "fighting" end
	return "none"
end

function MonsterType.getRace2Name(self)
	local raceNumber = self:getRace2()
	if raceNumber == 1 then return "venon" end
	if raceNumber == 2 then return "blood" end
	if raceNumber == 3 then return "undead" end
	if raceNumber == 4 then return "fire" end
	if raceNumber == 5 then return "energy" end
	if raceNumber == 6 then return "grass" end
	if raceNumber == 7 then return "normal" end
	if raceNumber == 8 then return "water" end
	if raceNumber == 9 then return "flying" end
	if raceNumber == 10 then return "poison" end
	if raceNumber == 11 then return "electric" end
	if raceNumber == 12 then return "ground" end
	if raceNumber == 13 then return "psychic" end
	if raceNumber == 14 then return "rock" end
	if raceNumber == 15 then return "ice" end
	if raceNumber == 16 then return "bug" end
	if raceNumber == 17 then return "dragon" end
	if raceNumber == 18 then return "ghost" end
	if raceNumber == 19 then return "dark" end
	if raceNumber == 20 then return "steel" end
	if raceNumber == 21 then return "fairy" end
	if raceNumber == 22 then return "fighting" end
	return "none"
end

--function searchInContainer(container, itemId)
--	local count = 0
--	if container:isContainer() then
--		for i = 0, container:getSize() do
--			local item = container:getItem(i)
--			if item then
--				if item:isContainer() then
--					if item:getId() == itemId then
--						count = count + item:getCount()
--					end
--					count = count + searchInContainer(item, itemId)
--				elseif item:getId() == itemId then
--					count = count + item:getCount()
--				end
--			end
--		end
--	end
--	return count
--end

function teleportMonster(cid, position)
    local monster = Monster(cid)
    if monster then
        monster:teleportTo(position)
    end
end
 
function Player.getSummon(self)
	if hasSummons(self) then
		return self:getSummons()[1]
	end
	return false
end

function Player.isOnRide(self)
	if self:getStorageValue(storageRide) > 0 then
		return true
	end
	return false
end

function Player.isOnFly(self)
	if self:getStorageValue(storageFly) > 0 then
		return true
	end
	return false
end

function Player.isOnSurf(self)
	if self:getStorageValue(storageSurf) > 0 then
		return true
	end
	return false
end

function Player.isOnBike(self)
	if self:getStorageValue(storageBike) == 1 then
		return true
	end
	return false
end

function Player.isOnEvent(self)
	if self:getStorageValue(storageEvent) == 1 then
		return true
	end
	return false
end

function Player.isOnDive(self)
	if self:getStorageValue(storageDive) == 1 then
		return true
	end
	return false
end

function Player.isAutoLooting(self)
	if self:getStorageValue(storageAutoLoot) == 1 then
		return true
	end
	return false
end

function Player.enableAutoLoot(self)
	if self:getStorageValue(storageAutoLoot) < 0 then
		self:setStorageValue(storageAutoLoot, 1)
		return true
	end
	return false
end

function Player.disableAutoLoot(self)
	if self:getStorageValue(storageAutoLoot) == 1 then
		self:setStorageValue(storageAutoLoot, -1)
		return true
	end
	return false
end

-- Pokemon de jugador escalan con el entrenador; los de NPC conservan el nivel configurado.
-- Los salvajes usan sus stats base de especie, sin escalado por nivel o etapa.
function Monster.getPowerLevel(self)
	local master = self:getMaster()
	if master then
		return master:isPlayer() and master:getLevel() or self:getLevel()
	end
	if MonsterType(self:getName()):dexEntry() <= 0 then
		return self:getLevel() -- monstruos que no son pokemon
	end
	-- salvajes: fuerza del nivel que pide su especie (ver wildPowerFromSpecies) o la de wildPowerLevels
	local override = wildPowerLevels and wildPowerLevels[self:getName():lower():gsub("^shiny ", "")]
	if override then
		return override
	end
	if wildPowerFromSpecies and getPokemonRequiredLevel then
		return math.floor(getPokemonRequiredLevel(self:getName()) * wildPowerFactor)
	end
	return 0
end

function Monster.getSummonBoost(self)
	if self:isPokemon() then
		local master = self:getMaster()
--		local item = master:getSlotItem(CONST_SLOT_AMMO)
		local item = master:getUsingBall()
		local pokeBoost = item:getSpecialAttribute("pokeBoost")
		if pokeBoost ~= nil then
			return pokeBoost
		end
	end
	return 0
end

function Monster.getLove(self)
	if self:isPokemon() then
		local master = self:getMaster()
--		local item = master:getSlotItem(CONST_SLOT_AMMO)
		local item = master:getUsingBall()
		local pokeLove = item:getSpecialAttribute("pokeLove")
		if pokeLove ~= nil then
			return pokeLove
		end
	end
	return 0
end

function Monster.getMasterLevel(self)
	if self:isPokemon() then
		local master = self:getMaster()
		if master then			
			return master:getLevel()
		end
	end
	return 1
end

function Monster.getSummonName(self)
	if isSummon(self) then
		local master = self:getMaster()
--		local item = master:getSlotItem(CONST_SLOT_AMMO)
		local item = master:getUsingBall()
		local pokeName = item:getSpecialAttribute("pokeName")
		if pokeName ~= nil then			
			return pokeName
		end
	end
	return "unamed"
end

function Monster.isEvolving(self)
	if self:isPokemon() then
		local master = self:getMaster()
		if master and master:getStorageValue(storageEvolving) == 1 then return true end
	end
	return false
end

function doChangeOutfit(cid, outfit, time)
	local creature = Creature(cid)
	if not creature then return false end
	if time == nil then time = -1 end
	doSetCreatureOutfit(creature, outfit, time)
	return true
end

function doSendDelayedEffect(pos, effect)
	local tile = Tile(pos)
	if tile then
		pos:sendMagicEffect(effect)
	end
	return true
end

function doTransformPokeball(item)
	if not item:isPokeball() then return false end
	for key, value in pairs(balls) do
		if value.usedOn == item:getId() then
			doTransformItem(item.uid, value.usedOff)
			return true			
		end
		if value.usedOff == item:getId() then
			doTransformItem(item.uid, value.usedOn)
			return true			
		end
	end
	return false
end

-- Smart Combo: info de cada ataque (elemento, categoria de dano y efecto), leida una vez
-- de spells.xml y de los scripts de data/spells/scripts/moves
local moveInfoCache = nil
local function buildMoveInfoCache()
	moveInfoCache = {}
	local f = io.open("data/spells/spells.xml", "r")
	if not f then
		print("[SmartCombo] No se pudo abrir data/spells/spells.xml")
		return
	end
	local xml = f:read("*a")
	f:close()
	for tag in xml:gmatch("<instant[^>]*>") do
		local name = tag:match('name="([^"]+)"')
		local script = tag:match('script="([^"]+)"')
		if name and script then
			local element = script:match("^moves/([^/]+)/") or ""
			local category, effect, target = "", "", false
			local sf = io.open("data/spells/scripts/" .. script, "r")
			if sf then
				local src = sf:read("*a")
				sf:close()
				category = src:match("damageMultiplierMoves%.(%w+)") or ""
				-- si el script usa getTarget() el ataque no hace nada sin objetivo
				target = src:find("getTarget%(%)") ~= nil
				if src:find("CONDITION_POISON") then effect = "poison"
				elseif src:find("CONDITION_FIRE") then effect = "burn"
				elseif src:find("CONDITION_REGENERATION") or src:find("COMBAT_HEALING") then effect = "heal"
				elseif src:find("CONDITION_ATTRIBUTES") or src:find("CONDITION_HASTE") then effect = "buff"
				elseif src:find("CONDITION_PARALYZE") then effect = "slow"
				end
			end
			moveInfoCache[name:lower()] = {element = element, category = category, effect = effect, target = target}
		end
	end
	local count = 0
	for _ in pairs(moveInfoCache) do count = count + 1 end
	print("[SmartCombo] Info de " .. count .. " ataques cargada")
end

function getMoveInfo(moveName)
	if not moveInfoCache then buildMoveInfoCache() end
	return moveInfoCache[moveName:lower()] or {element = "", category = "", effect = "", target = false}
end

-- true si el ataque necesita un objetivo (isTarget del XML del monstruo o el script usa getTarget)
function moveNeedsTarget(move)
	if move.isTarget == true or tonumber(move.isTarget) == 1 then return true end
	return getMoveInfo(move.name).target
end

-- Lanza el ataque numero i del pokemon del jugador (m1..m12 y Smart Combo).
-- Con quiet = true no manda avisos y devuelve el motivo del fallo (lo usa el combo).
function doSummonMove(player, i, quiet)
	local function fail(message, reason)
		if not quiet then
			player:sendCancelMessage(message)
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
		end
		return false, reason
	end

	local summon = player:getSummon()
	if not summon then
		return fail("Sorry, not possible. You need a summon to conjure spells.", "sin pokemon")
	end

	local tile = Tile(player:getPosition())
	if tile and tile:hasFlag(TILESTATE_PROTECTIONZONE) then
		return fail("Sorry, not possible in protection zone.", "zona protegida")
	end

	local summonName = summon:getName()
	local move = MonsterType(summonName):getMoveList()[i]
	if not move then
		return fail("Sorry, not possible.", "no existe")
	end

	local target = summon:getTarget()
	local needsTarget = moveNeedsTarget(move)
	local range = tonumber(move.range) or 0
	if needsTarget and not target then
		return fail("Sorry, not possible. You need a target.", "sin objetivo")
	end
	if target and needsTarget and range > 0 and getDistanceBetween(summon:getPosition(), target:getPosition()) > range then
		return fail("Sorry, not possible. You are too far.", "lejos")
	end
	if getCreatureCondition(summon, CONDITION_SLEEP) then
		return fail("Sorry, not possible. Your pokemon is sleeping.", "dormido")
	end
	if quiet then
		local ball = player:getUsingBall()
		if ball and os.time() <= (ball:getSpecialAttribute("cd" .. i) or 0) then
			return false, "recarga"
		end
	end
	if player:checkMoveExhaustion(i, move.speed / 1000) then
		return false, "recarga"
	end
	doCreatureCastSpell(summon, move.name)
	player:say(summonName .. ", use " .. move.name .. "!", TALKTYPE_MONSTER_SAY)
	return true
end

-- Smart Combo: el cliente manda la secuencia una sola vez ("smartcombo 1,3,2")
-- y el servidor lanza los ataques uno a uno. Al acabar avisa al cliente por opcode 61:
-- "lanzados|slot:motivo,slot:motivo"
local SMART_COMBO_GAP = 500
local OPCODE_COMBO_DONE = 61
local smartComboEvents = {}

local function smartComboStep(cid, slots, index, cast, skipped)
	smartComboEvents[cid] = nil
	local player = Player(cid)
	if not player then return end
	while index <= #slots do
		local slot = slots[index]
		index = index + 1
		local ok, reason = doSummonMove(player, slot, true)
		if ok then
			cast = cast + 1
			if index <= #slots then
				smartComboEvents[cid] = addEvent(smartComboStep, SMART_COMBO_GAP, cid, slots, index, cast, skipped)
				return
			end
		else
			table.insert(skipped, slot .. ":" .. (reason or "?"))
			if reason == "sin pokemon" or reason == "zona protegida" then break end
		end
	end
	player:sendExtendedOpcode(OPCODE_COMBO_DONE, cast .. "|" .. table.concat(skipped, ","))
end

function doSmartCombo(player, param)
	local cid = player:getId()
	if smartComboEvents[cid] then
		stopEvent(smartComboEvents[cid])
		smartComboEvents[cid] = nil
	end
	local slots = {}
	for s in (param or ""):gmatch("%d+") do
		local i = tonumber(s)
		if i >= 1 and i <= #moveWords and #slots < #moveWords then
			slots[#slots + 1] = i
		end
	end
	if #slots == 0 then return end
	smartComboStep(cid, slots, 1, 0, {})
end

-- Manda al cliente los datos del pokemon que esta fuera: opcode 60 (retrato, outfit, nombre,
-- info de ataques, id de la criatura, vida maxima) y 52 (barra de ataques con cooldowns).
-- Se usa al sacarlo y cuando el cliente lo pide (opcode 71).
function sendSummonInfo(player, monster, ball)
	local monsterType = MonsterType(monster:getName())
	if not monsterType then return end
	local movesTable = {}
	local moves = monsterType:getMoveList()
	for i = 1, #moveWords do
		local move = moves[i]
		if move then
			if i == 1 then
				table.insert(movesTable, move.name)
			else
				table.insert(movesTable, "," .. move.name)
			end
		end
	end
	for i = 1, #moveWords do
		local move = moves[i]
		if move then
			table.insert(movesTable, "," .. move.speed)
		end
	end
	-- un valor por ataque existente (si no, los bloques siguientes se desplazan en el cliente)
	for i = 1, #moveWords do
		if moves[i] then
			local moveCooldown = ball and ball:getSpecialAttribute("cd" .. i) or 0
			if os.time() > moveCooldown then
				table.insert(movesTable, ",0")
			else
				table.insert(movesTable, "," .. 1000 * math.floor(moveCooldown - os.time()))
			end
		end
	end
	-- Smart Combo: 1 si el ataque necesita objetivo, 0 si es de area
	for i = 1, #moveWords do
		local move = moves[i]
		if move then
			table.insert(movesTable, "," .. (moveNeedsTarget(move) and 1 or 0))
		end
	end
	-- Smart Combo: alcance maximo de cada ataque (0 = sin limite)
	for i = 1, #moveWords do
		local move = moves[i]
		if move then
			table.insert(movesTable, "," .. (tonumber(move.range) or 0))
		end
	end
	table.insert(movesTable, ",")
	-- Smart Combo: retrato, outfit, nombre y elemento/categoria/efecto de cada ataque
	local movesInfo = {}
	for i = 1, #moveWords do
		local move = moves[i]
		if move then
			local info = getMoveInfo(move.name)
			table.insert(movesInfo, info.element .. ":" .. info.category .. ":" .. info.effect)
		end
	end
	-- 5: id de la criatura (el cliente lee su vida en directo), 6: vida maxima
	local lookType = monster:getOutfit().lookType
	lookType = premierLooksReverse and premierLooksReverse[lookType] or lookType
	player:sendExtendedOpcode(60, (monsterType:portraitId() or 0) .. "|" .. lookType .. "|" .. monster:getName() .. "|" .. table.concat(movesInfo, ";")
		.. "|" .. monster:getId() .. "|" .. monster:getMaxHealth())
	player:sendExtendedOpcode(52, table.concat(movesTable))
end

-- Premier Ball: el pokemon sale con su aspecto de contorno arcoiris (premierlooks.lua, generado
-- por tools/pokeassets/RainbowApply.cs junto con los dibujos del cliente)
function Monster.setPremierLook(self)
	if not premierLooks then return false end
	local outfit = self:getOutfit()
	local premier = premierLooks[outfit.lookType]
	if not premier then return false end
	outfit.lookType = premier
	self:setOutfit(outfit)
	return true
end

function doReleaseSummon(cid, pos, effect, message, missile)
	local player = Player(cid)
	if not player then return false end
--	local ball = player:getSlotItem(CONST_SLOT_AMMO)
	local ball = player:getUsingBall()
	if not ball then return false end
	if effect == nil then effect = CONST_ME_TELEPORT end
	if message == nil then message = true end
	local name = ball:getSpecialAttribute("pokeName")
	-- to fix ball bug
	if not name then
		ball:remove()
		return false
	end
	if name == "Ditto" or name == "Shiny ditto" or name == "Xmas ditto" then
		local dittoTime = ball:getSpecialAttribute("dittoTime")
		if dittoTime and os.time() < dittoTime then
			name = ball:getSpecialAttribute("dittoTransform")
		end
	end
	local monsterType = MonsterType(name)
	if not monsterType:isConvinceable() then
		print("WARNING: Monster " .. name .. " is not convinceable.")
		player:sendCancelMessage("Sorry, not possible. This problem was reported.")
		ball:setSpecialAttribute("isBeingUsed", 0)
		return false 
	end
	if not monsterType:isIllusionable() then
		print("WARNING: Monster " .. name .. " is not illusionable.")
		player:sendCancelMessage("Sorry, not possible. This problem was reported.")
		ball:setSpecialAttribute("isBeingUsed", 0)
		return false 
	end
	if not monsterType:isSummonable() then
		print("WARNING: Monster " .. name .. " is not illusionable.")
		player:sendCancelMessage("Sorry, not possible. This problem was reported.")
		ball:setSpecialAttribute("isBeingUsed", 0)
		return false 
	end

	local health = ball:getSpecialAttribute("pokeHealth") or 0
	if health <= 0 then
		player:sendCancelMessage("Sorry, not possible. Your summon is dead.")
		ball:setSpecialAttribute("isBeingUsed", 0)
		return true
	end	

	local summonBoost = ball:getSpecialAttribute("pokeBoost") or 0

	local newPos = player:getClosestFreePosition(pos, 2, false, true) or pos
	if newPos.x == 0 then
		newPos = pos
	end
	-- el pokemon no tiene nivel propio: se crea con el nivel del entrenador
	local monster = Game.createMonster(name, newPos, true, true, player:getLevel(), summonBoost)

	if monster ~= nil then
		if message then
			player:say(monster:getName() .. ", I need your help!", TALKTYPE_MONSTER_SAY)
		end
		player:addSummon(monster)
		if getBallKey(ball:getId()) == "premierball" then
			monster:setPremierLook()
		end
		monster:setDirection(ball:getSpecialAttribute("pokeLookDir") or DIRECTION_SOUTH)
		if summonBoost >= maxBoost then
			doStartAurea(monster)
		end
		local maxHealth = monster:getTotalHealth()
		-- runas de la Pokeball (lib/core/runes.lua): se guardan para el combate y la de vida suma aqui
		if cacheSummonRunes then
			cacheSummonRunes(monster, ball)
			maxHealth = math.floor(maxHealth * (1 + getSummonRuneBonus(monster, "hp")))
		end
		monster:setMaxHealth(maxHealth)
		monster:setHealth(math.min(health, maxHealth))
		monster:changeSpeed(-monster:getSpeed() + monster:getTotalSpeed())
		player:registerEvent("RemoveSummon")
		if effect then
			monster:getPosition():sendMagicEffect(effect)
		end
		if missile then
			doSendDistanceShoot(player:getPosition(), monster:getPosition(), missile)
		end
		monster:removeTarget(player)
		monster:registerEvent("MonsterHealthChange")
		monster:registerEvent("MonsterDeath")

		local attackers = Game.getSpectators(newPos, true, false) 
		for i = 1, #attackers do
			local attacker = attackers[i]
			if attacker and attacker:isMonster() then
				local hostile = MonsterType(Monster(attacker):getName()):isHostile()
				if hostile then
					if attacker:getTarget() == player then
						attacker:addTarget(monster, true)
						attacker:removeTarget(Creature(player:getId()))
						attacker:searchTarget()
--						for i = 1, #attacker:getTargetList() do
--							print(attacker:getTargetList()[i]:getName())
--						end
					end
				end
			end
		end

		sendSummonInfo(player, monster, ball)

		return monster:getId()
	end
	return true

end


function doRemoveSummon(cid, effect, uid, message, missile)
	local player = Player(cid)
	if not player then return false end
	if effect == nil then effect = CONST_ME_POFF end
	if message == nil then message = true end
	local summons = player:getSummons()
	if not summons then return false end
	local summon = Creature(summons[1])
	if not summon then
		return false
	end
	local summonPos = summon:getPosition()
	local attackers = Game.getSpectators(summonPos, true, false) 
	for i = 1, #attackers do
		local attacker = attackers[i]
		if attacker and attacker:isMonster() then
--			attacker:say(attacker:getTargetCount(), TALKTYPE_SAY)
			local targetList = attacker:getTargetList()
			for j = 1, #targetList do
				if targetList[j] == summon then
					attacker:removeTarget(summon)
					if not attacker:getMaster() and attacker:isOpponent(player) then
						attacker:addTarget(player, true)
						if not attacker:selectTarget(player) then
							attacker:searchTarget()
						end
					else
						attacker:searchTarget()
					end
				end
			end
		end
	end
	if effect then
		summonPos:sendMagicEffect(effect)
	end
	if missile then
		doSendDistanceShoot(summonPos, player:getPosition(), missile)
	end
	summon:unregisterEvent("MonsterGetExperience")
	summon:unregisterEvent("MonsterHealthChange")
	player:unregisterEvent("RemoveSummon")
--	local ball = player:getSlotItem(CONST_SLOT_AMMO)
	local ball = player:getUsingBall()
	if uid and not ball then
		ball = Item(uid)
	end
	if ball and ball:isPokeball() then
		ball:setSpecialAttribute("pokeHealth", summon:getHealth())
		ball:setSpecialAttribute("pokeMaxHealth", summon:getMaxHealth())
		ball:setSpecialAttribute("pokeLookDir", summon:getDirection())
	end
	if not (player:isOnFly() or player:isOnRide() or player:isOnSurf() or summon:isEvolving()) then
		if ball then
			ball:setSpecialAttribute("isBeingUsed", 0)
		else
			print("WARNING! Player " .. player:getName() .. " had problems on remove summon: ball does not exist.")
		end
	end
	if summon:isEvolving() then 
		player:setStorageValue(storageEvolving, -1)
	end
	if message then
		player:say("Thanks, " .. summon:getName() .. "!", TALKTYPE_MONSTER_SAY)
	end
	summon:remove()	
	-- panel del pokemon activo: ya no hay ninguno fuera; barra del equipo con la vida guardada
	player:sendExtendedOpcode(70, "")
	player:refreshPokemonBar({}, {})
	return true
end

function doEvolveSummon(cid, evolutionName, ancient)
	if not ancient then ancient = false end
	local monsterType = MonsterType(evolutionName)
	local summon = Creature(cid)
	local master = summon:getMaster()
	local summonPos = summon:getPosition()
--	local item = master:getSlotItem(CONST_SLOT_AMMO)
	local item = master:getUsingBall()
	if monsterType and summon:isMonster() then
		master:say("Wow, my " .. summon:getName() .. " is evolving!", TALKTYPE_SAY)
		master:getPosition():sendMagicEffect(292)
		master:setStorageValue(storageEvolving, 1)
		summon:changeSpeed(-summon:getSpeed())
		item:setSpecialAttribute("pokeName", evolutionName)
		if ancient then
			item:setSpecialAttribute("owner", master:getName())
			master:setStorageValue(storageEvolutionAncient, 1)
		end
--		local portrait = master:getSlotItem(CONST_SLOT_HEAD)
--		local removePortrait = nil
--		if portrait then
--			removePortrait = master:removeItem(portrait:getId(), 1)
--		end
--		local portraitId = monsterType:portraitId()
--		if portraitId ~= 0 then 
--			local putPortrait = master:addItem(portraitId, 1, false, 1, CONST_SLOT_HEAD)
--			if not removePortrait or not putPortrait and master:getSlotItem(CONST_SLOT_HEAD):getId() ~= portraitId then
--				print("WARNING! Problem on put portrait after evolution " .. evolutionName .. " player " .. master:getName())
--			end
--		end

		local baseHealth = MonsterType(evolutionName):getMaxHealth()
		local newMaxHealth = math.floor(baseHealth * statusGainFormula(master:getLevel(), 0, item:getSpecialAttribute("pokeBoost") or 0, item:getSpecialAttribute("pokeLove") or 0) * getPokemonShinyStatMultiplier(evolutionName))
		summon:setMaxHealth(newMaxHealth)
		summon:setHealth(newMaxHealth)

		addEvent(doChangeOutfit, 500, summon:getId(), monsterType:getOutfit(), 500)
		addEvent(doSendDelayedEffect, 500, summon:getPosition(), 10)
		addEvent(doSendDelayedEffect, 1000, summon:getPosition(), 12)
		addEvent(doChangeOutfit, 1500, summon:getId(), monsterType:getOutfit(), 500)
		addEvent(doSendDelayedEffect, 1500, summon:getPosition(), 10)
		addEvent(doSendDelayedEffect, 2000, summon:getPosition(), 12)
		addEvent(doSendDelayedEffect, 4000, summon:getPosition(), CONST_ME_HEARTS)

		addEvent(doRemoveSummon, 4000, master:getId(), false, nil, false)
		addEvent(doReleaseSummon, 4001, master:getId(), summonPos, false, false)
		master:refreshPokemonBar({}, {})
		return true
	else
		print("WARNING! Problem on evolution to " .. evolutionName .. " player " .. master:getName())
	end
	return false
end

function Position:sendAnimatedNumber(message_type, text, value, color)
	local message_type = message_type or MESSAGE_EXPERIENCE
	local color = color or TEXTCOLOR_BLUE
	local valid_message_types = {
		MESSAGE_DAMAGE_DEALT,
		MESSAGE_DAMAGE_OTHERS,
		MESSAGE_DAMAGE_RECEIVED,
		MESSAGE_EXPERIENCE,
		MESSAGE_EXPERIENCE_OTHERS,
		MESSAGE_HEALED,
		MESSAGE_HEALED_OTHERS,
	}
	assert(isInArray(valid_message_types, message_type), "invalid 'message_type', must output to server log")
	for _, v in ipairs(Game.getSpectators(self, false, true)) do
		if v:isPlayer() then
			v:sendTextMessage(message_type, text, self, value, color)
		end
	end
end


--function Item.isPokeball(self)
--	if self:getId() == filledPokeball then
--		return true
--	end
--	return false
--end


function Item.isPokeball(self)
	for key, value in pairs(balls) do
		if value.usedOn == self:getId() or value.usedOff == self:getId() then
			return true			
		end
	end
	return false
end

function doAddPokeball(cid, name, boost, ballKey, dp, msg)
	local player = Player(cid)
	if player then
		name = firstToUpper(name)
		local monsterType = MonsterType(name)
		if not monsterType then 
			print("WARNING: Monster " .. name .. " impossible to catch.") 
			player:sendCancelMessage("Sorry, not possible. This problem was reported.")
			return false 
		end
		local addBall
		-- si queda sitio en el cinturon, la pokeball va ahi
		local belt = player:getPokemonBelt()
		if belt and belt:getEmptySlots() > 0 then
			addBall = belt:addItem(balls[ballKey].usedOn, 1)
			dp = false
		end
		-- sin sitio en el cinturon: al PC (los pokemon nunca van a la mochila)
		if not addBall then
			dp = true
		end
		if addBall then
			-- ya esta en el cinturon
		elseif dp == false then
			addBall = player:addItem(balls[ballKey].usedOn, 1, false)
		else
			local depot = player:getInbox()
			addBall = depot:addItem(balls[ballKey].usedOn, 1, INDEX_WHEREEVER, FLAG_NOLIMIT)
		end
		if not addBall then
			if dp == false then -- try send to CP because BP is full
				local depot = player:getInbox()
				addBall = depot:addItem(balls[ballKey].usedOn, 1, INDEX_WHEREEVER, FLAG_NOLIMIT)
				addEvent(doPlayerSendTextMessage, msg, cid, MESSAGE_EVENT_ADVANCE, "Since you are at maximum capacity, your ball was sent to CP.")
--				print("WARNING! Player " .. player:getName() .. " sending pokemon " .. name .. " to CP after first try.")
				dp = true
			else
				addBall = player:addItem(balls[ballKey].usedOn, 1)
				addEvent(doPlayerSendTextMessage, msg, cid, MESSAGE_STATUS_WARNING, "Pokemon lost. Your CP is full!")
				print("WARNING! Player " .. player:getName() .. " lost pokemon " .. name .. " because CP is full.")
			end
		end
		if addBall then
			local baseHealth = monsterType:getMaxHealth()
			local maxHealth = math.floor(baseHealth * statusGainFormula(player:getLevel(), 0, boost, 0) * getPokemonShinyStatMultiplier(name))
			addBall:setSpecialAttribute("pokeName", name)
			addBall:setSpecialAttribute("pokeBoost", boost)
			addBall:setSpecialAttribute("pokeMaxHealth", maxHealth)
			addBall:setSpecialAttribute("pokeHealth", maxHealth)
			addBall:setSpecialAttribute("pokeLove", 0)
			if dp == false then
				player:refreshPokemonBar({}, {})
			end
			return true
		else
			print("ERROR! Player " .. player:getName() .. " lost pokemon " .. name .. " for unknown reason.")
		end
	end
	print("WARNING! Player not found to add pokeball.")
	return false	
end

function Player.getPokeballCount(self)
	local nBalls = 0
	for key, value in pairs(balls) do
		nBalls = nBalls + self:getItemCount(value.usedOn) + self:getItemCount(value.usedOff)
	end	
	return nBalls
end

function searchInContainer(container, itemId)
	local count = 0
	if container:isContainer() then
		local items = container:getItem()
		for i = 0, container:getSize() do
			local item = container:getItem(i)
			if item then
				if item:isContainer() then
					if item:getId() == itemId then
						count = count + item:getCount()
					end
					count = count + searchInContainer(item, itemId)
				elseif item:getId() == itemId then
					count = count + item:getCount()
				end
			end
		end
	end
	return count
end

function Item.isStone(self)
	if isInArray(stonesId[1], self:getId()) then
		return true
	end
	return false
end

function doSendAurea(cid)
	local monster = Monster(cid)	
	if monster then		
		monster:getPosition():sendMagicEffect(475)
		doStartAurea(monster)
	end
end

function doStartAurea(monster)
	addEvent(doSendAurea, 2000, monster.uid)
end

function Container.getPokeballs(self)
	local ret = {}
		local size = self:getSize()
		for i = size - 1, 0, -1 do
			local item = self:getItem(i)
			if item:isPokeball() then
				table.insert(ret, item)
			elseif item:isContainer() then
				local itemsInside = item:getPokeballs()
				for i=0, #itemsInside do
					table.insert(ret, itemsInside[i])
				end
			end
		end
	return ret
end

function Player.getPokemonBelt(self)
	local item = self:getSlotItem(pokemonBeltSlot)
	if item and item:getId() == pokemonBelt then
		return Container(item:getUniqueId())
	end
	return nil
end

-- Pone el cinturon si falta. Al crearlo mete en el hasta 6 pokeballs de la mochila.
function Player.checkPokemonBelt(self)
	if self:getPokemonBelt() then
		return
	end
	if self:getSlotItem(pokemonBeltSlot) then
		print("WARNING! Player " .. self:getName() .. " has the belt slot taken, no pokemon belt.")
		return
	end
	self:addItem(pokemonBelt, 1, false, 1, pokemonBeltSlot)
	local belt = self:getPokemonBelt()
	if not belt then
		return
	end
	local backpack = self:getSlotItem(CONST_SLOT_BACKPACK)
	if not backpack then
		return
	end
	-- getPokeballs recorre la mochila del final al principio: se mueven en el orden de la mochila
	local inBackpack = backpack:getPokeballs()
	for i = #inBackpack, 1, -1 do
		if belt:getEmptySlots() <= 0 then
			break
		end
		inBackpack[i]:moveTo(belt)
	end
end

function Player.getPokeballs(self)
	local pokeballs = {}

	-- primero el cinturon, en el orden de sus casillas
	local belt = self:getPokemonBelt()
	if belt then
		for slot = 0, belt:getSize() - 1 do
			local ball = belt:getItem(slot)
			if ball and ball:isPokeball() then
				table.insert(pokeballs, ball)
			end
		end
	end

	local backpack = self:getSlotItem(CONST_SLOT_BACKPACK)
	if backpack then
		for _, ball in ipairs(backpack:getPokeballs()) do
			table.insert(pokeballs, ball)
		end
	end	

	local ballOn = self:getSlotItem(CONST_SLOT_AMMO)
	if ballOn and ballOn:isPokeball() then
		table.insert(pokeballs, ballOn)
	end

	return pokeballs
end

function Player.updateQuestLog(self)
	for key, value in pairs(quests) do
		if self:getLevel() >= value.level then
			for j = 1, #value.prizes do
				for k = 1, #value.prizes do
					if self:getStorageValue(value.prizes[k].uid) < 0 then
						self:setStorageValue(value.prizes[k].uid, 0)
					end
				end
			end
		end
	end
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function Position:createFlyFloor()
	local toTile = Tile(self)
	if not toTile or not toTile:getItems() or not toTile:getGround() then
		doAreaCombatHealth(0, 0, self, 0, 0, 0, CONST_ME_NONE)
		Game.createItem(flyFloor, 1, self)
	end
	return true
end
 
function Tile:hasValidGround()
	local ground = self:getGround()
	local nilItem = self:getItemById(flyFloor)
	if ground and not nilItem then
		return true
	end 
	return false
end
 
function Player:activateFly()
	self:setStorageValue(storageFly, 1)
	self:registerEvent("FlyEvent")
	return true
end
 
function Player:deactivateFly()
	local can, floor = self:canDeactivateFly()
	local pos = self:getPosition()
	if can then
		local curtile = Tile(pos)
		local nilItem = curtile:getItemById(flyFloor)
		if nilItem then
			nilItem:remove()
		end
		self:unregisterEvent("FlyEvent")
		if pos.z ~= floor then
			pos.z = floor
			self:teleportTo(pos)
			pos:sendMagicEffect(CONST_ME_TELEPORT)
		end
	end 
	return can
end

function Player:canDeactivateFly()
    local pos = self:getPosition()
--    for z = pos.z, 15 do
        local tmp = Tile(pos.x, pos.y, pos.z)
        if tmp and tmp:hasValidGround() then
            if self:canFlyDown(pos.z) then
                return true, pos.z
            else
                return false
            end
        end
--    end
 
    return false
end
 
function Player:canFlyUp()
	local pos = self:getPosition()
	local tmp = Tile(pos.x, pos.y, pos.z-1)
	if tmp and tmp:hasValidGround() then
		return false
	end 
	tmp = Tile(pos.x, pos.y, pos.z-1)

	if tmp and (tmp:getHouse() or tmp:hasFlag(TILESTATE_PROTECTIONZONE) or tmp:hasFlag(TILESTATE_FLOORCHANGE) or tmp:hasFlag(TILESTATE_BLOCKSOLID) ) then
		return false
	end 

	if tmp and tmp:getGround() and isInArray(waterIds, tmp:getGround():getId()) then
		return false
	end
	return true
end
 
function Player:canFlyDown(floor)
	local pos = self:getPosition()
	local tmp = Tile(pos)
	if floor and floor == pos.z then
		return true
	end 
	if tmp:hasValidGround() then
		return false
	end 
	tmp = Tile(pos.x, pos.y, floor or pos.z+1)

	if tmp and (tmp:getHouse() or tmp:hasFlag(TILESTATE_PROTECTIONZONE) or tmp:hasFlag(TILESTATE_FLOORCHANGE) or tmp:hasFlag(TILESTATE_BLOCKSOLID) ) then
		return false
	end 

	if tmp and tmp:getGround() and isInArray(waterIds, tmp:getGround():getId()) then
		return false
	end
    return true
end
 
function Player:flyUp()
	if self:isOnFly() then
		if self:canFlyUp() then
			local pos = self:getPosition()
			local tile = Tile(pos)
			local itemfloor = tile:getItemById(flyFloor)
			if itemfloor then
				itemfloor:remove()
			end 
			pos.z = pos.z-1
			pos:createFlyFloor()
			self:teleportTo(pos)
			pos:sendMagicEffect(CONST_ME_TELEPORT) 
			return true
		end 
		return false
	else
		self:sendCancelMessage("You are not flying.")
		return false
	end
end
 
function Player:flyDown()
	if self:isOnFly() then
		if self:canFlyDown() then
			local pos = self:getPosition()
			local tile = Tile(pos)
			local itemfloor = tile:getItemById(flyFloor)
			if itemfloor then
				itemfloor:remove()
			end 
			pos.z = pos.z+1
			pos:createFlyFloor()
			self:teleportTo(pos)
			pos:sendMagicEffect(CONST_ME_TELEPORT)
			return true
		end 
		return false
	else
		self:sendCancelMessage("You are not flying.")
		return false
	end
end

function Player:addTokens(number)
	if self:getStorageValue(storageTokens) < 0 then
		self:setStorageValue(storageTokens, number)
	else
		self:setStorageValue(storageTokens, self:getStorageValue(storageTokens) + number)
	end
	return true
end

function Player:removeTokens(number)
	if self:getStorageValue(storageTokens) < number then
		return false
	else
		self:setStorageValue(storageTokens, self:getStorageValue(storageTokens) - number)
	end
	return true
end

function Player:getTokens()
	if self:getStorageValue(storageTokens) < 0 then
		return 0
	end
	return self:getStorageValue(storageTokens)
end

function Creature:hasKilledLegendaryPokemon()
	if self:isPlayer() and (os.time() < self:getStorageValue(storageLastLegendaryKilled)) then
		return true
	end
	return false
end

function Player:setKilledLegendaryPokemon()
	self:setStorageValue(storageLastLegendaryKilled, os.time() + 10 * 60)
	return true
end

function Player:isDuelingWithNpc()
	if self:getStorageValue(storageDuelNpc) > 0 then
		return true
	end
	return false
end

function Player:setDuelWithNpc()
	self:setStorageValue(storageDuelNpc, 1)
	self:setStorageValue(storageDuelNpcStatus, 1)
	return true
end

function Player:setOnLeague()
	self:setStorageValue(storageLeague, 1)
	self:setStorageValue(storageLeaguePotion, 0)
	self:setStorageValue(storageLeagueRevive, 0)
	self:setStorageValue(storageLeagueTime, os.time())
	return true
end

function Player:setOutLeague()
	self:setStorageValue(storageLeague, -1)
	return true
end

function Player:isOnLeague()
	if self:getStorageValue(storageLeague) == 1 then
		return true
	end
	return false
end

function Player:canUsePotionOnLeague()
	if self:getStorageValue(storageLeaguePotion) < 0 then self:setStorageValue(storageLeaguePotion, 0) end
	if self:getStorageValue(storageLeaguePotion) < 25 then
		self:setStorageValue(storageLeaguePotion, self:getStorageValue(storageLeaguePotion) + 1)
		self:sendTextMessage(MESSAGE_INFO_DESCR, "Usando potion " .. self:getStorageValue(storageLeaguePotion) .. " de 25.")
		return true
	end
	return false
end

function Player:canUseReviveOnLeague()
	if self:getStorageValue(storageLeagueRevive) < 0 then self:setStorageValue(storageLeagueRevive, 0) end
	if self:getStorageValue(storageLeagueRevive) < 5 then
		self:setStorageValue(storageLeagueRevive, self:getStorageValue(storageLeagueRevive) + 1)
		self:sendTextMessage(MESSAGE_INFO_DESCR, "Usando revive " .. self:getStorageValue(storageLeagueRevive) .. " de 5.")
		return true
	end
	return false
end

function Player:unsetDuelWithNpc()
	self:setStorageValue(storageDuelNpc, -1)
	return true
end

function Player:getDuelWithNpcStatus()
	if self:getStorageValue(storageDuelNpcStatus) < 1 then
		return 1
	end
	return self:getStorageValue(storageDuelNpcStatus)
end

function Player:increaseDuelWithNpcStatus()
	if self:getStorageValue(storageDuelNpcStatus) < 1 then
		self:setStorageValue(storageDuelNpcStatus, 1)
	else
		self:setStorageValue(storageDuelNpcStatus, self:getStorageValue(storageDuelNpcStatus) + 1)
	end	
	return true
end

-- Premio de una quest (cofres con uniqueid = uid del premio, y NPC como los lideres de gimnasio).
-- Si la quest tiene varios premios (varios cofres), solo se puede coger uno.
-- Las de cofre son semanales (lib/core/weeklyquests.lua): se guarda la fecha y se pueden repetir
-- a los 7 dias con el premio semanal; los Pokemon y objetos especiales, solo la primera vez.
function Player:giveQuestPrize(uid, ignore)
	for key, value in pairs(quests) do
		for j = 1, #value.prizes do
			if uid == value.prizes[j].uid then
				if self:getLevel() < value.level then
					self:sendTextMessage(MESSAGE_INFO_DESCR, "Necesitas nivel " .. value.level .. " para abrirlo.")
					return true
				end
				local weekly = isWeeklyQuest and isWeeklyQuest(key, value) and not ignore
				local firstTime = true
				for k = 1, #value.prizes do
					if self:getStorageValue(value.prizes[k].uid) > 0 then
						firstTime = false
					end
				end
				if ignore then
					firstTime = true
				end
				if weekly and not firstTime then
					local wait = weeklyQuestWait(self, value)
					if wait > 0 then
						self:sendTextMessage(MESSAGE_INFO_DESCR, "Esta vacio. Vuelve dentro de " .. formatWait(wait) .. ".")
						return true
					end
				elseif not firstTime then
					self:sendTextMessage(MESSAGE_INFO_DESCR, "Esta vacio.")
					return true
				end

				if value.teleportCP == 1 then
					self:teleportTo(self:getTown():getTemplePosition())
				end
				local prize = value.prizes[j]
				if firstTime then
					for i = 1, #prize.pokes do
						local dp = 1
						local container = self:getSlotItem(CONST_SLOT_BACKPACK)
						if container and container:getEmptySlots() > 0 then
							dp = 0
						end
						doAddPokeball(self:getId(), prize.pokes[i].name, prize.pokes[i].boost, getBallKey(balls.ultraball.usedOn), dp, 0)
						local msg = "Has encontrado: " .. prize.pokes[i].name .. " +" .. prize.pokes[i].boost .. "."
						if dp == 1 then
							msg = msg .. " Se ha enviado al PC porque no te cabe en la mochila."
						end
						self:sendTextMessage(MESSAGE_INFO_DESCR, msg)
					end
				end

				local items = weekly and weeklyFilterItems(prize.items, firstTime) or prize.items
				for i = 1, #items do
					self:addItem(items[i].item, items[i].count)
					self:sendTextMessage(MESSAGE_INFO_DESCR, "Has encontrado: " .. items[i].count .. " " .. ItemType(items[i].item):getName() .. ".")
				end

				for i = 1, #prize.badges do
					local item = self:getItemById(prize.badges[i].remove, true)
					if item then
						item:transform(prize.badges[i].add)
						self:sendTextMessage(MESSAGE_INFO_DESCR, "Has conseguido: " .. ItemType(prize.badges[i].add):getName() .. ".")
					else
						print("WARNING! Player " .. self:getName() .. " with problems while adding " .. ItemType(prize.badges[i].add):getName() .. ".")
					end
				end

				if weekly then
					giveWeeklyReward(self, value.level, "Quest de nivel " .. value.level)
				end
				-- semanal: se guarda la fecha; normal: 1. En los dos casos cuenta como hecha (> 0)
				local mark = weekly and os.time() or 1
				for k = 1, #value.prizes do
					self:setStorageValue(value.prizes[k].uid, mark)
				end
				return true
			end
		end
	end

	self:sendTextMessage(MESSAGE_INFO_DESCR, "Esta vacio.")
	return false
end

function Player:addSlotItems()
	for i = 1, #slotItems do
		local itemId = slotItems[i]
		if not self:getItemById(itemId) then
			local item = self:addItem(itemId)
			if item and itemId == badgeContainer and ItemType(itemId) then
				local container = Container(item.uid)
				if container then
					for j = 1, #badgesPortraits do
						container:addItem(badgesPortraits[j])
					end
				end
			end
		end
	end
end

function Position:getClosestTownId()
	local distances = {}

	for i = 1, 59 do
		local town = Town(i)
		if town then
			local templePosition = town:getTemplePosition()
			distances[i] = getDistanceBetween(templePosition, self)
		end
	end

	local key = next(distances)
	local min = distances[key]

	for k, v in pairs(distances) do
	    if distances[k] < min then
		key, min = k, v
	    end
	end

	return key
end

function MonsterType:isLegendary()
	if isInArray(self:getCreatureEvents(), "LegendariesDeath") then
		return true
	end
	return false
end

function Player:refreshPokemonBar(add, remove)
	local pokeballs = self:getPokeballs()
	local pokemonsTable = {}
	for i = 1, #pokeballs do
		local ball = pokeballs[i]
		local pokeName = ball:getSpecialAttribute("pokeName")
		if not pokeName then -- fix ball bug
			ball:remove()
			print("WARNING! Player " .. self:getName() .. " had one ball removed!")
		else
			if not isInArray(remove, pokeName) then
				-- 10 campos por pokemon: nombre, % de vida (la guardada en la ball), 1 si esta fuera,
				-- n de ataques, cooldowns, boost, vida, vida maxima, n de pokedex, nombres de ataques
				local health = tonumber(ball:getSpecialAttribute("pokeHealth")) or 0
				local maxHealth = tonumber(ball:getSpecialAttribute("pokeMaxHealth")) or 0
				local percent = 100
				if health <= 0 then
					percent = 0
				elseif maxHealth > 0 then
					percent = math.max(1, math.min(100, math.floor(health * 100 / maxHealth)))
				end
				local used = (ball:getSpecialAttribute("isBeingUsed") or 0) == 1 and 1 or 0
				-- ataques: cuantos tiene y segundos de cooldown que le quedan a cada uno ("0" = listo)
				local total = 0
				local cooldowns = {}
				local moveNames = {}
				local dex = 0
				local monsterType = MonsterType(pokeName)
				if monsterType then
					local moveList = monsterType:getMoveList()
					total = math.min(#moveWords, #moveList)
					for m = 1, total do
						local cdEnd = tonumber(ball:getSpecialAttribute("cd" .. m)) or 0
						cooldowns[m] = math.max(0, cdEnd - os.time())
						moveNames[m] = (moveList[m].name or "?"):gsub("[,;|]", " ")
					end
					dex = tonumber(monsterType:dexEntry()) or 0
				end
				-- para el recuadro de la Pokebar: boost, vida exacta, numero de pokedex y ataques
				local boost = tonumber(ball:getSpecialAttribute("pokeBoost")) or 0
				table.insert(pokemonsTable, "," .. pokeName .. "," .. percent .. "," .. used .. "," .. total
					.. "," .. (#cooldowns > 0 and table.concat(cooldowns, ";") or "-")
					.. "," .. boost .. "," .. math.max(0, health) .. "," .. maxHealth .. "," .. dex
					.. "," .. (#moveNames > 0 and table.concat(moveNames, ";") or "-"))
			end
		end
		
	end
	for i = 1, #add do
		table.insert(pokemonsTable, "," .. add[i] .. ",100,0,0,-,0,0,0,0,-")
	end
	table.insert(pokemonsTable, ",")
	self:sendExtendedOpcode(53, table.concat(pokemonsTable))
--	self:setSpecialStorage("pokes", pokeballs)
	return true
end

function Player:isSummonBlocked()
--	if os.time() > self:getStorageValue(storageDelay) then
--	       	self:setStorageValue(storageDelay, os.time() + delay)
--	else
--		self:sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED)
--		return true
--	end

--	if item ~= self:getSlotItem(CONST_SLOT_AMMO) then
--		self:sendCancelMessage("Sorry, not possible. Please put the pokeball in the right place.")
--              return true
--	end

	if self:getSlotItem(CONST_SLOT_LEFT) == nil then
		self:sendCancelMessage("Sorry, not possible. You need a wand to control your summon.")
                return true
	end

	if self:getStorageValue(storageRide) == 1 then
		self:sendCancelMessage("Sorry, not possible while on ride.")
		return true
	end

	if self:getStorageValue(storageFly) == 1 then
		self:sendCancelMessage("Sorry, not possible while on fly.")
		return true
	end

	if self:getStorageValue(storageSurf) > 0 then
		self:sendCancelMessage("Sorry, not possible while on surf.")
		return true
	end

	if self:getStorageValue(storageEvent) > 0 then
		self:sendCancelMessage("Sorry, not possible while on event.")
		return true
	end

	if self:getStorageValue(storageEvolving) == 1 then
		self:sendCancelMessage("Sorry, not possible while evolving.")
		return true
	end

	return false
end


function Player:canReleaseSummon(pokeName, ownerName)

	-- to fix ball bug
	if not pokeName then return false end

	local playerLevel = self:getLevel()
	local minimumLevel = getPokemonRequiredLevel(pokeName)

	if playerLevel < minimumLevel then
		self:sendCancelMessage("Sorry, not possible. You need level " .. minimumLevel .. " to use this pokemon.")
		return false
	end

	if ownerName then
		if self:getStorageValue(quests.cathemAll.prizes[1].uid) < 2 then
			print("WARNING! Player " .. self:getName() .. " using unique Pokemon without finish the quest!")
		end
	end

	if ownerName and ownerName ~= self:getName() then
		self:sendCancelMessage("Sorry, it belongs to " .. ownerName .. ".")
		return false
	end

	return true
end

function Item:getSummonName()
	return self:getSpecialAttribute("pokeName")
end

function Item:getSummonBoost()
	return self:getSpecialAttribute("pokeBoost")
end

function Item:getSummonOwner()
	return self:getSpecialAttribute("owner")
end

function Item:isBeingUsed()
	local isBallBeingUsed = self:getSpecialAttribute("isBeingUsed")
	if isBallBeingUsed and isBallBeingUsed == 1 then
		return true
	end
	return false
end

function Item:setBeingUsed()
	self:setSpecialAttribute("isBeingUsed", 1)
	return true
end

function Item:unsetBeingUsed()
	self:setSpecialAttribute("isBeingUsed", 0)
	return true
end

function Player:getCatchRemain(table)
	local catchRemain = 0
	local msg = "Pokemons que faltam catalogar: \n"
	for i = 1, #table do
		if self:getStorageValue(baseStorageCatches + table[i]) <= 0 then
			catchRemain = catchRemain + 1
--			msg = msg .. "[" .. table[i] .. "] " .. monsterNumber[table[i]][1] .. "\n"
			msg = msg .. "[" .. table[i] .. "] " .. monstersTable[tonumber(table[i])] .. "\n"
		end
	end
	if msg ~= "Pokemons que faltam catalogar: \n" then
		self:showTextDialog(2263, msg)
	end
	return catchRemain
end

function Monster:getUsedVitaminsNumber(status)
	if status == nil then status = "vitTotal" end
	local total = 0
	if self:isPokemon() then
		local item = self:getMaster():getUsingBall()
		if item then
			total = item:getSpecialAttribute(status)
			if not total or total < 0 then total = 0 end
		end		
	end	
	return total
end

function Monster:increaseUsedVitaminsNumber()
	if self:isPokemon() then
		local item = self:getMaster():getUsingBall()
		if item then
			local total = item:getSpecialAttribute("vitTotal")
			if not total or total < 0 then total = 0 end
			if total < maxVitamins then
				item:setSpecialAttribute("vitTotal", total + 1)
				return true
			end
		end		
	end
	return false
end

function Monster:increaseStatus(statusName)
	if self:isPokemon() then
		local master = self:getMaster()
		local item = master:getUsingBall()
		if item then
			local total = item:getSpecialAttribute(statusName)
			if not total or total < 0 then total = 0 end
			item:setSpecialAttribute(statusName, total + 1)
			return true
		end		
	end
	return false
end
