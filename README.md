# HELIOS PROTOCOL // UAC TACTICAL EDITION (v8.0)

> **Apple Watch 独立 2.5D 硬核写实军事科幻第一人称射击游戏 (watchOS 10+ SwiftUI Canvas & Retina Web Simulator)**
>
> *Inspired by DOOM (1993 / 2016), Brutal Doom, Monument Valley & Dead Space — Built for Apple Watch Digital Crown & CoreMotion Wrist Pitch*

![Full Simulator Workbench](Preview/playtest_output/00_full_simulator.png)

---

## 1. v8.0 核心架构升级 (Campaign Map · Zero-HUD · Rigid-Body Physics · Shotgun Destruction)

1. **全景等高线战术闯关大地图 (`CAMPAIGN_NODES` & `renderPanoramicCampaignMap`)**
   - 在表盘主界面 (`MENU`) 直接渲染交互式 **UAC 火卫一全景等高线战术地图**，包含 **5 个闯关节点 (`NODE 01` ~ `NODE 05`)**、实时脉冲信标、战役推进路线与当前节点任务简报。
   - **点到哪里直接进行当前关卡**：轻点全景地图上的任意节点（如 `01 BREACH GATE`、`02 COOLING TOWERS`、`03 CYBER LORD`、`04 BLACK MESA`、`05 POLAR CORE`），立即切入对应战役关卡与阶段。
2. **关卡内 100% 零 UI 沉浸视图 (`Zero-HUD In-Level Immersion`)**
   - 在 3D 关卡战斗 (`PLAYING`) 中**彻底移除所有 2D UI 框体、文字横幅、雷达小地图与底栏**，将 Apple Watch `272×334` 视口 100% 留给第一人称 3D 画面与底部贴合锚定的 **Freedoom 原生第一人称重型枪械 (`shtga0` / `chgga0` / `plsga0`)**。
   - **纯 3D 场景化状态与目标反馈 (Diegetic 3D Feedback)**：
     - **任务指引**：3D 空间垂直体积光柱 (`Volumetric Light-Shaft Beacon`) + Freedoom 动态闪烁战术灯柱 (`tlmpa0..d0`)，无需任何文字弹窗即可看清拉闸、冷却塔与撤离点方位。
     - **受击与生命值反馈**：屏幕边缘立体鲜血飞溅液滴 (`Visor Blood Droplets`) + 低血量心跳红晕脉冲。
3. **2.5D 连续圆与网格切向滑动 + 刚体冲量物理引擎 (`resolveCircleMapPhysics`)**
   - 借鉴 *Quake (`PM_SlideMove`)* 与 *ImpulseEngine* 的连续最近点法线投影算法 (`v_new = v - (1 + e)(v · n)n`)：
     - **玩家丝滑切向擦墙 (`e = 0.0`)**：斜向贴墙移动时速度自动沿墙壁切线无损分解，彻底消除卡墙角与贴墙抖动。
     - **敌方刚体动量碰撞与撞墙碎裂伤害 (`e = 0.42`)**：怪兽之间具备基于质量的刚体冲量传递（近距离轰飞前排恶魔会像保龄球一样撞退后排敌人），高速撞击掩体墙面还会触发**二次物理撞墙伤害与碎石飞溅**。
4. **霰弹枪 8 弹丸多射线物理破坏与 3D 弹跳碎块 (`castShotgunPelletRays` & `state.debris`)**
   - **可轰塌裂纹掩体墙 (`Tile 10`)**：霰弹枪近距离齐射可轰穿带发光裂纹的战术掩体墙，打通隐藏捷径并爆出 22+ 枚受重力与地面弹性碰撞 (`e = 0.48`) 驱动的 **3D 物理弹跳碎块**。
   - **可破坏 3D 石柱 (`col1a0` / `col2a0` → `colua0`)**：轰碎地图中的 3D 装饰立柱，炸裂出石块残骸并暴露其后的敌人。
   - **原生 Freedoom 火花与血雾精灵**：子弹命中墙面迸发 `puffa0..d0` 火花硝烟，命中肉体迸发 `bluda0..c0` 血雾与 `pol5a0` 地面碎肉血泊。
5. **124 项开源 DOOM (`Freedoom` + `Aquatex`) 正版授权素材库 + 多点彩色动态光照 (`pointLights`)**
   - 内置 `124` 项 `BSD-3-Clause` 开源纹理、精灵与 HUD 数字字模 (`assets/freedoom_assets.js`)。
   - 发光墙面 (`aqlite01`)、反应堆核心、飞行等离子弹丸与爆炸火光实时向周围墙面、地面与 3D 精灵投射多点 RGB 彩色衰减光照。

---

## 2. 实机截图预览 (Apple Watch Ultra 272×334 视口)

| 全景闯关大地图 (`01_menu_home`) | 军火库 (`02_menu_armory`) |
| :---: | :---: |
| ![Home Menu](Preview/playtest_output/01_menu_home.png) | ![Armory Menu](Preview/playtest_output/02_menu_armory.png) |

| 零 UI 关卡内第一阶段 (`03_gameplay_early_2s`) | 物理破坏与第二阶段激战 (`04_gameplay_boss_fever`) | 第三阶段撤离信标 (`05_gameplay_late`) |
| :---: | :---: | :---: |
| ![Stage 1 Breakthrough](Preview/playtest_output/03_gameplay_early_2s.png) | ![Stage 2 Combat](Preview/playtest_output/04_gameplay_boss_fever.png) | ![Stage 3 Extraction](Preview/playtest_output/05_gameplay_late.png) |

---

## 3. 五节点全景战役架构 (`CAMPAIGN_NODES`)

| 节点 | 战区代号 | 核心任务指示 | 物理破坏与机关特性 |
| :--- | :--- | :--- | :--- |
| **NODE 01** | `PHOBOS GATE` | 寻路拉下东南配电闸，轰穿裂纹掩体墙开启防爆门 | 可轰塌掩体墙 (`Tile 10`) + 可破坏战术立柱 |
| **NODE 02** | `COOLING TOWERS` | 突入中央反应堆防区，利用霰弹枪与爆炸桶摧毁双翼冷却塔 | 链式殉爆核废料桶 + 3D 石柱掩体破坏 |
| **NODE 03** | `CYBER LORD` | 肃清镇守北侧升降梯的地狱赛博领主并完成撤离 | 高压特斯拉电弧防卫线圈 + 领主刚体冲量击退 |
| **NODE 04** | `BLACK MESA` | 深入黑山反应堆走廊，夺取门禁磁卡突破封锁区 | 多点工业灯带 (`aqlite01`) + 狭窄走廊霰弹轰墙捷径 |
| **NODE 05** | `POLAR CORE` | 极地天穹开放前哨，驻守核心完成 100% 超载上传 | 敞开式极光天穹 + 360° 立体防卫战 |

---

## 4. 目录结构 (Repository Layout)

```text
├── CyberStrideSimulator.html        # 60FPS 2x Retina 网页版 Apple Watch Ultra 模拟器 (主入口)
├── assets/
│   ├── freedoom_assets.js           # 124 项 Freedoom + Aquatex Base64 纹理与精灵资源包
│   └── freedoom/                    # 原始 PNG 贴图、怪物/武器/破坏柱/火花精灵与 LICENSE.txt
├── Preview/
│   ├── CyberStrideSimulator.html    # 模拟器预览副本
│   └── playtest_output/             # 自动化无头浏览器实机测试截图与 HIG 审计报告
├── WatchApp/
│   ├── CyberStrideApp.swift         # watchOS App 入口
│   ├── CyberStrideEngine.swift      # CoreMotion 腕部俯仰 + Digital Crown 转向 + DDA 射线引擎
│   ├── CyberStrideWatchView.swift   # SwiftUI 战术视图层
│   └── CyberStrideWatchCanvasView.swift # watchOS 10+ SwiftUI Canvas + TimelineView 60FPS 渲染实现
└── project.yml                      # XcodeGen 工程配置文件 (watchOS 10.0+)
```

---

## 5. 快速运行指南 (Quick Start)

### 方式 A：直接运行交互式 Apple Watch Ultra 网页模拟器
无需安装 Xcode，直接用现代浏览器（Chrome / Edge / Safari）打开根目录下的 `CyberStrideSimulator.html`：
- **全景地图选关 (`MENU`)**：直接点击表盘地图上的 `01` ~ `05` 战术节点即可切入任意关卡。
- **转动表冠 / 鼠标滚轮 / 左右方向键 (`A`/`D`)**：360° 战术瞄准转向（瞄准敌人时自动触发阻尼减速与辅助吸附）。
- **手腕前倾 / `W`/`S` 键**：前后战术推进与后撤（贴墙移动自动触发连续切向丝滑滑动）。
- **轻点屏幕 / 空格键 / `E` 键**：靠近发光信标时拉下工业电闸、激活高压电弧防卫塔、拾取门禁卡或引爆超载脉冲。
- **右侧快捷键 `1` / `2` / `3`**：切换 **M870 物理破障霰弹枪**、**GAU-19 转管机枪** 与 **MK-IV 等离子步枪**。

### 方式 B：生成原生 watchOS Xcode 工程
在 macOS 上安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 后执行：
```bash
xcodegen generate
open HeliosProtocolWatch.xcodeproj
```
选择 **Apple Watch Series 9 / Ultra 2 Simulator** 即可编译运行。
