# Orbes de evolucion shiny: genera los 7 PNG de los orbes y un holograma por cada shiny destino.
#   powershell -ExecutionPolicy Bypass -File tools\pokeassets\ShinyOrbs.ps1            # PNG de orbes + hologramas
#   powershell -ExecutionPolicy Bypass -File tools\pokeassets\ShinyOrbs.ps1 -Apply     # ademas pone los orbes en Tibia.spr/.dat
# Orbes -> ids 46001..46007 (mythic, legendary, ultra, super, t1, t2, bronze), igual que SHINY_ORB_IDS en
# bases/pokedashpota1.0/data/lib/core/shinyevolution.lua. Hologramas -> modules/game_containers/holograms/<nombre>.png
param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$t = $PSScriptRoot
Add-Type -Path "$t\PixelArt.cs","$t\OrbDesign.cs","$t\Otb.cs","$t\Things.cs","$t\SpriteSwap.cs" -ReferencedAssemblies System.Drawing
$client = "$root\bases\pokedashpota1.0_client"
$orbDir = "$t\orbs"
New-Item -ItemType Directory -Force $orbDir | Out-Null

$ids = @(); $pngs = @(); $id = 46001
foreach ($key in [OrbDesign]::Keys) {
	$png = "$orbDir\orb_$key.png"
	[OrbDesign]::Orb($key).Save($png, 1)
	$ids += $id; $pngs += $png; $id++
}
Write-Host "Orbes: $($pngs.Count) en $orbDir"

$holoDir = "$client\modules\game_containers\holograms"
New-Item -ItemType Directory -Force $holoDir | Out-Null
# cada holograma del color de su orbe (bronce, plata, oro...), no en cian
$lines = & python -I "$root\tools\shinyorbs.py" --keys
$n = 0
foreach ($line in $lines) {
	$name, $key = $line.Split('|')
	$src = "$client\modules\game_pokedex\artwork\$($name.ToLower()).png"
	if (Test-Path $src) {
		[OrbDesign]::HologramTinted($src, "$holoDir\$($name.ToLower()).png", 48, $key)
		$n++
	}
}
Write-Host "Hologramas: $n en $holoDir"

if ($Apply) {
	$dat = "$client\data\things\1098\Tibia.dat"; $spr = "$client\data\things\1098\Tibia.spr"
	$otb = "$root\bases\pokedashpota1.0\data\items\items.otb"
	Write-Host ([SpriteSwap]::RunMany($dat, $spr, $otb, [int[]]$ids, [string[]]$pngs, $false))
}
