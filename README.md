# Pixel Survivor -- 像素幸存者

> 像素风 Roguelike 类幸存者游戏 -- 毕业设计作品

## 项目概述

**Pixel Survivor** 是一款参考《Vampire Survivors》核心玩法的像素风 Roguelike 类幸存者游戏。玩家选择角色后在开放地图中生存，武器自动攻击靠近的敌人，通过击败敌人获取经验、升级、选择 Buff 来强化自身，最终击败 Boss 获得胜利。

项目包含三大模块：
- **Game**: Godot 4 游戏客户端（GDScript）
- **Backend**: Spring Boot 3 后端服务（Java 17 + MyBatis-Plus）
- **Frontend**: Vue 3 管理后台（Element Plus + ECharts）

## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 游戏引擎 | Godot | 4.x |
| 后端框架 | Spring Boot | 3.2.5 |
| 后端语言 | Java | 17 |
| ORM | MyBatis-Plus | 3.5+ |
| 数据库 | MySQL | 8.0 |
| 缓存 | Redis | 7.x |
| 分布式锁 | Redisson | 3.x |
| 认证 | JWT (jjwt) + BCrypt | - |
| API文档 | Knife4j | 4.x |
| 前端框架 | Vue 3 | 3.4+ |
| 构建工具 | Vite | 5.x |
| UI组件库 | Element Plus | 2.x |
| 状态管理 | Pinia | 2.x |
| 图表库 | ECharts | 5.x |

## 快速开始

### 1. 环境要求

- JDK 17+
- MySQL 8.0
- Redis 7.x
- Maven 3.6+
- Node.js 18+
- Godot 4.x

### 2. 初始化数据库

```bash
# 连接 MySQL，执行初始化脚本
mysql -u root -p < backend/sql/init.sql
# 或使用 Navicat / DataGrip 打开并执行 backend/sql/init.sql
```

数据库名为 `pixel_survivor`，默认管理员账号 `admin` / 密码 `admin123`。

### 3. 启动后端

```bash
cd backend
# 修改 src/main/resources/application.yml 中的数据库和 Redis 连接信息（如需要）
mvn spring-boot:run
```

后端启动在 `http://localhost:8080`，API 文档地址 `http://localhost:8080/doc.html`。

### 4. 启动前端

```bash
cd frontend
npm install
npm run dev
```

前端启动在 `http://localhost:5173`，登录使用管理员账号 `admin / admin123`。

### 5. 运行游戏

1. 打开 Godot 4 编辑器
2. 导入项目：选择 `game-demo/project.godot`
3. 点击运行按钮（F5）或通过编辑器菜单运行

游戏默认无需登录即可游玩（离线模式）。如需使用云存档同步，需先在游戏内注册/登录。

## 目录结构

```
pixel-survivor-game/
├── README.md                    # 项目说明
├── docs/                        # 项目文档
│   ├── architecture.md          # 系统架构文档
│   ├── database-design.md       # 数据库设计文档
│   ├── api-design.md            # API 接口文档
│   ├── game-design.md           # 游戏设计文档
│   ├── sync-api-design.md       # 数据同步接口文档
│   └── resume.md                # 简历编写与面试准备指南
├── backend/                     # Spring Boot 后端
│   ├── src/main/java/com/pixelsurvivor/
│   │   ├── common/              # 通用组件（Result, Exception, Annotation, AOP, JWT）
│   │   ├── config/              # 配置（Security, Web, Redis, Redisson）
│   │   ├── config/interceptor/  # 拦截器（GameAuth, AdminAuth, RateLimit）
│   │   ├── controller/          # 控制器
│   │   ├── service/             # 服务层
│   │   ├── mapper/              # MyBatis-Plus Mapper
│   │   ├── entity/              # 实体类
│   │   ├── dto/                 # 数据传输对象
│   │   └── task/                # 定时任务
│   ├── src/main/resources/
│   │   └── application.yml      # 应用配置
│   └── sql/init.sql             # 数据库初始化脚本
├── frontend/                    # Vue 3 管理后台
│   └── src/
│       ├── views/               # 页面组件
│       │   ├── Login.vue        # 登录页（黑洞动画）
│       │   ├── Dashboard.vue    # 仪表盘
│       │   ├── UserManage.vue   # 用户管理
│       │   ├── UserDataManage.vue # 用户数据管理
│       │   ├── OperationLogs.vue  # 操作日志
│       │   ├── AdminManage.vue  # 管理员管理
│       │   └── Profile.vue      # 修改密码
│       ├── layout/              # 布局组件
│       ├── router/              # 路由配置
│       ├── stores/              # Pinia 状态管理
│       ├── api/                 # API 请求封装
│       └── utils/request.js     # Axios 拦截器
└── game-demo/                   # Godot 4 游戏客户端
    ├── project.godot            # Godot 项目配置
    ├── scenes/                  # 场景文件 (.tscn)
    ├── scripts/                 # GDScript 脚本
    │   ├── autoload/            # 全局自动加载（database, save_manager, network_manager 等）
    │   ├── player.gd            # 玩家控制
    │   ├── enemy_base.gd        # 敌人行为
    │   ├── boss.gd              # Boss 逻辑
    │   ├── hud.gd               # HUD 界面
    │   └── ...
    └── assets/                  # 美术/音频资源
        ├── images/              # 精灵图（角色、敌人、Boss、武器、UI等）
        └── audio/               # 音效与背景音乐
```

## 功能概览

### 游戏客户端

- 9 个可玩角色（各有独特初始武器和被动技能）
- 12 种武器（每种 8 级升级路线）
- 16 种被动道具
- 4 种敌人 + 5 个 Boss（多阶段战斗）
- 4 张地图（线性解锁）
- 升级选择 Buff 的 Roguelike 核心循环
- 胜利/失败结算 + 评级系统
- 用户注册/登录 + 云存档同步
- 音频系统（BGM/SFX 独立音量控制）
- 设置（音量、全屏、按键自定义）
- 主菜单、角色选择、地图选择、图鉴、暂停、对话等完整 UI

### 后端服务

- JWT 双Token认证（游戏端 2h / 管理端 8h）
- Redis 多场景应用（缓存、限流、分布式锁、在线追踪）
- AOP 操作日志自动审计
- 云存档 JSON Blob 同步
- 管理端完整 CRUD API

### 管理后台

- 黑洞动画登录页
- 数据仪表盘（ECharts 图表）
- 用户管理（搜索、封禁/解封、删除）
- 用户数据管理（查看/编辑存档 JSON）
- 操作日志（筛选、分页）
- 管理员管理（新增、删除、修改密码）

## 文档索引

| 文档 | 说明 |
|------|------|
| [系统架构文档](pixel-survivor-game/docs/architecture.md) | 整体架构、技术选型、Redis缓存架构、安全设计 |
| [数据库设计文档](pixel-survivor-game/docs/database-design.md) | 9 张表的完整表结构、ER关系、初始数据 |
| [API 接口文档](pixel-survivor-game/docs/api-design.md) | 游戏端 + 管理端全部接口，含请求/响应示例 |
| [游戏设计文档](pixel-survivor-game/docs/game-design.md) | 角色、武器、敌人、Boss、地图、战斗机制详情 |
| [数据同步接口文档](pixel-survivor-game/docs/sync-api-design.md) | JSON Blob 云存档同步的完整规范 |
| [简历与面试指南](pixel-survivor-game/docs/resume.md) | STAR 面试示例、常见追问准备、自检清单 |
