# Montar Poketibia en tu PC (servidor + cliente + cuenta GOD)

Guía paso a paso para quien quiera ayudar con el proyecto. Servidor: PokeDash PotA (protocolo 10.98) sobre TFS, con un OTClient personalizado.

## Resumen: paso a paso

1. Instala **Git**, **XAMPP** y el **Visual C++ Redistributable 2022 x64**. Opcional: **GitHub CLI** (`gh`), imprescindible si el repositorio es privado.
2. `git clone` del repositorio.
3. Ejecuta `descargar.ps1` (baja los sprites). Antes, quien tenga el proyecto debe haber editado `$Repo` y `$Tag` dentro del script y haber subido `Tibia.spr` a la Release.
4. Abre XAMPP y arranca solo **MySQL**. En phpMyAdmin crea la base `pokedashpota` e importa `bases/pokedashpota1.0/schema.sql`.
5. En `bases/pokedashpota1.0/config.lua` pon tu usuario y contraseña de MySQL (en XAMPP suele ser `root` y contraseña vacía).
6. Arranca `bases/pokedashpota1.0/pokedashpota_win64.exe`.
7. Abre el cliente y entra en `127.0.0.1` con la cuenta `gm` y el personaje **GOD Pota** (ver sección 5).

## 1. Qué viene en git y qué no

Con `git clone` te llegan los scripts Lua, los XML (monstruos, items, talkactions...), `schema.sql`, `config.lua`, el cliente (módulos), `Tibia.dat`, el mapa (`global_dash.otbm`, ~83 MB) y el ejecutable `pokedashpota_win64.exe` con sus `.dll`.

**No** vienen en git por su tamaño. Los baja `descargar.ps1` desde una Release de GitHub:

| Archivo | Dónde queda | Tamaño aprox. |
|---|---|---|
| `Tibia.spr` (sprites) | `bases/pokedashpota1.0_client/data/things/1098/` | ~487 MB |

Usa el ejecutable original de Poketibia. **No** uses el `tfs.exe` que se compila desde `forgottenserver-1.6`: es incompatible con esta base.

### Para quien mantiene el proyecto: subir los archivos grandes

1. En GitHub: Releases → *Draft a new release*, con la etiqueta que pongas en `$Tag` de `descargar.ps1` (por ejemplo `datos-v1`).
2. Adjunta `Tibia.spr` (puede pesar hasta 2 GB).
3. Si cambian los sprites, crea otra release (`datos-v2`...) y actualiza `$Tag`.

## 2. Base de datos

1. Arranca MySQL en XAMPP (o instala MariaDB/MySQL por tu cuenta).
2. Crea la base de datos `pokedashpota` (host `127.0.0.1`, puerto `3306`).
3. Importa `bases/pokedashpota1.0/schema.sql`.
4. En `config.lua` pon tu propio usuario y contraseña (`mysqlUser`, `mysqlPass`). No subas tus credenciales a git.

## 3. Arrancar el servidor

Ejecuta `bases/pokedashpota1.0/pokedashpota_win64.exe`. Escucha en `127.0.0.1`, puertos 7171 (login) y 7172 (juego). El mapa es `global_dash`.

Tras cambiar archivos Lua o XML hay que **reiniciar el servidor** para que se apliquen.

## 4. Cliente

Abre el OTClient personalizado (carpeta `otclient/` y `bases/pokedashpota1.0_client/`) y conéctate a `127.0.0.1`. Necesita `Tibia.spr` y `Tibia.dat` en `data/things/1098/`.

## 5. Cuenta y personaje GOD

El `schema.sql` ya trae una cuenta `gm` (tipo 6) con el personaje **GOD Pota**, del grupo `god` (id 3 en `data/XML/groups.xml`). Si no sabes la contraseña, cámbiala con SQL (la columna `password` es un hash de 40 caracteres, SHA-1):

```sql
UPDATE accounts SET password = SHA1('tu_contraseña') WHERE name = 'gm';
```

Para convertir otro personaje en god: `UPDATE players SET group_id = 3 WHERE name = 'TuPersonaje';` con el personaje desconectado, y la cuenta con `type` 6.

Los comandos de GM/god están en `comandos-juego.md` (`/m`, `/i`, `/s`, `/cb`, `/setlevel`, `/goto`...).

## 6. Al editar archivos

- Los XML de Pokémon (`data/monster/Pokes1/`) están en **ISO-8859-1**. No dejes que el editor los convierta a UTF-8.
- Los Lua usan saltos de línea **CRLF**; respétalos.
- Antes de subir cambios: `git status` y no sobrescribas cambios de otros.
- El mapa (`global_dash.otbm`) está en git, pero es binario y no se puede fusionar: antes de editarlo, haz `git pull` y avisa para que no lo editéis dos a la vez. Está cerca del tope de GitHub (100 MB por archivo) y cada cambio guarda una copia entera en el historial.

## 7. Herramientas (opcionales)

- Editor de mapas: Remere's Map Editor (debe coincidir con el `items.otb` del servidor).
- Editor de items: `bases/item editor 10.98 32 bits/`.
- Editor de sprites y objetos: `bases/ObjectBuilder_edited/`.
