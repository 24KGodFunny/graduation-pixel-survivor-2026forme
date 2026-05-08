-- ============================================================
-- 地图定义表
-- 存储游戏所有地图的元数据信息
-- 新增地图只需 INSERT 一行数据即可
-- ============================================================

USE pixel_survivor;

-- -----------------------------------------------------------
-- 地图定义表
-- map_code 为唯一业务标识，程序通过它识别地图
-- required_map_code 指定解锁前置地图（NULL 表示初始即可用）
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


-- ============================================================
-- 初始地图数据
-- 数据来源：game-demo/scripts/autoload/database.gd 中定义的 3 张地图
-- map_code 必须与游戏客户端 Database.maps 中的 key 一致
-- ============================================================

INSERT INTO t_map_definition (map_code, map_name, chapter, order_index, required_map_code, is_active) VALUES
('tutorial',       '废弃城市',   0, 0, NULL,            1),
('endless_road',   '公路',       1, 1, 'tutorial',      1),
('wasteland',      '荒原',       1, 2, 'endless_road',  1),
('crimson_forest', '森林',       1, 3, 'wasteland',     1);
