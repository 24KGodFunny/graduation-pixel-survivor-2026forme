# 系统架构文档

## 1. 整体架构

```
┌──────────────────────┐         ┌──────────────────────┐
│   Godot 4 游戏客户端  │         │   Vue3 + Vite        │
│   (GDScript)         │         │   管理后台            │
│                      │         │                      │
│  本地数据定义:         │         │  页面:               │
│  - database.gd       │         │  - 登录 (黑洞动画)    │
│    (角色/武器/敌人/   │         │  - 仪表盘 (ECharts)  │
│     地图/Boss定义)    │         │  - 用户管理           │
│                      │         │  - 用户数据管理       │
│                      │         │  - 操作日志           │
│                      │         │  - 管理员管理         │
│                      │         │  - 修改密码           │
└──────────┬───────────┘         └──────────┬───────────┘
           │  HTTP REST                      │  HTTP REST
           │  JSON                           │  JSON
           │                                 │
     ┌─────┴─────────────────────────────────┴─────┐
     │                                              │
     │         Spring Boot 3.2.5 (Java 17)          │
     │         Port: 8080                           │
     │                                              │
     │  ┌──────────────────────────────────────┐   │
     │  │         Controller 层                 │   │
     │  │  GameUserController                  │   │
     │  │  GameSyncController                  │   │
     │  │  AdminController                     │   │
     │  ├──────────────────────────────────────┤   │
     │  │         Interceptor 层               │   │
     │  │  GameAuthInterceptor (游戏JWT验证)    │   │
     │  │  AdminAuthInterceptor (管理端JWT验证) │   │
     │  │  RateLimitInterceptor (Redis限流)    │   │
     │  ├──────────────────────────────────────┤   │
     │  │         Service 层                   │   │
     │  │  UserService / UserServiceImpl       │   │
     │  │  SyncService / SyncServiceImpl       │   │
     │  │  AdminService / AdminServiceImpl     │   │
     │  ├──────────────────────────────────────┤   │
     │  │         Mapper 层                    │   │
     │  │  UserMapper                          │   │
     │  │  UserSaveDataMapper                  │   │
     │  │  AdminMapper                         │   │
     │  │  AdminOperationLogMapper             │   │
     │  │  CharacterDefinitionMapper           │   │
     │  │  MapDefinitionMapper                 │   │
     │  ├──────────────────────────────────────┤   │
     │  │         Entity 层                    │   │
     │  │  User / Admin / UserSaveData          │   │
     │  │  AdminOperationLog                    │   │
     │  │  CharacterDefinition / MapDefinition │   │
     │  └──────────────────────────────────────┘   │
     │                                              │
     │  AOP: OperationLogAspect (操作日志自动记录)    │
     │  Task: OnlineUserCleanupTask (每5分钟清理)    │
     │                                              │
     └──────────┬───────────────┬───────────────────┘
                │               │
          ┌─────▼─────┐   ┌────▼─────┐
          │   MySQL   │   │  Redis   │
          │   8.0     │   │          │
          │  :3306    │   │  :6379   │
          └───────────┘   └──────────┘
```

## 2. 技术选型

| 组件 | 技术 | 版本 | 说明 |
|------|------|------|------|
| 游戏引擎 | Godot | 4.x | GDScript，像素风类幸存者游戏 |
| 前端框架 | Vue 3 | 3.4+ | Composition API |
| 构建工具 | Vite | 5.x | 前端开发构建 |
| UI组件库 | Element Plus | 2.x | 管理后台UI |
| 状态管理 | Pinia | 2.x | Vue 3状态管理 |
| 图表库 | ECharts | 5.x | 仪表盘图表 |
| HTTP客户端 | Axios | - | 前端HTTP请求 |
| 后端框架 | Spring Boot | 3.2.5 | Java 17 |
| ORM框架 | MyBatis-Plus | 3.5+ | 简化数据库操作 |
| 安全框架 | Spring Security | - | CSRF禁用，无状态会话 |
| 密码加密 | BCrypt | - | 密码哈希存储 |
| JWT | jjwt | 0.12+ | HMAC-SHA256签名 |
| 数据库 | MySQL | 8.0 | InnoDB，utf8mb4 |
| 缓存 | Redis | 7.x | 多种缓存策略 |
| 分布式锁 | Redisson | 3.x | Redis分布式锁 |
| 定时任务 | Spring @Scheduled | - | 在线用户定时清理 |
| AOP | Spring AOP | - | 操作日志自动记录 |
| API文档 | Knife4j | 4.x | Swagger增强，/doc.html |
| 构建工具 | Maven | - | 后端依赖管理 |

## 3. 后端包结构

```
com.pixelsurvivor
├── PixelSurvivorApplication.java     # 启动类（启用定时任务）
├── config/                            # 配置类
│   ├── SecurityConfig.java           # Spring Security（CSRF禁用，无状态会话，全部放行）
│   ├── WebConfig.java                # CORS配置 + 拦截器注册
│   ├── RedisConfig.java              # Redis连接配置
│   └── RedissonConfig.java           # Redisson分布式锁客户端
├── common/                            # 通用组件
│   ├── result/
│   │   ├── Result.java               # 统一响应格式 {code, message, data}
│   │   └── ResultCode.java           # 错误码枚举
│   ├── exception/
│   │   ├── BusinessException.java    # 业务异常
│   │   └── GlobalExceptionHandler.java
│   ├── annotation/
│   │   ├── OperationLog.java         # 操作日志注解
│   │   └── RateLimit.java            # 限流注解
│   ├── aspect/
│   │   └── OperationLogAspect.java  # AOP切面：自动记录管理端操作
│   ├── constant/
│   │   └── RedisConstant.java       # Redis Key前缀常量
│   └── util/
│       └── JwtUtil.java             # JWT工具（生成/解析/验证双Token）
├── config/interceptor/
│   ├── GameAuthInterceptor.java     # 游戏端JWT拦截器（验证game token）
│   ├── AdminAuthInterceptor.java    # 管理端JWT拦截器（验证admin token）
│   └── RateLimitInterceptor.java    # Redis固定窗口限流拦截器
├── controller/
│   ├── GameUserController.java      # 游戏端：注册/登录/用户信息
│   ├── GameSyncController.java      # 游戏端：存档上传/下载
│   └── AdminController.java         # 管理端：全部管理功能
├── service/
│   ├── UserService.java / UserServiceImpl.java
│   ├── SyncService.java / SyncServiceImpl.java
│   └── AdminService.java / AdminServiceImpl.java
├── mapper/
│   ├── UserMapper.java
│   ├── UserSaveDataMapper.java
│   ├── AdminMapper.java
│   ├── AdminOperationLogMapper.java
│   ├── CharacterDefinitionMapper.java
│   └── MapDefinitionMapper.java
├── entity/
│   ├── User.java                     # t_user
│   ├── Admin.java                    # t_admin
│   ├── UserSaveData.java             # t_user_save_data
│   ├── AdminOperationLog.java        # t_admin_operation_log
│   ├── CharacterDefinition.java      # t_character_definition
│   ├── MapDefinition.java            # t_map_definition
│   └── vo/
│       ├── DailyStatsVO.java         # 每日统计视图对象
│       └── UserItemVO.java           # 用户物品视图对象
├── dto/
│   ├── SyncUploadDTO.java            # 存档上传请求DTO
│   └── SyncDownloadVO.java           # 存档下载响应VO
└── task/
    └── OnlineUserCleanupTask.java    # 定时清理离线用户（每5分钟）
```

## 4. Redis 缓存架构

本项目使用 Redis 实现了 5 种核心功能，覆盖缓存、分布式锁、限流和在线状态管理。

### 4.1 功能一览

| 序号 | 功能 | Redis数据结构 | Key格式 | TTL/策略 | 说明 |
|------|------|-------------|---------|----------|------|
| 1 | 用户信息缓存 | String (Hash预留) | `user:info:{userId}` | 30分钟 | Cache-Aside模式：查询时先查Redis，未命中查MySQL后回填；更新时删除缓存 |
| 2 | 仪表盘统计缓存 | 间接缓存 | 无独立Key | 数据库联表查询 | 仪表盘总览和每日统计直接查询MySQL（因涉及按日期分组聚合），通过分页和索引优化 |
| 3 | 分布式锁 | Redisson Lock | `lock:sync:{userId}` | 自动续期 | 存档上传时使用Redisson分布式锁，防止同一用户并发上传导致数据损坏 |
| 4 | API限流 | String (INCR) | `rate:api:{IP地址}` | 可配时间窗口 | 固定窗口算法：每个IP在窗口期内最多N次请求。Redis不可用时自动降级放行（fail-open） |
| 5 | 在线用户追踪 | Set | `user:online` | 定时清理 | 登录时将userId加入Set；@Scheduled每5分钟扫描Set，将数据库中is_online=0的用户移除 |

### 4.2 用户信息缓存流程（Cache-Aside）

```
读取流程:
  GET /api/game/user/info
    → 查询 Redis: user:info:{userId}
    → 命中: 直接返回
    → 未命中: 查询 MySQL t_user → 返回给客户端

写入流程:
  更新用户信息（昵称/头像/货币/统计数据）
    → 更新 MySQL
    → DELETE Redis: user:info:{userId}  (删除缓存，下次查询时自动回填)
```

### 4.3 限流拦截器详细设计

```
拦截路径: /api/**  (通过 @RateLimit 注解标注方法)
算法: 固定窗口计数 (Fixed Window)
实现: Redis INCR + EXPIRE

流程:
  1. 提取客户端真实 IP (X-Forwarded-For → X-Real-IP → RemoteAddr)
  2. 拼接 Key: rate:api:{ip}
  3. 执行 INCR rate:api:{ip}
  4. 若 INCR 返回 1 → 设置过期时间 (window秒)
  5. 若 count > maxRequests → 返回 HTTP 429

容错: Redis 连接异常时 fail-open（记录警告日志，放行请求）
```

### 4.4 在线用户追踪详细设计

```
记录上线:
  UserServiceImpl.login()
    → 更新 MySQL: is_online = 1
    → Redis SADD user:online {userId}

定时清理 (OnlineUserCleanupTask):
  每 5 分钟执行:
    → SMEMBERS user:online 获取所有在线userId
    → 遍历每个userId，查询 MySQL: is_online 字段
    → 若 is_online != 1 → SREM user:online {userId}
  
  容错: Redis 不可用时跳过本次清理
```

## 5. 安全架构

### 5.1 JWT 双Token认证体系

| 对比维度 | 游戏端Token | 管理端Token |
|----------|------------|------------|
| 类型标记 | `type: "game"` | `type: "admin"` |
| 有效时长 | 2小时 | 8小时 |
| 签发内容 | userId, username | adminId, username, role |
| 拦截器 | GameAuthInterceptor | AdminAuthInterceptor |
| 路径范围 | /api/game/** | /api/admin/** |
| 放行路径 | /api/game/user/login, /api/game/user/register | /api/admin/login |

### 5.2 认证流程

```
客户端 → POST /api/game/user/login (username, password)
       ← JWT Game Token (2h有效期)

客户端 → GET /api/game/user/info (Header: Authorization: Bearer {token})
       → GameAuthInterceptor 验证Token签名、有效期、类型
       → 解析userId → setAttribute("userId", userId)
       → Controller 通过 @RequestAttribute Long userId 获取
       ← 响应数据
```

### 5.3 Spring Security 配置

- CSRF: 已禁用（REST API不需要）
- 会话管理: STATELESS（JWT无状态认证）
- 表单登录/Basic认证: 已禁用
- 请求授权: 全部放行（`anyRequest().permitAll()`），认证由自定义拦截器处理
- CORS: 允许所有来源，支持 GET/POST/PUT/DELETE/OPTIONS

### 5.4 安全措施汇总

- 密码存储：BCrypt 加密（Spring Security BCryptPasswordEncoder）
- JWT签名：HMAC-SHA256（jjwt库），密钥可配置
- CORS：WebConfig 中配置白名单
- SQL注入：MyBatis-Plus 参数化查询
- API限流：Redis 固定窗口计数器
- 操作审计：AOP 自动记录管理端所有敏感操作（含IP、参数、响应、耗时）
- 封禁检查：被禁用户（status=1）无法登录和同步数据

## 6. AOP操作日志

`OperationLogAspect` 通过 `@Around` 环绕通知拦截所有标注 `@OperationLog` 注解的方法，自动记录：

- 操作人 (adminId, adminUsername 从JWT解析)
- 操作模块 (module: 用户管理/用户数据管理/管理员管理)
- 操作类型 (operation: CREATE/UPDATE/DELETE/LOGIN)
- 操作描述 (description)
- 请求参数 JSON（截断至1000字符）
- 响应结果 JSON（截断至1000字符）
- 操作IP地址
- 异常信息
- 耗时（毫秒）

日志通过 JDBC Template 直接写入 `t_admin_operation_log` 表（不走 MyBatis-Plus），确保即使业务异常也能记录日志（finally 块中执行）。

## 7. 部署环境

### 7.1 开发环境

| 组件 | 地址 | 说明 |
|------|------|------|
| MySQL | localhost:3306 | 数据库名 pixel_survivor，账号 root / 密码 1234 |
| Redis | localhost:6379 | 默认配置 |
| 后端 | localhost:8080 | Spring Boot 内嵌 Tomcat |
| 前端 | localhost:5173 | Vite 开发服务器 |
| 游戏 | Godot编辑器 | 直接运行 project.godot |
| API文档 | localhost:8080/doc.html | Knife4j |

### 7.2 初始化步骤

1. 启动 MySQL，执行 `backend/sql/init.sql` 初始化数据库
2. 启动 Redis
3. 启动后端：`cd backend && mvn spring-boot:run`
4. 启动前端：`cd frontend && npm install && npm run dev`
5. 打开 Godot 编辑器，导入 `game-demo/project.godot`，点击运行
6. 管理端默认账号：admin / admin123
7. API文档访问：http://localhost:8080/doc.html

## 8. 开发规范

### 8.1 命名规范

- 数据库表名：`t_` 前缀，小写下划线（如 `t_user_save_data`）
- Java类名：大驼峰（如 `GameUserController`）
- Java方法名/变量名：小驼峰（如 `getUserById`）
- 常量：全大写下划线（如 `USER_INFO`）
- API路径：小写，用 `-` 分隔（如 `/api/admin/daily-stats`）
- 游戏资源编码：小写+下划线（如 `char_warrior`、`map_endless_road`）

### 8.2 注释规范

- 类注释：使用 JavaDoc 格式说明类的职责
- 方法注释：说明功能、参数、返回值、异常
- 复杂逻辑：行内注释说明

### 8.3 Git规范

- 主分支：main（远程）/ master（本地）
- 提交信息格式：`类型: 描述`（如 `feat: 添加Redis限流拦截器`）
