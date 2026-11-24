# Creates a new game repo from Beam's template, pinned to this version of Beam.
# Usage: .\tools\new-game.ps1 -Name my-game -Destination ..\my-game

param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Destination
)

$ErrorActionPreference = 'Stop'

if ($Name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    throw "Name must be a lowercase slug, e.g. my-game"
}
if (Test-Path $Destination) {
    throw "Destination already exists: $Destination"
}

$beam = Split-Path -Parent $PSScriptRoot
$cfg = Get-Content (Join-Path $beam 'addons\beam\plugin.cfg')
$versionLine = $cfg | Where-Object { $_ -match '^version="(.+)"' } | Select-Object -First 1
if (-not $versionLine) {
    throw "Cannot read Beam's version from addons/beam/plugin.cfg"
}
$null = $versionLine -match '^version="(.+)"'
$beamVersion = "v$($Matches[1])"

Copy-Item -Recurse (Join-Path $beam 'template') $Destination

$files = @(
    'project.godot',
    'export_presets.cfg',
    'addons.json',
    '.github\workflows\release.yml',
    'docs\spec.md',
    'README.md'
)
foreach ($file in $files) {
    $path = Join-Path $Destination $file
    $text = [System.IO.File]::ReadAllText($path)
    $text = $text.Replace('__GAME_NAME__', $Name).Replace('__BEAM_VERSION__', $beamVersion)
    [System.IO.File]::WriteAllText($path, $text)
}

Write-Host "Created $Name at $Destination (Beam $beamVersion)"
Write-Host "Next, from the new folder: godot --headless -s res://tools/addons.gd"
