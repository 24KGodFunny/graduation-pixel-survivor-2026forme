
# 大学生毕业设计项目 🎮 Pixel Survivor — 像素风类幸存者游戏

> 毕业设计项目 — 一款带付费功能的像素风Roguelike类幸存者游戏

## 📖 项目简介

Pixel Survivor 是一款像素风格的 Roguelike 类幸存者游戏，玩家在游戏中选择角色进入关卡，通过击杀怪物获取经验升级，随机选择 Buff 强化自身，最终击败 Boss 通关。游戏内置商城系统，支持游戏币和钻石（付费货币）双货币体系。

## 🏗️ 项目架构

```
pixel-survivor-game/
├── README.md                    # 项目说明（本文件）
├── docs/                        # 开发需求文档
│   ├── requirements.md          # 需求规格说明书
│   ├── database-design.md       # 数据库设计文档
│   ├── api-design.md            # API接口文档
│   └── architecture.md          # 系统架构文档
├── backend/                     # Spring Boot 后端服务
│   ├── pom.xml
│   ├── src/
│   └── sql/                     # 数据库初始化脚本
├── frontend/                    # Vue3 + Vite 管理后台
│   ├── package.json
│   ├── src/
│   └── index.html
└── game/                        # Godot 4.0 游戏客户端
    ├── project.godot
    ├── scenes/
    ├── scripts/
    └── assets/
```

## 🛠️ 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| **游戏客户端** | Godot 4.0 (GDScript) | 像素风游戏主体 |
| **管理后台** | Vue 3 + Vite + Element Plus | 管理员后台界面 |
| **后端服务** | Spring Boot 3.x + MyBatis-Plus | RESTful API 服务 |
| **缓存** | Redis + Caffeine | 多级缓存，防穿透/击穿/雪崩 |
| **数据库** | MySQL 8.0 | 持久化存储 |
| **认证** | Spring Security + JWT | 用户认证与授权 |
| **API文档** | Knife4j | 接口文档自动生成 |

## 🚀 快速开始

### 环境要求

- JDK 17+
- Node.js 18+
- MySQL 8.0
- Redis 7.x
- Godot 4.0

### 1. 数据库初始化

```bash
# 登录 MySQL
mysql -u root -p1234

# 执行建表脚本
source backend/sql/init.sql
```

### 2. 启动后端

```bash
cd backend
mvn spring-boot:run
```

后端默认运行在 `http://localhost:8080`

### 3. 启动管理后台

```bash
cd frontend
npm install
npm run dev
```

管理后台默认运行在 `http://localhost:5173`

### 4. 运行游戏

使用 Godot 4.0 打开 `game/project.godot` 项目文件，点击运行即可。

## 📋 功能清单

### 游戏端（用户端）
- [x] 登录/注册（支持离线模式）
- [x] 游戏大厅（NPC交互）
- [x] Roguelike 幸存者核心玩法
- [x] Buff 随机选择系统
- [x] 背包系统（局内使用道具）
- [x] 商城系统（游戏币/钻石购买）
- [x] 好友系统
- [x] 每日签到
- [x] 成就系统
- [x] 排行榜
- [x] 邮件系统

### 管理后台
- [x] 管理员登录
- [x] 数据看板（用户数、收入、在线数等）
- [x] 商品管理（CRUD、上下架）
- [x] 用户管理（查看、封禁）
- [x] 订单管理（购买记录、充值记录）
- [x] 游戏数据管理（Buff、地图、角色、成就）
- [x] 任务/签到配置
- [x] 邮件管理
- [x] 操作日志

## 📄 文档

- [需求规格说明书](docs/requirements.md)
- [数据库设计文档](docs/database-design.md)
- [API接口文档](docs/api-design.md)
- [系统架构文档](docs/architecture.md)

## 📝 开发日志

| 日期 | 内容 |
|------|------|
| 2026-05-04 | 项目初始化，完成架构设计和骨架搭建 |

## 📜 License

本项目仅用于记录开发过程以及版本管理，利用了agent工具协助开发，不建议参考。
其中后端的test用于生成加密后的密码，测试时，可以用它生成密码，直接填数据库里测试其它功能。