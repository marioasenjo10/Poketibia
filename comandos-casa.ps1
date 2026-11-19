# =====================================================================
# Comandos para ejecutar en el ordenador de casa.
# Uso: haz git pull, abre este archivo, copia el bloque que toque
# y pégalo en una terminal PowerShell.
# =====================================================================

# ---------------------------------------------------------------------
# [1] (HECHO) Revisión de seguridad de la base PokeDash
#     Genera revision-base.txt. Después: commit + push.
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
$b = 'bases\pokedashpota1.0'
$o = 'revision-base.txt'

"=== CONFIG ===" | Out-File $o
Get-Content "$b\config.lua" | Out-File $o -Append

"=== SOSPECHOSOS ===" | Out-File $o -Append
Get-ChildItem "$b\data", 'bases\pokedashpota1.0_client\modules' -Recurse -Include *.lua |
    Select-String -Pattern 'os\.execute|io\.popen|io\.open|loadstring|dofile|require|socket|http|setGroup|setAccountType|db\.query|getAccountType|ACCOUNT_TYPE_GOD|groupId' |
    ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" } |
    Out-File $o -Append -Width 400

"=== POKES ===" | Out-File $o -Append
Get-ChildItem "$b\data\monster\Pokes1" -Recurse -File |
    Select-Object -ExpandProperty Name |
    Out-File $o -Append

"=== THINGS ===" | Out-File $o -Append
Get-ChildItem 'bases\pokedashpota1.0_client\data\things' -Recurse -File |
    Select-Object FullName, Length |
    Out-File $o -Append -Width 300

git add $o
git commit -m "Revision de seguridad de la base PokeDash"
git push

# ---------------------------------------------------------------------
# [2] Preparar la base de datos de PokeDash
#     ANTES: cierra el servidor TFS 1.6 (usa los mismos puertos).
#            XAMPP con MySQL arrancado.
#     Crea la BD 'pokedashpota', importa schema.sql, crea la cuenta
#     admin/admin (GOD) y genera paso2.txt con info para el paso 3.
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
$base  = 'C:/Develop/Poketibia-project/bases/pokedashpota1.0'
$cli   = 'bases\pokedashpota1.0_client'
$o     = 'paso2.txt'

"=== CREAR BD + IMPORTAR ===" | Out-File $o -Encoding utf8
& $mysql -u root -e "CREATE DATABASE IF NOT EXISTS pokedashpota CHARACTER SET utf8;" 2>&1 | Out-File $o -Append -Encoding utf8
& $mysql -u root pokedashpota -e "source $base/schema.sql" 2>&1 | Out-File $o -Append -Encoding utf8

"=== CREAR CUENTA admin/admin ===" | Out-File $o -Append -Encoding utf8
& $mysql -u root pokedashpota -e "INSERT INTO accounts (name, password, email, type, creation) VALUES ('admin', SHA1('admin'), 'admin@local', 5, UNIX_TIMESTAMP());" 2>&1 | Out-File $o -Append -Encoding utf8

"=== TABLAS ===" | Out-File $o -Append -Encoding utf8
& $mysql -u root pokedashpota -e "SHOW TABLES;" 2>&1 | Out-File $o -Append -Encoding utf8
"=== CUENTAS ===" | Out-File $o -Append -Encoding utf8
& $mysql -u root pokedashpota -e "SELECT id, name, type FROM accounts;" 2>&1 | Out-File $o -Append -Encoding utf8
"=== PLAYERS EXISTENTES ===" | Out-File $o -Append -Encoding utf8
& $mysql -u root pokedashpota -e "SELECT id, name, account_id, group_id, level, vocation, town_id, posx, posy, posz FROM players;" 2>&1 | Out-File $o -Append -Encoding utf8
"=== ESTRUCTURA PLAYERS ===" | Out-File $o -Append -Encoding utf8
& $mysql -u root pokedashpota -e "SHOW CREATE TABLE players\G" 2>&1 | Out-File $o -Append -Encoding utf8

"=== CLIENTE: init.lua ===" | Out-File $o -Append -Encoding utf8
Get-Content "$cli\init.lua" | Out-File $o -Append -Encoding utf8
"=== CLIENTE: lineas con host/ip/puerto/version ===" | Out-File $o -Append -Encoding utf8
Get-ChildItem "$cli\modules\client_entergame", "$cli\modules\client_serverlist" -Recurse -Include *.lua, *.otui |
    Select-String -Pattern 'host|Host|port|Port|clientVersion|ClientVersion|Servers|127\.0|\d+\.\d+\.\d+\.\d+' |
    ForEach-Object { "$($_.Filename):$($_.LineNumber): $($_.Line.Trim())" } |
    Out-File $o -Append -Encoding utf8 -Width 400

git add $o
git commit -m "Paso 2: BD PokeDash"
git push

# (SQL usado en phpMyAdmin para pasar GOD Pota a la cuenta admin - NO pegar en PowerShell)
# INSERT INTO accounts (name, password, email, type, creation)
# VALUES ('admin', SHA1('admin'), 'admin@local', 5, UNIX_TIMESTAMP());
# UPDATE players
# SET account_id = (SELECT id FROM accounts WHERE name = 'admin'), group_id = 3
# WHERE name = 'GOD Pota';

# ---------------------------------------------------------------------
# [3] Listar los comandos de GM, NPCs y scripts de la base
#     Genera paso3.txt. Después: commit + push.
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
$b = 'bases\pokedashpota1.0\data'
$o = 'paso3.txt'

"=== TALKACTIONS.XML (comandos) ===" | Out-File $o -Encoding utf8
Get-Content "$b\talkactions\talkactions.xml" | Out-File $o -Append -Encoding utf8

"=== NPCS ===" | Out-File $o -Append -Encoding utf8
Get-ChildItem "$b\npc" -File -Filter *.xml | Select-Object -ExpandProperty BaseName | Out-File $o -Append -Encoding utf8

"=== ACTIONS.XML ===" | Out-File $o -Append -Encoding utf8
Get-Content "$b\actions\actions.xml" | Out-File $o -Append -Encoding utf8

"=== CREATURESCRIPTS.XML ===" | Out-File $o -Append -Encoding utf8
Get-Content "$b\creaturescripts\creaturescripts.xml" | Out-File $o -Append -Encoding utf8

"=== CIUDADES (del mapa) ===" | Out-File $o -Append -Encoding utf8
$bytes = [IO.File]::ReadAllBytes((Resolve-Path "$b\world\global_dash.otbm").Path)
$i = [Math]::Max(0, $bytes.Length - 5MB)
while (($i = [Array]::IndexOf($bytes, [byte]0xFE, $i)) -ge 0 -and $i -lt $bytes.Length - 8) {
    if ($bytes[$i+1] -eq 0x0D) {
        $id  = [BitConverter]::ToUInt32($bytes, $i+2)
        $len = [BitConverter]::ToUInt16($bytes, $i+6)
        if ($len -gt 0 -and $len -lt 40) {
            $name = [Text.Encoding]::ASCII.GetString($bytes, $i+8, $len)
            if ($name -match '^[\w \.\-]+$') { "town $id : $name" | Out-File $o -Append -Encoding utf8 }
        }
    }
    $i++
}

git add $o
git commit -m "Paso 3: comandos y NPCs PokeDash"
git push

# ---------------------------------------------------------------------
# [4] Preparar el editor de mapas (RME) con los items de PokeDash
#     Copia items.otb e items.xml del servidor a RME (guarda copia
#     de los originales en data\1098\original\).
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project\bases'
$rme = 'pack_mapper\rme-3.5\data\1098'
$srv = 'pokedashpota1.0\data\items'
New-Item -ItemType Directory -Force "$rme\original" | Out-Null
foreach ($f in 'items.otb', 'items.xml') {
    if ((Test-Path "$rme\$f") -and -not (Test-Path "$rme\original\$f")) { Copy-Item "$rme\$f" "$rme\original\$f" }
    Copy-Item "$srv\$f" "$rme\$f" -Force
}
Get-ChildItem $rme -File | Select-Object Name, Length

# ---------------------------------------------------------------------
# [5] Diagnóstico del calentamiento
#     ANTES: servidor y cliente abiertos, dentro del juego, con tu
#            Pokémon fuera y cerca de Pokémon salvajes.
#     Mide CPU y GPU durante 15 segundos (no toques nada mientras).
#     Genera diag-calor.txt. Después: commit + push.
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
$o   = 'diag-calor.txt'
$cli = 'bases\pokedashpota1.0_client'
$seg = 15
$cores = [Environment]::ProcessorCount

"=== EQUIPO ===" | Out-File $o -Encoding utf8
(Get-CimInstance Win32_Processor).Name | Out-File $o -Append -Encoding utf8
"Nucleos logicos: $cores" | Out-File $o -Append -Encoding utf8
Get-CimInstance Win32_VideoController | ForEach-Object { "GPU: $($_.Name) | $($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution) @ $($_.CurrentRefreshRate) Hz" } | Out-File $o -Append -Encoding utf8

Write-Host "Midiendo $seg segundos, no toques nada..."
$antes = @{}; Get-Process | ForEach-Object { $antes[$_.Id] = $_.CPU }
$gpuMuestras = @()
for ($s = 0; $s -lt $seg; $s++) {
    $gpuMuestras += Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'engtype_3D' -and $_.UtilizationPercentage -gt 0 }
    Start-Sleep -Seconds 1
}

"=== CPU (% del total del procesador, media $seg s) ===" | Out-File $o -Append -Encoding utf8
Get-Process | Where-Object { $antes.ContainsKey($_.Id) -and $_.CPU } | ForEach-Object {
    [pscustomobject]@{
        Proceso = $_.ProcessName
        CPU     = [math]::Round((($_.CPU - $antes[$_.Id]) / $seg / $cores) * 100, 1)
        RAM_MB  = [math]::Round($_.WorkingSet64 / 1MB)
        Prioridad = $_.PriorityClass
    }
} | Sort-Object CPU -Descending | Select-Object -First 12 | Format-Table -AutoSize | Out-File $o -Append -Encoding utf8 -Width 200

"=== GPU 3D (% medio por proceso) ===" | Out-File $o -Append -Encoding utf8
$gpuMuestras | ForEach-Object {
    $procId = if ($_.Name -match 'pid_(\d+)_') { [int]$Matches[1] } else { 0 }
    [pscustomobject]@{ Proceso = (Get-Process -Id $procId -ErrorAction SilentlyContinue).ProcessName; GPU = $_.UtilizationPercentage }
} | Group-Object Proceso | ForEach-Object {
    [pscustomobject]@{ Proceso = $_.Name; GPU = [math]::Round((($_.Group | Measure-Object GPU -Sum).Sum) / $seg, 1) }
} | Sort-Object GPU -Descending | Select-Object -First 8 | Format-Table -AutoSize | Out-File $o -Append -Encoding utf8 -Width 200

"=== SERVIDOR: prioridad ===" | Out-File $o -Append -Encoding utf8
Select-String -Path 'bases\pokedashpota1.0\config.lua' -Pattern 'defaultPriority' | ForEach-Object { $_.Line } | Out-File $o -Append -Encoding utf8

"=== CLIENTE: archivos de configuracion (config.otml) ===" | Out-File $o -Append -Encoding utf8
@(Get-ChildItem $cli -Recurse -Filter config.otml -ErrorAction SilentlyContinue) +
@(Get-ChildItem $env:APPDATA -Recurse -Depth 2 -Filter config.otml -ErrorAction SilentlyContinue) | ForEach-Object {
    "--- $($_.FullName) ($($_.LastWriteTime))" | Out-File $o -Append -Encoding utf8
    Get-Content $_.FullName | Out-File $o -Append -Encoding utf8
}

"=== CLIENTE: codigo de FPS / vsync ===" | Out-File $o -Append -Encoding utf8
Get-ChildItem "$cli\modules", "$cli\init.lua", "$cli\otclientrc.lua" -Recurse -Include *.lua, *.otui -ErrorAction SilentlyContinue |
    Select-String -Pattern 'vsync|VerticalSync|FrameRate|MaxFps|setFps|frameRate|fpsLimit' |
    ForEach-Object { "$($_.Path -replace '^.*?bases\\',''):$($_.LineNumber): $($_.Line.Trim())" } |
    Out-File $o -Append -Encoding utf8 -Width 400

git add $o
git commit -m "Diagnostico calentamiento"
git push

# ---------------------------------------------------------------------
# [6] (HECHO) Ver cómo funciona /cb (crear pokeball) y cómo se guarda un poke
#     Genera paso6.txt con el script de /cb, el de usar la pokeball
#     y las funciones de la librería que guardan el Pokémon en la ball.
#     Después: commit + push.
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
$d = 'bases\pokedashpota1.0\data'
$o = 'paso6.txt'

"=== talkactions\scripts\create_pokeball.lua ===" | Out-File $o -Encoding utf8
Get-Content "$d\talkactions\scripts\create_pokeball.lua" | Out-File $o -Append -Encoding utf8

"=== actions\scripts\poke\summon.lua ===" | Out-File $o -Append -Encoding utf8
Get-Content "$d\actions\scripts\poke\summon.lua" | Out-File $o -Append -Encoding utf8

"=== actions.xml: lineas de poke/summon.lua (ids de las balls) ===" | Out-File $o -Append -Encoding utf8
Select-String -Path "$d\actions\actions.xml" -Pattern 'poke/summon.lua' | ForEach-Object { $_.Line.Trim() } | Out-File $o -Append -Encoding utf8

"=== Funciones relacionadas en data\lib ===" | Out-File $o -Append -Encoding utf8
Get-ChildItem "$d\lib" -Recurse -Include *.lua |
    Select-String -Pattern 'filled|pokeName|setSpecialAttribute|getSpecialAttribute|addPokeball|createPokeball|ballKey|pokeballs\s*=' |
    ForEach-Object { "$($_.Path -replace '^.*?data\\',''):$($_.LineNumber): $($_.Line.Trim())" } |
    Out-File $o -Append -Encoding utf8 -Width 400

git add $o
git commit -m "Paso 6: scripts de pokeball"
git push

# ---------------------------------------------------------------------
# [7] (HECHO) Arreglar /cb para que use la misma función que el juego
#     (doAddPokeball) y sacar más info por si no basta.
#     - Guarda el original como create_pokeball.lua.bak
#     - Genera paso7.txt. Después: commit + push.
#     DESPUÉS: reinicia el servidor y prueba /cb groudon
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
$d  = 'bases\pokedashpota1.0\data'
$cb = "$d\talkactions\scripts\create_pokeball.lua"
$o  = 'paso7.txt'

if (-not (Test-Path "$cb.bak")) { Copy-Item $cb "$cb.bak" }
@'
function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return false
	end

	local split = param:split(",")
	local name = (split[1] or ""):match("^%s*(.-)%s*$")
	if name == "" or not MonsterType(name) then
		player:sendCancelMessage("Pokemon not found.")
		return false
	end

	name = firstToUpper(name)
	local level = tonumber(split[2]) or 1
	local boost = tonumber(split[3]) or 0

	doAddPokeball(player:getId(), name, level, boost, getBallKey(balls.ultraball.usedOn), false, 0)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end
'@ | Set-Content $cb -Encoding ASCII

$nf = Get-Content "$d\lib\core\newfunctions.lua"
"=== newfunctions.lua 2600-2690 (doAddPokeball) ===" | Out-File $o -Encoding utf8
$nf[2599..2689] | Out-File $o -Append -Encoding utf8
"=== newfunctions.lua: canReleaseSummon / balls = ===" | Out-File $o -Append -Encoding utf8
$i = ($nf | Select-String -Pattern 'function Player:canReleaseSummon|function Player.canReleaseSummon' | Select-Object -First 1).LineNumber
if ($i) { $nf[($i-1)..($i+40)] | Out-File $o -Append -Encoding utf8 }
Get-ChildItem "$d\lib" -Recurse -Include *.lua | Select-String -Pattern '^\s*balls\s*=' | ForEach-Object {
    $l = Get-Content $_.Path; $l[($_.LineNumber-1)..($_.LineNumber+20)]
} | Out-File $o -Append -Encoding utf8
"=== item_attributes.lua ===" | Out-File $o -Append -Encoding utf8
Get-Content "$d\lib\core\item_attributes.lua" | Out-File $o -Append -Encoding utf8
"=== events\scripts\player.lua (onLook) ===" | Out-File $o -Append -Encoding utf8
Get-Content "$d\events\scripts\player.lua" -TotalCount 120 | Out-File $o -Append -Encoding utf8

git add $o
git commit -m "Paso 7: arreglo /cb + info"
git push

# ---------------------------------------------------------------------
# [8] Subir a git el servidor y el cliente de PokeDash
#     El .gitignore (ya actualizado) deja FUERA: el mapa .otbm, los
#     sprites (things), los .exe/.dll, los binarios de Linux y los logs.
#     Si algo pesa demasiado, NO sube nada y te dice qué es.
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
git pull
git add bases/pokedashpota1.0 bases/pokedashpota1.0_client
$files = @(git -c core.quotepath=off diff --cached --name-only)
$sizes = $files | ForEach-Object { $f = Get-Item -LiteralPath $_ -ErrorAction SilentlyContinue; if ($f) { [pscustomobject]@{ Path = $_; MB = [math]::Round($f.Length / 1MB, 1) } } }
$total = [math]::Round((($sizes | Measure-Object MB -Sum).Sum), 1)
"Archivos: $($files.Count)   Total: $total MB"
$big = @($sizes | Where-Object { $_.MB -gt 20 })
if ($big.Count -gt 0 -or $total -gt 150) {
    "DEMASIADO GRANDE, no se sube nada. Archivos grandes:"
    $sizes | Sort-Object MB -Descending | Select-Object -First 10 | Format-Table -AutoSize
    git reset -q
} else {
    git commit -q -m "PokeDash: servidor y cliente (sin mapa, sprites ni binarios)"
    git push
}

# ---------------------------------------------------------------------
# [9] Dibujo brillante para los objetos de evolucion shiny (46001+)
#     Crea en Tibia.dat/Tibia.spr una copia "brillante" del dibujo de cada
#     objeto y la asigna en items.otb. Primero hace una PRUEBA sin tocar nada
#     y genera tools\pokeassets\preview.png (izquierda original, derecha brillo).
#     Guarda copias *.bak de los 3 archivos antes de modificarlos.
#     IMPORTANTE: cierra el cliente y el servidor antes de ejecutarlo.
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
git pull
$t   = (Resolve-Path 'tools\pokeassets').Path
$dat = (Resolve-Path 'bases\pokedashpota1.0_client\data\things\1098\Tibia.dat').Path
$spr = (Resolve-Path 'bases\pokedashpota1.0_client\data\things\1098\Tibia.spr').Path
$otb = (Resolve-Path 'bases\pokedashpota1.0\data\items\items.otb').Path
$pre = Join-Path $t 'preview.png'
Add-Type -Path "$t\Otb.cs","$t\Things.cs" -ReferencedAssemblies System.Drawing
[PokeAssets]::Run($dat, $spr, $otb, 46001, 46999, $pre, $true)
Start-Process $pre
# Si la prueba dice "Prueba OK" y la imagen te gusta, ejecuta estas 4 lineas:
[PokeAssets]::Run($dat, $spr, $otb, 46001, 46999, $null, $false)
git add bases/pokedashpota1.0/data/items/items.otb tools/pokeassets/preview.png
git commit -q -m "Objetos de evolucion shiny con dibujo brillante"
git push


PS C:\Develop\Poketibia-project> Set-Location 'C:\Develop\Poketibia-project'
PS C:\Develop\Poketibia-project> git pull
Already up to date.
PS C:\Develop\Poketibia-project> $t   = (Resolve-Path 'tools\pokeassets').Path
PS C:\Develop\Poketibia-project> $dat = (Resolve-Path 'bases\pokedashpota1.0_client\data\things\1098\Tibia.dat').Path
PS C:\Develop\Poketibia-project> $spr = (Resolve-Path 'bases\pokedashpota1.0_client\data\things\1098\Tibia.spr').Path
PS C:\Develop\Poketibia-project> $otb = (Resolve-Path 'bases\pokedashpota1.0\data\items\items.otb').Path
PS C:\Develop\Poketibia-project> $pre = Join-Path $t 'preview.png'
PS C:\Develop\Poketibia-project> Add-Type -Path "$t\Otb.cs","$t\Things.cs" -ReferencedAssemblies System.Drawing

PS C:\Develop\Poketibia-project> [PokeAssets]::Run($dat, $spr, $otb, 46001, 46999, $pre, $true)
Excepción al llamar a "Run" con los argumentos "7": "No se pudo leer Tibia.dat: atributo desconocido 254 en 
593"
En línea: 1 Carácter: 1
+ [PokeAssets]::Run($dat, $spr, $otb, 46001, 46999, $pre, $true)
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : Exception
 
PS C:\Develop\Poketibia-project> Start-Process $pre
Start-Process : Este comando no se puede ejecutar debido al error: El sistema no puede encontrar el archivo 
especificado.
En línea: 1 Carácter: 1
+ Start-Process $pre
+ ~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [Start-Process], InvalidOperationException
    + FullyQualifiedErrorId : InvalidOperationException,Microsoft.PowerShell.Commands.StartProcessCommand
 
PS C:\Develop\Poketibia-project> # Si la prueba dice "Prueba OK" y la imagen te gusta, ejecuta estas 4 lineas:
PS C:\Develop\Poketibia-project> [PokeAssets]::Run($dat, $spr, $otb, 46001, 46999, $null, $false)
Excepción al llamar a "Run" con los argumentos "7": "No se pudo leer Tibia.dat: atributo desconocido 254 en 
593"
En línea: 1 Carácter: 1
+ [PokeAssets]::Run($dat, $spr, $otb, 46001, 46999, $null, $false)
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : Exception
 
PS C:\Develop\Poketibia-project> git add bases/pokedashpota1.0/data/items/items.otb tools/pokeassets/preview.png
fatal: pathspec 'tools/pokeassets/preview.png' did not match any files
PS C:\Develop\Poketibia-project> git commit -q -m "Objetos de evolucion shiny con dibujo brillante"
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
PS C:\Develop\Poketibia-project> git push
Everything up-to-date