package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户游戏统计实体
 * 对应数据库表 t_user_game_stats
 */
@Data
@TableName("t_user_game_stats")
public class UserGameStats {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 累计击杀数 */
    private Integer totalKills;

    /** 累计游戏次数 */
    private Integer totalGames;

    /** 累计通关次数 */
    private Integer totalWins;

    /** 累计获得游戏币 */
    private Integer totalCoins;

    /** 最长存活时间(秒) */
    private Double bestTime;        // 数据库 FLOAT 对应 Double

    /** 创建时间 */
    private LocalDateTime createdAt;

    /** 更新时间 */
    private LocalDateTime updatedAt;
}