# Comandos del juego - PokeDash PotA (10.98)

Sacados de `data/talkactions/talkactions.xml` de la base.
Los marcados con (?) no están probados todavía.

## GM - Teleport

| Comando | Qué hace | Ejemplo |
|---|---|---|
| `/town nombre` | Ir a una ciudad | `/town Saffron` |
| `/goto nombre` | Ir junto a un jugador/criatura | `/goto Tester` |
| `/gotopos x,y,z` | Ir a coordenadas | `/gotopos 1050,980,7` |
| `/c nombre` | Traer a un jugador/criatura a tu lado | `/c Tester` |
| `/a N` | Avanzar N casillas hacia donde miras | `/a 10` |
| `/up` / `/down` | Subir / bajar un piso | |
| `/t` | Volver a tu templo | |
| `/pos` | Ver tus coordenadas | |

## GM - Crear cosas

| Comando | Qué hace | Ejemplo |
|---|---|---|
| `/m nombre` | Invocar un monstruo/Pokémon salvaje | `/m pikachu` |
| `/cb nombre` | Crear una pokeball con ese Pokémon (?) | `/cb charizard` |
| `/i nombre o id` | Crear un item | `/i ultra ball` |
| `/s nombre` | Poner un NPC | `/s Nurse Joy` |
| `/summon nombre` | Invocar un monstruo como summon tuyo (?) | |
| `/r` | Borrar lo que tienes delante | |

## GM - Administración

| Comando | Qué hace |
|---|---|
| `/ghost` | Hacerte invisible |
| `/hide` | Ocultarte (?) |
| `/chameleon nombre` | Disfrazarte de un item (?) |
| `/looktype N` | Cambiar tu apariencia por un número de outfit |
| `/info nombre` | Info de un jugador |
| `/kick nombre` | Echar a un jugador |
| `/ban nombre` / `/ipban nombre` / `/unban nombre` | Banear / desbanear |
| `/B mensaje` | Mensaje a todo el servidor |
| `/addskill nombre, skill` | Subir un skill |
| `/addpremium nombre, días` | Dar premium (?) |
| `/addtutor` / `/removetutor` | Dar / quitar tutor |
| `/setactionid N` | Poner un actionid a un item (?) |
| `/removeoutfit` | Quitar un outfit (?) |
| `/owner` | Ver/cambiar dueño de casa (?) |
| `/mccheck` | Ver jugadores con multi-client |
| `/save` | Guardar el servidor |
| `/clean` | Limpiar items del suelo |
| `/openserver` / `/closeserver` | Abrir / cerrar el servidor |

## Jugador

| Comando | Qué hace |
|---|---|
| `!commands` / `!comandos` | Lista de comandos en el juego |
| `m1` ... `m12` | Ataques de tu Pokémon (también desde la barra) |
| `!p` | Usar tu Pokémon (?) |
| `!teleport ciudad` | Teletransporte con tu Pokémon (?) |
| `!up` / `!down` | Volar subir / bajar (necesita Pokémon que vuele) |
| `!autoloot` | Configurar autoloot |
| `!catch` | Ver los Pokémon que has capturado (?) |
| `!desbugar` | Desbugear al personaje si se queda atascado (?) |
| `!tutorial` | Tutorial |
| `!online` | Jugadores online |
| `!uptime` | Tiempo que lleva el servidor encendido |
| `!serverinfo` | Rates e info del servidor |
| `!deathlist` / `!kills` | Muertes / kills |
| `!buyhouse` / `!leavehouse` | Comprar / dejar casa |
| `!buypremium` / `!buyvip` | Comprar premium |
| `!changesex` | Cambiar sexo del personaje |

## Pruebas (del autor)

| Comando | Qué hace |
|---|---|
| `!z N` | Mostrar efecto mágico número N |
| `!x N` | Mostrar efecto de proyectil número N |

## Ciudades (`/town`)

**Kanto:** Pallet, Viridian, Pewter, Cerulean, Vermilion, Lavender, Celadon, Saffron, Fuchsia, Cinnabar

**Johto:** New Bark, Cherrygrove, Violet, Azalea, Goldenrod, Ecruteak, Cianwood, Olivine, Mahogany, Blackthorn

**Propias:** Eirian, Arcania, Eternia, Lunna, Snow, Nostrus, Natturu, Outland, Trade Center

## NPCs

- La enfermera se usa hablando: `hi` → `heal` (?)
