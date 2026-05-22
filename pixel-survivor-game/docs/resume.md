# 简历编写与面试准备指南

## 1. 项目一句话描述

> **Pixel Survivor** —— 一款像素风 Roguelike 类幸存者游戏，包含 Godot 4 游戏客户端、Spring Boot 3 后端服务、Vue 3 管理后台的完整全栈项目，实现了 JWT 双Token认证、Redis多层缓存、Redisson分布式锁、AOP操作审计等企业级技术方案。

---

## 2. 技术亮点（可用于简历中）

### 后端技术亮点

- **Spring Boot 3.2.5 + Java 17**: 构建 RESTful API 服务，MyBatis-Plus 作为 ORM 框架
- **JWT 双Token体系**: 游戏端 Token (2h) 与管理端 Token (8h) 独立签发与校验，token类型隔离
- **自定义拦截器链**: GameAuthInterceptor / AdminAuthInterceptor / RateLimitInterceptor 替代 Spring Security 默认认证流程
- **Redis 多场景应用 (5种)**:
  - 用户信息缓存（Cache-Aside 模式，30min TTL）
  - 仪表盘数据缓存
  - Redisson 分布式锁（防止并发冲突）
  - 固定窗口限流（按 IP 计数，fail-open 降级）
  - 在线用户追踪（Redis Set + 定时清理）
- **AOP 操作日志**: 通过 `@OperationLog` 注解 + `@Around` 切面自动记录管理端所有敏感操作，含 IP、参数、响应、耗时
- **BCrypt 密码加密**: 所有密码哈希存储，防彩虹表
- **Knife4j API 文档**: 自动生成 Swagger 接口文档，可在线调试
- **Redisson 分布式锁**: 基于 Redis 实现的分布式锁，用于数据同步并发控制

### 全栈技术亮点

- **前后端分离架构**: Vue 3 (Composition API) + Spring Boot REST API
- **Pinia 状态管理 + Element Plus UI**: 管理后台 6 个功能页面
- **ECharts 数据可视化**: 仪表盘柱状图/折线图展示用户增长趋势
- **Axios 拦截器**: 统一请求/响应处理，JWT Token 自动注入，401 自动跳转登录
- **Vue Router 路由守卫**: 基于 Token 存在性的页面访问控制
- **Godot 4 游戏引擎**: GDScript 编写的完整 Roguelike 幸存者游戏

### 游戏开发技术亮点

- **12种武器系统**: 手枪、狙击、消防斧、手榴弹、棒球、喷火器、无人机、导弹、符咒、飞刀、圣水、星星，每种 8 级升级路线
- **9个可玩角色**: 各具独特初始武器和被动技能，支持解锁和等级强化
- **5个 Boss**: 多阶段战斗机制（1~3 阶段），专属 BGM 和对话
- **地图系统**: 4 张地图，线性解锁，含教程关
- **16种被动道具**: 升级时随机选择，覆盖移速/暴击/范围/数量等属性
- **云存档同步**: 通过 HTTP 与后端通信，JSON Blob 方式整体上传/下载游戏进度

---

## 3. 简历项目描述（按岗位方向定制）

### 3.1 后端开发岗位

**项目名称**: 像素幸存者 - 游戏后端服务系统

**项目描述**:  
基于 Spring Boot 3.2.5 + Java 17 + MyBatis-Plus 开发的游戏后端服务，为 Godot 4 游戏客户端和 Vue 3 管理后台提供 RESTful API。实现了 JWT 双Token认证体系、Redis 多场景缓存方案、Redisson 分布式锁、AOP 操作审计等。

**主要职责与成果**:
- 设计并实现了 JWT 双Token认证体系（游戏端2h / 管理端8h），通过 3 个自定义拦截器（GameAuth / AdminAuth / RateLimit）完成认证、授权和限流
- 基于 Redis 实现了 5 种缓存与应用场景：用户信息 Cache-Aside 缓存、仪表盘数据缓存、Redisson 分布式锁、固定窗口 API 限流（fail-open 降级）、在线用户 Set 追踪 + 定时清理
- 使用 Spring AOP + 自定义 `@OperationLog` 注解实现管理端操作自动审计，记录操作人、IP、参数、响应、耗时到数据库
- 设计了 JSON Blob 模式的游戏存档同步方案，通过 `t_user_save_data` 表的一条记录承载全部游戏进度数据
- 使用 Spring Security + BCrypt 实现密码加密存储，CSRF 禁用 + 无状态会话适配 REST API
- 集成 Knife4j 自动生成 API 文档，便于前后端联调

**技术栈**: Spring Boot 3.2.5, Java 17, MyBatis-Plus, MySQL 8.0, Redis, Redisson, Spring Security, JWT (jjwt), Knife4j, Spring AOP

---

### 3.2 全栈开发岗位

**项目名称**: 像素幸存者 - 全栈游戏平台

**项目描述**:  
独立设计并开发了包含 Godot 游戏客户端、Spring Boot 后端服务、Vue 3 管理后台的完整游戏平台。后端提供 RESTful API，前端管理后台实现数据看板、用户管理、操作日志等功能，游戏客户端通过 HTTP 实现云存档同步。

**主要职责与成果**:
- **后端**: 使用 Spring Boot 3 + Java 17 开发 RESTful API，整合 JWT 双Token认证、Redis 多场景缓存、Redisson 分布式锁、AOP 操作审计等技术方案
- **前端**: 使用 Vue 3 (Composition API) + Vite + Element Plus + Pinia + ECharts 开发管理后台，包含登录（黑洞动画）、仪表盘（图表）、用户管理、数据编辑、操作日志、管理员管理等 6 个功能页面
- **前后端通信**: Axios 拦截器统一处理 JWT Token 注入、401 响应自动跳转、错误提示；Vue Router 路由守卫实现页面访问控制
- **数据可视化**: ECharts 柱状图展示每日新增用户趋势，支持 7天/30天/3个月时间范围切换
- **游戏端集成**: Godot 4 游戏通过 NetworkManager 脚本与后端 HTTP API 交互，实现用户注册/登录和云存档上传/下载

**技术栈**: Vue 3, Vite, Element Plus, Pinia, ECharts, Axios, Spring Boot 3, MyBatis-Plus, MySQL, Redis, Redisson, JWT, Godot 4, GDScript

---

### 3.3 游戏开发岗位

**项目名称**: 像素幸存者 - Roguelike 幸存者游戏

**项目描述**:  
使用 Godot 4 引擎 (GDScript) 独立开发的像素风 Roguelike 类幸存者游戏，参考《Vampire Survivors》核心玩法。实现了 9 角色/12 武器/5 Boss/4 地图的完整游戏内容，以及云存档同步和音频系统。

**主要职责与成果**:
- 设计并实现了 12 种武器的数据驱动升级系统，每种武器 8 个等级，通过 database.gd 集中管理所有游戏数据
- 实现 9 个各具特色的可玩角色，具有不同的初始武器和被动技能，支持金币解锁和等级强化
- 设计 5 个 Boss 的多阶段战斗机制（1~3 阶段，含专属 BGM 和对话框）
- 实现完整 Roguelike 循环：击杀敌人 → 获取经验 → 升级 → 选择 Buff → 变得更强
- 16 种被动道具随机池，升级时从随机 3~4 个选项中选择
- 通过 NetworkManager 脚本实现 HTTP 云存档同步，支持多设备游戏进度互通
- 音频系统支持 BGM/SFX 独立音量控制，20+ 音效文件
- UI 系统包含主菜单、角色选择、地图选择、HUD、升级界面、结算界面、设置（键位自定义）、图鉴等

**技术栈**: Godot 4, GDScript, HTTP (存档同步 API)

---

## 4. STAR 法则面试示例

### Q: "请介绍一个你最有成就感的技术实现"

**S (情境)**:  
在 Pixel Survivor 游戏项目中，需要为管理后台提供操作审计功能——记录每个管理员的操作（谁、什么时候、做了什么、结果如何），但不能侵入业务代码。

**T (任务)**:  
实现一个无侵入的操作日志记录方案，对管理端所有敏感操作自动记录到数据库。

**A (行动)**:
1. 自定义 `@OperationLog` 注解，包含 module、operation、description 属性
2. 使用 Spring AOP 的 `@Around` 环绕通知拦截所有标注该注解的方法
3. 在切面中从 JWT Token 解析操作人信息（adminId, username）
4. 从 HttpServletRequest 获取操作 IP（X-Forwarded-For → X-Real-IP → RemoteAddr 链式获取）
5. 使用 Jackson 序列化请求参数和响应结果（截断至 1000 字符防溢出）
6. 通过 JDBC Template 直接写入 `t_admin_operation_log` 表（绕过 MyBatis-Plus，确保 finally 块中即使业务异常也能记录）
7. 记录耗时（System.currentTimeMillis() 差值）

**R (结果)**:
- 开发者只需在 Controller 方法上加 `@OperationLog` 注解即可自动记录，零代码侵入
- 管理后台的"操作日志"页面可查询、筛选、追溯所有管理员的历史操作
- 日志包含 IP 地址，支持安全审计

### Q: "你在项目中如何保证高并发下的数据一致性？"

**S (情境)**:  
云存档同步功能允许玩家将本地游戏进度上传到服务器。同一玩家如果在两台设备同时登录并上传，可能造成数据覆盖或损坏。

**T (任务)**:  
防止同一用户并发上传导致的写写冲突。

**A (行动)**:
1. 引入 Redisson 分布式锁（基于 Redis），配置单节点 RedissonClient
2. 在 upload 方法中使用 `lock:sync:{userId}` 作为锁 Key
3. 使用 tryLock 机制，获取锁超时 5 秒，锁自动释放 10 秒
4. 上传操作包裹在 Spring `@Transactional` 事务中，保证写入原子性
5. 上传完成后删除 Redis 用户缓存（`user:info:{userId}`），保证缓存一致性

**R (结果)**:
- 同一用户的并发上传被串行化处理，避免数据损坏
- 事务保证写入原子性，失败时自动回滚
- 缓存删除策略保证下次查询获取最新数据

### Q: "你项目中 Redis 用在了哪些场景？"

**S (情境)**:  
项目中需要缓存、限流、分布式锁、在线状态管理等多种功能，Redis 是核心基础设施。

**T (任务)**:  
合理利用 Redis 的不同数据结构和特性解决不同场景的问题。

**A (行动)** - 实现了 5 种 Redis 应用场景：

1. **用户信息缓存 (String)**: Cache-Aside 模式，查询时先查 Redis，未命中查 MySQL 并回填；更新时删除缓存。TTL 30 分钟。
2. **仪表盘统计缓存**: 每日新增用户等聚合统计数据。
3. **分布式锁 (Redisson)**: 基于 Redisson 实现，用于存档同步的并发控制。
4. **API 限流 (String INCR)**: 固定窗口算法，使用 Redis INCR 原子自增 + EXPIRE 设置过期时间。每个 IP 在指定窗口内最多 N 次请求，超出返回 HTTP 429。Redis 不可用时 fail-open（降级放行）。
5. **在线用户追踪 (Set)**: 登录时 SADD，通过 `@Scheduled` 每 5 分钟扫描 Set，对比数据库 is_online 字段，清理离线用户。

**R (结果)**:
- 5 种 Redis 场景覆盖了项目中的缓存、并发控制、限流、状态管理等需求
- 限流 fail-open 策略确保 Redis 挂掉不影响正常服务
- 定时清理任务保证在线状态数据的最终一致性

---

## 5. 常见面试追问与准备

### Q1: "JWT Token 过期了怎么处理？为什么不自动续期？"

A: 当前设计是简单的过期重登方案。游戏 Token 2 小时，管理 Token 8 小时。这是毕业设计的简化方案。生产环境可用 Refresh Token 双Token机制：短期 Access Token（15min）+ 长期 Refresh Token（7天），Access Token 过期后用 Refresh Token 换取新的，Refresh Token 过期才需要重新登录。

### Q2: "你的限流是什么算法？和令牌桶有什么区别？"

A: 使用的是固定窗口（Fixed Window）算法，通过 Redis INCR 命令的原子性实现。优点是实现简单、Redis 原生支持好。缺点是存在临界点突发问题（窗口边界处的流量尖峰）。令牌桶算法更平滑但实现更复杂。对于毕业设计场景，固定窗口已足够。

### Q3: "为什么用 JSON Blob 而不是分表存储游戏存档？"

A: 游戏存档的结构经常变化（如新增角色、新地图、新成就类型），使用 JSON Blob 可以灵活适应结构变更而不需要 ALTER TABLE。管理端编辑也是直接修改 JSON。这是"无模式"设计在关系数据库中的一种折中方案。缺点是无法使用 SQL 进行存档内字段的查询和统计——但这在毕业设计中不是痛点。

### Q4: "为什么不直接用 Spring Security 的认证流程？"

A: Spring Security 默认的表单登录 + Session 机制不适合 REST API。已配置了 CSRF 禁用、无状态会话、全部请求放行。自定义拦截器 (GameAuthInterceptor / AdminAuthInterceptor) 实现了更细粒度的控制：两种 Token 类型隔离（game vs admin）、不同过期时间、不同路径匹配规则。这是灵活性和简单性的平衡。

### Q5: "MyBatis-Plus 和 MyBatis 有什么区别？为什么选 MP？"

A: MyBatis-Plus 是 MyBatis 的增强工具，提供了：
- 内置 CRUD 方法（ServiceImpl 的 save/update/getById/page 等），减少模板代码
- LambdaQueryWrapper 类型安全的条件构造（避免字符串拼接字段名）
- 分页插件自动拦截并改写 SQL
- 代码生成器（本项目未使用）

项目中大量使用 LambdaQueryWrapper 进行类型安全查询，显著减少了 SQL 拼接错误。

### Q6: "AOP 切面中为什么用 JDBC Template 而不是 MyBatis-Plus Mapper？"

A: 日志写入使用 JDBC Template 直接执行 INSERT SQL，有两个原因：
1. **可靠性**: AOP 切面在 finally 块中执行，此时 MyBatis 的 SqlSession 可能已经提交或关闭。JDBC Template 直接管理连接，更可靠。
2. **简单性**: 操作日志表只有简单的 INSERT，不需要复杂的 ORM 映射。

### Q7: "项目中的密码加密强度是多少？为什么选 BCrypt？"

A: 使用 Spring Security 的 BCryptPasswordEncoder（默认强度 10，即 2^10 = 1024 轮哈希）。BCrypt 的优势：
- 内置 salt（不需要单独管理盐值）
- 计算速度慢（对抗暴力破解）
- 强度可配置（cost factor）
- Spring Security 开箱即用

---

## 6. 项目面试自检清单

简历中写了这个项目后，确保能回答以下问题：

- [ ] Spring Boot 的自动配置原理是什么？
- [ ] JWT 的结构（Header.Payload.Signature）和签名验证流程？
- [ ] Redis 的 5 种基本数据结构及在本项目中的使用场景？
- [ ] Cache-Aside 模式的具体流程和缓存更新策略？
- [ ] Redisson 分布式锁的底层原理（Lua 脚本 + Hash）？
- [ ] 固定窗口限流的优缺点？和滑动窗口/令牌桶的区别？
- [ ] Spring AOP 的两种代理方式（JDK 动态代理 vs CGLIB）？
- [ ] `@Transactional` 的传播机制和失效场景？
- [ ] MyBatis-Plus 的 LambdaQueryWrapper 实现原理？
- [ ] 跨域 (CORS) 是什么？项目中如何配置的？
- [ ] MySQL 索引优化：项目中哪些字段建了索引？为什么？
- [ ] Godot 4 的场景树和信号机制？
