# Cuentas de prueba (solo servidor local)

Creadas por Claude para testear el inicio del juego. No usar en un servidor publico.

| Cuenta | Contrasena | Personaje |
|---|---|---|
| claudetest1 | Tstfbe7500c9e | Claude Tester |
| claudeplantillas | peu3gcm07wnh8tk4 | Plantilla Brock (no jugar: es la copia de seguridad) |

## Plantillas para no repetir el principio

Las plantillas son personajes congelados en un punto de la historia, en la cuenta `claudeplantillas`.
Con [clonar-personaje.ps1](clonar-personaje.ps1) se copian encima del tester (con el servidor cerrado o el tester desconectado):

| Plantilla | Estado |
|---|---|
| Plantilla Brock | Copia de Claude Tester Dos (nivel 17) con la Medalla Roca. Al entrar se cierra la tarea de Brock y empieza la ruta a Misty. |
| Plantilla Misty | Claude Tester Dos (nivel 31) recién ganada la Medalla Cascada, en Ciudad Celeste. Sigue la ruta al Teniente Surge. |
| Plantilla Surge | Claude Tester Dos (nivel 41) con 3 medallas (Roca, Cascada, Trueno), en el Centro Pokémon de Ciudad Carmín. Sigue «Contra las plantas» (25 voladores al norte de Carmín) y la ruta a Erika. |
| Plantilla Erika | Claude Tester Dos (nivel 50) con 4 medallas (Roca, Cascada, Trueno, Arcoíris). En tierra en 864,1095,6 (Fearow guardado). Sigue «lavender_gastly» (capturar un Gastly) y la ruta a Sabrina. |
| Plantilla Sabrina | Claude Tester Dos (nivel 59) con 5 medallas (Roca, Cascada, Trueno, Arcoíris, Pantano), en Ciudad Azafrán (1059,1048,7). Sigue «Entrenamiento en el Safari» (50 derrotas en la Zona Safari) y la ruta a Koga. |
| Plantilla Koga | Claude Tester Dos (nivel 70) con 6 medallas (hasta la Alma), en el piso 1 de la tienda de Ciudad Fucsia (1226,1365,6). Al entrar siguen «Preparacion contra Blaine» (opcional) y «Rumbo a Isla Canela». |
| Plantilla Blaine | Claude Tester Dos (nivel 80) con 7 medallas (hasta la Volcan), en Isla Canela (846,1397,7). Siguen el entrenamiento de tipo Tierra (opcional) y «La Medalla Tierra» contra Giovanni. |
| Plantilla Giovanni | Claude Tester Dos (nivel 91) con las 8 medallas, en Ciudad Verde (704,1089,7). Sigue la Calle Victoria (25 derrotas) de camino a la Liga. |

```powershell
# dejar a Claude Tester Dos como en la plantilla
.\tools\clonar-personaje.ps1 -Origen "Plantilla Brock" -Destino "Claude Tester Dos" -Reemplazar

# guardar una plantilla nueva (por ejemplo, despues de Misty)
.\tools\clonar-personaje.ps1 -Origen "Claude Tester Dos" -Destino "Plantilla Misty" -Cuenta claudeplantillas

# ver las plantillas
.\tools\clonar-personaje.ps1 -Listar
```
