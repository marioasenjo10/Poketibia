<#
Copia un personaje entero (nivel, posicion, Pokemon, objetos, deposito, storages de tareas y medallas)
a otro nombre. Sirve para guardar "puntos de partida" de pruebas y volver a ellos en segundos.

Uso tipico:
  # 1) Guardar una plantilla (una vez). Va a la cuenta de plantillas para no jugarla sin querer.
  .\tools\clonar-personaje.ps1 -Origen "Claude Tester Dos" -Destino "Plantilla Brock" -Cuenta claudeplantillas

  # 2) Antes de cada prueba: dejar al tester como en la plantilla
  .\tools\clonar-personaje.ps1 -Origen "Plantilla Brock" -Destino "Claude Tester Dos" -Reemplazar

  # Ver las plantillas guardadas
  .\tools\clonar-personaje.ps1 -Listar

Reglas:
  - El DESTINO no puede estar conectado. Lo mas seguro es tener el servidor cerrado.
  - Si el ORIGEN esta conectado, se copia lo ultimo que el servidor guardo (al salir o con /save).
  - -Reemplazar borra el destino y lo crea de nuevo (pierde casa, VIP y gremio; para testers da igual).
  - Solo para el servidor local de pruebas.
#>
param(
	[string]$Origen,
	[string]$Destino,
	[string]$Cuenta,
	[switch]$Reemplazar,
	[switch]$Listar,
	[string]$MySql = 'C:\xampp\mysql\bin\mysql.exe',
	[string]$Base = 'pokedashpota',
	[string]$Usuario = 'root',
	[string]$Clave = '',
	[string]$CuentaPlantillas = 'claudeplantillas'
)

$ErrorActionPreference = 'Stop'

function Invoke-Sql([string]$query) {
	# el SQL va por un archivo (pasarlo como argumento rompe las comillas en PowerShell 5.1)
	$file = [System.IO.Path]::GetTempFileName()
	$errFile = [System.IO.Path]::GetTempFileName()
	try {
		[System.IO.File]::WriteAllText($file, $query, (New-Object System.Text.UTF8Encoding $false))
		$pass = if ($Clave -ne '') { "-p$Clave " } else { '' }
		$output = cmd /c "`"$MySql`" -u $Usuario $pass--default-character-set=utf8mb4 -N -B $Base < `"$file`" 2> `"$errFile`""
		if ($LASTEXITCODE -ne 0) { throw "Error de MySQL: $([System.IO.File]::ReadAllText($errFile))" }
		# la coma evita que PowerShell convierta una lista de un elemento en texto suelto
		return , @($output | Where-Object { $_ -ne $null -and "$_" -ne '' } | ForEach-Object { "$_" })
	} finally {
		Remove-Item $file, $errFile -ErrorAction SilentlyContinue
	}
}

function Format-SqlText([string]$text) {
	return "'" + ($text -replace '\\', '\\\\' -replace "'", "''") + "'"
}

if (-not (Test-Path $MySql)) { throw "No encuentro mysql en $MySql (usa -MySql para indicar la ruta)." }

if ($Listar) {
	Write-Host "Personajes de la cuenta de plantillas ($CuentaPlantillas):"
	$rows = Invoke-Sql "SELECT p.name, p.level, p.posx, p.posy, p.posz FROM players p JOIN accounts a ON a.id = p.account_id WHERE a.name = $(Format-SqlText $CuentaPlantillas) ORDER BY p.name"
	if ($rows.Count -eq 0) { Write-Host '  (ninguno)' }
	foreach ($row in $rows) {
		$f = $row -split "`t"
		Write-Host ("  {0}  nivel {1}  en {2},{3},{4}" -f $f[0], $f[1], $f[2], $f[3], $f[4])
	}
	return
}

if (-not $Origen -or -not $Destino) { throw 'Faltan -Origen y -Destino (o usa -Listar).' }
if ($Origen -eq $Destino) { throw 'El origen y el destino no pueden ser el mismo personaje.' }

# --- origen ---
$src = Invoke-Sql "SELECT id, account_id FROM players WHERE name = $(Format-SqlText $Origen)"
if ($src.Count -eq 0) { throw "No existe el personaje '$Origen'." }
$srcId, $srcAccount = $src[0] -split "`t"
if ((Invoke-Sql "SELECT COUNT(*) FROM players_online WHERE player_id = $srcId")[0] -ne '0') {
	Write-Warning "'$Origen' esta conectado: se copia lo ultimo guardado. Sal del juego o usa /save si quieres lo de ahora."
}

# --- cuenta del destino ---
if ($Cuenta) {
	$acc = Invoke-Sql "SELECT id FROM accounts WHERE name = $(Format-SqlText $Cuenta)"
	if ($acc.Count -eq 0) {
		if ($Cuenta -ne $CuentaPlantillas) { throw "No existe la cuenta '$Cuenta'." }
		# la cuenta de plantillas se crea sola, con una contrasena al azar (no hace falta entrar con ella)
		$password = -join ((48..57) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
		$sha1 = [System.BitConverter]::ToString(
			[System.Security.Cryptography.SHA1]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($password))
		).Replace('-', '').ToLower()
		Invoke-Sql "INSERT INTO accounts (name, password, email, creation) VALUES ($(Format-SqlText $Cuenta), '$sha1', '', UNIX_TIMESTAMP())" | Out-Null
		$acc = Invoke-Sql "SELECT id FROM accounts WHERE name = $(Format-SqlText $Cuenta)"
		Write-Host "Creada la cuenta '$Cuenta' (contrasena: $password)."
	}
	$accountId = $acc[0]
} else {
	$accountId = $srcAccount
}

# --- destino ---
$dst = Invoke-Sql "SELECT id FROM players WHERE name = $(Format-SqlText $Destino)"
if ($dst.Count -gt 0) {
	if (-not $Reemplazar) { throw "Ya existe '$Destino'. Usa -Reemplazar para sobrescribirlo." }
	if ((Invoke-Sql "SELECT COUNT(*) FROM players_online WHERE player_id = $($dst[0])")[0] -ne '0') {
		throw "'$Destino' esta conectado. Sal del juego (o cierra el servidor) y repite."
	}
	if (-not $Cuenta) {
		# al reemplazar se mantiene la cuenta en la que ya estaba el destino
		$accountId = (Invoke-Sql "SELECT account_id FROM players WHERE id = $($dst[0])")[0]
	}
}

$columns = (Invoke-Sql "SELECT GROUP_CONCAT(CONCAT('``', COLUMN_NAME, '``') ORDER BY ORDINAL_POSITION) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = $(Format-SqlText $Base) AND TABLE_NAME = 'players' AND COLUMN_NAME NOT IN ('id', 'name', 'account_id')")[0]
$hasZnote = (Invoke-Sql "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = $(Format-SqlText $Base) AND TABLE_NAME = 'znote_players'")[0] -ne '0'
$name = Format-SqlText $Destino

$sql = @"
START TRANSACTION;
DELETE FROM players WHERE name = $name;
INSERT INTO players (``name``, ``account_id``, $columns) SELECT $name, $accountId, $columns FROM players WHERE id = $srcId;
SET @nuevo = LAST_INSERT_ID();
INSERT INTO player_items (player_id, pid, sid, itemtype, count, attributes) SELECT @nuevo, pid, sid, itemtype, count, attributes FROM player_items WHERE player_id = $srcId;
INSERT INTO player_depotitems (player_id, sid, pid, itemtype, count, attributes) SELECT @nuevo, sid, pid, itemtype, count, attributes FROM player_depotitems WHERE player_id = $srcId;
INSERT INTO player_inboxitems (player_id, sid, pid, itemtype, count, attributes) SELECT @nuevo, sid, pid, itemtype, count, attributes FROM player_inboxitems WHERE player_id = $srcId;
INSERT INTO player_storage (player_id, ``key``, value) SELECT @nuevo, ``key``, value FROM player_storage WHERE player_id = $srcId;
INSERT INTO player_spells (player_id, name) SELECT @nuevo, name FROM player_spells WHERE player_id = $srcId;
$(if ($hasZnote) { "INSERT INTO znote_players (player_id, created, hide_char, comment) VALUES (@nuevo, UNIX_TIMESTAMP(), 1, '');" })
COMMIT;
SELECT @nuevo;
"@

$newId = (Invoke-Sql $sql)[-1]
$summary = (Invoke-Sql "SELECT level, posx, posy, posz, (SELECT COUNT(*) FROM player_items WHERE player_id = $newId), (SELECT COUNT(*) FROM player_storage WHERE player_id = $newId) FROM players WHERE id = $newId")[0] -split "`t"
Write-Host ("Listo: '{0}' -> '{1}' (id {2}). Nivel {3}, en {4},{5},{6}; {7} objetos encima y {8} storages." -f `
	$Origen, $Destino, $newId, $summary[0], $summary[1], $summary[2], $summary[3], $summary[4], $summary[5])
