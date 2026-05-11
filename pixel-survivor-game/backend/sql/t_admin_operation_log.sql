-- ============================================================
-- 管理员操作日志表（重建）
-- 记录哪个管理员，在何时进行了什么操作
-- ============================================================

DROP TABLE IF EXISTS t_admin_operation_log;

CREATE TABLE t_admin_operation_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    admin_id BIGINT NOT NULL COMMENT '管理员ID',
    admin_username VARCHAR(50) NOT NULL COMMENT '管理员用户名',
    module VARCHAR(50) NOT NULL COMMENT '操作模块，如：用户管理、用户数据管理、管理员管理',
    operation VARCHAR(50) NOT NULL COMMENT '操作类型，如：新增、修改、删除、封禁、解封',
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