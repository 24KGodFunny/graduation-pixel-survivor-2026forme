package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 管理员操作日志实体
 */
@Data
@TableName("t_admin_operation_log")
public class AdminOperationLog {

    /**
     * 主键ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 管理员ID
     */
    private Long adminId;

    /**
     * 管理员用户名
     */
    private String adminUsername;

    /**
     * 操作名称（如：新增用户）
     */
    private String operation;

    /**
     * 操作模块（如：用户管理）
     */
    private String module;

    /**
     * 目标类型（如：USER, ROLE）
     */
    private String targetType;

    /**
     * 目标ID
     */
    private String targetId;

    /**
     * 操作详情（JSON或文本）
     */
    private String detail;

    /**
     * IP地址
     */
    private String ipAddress;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
}