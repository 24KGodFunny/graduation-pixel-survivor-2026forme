package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 管理员操作日志实体
 * <p>记录哪个管理员，在何时进行了什么操作</p>
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
     * 操作模块（如：用户管理、用户数据管理、管理员管理）
     */
    private String module;

    /**
     * 操作类型（如：CREATE、UPDATE、DELETE、LOGIN）
     */
    private String operation;

    /**
     * 操作描述（如：封禁用户、编辑用户存档数据）
     */
    private String description;

    /**
     * 请求方法（类名.方法名）
     */
    private String method;

    /**
     * 请求参数JSON
     */
    private String params;

    /**
     * 响应结果JSON
     */
    private String response;

    /**
     * 操作IP地址
     */
    private String ip;

    /**
     * 异常信息
     */
    private String errorMsg;

    /**
     * 耗时(毫秒)
     */
    private Long costTime;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
}