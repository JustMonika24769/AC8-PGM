[CmdletBinding()]
param(
    [ValidateSet('Enable', 'Disable')]
    [string]$Action = 'Enable',
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
                $steamRoot = $item.$property
                if (-not $steamRoot) { continue }
                $libraries = New-Object System.Collections.Generic.List[string]
                $libraries.Add([string]$steamRoot)
                $vdf = Join-Path $steamRoot 'steamapps\libraryfolders.vdf'
                if (Test-Path -LiteralPath $vdf) {
                    $text = [IO.File]::ReadAllText($vdf)
                    foreach ($match in [regex]::Matches($text, '"path"\s+"([^"]+)"')) {
                        $libraries.Add($match.Groups[1].Value.Replace('\\', '\'))
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
    throw 'ACE COMBAT 8 was not found. Use: .\EnableOffline.cmd -GamePath "D:\...\ACE COMBAT 8"'
}

function Get-SHA256 {
    param([string]$Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant() }
    finally { $stream.Dispose(); $sha.Dispose() }
}

function Copy-Atomic {
    param([string]$Source, [string]$Destination)
    $temp = $Destination + '.ac8pgm-installing'
    Copy-Item -LiteralPath $Source -Destination $temp -Force
    Move-Item -LiteralPath $temp -Destination $Destination -Force
}

function Enable-Offline {
    param([string]$Game)
    $win64 = Join-Path $Game 'Game\Binaries\Win64'
    $eac = Join-Path $Game 'EasyAntiCheat'
    $statePath = Join-Path $win64 'AC8PGM_Offline.state.json'
    if (Test-Path -LiteralPath $statePath) { throw 'AC8 PGM offline EAC mode is already enabled.' }
    if (-not (Test-Path -LiteralPath $eac)) { throw "EasyAntiCheat directory was not found: $eac" }

    $files = @(
        @{ Source = Join-Path $PSScriptRoot 'offline\EasyAntiCheat\AC8PGM_Offline.json'; Destination = Join-Path $eac 'AC8PGM_Offline.json' },
        @{ Source = Join-Path $PSScriptRoot 'offline\Game\Binaries\Win64\steam_appid.txt'; Destination = Join-Path $win64 'steam_appid.txt' }
    )
    $state = @()
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath $file.Source)) { throw "Offline EAC file is missing from the package: $($file.Source)" }
        $backup = $file.Destination + '.ac8pgm-original'
        $hadOriginal = Test-Path -LiteralPath $file.Destination
        if ($hadOriginal) {
            if (Test-Path -LiteralPath $backup) { throw "Backup already exists; refusing to overwrite: $backup" }
            Move-Item -LiteralPath $file.Destination -Destination $backup
        }
        Copy-Atomic $file.Source $file.Destination
        $state += [ordered]@{
            destination = $file.Destination
            backup = $backup
            hadOriginal = $hadOriginal
            sourceHash = Get-SHA256 $file.Source
        }
    }
    [IO.File]::WriteAllText($statePath, (($state | ConvertTo-Json -Depth 3)), (New-Object Text.UTF8Encoding($false)))
    Write-Host "Offline EAC configuration enabled for campaign use: $Game" -ForegroundColor Green
    Write-Host 'Now set the documented Steam launch option before starting the game.'
}

function Disable-Offline {
    param([string]$Game)
    $win64 = Join-Path $Game 'Game\Binaries\Win64'
    $statePath = Join-Path $win64 'AC8PGM_Offline.state.json'
    if (-not (Test-Path -LiteralPath $statePath)) {
        Write-Host 'AC8 PGM offline EAC mode is not enabled by this package.'
        return
    }
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    foreach ($file in @($state)) {
        if (Test-Path -LiteralPath $file.destination) {
            $currentHash = Get-SHA256 $file.destination
            if ($currentHash -ne $file.sourceHash) {
                throw "Refusing to remove a changed file; inspect manually: $($file.destination)"
            }
            Remove-Item -LiteralPath $file.destination -Force
        }
        if ([bool]$file.hadOriginal) {
            if (-not (Test-Path -LiteralPath $file.backup)) { throw "Original file backup is missing: $($file.backup)" }
            Move-Item -LiteralPath $file.backup -Destination $file.destination
        }
    }
    Remove-Item -LiteralPath $statePath -Force
    Write-Host "Offline EAC configuration disabled and original files restored: $Game" -ForegroundColor Green
}

try {
    if (Get-Process -Name AceCombat8 -ErrorAction SilentlyContinue) { throw 'Exit ACE COMBAT 8 before changing offline EAC files.' }
    $game = Find-GamePath $GamePath
    if ($Action -eq 'Enable') { Enable-Offline $game } else { Disable-Offline $game }
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
