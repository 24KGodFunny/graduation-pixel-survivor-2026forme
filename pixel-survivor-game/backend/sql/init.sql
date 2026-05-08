-- ============================================================
-- Pixel Survivor 数据库初始化脚本
-- 数据库: pixel_survivor
-- MySQL 8.0 | 用户: root | 密码: 1234
-- ============================================================
-- 设计原则：
--   游戏内容数据（角色定义、Buff定义、地图定义、成就定义、
--   任务定义、商品详情等）全部由 Godot 游戏客户端资源文件定义。
--   数据库只存储涉及用户状态、交易、社交等"运行时"数据。
--   所有游戏内容引用均使用 item_code / character_code 等字符串编码，
--   与游戏客户端资源文件中的 ID 一一对应。
-- ============================================================

CREATE DATABASE IF NOT EXISTS pixel_survivor DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE pixel_survivor;

-- -----------------------------------------------------------
-- 1. 用户表
-- -----------------------------------------------------------
CREATE TABLE t_user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    password VARCHAR(255) NOT NULL COMMENT '密码(BCrypt)',
    nickname VARCHAR(50) DEFAULT NULL COMMENT '昵称',
    avatar_url VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
    email VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    game_coin INT DEFAULT 0 COMMENT '游戏币余额',
    diamond INT DEFAULT 0 COMMENT '钻石余额',
    level INT DEFAULT 1 COMMENT '等级',
    exp INT DEFAULT 0 COMMENT '经验值',
    total_play_time INT DEFAULT 0 COMMENT '总游戏时长(秒)',
    max_wave INT DEFAULT 0 COMMENT '最高波数',
    status TINYINT DEFAULT 1 COMMENT '1正常 0封禁',
    is_online TINYINT DEFAULT 0 COMMENT '是否在线',
    last_login_at DATETIME DEFAULT NULL COMMENT '最后登录',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='用户表';

-- -----------------------------------------------------------
-- 2. 管理员表
-- -----------------------------------------------------------
CREATE TABLE t_admin (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '账号',
    password VARCHAR(255) NOT NULL COMMENT '密码(BCrypt)',
    role VARCHAR(20) DEFAULT 'ADMIN' COMMENT 'SUPER_ADMIN/ADMIN',
    status TINYINT DEFAULT 1 COMMENT '1正常 0禁用',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='管理员表';

INSERT INTO t_admin (username, password, role) VALUES
('admin', '$2a$10$DsDNB3GTX7QLNrnvCRpJSeS3w/6WRTeuo3XTH7BBmgLazLuiGI4Ta', 'SUPER_ADMIN');

-- -----------------------------------------------------------
-- 3. 商品表（仅存运营数据，商品详情由游戏客户端资源定义）
--    item_code 对应游戏客户端 shop_items.json 中的 id 字段
--    商品名称、描述、图片、效果等均在客户端资源中定义
-- -----------------------------------------------------------
CREATE TABLE t_shop_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    item_code VARCHAR(50) NOT NULL UNIQUE COMMENT '商品编码，对应游戏客户端资源ID，如 item_heal_potion',
    price_coin INT DEFAULT 0 COMMENT '游戏币价格(0表示不可用游戏币购买)',
    price_diamond INT DEFAULT 0 COMMENT '钻石价格(0表示不可用钻石购买)',
    stock INT DEFAULT -1 COMMENT '库存(-1为无限)',
    max_buy_count INT DEFAULT -1 COMMENT '每人限购(-1为无限)',
    status TINYINT DEFAULT 1 COMMENT '1上架 0下架',
    sort_order INT DEFAULT 0 COMMENT '排序权重',
    start_time DATETIME DEFAULT NULL COMMENT '上架开始时间(NULL=永久)',
    end_time DATETIME DEFAULT NULL COMMENT '上架结束时间(NULL=永久)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_item_code (item_code)
) ENGINE=InnoDB COMMENT='商品表(仅存运营数据，商品详情由游戏客户端资源定义)';


-- -----------------------------------------------------------
-- 9. 管理员操作日志表
-- -----------------------------------------------------------
CREATE TABLE t_admin_operation_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    admin_id BIGINT NOT NULL,
    admin_username VARCHAR(50) DEFAULT NULL,
    operation VARCHAR(50) NOT NULL COMMENT 'CREATE/UPDATE/DELETE/LOGIN',
    module VARCHAR(50) NOT NULL COMMENT '操作模块',
    target_type VARCHAR(50) DEFAULT NULL,
    target_id VARCHAR(50) DEFAULT NULL,
    detail TEXT COMMENT '操作详情JSON',
    ip_address VARCHAR(50) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='管理员操作日志表';

-- -----------------------------------------------------------
-- 10. 用户角色表（角色定义由游戏客户端资源管理）
--     character_code 对应游戏客户端 characters.json 中的 id 字段
--     角色名、基础属性、技能、武器类型等均在客户端资源中定义
--     数据库只记录用户对该角色的解锁状态和强化数据
-- -----------------------------------------------------------
CREATE TABLE t_user_character (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    character_code VARCHAR(50) NOT NULL COMMENT '角色编码，对应游戏客户端资源ID，如 char_warrior',
    is_selected TINYINT DEFAULT 0 COMMENT '是否当前选中',
    level INT DEFAULT 1 COMMENT '角色等级',
    hp_upgrade INT DEFAULT 0 COMMENT '生命强化次数',
    atk_upgrade INT DEFAULT 0 COMMENT '攻击强化次数',
    def_upgrade INT DEFAULT 0 COMMENT '防御强化次数',
    speed_upgrade INT DEFAULT 0 COMMENT '移速强化次数',
    combat_power INT DEFAULT 0 COMMENT '战力',
    acquired_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_char (user_id, character_code)
) ENGINE=InnoDB COMMENT='用户角色表(角色定义由游戏客户端资源管理)';


-- -----------------------------------------------------------
-- 12. 用户成就进度表（成就定义由游戏客户端资源管理）
--     achievement_code 对应游戏客户端 achievements.json 中的 id 字段
--     成就名、条件、奖励等均在客户端资源中定义
--     数据库只记录用户的成就进度和领取状态
-- -----------------------------------------------------------
CREATE TABLE t_user_achievement (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    achievement_code VARCHAR(50) NOT NULL COMMENT '成就编码，对应游戏客户端资源ID',
    progress INT DEFAULT 0 COMMENT '当前进度',
    is_completed TINYINT DEFAULT 0 COMMENT '是否已完成',
    is_rewarded TINYINT DEFAULT 0 COMMENT '是否已领取奖励',
    completed_at DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_ach (user_id, achievement_code),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB COMMENT='用户成就进度表(成就定义由游戏客户端资源管理)';


-- ============================================================
-- 初始数据：商品运营数据
-- item_code 必须与游戏客户端 shop_items.json 中的 id 一致
-- ============================================================

INSERT INTO t_shop_item (item_code, price_coin, price_diamond, stock, max_buy_count, status, sort_order) VALUES
('item_heal_potion', 100, 0, -1, -1, 1, 1),
('item_super_heal_potion', 300, 10, -1, -1, 1, 2),
('item_shield', 200, 0, -1, -1, 1, 3),
('item_atk_boost', 150, 0, -1, -1, 1, 4),
('item_speed_boost', 120, 0, -1, -1, 1, 5),
('item_revive_token', 0, 50, -1, 3, 1, 6),
('item_exp_boost', 0, 30, -1, 5, 1, 7),
('item_coin_magnet', 250, 0, -1, -1, 1, 8),
('pack_starter', 0, 88, -1, 1, 1, 9),
('pack_advanced', 0, 288, -1, 1, 1, 10);