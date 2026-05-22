# 数据库设计文档

## 1. 概述

- **数据库**：MySQL 8.0
- **字符集**：utf8mb4
- **排序规则**：utf8mb4_general_ci
- **存储引擎**：InnoDB
- **数据库名**：pixel_survivor
- **初始化脚本**：`backend/sql/init.sql`

## 2. ER 关系图

```
t_user (用户账号)
  ├── 1:1 → t_user_save_data (全局存档JSON)
  ├── 1:N → t_user_character (角色解锁/强化)
  └── 1:N → t_user_achievement (成就进度)

t_admin (管理员)
  └── 1:N → t_admin_operation_log (操作日志)

t_character_definition (角色定义元数据，9个角色)
t_map_definition (地图定义元数据，4个地图)
t_shop_item (商品运营数据，10个商品)
```

## 3. 表结构详细设计

---

### 3.1 t_user -- 用户表

存储玩家账号的基本信息和游戏统计数据。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 用户ID |
| username | VARCHAR(50) | UNIQUE, NOT NULL | - | 用户名 |
| password | VARCHAR(255) | NOT NULL | - | 密码 (BCrypt加密) |
| nickname | VARCHAR(50) | - | NULL | 昵称 |
| avatar_url | VARCHAR(255) | - | NULL | 头像URL |
| email | VARCHAR(100) | - | NULL | 邮箱 (预留字段) |
| game_coin | INT | - | 0 | 游戏币余额 |
| diamond | INT | - | 0 | 钻石余额 |
| level | INT | - | 1 | 等级 |
| exp | INT | - | 0 | 经验值 |
| total_play_time | INT | - | 0 | 总游戏时长 (秒) |
| max_wave | INT | - | 0 | 最高波数记录 |
| status | TINYINT | - | 1 | 状态: 1正常, 0封禁 |
| is_online | TINYINT | - | 0 | 是否在线: 1在线, 0离线 |
| last_login_at | DATETIME | - | NULL | 最后登录时间 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 注册时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：
- `idx_username` ON (username)
- `idx_status` ON (status)

**注册默认值**：新用户赠送 500 游戏币 + 50 钻石，昵称默认为"像素冒险家"。

---

### 3.2 t_admin -- 管理员表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 管理员ID |
| username | VARCHAR(50) | UNIQUE, NOT NULL | - | 账号 |
| password | VARCHAR(255) | NOT NULL | - | 密码 (BCrypt加密) |
| role | VARCHAR(20) | - | 'ADMIN' | 角色: SUPER_ADMIN / ADMIN |
| status | TINYINT | - | 1 | 状态: 1正常, 0禁用 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**初始数据**：超级管理员 admin / admin123（BCrypt加密）

---

### 3.3 t_user_save_data -- 用户全局存档表

将游戏全部进度以 JSON 字符串形式存储，实现多设备数据同步。通过 userId 与 t_user 一对一关联。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键ID |
| user_id | BIGINT | UNIQUE, NOT NULL | - | 用户ID |
| save_data | LONGTEXT | NOT NULL | - | 存档JSON数据 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：`uk_user_id` UNIQUE ON (user_id)

**save_data JSON 结构示例**：
```json
{
  "coins": 1500,
  "diamonds": 60,
  "unlocked_characters": ["maphy", "minami", "yuria"],
  "character_levels": {"maphy": 3, "minami": 2, "yuria": 1},
  "unlocked_maps": ["tutorial", "endless_road"],
  "completed_maps": ["tutorial"],
  "unlocked_achievements": ["first_blood", "first_win"]
}
```

---

### 3.4 t_user_character -- 用户角色表

记录玩家解锁的角色及其强化数据。character_code对应 database.gd 中的角色ID。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | NOT NULL | - | 用户ID |
| character_code | VARCHAR(50) | NOT NULL | - | 角色编码 (如 maphy) |
| is_selected | TINYINT | - | 0 | 是否当前选中 |
| level | INT | - | 1 | 角色等级 |
| hp_upgrade | INT | - | 0 | 生命强化次数 |
| atk_upgrade | INT | - | 0 | 攻击强化次数 |
| def_upgrade | INT | - | 0 | 防御强化次数 |
| speed_upgrade | INT | - | 0 | 移速强化次数 |
| combat_power | INT | - | 0 | 战力 |
| acquired_at | DATETIME | - | CURRENT_TIMESTAMP | 获取时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：`uk_user_char` UNIQUE ON (user_id, character_code)

---

### 3.5 t_user_achievement -- 用户成就进度表

记录玩家的成就进度和领取状态。achievement_code 对应成就ID。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | NOT NULL | - | 用户ID |
| achievement_code | VARCHAR(50) | NOT NULL | - | 成就编码 (如 first_blood) |
| progress | INT | - | 0 | 当前进度 |
| is_completed | TINYINT | - | 0 | 是否完成 |
| is_rewarded | TINYINT | - | 0 | 是否已领奖 |
| completed_at | DATETIME | - | NULL | 完成时间 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：
- `uk_user_ach` UNIQUE ON (user_id, achievement_code)
- `idx_user_id` ON (user_id)

---

### 3.6 t_admin_operation_log -- 管理员操作日志表

通过 AOP 切面（OperationLogAspect）自动记录管理端的每一次操作，用于审计追溯。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 日志ID |
| admin_id | BIGINT | NOT NULL | - | 管理员ID |
| admin_username | VARCHAR(50) | NOT NULL | - | 管理员用户名 |
| module | VARCHAR(50) | NOT NULL | - | 操作模块 (如 用户管理、管理员管理) |
| operation | VARCHAR(50) | NOT NULL | - | 操作类型 (如 CREATE、UPDATE、DELETE) |
| description | VARCHAR(200) | NOT NULL | - | 操作描述 (如 封禁用户) |
| method | VARCHAR(200) | - | NULL | 请求方法 (类名.方法名) |
| params | TEXT | - | NULL | 请求参数JSON (截断至1000字符) |
| response | TEXT | - | NULL | 响应结果JSON (截断至1000字符) |
| ip | VARCHAR(50) | - | NULL | 操作IP |
| error_msg | TEXT | - | NULL | 异常信息 |
| cost_time | BIGINT | - | 0 | 耗时 (毫秒) |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 操作时间 |

**索引**：
- `idx_admin_id` ON (admin_id)
- `idx_module` ON (module)
- `idx_created_at` ON (created_at)

---

### 3.7 t_character_definition -- 角色定义表

存储所有 9 个角色的元数据，作为服务端可控的角色定义（与 database.gd 数据保持一致）。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| char_code | VARCHAR(50) | UNIQUE, NOT NULL | - | 唯一业务标识 (如 maphy) |
| char_name | VARCHAR(100) | NOT NULL | - | 角色中文名 (如 玛菲) |
| char_name_en | VARCHAR(100) | - | NULL | 角色英文名 (如 Maphy) |
| description | VARCHAR(500) | - | NULL | 角色描述 |
| max_hp | INT | NOT NULL | 100 | 基础生命上限 |
| speed | FLOAT | NOT NULL | 200.0 | 基础移动速度 |
| armor | FLOAT | NOT NULL | 0 | 基础护甲 |
| damage_mult | FLOAT | NOT NULL | 1.0 | 伤害倍率 |
| cooldown_mult | FLOAT | NOT NULL | 1.0 | 冷却倍率 |
| crit_chance | FLOAT | NOT NULL | 0.05 | 暴击率 |
| crit_damage | FLOAT | NOT NULL | 1.5 | 暴击伤害 |
| luck | FLOAT | NOT NULL | 1.0 | 幸运值 |
| growth | FLOAT | NOT NULL | 1.0 | 成长值 |
| greed | FLOAT | NOT NULL | 1.0 | 贪婪值 |
| magnet_range | FLOAT | NOT NULL | 50.0 | 拾取范围 |
| starting_weapon | VARCHAR(50) | - | NULL | 初始武器编码 (如 pistol) |
| passive | VARCHAR(50) | - | NULL | 被动技能编码 |
| unlock_cost | INT | - | 0 | 解锁所需金币 (0=免费) |
| unlock_condition | VARCHAR(200) | - | NULL | 解锁条件描述 (NULL=默认解锁) |
| is_active | TINYINT | - | 1 | 是否启用 (1启用, 0弃用) |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**初始数据（9个角色）**：

| char_code | 角色名 | 类型 | HP | 速度 | 初始武器 | 被动 | 解锁 |
|-----------|--------|------|-----|------|---------|------|------|
| maphy | 玛菲 | 标准型 | 100 | 200 | 手枪 | - | 默认 |
| minami | 美波 | 高速型 | 80 | 260 | 飞刀 | 移速 | 默认 |
| yuria | 尤利娅 | 重装型 | 150 | 170 | 消防斧 | 护甲 | 默认 |
| sakura | 樱 | 攻击型 | 90 | 200 | 狙击步枪 | 力量 | 通关公路 |
| kanna | 栞那 | 魔法型 | 85 | 210 | 符咒 | 冷却 | 500金币 |
| kiko | 绮子 | 幸运型 | 90 | 200 | 棒球 | 幸运 | 800金币 |
| kureha | 暮叶 | 恢复型 | 110 | 200 | 圣水 | 恢复 | 1000金币 |
| miho | 美穗 | 成长型 | 95 | 200 | 手榴弹 | 成长 | 1500金币 |
| mika | 米卡 | 全能型 | 120 | 230 | 星星 | 暴击 | 2000金币 |

---

### 3.8 t_map_definition -- 地图定义表

存储所有 4 个地图（关卡）的元数据。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| map_code | VARCHAR(50) | UNIQUE, NOT NULL | - | 唯一业务标识 (如 endless_road) |
| map_name | VARCHAR(100) | NOT NULL | - | 地图名称 (如 公路) |
| chapter | INT | - | 1 | 所属章节 |
| order_index | INT | - | 0 | 章节内排序 |
| required_map_code | VARCHAR(50) | - | NULL | 解锁前置地图编码 (NULL=初始即可见) |
| is_active | TINYINT | - | 1 | 是否启用 (1启用, 0弃用) |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**初始数据（4个地图）**：

| map_code | 地图名 | 章节 | 前置地图 | 说明 |
|----------|--------|------|---------|------|
| tutorial | 废弃城市 | 0 | 无 | 新手教学关卡，3分钟限时 |
| endless_road | 公路 | 1 | tutorial | 主线，Boss: 血樱妖姬 |
| wasteland | 荒原 | 1 | endless_road | 支线，Boss: 烈焰狂鬼 |
| crimson_forest | 森林 | 1 | wasteland | 终章，Boss: 幽冥魔导 |

---

### 3.9 t_shop_item -- 商品表

仅存储商品运营数据（价格、库存、上下架状态），商品名称和描述由游戏客户端 database.gd 定义。

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| item_code | VARCHAR(50) | UNIQUE, NOT NULL | - | 商品编码 (如 item_heal_potion) |
| price_coin | INT | - | 0 | 游戏币价格 (0=不可用金币购买) |
| price_diamond | INT | - | 0 | 钻石价格 (0=不可用钻石购买) |
| stock | INT | - | -1 | 库存 (-1=无限) |
| max_buy_count | INT | - | -1 | 每人限购 (-1=无限) |
| status | TINYINT | - | 1 | 状态: 1上架, 0下架 |
| sort_order | INT | - | 0 | 排序权重 |
| start_time | DATETIME | - | NULL | 上架开始时间 (NULL=永久) |
| end_time | DATETIME | - | NULL | 上架结束时间 (NULL=永久) |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：
- `idx_status` ON (status)
- `idx_item_code` ON (item_code)

**初始数据（10个商品）**：

| item_code | 金币价格 | 钻石价格 | 限购 | 说明 |
|-----------|---------|---------|------|------|
| item_heal_potion | 100 | 0 | 无限 | 治疗药水 |
| item_super_heal_potion | 300 | 10 | 无限 | 超级治疗药水 |
| item_shield | 200 | 0 | 无限 | 护盾 |
| item_atk_boost | 150 | 0 | 无限 | 攻击力提升 |
| item_speed_boost | 120 | 0 | 无限 | 移速提升 |
| item_revive_token | 0 | 50 | 每人3个 | 复活令牌 |
| item_exp_boost | 0 | 30 | 每人5个 | 经验加成 |
| item_coin_magnet | 250 | 0 | 无限 | 金币磁铁 |
| pack_starter | 0 | 88 | 每人1个 | 新手礼包 |
| pack_advanced | 0 | 288 | 每人1个 | 高级礼包 |

> **注意**：商城系统目前仅有数据库表定义及初始数据，游戏客户端尚未实现完整的商城购买流程。

---

## 4. 表关系汇总

| 关系 | 类型 | 说明 |
|------|------|------|
| t_user → t_user_save_data | 1:1 | 每个用户最多一份全局存档JSON |
| t_user → t_user_character | 1:N | 用户解锁多个角色及其强化数据 |
| t_user → t_user_achievement | 1:N | 用户有多个成就进度记录 |
| t_admin → t_admin_operation_log | 1:N | 管理员的所有操作日志 |
| t_character_definition | 独立元数据 | 9个角色定义，供管理端查询 |
| t_map_definition | 独立元数据 | 4个地图定义，供管理端查询 |
| t_shop_item | 独立元数据 | 10个商品运营数据 |

## 5. 初始化说明

完整的建表和数据初始化脚本位于 `backend/sql/init.sql`，包含：

- 9 个表的 CREATE TABLE 语句
- 1 个默认超级管理员插入 (admin / admin123)
- 9 个角色定义数据插入
- 4 个地图定义数据插入
- 10 个商品数据插入

执行方式：连接 MySQL 后直接运行 `source backend/sql/init.sql` 或者在 Navicat/DataGrip 中执行该 SQL 文件。
