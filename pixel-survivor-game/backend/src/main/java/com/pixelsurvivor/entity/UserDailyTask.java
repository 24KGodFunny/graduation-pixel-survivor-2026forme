package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 用户每日任务进度实体（任务定义由游戏客户端资源管理）
 * <p>task_code 对应游戏客户端 daily_tasks.json 中的 id 字段</p>
 * <p>任务名、类型、目标等均在客户端资源中定义</p>
 * <p>数据库只记录用户的任务进度和领取状态</p>
 */
@Data
@TableName("t_user_daily_task")
public class UserDailyTask {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 任务编码，对应游戏客户端资源ID */
    private String taskCode;

    /** 任务日期 */
    private LocalDate taskDate;

    /** 当前进度 */
    private Integer progress;

    /** 是否已完成 */
    private Integer isCompleted;

    /** 是否已领取奖励 */
    private Integer isRewarded;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}