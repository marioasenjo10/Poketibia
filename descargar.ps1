# Descarga los sprites (Tibia.spr, que no va en git por su tamano) desde una Release de GitHub y los
# coloca en su sitio. Ejecutalo despues de hacer git clone, desde la raiz del proyecto:
#
#   powershell -ExecutionPolicy Bypass -File .\descargar.ps1
#
# Si cambian los sprites: sube el Tibia.spr nuevo a una Release nueva, cambia $Tag y pon en $Sha256
# el resultado de:  (Get-FileHash .\bases\pokedashpota1.0_client\data\things\1098\Tibia.spr).Hash

$Repo   = "marioasenjo10/Poketibia"
$Tag    = "datos-v1"
$Nombre = "Tibia.spr"
$Sha256 = "23FEB4497B7692866FF0B11DED63B58FD80E8DF0DB3327FAEBBA11B31DF8AC03"

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # con la barra, PowerShell 5.1 descarga muchisimo mas lento
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$carpeta = Join-Path $PSScriptRoot "bases\pokedashpota1.0_client\data\things\1098"
$ruta = Join-Path $carpeta $Nombre
$temporal = "$ruta.descargando"

if (Test-Path $ruta) {
    if ((Get-FileHash $ruta -Algorithm SHA256).Hash -eq $Sha256) {
        Write-Host "Ya tienes los sprites de la release $Tag." -ForegroundColor Green
    } else {
        Write-Host "Ya existe $Nombre pero no es el de la release $Tag, y no se toca." -ForegroundColor Yellow
        Write-Host "Si quieres el de la release, renombra el tuyo y vuelve a ejecutar este script."
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
$url = "https://github.com/$Repo/releases/download/$Tag/$Nombre"
Write-Host "Descargando $Nombre (unos 465 MB, puede tardar) ..."
try {
    Invoke-WebRequest -Uri $url -OutFile $temporal -UseBasicParsing
} catch {
    Remove-Item $temporal -ErrorAction SilentlyContinue
    Write-Host "No se pudo descargar: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Comprueba que existe la release '$Tag' con el archivo $Nombre en https://github.com/$Repo/releases"
    exit 1
}

if ((Get-FileHash $temporal -Algorithm SHA256).Hash -ne $Sha256) {
    Remove-Item $temporal
    Write-Host "El archivo descargado esta incompleto o no es el esperado. Vuelve a intentarlo." -ForegroundColor Red
    exit 1
}
Move-Item $temporal $ruta

Write-Host "Listo. Ahora importa schema.sql en MySQL y arranca el servidor (mira SETUP.md)." -ForegroundColor Green
