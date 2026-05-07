# API 接口文档

## 1. 概述

- **Base URL**: `http://localhost:8080/api`
- **数据格式**: JSON
- **认证方式**: JWT Token（Header: `Authorization: Bearer {token}`）
- **API文档**: Knife4j 地址 `http://localhost:8080/doc.html`

## 2. 统一返回格式

```json
{
    "code": 200,
    "message": "success",
    "data": {}
}
```

分页返回格式：
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "records": [],
        "total": 100,
        "page": 1,
        "size": 10
    }
}
```

## 3. 错误码

| code | 说明 |
|------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未认证/Token过期 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |
| 1001 | 用户名已存在 |
| 1002 | 用户名或密码错误 |
| 1003 | 账号已被封禁 |
| 2001 | 游戏币不足 |
| 2002 | 钻石不足 |
| 2003 | 商品已下架 |
| 2004 | 库存不足 |
| 2005 | 超出限购数量 |
| 3001 | 好友请求已发送 |
| 3002 | 已是好友 |
| 4001 | 今日已签到 |
| 4002 | 任务未完成 |

---

## 4. 数据归属说明

### 4.1 游戏客户端资源（本地数据）

以下数据由 Godot 游戏客户端资源文件定义，**不存储在数据库中**：

| 资源类型 | 客户端资源文件 | 说明 |
|----------|---------------|------|
| 角色定义 | `data/characters.json` | 角色名、基础属性、技能、武器类型、解锁条件等 |
| Buff定义 | `data/buffs.json` | Buff名称、效果类型、数值、稀有度、持续时间等 |
| 地图/关卡定义 | `data/maps.json` | 地图名、难度、波数、Boss间隔、解锁条件等 |
| 成就定义 | `data/achievements.json` | 成就名、条件类型、条件值、奖励等 |
| 每日任务定义 | `data/daily_tasks.json` | 任务名、类型、目标值、奖励等 |
| 商品详情 | `data/shop_items.json` | 商品名、描述、图片、效果类型、效果值等 |

### 4.2 后端数据库（运行时数据）

以下数据存储在后端数据库中：

| 数据类型 | 说明 |
|----------|------|
| 用户账户 | 用户名、密码、昵称、头像、等级、经验、货币余额 |
| 商品运营数据 | 价格、库存、限购、上下架状态、时间限制 |
| 用户背包 | 用户拥有的物品编码(item_code)及数量 |
| 用户角色状态 | 用户解锁的角色编码(character_code)及强化数据 |
| 购买/充值记录 | 订单号、金额、状态等交易数据 |
| 好友关系 | 好友列表、好友请求 |
| 成就/任务进度 | 用户的进度、完成状态、领取状态 |
| 游戏记录 | 每局游戏的统计数据 |
| 排行榜 | 排行榜分数快照 |
| 邮件 | 系统邮件及奖励 |
| 签到 | 签到记录 |

### 4.3 编码对应关系

数据库中的 `item_code`、`character_code`、`achievement_code`、`task_code`、`map_code` 等字段，与游戏客户端资源文件中的 `id` 字段一一对应。客户端通过这些编码关联本地资源获取完整的名称、描述、图片等信息。

---

## 5. 游戏端接口（/api/game）

### 5.1 用户认证

#### POST /api/game/register — 用户注册

**请求体**：
```json
{
    "username": "player001",
    "password": "123456",
    "nickname": "勇者一号"
}
```

**响应**：
```json
{
    "code": 200,
    "message": "注册成功",
    "data": {
        "userId": 1,
        "username": "player001",
        "nickname": "勇者一号",
        "token": "eyJhbGciOiJIUzI1NiJ9...",
        "tokenExpire": 7200
    }
}
```

#### POST /api/game/login — 用户登录

**请求体**：
```json
{
    "username": "player001",
    "password": "123456"
}
```

**响应**：
```json
{
    "code": 200,
    "message": "登录成功",
    "data": {
        "userId": 1,
        "username": "player001",
        "nickname": "勇者一号",
        "token": "eyJhbGciOiJIUzI1NiJ9...",
        "tokenExpire": 7200
    }
}
```

### 5.2 用户信息

#### GET /api/game/user/info — 获取用户信息

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": {
        "id": 1,
        "username": "player001",
        "nickname": "勇者一号",
        "avatarUrl": null,
        "gameCoin": 1500,
        "diamond": 60,
        "level": 5,
        "exp": 2300,
        "maxWave": 15,
        "totalPlayTime": 3600
    }
}
```

#### PUT /api/game/user/info — 修改用户信息

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "nickname": "新昵称",
    "avatarUrl": "avatar_01.png"
}
```

### 5.3 商城

> **说明**：商城接口只返回运营数据（价格、库存、上下架状态等），商品的名称、描述、图片、效果等详情由游戏客户端根据 `item_code` 从本地资源文件 `shop_items.json` 中获取。

#### GET /api/game/shop/items — 获取商城商品列表

**Headers**: `Authorization: Bearer {token}`

**Query参数**：
- `page` (可选): 页码，默认1
- `size` (可选): 每页数量，默认20

**响应**：
```json
{
    "code": 200,
    "data": {
        "records": [
            {
                "itemCode": "item_heal_potion",
                "priceCoin": 100,
                "priceDiamond": 0,
                "stock": -1,
                "maxBuyCount": -1,
                "status": 1,
                "sortOrder": 1
            },
            {
                "itemCode": "item_revive_token",
                "priceCoin": 0,
                "priceDiamond": 50,
                "stock": -1,
                "maxBuyCount": 3,
                "status": 1,
                "sortOrder": 6
            }
        ],
        "total": 10,
        "page": 1,
        "size": 20
    }
}
```

**客户端处理流程**：
1. 从后端获取商品列表（item_code + 运营数据）
2. 根据 item_code 从本地 `shop_items.json` 获取商品名称、描述、图片、效果等
3. 合并展示

#### POST /api/game/shop/buy — 购买商品

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "itemCode": "item_heal_potion",
    "quantity": 2,
    "payType": 1
}
```

**响应**：
```json
{
    "code": 200,
    "message": "购买成功",
    "data": {
        "orderNo": "PUR20260504143000123456",
        "itemCode": "item_heal_potion",
        "quantity": 2,
        "totalPrice": 200,
        "payType": 1,
        "remainingCoin": 1300
    }
}
```

### 5.4 充值

#### GET /api/game/recharge/packages — 获取充值档位

**响应**：
```json
{
    "code": 200,
    "data": [
        {"id": 1, "amount": 6.00, "diamond": 60, "bonus": 0},
        {"id": 2, "amount": 30.00, "diamond": 300, "bonus": 30},
        {"id": 3, "amount": 98.00, "diamond": 980, "bonus": 120},
        {"id": 4, "amount": 198.00, "diamond": 1980, "bonus": 300},
        {"id": 5, "amount": 328.00, "diamond": 3280, "bonus": 600},
        {"id": 6, "amount": 648.00, "diamond": 6480, "bonus": 1600}
    ]
}
```

#### POST /api/game/recharge/create — 创建充值订单

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "packageId": 2,
    "payChannel": "alipay"
}
```

**响应**（模拟模式直接返回成功）：
```json
{
    "code": 200,
    "message": "充值成功(模拟模式)",
    "data": {
        "orderNo": "RCH20260504143000123456",
        "amount": 30.00,
        "diamondReceived": 330,
        "status": 1
    }
}
```

### 5.5 背包

> **说明**：背包接口只返回物品编码和数量，物品的名称、描述、图片、效果等详情由游戏客户端根据 `item_code` 从本地资源文件获取。

#### GET /api/game/user/items — 获取用户背包

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": [
        {
            "itemCode": "item_heal_potion",
            "quantity": 5,
            "isEquipped": false
        },
        {
            "itemCode": "item_shield",
            "quantity": 2,
            "isEquipped": true
        }
    ]
}
```

**客户端处理流程**：
1. 从后端获取背包列表（item_code + quantity + isEquipped）
2. 根据 item_code 从本地 `shop_items.json` 获取物品名称、描述、图片、效果等
3. 合并展示

#### PUT /api/game/user/items/equip — 装备/卸下道具

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "itemCode": "item_shield",
    "equip": true
}
```

### 5.6 好友系统

#### GET /api/game/friends — 好友列表

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": [
        {
            "friendId": 2,
            "nickname": "冒险者",
            "avatarUrl": null,
            "level": 8,
            "isOnline": true
        }
    ]
}
```

#### POST /api/game/friends/search — 搜索用户

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "keyword": "player"
}
```

#### POST /api/game/friends/request — 发送好友请求

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "targetUserId": 3,
    "message": "加个好友一起玩吧！"
}
```

#### GET /api/game/friends/requests — 获取好友请求列表

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": [
        {
            "id": 1,
            "fromUserId": 3,
            "fromNickname": "新手玩家",
            "message": "加个好友一起玩吧！",
            "createdAt": "2026-05-04 14:30:00"
        }
    ]
}
```

#### PUT /api/game/friends/accept/{requestId} — 接受好友请求

**Headers**: `Authorization: Bearer {token}`

#### PUT /api/game/friends/reject/{requestId} — 拒绝好友请求

**Headers**: `Authorization: Bearer {token}`

#### DELETE /api/game/friends/{friendId} — 删除好友

**Headers**: `Authorization: Bearer {token}`

### 5.7 签到

#### POST /api/game/sign/daily — 每日签到

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "message": "签到成功",
    "data": {
        "consecutiveDays": 3,
        "rewardType": "coin",
        "rewardValue": 200,
        "todaySign": true
    }
}
```

#### GET /api/game/sign/status — 获取签到状态

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": {
        "todaySigned": false,
        "consecutiveDays": 2,
        "signRecords": [1, 2, 0, 0, 0, 0, 0]
    }
}
```

### 5.8 成就

> **说明**：成就定义（名称、条件、奖励等）由游戏客户端本地资源 `achievements.json` 提供，后端只存储和返回用户的成就进度。

#### GET /api/game/achievements/progress — 获取用户成就进度

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": [
        {
            "achievementCode": "ach_kill_100",
            "progress": 56,
            "isCompleted": false,
            "isRewarded": false
        },
        {
            "achievementCode": "ach_first_clear",
            "progress": 1,
            "isCompleted": true,
            "isRewarded": true
        }
    ]
}
```

**客户端处理流程**：
1. 从后端获取用户成就进度（achievement_code + progress + 状态）
2. 从本地 `achievements.json` 获取成就定义（名称、描述、图标、条件、奖励）
3. 合并展示

#### POST /api/game/achievements/{achievementCode}/claim — 领取成就奖励

**Headers**: `Authorization: Bearer {token}`

**路径参数**：`achievementCode` — 成就编码（如 `ach_kill_100`）

**响应**：
```json
{
    "code": 200,
    "message": "领取成功",
    "data": {
        "achievementCode": "ach_kill_100",
        "rewardType": "coin",
        "rewardValue": 500,
        "newCoinBalance": 2000
    }
}
```

### 5.9 任务

> **说明**：每日任务定义（名称、类型、目标等）由游戏客户端本地资源 `daily_tasks.json` 提供，后端只存储和返回用户的任务进度。

#### GET /api/game/tasks/daily/progress — 获取用户每日任务进度

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": [
        {
            "taskCode": "task_play_game",
            "progress": 1,
            "isCompleted": false,
            "isRewarded": false
        },
        {
            "taskCode": "task_kill_enemy",
            "progress": 200,
            "isCompleted": true,
            "isRewarded": false
        }
    ]
}
```

**客户端处理流程**：
1. 从后端获取用户任务进度（task_code + progress + 状态）
2. 从本地 `daily_tasks.json` 获取任务定义（名称、描述、类型、目标值、奖励）
3. 合并展示

#### POST /api/game/tasks/{taskCode}/claim — 领取任务奖励

**Headers**: `Authorization: Bearer {token}`

**路径参数**：`taskCode` — 任务编码（如 `task_play_game`）

### 5.10 排行榜

#### GET /api/game/ranking/{type} — 获取排行榜

**Headers**: `Authorization: Bearer {token}`

**路径参数**：`type` — wave / kill / score

**响应**：
```json
{
    "code": 200,
    "data": {
        "type": "wave",
        "season": 1,
        "list": [
            {"rank": 1, "userId": 5, "nickname": "大神", "score": 50},
            {"rank": 2, "userId": 2, "nickname": "冒险者", "score": 35},
            {"rank": 3, "userId": 1, "nickname": "勇者一号", "score": 15}
        ],
        "myRank": 3,
        "myScore": 15
    }
}
```

### 5.11 邮件

#### GET /api/game/mails — 获取邮件列表

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": [
        {
            "id": 1,
            "title": "欢迎来到像素幸存者！",
            "content": "感谢您的注册，赠送100游戏币！",
            "mailType": 1,
            "rewardType": "coin",
            "rewardValue": 100,
            "rewardItemCode": null,
            "isRead": false,
            "isClaimed": false,
            "createdAt": "2026-05-04 14:00:00"
        }
    ]
}
```

#### PUT /api/game/mails/{id}/read — 标记已读

**Headers**: `Authorization: Bearer {token}`

#### POST /api/game/mails/{id}/claim — 领取邮件奖励

**Headers**: `Authorization: Bearer {token}`

### 5.12 游戏记录

#### POST /api/game/record/submit — 提交游戏结算

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "characterCode": "char_warrior",
    "mapCode": "map_1_1",
    "chapter": 1,
    "gameLevel": 1,
    "isEndless": false,
    "waveReached": 15,
    "killCount": 230,
    "bossKillCount": 1,
    "expGained": 5000,
    "coinGained": 800,
    "playDuration": 600,
    "isCleared": false,
    "deathReason": "enemy_damage",
    "buffsUsed": ["atk_up", "speed_up", "crit_rate_up"],
    "itemsUsed": [{"itemCode": "item_heal_potion", "count": 2}],
    "score": 3500
}
```

**响应**：
```json
{
    "code": 200,
    "message": "结算成功",
    "data": {
        "coinGained": 800,
        "expGained": 5000,
        "levelUp": true,
        "newLevel": 6,
        "achievementsUnlocked": ["ach_kill_100", "ach_first_clear"],
        "tasksUpdated": [{"taskCode": "task_play_game", "progress": 2, "completed": false}]
    }
}
```

### 5.13 角色

> **说明**：角色定义（名称、基础属性、技能、武器类型、解锁条件等）由游戏客户端本地资源 `characters.json` 提供，后端只存储和返回用户的角色解锁状态和强化数据。

#### GET /api/game/user/characters — 获取用户角色状态

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": [
        {
            "characterCode": "char_warrior",
            "isSelected": true,
            "level": 3,
            "hpUpgrade": 1,
            "atkUpgrade": 2,
            "defUpgrade": 0,
            "speedUpgrade": 0,
            "combatPower": 150
        },
        {
            "characterCode": "char_ranger",
            "isSelected": false,
            "level": 1,
            "hpUpgrade": 0,
            "atkUpgrade": 0,
            "defUpgrade": 0,
            "speedUpgrade": 0,
            "combatPower": 80
        }
    ]
}
```

**客户端处理流程**：
1. 从后端获取用户角色状态（character_code + 强化数据）
2. 从本地 `characters.json` 获取角色定义（名称、描述、基础属性、技能、武器类型、解锁条件）
3. 根据 character_code 匹配，合并展示
4. 未解锁的角色根据客户端资源中的 unlock_type 和 unlock_value 判断是否可解锁

#### POST /api/game/characters/{characterCode}/select — 选择角色

**Headers**: `Authorization: Bearer {token}`

**路径参数**：`characterCode` — 角色编码（如 `char_warrior`）

#### POST /api/game/characters/{characterCode}/unlock — 解锁角色

**Headers**: `Authorization: Bearer {token}`

**路径参数**：`characterCode` — 角色编码

**请求体**：
```json
{
    "unlockType": "diamond"
}
```

**说明**：`unlockType` 可选值为 `default`(默认解锁)、`level`(等级解锁)、`diamond`(钻石购买)、`achievement`(成就解锁)。后端根据客户端传来的解锁方式执行对应的扣款/验证逻辑。

#### POST /api/game/characters/{characterCode}/upgrade — 强化角色属性

**Headers**: `Authorization: Bearer {token}`

**路径参数**：`characterCode` — 角色编码

**请求体**：
```json
{
    "upgradeType": "atk"
}
```

**说明**：`upgradeType` 可选值为 `hp`、`atk`、`def`、`speed`。后端扣除游戏币并更新强化次数。

---

## 6. 管理端接口（/api/admin）

### 6.1 管理员认证

#### POST /api/admin/login — 管理员登录

**请求体**：
```json
{
    "username": "admin",
    "password": "admin123"
}
```

**响应**：
```json
{
    "code": 200,
    "message": "登录成功",
    "data": {
        "adminId": 1,
        "username": "admin",
        "role": "SUPER_ADMIN",
        "token": "eyJhbGciOiJIUzI1NiJ9...",
        "tokenExpire": 7200
    }
}
```

#### GET /api/admin/info — 获取管理员信息

**Headers**: `Authorization: Bearer {token}`

### 6.2 数据看板

#### GET /api/admin/dashboard/overview — 总览数据

**Headers**: `Authorization: Bearer {token}`

**响应**：
```json
{
    "code": 200,
    "data": {
        "totalUsers": 156,
        "todayNewUsers": 12,
        "onlineUsers": 23,
        "todayRevenue": 456.00,
        "totalRevenue": 12580.00,
        "todayOrders": 34,
        "totalOrders": 890
    }
}
```

#### GET /api/admin/dashboard/trend — 趋势数据

**Headers**: `Authorization: Bearer {token}`

**Query参数**：
- `days`: 天数，默认7

**响应**：
```json
{
    "code": 200,
    "data": {
        "dates": ["2026-04-28", "2026-04-29", "..."],
        "newUsers": [5, 8, 12, "..."],
        "revenue": [120.00, 230.00, 456.00, "..."],
        "orders": [10, 18, 34, "..."]
    }
}
```

### 6.3 商品管理

> **说明**：管理端只管理商品的运营数据（价格、库存、上下架等），商品的游戏内容详情（名称、描述、图片、效果）由游戏客户端资源管理。

#### GET /api/admin/items — 商品列表

**Headers**: `Authorization: Bearer {token}`

**Query参数**：
- `page`, `size`, `keyword`(按item_code搜索), `status`

**响应**：
```json
{
    "code": 200,
    "data": {
        "records": [
            {
                "id": 1,
                "itemCode": "item_heal_potion",
                "priceCoin": 100,
                "priceDiamond": 0,
                "stock": -1,
                "maxBuyCount": -1,
                "status": 1,
                "sortOrder": 1,
                "startTime": null,
                "endTime": null
            }
        ],
        "total": 10,
        "page": 1,
        "size": 10
    }
}
```

#### POST /api/admin/items — 新增商品

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "itemCode": "item_new_potion",
    "priceCoin": 200,
    "priceDiamond": 0,
    "stock": -1,
    "maxBuyCount": -1,
    "status": 1,
    "sortOrder": 11,
    "startTime": null,
    "endTime": null
}
```

**说明**：`itemCode` 必须与游戏客户端 `shop_items.json` 中定义的物品ID一致。

#### PUT /api/admin/items/{id} — 修改商品运营数据

**Headers**: `Authorization: Bearer {token}`

#### DELETE /api/admin/items/{id} — 删除商品

**Headers**: `Authorization: Bearer {token}`

#### PUT /api/admin/items/{id}/status — 上下架

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "status": 0
}
```

### 6.4 用户管理

#### GET /api/admin/users — 用户列表

**Headers**: `Authorization: Bearer {token}`

**Query参数**：
- `page`, `size`, `keyword`, `status`

#### GET /api/admin/users/{id} — 用户详情

**Headers**: `Authorization: Bearer {token}`

#### PUT /api/admin/users/{id}/status — 封禁/解封

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "status": 0,
    "reason": "违规行为"
}
```

#### PUT /api/admin/users/{id}/currency — 调整用户货币

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "gameCoin": 1000,
    "diamond": 50,
    "reason": "活动补偿"
}
```

### 6.5 订单管理

#### GET /api/admin/orders/purchase — 购买记录

**Headers**: `Authorization: Bearer {token}`

**Query参数**：
- `page`, `size`, `userId`, `payType`, `startDate`, `endDate`

#### GET /api/admin/orders/recharge — 充值记录

**Headers**: `Authorization: Bearer {token}`

**Query参数**：
- `page`, `size`, `userId`, `payChannel`, `startDate`, `endDate`

#### GET /api/admin/orders/stats — 订单统计

**Headers**: `Authorization: Bearer {token}`

### 6.6 邮件管理

#### GET /api/admin/mails — 邮件列表

**Headers**: `Authorization: Bearer {token}`

#### POST /api/admin/mails — 发送邮件

**Headers**: `Authorization: Bearer {token}`

**请求体**：
```json
{
    "userId": 0,
    "title": "维护补偿",
    "content": "感谢您的耐心等待，补偿100钻石！",
    "mailType": 2,
    "rewardType": "diamond",
    "rewardValue": 100,
    "rewardItemCode": null,
    "expireDays": 30
}
```

**说明**：`userId` 为 0 表示全服邮件。`rewardItemCode` 为物品奖励时填写对应的游戏客户端资源ID。

#### DELETE /api/admin/mails/{id} — 删除邮件

**Headers**: `Authorization: Bearer {token}`

### 6.7 操作日志

#### GET /api/admin/logs — 操作日志列表

**Headers**: `Authorization: Bearer {token}`

**Query参数**：
- `page`, `size`, `adminId`, `module`, `operation`, `startDate`, `endDate`

**响应**：
```json
{
    "code": 200,
    "data": {
        "records": [
            {
                "id": 1,
                "adminId": 1,
                "adminUsername": "admin",
                "operation": "UPDATE",
                "module": "商品管理",
                "targetType": "ShopItem",
                "targetId": "1",
                "detail": "{\"itemCode\":\"item_heal_potion\",\"priceCoin\":150}",
                "ipAddress": "127.0.0.1",
                "createdAt": "2026-05-04 15:00:00"
            }
        ],
        "total": 50,
        "page": 1,
        "size": 10
    }
}
```

---

## 7. 接口认证说明

### 7.1 Token获取
通过登录接口获取JWT Token。

### 7.2 Token使用
在需要认证的接口请求头中添加：
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

### 7.3 Token过期
- Token有效期：2小时
- 过期后返回 `code: 401`
- 客户端需重新登录获取新Token

### 7.4 离线模式
- 离线模式下不携带Token
- 所有需要认证的接口返回 `code: 401`
- 游戏内容（角色、Buff、地图、成就等）由客户端本地资源提供，离线可正常游玩
- 离线模式限制：不可使用商城购买、好友系统、排行榜、邮件、签到等联网功能
- 离线模式下的游戏进度暂存本地，联网登录后可同步提交