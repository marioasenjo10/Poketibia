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