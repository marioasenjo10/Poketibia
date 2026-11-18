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