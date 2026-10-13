param([string]$GamePath = 'D:\SteamLibrary\steamapps\common\Call of Duty - Infinite Warfare', [switch]$Update)
$ErrorActionPreference = 'Stop'
$resolvedGame = (Resolve-Path -LiteralPath $GamePath).Path
if (!(Test-Path -LiteralPath (Join-Path $resolvedGame 'iw7-mod.exe'))) { throw 'iw7-mod.exe is missing from the game directory.' }
if (Get-Process -Name 'iw7-mod','iw7_ship' -ErrorAction SilentlyContinue) { throw 'Close Infinite Warfare before installing.' }
$files = @('custom_scripts\cp\beast_runner.gsc', 'ui_scripts\BeastRunner\__init__.lua', 'ui_scripts\BeastRunner\core.lua')
$modRoot = Join-Path $resolvedGame 'iw7-mod'
$changedFiles = @()
foreach ($relative in $files) {
    $target = Join-Path $modRoot $relative
    $source = Join-Path (Join-Path $PSScriptRoot 'iw7-mod') $relative
    if (Test-Path -LiteralPath $target) {
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
            if (!$Update) { throw "A different version exists: $target. Use -Update to back up and replace the toolkit scripts." }
            $changedFiles += $relative
        }
    }
}
if ($changedFiles.Count) {
    $backupRoot = Join-Path $PSScriptRoot (Join-Path '.development\install-backups' ([Guid]::NewGuid().ToString()))
    foreach ($relative in $changedFiles) {
        $backupFile = Join-Path $backupRoot $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $backupFile) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $modRoot $relative) -Destination $backupFile
    }
    Write-Output "Previous toolkit scripts backed up to: $backupRoot"
}
foreach ($relative in $files) {
    $target = Join-Path $modRoot $relative
    $source = Join-Path (Join-Path $PSScriptRoot 'iw7-mod') $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force
    if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw "Installation verification failed: $target" }
}
Write-Output 'Installed and verified 3 script files. Launch iw7-mod.exe, then start The Beast from Beyond.'
Write-Output 'Open the pause menu > SPEEDRUN STATS. Console fallback: luiOpenMenu BeastRunnerStats'
