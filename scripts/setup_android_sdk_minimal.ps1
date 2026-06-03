# Android Studio OLMADAN minimal SDK kurulumu (~1-2 GB, IDE yok)
# Kullanim: .\scripts\setup_android_sdk_minimal.ps1
# Sonra: .\scripts\build_apk.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Minimal Android SDK (Studio yok) ===" -ForegroundColor Cyan

# Java 17
$jdk17 = Get-ChildItem "C:\Program Files\Microsoft\jdk-*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
if (-not $jdk17) {
    Write-Host "JDK 17 yok. Kuruluyor..." -ForegroundColor Yellow
    winget install Microsoft.OpenJDK.17 --accept-package-agreements --accept-source-agreements
    $jdk17 = Get-ChildItem "C:\Program Files\Microsoft\jdk-*" | Sort-Object Name -Descending | Select-Object -First 1
}
$env:JAVA_HOME = $jdk17.FullName
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
Write-Host "Java: $env:JAVA_HOME"

$sdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
$latestDir = "$sdkRoot\cmdline-tools\latest"
$sdkmanager = "$latestDir\bin\sdkmanager.bat"

# cmdline-tools yoksa indir (~150 MB)
if (-not (Test-Path $sdkmanager)) {
    Write-Host "cmdline-tools indiriliyor..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null
    $zipUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    $zipPath = "$env:USERPROFILE\Downloads\android-cmdline-tools.zip"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    $extractTemp = "$env:TEMP\android-cmd-extract"
    if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force
    New-Item -ItemType Directory -Force -Path "$sdkRoot\cmdline-tools" | Out-Null
    if (Test-Path $latestDir) { Remove-Item $latestDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $latestDir | Out-Null
    Copy-Item "$extractTemp\cmdline-tools\*" $latestDir -Recurse -Force
    Write-Host "cmdline-tools kuruldu."
}

# Lisanslari dosya ile kabul et (etkilesim gerektirmez)
$licDir = "$sdkRoot\licenses"
New-Item -ItemType Directory -Force -Path $licDir | Out-Null
Set-Content "$licDir\android-sdk-license" "8933bad161af4178b11849ca0d783fa"
Set-Content "$licDir\android-sdk-preview-license" "84831b94096429a485f425b122416880a71617352"
Set-Content "$licDir\android-googletv-license" "601085b94cd77f0b54ff2648725edf424075cd9"
Set-Content "$licDir\android-sdk-arm-dbt-license" "859f31769664ba48024dfd9a202a82784e291145"
Set-Content "$licDir\google-gdk-license" "33b6a2b64607f11b759f320ebbad8a228e07f971"
Set-Content "$licDir\intel-android-extra-license" "d975f5926986f2deef830b1744704e245f7bc2b"
Write-Host "Lisanslar hazir."

# Sadece APK icin gerekli paketler (~800 MB - 1.5 GB)
Write-Host "SDK paketleri indiriliyor (internet gerekir, 5-15 dk)..." -ForegroundColor Yellow
$packages = @(
    "platform-tools",
    "platforms;android-35",
    "build-tools;35.0.0"
)

$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot

& $sdkmanager --sdk_root=$sdkRoot $packages
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nIndirme basarisiz. VPN/firewall kapatin veya tekrar deneyin." -ForegroundColor Red
    Write-Host "Manuel: $sdkmanager --sdk_root=$sdkRoot platform-tools platforms;android-35 build-tools;35.0.0"
    exit 1
}

# Flutter'a SDK yolunu bildir
$flutterBin = "$env:USERPROFILE\flutter\bin"
if (Test-Path "$flutterBin\flutter.bat") {
    $env:PATH = "$flutterBin;$env:PATH"
    flutter config --android-sdk $sdkRoot | Out-Null
    flutter doctor --android-licenses 2>&1 | Out-Null
}

Write-Host "`nTAMAM! SDK: $sdkRoot" -ForegroundColor Green
Write-Host "Disk kullanimi (yaklasik):"
Get-ChildItem $sdkRoot -Recurse -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum |
    ForEach-Object { "  $('{0:N1}' -f ($_.Sum / 1GB)) GB" }

Write-Host "`nSimdi APK icin: .\scripts\build_apk.ps1" -ForegroundColor Cyan
