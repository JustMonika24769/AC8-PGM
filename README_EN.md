# AC8 PGM

> **Version 1.0.0** | For ACE COMBAT 8 `1.1.2.0` | Offline campaign only

[简体中文](README.md) | [English](README_EN.md)

`AC8 PGM` (Proportional Guided Missile) is a resource override mod for ACE COMBAT 8. It directly overrides weapon blueprints and data tables without UObject polling, and it never writes resources back to the game's original `pakchunk0-Windows.*` files.

## Contents

- [Requirements](#requirements)
- [Install UE4SS](#install-ue4ss)
- [Install the mod](#install-the-mod)
- [Offline mode and EAC](#offline-mode-and-eac)
- [Supported use](#supported-use)
- [Uninstall](#uninstall)
- [Default tuning](#default-tuning)
- [Customize parameters](#customize-parameters)
- [Troubleshooting](#troubleshooting)

## Requirements

| Component | Requirement |
| --- | --- |
| Game | ACE COMBAT 8 `1.1.2.0` (verified on 2026-10-04) |
| Mod loader | UE4SS `3.0.1 Beta #0` (commit `e3ba1016`) |
| System tool | Windows PowerShell 5.1 or PowerShell 7 |

## Install UE4SS

1. Download the UE5.4 x64-compatible `3.0.1 Beta #0` archive (commit `e3ba1016`) from the official UE4SS releases page. Do not mix in UE4SS files from another game or use an unknown nightly build.
2. Exit the game, then back up any existing UE4SS files under `Game\Binaries\Win64` and the `ue4ss\Mods` directory.
3. Preserve the archive's directory structure and extract its contents to:

   ```text
   ACE COMBAT 8\Game\Binaries\Win64\
   ```

   Do not add another enclosing directory. After installation, `Game\Binaries\Win64\ue4ss\Mods` and the startup loader files included with UE4SS should be present.
4. Launch the game once, reach the main menu, and exit. Confirm that `ue4ss\Mods\mods.txt` has been created before installing this mod.

> [!IMPORTANT]
> If UE4SS is not installed correctly, `Install.cmd` will report that it cannot find `ue4ss\Mods`. Fix the UE4SS installation instead of creating an empty directory manually.

## Install the mod

1. Exit the game.
2. Fully uninstall any other proportional-guidance mods and their UE4SS files.
3. Extract the complete release archive. Do not extract only the DLL.
4. Double-click `Install.cmd`.
5. If the script cannot locate the game, specify its path in PowerShell:

   ```powershell
   .\Install.ps1 -GamePath "D:\SteamLibrary\steamapps\common\ACE COMBAT 8"
   ```

The installer only adds or updates this mod's entry in `mods.txt`; it does not overwrite other mod settings. Use the original uninstaller when removing another proportional-guidance mod, and do not mix files from different releases.

Before installation, confirm that:

- the game is not running;
- the game version is `1.1.2.0`; and
- you have backed up `Game\Binaries\Win64\ue4ss\Mods\mods.txt` and your existing UE4SS mod directory.

## Offline mode and EAC

The UE4SS native loader and Easy Anti-Cheat (EAC) must not run in the same process. This release includes an EAC null-client configuration matched to the supported game version, together with `steam_appid.txt`. These files are only for launching the single-player campaign offline.

### Enable offline mode

1. Run `EnableOffline.cmd`. The script copies the following files and automatically backs up existing files at the destinations:

   | Source | Destination in the game directory |
   | --- | --- |
   | `offline\EasyAntiCheat\AC8PGM_Offline.json` | `EasyAntiCheat` |
   | `offline\Game\Binaries\Win64\steam_appid.txt` | `Game\Binaries\Win64` |

2. Add the following line to the game's Steam launch options. Keep `%command%` unchanged so Steam can expand it:

   ```text
   cmd /d /c "set EOS_USE_ANTICHEATCLIENTNULL=1&& %command% -anticheat_settings=AC8PGM_Offline.json"
   ```

3. Use this launch option only to enter the single-player campaign.

### Restore normal startup

1. Exit the game.
2. Run `DisableOffline.cmd`. The script verifies that the installed files have not been changed by another program before restoring the originals.
3. Remove the launch option above from Steam and return to the normal EAC-enabled startup method.

> [!WARNING]
> Do not load this mod through the normal EAC launch path. Never use the offline arguments in multiplayer, online events, leaderboards, or any other online service.

Additional restrictions:

- Do not delete, replace, or rename the `EasyAntiCheat` directory, and do not modify EAC binaries.
- `EasyAntiCheat_EOS_Setup.exe` only installs or repairs EAC; it is not a disable switch.
- Do not use this mod if the current game version rejects the null-client configuration or Steam cannot expand `%command%`.

This method only selects the EAC null client for the current offline process. It does not delete, replace, or modify any EAC binary, and it is not suitable for online services.

## Supported use

Modified resources are stored in a separate IoStore override container. At game startup, UE4SS loads an AC8-specific native mounter so that the game reads this container at a higher priority.

The override container will not activate automatically without UE4SS. Do not manually copy its files to `Paks`, `~mods`, or `LogicMods`.

This mod supports only the single-player campaign and offline testing. Disable it and run `Uninstall.cmd` before:

- entering multiplayer, online events, or leaderboard modes;
- using any startup path that requires online-service validation; or
- using another mod that changes weapons, guidance, or IoStore mounting.

This mod has not been tested for compatibility with multiplayer, anti-cheat environments, or online services. Do not attempt to bypass the game's online restrictions or security checks.

## Uninstall

Exit the game, then double-click `Uninstall.cmd`. The uninstaller removes only the containers and loader installed by this release. It does not modify the game's original `pakchunk` files.

If offline mode was enabled, also run `DisableOffline.cmd` and remove the offline launch option from Steam.

## Default tuning

The values below are built into the current release.

| Side | Value | Missiles |
| --- | ---: | --- |
| Player | 1.00 | QAAM |
| Player | 0.95 | SAAM, 2AAM |
| Player | 0.90 | LAAM, SASM, 4AAM, 6AAM |
| Player | 0.85 | HVAA |
| Player | 0.80 | HCAA, MSL |
| Player | 0.75 | HPAA |
| Enemy | 0.30 | QAAM, SAAM, LAAM, 2AAM |
| Enemy | 0.25 | MSL, 4AAM, 6AAM, 8AAM, HCAA, HVAA, SASM |
| Enemy | 0.20 | HPAA |

## Customize parameters

`tools\AC8PGMCustomizer-v1.0.0.zip` contains an optional customization utility. It reads player and enemy missile values from `config.json`, then rebuilds and validates the following override resources:

- `AC8PGMDirect_P.utoc`
- `AC8PGMDirect_P.ucas`
- `AC8PGMDirect_P.pak`
- `AC8PGMDirect_P.build.json`

The utility is self-contained and does not require a separate .NET installation.

### Usage

1. Install the base AC8 PGM release as described above and confirm that its default settings work in an offline campaign.
2. Exit the game and fully extract `tools\AC8PGMCustomizer-v1.0.0.zip` to a separate directory. Do not run it inside the archive or extract only the EXE; the program requires the adjacent `data` directory.
3. Open `config.json` from the utility directory in a text editor. Change the required values under `player` and `enemy`. Each value must be a finite number from `0` through `10`; deleting an entry preserves the template's default value.
4. Open PowerShell or Command Prompt in the utility directory and validate the configuration:

   ```text
   AC8PGMCustomizer.exe check
   ```

5. With the base mod already installed, generate, read back, validate, and install all four override resources:

   ```text
   AC8PGMCustomizer.exe install
   ```

   To generate the files without installing them, run:

   ```text
   AC8PGMCustomizer.exe generate
   ```

Generated files are written to the utility's `output` directory. After changing parameters, run `install` again to update the resources loaded by the game. To restore the defaults supplied by this release, exit the game and rerun the top-level `Install.cmd`.

The customization utility does not modify the game's original `pakchunk0-Windows.*` files, but its generated resources still depend on the base mod's UE4SS IoStore loader. It is likewise restricted to the offline single-player campaign in game version `1.1.2.0` and must not be used in multiplayer, online events, or leaderboards.

More detailed parameter and troubleshooting information is available in the `README.md` inside the utility archive. Implementation and build documentation is included in the separate Developer package.

## Troubleshooting

The runtime log is located at:

```text
Game\Binaries\Win64\ue4ss\Mods\IoStoreLoaderMod\AC8IoStoreLoader.log
```

A successful log should contain:

```text
custom mount code=0 message=OK
```

If a game update makes the signature non-unique, the loader will refuse to apply the patch. The loader must then be updated for the new game version; do not force an older DLL to load.

If the game behaves unexpectedly after startup:

1. Exit the game and run `Uninstall.cmd`.
2. For an emergency disable, you can also add the following line to `ue4ss\Mods\mods.txt`:

   ```text
   IoStoreLoaderMod : 0
   ```

The mod does not alter the original game containers, but it may still conflict with other UE4SS mods or future game updates.

Technical notes and source code are provided in the separate Developer archive. The underlying UE4SS entry remains named `IoStoreLoaderMod`; this is the loader module name, not the mod's display name.
