# TODO — PokeDash

Lo pendiente, por bloques. Lo que ya está hecho y falta probar está en [tools/pruebas-historia.md](tools/pruebas-historia.md).

## Esperando datos del usuario

- [ ] **Mercado en la tienda**: pasar el id (y el aspecto) de la máquina del mercado de cada tienda y del objeto de al lado,
  que será la taquilla de «Recibidos». Entonces: action al usar la máquina → abre el mercado; al usar la taquilla → abre
  Recibidos. Decidir si se quita el botón «Mercado» del menú de arriba.
- [ ] **Categoría de helds/objetos especiales en el mercado**: decir cómo se llaman esos objetos aquí (o sus ids).

## Contenido

- [ ] **Gimnasios de Johto** (medallas zephyr…rising ya existen, sin NPC enganchado): niveles y Pokémon fuertes, como
  preparación para Red. Mismo sistema que Kanto (topes de nivel, bono de medalla, tareas, marca en el mapa).
- [ ] **Capítulo 2 de la historia** (ya existe en portugués en Oak, Red y el Viejo): Mewtwo en la Cueva Celeste (nivel 150) →
  Red (175) → mazmorra de Mew (175) → piedra ancestral. Meterlo en el panel de Tareas, traducir y reequilibrar a Red
  (ahora nivel 250-400 con ×10 de vida). Revisar el salto de nivel 100 → 150 (los gimnasios de Johto pueden llenarlo).
- [ ] **Mazmorras individuales en Johto**: una por especie fuerte (ej. Luxray), ~10 instancias por especie, cuevas llenas
  para cazar solo sin pisarse. Para subir del 100 al 250-300. Hace falta diseñar las cuevas en el mapa y un gestor de
  instancias (entrada que te asigna una libre).
- [ ] **Versiones más fuertes de Pokémon en Kanto** (dan más experiencia), para subir más fácil.
- [ ] **Hoenn** a partir del nivel 250-300: mapa nuevo en otra isla (más adelante).
- [ ] **Tareas diarias** (aplazadas).
- [ ] **Mercado v2**: «Make Offer» (regatear) y «Create Request» (pedidos de compra).

## Equilibrio (tras probar)

- [ ] Experiencia: `expKillsPerLevel` en `lib/core/progression.lua` (objetivo ~30 min entre gimnasios). Apuntar nivel y
  tiempo al llegar a cada gimnasio. Valorar que los Pokémon muy por debajo del tramo den menos.
- [ ] Gimnasios, Alto Mando y campeón: niveles, vida y daño al principio de cada `npc/scripts/<lider>.lua`.
- [ ] Runas (`lib/core/runes.lua`) y premio semanal (`lib/core/weeklyquests.lua`).
- [ ] Sala de Agatha en la Liga: la posición a la que manda Bruno al ganar está calculada, comprobar que no es una pared.

## Mapa y spawns

- [ ] Kanto, pisos altos: siguen los Johto fuertes (≈90 Steelix, Tyranitar…). Decidir si se quitan.
- [ ] Subterráneos (pisos 8-11): muchos Hoenn y legendarios (Rayquaza, Latios…). Decidir cuando se diseñe esa zona.
- [ ] Zona Safari (Fucsia): 12 Tauros entre Carmín y Fucsia se cambiaron por Doduo; si eran de la Safari, devolverlos.
- [ ] Quests de cofre en regiones que aún no son de la historia (Outland, Eternia, Nostrus, Arcania, R'lyeh, Lunna, Snow,
  Johto): revisar niveles y premios cuando se integren. Ficha de todas: `python tools/questreview.py`.

## Limpieza y mantenimiento

- [ ] Textos en portugués que quedan: Oak (parte de quests), Red, el Viejo y `XML/quests.xml` (registro antiguo, ya no se usa).
- [ ] Copia de `Tibia.spr` (≈490 MB) fuera del PC: no cabe en GitHub.
- [ ] Comprobar los Lua antes de cada commit (hook con `tools/luacheck_strings.py` + luaparser).
- [ ] Ordenar los `.txt` sueltos de la raíz (`contexto-claude.txt`, `paso*.txt`, `diag-calor.txt`, `revision-base.txt`).

## Antes de abrir el servidor a otros

- [ ] Contraseña de MySQL (ahora `root` sin contraseña) y revisar `passwordType = sha1`.
- [ ] Sistema de actualización del cliente (los cambios de sprites obligan a bajar el `.spr` entero).
- [ ] Quitar las cuentas de prueba de `/progreso` (`TEST_ACCOUNTS` en `talkactions/scripts/progreso.lua`).
