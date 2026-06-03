# Seramik Katalogu — Android APK derleme betiği
# Kullanım: PowerShell'de proje klasöründen:
#   .\scripts\build_apk.ps1

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $ProjectRoot

# Flutter PATH
$flutterBin = "$env:USERPROFILE\flutter\bin"
if (-not (Test-Path "$flutterBin\flutter.bat")) {
    Write-Host "HATA: Flutter bulunamadi. Once Flutter kurun." -ForegroundColor Red
    exit 1
}
$env:PATH = "$flutterBin;$env:PATH"

# Java 17 (Android Gradle icin gerekli)
$jdk17 = Get-ChildItem "C:\Program Files\Microsoft\jdk-*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
if ($jdk17) {
    $env:JAVA_HOME = $jdk17.FullName
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
    Write-Host "Java: $env:JAVA_HOME"
} else {
    Write-Host "UYARI: JDK 17 bulunamadi. winget install Microsoft.OpenJDK.17" -ForegroundColor Yellow
}

# Android SDK
$sdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
if (Test-Path $sdkRoot) {
    $env:ANDROID_HOME = $sdkRoot
    $env:ANDROID_SDK_ROOT = $sdkRoot
    & flutter config --android-sdk $sdkRoot 2>&1 | Out-Null
    Write-Host "Android SDK: $sdkRoot"
} else {
    Write-Host "HATA: Android SDK yok." -ForegroundColor Red
    Write-Host "  Android Studio GEREKMEZ. Once calistirin:" -ForegroundColor Yellow
    Write-Host "  .\scripts\setup_android_sdk_minimal.ps1"
    exit 1
}

# platform-tools yoksa minimal kurulum gerekli
if (-not (Test-Path "$sdkRoot\platform-tools\adb.exe")) {
    Write-Host "HATA: SDK paketleri eksik." -ForegroundColor Red
    Write-Host "  .\scripts\setup_android_sdk_minimal.ps1" -ForegroundColor Yellow
    exit 1
}

# local.properties guncelle
$sdkEscaped = $sdkRoot -replace '\\', '\\'
$flutterEscaped = "$env:USERPROFILE\flutter" -replace '\\', '\\'
@"
sdk.dir=$sdkEscaped
flutter.sdk=$flutterEscaped
"@ | Set-Content -Path "$ProjectRoot\android\local.properties" -Encoding UTF8

Write-Host "`n--- flutter doctor (Android) ---" -ForegroundColor Cyan
# Flutter uyarilari stderr'e yazar; Stop modunda betik erken kesilmesin.
$prevErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Continue"
flutter doctor --android-licenses 2>&1 | Out-Null
flutter doctor 2>&1 | Select-String "Android"
$ErrorActionPreference = $prevErrorAction

Write-Host "`n--- APK derleniyor (release) ---" -ForegroundColor Cyan
flutter pub get 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter build apk --release 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apkSource = "$ProjectRoot\build\app\outputs\flutter-apk\app-release.apk"
$apkDest = "$ProjectRoot\seramik-katalogu-release.apk"

if (Test-Path $apkSource) {
    Copy-Item $apkSource $apkDest -Force
    Write-Host "`nBASARILI!" -ForegroundColor Green
    Write-Host "APK: $apkDest"
    Write-Host "`nTablete kurulum:" -ForegroundColor Cyan
    Write-Host "  1. Tableti USB ile baglayin"
    Write-Host "  2. USB hata ayiklama acik olsun"
    Write-Host "  3. APK dosyasini tablete kopyalayip acin VEYA:"
    Write-Host "     flutter install   (tablet bagliyken)"
} else {
    Write-Host "APK olusturulamadi. flutter doctor ciktisini kontrol edin." -ForegroundColor Red
    exit 1
}
