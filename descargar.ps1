# Descarga el mapa y los sprites (que no van en git por su tamano) desde una Release de GitHub
# y los coloca en su sitio. Ejecutalo UNA vez despues de hacer git clone, desde la raiz del proyecto:
#
#   powershell -ExecutionPolicy Bypass -File .\descargar.ps1
#
# Cambia $Repo y $Tag por los de vuestro repositorio y la release donde subais los archivos.
# Si el repositorio es privado hace falta GitHub CLI (https://cli.github.com) y haber hecho "gh auth login".

$Repo = "USUARIO/REPOSITORIO"   # <-- poned aqui "usuario/repo" de GitHub
$Tag  = "datos-v1"              # <-- nombre de la release donde estan los archivos

$Raiz = $PSScriptRoot
$Archivos = @(
    @{ Nombre = "global_dash.otbm"; Destino = "bases\pokedashpota1.0\data\world" },
    @{ Nombre = "Tibia.spr";        Destino = "bases\pokedashpota1.0_client\data\things\1098" }
)

if ($Repo -like "USUARIO/*") {
    Write-Host "Edita descargar.ps1 y pon el repositorio en `$Repo antes de ejecutarlo." -ForegroundColor Yellow
    exit 1
}

$tieneGh = [bool](Get-Command gh -ErrorAction SilentlyContinue)

foreach ($a in $Archivos) {
    $carpeta = Join-Path $Raiz $a.Destino
    $ruta = Join-Path $carpeta $a.Nombre
    if (Test-Path $ruta) {
        Write-Host "Ya existe $($a.Nombre), se salta."
        continue
    }
    New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
    Write-Host "Descargando $($a.Nombre) ..."
    if ($tieneGh) {
        gh release download $Tag -R $Repo -p $a.Nombre -D $carpeta
    } else {
        $url = "https://github.com/$Repo/releases/download/$Tag/$($a.Nombre)"
        Invoke-WebRequest -Uri $url -OutFile $ruta
    }
    if (-not (Test-Path $ruta)) {
        Write-Host "No se pudo descargar $($a.Nombre). Si el repo es privado, instala GitHub CLI y haz 'gh auth login'." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Listo. Ahora importa schema.sql en MySQL y arranca el servidor (mira SETUP.md)." -ForegroundColor Green
