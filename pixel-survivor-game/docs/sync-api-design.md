# 数据同步接口文档

## 1. 概述

数据同步功能允许已登录用户将本地游戏进度上传到后端数据库，或从后端数据库下载数据到本地。实现多设备间的游戏进度同步。

- **前置条件**：用户必须已登录（携带有效 JWT Token）
- **认证方式**：`Authorization: Bearer {token}`
- **封禁检查**：被封禁用户（`t_user.status = 0`）无法使用同步功能，返回错误码 `1003`

---

## 2. 数据同步范围

| 数据类型 | 本地变量（SaveManager） | 数据库表 | 字段映射 |
|----------|------------------------|----------|----------|
| 金币 | `gold` | `t_user` | `game_coin` |
| 钻石 | `diamond` | `t_user` | `diamond` |
| 已解锁角色 | `unlocked_characters` | `t_user_character` | `character_code`（存在即解锁） |
| 角色等级 | `character_levels` | `t_user_character` | `level` |
| 已解锁地图 | `unlocked_maps` | `t_user_map_progress` | `is_unlocked = 1` |
| 地图最佳成绩 | `best_scores` | `t_user_map_progress` | `best_score` |
| 成就数据 | `achievements` | `t_user_achievement` | `progress` + `is_completed` |
| 累计击杀 | `total_kills` | `t_user_game_stats` | `total_kills` |
| 累计游戏次数 | `total_games` | `t_user_game_stats` | `total_games` |
| 累计通关次数 | `total_wins` | `t_user_game_stats` | `total_wins` |
| 累计获得金币 | `total_coins` | `t_user_game_stats` | `total_coins` |
| 最长存活时间 | `best_time` | `t_user_game_stats` | `best_time` |

---

## 3. 接口详情

### 3.1 POST /api/game/sync/upload — 上传本地数据到服务器

**说明**：将客户端本地的全部游戏进度上传到后端数据库。采用 **覆盖写入** 策略，以客户端数据为准。

**Headers**：
```
Authorization: Bearer {token}
Content-Type: application/json
```

**请求体**：
```json
{
    "gold": 1500,
    "diamond": 60,
    "unlockedCharacters": ["maphy", "minami", "yuria", "sakura"],
    "characterLevels": {
        "maphy": 3,
        "minami": 2,
        "yuria": 1,
        "sakura": 1
    },
    "unlockedMaps": ["endless_road", "wasteland"],
    "bestScores": {
        "endless_road": 3500,
        "wasteland": 2000
    },
    "achievements": [
        {"code": "first_blood", "progress": 1, "completed": true},
        {"code": "kill_100", "progress": 56, "completed": false},
        {"code": "kill_1000", "progress": 0, "completed": false},
        {"code": "first_win", "progress": 1, "completed": true},
        {"code": "speed_run", "progress": 0, "completed": false},
        {"code": "no_damage", "progress": 0, "completed": false},
        {"code": "konami", "progress": 0, "completed": false},
        {"code": "boss_rush", "progress": 0, "completed": false},
        {"code": "max_weapon", "progress": 0, "completed": false},
        {"code": "full_build", "progress": 0, "completed": false},
        {"code": "survivor", "progress": 0, "completed": false},
        {"code": "collector", "progress": 0, "completed": false},
        {"code": "secret_char", "progress": 0, "completed": false},
        {"code": "all_maps", "progress": 0, "completed": false},
        {"code": "kill_10000", "progress": 0, "completed": false}
    ],
    "totalKills": 500,
    "totalGames": 20,
    "totalWins": 5,
    "totalCoins": 10000,
    "bestTime": 600.0
}
```

**字段说明**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `gold` | int | ✅ | 当前金币数量 |
| `diamond` | int | ✅ | 当前钻石数量 |
| `unlockedCharacters` | string[] | ✅ | 已解锁的角色编码列表 |
| `characterLevels` | object | ✅ | 角色等级映射 `{char_id: level}` |
| `unlockedMaps` | string[] | ✅ | 已解锁的地图编码列表 |
| `bestScores` | object | ✅ | 地图最佳成绩映射 `{map_id: score}` |
| `achievements` | array | ✅ | 成就进度列表 |
| `achievements[].code` | string | ✅ | 成就编码 |
| `achievements[].progress` | int | ✅ | 当前进度 |
| `achievements[].completed` | bool | ✅ | 是否已完成 |
| `totalKills` | int | ✅ | 累计击杀数 |
| `totalGames` | int | ✅ | 累计游戏次数 |
| `totalWins` | int | ✅ | 累计通关次数 |
| `totalCoins` | int | ✅ | 累计获得金币总数 |
| `bestTime` | float | ✅ | 最长存活时间(秒) |

**成功响应**：
```json
{
    "code": 200,
    "message": "上传成功",
    "data": {
        "syncedAt": "2026-05-07 22:00:00"
    }
}
```

**错误响应**：
```json
// 账号被封禁
{"code": 1003, "message": "账号已被封禁", "data": null}

// 未登录
{"code": 401, "message": "未认证", "data": null}
```

**后端处理逻辑**（伪代码）：
```
1. 验证 JWT Token，解析 userId
2. 检查 t_user.status，若为 0 则返回 1003
3. 开启事务：
   a. UPDATE t_user SET game_coin = ?, diamond = ? WHERE id = ?
   b. 遍历 unlockedCharacters + characterLevels：
      INSERT INTO t_user_character (user_id, character_code, level)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE level = VALUES(level)
      注意：未在 unlockedCharacters 中但数据库已有的角色记录不删除（保留历史）
   c. 遍历 unlockedMaps + bestScores：
      INSERT INTO t_user_map_progress (user_id, map_code, is_unlocked, best_score)
      VALUES (?, ?, 1, ?)
      ON DUPLICATE KEY UPDATE
        is_unlocked = GREATEST(is_unlocked, VALUES(is_unlocked)),
        best_score = GREATEST(best_score, VALUES(best_score))
   d. 遍历 achievements：
      INSERT INTO t_user_achievement (user_id, achievement_code, progress, is_completed)
      VALUES (?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        progress = GREATEST(progress, VALUES(progress)),
        is_completed = GREATEST(is_completed, VALUES(is_completed))
   e. INSERT INTO t_user_game_stats (user_id, total_kills, total_games, total_wins, total_coins, best_time)
      VALUES (?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        total_kills = VALUES(total_kills),
        total_games = VALUES(total_games),
        total_wins = VALUES(total_wins),
        total_coins = VALUES(total_coins),
        best_time = GREATEST(best_time, VALUES(best_time))
4. 提交事务
5. 返回成功
```

**设计说明**：
- 金币和钻石采用 **直接覆盖**，以客户端最新数据为准
- 角色、地图、成就采用 **取较大值** 策略（`GREATEST`），避免覆盖已有的更好成绩
- 角色解锁列表不做删除操作，只添加新解锁的角色

---

### 3.2 POST /api/game/sync/download — 从服务器下载数据到本地

**说明**：从后端数据库获取用户的全部游戏进度，客户端用返回的数据覆盖本地 SaveManager。

**Headers**：
```
Authorization: Bearer {token}
Content-Type: application/json
```

**请求体**：无

**成功响应**：
```json
{
    "code": 200,
    "message": "下载成功",
    "data": {
        "gold": 1500,
        "diamond": 60,
        "unlockedCharacters": ["maphy", "minami", "yuria", "sakura"],
        "characterLevels": {
            "maphy": 3,
            "minami": 2,
            "yuria": 1,
            "sakura": 1
        },
        "unlockedMaps": ["endless_road", "wasteland"],
        "bestScores": {
            "endless_road": 3500,
            "wasteland": 2000
        },
        "achievements": [
            {"code": "first_blood", "progress": 1, "completed": true},
            {"code": "kill_100", "progress": 56, "completed": false}
        ],
        "totalKills": 500,
        "totalGames": 20,
        "totalWins": 5,
        "totalCoins": 10000,
        "bestTime": 600.0
    }
}
```

**错误响应**：
```json
// 账号被封禁
{"code": 1003, "message": "账号已被封禁", "data": null}

// 未登录
{"code": 401, "message": "未认证", "data": null}
```

**后端处理逻辑**（伪代码）：
```
1. 验证 JWT Token，解析 userId
2. 检查 t_user.status，若为 0 则返回 1003
3. 查询数据：
   a. SELECT game_coin, diamond FROM t_user WHERE id = ?
   b. SELECT character_code, level FROM t_user_character WHERE user_id = ?
   c. SELECT map_code, is_unlocked, best_score FROM t_user_map_progress WHERE user_id = ?
   d. SELECT achievement_code, progress, is_completed FROM t_user_achievement WHERE user_id = ?
   e. SELECT total_kills, total_games, total_wins, total_coins, best_time FROM t_user_game_stats WHERE user_id = ?
4. 组装响应数据：
   - unlockedCharacters: 从 t_user_character 查询所有记录的 character_code
   - characterLevels: 从 t_user_character 查询 {character_code: level}
   - unlockedMaps: 从 t_user_map_progress 查询 is_unlocked=1 的 map_code
   - bestScores: 从 t_user_map_progress 查询 {map_code: best_score}
   - achievements: 从 t_user_achievement 查询所有记录
   - 统计数据: 从 t_user_game_stats 查询
5. 返回数据
```

**客户端处理逻辑**（GDScript 伪代码）：
```gdscript
func _on_sync_download_completed(data: Dictionary):
    # 覆盖本地数据
    SaveManager.gold = data.get("gold", 0)
    SaveManager.diamond = data.get("diamond", 0)
    
    SaveManager.unlocked_characters.clear()
    for c in data.get("unlockedCharacters", []):
        SaveManager.unlocked_characters.append(c)
    
    SaveManager.character_levels = data.get("characterLevels", {})
    
    SaveManager.unlocked_maps.clear()
    for m in data.get("unlockedMaps", []):
        SaveManager.unlocked_maps.append(m)
    
    SaveManager.best_scores = data.get("bestScores", {})
    
    for ach in data.get("achievements", []):
        var code = ach.get("code", "")
        if SaveManager.achievements.has(code):
            SaveManager.achievements[code]["unlocked"] = ach.get("completed", false)
    
    SaveManager.total_kills = data.get("totalKills", 0)
    SaveManager.total_games = data.get("totalGames", 0)
    SaveManager.total_wins = data.get("totalWins", 0)
    SaveManager.total_coins = data.get("totalCoins", 0)
    SaveManager.best_time = data.get("bestTime", 0.0)
    
    SaveManager.save_data()
```

---

## 4. 涉及的数据库表汇总

| 表名 | 操作 | 说明 |
|------|------|------|
| `t_user` | UPDATE | 更新 `game_coin`、`diamond` |
| `t_user` | SELECT | 读取 `game_coin`、`diamond`、`status` |
| `t_user_character` | UPSERT | 角色解锁状态和等级 |
| `t_user_map_progress` | UPSERT | 地图解锁状态和最佳成绩（**新增表**） |
| `t_user_achievement` | UPSERT | 成就进度 |
| `t_user_game_stats` | UPSERT | 游戏统计数据（**新增表**） |

---

## 5. 安全与一致性

### 5.1 封禁检查
- 上传和下载接口均需检查 `t_user.status`
- 被封禁用户返回错误码 `1003`，拒绝同步

### 5.2 数据一致性
- 上传操作使用数据库事务，保证原子性
- 使用 `GREATEST` 函数确保不会覆盖已有的更好成绩
- 金币/钻石直接覆盖（以客户端为准）

### 5.3 防作弊说明
- 当前设计以客户端数据为准，适合毕业设计场景
- 生产环境建议：金币/钻石等货币数据应以服务端为准，客户端只能请求增减操作

---

## 6. 游戏端 UI 设计

### 6.1 同步按钮位置
在选人界面（main_menu）TopBar 中，登录按钮左侧添加「同步数据」按钮，仅在登录后显示。

### 6.2 同步菜单
点击同步按钮弹出下拉菜单：
- **📤 上传数据** — 将本地进度上传到云端
- **📥 下载数据** — 从云端下载进度到本地

### 6.3 操作反馈
- 上传成功：显示 "数据上传成功 ✓"
- 下载成功：显示 "数据下载成功 ✓"，并刷新界面数据
- 失败：显示错误信息
- 操作中：按钮显示加载状态，防止重复点击