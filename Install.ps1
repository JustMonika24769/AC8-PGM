[CmdletBinding()]
param(
    [string]$GamePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-GamePath {
    param([string]$RequestedPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) {
        $candidates.Add([IO.Path]::GetFullPath($RequestedPath))
    }

    $candidates.Add($PSScriptRoot)
    $candidates.Add((Split-Path -Parent $PSScriptRoot))

    $steamRoots = New-Object System.Collections.Generic.List[string]
    foreach ($key in @(
        'HKCU:\Software\Valve\Steam',
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'
    )) {
        try {
            $item = Get-ItemProperty -LiteralPath $key
            foreach ($property in @('SteamPath', 'InstallPath')) {
                $value = $item.$property
                if ($value) { $steamRoots.Add([string]$value) }
            }
        } catch { }
    }

    foreach ($steamRoot in $steamRoots) {
        $libraries = New-Object System.Collections.Generic.List[string]
        $libraries.Add($steamRoot)
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

    foreach ($candidate in $candidates | Select-Object -Unique) {
        $exe = Join-Path $candidate 'Game\Binaries\Win64\AceCombat8.exe'
        if (Test-Path -LiteralPath $exe) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }

    throw 'ACE COMBAT 8 was not found. Use: .\Install.ps1 -GamePath "D:\...\ACE COMBAT 8"'
}

function Set-ModState {
    param(
        [string]$ModsFile,
        [string]$Name,
        [int]$State
    )

    $lines = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $ModsFile) {
        $lines.AddRange([string[]][IO.File]::ReadAllLines($ModsFile))
    }
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

function Copy-Atomic {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path -LiteralPath $Source)) {
        throw "The release package is missing: $Source"
    }
    $parent = Split-Path -Parent $Destination
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    $temp = $Destination + '.installing'
    Copy-Item -LiteralPath $Source -Destination $temp -Force
    Move-Item -LiteralPath $temp -Destination $Destination -Force
}

function Get-SHA256 {
    param([string]$Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try {
        return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant()
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
}

function Test-Payload {
    $expected = [ordered]@{
        'payload\AC8PGMDirect\AC8PGMDirect_P.build.json' = '3a156ab2558c6e23da301155c112f6e8366d8f987e87b55950a3adf78b356320'
        'payload\AC8PGMDirect\AC8PGMDirect_P.pak' = '75e7144577253917f6da7312ef5e585b12fb728226a22b0938323751a6b555cd'
        'payload\AC8PGMDirect\AC8PGMDirect_P.ucas' = '7b3a4cf4b3329e889caf25b079362e69c653dfe8023646de6c1a21f7e177bcac'
        'payload\AC8PGMDirect\AC8PGMDirect_P.utoc' = 'c3ed7a693ec74923c8785f36a548bd7557815496e91fdfe7e4c470fbab61958e'
        'payload\dlls\main.dll' = 'b6c1a8678736628404d9f81a4ad65952aaab071d35f823b29d6e51fd4cb53785'
    }
    foreach ($relative in $expected.Keys) {
        $path = Join-Path $PSScriptRoot $relative
        if (-not (Test-Path -LiteralPath $path)) { throw "The release package is missing: $relative" }
        if ((Get-SHA256 $path) -ne $expected[$relative]) {
            throw "Payload checksum mismatch: $relative"
        }
    }
}

try {
    if (Get-Process -Name AceCombat8 -ErrorAction SilentlyContinue) {
        throw 'Exit ACE COMBAT 8 before installing the mod.'
    }

    Test-Payload
    $game = Find-GamePath $GamePath
    $win64 = Join-Path $game 'Game\Binaries\Win64'
    $mods = Join-Path $win64 'ue4ss\Mods'
    if (-not (Test-Path -LiteralPath $mods)) {
        throw "The UE4SS Mods directory was not found: $mods. Install a compatible UE4SS first."
    }

    $loader = Join-Path $mods 'IoStoreLoaderMod'
    $container = Join-Path $loader 'AC8PGMDirect'
    foreach ($name in @(
        'AC8PGMDirect_P.utoc',
        'AC8PGMDirect_P.ucas',
        'AC8PGMDirect_P.pak',
        'AC8PGMDirect_P.build.json'
    )) {
        Copy-Atomic (Join-Path $PSScriptRoot "payload\AC8PGMDirect\$name") (Join-Path $container $name)
    }
    Copy-Atomic (Join-Path $PSScriptRoot 'payload\dlls\main.dll') (Join-Path $loader 'dlls\main.dll')

    $modsFile = Join-Path $mods 'mods.txt'
    Set-ModState $modsFile 'IoStoreLoaderMod' 1
    Set-ModState $modsFile 'AC8AssetMappingDumper' 0

    Write-Host "Installed successfully: $game" -ForegroundColor Green
    Write-Host 'IoStoreLoaderMod is enabled. Display name: AC8 PGM.'
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
