-- ============================================================
-- 角色定义表
-- 存储游戏所有角色的元数据信息
-- 新增角色只需 INSERT 一行数据即可
-- ============================================================

USE pixel_survivor;

-- -----------------------------------------------------------
-- 角色定义表
-- char_code 为唯一业务标识，程序通过它识别角色
-- unlock_condition 描述解锁条件（NULL=默认解锁）
-- unlock_cost 为解锁所需金币（0=免费/条件解锁）
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


-- ============================================================
-- 初始角色数据
-- 数据来源：game-demo/scripts/autoload/database.gd 中定义的 9 个角色
-- char_code 必须与游戏客户端 Database.characters 中的 key 一致
-- ============================================================

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