package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 排行榜实体（持久化快照）
 */
@Data
@TableName("t_ranking")
public class Ranking {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 排行类型: wave/kill/score */
    private String rankingType;

    /** 分数 */
    private Integer score;

    /** 赛季 */
    private Integer season;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}