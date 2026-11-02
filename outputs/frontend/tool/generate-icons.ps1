# Rasterize the existing BrandSpark geometry; no external artwork or packages.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
function Write-BrandIcon([string]$RelativePath, [int]$Size) {
    $destination = Join-Path $root $RelativePath
    New-Item -ItemType Directory -Force (Split-Path $destination -Parent) | Out-Null
    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#167C73'))
    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#E4F4EE'))
        # 56% footprint remains within the maskable/adaptive safe area.
        $graphics.TranslateTransform(($Size * .22), ($Size * .22))
        $graphics.ScaleTransform(($Size * .00056), ($Size * .00056))
        $path.AddBezier(500,0,600,300,700,400,1000,500)
        $path.AddBezier(1000,500,700,600,600,700,500,1000)
        $path.AddBezier(500,1000,400,700,300,600,0,500)
        $path.AddBezier(0,500,300,400,400,300,500,0)
        $path.CloseFigure()
        $graphics.FillPath($brush,$path)
        $bitmap.Save($destination,[System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $brush.Dispose(); $path.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
    }
}
foreach ($entry in @{mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192}.GetEnumerator()) {
    Write-BrandIcon "android/app/src/main/res/mipmap-$($entry.Key)/ic_launcher.png" $entry.Value
}
$catalog = Get-Content (Join-Path $root 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
foreach ($entry in $catalog.images) {
    $pixels = [int]([double]($entry.size.Split('x')[0]) * [double]($entry.scale.TrimEnd('x')))
    Write-BrandIcon "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.filename)" $pixels
}
foreach ($size in @(192,512)) {
    Write-BrandIcon "web/icons/Icon-$size.png" $size
    Write-BrandIcon "web/icons/Icon-maskable-$size.png" $size
}
Write-BrandIcon 'web/favicon.png' 32
Write-BrandIcon 'design-review/launcher-icon.png' 512
Write-Output 'Generated Android, iOS and web icons from BrandSpark.'
