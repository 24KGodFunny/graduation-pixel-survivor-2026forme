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
-- 4. 用户背包表
--    item_code 对应游戏客户端资源中的物品ID
-- -----------------------------------------------------------
CREATE TABLE t_user_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    item_code VARCHAR(50) NOT NULL COMMENT '商品编码，对应游戏客户端资源ID',
    quantity INT DEFAULT 1 COMMENT '数量',
    is_equipped TINYINT DEFAULT 0 COMMENT '是否装备',
    acquired_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_user_item (user_id, item_code)
) ENGINE=InnoDB COMMENT='用户背包表';

-- -----------------------------------------------------------
-- 5. 购买记录表
-- -----------------------------------------------------------
CREATE TABLE t_purchase_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(64) NOT NULL UNIQUE COMMENT '订单号',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    item_code VARCHAR(50) NOT NULL COMMENT '商品编码',
    item_name VARCHAR(100) DEFAULT NULL COMMENT '商品名(冗余，方便后台查看)',
    quantity INT DEFAULT 1 COMMENT '数量',
    total_price INT NOT NULL COMMENT '总价',
    pay_type TINYINT NOT NULL COMMENT '1游戏币2钻石',
    status TINYINT DEFAULT 1 COMMENT '0待支付1成功2失败3退款',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB COMMENT='购买记录表';

-- -----------------------------------------------------------
-- 6. 充值记录表
-- -----------------------------------------------------------
CREATE TABLE t_recharge_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(64) NOT NULL UNIQUE COMMENT '充值订单号',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    amount DECIMAL(10,2) NOT NULL COMMENT '金额(元)',
    diamond_count INT NOT NULL COMMENT '获得钻石',
    bonus_diamond INT DEFAULT 0 COMMENT '赠送钻石',
    status TINYINT DEFAULT 0 COMMENT '0待支付1成功2失败',
    pay_channel VARCHAR(20) DEFAULT NULL COMMENT 'alipay/wechat',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB COMMENT='充值记录表';

-- -----------------------------------------------------------
-- 7. 好友关系表
-- -----------------------------------------------------------
CREATE TABLE t_friend (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    friend_id BIGINT NOT NULL,
    status TINYINT DEFAULT 1 COMMENT '1已确认',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_friendship (user_id, friend_id),
    INDEX idx_user_id (user_id),
    INDEX idx_friend_id (friend_id)
) ENGINE=InnoDB COMMENT='好友关系表(双向存储)';

-- -----------------------------------------------------------
-- 8. 好友请求表
-- -----------------------------------------------------------
CREATE TABLE t_friend_request (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    from_user_id BIGINT NOT NULL,
    to_user_id BIGINT NOT NULL,
    message VARCHAR(200) DEFAULT '',
    status TINYINT DEFAULT 0 COMMENT '0待处理1同意2拒绝',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_to_user (to_user_id, status)
) ENGINE=InnoDB COMMENT='好友请求表';

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
-- 11. 游戏局记录表
--     character_code / map_code 对应游戏客户端资源中的ID
-- -----------------------------------------------------------
CREATE TABLE t_game_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    character_code VARCHAR(50) DEFAULT NULL COMMENT '角色编码',
    map_code VARCHAR(50) DEFAULT NULL COMMENT '地图编码，如 map_1_1',
    chapter INT DEFAULT 1 COMMENT '章节1-3',
    game_level INT DEFAULT 1 COMMENT '关卡1-6',
    is_endless TINYINT DEFAULT 0 COMMENT '是否无尽模式',
    wave_reached INT DEFAULT 0 COMMENT '到达波数',
    kill_count INT DEFAULT 0 COMMENT '击杀数',
    boss_kill_count INT DEFAULT 0 COMMENT 'Boss击杀数',
    exp_gained INT DEFAULT 0 COMMENT '获得经验',
    coin_gained INT DEFAULT 0 COMMENT '获得游戏币',
    play_duration INT DEFAULT 0 COMMENT '游戏时长(秒)',
    is_cleared TINYINT DEFAULT 0 COMMENT '是否通关',
    death_reason VARCHAR(50) DEFAULT NULL COMMENT '死亡原因',
    buffs_used TEXT COMMENT '使用的Buff列表(JSON)',
    items_used TEXT COMMENT '使用的道具列表(JSON)',
    score INT DEFAULT 0 COMMENT '得分',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_wave (wave_reached),
    INDEX idx_score (score)
) ENGINE=InnoDB COMMENT='游戏局记录表';

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

-- -----------------------------------------------------------
-- 13. 每日签到表
-- -----------------------------------------------------------
CREATE TABLE t_daily_sign (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    sign_date DATE NOT NULL,
    consecutive_days INT DEFAULT 1,
    reward_type VARCHAR(20) DEFAULT NULL COMMENT 'coin/diamond',
    reward_value INT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_date (user_id, sign_date),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB COMMENT='每日签到表';

-- -----------------------------------------------------------
-- 14. 用户每日任务进度表（任务定义由游戏客户端资源管理）
--     task_code 对应游戏客户端 daily_tasks.json 中的 id 字段
--     任务名、类型、目标等均在客户端资源中定义
--     数据库只记录用户的任务进度和领取状态
-- -----------------------------------------------------------
CREATE TABLE t_user_daily_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    task_code VARCHAR(50) NOT NULL COMMENT '任务编码，对应游戏客户端资源ID',
    task_date DATE NOT NULL,
    progress INT DEFAULT 0 COMMENT '当前进度',
    is_completed TINYINT DEFAULT 0 COMMENT '是否已完成',
    is_rewarded TINYINT DEFAULT 0 COMMENT '是否已领取奖励',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_task_date (user_id, task_code, task_date),
    INDEX idx_user_date (user_id, task_date)
) ENGINE=InnoDB COMMENT='用户每日任务进度表(任务定义由游戏客户端资源管理)';

-- -----------------------------------------------------------
-- 15. 邮件表
-- -----------------------------------------------------------
CREATE TABLE t_mail (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '0=全服邮件',
    title VARCHAR(100) NOT NULL,
    content TEXT,
    mail_type TINYINT DEFAULT 1 COMMENT '1系统2补偿3活动4奖励',
    reward_type VARCHAR(20) DEFAULT NULL COMMENT 'coin/diamond/item',
    reward_value INT DEFAULT NULL COMMENT '奖励数量',
    reward_item_code VARCHAR(50) DEFAULT NULL COMMENT '奖励物品编码(对应游戏客户端资源ID)',
    is_read TINYINT DEFAULT 0,
    is_claimed TINYINT DEFAULT 0,
    expire_at DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_expire (expire_at)
) ENGINE=InnoDB COMMENT='邮件表';

-- -----------------------------------------------------------
-- 16. 排行榜表
-- -----------------------------------------------------------
CREATE TABLE t_ranking (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    ranking_type VARCHAR(20) NOT NULL COMMENT 'wave/kill/score',
    score INT NOT NULL,
    season INT DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_type_season (user_id, ranking_type, season),
    INDEX idx_type_score (ranking_type, score DESC)
) ENGINE=InnoDB COMMENT='排行榜表(持久化快照)';

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