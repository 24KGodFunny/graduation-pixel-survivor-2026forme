# 数据库设计文档

## 1. 概述

- **数据库**：MySQL 8.0
- **字符集**：utf8mb4
- **排序规则**：utf8mb4_general_ci
- **存储引擎**：InnoDB
- **连接信息**：用户名 root，密码 1234
- **数据库名**：pixel_survivor

## 2. ER关系图（文字描述）

```
t_user (用户)
  ├── 1:N → t_user_item (背包)
  ├── 1:N → t_purchase_record (购买记录)
  ├── 1:N → t_recharge_record (充值记录)
  ├── 1:N → t_game_record (游戏记录)
  ├── 1:N → t_user_character (拥有的角色)
  ├── 1:N → t_user_achievement (成就进度)
  ├── 1:N → t_daily_sign (签到记录)
  ├── 1:N → t_user_daily_task (任务进度)
  ├── 1:N → t_mail (邮件)
  ├── 1:N → t_ranking (排行榜)
  ├── N:N → t_friend (好友关系)
  └── 1:N → t_friend_request (好友请求)

t_admin (管理员)
  └── 1:N → t_admin_operation_log (操作日志)

t_shop_item (商品)
  ├── 1:N → t_user_item (背包)
  └── 1:N → t_purchase_record (购买记录)

t_character (角色)
  └── 1:N → t_user_character (用户角色)

t_achievement (成就定义)
  └── 1:N → t_user_achievement (用户成就)

t_daily_task (任务定义)
  └── 1:N → t_user_daily_task (用户任务)

t_buff_definition (Buff定义)
t_map (地图)
```

## 3. 表结构详细设计

### 3.1 t_user — 用户表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 用户ID |
| username | VARCHAR(50) | UNIQUE, NOT NULL | - | 用户名 |
| password | VARCHAR(255) | NOT NULL | - | 密码(BCrypt) |
| nickname | VARCHAR(50) | - | NULL | 昵称 |
| avatar_url | VARCHAR(255) | - | NULL | 头像URL |
| email | VARCHAR(100) | - | NULL | 邮箱 |
| game_coin | INT | - | 0 | 游戏币余额 |
| diamond | INT | - | 0 | 钻石余额 |
| level | INT | - | 1 | 等级 |
| exp | INT | - | 0 | 经验值 |
| total_play_time | INT | - | 0 | 总游戏时长(秒) |
| max_wave | INT | - | 0 | 最高波数记录 |
| status | TINYINT | - | 1 | 1正常 0封禁 |
| is_online | TINYINT | - | 0 | 是否在线 |
| last_login_at | DATETIME | - | NULL | 最后登录时间 |
| offline_coin | INT | - | 0 | 离线累积游戏币 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 注册时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：
- `idx_username` ON (username)
- `idx_status` ON (status)

**初始数据**：注册时赠送100游戏币

---

### 3.2 t_admin — 管理员表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 管理员ID |
| username | VARCHAR(50) | UNIQUE, NOT NULL | - | 账号 |
| password | VARCHAR(255) | NOT NULL | - | 密码(BCrypt) |
| role | VARCHAR(20) | - | 'ADMIN' | SUPER_ADMIN / ADMIN |
| status | TINYINT | - | 1 | 1正常 0禁用 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**初始数据**：
- 超级管理员：admin / admin123（BCrypt加密）

---

### 3.3 t_shop_item — 商品表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 商品ID |
| name | VARCHAR(100) | NOT NULL | - | 商品名称 |
| description | TEXT | - | NULL | 商品描述 |
| item_type | TINYINT | NOT NULL | - | 1皮肤 2武器 3消耗道具 4礼包 5通行证 |
| price_coin | INT | - | 0 | 游戏币价格 |
| price_diamond | INT | - | 0 | 钻石价格 |
| image_url | VARCHAR(255) | - | NULL | 商品图片 |
| rarity | TINYINT | - | 1 | 1普通 2稀有 3史诗 4传说 |
| stock | INT | - | -1 | 库存(-1无限) |
| max_buy_count | INT | - | -1 | 每人限购(-1无限) |
| effect_type | VARCHAR(50) | - | NULL | 效果类型 |
| effect_value | INT | - | NULL | 效果数值 |
| effect_duration | INT | - | NULL | 效果持续时间(秒) |
| status | TINYINT | - | 1 | 1上架 0下架 |
| sort_order | INT | - | 0 | 排序权重 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：
- `idx_type_status` ON (item_type, status)

**effect_type 枚举值**：
- `heal` — 回复生命
- `shield` — 护盾
- `atk_boost` — 攻击力提升
- `speed_boost` — 移速提升
- `exp_boost` — 经验加成
- `coin_boost` — 游戏币加成

---

### 3.4 t_user_item — 用户背包表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| item_id | BIGINT | FK → t_shop_item.id, NOT NULL | - | 商品ID |
| quantity | INT | - | 1 | 数量 |
| is_equipped | TINYINT | - | 0 | 是否装备 |
| acquired_at | DATETIME | - | CURRENT_TIMESTAMP | 获取时间 |

**索引**：
- `idx_user_id` ON (user_id)
- `idx_user_item` ON (user_id, item_id)

---

### 3.5 t_purchase_record — 购买记录表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 记录ID |
| order_no | VARCHAR(64) | UNIQUE, NOT NULL | - | 订单号 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| item_id | BIGINT | FK → t_shop_item.id, NOT NULL | - | 商品ID |
| item_name | VARCHAR(100) | - | NULL | 商品名(冗余) |
| quantity | INT | - | 1 | 购买数量 |
| total_price | INT | NOT NULL | - | 总价 |
| pay_type | TINYINT | NOT NULL | - | 1游戏币 2钻石 |
| status | TINYINT | - | 1 | 0待支付 1成功 2失败 3退款 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 购买时间 |

**索引**：
- `idx_user_id` ON (user_id)
- `idx_created_at` ON (created_at)

**订单号生成规则**：`PUR` + yyyyMMddHHmmss + 6位随机数

---

### 3.6 t_recharge_record — 充值记录表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 记录ID |
| order_no | VARCHAR(64) | UNIQUE, NOT NULL | - | 充值订单号 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| amount | DECIMAL(10,2) | NOT NULL | - | 充值金额(元) |
| diamond_count | INT | NOT NULL | - | 获得钻石 |
| bonus_diamond | INT | - | 0 | 赠送钻石 |
| status | TINYINT | - | 0 | 0待支付 1成功 2失败 |
| pay_channel | VARCHAR(20) | - | NULL | alipay/wechat |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 充值时间 |

**索引**：
- `idx_user_id` ON (user_id)

**订单号生成规则**：`RCH` + yyyyMMddHHmmss + 6位随机数

---

### 3.7 t_friend — 好友关系表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| friend_id | BIGINT | FK → t_user.id, NOT NULL | - | 好友ID |
| status | TINYINT | - | 1 | 1已确认 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**索引**：
- `uk_friendship` UNIQUE ON (user_id, friend_id)
- `idx_user_id` ON (user_id)
- `idx_friend_id` ON (friend_id)

**说明**：好友关系为双向存储，A加B为好友时插入两条记录(A,B)和(B,A)

---

### 3.8 t_friend_request — 好友请求表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| from_user_id | BIGINT | FK → t_user.id, NOT NULL | - | 发起者ID |
| to_user_id | BIGINT | FK → t_user.id, NOT NULL | - | 接收者ID |
| message | VARCHAR(200) | - | '' | 附言 |
| status | TINYINT | - | 0 | 0待处理 1同意 2拒绝 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 请求时间 |

**索引**：
- `idx_to_user` ON (to_user_id, status)

---

### 3.9 t_admin_operation_log — 管理员操作日志表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 日志ID |
| admin_id | BIGINT | FK → t_admin.id, NOT NULL | - | 管理员ID |
| admin_username | VARCHAR(50) | - | NULL | 管理员用户名(冗余) |
| operation | VARCHAR(50) | NOT NULL | - | CREATE/UPDATE/DELETE/LOGIN/EXPORT |
| module | VARCHAR(50) | NOT NULL | - | 操作模块 |
| target_type | VARCHAR(50) | - | NULL | 操作对象类型 |
| target_id | VARCHAR(50) | - | NULL | 操作对象ID |
| detail | TEXT | - | NULL | 操作详情(JSON) |
| ip_address | VARCHAR(50) | - | NULL | 操作IP |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 操作时间 |

**索引**：
- `idx_admin_id` ON (admin_id)
- `idx_created_at` ON (created_at)

---

### 3.10 t_character — 角色表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 角色ID |
| name | VARCHAR(50) | NOT NULL | - | 角色名 |
| description | TEXT | - | NULL | 角色描述 |
| sprite_url | VARCHAR(255) | - | NULL | 角色立绘 |
| base_hp | INT | - | 100 | 基础生命 |
| base_atk | INT | - | 10 | 基础攻击 |
| base_def | INT | - | 5 | 基础防御 |
| base_speed | FLOAT | - | 150.0 | 基础移速 |
| special_ability | VARCHAR(200) | - | NULL | 特殊技能描述 |
| unlock_type | TINYINT | - | 0 | 0默认 1等级 2钻石 3成就 |
| unlock_value | INT | - | 0 | 解锁条件值 |
| price_diamond | INT | - | 0 | 钻石价格 |
| status | TINYINT | - | 1 | 1正常 0禁用 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

---

### 3.11 t_user_character — 用户角色表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| character_id | BIGINT | FK → t_character.id, NOT NULL | - | 角色ID |
| is_selected | TINYINT | - | 0 | 是否当前选用 |
| level | INT | - | 1 | 角色等级 |
| hp_upgrade | INT | - | 0 | 生命强化次数 |
| atk_upgrade | INT | - | 0 | 攻击强化次数 |
| def_upgrade | INT | - | 0 | 防御强化次数 |
| speed_upgrade | INT | - | 0 | 移速强化次数 |
| acquired_at | DATETIME | - | CURRENT_TIMESTAMP | 获取时间 |

**索引**：
- `uk_user_char` UNIQUE ON (user_id, character_id)

---

### 3.12 t_game_record — 游戏局记录表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 记录ID |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| character_id | BIGINT | FK → t_character.id | NULL | 使用角色 |
| map_id | INT | - | NULL | 地图ID |
| wave_reached | INT | - | 0 | 到达波数 |
| kill_count | INT | - | 0 | 击杀数 |
| boss_kill_count | INT | - | 0 | Boss击杀数 |
| exp_gained | INT | - | 0 | 获得经验 |
| coin_gained | INT | - | 0 | 获得游戏币 |
| play_duration | INT | - | 0 | 游戏时长(秒) |
| is_cleared | TINYINT | - | 0 | 是否通关 |
| death_reason | VARCHAR(50) | - | NULL | 死亡原因 |
| buffs_used | TEXT | - | NULL | 选择的buff(JSON) |
| items_used | TEXT | - | NULL | 使用的道具(JSON) |
| score | INT | - | 0 | 本局积分 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**索引**：
- `idx_user_id` ON (user_id)
- `idx_wave` ON (wave_reached)
- `idx_score` ON (score)

---

### 3.13 t_achievement — 成就定义表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 成就ID |
| name | VARCHAR(100) | NOT NULL | - | 成就名称 |
| description | TEXT | - | NULL | 成就描述 |
| icon_url | VARCHAR(255) | - | NULL | 图标 |
| category | TINYINT | - | NULL | 1击杀 2通关 3收集 4等级 5特殊 |
| condition_type | VARCHAR(50) | NOT NULL | - | 条件类型 |
| condition_value | INT | NOT NULL | - | 条件值 |
| reward_type | VARCHAR(20) | - | NULL | coin/diamond/item |
| reward_value | INT | - | NULL | 奖励数值 |
| reward_item_id | BIGINT | - | NULL | 奖励道具ID |
| sort_order | INT | - | 0 | 排序 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**condition_type 枚举值**：
- `total_kill` — 累计击杀数
- `total_clear` — 累计通关数
- `total_play` — 累计游戏次数
- `max_wave` — 最高波数
- `collect_item` — 收集道具种类数
- `reach_level` — 达到等级
- `no_item_clear` — 不使用道具通关
- `full_hp_clear` — 满血通关

---

### 3.14 t_user_achievement — 用户成就进度表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| achievement_id | BIGINT | FK → t_achievement.id, NOT NULL | - | 成就ID |
| progress | INT | - | 0 | 当前进度 |
| is_completed | TINYINT | - | 0 | 是否完成 |
| is_rewarded | TINYINT | - | 0 | 是否已领奖 |
| completed_at | DATETIME | - | NULL | 完成时间 |

**索引**：
- `uk_user_ach` UNIQUE ON (user_id, achievement_id)
- `idx_user_id` ON (user_id)

---

### 3.15 t_daily_sign — 每日签到表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| sign_date | DATE | NOT NULL | - | 签到日期 |
| consecutive_days | INT | - | 1 | 连续签到天数 |
| reward_type | VARCHAR(20) | - | NULL | coin/diamond/item |
| reward_value | INT | - | NULL | 奖励数值 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**索引**：
- `uk_user_date` UNIQUE ON (user_id, sign_date)
- `idx_user_id` ON (user_id)

---

### 3.16 t_daily_task — 每日任务定义表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 任务ID |
| name | VARCHAR(100) | NOT NULL | - | 任务名称 |
| description | TEXT | - | NULL | 任务描述 |
| task_type | VARCHAR(50) | NOT NULL | - | 任务类型 |
| target_value | INT | NOT NULL | - | 目标值 |
| reward_type | VARCHAR(20) | - | NULL | coin/diamond/exp |
| reward_value | INT | - | NULL | 奖励数值 |
| is_active | TINYINT | - | 1 | 是否启用 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**task_type 枚举值**：
- `play_game` — 进行N局游戏
- `kill_enemy` — 击杀N个敌人
- `clear_stage` — 通关N次
- `use_item` — 使用N个道具
- `reach_wave` — 到达第N波

---

### 3.17 t_user_daily_task — 用户每日任务进度表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| task_id | BIGINT | FK → t_daily_task.id, NOT NULL | - | 任务ID |
| task_date | DATE | NOT NULL | - | 任务日期 |
| progress | INT | - | 0 | 当前进度 |
| is_completed | TINYINT | - | 0 | 是否完成 |
| is_rewarded | TINYINT | - | 0 | 是否已领奖 |

**索引**：
- `uk_user_task_date` UNIQUE ON (user_id, task_id, task_date)
- `idx_user_date` ON (user_id, task_date)

---

### 3.18 t_mail — 邮件表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 邮件ID |
| user_id | BIGINT | NOT NULL | - | 用户ID(0=全服邮件) |
| title | VARCHAR(100) | NOT NULL | - | 邮件标题 |
| content | TEXT | - | NULL | 邮件内容 |
| mail_type | TINYINT | - | 1 | 1系统 2补偿 3活动 4奖励 |
| reward_type | VARCHAR(20) | - | NULL | coin/diamond/item |
| reward_value | INT | - | NULL | 奖励数值 |
| reward_item_id | BIGINT | - | NULL | 奖励道具ID |
| is_read | TINYINT | - | 0 | 是否已读 |
| is_claimed | TINYINT | - | 0 | 奖励是否领取 |
| expire_at | DATETIME | - | NULL | 过期时间 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**索引**：
- `idx_user_id` ON (user_id)
- `idx_expire` ON (expire_at)

---

### 3.19 t_ranking — 排行榜表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 主键 |
| user_id | BIGINT | FK → t_user.id, NOT NULL | - | 用户ID |
| ranking_type | VARCHAR(20) | NOT NULL | - | wave/kill/score |
| score | INT | NOT NULL | - | 分数 |
| season | INT | - | 1 | 赛季 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | - | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |

**索引**：
- `uk_user_type_season` UNIQUE ON (user_id, ranking_type, season)
- `idx_type_score` ON (ranking_type, score DESC)

**说明**：实时排行使用Redis Sorted Set，此表为持久化快照

---

### 3.20 t_buff_definition — Buff定义表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | Buff ID |
| name | VARCHAR(50) | NOT NULL | - | Buff名称 |
| description | TEXT | - | NULL | 描述 |
| icon_url | VARCHAR(255) | - | NULL | 图标 |
| buff_type | VARCHAR(50) | NOT NULL | - | 类型 |
| value_type | TINYINT | - | 1 | 1百分比 2固定值 |
| value | FLOAT | NOT NULL | - | 数值 |
| rarity | TINYINT | - | 1 | 1普通 2稀有 3史诗 4传说 |
| max_stack | INT | - | 1 | 最大叠加层数 |
| is_active | TINYINT | - | 1 | 是否启用 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

**buff_type 枚举值**：
- `atk_up` — 攻击力提升
- `atk_speed_up` — 攻速提升
- `speed_up` — 移速提升
- `hp_up` — 生命上限提升
- `hp_regen` — 生命恢复
- `crit_rate_up` — 暴击率提升
- `crit_dmg_up` — 暴击伤害提升
- `def_up` — 防御提升
- `aoe` — 范围伤害
- `pierce` — 穿透
- `multi_shot` — 多重射击
- `magnet` — 拾取范围增大

---

### 3.21 t_map — 地图/关卡表

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 地图ID |
| name | VARCHAR(100) | NOT NULL | - | 地图名 |
| description | TEXT | - | NULL | 描述 |
| difficulty | TINYINT | - | 1 | 难度1-5 |
| max_wave | INT | - | 30 | 总波数 |
| boss_wave_interval | INT | - | 10 | Boss出现间隔波数 |
| unlock_type | TINYINT | - | 0 | 0默认 1等级 2通关前置 |
| unlock_value | INT | - | 0 | 解锁条件值 |
| background_url | VARCHAR(255) | - | NULL | 背景图 |
| status | TINYINT | - | 1 | 1正常 0禁用 |
| sort_order | INT | - | 0 | 排序 |
| created_at | DATETIME | - | CURRENT_TIMESTAMP | 创建时间 |

---

## 4. 表关系汇总

| 关系 | 类型 | 说明 |
|------|------|------|
| t_user → t_user_item | 1:N | 用户拥有多个背包物品 |
| t_user → t_purchase_record | 1:N | 用户有多条购买记录 |
| t_user → t_recharge_record | 1:N | 用户有多条充值记录 |
| t_user → t_game_record | 1:N | 用户有多局游戏记录 |
| t_user → t_user_character | 1:N | 用户拥有多个角色 |
| t_user → t_user_achievement | 1:N | 用户有多个成就进度 |
| t_user → t_daily_sign | 1:N | 用户有多条签到记录 |
| t_user → t_user_daily_task | 1:N | 用户有多条任务进度 |
| t_user → t_mail | 1:N | 用户有多封邮件 |
| t_user → t_ranking | 1:N | 用户有多条排行记录 |
| t_user ↔ t_user (t_friend) | N:N | 好友关系 |
| t_user → t_friend_request | 1:N | 好友请求 |
| t_admin → t_admin_operation_log | 1:N | 管理员操作日志 |
| t_shop_item → t_user_item | 1:N | 商品在多个用户背包中 |
| t_shop_item → t_purchase_record | 1:N | 商品有多条购买记录 |
| t_character → t_user_character | 1:N | 角色被多个用户拥有 |
| t_achievement → t_user_achievement | 1:N | 成就有多个用户进度 |
| t_daily_task → t_user_daily_task | 1:N | 任务有多个用户进度 |

---

## 5. 数据量预估

| 表 | 预估数据量（毕业设计规模） | 说明 |
|------|------|------|
| t_user | 100-1000 | 测试用户 |
| t_admin | 2-5 | 管理员 |
| t_shop_item | 20-50 | 商品种类 |
| t_user_item | 1000-5000 | 用户背包 |
| t_purchase_record | 500-5000 | 购买记录 |
| t_recharge_record | 100-1000 | 充值记录 |
| t_game_record | 500-5000 | 游戏记录 |
| t_friend | 200-2000 | 好友关系 |
| t_admin_operation_log | 500-5000 | 操作日志 |
| 其他表 | 各100-1000 | - |