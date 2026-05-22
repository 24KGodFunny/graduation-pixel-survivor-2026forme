# API 接口文档

## 1. 概述

- **Base URL**: `http://localhost:8080/api`
- **数据格式**: JSON
- **认证方式**: JWT Token（Header: `Authorization: Bearer {token}`）
- **API文档**: Knife4j `http://localhost:8080/doc.html`

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
        "size": 10,
        "current": 1,
        "pages": 10
    }
}
```

## 3. 错误码

| code | 说明 |
|------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未认证 / Token过期 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 429 | 请求过于频繁（限流） |
| 500 | 服务器内部错误 |
| 1001 | 用户名已存在 |
| 1002 | 用户名或密码错误 |
| 1003 | 账号已被封禁 |

## 4. 游戏端接口 (/api/game)

### 4.1 用户注册

**POST /api/game/user/register**

无需认证。

请求体：
```json
{
    "username": "player001",
    "password": "123456",
    "nickname": "勇者一号"
}
```

响应：
```json
{
    "code": 200,
    "message": "注册成功",
    "data": {
        "id": 1,
        "username": "player001",
        "nickname": "勇者一号"
    }
}
```

> 新用户默认赠送 500 游戏币 + 50 钻石。

---

### 4.2 用户登录

**POST /api/game/user/login**

无需认证。

请求体：
```json
{
    "username": "player001",
    "password": "123456"
}
```

响应：
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiJ9...",
        "userId": 1,
        "nickname": "勇者一号"
    }
}
```

> Token 有效期：2 小时。Token 类型标记为 "game"，只能访问 /api/game/** 路径。

---

### 4.3 获取用户信息

**GET /api/game/user/info**

需要认证（Game Token）。

响应：
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
        "totalPlayTime": 3600,
        "maxWave": 15,
        "status": 0,
        "isOnline": 1
    }
}
```

> userId 由 GameAuthInterceptor 从 JWT Token 中解析注入，客户端无需传参。

---

### 4.4 修改用户信息

**PUT /api/game/user/info**

需要认证（Game Token）。

请求体：
```json
{
    "nickname": "新昵称",
    "avatar": "avatar_01.png"
}
```

响应：
```json
{
    "code": 200,
    "message": "操作成功",
    "data": null
}
```

---

### 4.5 上传存档

**POST /api/game/sync/upload**

需要认证（Game Token）。将客户端游戏进度 JSON 上传至服务器，使用 Redisson 分布式锁防止并发写入。

请求体：
```json
{
    "saveData": {
        "coins": 1500,
        "diamonds": 60,
        "unlocked_characters": ["maphy", "minami", "yuria"],
        "character_levels": {"maphy": 3, "minami": 2, "yuria": 1},
        "unlocked_maps": ["tutorial", "endless_road"],
        "completed_maps": ["tutorial"],
        "unlocked_achievements": ["first_blood", "first_win"]
    }
}
```

响应：
```json
{
    "code": 200,
    "message": "数据上传成功",
    "data": null
}
```

> 详细说明见《数据同步接口文档》(sync-api-design.md)。

---

### 4.6 下载存档

**POST /api/game/sync/download**

需要认证（Game Token）。从服务器获取用户存档 JSON。

请求体：无。

响应：
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "saveData": {
            "coins": 1500,
            "diamonds": 60,
            "unlocked_characters": ["maphy", "minami", "yuria"],
            "character_levels": {"maphy": 3, "minami": 2, "yuria": 1},
            "unlocked_maps": ["tutorial", "endless_road"],
            "completed_maps": ["tutorial"],
            "unlocked_achievements": ["first_blood", "first_win"]
        }
    }
}
```

> 如果用户从未上传过存档，saveData 为 null，客户端使用本地默认值。

---

## 5. 管理端接口 (/api/admin)

### 5.1 管理员登录

**POST /api/admin/login**

无需认证。

请求体：
```json
{
    "username": "admin",
    "password": "admin123"
}
```

响应：
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiJ9...",
        "adminId": 1,
        "username": "admin",
        "role": "SUPER_ADMIN"
    }
}
```

> Token 有效期：8 小时。Token 类型标记为 "admin"。

---

### 5.2 注册管理员

**POST /api/admin/register**

需要认证（Admin Token）。记录操作日志。

请求体：
```json
{
    "username": "newadmin",
    "password": "123456",
    "role": "ADMIN"
}
```

---

### 5.3 仪表盘概览

**GET /api/admin/dashboard/overview**

需要认证（Admin Token）。

响应：
```json
{
    "code": 200,
    "data": {
        "totalUsers": 156,
        "totalOrders": 0,
        "totalRevenue": 0,
        "todayNewUsers": 12,
        "todayOrders": 0,
        "todayRevenue": 0
    }
}
```

> totalOrders、totalRevenue、todayOrders、todayRevenue 固定为 0（购买/支付功能未实现，保留字段仅为前端结构兼容）。

**兼容接口**：
- `GET /api/admin/dashboard/stats` — 等同 `/dashboard/overview`

---

### 5.4 每日统计数据

**GET /api/admin/dashboard/daily-stats**

需要认证（Admin Token）。

查询参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| range | string | "7d" | 时间范围: 7d / 30d / 3m / 6m |

响应：
```json
{
    "code": 200,
    "data": [
        {"date": "2026-05-16", "newUsers": 5, "newOrders": 0, "revenue": 0},
        {"date": "2026-05-17", "newUsers": 8, "newOrders": 0, "revenue": 0}
    ]
}
```

**兼容接口**：
- `GET /api/admin/dashboard/daily?range=7d` — 等同 `/dashboard/daily-stats`

---

### 5.5 用户列表

**GET /api/admin/users**

需要认证（Admin Token）。

查询参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | int | 1 | 页码 |
| size | int | 20 | 每页数量 |

响应：标准分页格式，records 为 User 实体数组。

---

### 5.6 封禁用户

**PUT /api/admin/users/{id}/ban**

需要认证（Admin Token）。将用户 status 设置为 1（封禁状态）。记录操作日志。

响应：
```json
{
    "code": 200,
    "message": "用户已封禁",
    "data": null
}
```

---

### 5.7 解封用户

**PUT /api/admin/users/{id}/unban**

需要认证（Admin Token）。将用户 status 设置为 0（正常状态）。记录操作日志。

---

### 5.8 根据用户名查询用户详情

**GET /api/admin/users/detail-by-username?username={username}**

需要认证（Admin Token）。

响应：
```json
{
    "code": 200,
    "data": {
        "user": {
            "id": 1,
            "username": "player001",
            "nickname": "勇者一号",
            "gameCoin": 1500,
            "diamond": 60,
            "level": 5,
            "exp": 2300
        },
        "saveData": {
            "unlocked_characters": ["maphy", "minami"],
            "character_levels": {"maphy": 3, "minami": 2},
            "unlocked_maps": ["tutorial", "endless_road"],
            "completed_maps": ["tutorial"],
            "unlocked_achievements": [],
            "coins": 1500,
            "diamonds": 60,
            "mapDefinitions": [...],
            "characterDefinitions": [...]
        }
    }
}
```

> saveData 中包含 `mapDefinitions` 和 `characterDefinitions` 数组，供前端渲染编辑界面时使用。

---

### 5.9 根据用户ID查询用户详情

**GET /api/admin/users/{userId}/detail**

需要认证（Admin Token）。响应格式与 5.8 完全一致。

---

### 5.10 编辑用户信息

**PUT /api/admin/users/{userId}**

需要认证（Admin Token）。记录操作日志。

请求体：
```json
{
    "nickname": "新昵称"
}
```

> 当前仅支持修改昵称字段。

---

### 5.11 编辑用户存档数据

**PUT /api/admin/users/{userId}/save-data**

需要认证（Admin Token）。修改 t_user_save_data 表中的 JSON 数据。记录操作日志。

请求体：
```json
{
    "coins": 2000,
    "diamonds": 100,
    "unlocked_characters": ["maphy", "minami", "yuria", "sakura"],
    "character_levels": {"maphy": 5, "minami": 3, "yuria": 2, "sakura": 1},
    "unlocked_maps": ["tutorial", "endless_road", "wasteland"],
    "completed_maps": ["tutorial", "endless_road"],
    "unlocked_achievements": ["first_blood", "first_win", "kill_100"]
}
```

> 采用增量合并策略：传入的字段覆盖，未传入的字段保留原值。

---

### 5.12 删除用户

**DELETE /api/admin/users/{userId}**

需要认证（Admin Token）。删除用户账号及其关联的存档数据（t_user + t_user_save_data）。记录操作日志。

---

### 5.13 管理员列表

**GET /api/admin/admins**

需要认证（Admin Token）。

查询参数：page (默认1)、size (默认20)。

响应：分页格式，每条管理员记录的密码字段已清除。

---

### 5.14 删除管理员

**DELETE /api/admin/admins/{id}**

需要认证（Admin Token）。不允许删除自己，不允许删除 SUPER_ADMIN。记录操作日志。

---

### 5.15 修改密码

**PUT /api/admin/password**

需要认证（Admin Token）。记录操作日志。

请求体：
```json
{
    "oldPassword": "old123",
    "newPassword": "new456"
}
```

---

### 5.16 操作日志列表

**GET /api/admin/logs**

需要认证（Admin Token）。

查询参数：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认 1 |
| size | int | 否 | 每页数量，默认 20 |
| adminUsername | string | 否 | 管理员用户名（模糊匹配） |
| module | string | 否 | 操作模块（精确匹配） |
| startDate | string | 否 | 起始日期 yyyy-MM-dd |
| endDate | string | 否 | 截止日期 yyyy-MM-dd |

响应示例：
```json
{
    "code": 200,
    "data": {
        "records": [
            {
                "id": 1,
                "adminId": 1,
                "adminUsername": "admin",
                "module": "用户管理",
                "operation": "封禁",
                "description": "封禁用户",
                "method": "AdminController.banUser",
                "params": "[1]",
                "response": "{\"code\":200,...}",
                "ip": "127.0.0.1",
                "errorMsg": null,
                "costTime": 15,
                "createdAt": "2026-05-20 15:00:00"
            }
        ],
        "total": 50,
        "size": 20,
        "current": 1
    }
}
```

---

## 6. 接口认证说明

### 6.1 路径权限划分

| 路径前缀 | 认证方式 | 拦截器 |
|----------|---------|--------|
| `/api/game/user/login` | 无需认证 | — |
| `/api/game/user/register` | 无需认证 | — |
| `/api/game/**` (其他) | Game JWT Token (2h) | GameAuthInterceptor |
| `/api/admin/login` | 无需认证 | — |
| `/api/admin/**` (其他) | Admin JWT Token (8h) | AdminAuthInterceptor |

### 6.2 Token 使用方式

在需要认证的请求头中添加：
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

### 6.3 Token 过期处理

- 游戏端 Token (2h) 过期或无效返回 `{code: 401}`
- 管理端 Token (8h) 过期或无效返回 `{code: 401}`
- Token 类型不匹配（如用游戏Token访问管理端接口）返回 `{code: 403}`
- 客户端需在收到 401 后重新登录获取新 Token

### 6.4 限流说明

对标注 `@RateLimit` 注解的接口，RateLimitInterceptor 会按 IP 进行固定窗口计数限流。超出限制返回 HTTP 429：
```json
{
    "code": 429,
    "message": "请求过于频繁，请 N 秒后重试",
    "data": null
}
```
