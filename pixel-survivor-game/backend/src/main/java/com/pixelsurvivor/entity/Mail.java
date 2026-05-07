package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 邮件实体
 */
@Data
@TableName("t_mail")
public class Mail {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户ID，0表示全服邮件 */
    private Long userId;

    /** 邮件标题 */
    private String title;

    /** 邮件内容 */
    private String content;

    /** 邮件类型: 1系统 2补偿 3活动 4奖励 */
    private Integer mailType;

    /** 奖励类型: coin/diamond/item */
    private String rewardType;

    /** 奖励数量 */
    private Integer rewardValue;

    /** 奖励物品编码(对应游戏客户端资源ID) */
    private String rewardItemCode;

    /** 是否已读 */
    private Integer isRead;

    /** 是否已领取 */
    private Integer isClaimed;

    /** 过期时间 */
    private LocalDateTime expireAt;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}