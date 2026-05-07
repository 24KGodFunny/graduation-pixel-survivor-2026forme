-- ============================================================
-- Pixel Survivor 数据同步表扩展脚本
-- 在 init.sql 基础上执行，新增用户地图进度和游戏统计表
-- MySQL 8.0 | 数据库: pixel_survivor
-- ============================================================

USE pixel_survivor;

-- -----------------------------------------------------------
-- 17. 用户地图进度表（地图定义由游戏客户端资源管理）
--     map_code 对应游戏客户端 maps.json 中的 id 字段
--     地图名、难度、波数等均在客户端资源中定义
--     数据库只记录用户的解锁状态和最佳成绩
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS t_user_map_progress (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    map_code VARCHAR(50) NOT NULL COMMENT '地图编码，对应游戏客户端资源ID，如 endless_road',
    is_unlocked TINYINT DEFAULT 0 COMMENT '是否已解锁',
    best_score INT DEFAULT 0 COMMENT '最佳成绩',
    best_wave INT DEFAULT 0 COMMENT '最高波数',
    clear_count INT DEFAULT 0 COMMENT '通关次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_map (user_id, map_code),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB COMMENT='用户地图进度表(地图定义由游戏客户端资源管理)';

-- -----------------------------------------------------------
-- 18. 用户游戏统计表
--     记录用户的累计统计数据，用于同步和成就判定
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS t_user_game_stats (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE COMMENT '用户ID',
    total_kills INT DEFAULT 0 COMMENT '累计击杀数',
    total_games INT DEFAULT 0 COMMENT '累计游戏次数',
    total_wins INT DEFAULT 0 COMMENT '累计通关次数',
    total_coins INT DEFAULT 0 COMMENT '累计获得游戏币',
    best_time FLOAT DEFAULT 0.0 COMMENT '最长存活时间(秒)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB COMMENT='用户游戏统计表';