# Build on Windows with Flutter and Visual Studio's Desktop development with C++.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    if ($env:OS -ne 'Windows_NT') { throw 'Windows paketi Windows bilgisayarda derlenmelidir.' }
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'Bu paket Windows x64 uzerinde 64-bit PowerShell ile derlenmelidir.' }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter PATH icinde bulunamadi.' }

    & flutter config --enable-windows-desktop
    if ($LASTEXITCODE -ne 0) { throw 'Windows masaustu destegi etkinlestirilemedi.' }
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter bagimliliklari hazirlanamadi.' }
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'Windows derlemesi basarisiz. flutter doctor -v ile Visual Studio/C++ kurulumunu kontrol edin.' }

    $release = Join-Path $PSScriptRoot 'build/windows/x64/runner/Release'
    if (-not (Test-Path (Join-Path $release 'FilERP.exe'))) { throw "FilERP.exe bulunamadi: $release" }
    if (-not (Test-Path (Join-Path $release 'flutter_windows.dll'))) { throw 'Flutter runtime DLL bulunamadi.' }
    if (-not (Test-Path (Join-Path $release 'data'))) { throw 'Uygulama veri klasoru bulunamadi.' }

    $versionLine = Get-Content 'pubspec.yaml' | Where-Object { $_ -match '^version:' } | Select-Object -First 1
    $version = (($versionLine -replace '^version:\s*', '').Trim() -split '\+')[0]
    if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'pubspec.yaml uygulama surumu okunamadi.' }
    $output = Join-Path $PSScriptRoot '.artifacts/windows'
    $package = Join-Path $output "FilERP-$version-win-x64"
    New-Item -ItemType Directory -Path $output -Force | Out-Null
    if (Test-Path $package) { Remove-Item $package -Recurse -Force }
    New-Item -ItemType Directory -Path $package | Out-Null
    # Copy the complete bundle: exe, plugins, Flutter runtime and data.
    Copy-Item (Join-Path $release '*') -Destination $package -Recurse -Force
    @'
FilERP Windows

ZIP dosyasini tamamen ayiklayin ve FilERP.exe dosyasini acin.
EXE, DLL dosyalari ve data klasoru birlikte kalmalidir.
Hedef bilgisayarda Microsoft Visual C++ 2015-2022 Redistributable x64 gereklidir:
https://aka.ms/vs/17/release/vc_redist.x64.exe
Windows Server'da Desktop Experience ve acik bir masaustu/RDP oturumu gerekir.
Bu paket Windows servisi olarak calismaz.
Dashboard icin Admin yetkili hesapla yeniden giris yapin.
'@ | Set-Content (Join-Path $package 'BASLAT.txt') -Encoding UTF8
    $zip = "$package.zip"
    Compress-Archive -Path $package -DestinationPath $zip -Force
    Write-Host "Hazir: $zip"
    Write-Host "Tum ZIP dosyasini sunucuya kopyalayip ayiklayin. Sadece EXE dosyasini tasimayin."
} finally {
    Pop-Location
}
