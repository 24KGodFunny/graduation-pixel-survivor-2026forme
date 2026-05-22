# 数据同步接口文档

## 1. 概述

数据同步功能允许已登录用户将本地游戏进度上传到后端数据库，或从后端数据库下载数据到本地，实现多设备间的游戏进度同步。

**核心设计思路**: 将所有游戏进度数据以 JSON 格式整体存储在 `t_user_save_data` 表的一个 `save_data` LONGTEXT 字段中。上传时覆盖写入，下载时整体返回。这种"JSON Blob"模式简单高效，适合毕业设计规模，避免了多表联合同步的复杂性。

- **前置条件**: 用户必须已登录（携带有效 Game JWT Token）
- **认证方式**: `Authorization: Bearer {token}`
- **封禁检查**: 被封禁用户（`t_user.status = 1`）无法使用同步功能，返回错误码 `1003`

---

## 2. 数据同步范围

所有游戏进度以一个 JSON 字典的形式存储和传输：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `coins` | int | 当前金币数量 |
| `diamonds` | int | 当前钻石数量 |
| `unlocked_characters` | string[] | 已解锁的角色编码列表 (如 ["maphy", "minami"]) |
| `character_levels` | object | 角色等级映射 (如 {"maphy": 3, "minami": 2}) |
| `unlocked_maps` | string[] | 已解锁的地图编码列表 (如 ["tutorial", "endless_road"]) |
| `completed_maps` | string[] | 已完成(通关)的地图编码列表 (如 ["tutorial"]) |
| `unlocked_achievements` | string[] | 已解锁的成就编码列表 (如 ["first_blood"]) |

---

## 3. 接口详情

### 3.1 POST /api/game/sync/upload -- 上传本地存档

**说明**: 将客户端本地全部游戏进度序列化为 JSON 覆盖写入 `t_user_save_data` 表。采用 **upsert** 策略（存在则更新，不存在则新增）。

**请求头**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**请求体**: 客户端将 GlobalSave 全部数据通过 `SyncUploadDTO.saveData` (Map) 传入：

```json
{
    "saveData": {
        "coins": 1500,
        "diamonds": 60,
        "unlocked_characters": ["maphy", "minami", "yuria", "sakura"],
        "character_levels": {
            "maphy": 3,
            "minami": 2,
            "yuria": 1,
            "sakura": 1
        },
        "unlocked_maps": ["tutorial", "endless_road"],
        "completed_maps": ["tutorial"],
        "unlocked_achievements": ["first_blood", "first_win"]
    }
}
```

**成功响应**:
```json
{
    "code": 200,
    "message": "数据上传成功",
    "data": null
}
```

**错误响应**:
```json
// 账号被封禁
{"code": 1003, "message": "账号已被封禁", "data": null}

// 未登录/Token过期
{"code": 401, "message": "未认证", "data": null}

// 存档数据为空
{"code": 400, "message": "参数错误", "data": null}
```

**后端处理流程** (SyncServiceImpl.upload):
```
1. 验证 JWT Token → 解析 userId
2. 收到 SyncUploadDTO，将 saveData (Map) 通过 Jackson 序列化为 JSON 字符串
3. 查询 t_user_save_data WHERE user_id = ? 判断是否已有存档
4. 已有存档 → UPDATE save_data = jsonStr, updated_at = NOW()
   无存档   → INSERT (user_id, save_data, created_at, updated_at)
5. 删除 Redis 缓存: DELETE user:info:{userId}
6. 返回成功
```

**设计特点**:
- 全量覆盖写入，以客户端数据为准
- 使用 MyBatis-Plus + 事务 (@Transactional) 保证原子性
- 上传后清除 Redis 用户缓存，确保下次查询数据一致

---

### 3.2 POST /api/game/sync/download -- 下载存档

**说明**: 从 `t_user_save_data` 表查询存档 JSON，反序列化为 Map 后返回给客户端。客户端用返回的数据覆盖本地存档。

**请求头**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**请求体**: 无（POST 空体）

**成功响应**:
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "saveData": {
            "coins": 1500,
            "diamonds": 60,
            "unlocked_characters": ["maphy", "minami", "yuria", "sakura"],
            "character_levels": {
                "maphy": 3,
                "minami": 2,
                "yuria": 1,
                "sakura": 1
            },
            "unlocked_maps": ["tutorial", "endless_road"],
            "completed_maps": ["tutorial"],
            "unlocked_achievements": ["first_blood", "first_win"]
        }
    }
}
```

**无存档时的响应** (用户从未上传过):
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "saveData": null
    }
}
```

> 客户端应在 saveData 为 null 时使用本地默认值初始化游戏。

**错误响应**:
```json
// 账号被封禁
{"code": 1003, "message": "账号已被封禁", "data": null}

// 未登录/Token过期
{"code": 401, "message": "未认证", "data": null}
```

**后端处理流程** (SyncServiceImpl.download):
```
1. 验证 JWT Token → 解析 userId
2. 查询 t_user_save_data WHERE user_id = ?
3. 有记录:
   → 将 save_data JSON 字符串通过 Jackson 反序列化为 Map
   → 封装到 SyncDownloadVO.saveData 返回
4. 无记录:
   → 返回 SyncDownloadVO.saveData = null
5. JSON 解析失败 (异常):
   → 返回 saveData = null (降级处理)
```

**客户端处理逻辑** (GDScript 伪代码):
```gdscript
func _on_sync_download_completed(data: Dictionary):
    var save_data = data.get("saveData", null)
    if save_data == null:
        return  # 使用本地默认数据

    GlobalSave.gold = save_data.get("coins", 0)
    GlobalSave.diamond = save_data.get("diamonds", 0)
    GlobalSave.unlocked_characters = save_data.get("unlocked_characters", [])
    GlobalSave.character_levels = save_data.get("character_levels", {})
    GlobalSave.unlocked_maps = save_data.get("unlocked_maps", [])
    GlobalSave.completed_maps = save_data.get("completed_maps", [])
    GlobalSave.unlocked_achievements = save_data.get("unlocked_achievements", [])
    GlobalSave.save_data()  # 持久化到本地文件
```

---

## 4. 涉及的数据库表

| 表名 | 操作 | 说明 |
|------|------|------|
| `t_user_save_data` | INSERT / UPDATE / SELECT | JSON 存档的读写 |

---

## 5. 安全与一致性

### 5.1 封禁检查

游戏端和同步接口在 GameAuthInterceptor 层统一检查 JWT Token 有效性。被封禁用户（status = 1）无法登录，因此也无法获取有效 Token 进行同步操作。

### 5.2 数据一致性

- 上传操作使用 Spring `@Transactional` 事务注解，保证写入原子性
- 上传后清除 Redis 用户缓存（`user:info:{userId}`），保证下次查询数据一致
- 以客户端数据为准的全量覆盖策略，简单可靠

### 5.3 防并发冲突

使用 Redisson 分布式锁（可选，当前 SyncServiceImpl 代码中未显式使用，但项目已配置 RedissonClient，可在需要时方便地添加锁逻辑）：

```java
// 可选的Redisson分布式锁增强方案
RLock lock = redissonClient.getLock("lock:sync:" + userId);
try {
    if (lock.tryLock(5, 10, TimeUnit.SECONDS)) {
        // 执行上传逻辑
    }
} finally {
    lock.unlock();
}
```

### 5.4 防作弊说明

当前设计以客户端数据为准（客户端上传什么就存什么），适合毕业设计场景。

生产环境建议改进：
- 货币数据以服务端为准，客户端只能请求增减操作
- 服务端验证数据合法性（如角色是否合法、数值范围检查等）
- 添加操作日志记录每次同步变更

---

## 6. 游戏端 UI 操作流程

### 6.1 同步入口

在主菜单界面顶部状态栏中，登录后显示"同步"按钮。

### 6.2 上传流程

1. 玩家点击"上传存档"
2. 客户端调用 `NetworkManager.upload_save()` → GlobalSave 序列化为字典 → POST /api/game/sync/upload
3. 成功后提示"存档上传成功"
4. 失败后显示错误信息

### 6.3 下载流程

1. 玩家点击"下载存档"
2. 客户端调用 `NetworkManager.download_save()` → POST /api/game/sync/download
3. 成功后提示"存档下载成功"，用返回数据覆盖本地 GlobalSave
4. 刷新界面数据（角色解锁状态、金币等）
5. 失败后显示错误信息

### 6.4 操作保护

- 操作中按钮显示加载状态，防止重复点击
- 封禁用户无法使用同步功能
