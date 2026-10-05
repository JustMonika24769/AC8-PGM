[CmdletBinding()]
param(
    [string]$GamePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-GamePath {
    param([string]$RequestedPath)
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) { $candidates.Add([IO.Path]::GetFullPath($RequestedPath)) }
    $candidates.Add($PSScriptRoot)
    $candidates.Add((Split-Path -Parent $PSScriptRoot))

    foreach ($key in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        try {
            $item = Get-ItemProperty -LiteralPath $key
            foreach ($property in @('SteamPath', 'InstallPath')) {
                $root = $item.$property
                if (-not $root) { continue }
                $libraries = @([string]$root)
                $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
                if (Test-Path -LiteralPath $vdf) {
                    $text = [IO.File]::ReadAllText($vdf)
                    $libraries += [regex]::Matches($text, '"path"\s+"([^"]+)"') | ForEach-Object {
                        $_.Groups[1].Value.Replace('\\', '\')
                    }
                }
                foreach ($library in $libraries) {
                    $candidates.Add((Join-Path $library 'steamapps\common\ACE COMBAT 8'))
                }
            }
        } catch { }
    }
    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'Game\Binaries\Win64\AceCombat8.exe')) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }
    throw 'ACE COMBAT 8 was not found. Use: .\Uninstall.ps1 -GamePath "D:\...\ACE COMBAT 8"'
}

function Set-ModState {
    param([string]$ModsFile, [string]$Name, [int]$State)
    if (-not (Test-Path -LiteralPath $ModsFile)) { return }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.AddRange([string[]][IO.File]::ReadAllLines($ModsFile))
    $pattern = '^\s*' + [regex]::Escape($Name) + '\s*:'
    $replacement = "$Name : $State"
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $pattern) {
            $lines[$i] = $replacement
            $found = $true
        }
    }
    if (-not $found) { $lines.Add($replacement) }
    $temp = $ModsFile + '.ac8propnav.tmp'
    [IO.File]::WriteAllLines($temp, $lines, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temp -Destination $ModsFile -Force
}

try {
    if (Get-Process -Name AceCombat8 -ErrorAction SilentlyContinue) {
        throw 'Exit ACE COMBAT 8 before uninstalling the mod.'
    }
    $game = Find-GamePath $GamePath
    $mods = Join-Path $game 'Game\Binaries\Win64\ue4ss\Mods'
    $loader = Join-Path $mods 'AC8OverrideLoader'
    $payloadRoot = Join-Path $loader 'payloads'
    $container = Join-Path $payloadRoot 'AC8PGMDirect'

    foreach ($name in @(
        'AC8PGMDirect_P.utoc',
        'AC8PGMDirect_P.ucas',
        'AC8PGMDirect_P.pak',
        'AC8PGMDirect_P.build.json'
    )) {
        $path = Join-Path $container $name
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    if ((Test-Path -LiteralPath $container) -and
        -not (Get-ChildItem -LiteralPath $container -Force)) {
        Remove-Item -LiteralPath $container -Force
    }

    $otherContainers = @()
    if (Test-Path -LiteralPath $payloadRoot) {
        $otherContainers = @(Get-ChildItem -LiteralPath $payloadRoot -Recurse -File -Filter '*.utoc')
    }
    if ($otherContainers.Count -eq 0) {
        foreach ($path in @(
            (Join-Path $loader 'dlls\main.dll'),
            (Join-Path $loader 'AC8OverrideLoader.log')
        )) {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
        }
        Set-ModState (Join-Path $mods 'mods.txt') 'AC8OverrideLoader' 0
    } else {
        Write-Host "AC8OverrideLoader remains enabled for $($otherContainers.Count) other container(s)."
    }

    # Also remove a legacy AC8PGM payload left by releases before this migration.
    $legacyContainer = Join-Path $mods 'IoStoreLoaderMod\AC8PGMDirect'
    foreach ($name in @(
        'AC8PGMDirect_P.utoc',
        'AC8PGMDirect_P.ucas',
        'AC8PGMDirect_P.pak',
        'AC8PGMDirect_P.build.json'
    )) {
        $legacyPath = Join-Path $legacyContainer $name
        if (Test-Path -LiteralPath $legacyPath) { Remove-Item -LiteralPath $legacyPath -Force }
    }

    foreach ($directory in @(
        $legacyContainer,
        $container,
        $payloadRoot,
        (Join-Path $loader 'dlls'),
        $loader
    )) {
        if ((Test-Path -LiteralPath $directory) -and -not (Get-ChildItem -LiteralPath $directory -Force)) {
            Remove-Item -LiteralPath $directory -Force
        }
    }

    Write-Host "Uninstalled successfully: $game" -ForegroundColor Green
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
