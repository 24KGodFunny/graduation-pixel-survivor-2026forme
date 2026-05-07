package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户成就进度实体（成就定义由游戏客户端资源管理）
 * <p>achievement_code 对应游戏客户端 achievements.json 中的 id 字段</p>
 * <p>成就名、条件、奖励等均在客户端资源中定义</p>
 * <p>数据库只记录用户的成就进度和领取状态</p>
 */
@Data
@TableName("t_user_achievement")
public class UserAchievement {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 成就编码，对应游戏客户端资源ID */
    private String achievementCode;

    /** 当前进度 */
    private Integer progress;

    /** 是否已完成 */
    private Integer isCompleted;

    /** 是否已领取奖励 */
    private Integer isRewarded;

    private LocalDateTime completedAt;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}