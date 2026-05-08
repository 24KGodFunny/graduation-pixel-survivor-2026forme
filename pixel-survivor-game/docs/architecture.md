# 系统架构文档

## 1. 整体架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Godot 4.0     │    │   Vue3 + Vite   │    │   浏览器/其他    │
│   游戏客户端     │    │   管理后台       │    │   (预留)         │
│                 │    │                 │    │                 │
│ 本地资源文件:    │    │                 │    │                 │
│ - characters.json│    │                 │    │                 │
│ - buffs.json    │    │                 │    │                 │
│ - maps.json     │    │                 │    │                 │
│ - achievements.json│  │                 │    │                 │
│ - daily_tasks.json│  │                 │    │                 │
│ - shop_items.json│   │                 │    │                 │
└────────┬────────┘    └────────┬────────┘    └────────┬────────┘
         │  HTTP/JSON           │  HTTP/JSON           │
         └──────────┬───────────┴──────────────────────┘
                    │
         ┌──────────▼──────────┐
         │   Nginx (可选)       │
         │   反向代理/静态资源   │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   Spring Boot 3.x   │
         │   RESTful API       │
         │   Port: 8080        │
         │                     │
         │  只处理运行时数据:    │
         │  用户/货币/交易/社交  │
         └──────────┬──────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
┌───▼───┐    ┌──────▼──────┐   ┌───▼───┐
│MySQL  │    │   Redis     │   │本地文件│
│8.0    │    │   7.x       │   │(日志) │
│:3306  │    │   :6379     │   │       │
└───────┘    └─────────────┘   └───────┘
```

## 2. 数据归属原则

### 2.1 游戏客户端资源（本地数据）

以下数据由 Godot 游戏客户端资源文件定义，**不存储在数据库中**：

| 资源类型 | 客户端资源文件 | 说明 |
|----------|---------------|------|
| 角色定义 | `data/characters.json` | 角色名、基础属性、技能、武器类型、解锁条件等 |
| Buff定义 | `data/buffs.json` | Buff名称、效果类型、数值、稀有度、持续时间等 |
| 地图/关卡定义 | `data/maps.json` | 地图名、难度、波数、Boss间隔、解锁条件等 |
| 成就定义 | `data/achievements.json` | 成就名、条件类型、条件值、奖励等 |
| 每日任务定义 | `data/daily_tasks.json` | 任务名、类型、目标值、奖励等 |
| 商品详情 | `data/shop_items.json` | 商品名、描述、图片、效果类型、效果值等 |

### 2.2 后端数据库（运行时数据）

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

### 2.3 编码对应关系

数据库中的 `item_code`、`character_code`、`achievement_code`、`task_code`、`map_code` 等字段，与游戏客户端资源文件中的 `id` 字段一一对应。客户端通过这些编码关联本地资源获取完整的名称、描述、图片等信息。

## 3. 技术选型

| 组件 | 技术 | 版本 | 说明 |
|------|------|------|------|
| 游戏引擎 | Godot | 4.0 | GDScript，像素风游戏 |
| 前端框架 | Vue 3 | 3.4+ | Composition API |
| 构建工具 | Vite | 5.x | 快速开发构建 |
| UI组件库 | Element Plus | 2.x | 管理后台UI |
| 状态管理 | Pinia | 2.x | Vue3状态管理 |
| 后端框架 | Spring Boot | 3.2+ | Java 17 |
| ORM | MyBatis-Plus | 3.5+ | 简化数据库操作 |
| 认证 | Spring Security + JWT | - | 认证授权 |
| 缓存 | Redis + Caffeine | - | 多级缓存 |
| 分布式锁 | Redisson | 3.x | Redis分布式锁 |
| API文档 | Knife4j | 4.x | Swagger增强 |
| 数据库 | MySQL | 8.0 | 关系型数据库 |

## 4. 后端分层架构

```
┌─────────────────────────────────────────┐
│              Controller 层              │
│   接收请求、参数校验、调用Service         │
├─────────────────────────────────────────┤
│              Service 层                 │
│   业务逻辑、事务管理、缓存操作            │
├─────────────────────────────────────────┤
│              Mapper 层                  │
│   数据库访问（MyBatis-Plus）             │
├─────────────────────────────────────────┤
│              Entity 层                  │
│   数据实体、DTO、VO                     │
└─────────────────────────────────────────┘
```

### 4.1 包结构

```
com.pixelsurvivor
├── PixelSurvivorApplication.java    # 启动类
├── config/                           # 配置类
│   ├── RedisConfig.java             # Redis配置
│   ├── SecurityConfig.java          # Security配置
│   ├── CorsConfig.java              # 跨域配置
│   ├── MyBatisPlusConfig.java       # MyBatis-Plus配置
│   ├── Knife4jConfig.java           # API文档配置
│   └── CaffeineConfig.java          # 本地缓存配置
├── common/                           # 通用组件
│   ├── result/
│   │   ├── Result.java              # 统一返回
│   │   └── ResultCode.java          # 错误码枚举
│   ├── exception/
│   │   ├── BusinessException.java   # 业务异常
│   │   └── GlobalExceptionHandler.java # 全局异常处理
│   ├── annotation/
│   │   └── OperationLog.java        # 操作日志注解
│   ├── aspect/
│   │   └── OperationLogAspect.java  # 操作日志切面
│   ├── util/
│   │   ├── JwtUtil.java             # JWT工具
│   │   ├── OrderNoUtil.java         # 订单号生成
│   │   └── IpUtil.java              # IP工具
│   └── constant/
│       └── RedisConstant.java       # Redis Key常量
├── module/
│   ├── admin/                        # 管理员模块
│   │   ├── controller/
│   │   ├── service/
│   │   ├── mapper/
│   │   ├── entity/
│   │   └── dto/
│   ├── user/                         # 用户模块
│   ├── shop/                         # 商城模块(运营数据管理)
│   ├── order/                        # 订单模块
│   ├── friend/                       # 好友模块
│   ├── sign/                         # 签到模块
│   ├── achievement/                  # 成就进度模块
│   ├── task/                         # 任务进度模块
│   ├── mail/                         # 邮件模块
│   ├── ranking/                      # 排行榜模块
│   ├── character/                    # 用户角色状态模块
│   ├── record/                       # 游戏记录模块
│   ├── recharge/                     # 充值模块
│   └── sync/                         # 数据同步模块
└── interceptor/
    ├── JwtAuthFilter.java            # JWT认证过滤器
    └── RateLimitInterceptor.java     # 限流拦截器
```

**说明**：已移除 `buff/`、`map/` 模块，因为 Buff 定义和地图定义由游戏客户端资源管理，后端不再存储和管理这些游戏内容数据。`character/` 模块保留但职责变更为只管理用户角色状态（解锁、强化），不再管理角色定义。`achievement/` 和 `task/` 模块保留但职责变更为只管理用户进度，不再管理成就/任务定义。

## 5. 缓存架构

### 5.1 多级缓存

```
请求 → Caffeine(L1, 5min) → Redis(L2, 15-40min) → MySQL
```

### 5.2 缓存策略

| 数据类型 | L1缓存 | L2缓存 | 防穿透 | 防击穿 | 防雪崩 |
|----------|--------|--------|--------|--------|--------|
| 商品运营数据 | Caffeine 5min | Redis 30min+random | 布隆过滤器 | 互斥锁 | 随机TTL |
| 用户信息 | Caffeine 3min | Redis 20min+random | 空值缓存 | 互斥锁 | 随机TTL |
| 用户背包 | Caffeine 3min | Redis 15min+random | 空值缓存 | 互斥锁 | 随机TTL |
| 用户角色状态 | Caffeine 3min | Redis 15min+random | 空值缓存 | 互斥锁 | 随机TTL |
| 排行榜 | - | Redis Sorted Set | - | - | - |
| 在线状态 | - | Redis Set | - | - | - |

**说明**：已移除 Buff 定义、地图数据的缓存项，因为这些数据由游戏客户端本地资源管理，后端不再存储和查询。

### 5.3 Redis Key 设计

```
# 用户
user:info:{userId}              Hash    TTL 20min+random
user:token:{userId}             String  TTL 2h
user:online                     Set     无过期

# 商品运营数据
shop:items:list                 String  TTL 30min+random
shop:item:{itemCode}            Hash    逻辑过期1h

# 排行榜
ranking:wave:{season}           Sorted Set
ranking:kill:{season}           Sorted Set
ranking:score:{season}          Sorted Set

# 好友
friend:list:{userId}            Set     TTL 10min

# 签到
sign:record:{userId}:{month}    Bitmap  TTL 40天

# 用户背包
user:items:{userId}             String  TTL 15min+random

# 用户角色状态
user:characters:{userId}        String  TTL 15min+random

# 分布式锁
lock:shop:item:{itemCode}       String  TTL 10s
lock:user:purchase:{userId}     String  TTL 10s
lock:sign:{userId}              String  TTL 5s

# 布隆过滤器
bloom:user:id                   BloomFilter
bloom:shop:item:code            BloomFilter

# 限流
rate:api:{ip}                   String  TTL 1min
rate:purchase:{userId}          String  TTL 1s
```

## 6. 安全架构

### 6.1 认证流程

```
客户端 → POST /login (username, password)
       ← JWT Token (2h有效期)

客户端 → GET /api/xxx (Header: Authorization: Bearer {token})
       → JwtAuthFilter 验证Token
       → 解析userId/adminId
       → 放行到Controller
       ← 响应数据
```

### 6.2 权限模型

| 路径前缀 | 认证要求 | 说明 |
|----------|----------|------|
| `/api/game/login`, `/api/game/register` | 无需认证 | 公开接口 |
| `/api/game/**` | Game JWT | 游戏用户Token |
| `/api/admin/login` | 无需认证 | 管理员登录 |
| `/api/admin/**` | Admin JWT | 管理员Token |

**说明**：已移除 `/api/game/buffs`、`/api/game/maps` 等公开数据接口，因为 Buff 定义和地图定义由游戏客户端本地资源提供，不再需要从后端获取。

### 6.3 安全措施

- 密码BCrypt加密（强度10）
- JWT Token签名（HS256）
- CORS白名单配置
- SQL注入防护（MyBatis-Plus参数化）
- XSS防护（输入过滤）
- API限流（令牌桶算法）
- 敏感操作日志记录

## 7. 支付架构

### 7.1 充值流程（模拟模式）

```
客户端 → POST /api/game/recharge/create
       → 创建充值订单（status=0）
       → 模拟支付成功
       → 更新订单状态（status=1）
       → 发放钻石到用户账户
       ← 返回充值结果
```

### 7.2 真实支付对接预留

```java
/*
 * 支付宝对接步骤：
 * 1. 申请支付宝开放平台商户账号
 * 2. 引入 alipay-sdk-java 依赖
 * 3. 配置 appId、privateKey、alipayPublicKey
 * 4. 实现 createPayRequest() 生成支付表单/链接
 * 5. 实现 alipayNotify() 处理异步回调
 *
 * 微信支付对接步骤：
 * 1. 申请微信支付商户号
 * 2. 引入 wechatpay-java 依赖
 * 3. 配置 merchantId、privateKey、serialNo等
 * 4. 实现 createPayRequest() 生成预支付订单
 * 5. 实现 wechatPayNotify() 处理异步回调
 */
```

## 8. 好友系统架构

### 8.1 当前实现（REST API）

```
客户端 → GET /api/game/friends
       → 查询好友列表（MySQL + Redis缓存）
       ← 返回好友列表（含在线状态）
```

### 8.2 WebSocket升级路径

```
1. 添加依赖：spring-boot-starter-websocket
2. 创建 WebSocket 配置和 Handler
3. 用户连接时注册到 Redis（user:ws:{userId}）
4. 好友请求通过 WebSocket 实时推送
5. 在线状态变更广播给所有好友
6. 心跳检测（30秒间隔）
7. 多实例部署使用 Redis Pub/Sub 同步
```

## 9. 部署架构

### 9.1 开发环境

```
本地开发：
- MySQL: localhost:3306
- Redis: localhost:6379
- 后端: localhost:8080
- 前端: localhost:5173 (Vite dev server)
- 游戏: Godot编辑器直接运行
```

### 9.2 生产环境（参考）

```
┌─────────────┐
│   Nginx     │ ← 静态资源 + 反向代理
│   :80/:443  │
└──────┬──────┘
       │
┌──────▼──────┐    ┌─────────────┐
│ Spring Boot │    │   Vue3      │
│ (JAR)       │    │   (静态部署) │
│ :8080       │    │             │
└──────┬──────┘    └─────────────┘
       │
┌──────▼──────┐    ┌─────────────┐
│   MySQL     │    │   Redis     │
│   :3306     │    │   :6379     │
└─────────────┘    └─────────────┘
```

## 10. 开发规范

### 10.1 命名规范
- 数据库表名：`t_` 前缀，小写下划线
- Java类名：大驼峰
- Java方法名/变量名：小驼峰
- 常量：全大写下划线
- API路径：小写，用 `-` 分隔
- 游戏资源编码：小写下划线，如 `char_warrior`、`item_heal_potion`、`ach_kill_100`

### 10.2 注释规范
- 类注释：说明类的作用
- 方法注释：说明方法功能、参数、返回值
- 复杂逻辑：行内注释说明

### 10.3 Git规范
- 主分支：main
- 开发分支：dev
- 功能分支：feature/xxx
- 提交信息：`类型: 描述`（如 `feat: 添加商品管理接口`）