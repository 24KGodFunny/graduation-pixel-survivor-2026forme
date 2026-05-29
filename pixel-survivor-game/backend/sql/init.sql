-- ============================================================
-- Pixel Survivor 数据库初始化脚本（完整版）
-- 数据库: pixel_survivor
-- MySQL 8.0 | 用户: root | 密码: 1234
-- ============================================================
-- 设计原则：
--   游戏内容数据（角色定义、Buff定义、地图定义、成就定义、
--   任务定义、商品详情等）全部由 Godot 游戏客户端资源文件定义。
--   数据库只存储涉及用户状态、交易等"运行时"数据 + 部分服务端
--   可控的元数据（角色定义、地图定义）。
--   所有游戏内容引用均使用 item_code / character_code 等字符串编码，
--   与游戏客户端资源文件中的 ID 一一对应。
-- ============================================================

CREATE DATABASE IF NOT EXISTS pixel_survivor DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE pixel_survivor;

-- ============================================================
-- 一、用户相关表
-- ============================================================

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
-- 2. 用户全局存档表
--    所有存档数据以 JSON 形式存储在一个字段中
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS t_user_save_data (
    id          BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    user_id     BIGINT   NOT NULL COMMENT '用户ID',
    save_data   LONGTEXT NOT NULL COMMENT '存档JSON数据（包含角色、地图、成就、金币、钻石等全部状态）',
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户全局存档表';

-- -----------------------------------------------------------
-- 3. 用户角色表（角色定义由游戏客户端资源管理）
--    character_code 对应游戏客户端 characters.json 中的 id 字段
--    角色名、基础属性、技能、武器类型等均在客户端资源中定义
--    数据库只记录用户对该角色的解锁状态和强化数据
-- -----------------------------------------------------------
CREATE TABLE t_user_character (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    character_code VARCHAR(50) NOT NULL COMMENT '角色编码，对应游戏客户端资源ID',
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

-- ============================================================
-- 二、管理员相关表
-- ============================================================

-- -----------------------------------------------------------
-- 5. 管理员表
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

-- 默认超级管理员：admin / admin123
INSERT INTO t_admin (username, password, role) VALUES
('admin', '$2a$10$DsDNB3GTX7QLNrnvCRpJSeS3w/6WRTeuo3XTH7BBmgLazLuiGI4Ta', 'SUPER_ADMIN');

-- -----------------------------------------------------------
-- 6. 管理员操作日志表
--    记录哪个管理员，在何时进行了什么操作
-- -----------------------------------------------------------
CREATE TABLE t_admin_operation_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    admin_id BIGINT NOT NULL COMMENT '管理员ID',
    admin_username VARCHAR(50) NOT NULL COMMENT '管理员用户名',
    module VARCHAR(50) NOT NULL COMMENT '操作模块，如：用户管理、用户数据管理、管理员管理',
    operation VARCHAR(50) NOT NULL COMMENT '操作类型，如：CREATE、UPDATE、DELETE、LOGIN',
    description VARCHAR(200) NOT NULL COMMENT '操作描述，如：封禁用户、编辑用户存档数据',
    method VARCHAR(200) DEFAULT NULL COMMENT '请求方法（类名.方法名）',
    params TEXT DEFAULT NULL COMMENT '请求参数JSON',
    response TEXT DEFAULT NULL COMMENT '响应结果JSON',
    ip VARCHAR(50) DEFAULT NULL COMMENT '操作IP地址',
    error_msg TEXT DEFAULT NULL COMMENT '异常信息',
    cost_time BIGINT DEFAULT 0 COMMENT '耗时(毫秒)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    INDEX idx_admin_id (admin_id),
    INDEX idx_module (module),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB COMMENT='管理员操作日志表';


-- ============================================================
-- 三、游戏内容定义表（服务端元数据管理）
-- ============================================================

-- -----------------------------------------------------------
-- 7. 角色定义表
--    存储游戏所有角色的元数据信息
--    char_code 为唯一业务标识，程序通过它识别角色
--    数据来源：game-demo/scripts/autoload/database.gd
-- -----------------------------------------------------------
CREATE TABLE t_character_definition (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    char_code VARCHAR(50) NOT NULL UNIQUE COMMENT '唯一业务标识，如 maphy',
    char_name VARCHAR(100) NOT NULL COMMENT '角色中文名，如 玛菲',
    char_name_en VARCHAR(100) DEFAULT NULL COMMENT '角色英文名，如 Maphy',
    description VARCHAR(500) DEFAULT NULL COMMENT '角色描述',
    max_hp INT NOT NULL DEFAULT 100 COMMENT '基础生命上限',
    speed FLOAT NOT NULL DEFAULT 200.0 COMMENT '基础移动速度',
    armor FLOAT NOT NULL DEFAULT 0 COMMENT '基础护甲',
    damage_mult FLOAT NOT NULL DEFAULT 1.0 COMMENT '伤害倍率',
    cooldown_mult FLOAT NOT NULL DEFAULT 1.0 COMMENT '冷却倍率',
    crit_chance FLOAT NOT NULL DEFAULT 0.05 COMMENT '暴击率',
    crit_damage FLOAT NOT NULL DEFAULT 1.5 COMMENT '暴击伤害',
    luck FLOAT NOT NULL DEFAULT 1.0 COMMENT '幸运值',
    growth FLOAT NOT NULL DEFAULT 1.0 COMMENT '成长值',
    greed FLOAT NOT NULL DEFAULT 1.0 COMMENT '贪婪值',
    magnet_range FLOAT NOT NULL DEFAULT 50.0 COMMENT '拾取范围',
    starting_weapon VARCHAR(50) DEFAULT NULL COMMENT '初始武器编码',
    passive VARCHAR(50) DEFAULT NULL COMMENT '被动技能编码',
    unlock_cost INT DEFAULT 0 COMMENT '解锁所需金币（0=免费/条件解锁）',
    unlock_condition VARCHAR(200) DEFAULT NULL COMMENT '解锁条件描述（NULL=默认解锁）',
    is_active TINYINT DEFAULT 1 COMMENT '是否启用（1=启用，0=弃用）',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB COMMENT='角色定义表（存储游戏所有角色元数据）';

-- 初始角色数据（9个角色）
INSERT INTO t_character_definition
    (char_code, char_name, char_name_en, description, max_hp, speed, armor,
     damage_mult, cooldown_mult, crit_chance, crit_damage, luck, growth, greed,
     magnet_range, starting_weapon, passive, unlock_cost, unlock_condition, is_active)
VALUES
    ('maphy',   '玛菲', 'Maphy',   '标准型角色，平衡的属性',                   100, 200.0, 0, 1.0,  1.0,  0.05, 1.5, 1.0, 1.0, 1.0, 50.0, 'pistol',   '',           0,    NULL,                    1),
    ('minami',  '美波', 'Minami',  '高速型角色，移动速度快',                   80,  260.0, 0, 0.9,  1.0,  0.05, 1.5, 1.0, 1.0, 1.0, 50.0, 'dagger',   'movespeed',  0,    NULL,                    1),
    ('yuria',   '尤利娅','Yuria',  '重装型角色，高护甲高血量',                 150, 170.0, 3, 1.1,  1.1,  0.03, 1.5, 1.0, 0.9, 1.0, 40.0, 'axe',      'armor',      0,    NULL,                    1),
    ('sakura',  '樱',   'Sakura',  '攻击型角色，高伤害',                       90,  200.0, 0, 1.4,  1.0,  0.10, 2.0, 1.0, 1.0, 1.0, 50.0, 'sniper',   'damage',     0,    '通关「公路」后解锁',    1),
    ('kanna',   '栞那', 'Kanna',   '魔法型角色，冷却时间短',                   85,  210.0, 0, 1.0,  0.8,  0.05, 1.5, 1.2, 1.1, 1.0, 60.0, 'talisman', 'cooldown',   500,  NULL,                    1),
    ('kiko',    '绮子', 'Kiko',    '幸运型角色，高幸运值',                     90,  200.0, 0, 1.0,  1.0,  0.08, 1.8, 1.5, 1.0, 1.3, 50.0, 'baseball', 'luck',       800,  NULL,                    1),
    ('kureha',  '暮叶', 'Kureha',  '恢复型角色，生命恢复快',                   110, 200.0, 1, 1.0,  1.0,  0.05, 1.5, 1.0, 1.0, 1.0, 50.0, 'holywater','recovery',   1000, NULL,                    1),
    ('miho',    '美穗', 'Miho',    '成长型角色，经验获取多',                   95,  200.0, 0, 1.0,  1.0,  0.05, 1.5, 1.0, 1.5, 1.0, 50.0, 'grenade',  'growth',     1500, NULL,                    1),
    ('mika',    '米卡', 'Mika',    '全属性均衡偏高的高级角色',                 120, 230.0, 2, 1.3,  0.85, 0.12, 2.0, 1.3, 1.2, 1.2, 70.0, 'star',     'critical',   2000, NULL,                    1);

-- -----------------------------------------------------------
-- 8. 地图定义表
--    存储游戏所有地图的元数据信息
--    map_code 为唯一业务标识，程序通过它识别地图
--    数据来源：game-demo/scripts/autoload/database.gd
-- -----------------------------------------------------------
CREATE TABLE t_map_definition (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    map_code VARCHAR(50) NOT NULL UNIQUE COMMENT '唯一业务标识，如 endless_road',
    map_name VARCHAR(100) NOT NULL COMMENT '地图名称，如 无尽之路',
    chapter INT DEFAULT 1 COMMENT '所属章节',
    order_index INT DEFAULT 0 COMMENT '章节内排序',
    required_map_code VARCHAR(50) DEFAULT NULL COMMENT '解锁前置地图编码（NULL=初始即可见）',
    is_active TINYINT DEFAULT 1 COMMENT '是否启用（1=启用，0=弃用）',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_chapter (chapter),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB COMMENT='地图定义表（存储游戏所有地图元数据）';

-- 初始地图数据（4张地图）
INSERT INTO t_map_definition (map_code, map_name, chapter, order_index, required_map_code, is_active) VALUES
('tutorial',       '废弃城市',   0, 0, NULL,            1),
('endless_road',   '公路',       1, 1, 'tutorial',      1),
('wasteland',      '荒原',       1, 2, 'endless_road',  1),
('crimson_forest', '森林',       1, 3, 'wasteland',     1);


-- . 地图通关/失败记录表
CREATE TABLE IF NOT EXISTS `t_map_record` (
                                              `id`              BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                              `user_id`         BIGINT       NOT NULL COMMENT '关联 t_user.id',
                                              `map_code`        VARCHAR(64)  NOT NULL COMMENT '地图编码, 如 endless_road',
    `char_code`       VARCHAR(64)  NOT NULL COMMENT '角色编码',
    `result`          TINYINT      NOT NULL COMMENT '1=胜利, 0=失败',
    `duration_seconds` INT         NOT NULL COMMENT '运行时长(秒)',
    `kill_count`      INT          NOT NULL DEFAULT 0 COMMENT '击杀数',
    `total_damage`    BIGINT       NOT NULL DEFAULT 0 COMMENT '总伤害',
    `damage_taken`    BIGINT       NOT NULL DEFAULT 0 COMMENT '承受伤害',
    `coins_collected` INT          NOT NULL DEFAULT 0 COMMENT '收集金币',
    `player_level`    INT          NOT NULL DEFAULT 1 COMMENT '玩家等级',
    `weapons_json`    JSON         DEFAULT NULL COMMENT '装备武器列表',
    `rating`          VARCHAR(2)   DEFAULT NULL COMMENT '评价等级 S/A/B/C/D (仅胜利)',
    `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_map_code` (`map_code`),
    INDEX `idx_created_at` (`created_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='地图通关/失败记录';

-- . 用户每日签到记录表
CREATE TABLE IF NOT EXISTS `t_user_checkin` (
                                                `id`           BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                `user_id`      BIGINT   NOT NULL COMMENT '关联 t_user.id',
                                                `checkin_date` DATE     NOT NULL COMMENT '签到日期',
                                                `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                UNIQUE KEY `uk_user_date` (`user_id`, `checkin_date`),
    INDEX `idx_user_id` (`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户每日签到记录';

