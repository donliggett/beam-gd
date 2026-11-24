# Creates a new game repo from Beam's template.
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

Copy-Item -Recurse (Join-Path $beam 'template') $Destination
New-Item -ItemType Directory -Force (Join-Path $Destination 'addons') | Out-Null
Copy-Item -Recurse (Join-Path $beam 'addons\beam') (Join-Path $Destination 'addons\beam')

$files = @(
    'project.godot',
    'export_presets.cfg',
    '.github\workflows\release.yml',
    'docs\spec.md',
    'README.md'
)
foreach ($file in $files) {
    $path = Join-Path $Destination $file
    $text = [System.IO.File]::ReadAllText($path)
    [System.IO.File]::WriteAllText($path, $text.Replace('__GAME_NAME__', $Name))
}

Write-Host "Created $Name at $Destination"
Write-Host "Next: add GUT to addons/gut, then run the rule tests."
