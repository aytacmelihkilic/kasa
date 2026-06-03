# Tablete dogrudan kurulum (USB + hata ayiklama acikken)
$flutterBin = "$env:USERPROFILE\flutter\bin"
$env:PATH = "$flutterBin;$env:PATH"

$jdk17 = Get-ChildItem "C:\Program Files\Microsoft\jdk-*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
if ($jdk17) {
    $env:JAVA_HOME = $jdk17.FullName
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
}

Write-Host "Bagli cihazlar:" -ForegroundColor Cyan
flutter devices

$android = flutter devices 2>&1 | Select-String "android"
if (-not $android) {
    Write-Host "`nAndroid tablet gorunmuyor." -ForegroundColor Yellow
    Write-Host "- USB hata ayiklamayi acin (Ayarlar > Gelistirici secenekleri)"
    Write-Host "- Bilgisayarda 'adb devices' ile kontrol edin"
    Write-Host "- Alternatif: seramik-katalogu-release.apk dosyasini tablete kopyalayin"
    exit 1
}

Set-Location (Split-Path $PSScriptRoot -Parent)
flutter install --release
Write-Host "Kurulum tamamlandi." -ForegroundColor Green
