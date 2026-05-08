-- 用户全局存档表
-- 将所有存档数据以 JSON 形式存储在一个字段中
CREATE TABLE IF NOT EXISTS `t_user_save_data` (
    `id`          BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `user_id`     BIGINT        NOT NULL COMMENT '用户ID',
    `save_data`   LONGTEXT      NOT NULL COMMENT '存档JSON数据（包含角色、地图、成就、金币、钻石等全部状态）',
    `created_at`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户全局存档表';