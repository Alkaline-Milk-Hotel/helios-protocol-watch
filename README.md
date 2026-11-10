# 曙光协议 · 腕上硬核第一人称射击模拟器 (v9.0)

> **Apple Watch 独立 2.5D 写实军事科幻第一人称射击游戏 (watchOS 10+ SwiftUI Canvas & 2x Retina 网页模拟器)**
>
> *对标开源经典 `id-Software/DOOM`、`nicklockwood/RetroRampage` 与《Brutal Doom》物理交互体系 —— 专为 Apple Watch 数码表冠与腕上微操打造*

![全景模拟器工作台](Preview/playtest_output/00_full_simulator.png)

---

## 一、 v9.0 核心升级亮点

1. **真实刚体与尸体交互物理 (`resolveCircleMapPhysics` & `gibCorpse`)**
   - **死尸惯性滑行与撞墙碎裂**：敌人被击毙后保留完整击退动量 `(kvx, kvy)` 沿地面滑行并拖出血迹，高速撞击墙面会迸发血雾甚至直接撞碎。
   - **踢尸滑行 (`DOOM MF_CORPSE` + 冲量反馈)**：倒地尸体绝不卡住玩家移动，玩家疾步走过尸体可将其一脚踢开并留下一道血痕。
   - **霰弹轰碎尸体 (`碎尸物理`)**：使用重型泵动霰弹枪、等离子步枪或引爆核废料油桶轰击地面尸体，可将其炸碎为永久 `pol5a0` 碎肉血泊与 14 块受重力弹跳的 3D 残肢碎块。
   - **活体阻挡与可推动油桶**：修复活体贴图穿模与推墙瞬移缺陷，支持用身体推撞爆炸油桶至裂隙墙或怪群旁再开枪引爆。
2. **紧凑走廊式五关战役流程（拒绝空旷迷路与重复灯柱）**
   - 借鉴 GitHub 高分 Raycaster 工程 [`nicklockwood/RetroRampage`](https://github.com/nicklockwood/RetroRampage) 与 [`id-Software/DOOM`](https://github.com/id-Software/DOOM) 的关卡动线：玩家出生即正对走廊守卫、防爆门、**门旁红绿双态电闸台座 (`sw1s0` / `sw1s1`)** 与**左侧发光裂隙破片墙 (`Tile 10`)**，“拉闸开门”或“霰弹破墙抄近道”一目了然。
   - 所有交互机关均拥有**独立高辨识度 3D 造型**：工业断路器电闸、悬浮蓝/红门禁卡全息台座、带独立血条的高热等离子反应核、带地面充能圈的超载控制台、以及终点绿色光幕撤离电梯。
3. **纯正第一人称手动操控 + 可选自动寻路托管**
   - 手动模式下彻底移除自动推墙与贴墙强转视角：支持 `WASD`/方向键前后平移、鼠标横向拖拽或滚轮 `1:1` 精准转向、左键按住连发开火、`1/2/3` 快捷键切枪。
   - 保留一键开启的 **自动寻路与战斗托管** 模式，方便测试与单手观战。
4. **100% 纯净简体中文界面 + 空间三维目标微标**
   - 全面统一为纯正简体中文界面与简报，杜绝生硬的中英混排。
   - 关卡内无常驻 2D 状态栏遮挡：枪身底座内嵌 **3 格内源性生命指示灯带**，仅在当前主目标上方投射极简 **3D 菱形微标与距离读数（如 `◇ 南门电闸 2米`）**，并在阶段突破时短暂浮现 `2.2` 秒顶部战术简报。

---

## 二、 实机运行截图 (Apple Watch Ultra 272×334 视口)

| 全景闯关大地图 (`01_menu_home`) | 武器军火库 (`02_menu_armory`) |
| :---: | :---: |
| ![全景战役地图](Preview/playtest_output/01_menu_home.png) | ![武器军火库](Preview/playtest_output/02_menu_armory.png) |

| 破门与碎尸激战 (`03_gameplay_early_2s`) | 领主决战与霰弹拉栓 (`04_gameplay_boss_fever`) | 门旁电闸与裂隙破片墙 (`05_gameplay_late`) |
| :---: | :---: | :---: |
| ![第一阶段激战](Preview/playtest_output/03_gameplay_early_2s.png) | ![领主决战](Preview/playtest_output/04_gameplay_boss_fever.png) | ![电闸与裂隙墙](Preview/playtest_output/05_gameplay_late.png) |

---

## 三、 五大闯关节点与任务流程 (`CAMPAIGN_NODES`)

| 关卡代号 | 战区名称 | 核心任务指令 | 专属机关与物理破坏体验 |
| :--- | :--- | :--- | :--- |
| **第 01 关** | `曙光外围配电区` | 拉下门旁电闸或轰开裂隙墙，拾取蓝色门禁卡撤离 | 重型泵动霰弹枪破墙 (`Tile 10`) + 踢尸/碎尸物理 |
| **第 02 关** | `重装军械弹药库` | 使用六管加特林机枪肃清走廊，拾取红色门禁卡开启北门 | 高射速弹幕压制 + 可推动链式殉爆油桶 |
| **第 03 关** | `双翼反应堆核心` | 突入中央防区，轰爆东西两侧高热反应堆核心 | 3D 装甲等离子反应核独立血条 + 石柱掩体轰碎 |
| **第 04 关** | `地下超载实验室` | 驻守中央超载控制台完成 `100%` 充能，突破北门 | 地面全息占领圈 + 狭窄走廊多点工业发光灯带 |
| **第 05 关** | `陨石坑指挥高台` | 决战深渊赛博领主，解除封锁并登上北侧绿色撤离电梯 | 敞开式血色天穹 + 高能等离子步枪决战巨型领主 |

---

## 四、 目录结构

```text
├── CyberStrideSimulator.html            # 60FPS 2x Retina 网页版 Apple Watch Ultra 模拟器 (主入口)
├── assets/
│   ├── freedoom_assets.js               # 124 项 Freedoom + Aquatex 开源纹理与精灵资源包 (BSD-3-Clause)
│   └── freedoom/                        # 原始 PNG 贴图、怪物/武器/破坏柱/开关精灵与 LICENSE.txt
├── Preview/
│   ├── CyberStrideSimulator.html        # 模拟器同步预览副本
│   └── playtest_output/                 # 自动化无头浏览器实机测试截图与 HIG 审计报告
├── WatchApp/
│   ├── CyberStrideApp.swift             # watchOS App 入口
│   ├── CyberStrideEngine.swift          # CoreMotion 腕部俯仰 + Digital Crown 转向 + DDA 射线引擎
│   ├── CyberStrideWatchView.swift       # SwiftUI 战术视图层
│   └── CyberStrideWatchCanvasView.swift # watchOS 10+ SwiftUI Canvas + TimelineView 60FPS 渲染实现
└── project.yml                          # XcodeGen 工程配置文件 (watchOS 10.0+)
```

---

## 五、 快速体验指南

直接用现代浏览器（Chrome / Edge / Safari）打开根目录下的 `CyberStrideSimulator.html` 即可即开即玩：
- **全景地图选关**：在表盘地图界面点击 `01` ~ `05` 任意关卡节点直接切入对应关卡。
- **移动与擦墙**：按 `W` / `A` / `S` / `D` 或上下方向键前后推进、左右平移（自动支持连续切向丝滑擦墙、推油桶与踢飞地上尸体）。
- **瞄准转向**：在表盘画面上**按住鼠标左右拖拽**、滚动鼠标滚轮、拖拽右侧数码表冠，或按 `Q` / 左右方向键精准转向。
- **开火与交互**：点击/按住鼠标左键或按 `空格` / `F` 键射击；靠近电闸时自动触发或按 `E` 键交互；按数字键 `1` / `2` / `3` 切换三大主战武器。
