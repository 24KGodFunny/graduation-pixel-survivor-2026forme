package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 每日签到实体
 */
@Data
@TableName("t_daily_sign")
public class SignRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 签到日期 */
    private LocalDate signDate;

    /** 连续签到天数 */
    private Integer consecutiveDays;

    /** 奖励类型: coin/diamond */
    private String rewardType;

    /** 奖励数量 */
    private Integer rewardValue;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}