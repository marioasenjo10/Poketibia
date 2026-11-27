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
| Misty | Celeste | Clefairy (al este de Plateada), llegar, 15 Psyduck (opcional) | Shiny Staryu 28, Golduck 29, Quagsire 29, Starmie 32 (vida x4,5) | 30 | Clefairy se encuentra y se captura |
| Lt. Surge | Carmín | Diglett/Sandshrew (este de Celeste), llegar + 15 eléctricos en la Central de Energía (opcional, a la vez) | Magneton 38, Electrode 39, Shiny Electrode 41, Raichu 44 (vida x4,5-6) | 40 | Con Tierra no basta un solo Pokémon; cambio de Spearow por Farfetch'd (Ramon, Centro Pokémon de Carmín) |
| Erika | Azulona | 25 voladores al norte de Carmín (Noctowl), llegar, 15 de tipo Planta | Tangela 46, Victreebel 48, Vileplume 49, Bellossom 50 | 50 | |
| Sabrina | Azafrán | Gastly (Torre de Lavanda), 15 de tipo Psíquico | Kadabra 56, Mr. Mime 58, Alakazam 60 | 60 | Los Gengar de la torre no son demasiado |
| Koga | Fucsia | Psíquico/Tierra, llegar, 15 de tipo Veneno | Venomoth 66, Crobat 67, Muk 68, Weezing 70 | 70 | El camino a Fucsia |
| Blaine | Canela | Llegar volando o surfeando; 50 en los alrededores de la isla (opcional) | Shiny Ninetales 76, Magmar 77, Shiny Rapidash 78, Arcanine 80 | 80 | Surfear hasta la isla funciona |
| Giovanni | Verde | 15 de tipo Tierra | Dugtrio 86, Shiny Persian 86, Nidoqueen 87, Golem 88, Nidoking 89, Rhydon 90 | 90 | Tras ganar, sin tope de nivel |

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

## Mercado global

Botón **Mercado** (bolsa azul) en el menú de arriba. Solo se abre cerca de un tendero (icono de la
bolsa en el mapa); los GM pueden abrirlo en cualquier sitio. Para probar compra y venta hacen falta
dos personajes (no se puede comprar lo propio): por ejemplo Claude Tester Dos y GOD Pota.

- [ ] **Vender** un objeto apilable (pociones, balls) indicando cantidad y precio: desaparece de la mochila.
- [ ] **Vender** un Pokémon: el que tienes fuera no sale en la lista.
- [ ] **Comprar** con otro personaje: cobra del banco y va a **Recibidos**; al vendedor le llega el dinero
  (menos el 5 %) aunque esté desconectado, y un aviso en sus Recibidos.
- [ ] **Recoger** en Recibidos: el Pokémon conserva boost, vida y cariño.
- [ ] **Mis ofertas → Cancelar**: vuelve a Recibidos. Las ofertas caducan a los 7 días.
- [ ] Categorías, búsqueda y páginas.

Ajustes al principio de `bases/pokedashpota1.0/data/lib/core/pokemarket.lua` (comisión, duración, máximo de
ofertas, distancia a la tienda). Tablas en la base de datos: `pkd_market_offers` y `pkd_market_locker`.

## Runas

Se consiguen con las quests semanales y la Liga (runas en blanco y fragmentos rúnicos). Con `/i 2260`
y `/i 2150` (GM) se pueden crear para probar.

- [ ] `!runas` → **Fabricar**: 1 runa en blanco + 10 fragmentos = runa de tier I al azar.
- [ ] Usar la runa sobre una Pokéball con Pokémon: al mirarla sale «Runas: ...». Máximo 3, de tipos distintos.
- [ ] Guardar y sacar el Pokémon: la de Vida sube su vida máxima; Ataque y Defensa se notan en combate.
- [ ] `!runas` → **Fusionar** 3 iguales → una del tier siguiente. **Quitar** devuelve la runa a la mochila.
- [ ] Las runas de Tibia usadas (great fireball, magic wall, intense healing, holy missile, sudden death)
  ya no lanzan hechizos.

## Quests semanales

- [ ] Un cofre de quest (por ejemplo el de Mt. Moon, nivel 25): premio semanal (banco, experiencia,
  fragmentos y una runa en blanco) y como mucho 3 piedras. Al repetirlo, «Vuelve dentro de X».
- [ ] La Liga: una vez por semana, ganes o pierdas; cada victoria da el premio de nivel 100.
- [ ] Moltres con 1 jugador; Annihilator con 2 (con 1 debe avisar).
- [ ] Simon deja pasar a la Calle Victoria con las 8 medallas y sin límite diario.

Ajustes: `lib/core/runes.lua` (tiers, coste de fabricar) y `lib/core/weeklyquests.lua` (premio semanal).

## Orbes de evolución shiny

Para probar sin cazar: `/progreso orbe shiny charmeleon` crea el orbe que toca con ese destino.

- [ ] Un shiny que es evolución (Shiny Charmeleon, Shiny Raichu…) suelta a veces un orbe: bronce (T3-T7), verde (T2)
  o plata (T1) según su rareza.
- [ ] En la mochila se ve el holograma del shiny con el orbe pequeño en la esquina; al pasar el ratón,
  «Orbe de evolución: Shiny X». Al mirarlo: «Evoluciona a: Shiny X».
- [ ] Usarlo con la fase anterior fuera (Shiny Charmander para un orbe de Shiny Charmeleon): evoluciona.
  Con otro Pokémon avisa de que no sirve.
- [ ] En el mercado sale como «Orbe De Evolucion De Bronce (Shiny X)».
- [ ] Evoluciones arregladas: Shiny Sentret → Shiny Furret, Shiny Tyrogue → Hitmonlee/Hitmonchan,
  Shiny Porygon → Porygon2, Shiny Chansey → Blissey.
