# =============================================================================
#  REGLE D'OR ABI - garde-fou de deploiement
#
#  Un APK de release doit TOUJOURS rester universel :
#    armeabi-v7a (TV 32 bits, ex. TCL BeyondTV), arm64-v8a, x86_64.
#
#  Ce script :
#    1. detecte l'appareil (USB, ou ADB over IP via -Ip),
#    2. lit l'ABI REELLE de l'appareil (ro.product.cpu.abilist),
#    3. lit les ABIs presentes dans l'APK (tool/abi_guard.dart),
#    4. echoue si l'APK n'est pas universel ou si aucune ABI n'est commune,
#    5. installe avec `adb install -r` et verifie le paquet installe.
#
#  Exemples :
#    .\tool\deploy_tv.ps1 -Ip 192.168.1.128
#    .\tool\deploy_tv.ps1 -Serial R5CN21FYWWT
#    .\tool\deploy_tv.ps1 -Ip 192.168.1.128 -Build
# =============================================================================
[CmdletBinding()]
param(
    [string]$Ip,
    [string]$Serial,
    [string]$Apk = 'build\app\outputs\flutter-apk\app-release.apk',
    [switch]$Build,
    [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Find-Adb {
    $candidates = @()
    foreach ($base in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)) {
        if ($base) { $candidates += (Join-Path $base 'platform-tools\adb.exe') }
    }
    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe')
    }
    $candidates = $candidates | Where-Object { Test-Path $_ }
    if ($candidates) { return @($candidates)[0] }
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "adb introuvable. Installer platform-tools ou definir ANDROID_HOME."
}

function Find-Flutter {
    if (Test-Path (Join-Path $root '.fvmrc')) {
        $version = (Get-Content (Join-Path $root '.fvmrc') -Raw | ConvertFrom-Json).flutter
        foreach ($base in @((Join-Path $env:USERPROFILE 'fvm\versions'),
                             (Join-Path $root '.fvm\versions'))) {
            $bat = Join-Path $base "$version\bin\flutter.bat"
            if (Test-Path $bat) { return $bat }
        }
    }
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "flutter introuvable (installer FVM ou ajouter Flutter au PATH)."
}

function Find-Dart([string]$FlutterPath) {
    if ($FlutterPath) {
        # Priorite au Dart du meme SDK que le Flutter du .fvmrc, sinon on
        # risquerait d'utiliser un autre SDK present dans le PATH.
        $binDir = Split-Path -Parent $FlutterPath
        foreach ($candidate in @(
            (Join-Path $binDir 'cache\dart-sdk\bin\dart.exe'),
            (Join-Path $binDir 'dart.exe'),
            (Join-Path $binDir 'dart.bat'))) {
            if (Test-Path $candidate) { return $candidate }
        }
    }
    $cmd = Get-Command dart -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "dart introuvable : il est necessaire pour tool/abi_guard.dart."
}

$adb = Find-Adb

if ($Build) {
    $flutter = Find-Flutter
    Write-Host "[build] $flutter build apk --release" -ForegroundColor Cyan
    & $flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw "Build APK echoue (exit $LASTEXITCODE)." }
}

# --- 1. Selection de l'appareil -------------------------------------------
if ($Ip) {
    $target = if ($Ip -match ':') { $Ip } else { "${Ip}:5555" }
    Write-Host "[adb] connect $target" -ForegroundColor Cyan
    & $adb connect $target | Out-Host
    $deviceSerial = $target
} elseif ($Serial) {
    $deviceSerial = $Serial
} else {
    $online = @(
        & $adb devices |
            Select-Object -Skip 1 |
            Where-Object { $_ -match '\s+device\s*$' } |
            ForEach-Object { ($_ -split '\s+')[0] }
    )
    if ($online.Count -eq 0) {
        throw "Aucun appareil ADB. Brancher en USB ou passer -Ip <ip-tv> (debogage reseau)."
    }
    if ($online.Count -gt 1) {
        throw "Plusieurs appareils connectes ($($online -join ', ')). Preciser -Serial ou -Ip."
    }
    $deviceSerial = $online[0]
}

$model = (& $adb -s $deviceSerial shell getprop ro.product.model).Trim()
$sdk   = (& $adb -s $deviceSerial shell getprop ro.build.version.sdk).Trim()
$kind  = (& $adb -s $deviceSerial shell getprop ro.build.characteristics).Trim()

# abilist = ordre de preference Android ; certains firmwares ne l'exposent pas.
$abilist = (& $adb -s $deviceSerial shell getprop ro.product.cpu.abilist).Trim()
if (-not $abilist) {
    $abilist = (& $adb -s $deviceSerial shell getprop ro.product.cpu.abi).Trim()
}
if (-not $abilist) {
    throw "Impossible de lire l'ABI de $deviceSerial (getprop vide)."
}

# --- 2. Lecture de l'APK + decision ABI -----------------------------------
if (-not (Test-Path $Apk)) {
    throw "APK introuvable : $Apk. Lancer avec -Build ou 'flutter build apk --release'."
}
$apkPath = (Resolve-Path $Apk).Path
$dart = Find-Dart (Find-Flutter)

Write-Host "[abi] analyse de l'APK et de l'appareil..." -ForegroundColor Cyan
$guardOutput = @(& $dart 'tool/abi_guard.dart' resolve --device $abilist --apk $apkPath 2>&1 |
    ForEach-Object { "$_" })
$guardExit = $LASTEXITCODE
$guardOutput | ForEach-Object { Write-Host "       $_" }

if ($guardExit -ne 0) {
    $message = ($guardOutput | Where-Object { $_ -like 'error=*' }) -replace '^error=', ''
    throw "GARDE-FOU ABI : $message"
}

$selected = ($guardOutput | Where-Object { $_ -like 'selected=*' }) -replace '^selected=', ''
$apkAbis  = ($guardOutput | Where-Object { $_ -like 'apk-abis=*' }) -replace '^apk-abis=', ''

# --- 3. Installation -------------------------------------------------------
Write-Host ""
Write-Host "  Appareil : $model ($deviceSerial)" -ForegroundColor Green
Write-Host "  Android  : API $sdk ($kind)"
Write-Host "  ABIs app.: $abilist"
Write-Host "  ABIs APK : $apkAbis"
Write-Host "  ABI      : $selected  <- choisie par le garde-fou" -ForegroundColor Green
Write-Host ""

$install = @(& $adb -s $deviceSerial install -r $apkPath 2>&1 | ForEach-Object { "$_" })
$install | ForEach-Object { Write-Host "       $_" }
if ($LASTEXITCODE -ne 0 -or ($install -join "`n") -notmatch 'Success') {
    throw "Installation echouee sur $deviceSerial."
}

# --- 4. Verification post-installation ------------------------------------
$appIdLine = Select-String -Path 'android/app/build.gradle' -Pattern 'applicationId\s*=\s*"([^"]+)"' |
    Select-Object -First 1
if (-not $appIdLine) { throw "applicationId introuvable dans android/app/build.gradle." }
$appId = $appIdLine.Matches[0].Groups[1].Value

$installed = & $adb -s $deviceSerial shell dumpsys package $appId |
    Select-String -Pattern 'versionName=' | Select-Object -First 1
if ($installed) {
    Write-Host "[ok] $appId installe sur $deviceSerial ($($installed.Line.Trim()))" -ForegroundColor Green
} else {
    throw "Le paquet $appId n'apparait pas dans dumpsys apres installation."
}

if (-not $NoLaunch) {
    & $adb -s $deviceSerial shell monkey -p $appId -c android.intent.category.LAUNCHER 1 | Out-Null
    $appPid = (& $adb -s $deviceSerial shell pidof $appId).Trim()
    if ($appPid) {
        Write-Host "[ok] $appId lance (pid $appPid)" -ForegroundColor Green
    } else {
        Write-Warning "Lancement demande mais pid introuvable : verifier logcat."
    }
}

exit 0
