package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户地图进度实体
 * 对应数据库表 t_user_map_progress
 */
@Data
@TableName("t_user_map_progress")
public class UserMapProgress {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 地图编码 */
    private String mapCode;

    /** 是否已解锁 (0-未解锁, 1-已解锁) */
    @TableField("is_unlocked")
    private Integer isUnlocked;      // 注意：字段名 isUnlocked，映射数据库列 is_unlocked

    /** 最佳成绩（分数） */
    private Integer bestScore;

    /** 最高波数 */
    private Integer bestWave;

    /** 通关次数 */
    private Integer clearCount;

    /** 创建时间 */
    private LocalDateTime createdAt;

    /** 更新时间 */
    private LocalDateTime updatedAt;
}