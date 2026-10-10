$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path $PSScriptRoot -Parent
$brandDirectory = Join-Path $projectRoot 'assets\brand'
$forest = [System.Drawing.Color]::FromArgb(23, 59, 53)
$ivory = [System.Drawing.Color]::FromArgb(247, 245, 239)

function Draw-Polyline {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Pen]$Pen,
        [float[]]$Coordinates
    )

    if ($Coordinates.Count -lt 4 -or $Coordinates.Count % 2 -ne 0) {
        throw 'A polyline requires at least two x/y coordinate pairs.'
    }

    $points = [System.Collections.Generic.List[System.Drawing.PointF]]::new()
    for ($index = 0; $index -lt $Coordinates.Count; $index += 2) {
        $points.Add([System.Drawing.PointF]::new($Coordinates[$index], $Coordinates[$index + 1]))
    }
    $Graphics.DrawLines($Pen, $points.ToArray())
}

function New-BaytCoIcon {
    param(
        [int]$Size,
        [double]$MarkScale = 0.82
    )

    $bitmap = [System.Drawing.Bitmap]::new(
        $Size,
        $Size,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $pen = [System.Drawing.Pen]::new($ivory, 5)
    $brush = [System.Drawing.SolidBrush]::new($ivory)
    $keyCenterBrush = [System.Drawing.SolidBrush]::new($forest)
    $matrix = $null

    try {
        $graphics.Clear($forest)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

        $coordinateScale = [single]($Size * $MarkScale / 100)
        $offset = [single](($Size - (100 * $coordinateScale)) / 2)
        $matrix = [System.Drawing.Drawing2D.Matrix]::new(
            $coordinateScale, 0, 0, $coordinateScale, $offset, $offset
        )
        $graphics.Transform = $matrix

        # The roof and open lower walls form the home silhouette.
        Draw-Polyline $graphics $pen ([float[]]@(10, 43, 50, 12, 90, 43))
        Draw-Polyline $graphics $pen ([float[]]@(18, 39, 18, 68, 24, 74, 35, 74))
        Draw-Polyline $graphics $pen ([float[]]@(82, 39, 82, 68, 76, 74, 65, 74))

        # The branching tree grows from a key-shaped trunk.
        Draw-Polyline $graphics $pen ([float[]]@(50, 70, 50, 39))
        Draw-Polyline $graphics $pen ([float[]]@(50, 58, 36, 47))
        Draw-Polyline $graphics $pen ([float[]]@(50, 54, 66, 42))
        Draw-Polyline $graphics $pen ([float[]]@(50, 45, 40, 34))
        Draw-Polyline $graphics $pen ([float[]]@(50, 42, 60, 31))
        Draw-Polyline $graphics $pen ([float[]]@(50, 70, 50, 83))
        $graphics.FillEllipse($brush, 42, 75, 16, 16)
        $graphics.FillEllipse($keyCenterBrush, 47, 80, 6, 6)
        Draw-Polyline $graphics $pen ([float[]]@(57, 83, 78, 83, 78, 77, 86, 77, 86, 90, 78, 90, 78, 86, 57, 86))

        return $bitmap
    }
    catch {
        $bitmap.Dispose()
        throw
    }
    finally {
        if ($null -ne $matrix) { $matrix.Dispose() }
        $keyCenterBrush.Dispose()
        $brush.Dispose()
        $pen.Dispose()
        $graphics.Dispose()
    }
}

function Save-BaytCoIcon {
    param(
        [int]$Size,
        [double]$MarkScale,
        [string]$Path
    )

    $bitmap = New-BaytCoIcon -Size $Size -MarkScale $MarkScale
    try {
        $directory = Split-Path $Path -Parent
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $bitmap.Dispose()
    }
}

Save-BaytCoIcon 1024 0.82 (Join-Path $brandDirectory 'bayt_co_icon_1024.png')
Save-BaytCoIcon 256 0.82 (Join-Path $brandDirectory 'bayt_co_icon.png')

$androidSizes = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}
foreach ($density in $androidSizes.Keys) {
    $path = Join-Path $projectRoot "android\app\src\main\res\$density\ic_launcher.png"
    Save-BaytCoIcon $androidSizes[$density] 0.82 $path
}

$iosContentsPath = Join-Path $projectRoot 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Contents.json'
$iosContents = Get-Content -LiteralPath $iosContentsPath -Raw | ConvertFrom-Json
foreach ($image in $iosContents.images) {
    if (-not $image.filename) { continue }
    $pointSize = [double](($image.size -split 'x')[0])
    $scale = [double]($image.scale -replace 'x', '')
    $pixelSize = [int][Math]::Round($pointSize * $scale)
    $path = Join-Path (Split-Path $iosContentsPath -Parent) $image.filename
    Save-BaytCoIcon $pixelSize 0.82 $path
}

$webDirectory = Join-Path $projectRoot 'web'
Save-BaytCoIcon 32 0.82 (Join-Path $webDirectory 'favicon.png')
Save-BaytCoIcon 192 0.82 (Join-Path $webDirectory 'icons\Icon-192.png')
Save-BaytCoIcon 512 0.82 (Join-Path $webDirectory 'icons\Icon-512.png')
Save-BaytCoIcon 192 0.68 (Join-Path $webDirectory 'icons\Icon-maskable-192.png')
Save-BaytCoIcon 512 0.68 (Join-Path $webDirectory 'icons\Icon-maskable-512.png')

Write-Output 'Generated Bayt Co launcher icons for Android, iOS, web, and the in-app brand mark.'
