package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 游戏局记录实体
 * <p>character_code / map_code 对应游戏客户端资源中的ID</p>
 */
@Data
@TableName("t_game_record")
public class GameRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 角色编码，对应游戏客户端资源ID */
    private String characterCode;

    /** 地图编码，如 map_1_1 */
    private String mapCode;

    /** 章节1-3 */
    private Integer chapter;

    /** 关卡1-6 */
    private Integer gameLevel;

    /** 是否无尽模式 */
    private Integer isEndless;

    /** 到达波数 */
    private Integer waveReached;

    /** 击杀数 */
    private Integer killCount;

    /** Boss击杀数 */
    private Integer bossKillCount;

    /** 获得经验 */
    private Integer expGained;

    /** 获得游戏币 */
    private Integer coinGained;

    /** 游戏时长(秒) */
    private Integer playDuration;

    /** 是否通关 */
    private Integer isCleared;

    /** 死亡原因 */
    private String deathReason;

    /** 使用的Buff列表(JSON) */
    private String buffsUsed;

    /** 使用的道具列表(JSON) */
    private String itemsUsed;

    /** 得分 */
    private Integer score;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}