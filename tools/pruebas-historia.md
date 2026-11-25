# Pruebas de la historia de Kanto

Lista de lo que falta probar en el juego. Todo con **Claude Tester Dos** (cuenta `claudetest1`).

## Preparar

Con el servidor cerrado (o el tester desconectado), dejar al tester recién salido de Brock:

```powershell
.\tools\clonar-personaje.ps1 -Origen "Plantilla Brock" -Destino "Claude Tester Dos" -Reemplazar
```

Comandos de prueba (el tester puede usarlos aunque no sea GM):

| Comando | Qué hace |
|---|---|
| `/progreso` | Tarea activa y tope de nivel |
| `/progreso tareas` | Lista de ids de las tareas |
| `/progreso ir misty` | Salta a esa tarea: las anteriores quedan hechas y se ponen las medallas previas |
| `/progreso saltar` | Completa la tarea activa (con recompensa) |
| `/progreso nivel 40` | Sube al nivel indicado (no baja) |
| `/progreso liga` | Quita la espera de 20 horas para repetir la Liga |

Para probar un gimnasio suelto: `/progreso ir <id del gimnasio>` + `/progreso nivel <recomendado>`.

## Lo de toda la historia

- [ ] Al entrar con la plantilla se cierra la tarea de Brock (+3.000 $) y empieza «La leyenda de Mt. Moon».
- [ ] Botón **Ver en el mapa** en la tarea activa: marca Pokémon, ciudades y gimnasios.
- [ ] Icono dorado del **siguiente gimnasio** en el mapa, con cualquier zoom; cambia al ganar la medalla.
- [ ] Ventana al ganar una medalla y `!medallas` con la lista.
- [ ] El bono de medalla se nota (+5% de daño de tus Pokémon de ese tipo).
- [ ] Retar a un líder sin la tarea de entrenamiento: al ganar se completan las dos.
- [ ] Ningún Pokémon de Hoenn ni evoluciones fuertes en la superficie de Kanto.

## Gimnasio por gimnasio

| Líder | Ciudad | Tareas antes | Equipo | Tope hasta ganar | Probar |
|---|---|---|---|---|---|
| Brock | Plateada | 15 Geodude | Geodude 20, Onix 22 | 20 | Onix más fuerte que antes |
| Misty | Celeste | Clefairy (Mt. Moon, piso +4), llegar, 15 Psyduck | Staryu 28, Starmie 30 | 30 | Clefairy se encuentra y se captura |
| Lt. Surge | Carmín | Diglett/Sandshrew (este de Celeste), llegar, 15 Voltorb/Magnemite | Voltorb 36, Magnemite 38, Raichu 40 | 40 | Los de Tierra no reciben daño eléctrico |
| Erika | Azulona | Fuego/Volador/Veneno/Bicho, llegar, 15 de tipo Planta | Tangela 46, Weepinbell 48, Vileplume 50 | 50 | |
| Sabrina | Azafrán | Gastly (Torre de Lavanda), 15 de tipo Psíquico | Kadabra 56, Mr. Mime 58, Alakazam 60 | 60 | Los Gengar de la torre no son demasiado |
| Koga | Fucsia | Psíquico/Tierra, llegar, 15 de tipo Veneno | Venomoth 66, Muk 68, Weezing 70 | 70 | El camino a Fucsia |
| Blaine | Canela | Pokémon con Surf, llegar surfeando desde Paleta, 15 de tipo Fuego | Ninetales 76, Rapidash 78, Arcanine 80 | 80 | Surfear hasta la isla funciona |
| Giovanni | Verde | 15 de tipo Tierra | Rhyhorn 86, Nidoking 88, Rhydon 90 | 90 | Tras ganar, sin tope de nivel |

## Liga Pokémon

Tras Giovanni: derrotar 25 Pokémon de la Calle Victoria (oeste de Ciudad Verde, subterráneos -1 y -2)
y llegar a nivel 100. El portero de la Meseta Añil pide las 8 medallas y nivel 100. Dentro, uno tras
otro, con 25 pociones y 5 revivir en total. El último de cada uno es shiny (+25% a todo); Blue lleva dos:

| Combate | Equipo |
|---|---|
| Lorelei (Hielo) | Dewgong 92, Cloyster 92, Slowbro 93, Jynx 93, **Shiny Lapras** 94 |
| Bruno (Lucha) | Onix 93, Hitmonchan 94, Hitmonlee 94, Onix 95, **Shiny Machamp** 96 |
| Agatha (Fantasma) | Gengar 95, Golbat 95, Arbok 96, **Shiny Gengar** 97 |
| Lance (Dragón) | Gyarados 97, Dragonair 97, Dragonair 98, Aerodactyl 98, **Shiny Dragonite** 100 |
| Blue (campeón) | Pidgeot 98, Alakazam 99, Rhydon 99, Exeggutor 100, **Shiny Gyarados** 100, **Shiny Arcanine** 102 |

- [ ] Al ganar a cada uno se pasa a la sala del siguiente (la de Agatha la he calculado; mírala).
- [ ] Al perder o al decir {rendirme}, fuera de la Liga y 20 horas de espera (`/progreso liga` la quita).
- [ ] Al ganar a Blue: premio de la quest, mensaje a todo el servidor y tarea completada.
- [ ] Antes, Bruno era un pescadero de Tibia y la Liga se cortaba en el segundo combate.

## Experiencia

Objetivo: unos 30 minutos entre gimnasios. Para ver el reparto por tramo:

```powershell
python tools/combatsim/expcurve.py 2     # 2 derrotas por minuto
```

- [ ] Apunta el nivel y el tiempo de juego al llegar a cada gimnasio.
- [ ] Si subes demasiado rápido, sube `expKillsPerLevel` en `lib/core/progression.lua`; si vas lento, bájalo.
- [ ] La primera captura de cada especie da un 10 % del nivel × su tier (`catchExpLevelFraction`).

Los valores de cada gimnasio (nivel, vida ×, daño ×) están al principio de su script en
`bases/pokedashpota1.0/data/npc/scripts/<lider>.lua`. Las tareas y recompensas, en
`bases/pokedashpota1.0/data/lib/core/progression.lua`.
