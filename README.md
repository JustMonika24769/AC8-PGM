<div align="center">

# AC8 PGM

面向 ACE COMBAT 8 的比例制导导弹资源覆盖模组

版本 `1.0.0` · 游戏版本 `1.1.2.0` · Unreal Engine `5.4` · 仅限离线单人战役

[简体中文](README.md) | [English](README_EN.md)

</div>

`AC8 PGM`（Proportional Guided Missile，比例制导导弹）直接覆盖武器蓝图与数据表，不使用 UObject 轮询逻辑，也不会改写游戏原始的 `pakchunk0-Windows.*`。

当前版本使用通用加载器 `AC8OverrideLoader`。旧版 `IoStoreLoaderMod` 已停用，安装程序会迁移并清理仅属于 AC8 PGM 的旧载荷。

## 目录

- [运行要求](#运行要求)
- [安装 UE4SS](#安装-ue4ss)
- [安装模组](#安装模组)
- [离线模式与 EAC](#离线模式与-eac)
- [运行方式与使用范围](#运行方式与使用范围)
- [卸载](#卸载)
- [默认参数](#默认参数)
- [自定义参数](#自定义参数)
- [排错](#排错)

## 运行要求

| 组件 | 要求 |
| --- | --- |
| 游戏 | ACE COMBAT 8 `1.1.2.0`（2026-10-04 验证） |
| 引擎版本 | Unreal Engine `5.4` |
| 模组加载器 | UE4SS `3.0.1 Beta #0`（提交 `e3ba1016`） |
| 系统工具 | Windows PowerShell 5.1 或 PowerShell 7 |

## 安装 UE4SS

1. 从 UE4SS 官方发布页取得与 UE5.4 x64 兼容的 `3.0.1 Beta #0`（提交 `e3ba1016`）压缩包。不要混用其他游戏的 UE4SS 文件或未知 nightly 版本。
2. 退出游戏，并备份 `Game\Binaries\Win64` 下现有的 UE4SS 文件和 `ue4ss\Mods` 目录。
3. 保持 UE4SS 压缩包原有的目录结构，将内容解压到：

   ```text
   ACE COMBAT 8\Game\Binaries\Win64\
   ```

   不要在目标目录中额外嵌套一层压缩包目录。安装后应能看到 `Game\Binaries\Win64\ue4ss\Mods`，以及 UE4SS 压缩包提供的启动加载文件。
4. 启动一次游戏并进入主菜单，然后退出。确认 `ue4ss\Mods\mods.txt` 已生成后，再安装本模组。

> [!IMPORTANT]
> 如果 UE4SS 没有正确安装，`Install.cmd` 会提示找不到 `ue4ss\Mods`。请修复 UE4SS 安装，不要手动创建空目录冒充 UE4SS。

## 安装模组

1. 退出游戏。
2. 完整卸载其他比例制导模组及其 UE4SS 文件。
3. 解压本发布包的全部内容，不要只提取 DLL。
4. 双击 `Install.cmd`。
5. 如果脚本未找到游戏，请在 PowerShell 中手动指定游戏路径：

   ```powershell
   .\Install.ps1 -GamePath "D:\SteamLibrary\steamapps\common\ACE COMBAT 8"
   ```

安装器只会增改 `mods.txt` 中属于本模组的条目，不会覆盖其他模组的配置。安装时，它还会：

- 启用 `AC8OverrideLoader`；
- 停用旧版 `IoStoreLoaderMod`；
- 清理旧加载器目录中仅属于 AC8 PGM 的旧载荷。

卸载其他比例制导模组时，请使用其自带的卸载程序，不要混装新旧模组文件。

安装前请再次确认：

- 游戏已经退出；
- 游戏版本为 `1.1.2.0`；
- 已备份 `Game\Binaries\Win64\ue4ss\Mods\mods.txt` 和现有 UE4SS 模组目录。

## 离线模式与 EAC

UE4SS 原生加载器与 Easy Anti-Cheat（EAC）不应在同一进程中运行。本发布包提供了与当前游戏版本匹配的 EAC 空客户端配置和 `steam_appid.txt`，仅用于离线启动单人战役。

### 启用离线模式

1. 运行 `EnableOffline.cmd`。脚本会复制以下文件，并自动备份目标位置已有的文件：

   | 来源 | 游戏内目标位置 |
   | --- | --- |
   | `offline\EasyAntiCheat\AC8PGM_Offline.json` | `EasyAntiCheat` |
   | `offline\Game\Binaries\Win64\steam_appid.txt` | `Game\Binaries\Win64` |

2. 在 Steam 的本游戏启动选项中加入以下内容。`%command%` 必须保留，由 Steam 展开：

   ```text
   cmd /d /c "set EOS_USE_ANTICHEATCLIENTNULL=1&& %command% -anticheat_settings=AC8PGM_Offline.json"
   ```

3. 仅通过该启动项进入单人战役。

### 恢复正常启动

1. 退出游戏。
2. 运行 `DisableOffline.cmd`。脚本会先确认文件没有被其他程序修改，再恢复原文件。
3. 删除 Steam 中的上述启动选项，恢复正常的 EAC 启动方式。

> [!WARNING]
> 不要使用普通的 EAC 启动项加载本模组，也不要将离线参数用于多人、联网活动、排行榜或其他在线服务。

还需注意：

- 不要删除、替换或重命名 `EasyAntiCheat` 目录，也不要修改 EAC 二进制文件。
- `EasyAntiCheat_EOS_Setup.exe` 只用于安装或修复 EAC，不是禁用开关。
- 如果当前游戏版本不接受空客户端配置，或 Steam 无法展开 `%command%`，请不要使用本模组。

这种方式只让本次离线进程使用 EAC 空客户端，不会删除、替换或修改 EAC 二进制文件，也不适用于任何在线服务。

## 运行方式与使用范围

修改后的资源保存在独立的 IoStore 覆盖容器中。UE4SS 负责在游戏启动时加载 AC8 专用原生挂载器，使游戏优先读取该容器。

没有 UE4SS 时，覆盖容器不会自动生效。不要手动将文件复制到 `Paks`、`~mods` 或 `LogicMods`。

本模组仅支持单人战役和离线测试。遇到以下情况时，请禁用模组并运行 `Uninstall.cmd`：

- 进入多人、联机、联网活动或排行榜模式；
- 使用任何需要在线服务验证的启动方式；
- 同时使用其他修改武器、制导或 IoStore 挂载的模组。

本模组未在多人环境、反作弊环境或在线服务中进行兼容性测试。请勿尝试绕过游戏的在线限制或安全检查。

## 卸载

退出游戏后，双击 `Uninstall.cmd`。卸载器只清理本发布包安装的 AC8 PGM 覆盖资源，不会修改游戏原始的 `pakchunk`。

如果 `AC8OverrideLoader` 还承载其他覆盖容器，卸载器会保留并继续启用它；没有其他容器时，卸载器会移除加载器文件并停用对应的 `mods.txt` 条目。

如果此前启用了离线模式，还应运行 `DisableOffline.cmd`，并删除 Steam 中的离线启动选项。

## 默认参数

下列制导参数内置于当前发布包。

| 阵营 | 参数值 | 导弹 |
| --- | ---: | --- |
| 玩家 | 1.00 | QAAM |
| 玩家 | 0.95 | SAAM, 2AAM |
| 玩家 | 0.90 | LAAM, SASM, 4AAM, 6AAM |
| 玩家 | 0.85 | HVAA |
| 玩家 | 0.80 | HCAA, MSL |
| 玩家 | 0.75 | HPAA |
| 敌方 | 0.30 | QAAM, SAAM, LAAM, 2AAM |
| 敌方 | 0.25 | MSL, 4AAM, 6AAM, 8AAM, HCAA, HVAA, SASM |
| 敌方 | 0.20 | HPAA |

## 自定义参数

发布包内的 `tools\AC8PGMCustomizer-v1.0.0.zip` 是可选的自定义工具。它可以读取 `config.json` 中的玩家和敌方导弹参数，重新生成并验证以下覆盖资源：

- `AC8PGMDirect_P.utoc`
- `AC8PGMDirect_P.ucas`
- `AC8PGMDirect_P.pak`
- `AC8PGMDirect_P.build.json`

生成的资源会安装到：

```text
Game\Binaries\Win64\ue4ss\Mods\AC8OverrideLoader\payloads\AC8PGMDirect
```

该工具是自包含程序，无需另外安装 .NET。

### 使用步骤

1. 按照上文安装基础版 AC8 PGM，并确认默认参数能在离线战役中正常生效。
2. 退出游戏，将 `tools\AC8PGMCustomizer-v1.0.0.zip` 完整解压到单独目录。不要直接在压缩包中运行，也不要只提取 EXE；程序需要同目录下的 `data` 文件夹。
3. 用文本编辑器打开工具目录中的 `config.json`，修改 `player` 和 `enemy` 下需要调整的值。数值必须是 `0` 到 `10` 之间的有限数字；删除某一项会保留模板默认值。
4. 在工具目录中打开 PowerShell 或命令提示符，检查配置：

   ```text
   AC8PGMCustomizer.exe check
   ```

5. 基础模组已经安装时，生成、回读验证并安装四个覆盖资源：

   ```text
   AC8PGMCustomizer.exe install
   ```

   如果只想生成文件而暂时不安装，请运行：

   ```text
   AC8PGMCustomizer.exe generate
   ```

生成结果位于工具目录的 `output` 文件夹。修改参数后，需要再次运行 `install` 才会更新游戏实际加载的资源。若要恢复本发布包的默认参数，请退出游戏并重新运行顶层的 `Install.cmd`。

自定义工具不会修改游戏原始的 `pakchunk0-Windows.*`，但生成的资源仍依赖基础模组的 UE4SS IoStore 加载器。它同样只允许用于游戏 `1.1.2.0` 的离线单人战役，不得用于多人、联网活动或排行榜。

更详细的参数与排错说明位于工具压缩包内的 `README.md`；开发实现和构建说明位于 Developer 包文档。

## 排错

运行日志位于：

```text
Game\Binaries\Win64\ue4ss\Mods\AC8OverrideLoader\AC8OverrideLoader.log
```

正常日志应包含：

```text
custom mount code=0 message=OK
```

游戏更新后，如果签名不再唯一，加载器会拒绝补丁。此时需要针对新版本重新适配，不能强行复用旧 DLL。

如果启动后出现异常：

1. 退出游戏并运行 `Uninstall.cmd`。
2. 如需紧急停用，也可以将以下内容写入 `ue4ss\Mods\mods.txt`：

   ```text
   AC8OverrideLoader : 0
   ```

本模组不修改原始游戏容器，但仍可能与其他 UE4SS 模组或未来的游戏更新发生冲突。

技术说明和源码位于单独的 Developer 压缩包中。底层 UE4SS 加载器条目现名为 `AC8OverrideLoader`；这是加载器模块名，不是模组展示名。
