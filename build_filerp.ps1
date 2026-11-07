$appName = "FilERP"

# pubspec.yaml'dan versiyon oku (ornek: 1.0.046+46)
$versionLine = Get-Content pubspec.yaml | Where-Object { $_ -match "^version:" }
$fullVersion = ($versionLine -replace "version:\s*", "").Trim()

# versionName (1.0.046) ve versionCode (46) ayir
$parts       = $fullVersion -split "\+"
$versionName = $parts[0]
$versionCode = if ($parts.Length -gt 1) { [int]$parts[1] } else { 0 }

Write-Host ""
Write-Host "Build basliyor: $appName $versionName (code: $versionCode)"
Write-Host ""

flutter clean
flutter build apk --release

$sourceApk = "build/app/outputs/flutter-apk/app-release.apk"
$targetApk = "build/app/outputs/flutter-apk/${appName}_v${versionName}.apk"

Move-Item $sourceApk $targetApk -Force

Write-Host ""
Write-Host "APK olusturuldu: $targetApk"

# version.json guncelle
$downloadUrl  = "https://filerp.com/apk/${appName}_v${versionName}.zip"
$releaseNotes = Read-Host "Release notu girin (bos birakabilirsiniz)"

$versionJson = @{
    versionCode  = $versionCode
    versionName  = $versionName
    downloadUrl  = $downloadUrl
    releaseNotes = $releaseNotes
} | ConvertTo-Json -Depth 2

$versionJson | Set-Content "version.json" -Encoding UTF8

Write-Host ""
Write-Host "version.json guncellendi:"
Write-Host $versionJson
Write-Host ""
Write-Host "Sunucuya guncellemeyi unutma:"
Write-Host "  APK  -> filerp.com/apk/download/${appName}_v${versionName}.apk"
Write-Host "  JSON -> filerp.com/apk/version.json"
Write-Host ""
