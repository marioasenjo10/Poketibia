# Icono "Mercado" del menu de arriba (cliente: data/images/topmenu/market.png).
# Bolsa de la compra azul con asa y una moneda dorada, suavizada (se dibuja a 4x y se reduce).
# Uso: powershell -ExecutionPolicy Bypass -File tools\pokeassets\MarketIcon.ps1
param(
	[string]$Out = (Join-Path $PSScriptRoot '..\..\bases\pokedashpota1.0_client\data\images\topmenu\market.png'),
	[int]$Size = 32
)
Add-Type -AssemblyName System.Drawing

$s = 4
$big = $Size * $s
$bmp = New-Object System.Drawing.Bitmap $big, $big
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

function RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$path.AddArc($x, $y, 2 * $r, 2 * $r, 180, 90)
	$path.AddArc($x + $w - 2 * $r, $y, 2 * $r, 2 * $r, 270, 90)
	$path.AddArc($x + $w - 2 * $r, $y + $h - 2 * $r, 2 * $r, 2 * $r, 0, 90)
	$path.AddArc($x, $y + $h - 2 * $r, 2 * $r, 2 * $r, 90, 90)
	$path.CloseFigure()
	return $path
}

$dark = [System.Drawing.Color]::FromArgb(255, 20, 40, 70)
# asa
$handle = New-Object System.Drawing.Pen $dark, ([float](3.2 * $s))
$g.DrawArc($handle, 10 * $s, 3 * $s, 12 * $s, 13 * $s, 180, 180)
$handleIn = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 144, 202, 249)), ([float](1.6 * $s))
$g.DrawArc($handleIn, 10 * $s, 3 * $s, 12 * $s, 13 * $s, 180, 180)
# bolsa
$bag = RoundRect (4 * $s) (10 * $s) (24 * $s) (19 * $s) (3.5 * $s)
$g.FillPath((New-Object System.Drawing.SolidBrush $dark), $bag)
$inner = RoundRect (5.5 * $s) (11.5 * $s) (21 * $s) (16 * $s) (2.5 * $s)
$rect = New-Object System.Drawing.RectangleF (5.5 * $s), (11.5 * $s), (21 * $s), (16 * $s)
$blue = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect,
	([System.Drawing.Color]::FromArgb(255, 66, 165, 245)), ([System.Drawing.Color]::FromArgb(255, 21, 101, 192)), 90.0
$g.FillPath($blue, $inner)
# moneda
$coinRect = New-Object System.Drawing.RectangleF (11 * $s), (14 * $s), (10 * $s), (10 * $s)
$g.FillEllipse((New-Object System.Drawing.SolidBrush $dark), (10.3 * $s), (13.3 * $s), (11.4 * $s), (11.4 * $s))
$gold = New-Object System.Drawing.Drawing2D.LinearGradientBrush $coinRect,
	([System.Drawing.Color]::FromArgb(255, 255, 214, 79)), ([System.Drawing.Color]::FromArgb(255, 239, 140, 0)), 90.0
$g.FillEllipse($gold, $coinRect)
$font = New-Object System.Drawing.Font 'Arial', ([float](7.5 * $s)), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center
$g.DrawString('$', $font, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 120, 70, 0))),
	(New-Object System.Drawing.RectangleF (11 * $s), (14.4 * $s), (10 * $s), (10 * $s)), $format)
$g.Dispose()

$small = New-Object System.Drawing.Bitmap $Size, $Size
$gs = [System.Drawing.Graphics]::FromImage($small)
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gs.DrawImage($bmp, 0, 0, $Size, $Size)
$gs.Dispose()
$small.Save([System.IO.Path]::GetFullPath($Out), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $small.Dispose()
Write-Host "Guardado: $([System.IO.Path]::GetFullPath($Out))"
