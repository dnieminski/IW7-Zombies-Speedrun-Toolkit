param([string]$GamePath = 'D:\SteamLibrary\steamapps\common\Call of Duty - Infinite Warfare')
$ErrorActionPreference = 'Stop'
if (Get-Process -Name 'iw7-mod','iw7_ship' -ErrorAction SilentlyContinue) { throw 'Close Infinite Warfare before uninstalling.' }
$modRoot = Join-Path (Resolve-Path -LiteralPath $GamePath).Path 'iw7-mod'
$files = @('custom_scripts\cp\beast_runner.gsc', 'ui_scripts\BeastRunner\__init__.lua', 'ui_scripts\BeastRunner\core.lua', 'ui_scripts\BeastRunner\maps.lua')
foreach ($relative in $files) {
    $target = Join-Path $modRoot $relative
    $source = Join-Path (Join-Path $PSScriptRoot 'iw7-mod') $relative
    if (Test-Path -LiteralPath $target) {
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw "Modified script found; refusing to remove it: $target" }
    }
}
foreach ($relative in $files) {
    $target = Join-Path $modRoot $relative
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target }
}
Write-Output 'Removed only the 4 toolkit scripts. Recorded history remains in the game log.'
