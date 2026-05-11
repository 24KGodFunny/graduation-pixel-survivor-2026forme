## 📁 game-demo 项目文件夹结构及功能说明

```
pixel-survivor-game/game-demo/
│
├── icon.svg                      # 项目图标（Godot应用图标）
├── project.godot                 # Godot 项目配置文件（分辨率、自动加载、输入映射等）
│
├── assets/                       # ★ 所有美术/音频资源根目录
│   ├── audio/                    # 音效与背景音乐
│   │   ├── bgm_battle.wav        #   战斗BGM（共3个变体）
│   │   ├── bgm_battle1.wav
│   │   ├── bgm_battle2.wav
│   │   ├── bgm_battle3.wav
│   │   ├── bgm_boss.wav          #   Boss战BGM
│   │   ├── bgm_gameover.wav      #   游戏结束BGM
│   │   ├── bgm_menu.wav          #   菜单BGM
│   │   ├── bgm_victory.wav       #   胜利BGM
│   │   ├── sfx_boss_appear.wav   #   Boss出场音效
│   │   ├── sfx_boss_intro.wav    #   Boss介绍音效
│   │   ├── sfx_coin.wav          #   拾取金币音效
│   │   ├── sfx_confirm.wav       #   确认操作音效
│   │   ├── sfx_death.wav         #   玩家死亡音效
│   │   ├── sfx_enemy_die.wav     #   敌人死亡音效
│   │   ├── sfx_explosion.wav     #   爆炸音效
│   │   ├── sfx_gameover.wav      #   游戏结束音效
│   │   ├── sfx_heal.wav          #   治疗音效
│   │   ├── sfx_hit.wav           #   命中音效
│   │   ├── sfx_levelup.wav       #   升级音效
│   │   ├── sfx_pickup.wav        #   拾取道具音效
│   │   ├── sfx_player_hit.wav    #   玩家受伤音效
│   │   ├── sfx_select.wav        #   选择音效
│   │   ├── sfx_shoot.wav         #   射击音效
│   │   └── sfx_victory.wav       #   胜利音效
│   │
│   ├── fonts/                    # 字体目录（当前为空，可能使用系统默认字体）
│   │
│   └── images/                   # ★ 所有图片资源（重点替换区域）
│       ├── characters/           # 【角色精灵图】
│       │   ├── player_maphy.png      # 角色：玛菲
│       │   ├── player_minami.png     # 角色：美波
│       │   ├── player_yuria.png      # 角色：尤利娅
│       │   ├── player_sakura.png     # 角色：樱
│       │   ├── player_kanna.png      # 角色：栞那
│       │   ├── player_kiko.png       # 角色：绮子
│       │   ├── player_kureha.png     # 角色：暮叶
│       │   ├── player_miho.png       # 角色：美穗
│       │   └── player_mika.png       # 角色：米卡
│       │
│       ├── bosses/               # 【Boss精灵图】
│       │   ├── boss_sakura.png       # Boss：樱
│       │   ├── boss_miho.png         # Boss：美穗
│       │   ├── boss_kanna.png        # Boss：栞那
│       │   ├── boss_kiko.png         # Boss：绮子
│       │   └── boss_kureha.png       # Boss：暮叶
│       │
│       ├── enemies/              # 【敌人精灵图】
│       │   ├── brainless_basic.png   # 普通敌人
│       │   ├── brainless_fast.png    # 快速敌人
│       │   ├── brainless_tank.png    # 重装敌人
│       │   └── brainless_ranged.png  # 远程敌人
│       │
│       ├── weapons/              # 【武器精灵图/弹道图】
│       │   ├── axe.png               # 消防斧
│       │   ├── baseball.png          # 棒球
│       │   ├── bullet_pistol.png     # 手枪子弹
│       │   ├── bullet_sniper.png     # 狙击子弹
│       │   ├── dagger.png            # 飞刀
│       │   ├── drone.png             # 无人机
│       │   ├── fire.png              # 喷火器
│       │   ├── fireroad.png          # 火焰路径
│       │   ├── grenade.png           # 手榴弹
│       │   ├── holywater.png         # 圣水
│       │   ├── matrix.png            # 矩阵
│       │   ├── missile.png           # 导弹
│       │   ├── orbital.png           # 轨道炮
│       │   ├── pulse.png             # 脉冲
│       │   ├── star.png              # 星星
│       │   └── talisman.png          # 符咒
│       │
│       ├── effects/              # 【特效精灵图】
│       │   ├── death.png             # 死亡特效
│       │   ├── explosion.png         # 爆炸特效
│       │   ├── heal.png              # 治疗特效
│       │   ├── hit.png               # 命中特效
│       │   └── levelup.png           # 升级特效
│       │
│       ├── items/                # 【道具精灵图】
│       │   ├── chest.png             # 宝箱
│       │   ├── coin.png              # 金币
│       │   ├── exp_gem_blue.png      # 蓝色经验宝石
│       │   ├── exp_gem_green.png     # 绿色经验宝石
│       │   ├── exp_gem_red.png       # 红色经验宝石
│       │   ├── heal_orb.png          # 治疗球
│       │   └── passive_*.png (×16)   # 16个被动道具精灵图
│       │
│       ├── pickups/              # 【拾取物精灵图】
│       │   ├── chest.png             # 宝箱
│       │   ├── coin.png              # 金币
│       │   ├── exp_gem.png           # 经验宝石
│       │   └── heal.png              # 治疗球
│       │
│       ├── maps/                 # 【地图瓦片贴图】
│       │   ├── tile_stone.png        # 废弃城市（石质）
│       │   ├── tile_grass.png        # 公路（草地）
│       │   ├── tile_sand.png         # 荒原（沙地）
│       │   ├── tile_forest.png       # 森林
│       │   ├── tile_dark.png         # 暗色瓦片（备用）
│       │   ├── tile_dirt.png         # 泥土瓦片（备用）
│       │   └── tile_road.png         # 道路瓦片（备用）
│       │
│       └── ui/                   # 【UI界面素材】
│           ├── button_normal.png     # 按钮-普通状态
│           ├── button_hover.png      # 按钮-悬停状态
│           ├── button_pressed.png    # 按钮-按下状态
│           ├── coin_icon.png         # 金币图标
│           ├── exp_bar.png           # 经验条
│           ├── health_bar.png        # 血条
│           ├── heart_icon.png        # 心形图标
│           ├── logo.png              # 游戏Logo
│           ├── panel_bg.png          # 面板背景
│           ├── icons/
│           │   ├── weapons/          # 武器图标（16个）
│           │   │   └── icon_weapon_*.png
│           │   └── passives/         # 被动道具图标（16个）
│           │       └── icon_passive_*.png
│           └── portraits/            # 角色头像/立绘（9个）
│               └── portrait_*.png
│
├── scenes/                       # Godot 场景文件（.tscn）
│   ├── game.tscn                     # 主游戏战斗场景
│   ├── main_menu.tscn                # 主菜单场景
│   ├── map_select.tscn               # 地图选择场景
│   ├── splash_screen.tscn            # 启动画面场景
│   └── title_screen.tscn             # 标题屏幕场景
│
└── scripts/                      # GDScript 脚本文件
    ├── autoload/                 # 【全局自动加载脚本】
    │   ├── audio_manager.gd          # 音频管理器（BGM/SFX播放控制）
    │   ├── database.gd              # ★ 游戏数据库（所有角色/武器/敌人/Boss/地图数据定义）
    │   ├── dialogue_manager.gd       # 对话管理器
    │   ├── display_manager.gd        # 显示管理器（窗口/分辨率）
    │   ├── game_manager.gd           # 游戏管理器（核心游戏流程）
    │   ├── global_save.gd            # 全局存档
    │   ├── network_manager.gd        # 网络管理器（后端通信）
    │   └── save_manager.gd           # 存档管理器
    │
    ├── utils/                    # 【工具脚本】
    │   └── anim_helper.gd            # 动画辅助工具
    │
    ├── player.gd                 # 玩家角色控制
    ├── enemy_base.gd             # 敌人基础行为
    ├── enemy_spawner.gd          # 敌人生成器
    ├── boss.gd                   # Boss行为逻辑
    ├── boss_health_bar.gd        # Boss血条UI
    ├── projectile.gd             # 投射物/弹道
    ├── weapon_manager.gd         # 武器管理器
    ├── melee_attack.gd           # 近战攻击
    ├── pickup.gd                 # 拾取物逻辑
    ├── coin_pickup.gd            # 金币拾取
    ├── damage_number.gd          # 伤害数字显示
    ├── minimap.gd                # 小地图
    ├── hud.gd                    # HUD界面（血条/经验条/金币等）
    ├── level_up_ui.gd            # 升级选择界面
    ├── codex_ui.gd               # 图鉴界面
    ├── game_over_ui.gd           # 游戏结束界面
    ├── victory_settlement_ui.gd  # 胜利结算界面
    ├── pause_menu.gd             # 暂停菜单
    ├── settings_ui.gd            # 设置界面
    ├── main_menu.gd              # 主菜单逻辑
    ├── map_select.gd             # 地图选择逻辑
    ├── title_screen.gd           # 标题画面逻辑
    ├── splash_screen.gd          # 启动画面逻辑
    ├── login_ui.gd               # 登录界面
    └── dialogue_ui.gd            # 对话界面
```

---

## 🎨 美术资源替换指南与推荐

### 一、资源引用方式

所有美术资源路径都硬编码在 `scripts/autoload/database.gd` 中，使用 Godot 的 `res://` 路径格式。替换资源时 **只需同名覆盖文件即可**，无需修改代码。

### 二、各类别替换建议

#### 1. 🧑 角色精灵图 (`assets/images/characters/`)
| 文件 | 当前尺寸建议 | 替换建议 |
|------|-------------|---------|
| `player_*.png` (9个) | 32×32 或 48×48 像素 | **推荐使用 Spritesheet（序列帧图）**，将角色的行走/待机/攻击动画帧水平排列。保持文件名不变，替换后在 Godot 中重新配置 SpriteFrames |

**推荐资源来源：**
- [itch.io - Pixel Character Sprites](https://itch.io/game-assets/tag-characters/tag-pixel-art)
- [OpenGameArt](https://opengart.org)
- 建议尺寸：**32×32** 或 **48×48** 每帧，风格统一为俯视角像素风格

#### 2. 👹 敌人精灵图 (`assets/images/enemies/`)
| 文件 | 替换建议 |
|------|---------|
| `brainless_basic/fast/tank/ranged.png` (4个) | 像素风怪物精灵，建议 32×32，用不同颜色/造型区分类型 |

**推荐风格：** 无脑僵尸/史莱姆/骷髅等经典俯视角敌人

#### 3. 🐉 Boss精灵图 (`assets/images/bosses/`)
| 文件 | 替换建议 |
|------|---------|
| `boss_*.png` (5个) | 建议 **64×64** 或 **96×96** 像素，需要比普通敌人明显更大、更有气势 |

**推荐：** 用角色的"暴走/暗黑"版本造型，与角色形成对比

#### 4. ⚔️ 武器精灵图 (`assets/images/weapons/`)
| 文件 | 替换建议 |
|------|---------|
| `bullet_pistol.png`, `bullet_sniper.png` | 小尺寸弹道图，建议 **8×8** 或 **16×16** |
| `axe.png`, `dagger.png`, `baseball.png` | 武器本体图，建议 **16×16** 或 **24×24** |
| `fire.png`, `fireroad.png` | 火焰特效，建议 **16×16**，可使用 SpriteSheet |
| `drone.png`, `missile.png`, `orbital.png` | 科技感武器，建议 **16×16 ~ 24×24** |
| `talisman.png`, `holywater.png`, `star.png` | 魔法系武器，建议 **16×16**，带发光效果 |
| `grenade.png`, `matrix.png`, `pulse.png` | 爆炸/范围系，建议 **16×16** |

#### 5. 🗺️ 地图瓦片 (`assets/images/maps/`)
| 文件 | 替换建议 |
|------|---------|
| `tile_stone.png` → 废弃城市 | 石质/水泥/废墟纹理 |
| `tile_grass.png` → 公路 | 草地/泥土混合 |
| `tile_sand.png` → 荒原 | 沙漠/干旱地面 |
| `tile_forest.png` → 森林 | 深色草地/苔藓 |

**关键要求：** 必须是 **可无缝平铺（seamless tileable）** 的纹理，建议 **16×16** 或 **32×32**

#### 6. 📦 道具与拾取物 (`assets/images/items/` + `assets/images/pickups/`)
- 经验宝石（蓝/绿/红）：建议 **8×8 ~ 16×16**，用颜色区分价值
- 金币：**8×8 ~ 16×16**，金黄色圆形
- 治疗球：**16×16**，绿色/粉红色发光球
- 被动道具图标（16个）：**16×16**，每个代表一种属性（护甲、伤害、速度等）

#### 7. ✨ 特效图 (`assets/images/effects/`)
| 文件 | 替换建议 |
|------|---------|
| `death.png`, `explosion.png`, `hit.png` | **SpriteSheet 序列帧**，16×16 ~ 32×32 每帧 |
| `heal.png`, `levelup.png` | 上升/扩散动画序列帧 |

#### 8. 🖼️ UI素材 (`assets/images/ui/`)
| 文件 | 替换建议 |
|------|---------|
| `button_*.png` (3个状态) | 按钮 9-patch 图，建议 **128×32** 或 **96×32** |
| `health_bar.png`, `exp_bar.png` | 进度条贴图，**256×16** 或 **128×8** |
| `coin_icon.png`, `heart_icon.png` | 小图标 **16×16 ~ 24×24** |
| `logo.png` | 游戏Logo，**256×128** 或更大 |
| `panel_bg.png` | 面板背景，**256×256** 9-patch 格式 |
| `icons/weapons/icon_weapon_*.png` (16个) | 武器图标 **32×32** |
| `icons/passives/icon_passive_*.png` (16个) | 被动道具图标 **32×32** |
| `portraits/portrait_*.png` (9个) | 角色头像 **64×64** 或 **96×96** |

### 三、替换操作流程

1. **准备新素材**：确保与原图相同的文件名和格式（.png）
2. **直接覆盖**：将新图片放入对应目录，覆盖旧文件（同名替换）
3. **删除 .import 文件**：删除同名的 `.png.import` 文件，让 Godot 重新导入
4. **在 Godot 编辑器中打开项目**：Godot 会自动重新导入所有资源
5. **检查动画配置**：如果使用了 SpriteSheet/AnimatedSprite，需要在 Godot 中重新配置帧动画
6. **测试运行**：检查所有场景中资源显示是否正常

### 四、免费像素美术资源推荐网站

| 网站 | 说明 |
|------|------|
| **[itch.io/game-assets](https://itch.io/game-assets/free/tag-pixel-art)** | 最大的免费游戏素材平台 |
| **[OpenGameArt.org](https://opengart.org)** | 开源游戏素材库 |
| **[Kenney.nl](https://kenney.nl)** | 高质量免费游戏素材 |
| **[itch.io - Vampire Survivors Style](https://itch.io/game-assets/tag-pixel-art/tag-vampire-survivors)** | 类幸存者风格素材 |
| **[Craftpix.net](https://craftpix.net/freebies/)** | 部分免费素材 |

### 五、特别注意

- `database.gd` 中还引用了一个 `boss_butcher.png`，但在 bosses 目录中 **实际不存在** 该文件，可能需要补充
- `player_mika.png` 存在于 characters 目录中，但 `database.gd` 中引用了它（路径 `res://assets/images/characters/player_mika.png`）
- 音频文件（`.wav`）也可以替换，保持文件名不变即可，推荐使用 `.ogg` 格式以减小文件体积