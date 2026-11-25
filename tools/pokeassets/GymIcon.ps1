# Icono "siguiente gimnasio" del mapa (cliente: data/images/map/gym_next.png).
# Circulo dorado con borde oscuro y una estrella blanca, suavizado. Se dibuja a 4x y se reduce.
# Uso: powershell -ExecutionPolicy Bypass -File tools\pokeassets\GymIcon.ps1
param(
	[string]$Out = (Join-Path $PSScriptRoot '..\..\bases\pokedashpota1.0_client\data\images\map\gym_next.png'),
	[int]$Size = 32
)
Add-Type -AssemblyName System.Drawing

$scale = 4
$big = $Size * $scale
$bmp = New-Object System.Drawing.Bitmap $big, $big
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# sombra suave, borde oscuro y relleno con degradado dorado
$pad = 2 * $scale
$shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 0, 0, 0))
$g.FillEllipse($shadow, $pad, $pad + $scale, $big - 2 * $pad, $big - 2 * $pad)
$dark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 27, 30, 36))
$g.FillEllipse($dark, $pad, $pad, $big - 2 * $pad, $big - 2 * $pad)
$inner = $pad + 3 * $scale
$rect = New-Object System.Drawing.RectangleF $inner, $inner, ($big - 2 * $inner), ($big - 2 * $inner)
$gold = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect,
	([System.Drawing.Color]::FromArgb(255, 255, 214, 79)), ([System.Drawing.Color]::FromArgb(255, 239, 140, 0)), 90.0
$g.FillEllipse($gold, $rect)

# estrella de 5 puntas
$cx = $big / 2.0
$cy = $big / 2.0 + 0.3 * $scale
$outerR = ($big - 2 * $inner) * 0.40
$innerR = $outerR * 0.45
$points = New-Object 'System.Drawing.PointF[]' 10
for ($i = 0; $i -lt 10; $i++) {
	$r = if ($i % 2 -eq 0) { $outerR } else { $innerR }
	$angle = -[Math]::PI / 2 + $i * [Math]::PI / 5
	$points[$i] = New-Object System.Drawing.PointF ([float]($cx + $r * [Math]::Cos($angle))), ([float]($cy + $r * [Math]::Sin($angle)))
}
$g.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), $points)
$outline = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(140, 120, 60, 0)), ([float]$scale * 0.8)
$outline.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$g.DrawPolygon($outline, $points)
$g.Dispose()

# reducir a tamano final con buena calidad
$small = New-Object System.Drawing.Bitmap $Size, $Size
$gs = [System.Drawing.Graphics]::FromImage($small)
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gs.DrawImage($bmp, 0, 0, $Size, $Size)
$gs.Dispose()
$small.Save([System.IO.Path]::GetFullPath($Out), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $small.Dispose()
Write-Host "Guardado: $([System.IO.Path]::GetFullPath($Out))"
